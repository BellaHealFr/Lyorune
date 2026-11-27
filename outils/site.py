# Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
# Fabrique le site de présentation à partir d'une seule source (site/src), pour deux hébergements :
#   python outils/site.py github       ->  dist-github/      (GitHub Pages, sous /Lyorune/)
#   python outils/site.py cloudflare   ->  dist-cloudflare/  (Cloudflare, à la racine d'un domaine)
#   python outils/site.py github public   (dossier de sortie au choix, utilisé par le circuit Site)
# Les textes sont dans site/src/textes (fr.json, en.json) : un texte ne s'écrit qu'une fois.
# Les couleurs des thèmes de la démo sont lues dans Themes.lua, la version dans Lyorune.toc, les nouveautés dans
# les CHANGELOG : le site suit l'addon sans rien recopier à la main.
import html, json, os, re, shutil, subprocess, sys, zipfile

ICI = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ICI, 'site', 'src')
IMAGES = os.path.join(ICI, 'docs', 'images')

# Une cible = une adresse. La principale porte le canonical : l'autre pointe vers elle pour ne pas lui faire
# concurrence dans les moteurs de recherche (à inverser le jour où le domaine Cloudflare devient l'adresse
# principale : passer « principale » de l'une à l'autre).
CIBLES = {
    'github': {
        'url': 'https://bellahealfr.github.io/Lyorune/',
        'principale': True,
        'goatcounter': 'lyorune',
    },
    'cloudflare': {
        # TODO domaine Cloudflare : à donner par SITE_URL_CLOUDFLARE (jamais affiché sur la page)
        'url': os.environ.get('SITE_URL_CLOUDFLARE', 'https://lyorune.example/'),
        'principale': False,
        # identifiant GoatCounter propre à cette cible (vide : aucun compteur)
        'goatcounter': os.environ.get('GOATCOUNTER_CLOUDFLARE', ''),
    },
}
LANGUES = ('fr', 'en')

PLATEFORMES = [
    ('curseforge', 'https://www.curseforge.com/wow/addons/lyorune-healing', True),
    ('wago', 'https://addons.wago.io/addons/lyorune', True),
    ('wowinterface', 'https://www.wowinterface.com/downloads/info27323-Lyorune.html', False),
    ('github', 'https://github.com/BellaHealFr/Lyorune/releases/latest', False),
]
MOIS = {
    'fr': ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre',
           'novembre', 'décembre'],
    'en': ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October',
           'November', 'December'],
}
# Lettres de l'inscription : les mêmes règles que Runes.lua (th et ng font une rune, v se lit u, c q x se lisent k)
RUNES_PAIRES = ('th', 'ng')
RUNES_AUTRES = {'v': 'u', 'c': 'k', 'q': 'k', 'x': 'k'}


def lire(*chemin):
    with open(os.path.join(ICI, *chemin), encoding='utf-8') as f:
        return f.read()


def ecrire(chemin, texte):
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, 'w', encoding='utf-8', newline='\n') as f:
        f.write(texte)


def attr(texte):
    """Texte sûr dans un attribut : sans balise, échappé."""
    return html.escape(re.sub(r'<[^>]+>', '', str(texte)), quote=True)


def date_lisible(iso, lang):
    a, m, j = (int(x) for x in iso.split('-'))
    if lang == 'fr':
        return '%d%s %s %d' % (j, 'er' if j == 1 else '', MOIS['fr'][m - 1], a)
    return '%s %d, %d' % (MOIS['en'][m - 1], j, a)


def markdown_ligne(texte):
    """Une ligne du CHANGELOG en HTML : liens [texte](url) et `code`."""
    texte = html.escape(texte, quote=False)
    texte = re.sub(r'\[([^\]]+)\]\((https?://[^)\s]+)\)', r'<a href="\2">\1</a>', texte)
    return re.sub(r'`([^`]+)`', r'<code>\1</code>', texte)


def journal(fichier, nombre=3):
    """Les dernières versions du CHANGELOG : [(version, date, [(rubrique, [lignes])])]."""
    versions = []
    for bloc in re.split(r'^## \[', lire(fichier), flags=re.M)[1:nombre + 1]:
        tete = re.match(r'([^\]]+)\] - (\d{4}-\d{2}-\d{2})', bloc)
        rubriques = []
        for nom, corps in re.findall(r'^### (.+)\n\n((?:- .*\n?)+)', bloc, flags=re.M):
            rubriques.append((nom.strip(), [l[2:].strip() for l in corps.strip().split('\n') if l.startswith('- ')]))
        versions.append((tete.group(1), tete.group(2), rubriques))
    return versions


def themes():
    """Couleurs des cinq thèmes et du contraste élevé, lues dans Themes.lua (valeurs de 0 à 1)."""
    code = lire('Themes.lua')
    resultat = {}
    for m in re.finditer(r'id = "(\w+)", name = "[^"]*".*?absorb = \{([^}]*)\}', code, flags=re.S):
        corps = m.group(0)
        def valeurs(nom):
            v = re.search(nom + r' = \{([^}]*)\}', corps)
            return [float(x) for x in v.group(1).split(',')] if v else None
        resultat[m.group(1)] = {
            'bg': valeurs('bg'), 'border': valeurs('border'), 'shade': valeurs('shade'),
            'incoming': valeurs('incoming'), 'absorb': valeurs('absorb'),
            'borderSize': int(re.search(r'borderSize = (\d+)', corps).group(1)),
            'outline': 'OUTLINE' in re.search(r'flags = "([^"]*)"', corps).group(1),
            'texture': 'WHITE' if 'texture = WHITE' in corps else ('CLASSIC' if 'RaidFrame' in corps else 'BAR'),
        }
    return resultat


def code_partage(reglages):
    """Code de partage du jeu (Share.lua, Z:Export) : Lyorune2;cle=tVALEUR, clés triées."""
    def coder(v):
        return re.sub(r'[^0-9A-Za-z]', lambda c: '%%%02X' % ord(c.group(0)), v)
    parts = ['Lyorune2']
    for cle in sorted(reglages):
        v = reglages[cle]
        if isinstance(v, bool):
            parts.append('%s=b%s' % (cle, 'true' if v else 'false'))
        elif isinstance(v, (int, float)):
            parts.append('%s=n%s' % (cle, v))
        else:
            parts.append('%s=s%s' % (cle, coder(v)))
    return ';'.join(parts)


def runes(phrase):
    """L'inscription en runes : [(fichier de la rune, lettre lue)] ; None pour une espace."""
    suite, i, phrase = [], 0, phrase.lower()
    while i < len(phrase):
        if phrase[i] == ' ':
            suite.append(None); i += 1; continue
        paire = phrase[i:i + 2]
        if paire in RUNES_PAIRES:
            suite.append((paire, paire.upper())); i += 2; continue
        lettre = phrase[i]
        suite.append((RUNES_AUTRES.get(lettre, lettre), lettre.upper())); i += 1
    return suite


def version_addon():
    return re.search(r'## Version: (\S+)', lire('Lyorune.toc')).group(1)


def numero_build():
    sha = os.environ.get('GITHUB_SHA', '')
    if sha:
        return sha[:8]
    try:
        return subprocess.run(['git', 'rev-parse', '--short=8', 'HEAD'], cwd=ICI, capture_output=True,
                              text=True, check=True).stdout.strip()
    except Exception:
        return 'local'


# ------------------------------------------------------------------------------------------------------------
# Les sections de la page
# ------------------------------------------------------------------------------------------------------------

def bloc_accueil(t, c):
    h = t['hero']
    auto, manuel = [], []
    for ident, url, app in PLATEFORMES:
        nom = t['plateformes'][ident]
        lien = ('<a class="plateforme%s" href="%s" data-evenement="telecharger-%s"%s>%s</a>'
                % (' principale' if app else '', url, ident,
                   ' data-archive' if ident == 'github' else '', nom))
        (auto if app else manuel).append(lien)
    version = h['version'].format(version=c['version'], date=c['date'], date_iso=c['date_iso'])
    return f'''<section class="accueil conteneur" aria-labelledby="titre">
  <div class="accueil-texte">
    <div class="couronne"><canvas aria-hidden="true"></canvas><img class="logo" src="{c['racine']}images/logo.png" alt="" width="256" height="256"></div>
    <h1 id="titre">Lyorune</h1>
    <p class="devise">{h['devise']}</p>
    <p class="accroche">{h['accroche']}</p>
    <div class="telecharger" id="telecharger">
      <h2 class="visuel-cache">{h['telecharger']}</h2>
      <p class="rangee-titre">{h['auto']}</p>
      <div class="rangee">{''.join(auto)}</div>
      <p class="rangee-titre">{h['manuel']}</p>
      <div class="rangee">{''.join(manuel)}<a class="plateforme guide" href="{h['guide_url']}">{h['guide']}</a></div>
      <p class="version">{version}</p>
    </div>
    <p class="infos">{h['infos']}</p>
  </div>
  <div class="accueil-groupe" role="img" aria-label="{attr(h['groupe_alt'])}">
    <div class="fenetre-titre" aria-hidden="true">{t['demo']['groupe'].format(n=1)}</div>
    <div class="mini-groupe" data-mini></div>
  </div>
</section>'''


def bloc_demo(t, c):
    d = t['demo']
    options_themes = ''.join('<option value="%s"%s>%s</option>' % (k, ' selected' if k == 'PURE' else '', v)
                             for k, v in d['themes'].items())
    joueurs = ''.join('<label><input type="radio" name="joueurs" value="%d"%s> %d</label>'
                      % (n, ' checked' if n == 5 else '', n) for n in (5, 20, 40))
    return f'''<section id="demo" class="demo" aria-labelledby="titre-demo">
  <div class="conteneur">
    <h2 id="titre-demo">{d['titre']}</h2>
    <p class="sous-titre">{d['intro']}</p>
    <div class="demo-cadre">
      <form class="demo-reglages" autocomplete="off" aria-label="{attr(d['titre'])}">
        <label class="reglage">{d['theme']}<select name="theme">{options_themes}</select></label>
        <fieldset class="reglage"><legend>{d['joueurs']}</legend><div class="choix">{joueurs}</div></fieldset>
        <label class="reglage">{d['taille']} <output name="taille-v">100 %</output><input type="range" name="taille" min="70" max="130" step="5" value="100"></label>
        <label class="reglage">{d['transparence']} <output name="alpha-v">100 %</output><input type="range" name="alpha" min="40" max="100" step="5" value="100"></label>
        <label class="reglage">{d['rangement']}<select name="rangement"><option value="GROUP">{d['par_groupe']}</option><option value="ROLE">{d['par_role']}</option></select></label>
        <label class="reglage case-a-cocher"><input type="checkbox" name="contraste"> {d['contraste']}</label>
        <div class="reglage boutons-demo">
          <button type="button" class="petit" data-pause>{d['pause']}</button>
          <button type="button" class="petit" data-zero>{d['zero']}</button>
        </div>
      </form>
      <div class="demo-scene">
        <div class="demo-groupe" id="demo-groupe" role="group" aria-label="{attr(d['aria_groupe'])}"></div>
        <noscript><p class="note">{d['sans_script']}</p></noscript>
        <p class="compteur" data-compteur aria-hidden="true"></p>
        <p class="visuel-cache" aria-live="polite" data-annonce></p>
      </div>
    </div>
    <p class="note">{d['aide']}</p>
    <p class="note discret">{d['honnete']}</p>
  </div>
</section>'''


def bloc_video(t, c):
    v = t['video']
    if os.path.exists(os.path.join(SRC, 'medias', 'jeu.mp4')):
        media = (f'<video controls preload="none" playsinline width="1059" height="696" '
                 f'poster="{c["racine"]}images/captures/options.png"><source src="{c["racine"]}medias/jeu.mp4" '
                 f'type="video/mp4"></video>')
    else:
        media = (f'<img src="{c["racine"]}images/captures/options.png?v={c["build"]}" alt="{attr(v["alt"])}" '
                 f'width="1059" height="696" loading="lazy">')
    return f'''<section class="video conteneur" aria-labelledby="titre-video">
  <h2 id="titre-video">{v['titre']}</h2>
  <figure>{media}<figcaption>{v['legende']}</figcaption></figure>
</section>'''


def bloc_coup(t, c):
    p = t['coup']
    pastilles = ''.join(
        f'<button type="button" class="pastille p{i}" aria-describedby="pin-{i}" data-pin="{i}">{i}</button>'
        for i in range(1, len(p['pins']) + 1))
    liste = ''.join(f'<li id="pin-{i}" data-pin="{i}"><strong>{i}. {x["titre"]}</strong> {x["texte"]}</li>'
                    for i, x in enumerate(p['pins'], 1))
    return f'''<section class="coup conteneur" aria-labelledby="titre-coup">
  <h2 id="titre-coup">{p['titre']}</h2>
  <p class="sous-titre">{p['intro']}</p>
  <div class="coup-grille">
    <div class="grande-case-zone">
      <div class="grande-case" aria-hidden="true">
        <div class="gc-vie"></div><div class="gc-entrant"></div><div class="gc-bouclier"></div>
        <div class="gc-menace"></div>
        <div class="gc-hots"><i class="h1"></i><i class="h2"></i><i class="h3 gris"></i></div>
        <div class="gc-role"><svg viewBox="0 0 20 20"><path d="M10 1 3 4v5c0 4.4 3 8.2 7 10 4-1.8 7-5.6 7-10V4z"/></svg></div>
        <div class="gc-nom">{p['nom']}<span>-3412</span></div>
        <div class="gc-boss"></div>
        <div class="gc-debuffs"><i></i><i></i></div>
        <div class="gc-mana"><div></div><b></b></div>
      </div>
      {pastilles}
    </div>
    <ol class="pins">{liste}</ol>
  </div>
</section>'''


def bloc_fonctions(t, c):
    f, l = t['phares'], t['liste']
    phares = ''.join(f'''<article class="infobulle">
      <h3>{x['nom']}</h3>
      <p class="lie">{f['lien']}</p>
      <p class="type"><span>{f['rarete']}</span><span>{x['type']}</span></p>
      <p class="utiliser">{f['utiliser']} {x['texte']}</p>
      <p class="saveur">{x['saveur']}</p>
    </article>''' for x in f['items'])
    liste = ''.join(f'''<li><img src="{c['racine']}images/runes/{x['rune']}.png" alt="" width="40" height="40" loading="lazy"><div><h3>{x['titre']}</h3><p>{x['texte']}</p></div></li>'''
                    for x in l['items'])
    return f'''<section id="fonctions" class="fonctions conteneur" aria-labelledby="titre-fonctions">
  <h2 id="titre-fonctions">{f['titre']}</h2>
  <p class="sous-titre">{f['intro']}</p>
  <div class="phares">{phares}</div>
  <h3 class="liste-titre">{l['titre']}</h3>
  <ul class="liste-fonctions">{liste}</ul>
  <p class="note">{l['elvui']}</p>
  <p class="note"><a href="{l['tout_url']}">{l['tout']}</a></p>
</section>'''


def bloc_profils(t, c):
    p = t['profils']
    cartes = []
    for profil in c['profils']:
        x = p['items'][profil['id']]
        code = code_partage(profil['reglages'])
        reglages = ''.join('<li>%s</li>' % r for r in x['reglages'])
        cartes.append(f'''<article class="profil">
      <h3>{x['nom']}</h3>
      <p>{x['pour']}</p>
      <ul>{reglages}</ul>
      <label class="code"><span class="visuel-cache">{p['code']} : {x['nom']}</span><input type="text" readonly value="{attr(code)}" spellcheck="false"></label>
      <div class="profil-boutons">
        <button type="button" class="petit plein" data-copier data-copie="{attr(p['copie'])}" data-evenement="profil-{profil['id']}">{p['copier']}</button>
        <a class="petit" href="#demo" data-essayer='{attr(json.dumps(profil['demo']))}'>{p['essayer']}</a>
      </div>
    </article>''')
    return f'''<section id="profils" class="profils conteneur" aria-labelledby="titre-profils">
  <h2 id="titre-profils">{p['titre']}</h2>
  <p class="sous-titre">{p['intro']}</p>
  <div class="profils-grille">{''.join(cartes)}</div>
</section>'''


def bloc_voies(t, c):
    v = t['voies']
    cartes = ''.join(f'''<article class="voie voie-{x['classe']}"><canvas data-classe="{x['classe']}" aria-hidden="true"></canvas><h3>{x['nom']}</h3><p>{x['texte']}</p></article>'''
                     for x in v['items'])
    return f'''<section id="voies" class="conteneur" aria-labelledby="titre-voies">
  <h2 id="titre-voies">{v['titre']}</h2>
  <p class="sous-titre">{v['intro']}</p>
  <div class="voies">{cartes}</div>
</section>'''


def bloc_pourquoi(t, c):
    p = t['pourquoi']
    forces = ''.join('<li>%s</li>' % x for x in p['forces'])
    limites = ''.join('<li>%s</li>' % x for x in p['limites'])
    return f'''<section class="pourquoi conteneur" aria-labelledby="titre-pourquoi">
  <h2 id="titre-pourquoi">{p['titre']}</h2>
  <p class="sous-titre">{p['intro']}</p>
  <div class="pourquoi-grille">
    <div class="forces"><h3>{p['forces_titre']}</h3><ul>{forces}</ul></div>
    <div class="limites"><h3>{p['limites_titre']}</h3><ul>{limites}</ul></div>
  </div>
</section>'''


def bloc_runes(t, c):
    r = t['runes']
    mots, mot = [], []
    for rune in runes(r['phrase']) + [None]:
        if rune is None:
            if mot:
                mots.append('<span class="mot">%s</span>' % ''.join(mot)); mot = []
            continue
        fichier, lettre = rune
        mot.append(f'<span class="rune" data-lettre="{lettre}"><img src="{c["racine"]}images/runes/{fichier}.png" alt="" width="32" height="32" loading="lazy"><b>{lettre}</b></span>')
    return f'''<section class="runes conteneur" aria-labelledby="titre-runes">
  <h2 id="titre-runes">{r['titre']}</h2>
  <p class="sous-titre">{r['intro']}</p>
  <div class="inscription" tabindex="0" role="img" aria-label="{attr(r['phrase'])}">{''.join(mots)}</div>
  <blockquote lang="{'fr' if c['lang'] == 'fr' else 'en'}">{r['citation']}<small>{r['source']}</small></blockquote>
  <p>{r['texte']}</p>
</section>'''


def bloc_nouveautes(t, c):
    n = t['nouveautes']
    versions = []
    for version, date, rubriques in journal(n['fichier']):
        corps = ''.join('<h4>%s</h4><ul>%s</ul>' % (html.escape(nom), ''.join('<li>%s</li>' % markdown_ligne(l) for l in lignes))
                        for nom, lignes in rubriques)
        quand = ('%s %s' % (n['le'], date_lisible(date, c['lang']))).strip()
        versions.append(f'<article class="version-bloc"><h3>{version} <time datetime="{date}">{quand}</time></h3>{corps}</article>')
    return f'''<section class="nouveautes conteneur" aria-labelledby="titre-nouveautes">
  <h2 id="titre-nouveautes">{n['titre']}</h2>
  <p class="sous-titre">{n['intro']}</p>
  <div class="versions">{''.join(versions)}</div>
  <p class="note"><a href="{n['journal_url']}">{n['journal']}</a></p>
</section>'''


def bloc_installation(t, c):
    i = t['installation']
    etapes = ''.join('<li>%s</li>' % e for e in i['etapes'])
    lignes = ''.join('<tr><td><code>%s</code></td><td>%s</td></tr>' % (html.escape(a), b) for a, b in i['commandes'])
    return f'''<section id="installation" class="installation conteneur" aria-labelledby="titre-installation">
  <h2 id="titre-installation">{i['titre']}</h2>
  <p class="sous-titre">{i['intro']}</p>
  <ol class="etapes">{etapes}</ol>
  <h3 class="liste-titre">{i['commandes_titre']}</h3>
  <table><thead><tr><th scope="col">{i['commande']}</th><th scope="col">{i['effet']}</th></tr></thead><tbody>{lignes}</tbody></table>
</section>'''


def bloc_faq(t, c):
    q = t['faq']
    items = ''.join('<details><summary>%s</summary><p>%s</p></details>' % (a, html.escape(b, quote=False)) for a, b in q['items'])
    return f'''<section id="questions" class="faq conteneur" aria-labelledby="titre-faq">
  <h2 id="titre-faq">{q['titre']}</h2>
  {items}
</section>'''


def bloc_auteur(t, c):
    a = t['auteur']
    texte = ''.join('<p>%s</p>' % x for x in a['texte'])
    return f'''<section class="auteur conteneur" aria-labelledby="titre-auteur">
  <h2 id="titre-auteur">{a['titre']}</h2>
  {texte}
  <div class="rangee centre">
    <a class="plateforme principale" href="https://discord.gg/uRaEPTGePu" data-evenement="discord">{a['discord']}</a>
    <a class="plateforme" href="https://github.com/BellaHealFr/Lyorune/issues/new/choose">{a['bug']}</a>
  </div>
</section>'''


def bloc_presse(t, c):
    p = t['presse']
    r = c['racine']
    fichiers = [
        ('images/logo.png', p['logo']), ('images/captures/banniere.jpg', p['banniere']),
        ('images/captures/cases.jpg', p['cases']), ('images/captures/options.png', p['options']),
        ('images/piliers.png', p['piliers']), ('images/runes.png', p['runes']),
        ('presse/presentation.txt', p['textes']),
    ]
    liens = ''.join(f'<li><a href="{r}{f}" download>{nom}</a></li>' for f, nom in fichiers)
    return f'''<section id="presse" class="presse conteneur" aria-labelledby="titre-presse">
  <h2 id="titre-presse">{p['titre']}</h2>
  <p class="sous-titre">{p['intro']}</p>
  <div class="presse-grille">
    <div>
      <a class="plateforme principale" href="{r}presse/lyorune-kit-presse.zip" download data-evenement="kit-presse">{p['archive']}</a>
      <h3>{p['fichiers']}</h3>
      <ul>{liens}</ul>
    </div>
    <div class="textes-presse">
      <h3>{p['court_titre']}</h3><p>{p['court']}</p>
      <h3>{p['long_titre']}</h3><p>{p['long']}</p>
    </div>
  </div>
</section>'''


def jsonld(t, c):
    faq = [{'@type': 'Question', 'name': a, 'acceptedAnswer': {'@type': 'Answer', 'text': b}} for a, b in t['faq']['items']]
    principale = c['principale_url']
    graphe = {
        '@context': 'https://schema.org',
        '@graph': [
            {
                '@type': 'SoftwareApplication', '@id': principale + '#addon', 'name': 'Lyorune',
                'alternateName': 'Lyorune healing frames', 'description': t['meta']['description'],
                'url': c['canonique'], 'image': principale + 'images/logo.png',
                'applicationCategory': 'GameApplication', 'applicationSubCategory': 'World of Warcraft addon',
                'operatingSystem': 'Windows, macOS', 'softwareVersion': c['version'], 'dateModified': c['date_iso'],
                'inLanguage': ['fr', 'en'], 'isAccessibleForFree': True,
                'offers': {'@type': 'Offer', 'price': '0', 'priceCurrency': 'EUR'},
                'downloadUrl': 'https://github.com/BellaHealFr/Lyorune/releases/latest',
                'codeRepository': 'https://github.com/BellaHealFr/Lyorune',
                'releaseNotes': t['nouveautes']['journal_url'],
                'softwareRequirements': 'World of Warcraft: Forever (interface 16001)',
                'author': {'@id': principale + '#auteur'},
                'sameAs': ['https://github.com/BellaHealFr/Lyorune', 'https://www.curseforge.com/wow/addons/lyorune-healing',
                           'https://addons.wago.io/addons/lyorune', 'https://www.wowinterface.com/downloads/info27323-Lyorune.html'],
                'keywords': t['meta']['keywords'], 'gamePlatform': 'World of Warcraft: Forever',
            },
            {'@type': 'Person', '@id': principale + '#auteur', 'name': 'BellaDroode', 'url': 'https://github.com/BellaHealFr'},
            {'@type': 'WebSite', '@id': principale + '#site', 'url': principale, 'name': 'Lyorune', 'inLanguage': t['lang']},
            {'@type': 'FAQPage', 'inLanguage': t['lang'], 'mainEntity': faq},
        ],
    }
    return json.dumps(graphe, ensure_ascii=False, indent=2).replace('</', '<\\/')


def page(t, autre, cible, commun):
    lang = t['lang']
    url = cible['url']
    principale_url = next(x['url'] for x in CIBLES.values() if x['principale'])
    chemin_base = re.sub(r'^https?://[^/]+', '', url)
    c = dict(commun)
    c.update({
        'lang': lang,
        'racine': '../' if t['chemin'] else './',
        'url': url,
        'canonique': principale_url + t['chemin'],
        'principale_url': principale_url,
        'date': date_lisible(commun['date_iso'], lang),
    })
    v = {
        'lang': lang, 'titre': html.escape(t['meta']['title']), 'description': attr(t['meta']['description']),
        'keywords': attr(t['meta']['keywords']), 'canonique': c['canonique'],
        'url_fr': url, 'url_en': url + 'en/', 'url': url,
        'locale': t['locale'], 'locale_autre': autre['locale'],
        'og_titre': attr(t['meta']['og_title']), 'og_description': attr(t['meta']['og_description']),
        'og_alt': attr(t['meta']['og_alt']), 'image_partage': url + 'images/partage-%s.png' % lang,
        'racine': c['racine'], 'racine_langue': './', 'build': c['build'], 'jsonld': jsonld(t, c),
        'lien_autre': c['racine'] + autre['chemin'] if autre['chemin'] else c['racine'],
        'lang_autre': autre['lang'], 'autre_lien': t['autre_lien'],
        'journal_url': t['nouveautes']['journal_url'],
    }
    for cle, texte in t['nav'].items():
        v['nav_' + cle] = texte
    for cle, texte in t['pied'].items():
        v['pied_' + cle] = texte
    for nom in ('accueil', 'demo', 'video', 'coup', 'fonctions', 'profils', 'voies', 'pourquoi', 'runes',
                'nouveautes', 'installation', 'faq', 'auteur', 'presse'):
        v[nom] = globals()['bloc_' + nom](t, c)
    config = {
        'lang': lang, 'textes': t['demo'], 'themes': commun['themes'],
        'goatcounter': cible['goatcounter'], 'cible': commun['cible'],
        'visites': [t['pied']['visites_un'], t['pied']['visites']], 'mois': MOIS[lang],
        # chemins comptés par GoatCounter pour les deux pages de cette cible (« /Lyorune » et « /Lyorune/en » sur GitHub)
        'chemins': [chemin_base.rstrip('/') or '/', chemin_base + 'en'],
    }
    v['config'] = json.dumps(config, ensure_ascii=False).replace('</', '<\\/')
    if cible['goatcounter']:
        v['statistiques'] = ('<script data-goatcounter="https://%s.goatcounter.com/count" async '
                             'src="https://gc.zgo.at/count.js"></script>' % cible['goatcounter'])
        v['compteur'] = '<p class="visites"><span id="visites" hidden></span> <small>%s</small></p>' % t['pied']['compteur']
    else:
        v['statistiques'] = ''
        v['compteur'] = ''
    gabarit = lire('site', 'src', 'page.html')
    manquants = set(re.findall(r'\{\{(\w+)\}\}', gabarit)) - set(v)
    if manquants:
        raise SystemExit('Gabarit : valeurs manquantes ' + ', '.join(sorted(manquants)))
    return re.sub(r'\{\{(\w+)\}\}', lambda m: str(v[m.group(1)]), gabarit)


def page_404(textes, cible, commun):
    fr, en = textes['fr'], textes['en']
    base = re.sub(r'^https?://[^/]+', '', cible['url'])  # chemin absolu : la page 404 est servie à toute adresse
    return f'''<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Hors de portée · Out of range · Lyorune</title>
<meta name="robots" content="noindex">
<link rel="icon" type="image/png" href="{base}images/logo.png">
<link rel="stylesheet" href="{base}style.css?v={commun['build']}">
</head>
<body class="page-404">
<main class="conteneur perdu">
  <div class="case-perdue" aria-hidden="true"><span>?</span><i></i></div>
  <h1>Hors de portée</h1>
  <p>Cette page est trop loin pour être soignée : elle n'existe pas, ou elle a changé d'adresse.</p>
  <p><a class="plateforme principale" href="{base}">Revenir au groupe</a></p>
  <h2 lang="en">Out of range</h2>
  <p lang="en">This page is out of healing range: it doesn't exist, or it has moved.</p>
  <p lang="en"><a class="plateforme" href="{base}en/">Back to the group</a></p>
</main>
</body>
</html>
'''


def sitemap(cible, date_iso):
    url = cible['url']
    lignes = ['<?xml version="1.0" encoding="UTF-8"?>',
              '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">']
    for adresse in (url, url + 'en/'):
        lignes += ['  <url>', '    <loc>%s</loc>' % adresse, '    <lastmod>%s</lastmod>' % date_iso,
                   '    <xhtml:link rel="alternate" hreflang="fr" href="%s"/>' % url,
                   '    <xhtml:link rel="alternate" hreflang="en" href="%sen/"/>' % url,
                   '    <xhtml:link rel="alternate" hreflang="x-default" href="%sen/"/>' % url, '  </url>']
    return '\n'.join(lignes + ['</urlset>', ''])


def presse(sortie, textes):
    """Kit presse : textes de présentation et archive avec les images."""
    lignes = []
    for lang in LANGUES:
        p = textes[lang]['presse']
        lignes += ['Lyorune (%s)' % ('français' if lang == 'fr' else 'English'), '',
                   p['court_titre'], p['court'], '', p['long_titre'], p['long'], '', '']
    lignes.append('https://github.com/BellaHealFr/Lyorune')
    ecrire(os.path.join(sortie, 'presse', 'presentation.txt'), '\n'.join(lignes) + '\n')
    archive = os.path.join(sortie, 'presse', 'lyorune-kit-presse.zip')
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
        z.write(os.path.join(sortie, 'presse', 'presentation.txt'), 'presentation.txt')
        for f in ('logo.png', 'piliers.png', 'runes.png', 'captures/banniere.jpg', 'captures/cases.jpg',
                  'captures/options.png'):
            z.write(os.path.join(sortie, 'images', f), f.replace('captures/', ''))


def entetes_cloudflare():
    csp = ("default-src 'self'; img-src 'self' data:; style-src 'self' https://fonts.googleapis.com; "
           "font-src https://fonts.gstatic.com; script-src 'self' https://gc.zgo.at; "
           "connect-src 'self' https://api.github.com https://*.goatcounter.com; frame-ancestors 'none'; base-uri 'self'")
    return '\n'.join([
        '/*',
        '  X-Content-Type-Options: nosniff',
        '  Referrer-Policy: strict-origin-when-cross-origin',
        '  Permissions-Policy: camera=(), microphone=(), geolocation=(), interest-cohort=()',
        '  X-Frame-Options: DENY',
        '  Content-Security-Policy: ' + csp,
        '/style.css',
        '  Cache-Control: public, max-age=31536000, immutable',
        '/site.js',
        '  Cache-Control: public, max-age=31536000, immutable',
        '/images/*',
        '  Cache-Control: public, max-age=604800',
        '/presse/*',
        '  Cache-Control: public, max-age=86400',
        '',
    ])


def fabriquer(nom, sortie=None):
    cible = dict(CIBLES[nom])
    sortie = os.path.abspath(sortie or os.path.join(ICI, 'dist-' + nom))
    # garde-fou : seul un dossier vide ou une ancienne sortie de ce script est vidé, jamais le dépôt ni ses sources
    if os.path.commonpath([sortie, ICI]) == sortie or os.path.commonpath([sortie, SRC]) == SRC:
        raise SystemExit('Dossier de sortie refusé : ' + sortie)
    if os.path.isdir(sortie) and os.listdir(sortie) and not os.path.exists(os.path.join(sortie, 'sitemap.xml')):
        raise SystemExit('Dossier de sortie refusé (ni vide ni ancienne sortie du site) : ' + sortie)
    os.makedirs(sortie, exist_ok=True)
    for f in os.listdir(sortie):  # vidé, pas supprimé : un serveur local peut s'y trouver
        chemin = os.path.join(sortie, f)
        shutil.rmtree(chemin) if os.path.isdir(chemin) else os.remove(chemin)
    textes = {lang: json.loads(lire('site', 'src', 'textes', lang + '.json')) for lang in LANGUES}
    profils = json.loads(lire('site', 'src', 'profils.json'))['profils']
    date_iso = journal('CHANGELOG.md', 1)[0][1]
    commun = {'version': version_addon(), 'date_iso': date_iso, 'build': numero_build(), 'themes': themes(),
              'profils': profils, 'cible': nom}

    # images : un seul exemplaire dans le dépôt (docs/images), plus les images de partage du site
    os.makedirs(os.path.join(sortie, 'images'))
    for f in os.listdir(IMAGES):
        if f.endswith('.png'):
            shutil.copy2(os.path.join(IMAGES, f), os.path.join(sortie, 'images', f))
    for dossier in ('runes', 'piliers', 'captures'):
        shutil.copytree(os.path.join(IMAGES, dossier), os.path.join(sortie, 'images', dossier),
                        ignore=shutil.ignore_patterns('*.md'))
    for f in os.listdir(os.path.join(SRC, 'images')):
        shutil.copy2(os.path.join(SRC, 'images', f), os.path.join(sortie, 'images', f))
    if os.path.isdir(os.path.join(SRC, 'medias')):
        shutil.copytree(os.path.join(SRC, 'medias'), os.path.join(sortie, 'medias'))
    for f in ('style.css', 'site.js'):
        shutil.copy2(os.path.join(SRC, f), os.path.join(sortie, f))

    for lang in LANGUES:
        t, autre = textes[lang], textes['en' if lang == 'fr' else 'fr']
        ecrire(os.path.join(sortie, t['chemin'], 'index.html'), page(t, autre, cible, commun))
    ecrire(os.path.join(sortie, '404.html'), page_404(textes, cible, commun))
    ecrire(os.path.join(sortie, 'sitemap.xml'), sitemap(cible, date_iso))
    ecrire(os.path.join(sortie, 'robots.txt'), 'User-agent: *\nAllow: /\n\nSitemap: %ssitemap.xml\n' % cible['url'])
    ecrire(os.path.join(sortie, 'llms.txt'), lire('site', 'src', 'llms.txt').replace('{{url}}', cible['url']).replace('{{version}}', commun['version']))
    presse(sortie, textes)
    if nom == 'github':
        ecrire(os.path.join(sortie, '.nojekyll'), '')
    else:
        ecrire(os.path.join(sortie, '_headers'), entetes_cloudflare())
    return sortie


if __name__ == '__main__':
    if len(sys.argv) < 2 or sys.argv[1] not in CIBLES:
        raise SystemExit('Usage : python outils/site.py github|cloudflare [dossier de sortie]')
    print(fabriquer(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None))
