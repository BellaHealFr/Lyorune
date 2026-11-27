# Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
# Test du site de présentation : fabrique les deux cibles (GitHub Pages et Cloudflare) dans un dossier temporaire
# et vérifie ce que docs/ANTI-IA.md promet. Chaque ligne doit commencer par OK. Code de sortie 1 si une étape échoue.
#   python tests/site.py
import codecs, glob, html.parser, importlib.util, json, os, re, sys, tempfile

ICI = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
spec = importlib.util.spec_from_file_location('site_lyorune', os.path.join(ICI, 'outils', 'site.py'))
site = importlib.util.module_from_spec(spec)
spec.loader.exec_module(site)

ECHECS = []
INTERDITS = [
    # tirets longs, textes de remplissage, liens vides
    chr(0x2014), chr(0x2013), 'lorem', 'href="#"', 'TODO',
    # formules creuses (docs/ANTI-IA.md)
    'Découvrez', 'Plongez', 'Libérez', "L'expérience ultime", 'Révolutionnaire', 'Sans effort', "N'hésitez pas",
    'Dans un monde où', 'unleash', 'elevate', 'seamless', 'game-changer', 'dive into', 'supercharge',
    "in today's", 'not just',
]
# aucun nom d'autre addon (seuls ElvUI et Clique, cités de façon neutre) : la liste est codée en ROT13 pour que ces
# noms ne soient jamais écrits en clair dans le dépôt
INTERDITS += [codecs.decode(n, 'rot13') for n in ('IhuQb', 'UrnyObg', 'Tevq2', 'UrnyXvg', 'CnyylCbjre', 'Qrphefvir', 'JrnxNhenf', 'Cyrkhf', 'urnyxvg')]


def etape(nom, erreurs):
    print(('  OK    ' if not erreurs else '  ERREUR ') + nom + ('' if not erreurs else ' : ' + '; '.join(erreurs[:6])))
    if erreurs:
        ECHECS.append(nom)


class Lecteur(html.parser.HTMLParser):
    def __init__(self):
        super().__init__()
        self.liens, self.images, self.h1, self.jsonld, self.lang, self._json = [], [], 0, [], None, None

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == 'html':
            self.lang = a.get('lang')
        if tag == 'h1':
            self.h1 += 1
        if tag == 'img':
            self.images.append(a)
        for cle in ('href', 'src'):
            if cle in a and tag in ('a', 'img', 'link', 'script', 'source', 'video'):
                self.liens.append(a[cle])
        if tag == 'script' and a.get('type') == 'application/ld+json':
            self._json = ''

    def handle_data(self, data):
        if self._json is not None:
            self._json += data

    def handle_endtag(self, tag):
        if tag == 'script' and self._json is not None:
            self.jsonld.append(self._json)
            self._json = None


def verifier(nom, dossier):
    url = site.CIBLES[nom]['url']
    autre = [c['url'] for n, c in site.CIBLES.items() if n != nom][0]
    pages = [os.path.join(dossier, 'index.html'), os.path.join(dossier, 'en', 'index.html')]

    erreurs = []
    for chemin in glob.glob(os.path.join(dossier, '**', '*'), recursive=True):
        if chemin.endswith(('.html', '.txt', '.xml', '.js', '.css', '_headers')):
            texte = open(chemin, encoding='utf-8').read()
            for mot in INTERDITS:
                if mot in texte and not (mot == 'TODO' and chemin.endswith('.js')):
                    erreurs.append('%s dans %s' % (mot, os.path.relpath(chemin, dossier)))
    etape('%s : aucun tiret long, formule creuse, texte de remplissage ni nom d\'autre addon' % nom, erreurs)

    contenus = [open(p, encoding='utf-8').read() for p in pages]
    erreurs = []
    for page, contenu in zip(pages, contenus):
        lecteur = Lecteur()
        lecteur.feed(contenu)
        base = os.path.dirname(page)
        for lien in lecteur.liens:
            if re.match(r'^(https?:|mailto:|#)', lien):
                continue
            cible = os.path.normpath(os.path.join(base, lien.split('?')[0].split('#')[0]))
            if os.path.isdir(cible):
                cible = os.path.join(cible, 'index.html')
            if not os.path.exists(cible):
                erreurs.append('lien cassé %s dans %s' % (lien, os.path.relpath(page, dossier)))
        for img in lecteur.images:
            if 'alt' not in img:
                erreurs.append('image sans alt %s' % img.get('src'))
            if not img.get('width') or not img.get('height'):
                erreurs.append('image sans dimensions %s' % img.get('src'))
        if lecteur.h1 != 1:
            erreurs.append('%d titres h1 dans %s' % (lecteur.h1, os.path.relpath(page, dossier)))
        if lecteur.lang not in ('fr', 'en'):
            erreurs.append('langue absente')
        for bloc in lecteur.jsonld:
            try:
                json.loads(bloc)
            except ValueError as e:
                erreurs.append('données structurées illisibles : %s' % e)
    etape('%s : liens, images, titre et données structurées des deux langues' % nom, erreurs)

    erreurs = []
    fr, en = contenus
    principale = [c['url'] for c in site.CIBLES.values() if c['principale']][0]
    for texte, lang, chemin in ((fr, 'fr', ''), (en, 'en', 'en/')):
        if '<link rel="canonical" href="%s%s">' % (principale, chemin) not in texte:
            erreurs.append('canonical %s' % lang)
        for h, adresse in (('fr', url), ('en', url + 'en/'), ('x-default', url + 'en/')):
            if '<link rel="alternate" hreflang="%s" href="%s">' % (h, adresse) not in texte:
                erreurs.append('hreflang %s absent ou faux (%s)' % (h, lang))
        if 'images/partage-%s.png' % lang not in texte:
            erreurs.append('image de partage %s' % lang)
        # aucune adresse de l'autre cible, sauf le canonical (et og:url, son double) et les données structurées,
        # qui désignent la page principale
        reste = re.sub(r'<link rel="canonical"[^>]*>|<meta property="og:url"[^>]*>', '', texte)
        reste = re.sub(r'<script type="application/ld\+json">.*?</script>', '', reste, flags=re.S)
        if autre in reste:
            erreurs.append('adresse de l\'autre cible dans la page %s' % lang)
    # parité : mêmes sections, dans le même ordre
    sections = lambda t: re.findall(r'<section[^>]*class="([^"]*)"', t)
    if sections(fr) != sections(en):
        erreurs.append('sections différentes entre le français et l\'anglais')
    for f in ('sitemap.xml', 'robots.txt', 'llms.txt'):
        if autre in open(os.path.join(dossier, f), encoding='utf-8').read():
            erreurs.append('adresse de l\'autre cible dans %s' % f)
    if url not in open(os.path.join(dossier, 'sitemap.xml'), encoding='utf-8').read():
        erreurs.append('sitemap sans sa propre adresse')
    etape('%s : canonical, hreflang, parité des langues, aucune adresse de l\'autre cible' % nom, erreurs)

    erreurs = []
    for f in ('404.html', 'presse/lyorune-kit-presse.zip', 'presse/presentation.txt', 'images/partage-fr.png',
              'images/partage-en.png', 'images/logo.png', 'site.js', 'style.css'):
        if not os.path.exists(os.path.join(dossier, f)):
            erreurs.append(f + ' absent')
    extra = '.nojekyll' if nom == 'github' else '_headers'
    if not os.path.exists(os.path.join(dossier, extra)):
        erreurs.append(extra + ' absent')
    etape('%s : kit presse, images de partage, page 404 et fichiers d\'hébergement' % nom, erreurs)


def textes():
    """Les deux fichiers de textes ont exactement les mêmes clés : aucune langue n'a une section de moins."""
    def cles(v, prefixe=''):
        if isinstance(v, dict):
            return {c for k, x in v.items() for c in cles(x, prefixe + '.' + k)} | {prefixe}
        if isinstance(v, list):
            return {c for i, x in enumerate(v) for c in cles(x, '%s[%d]' % (prefixe, i))} | {prefixe}
        return {prefixe}
    fr = json.load(open(os.path.join(ICI, 'site', 'src', 'textes', 'fr.json'), encoding='utf-8'))
    en = json.load(open(os.path.join(ICI, 'site', 'src', 'textes', 'en.json'), encoding='utf-8'))
    difference = sorted(cles(fr) ^ cles(en))
    etape('textes : mêmes clés en français et en anglais', difference)


textes()
for nom in site.CIBLES:
    with tempfile.TemporaryDirectory() as dossier:
        site.fabriquer(nom, dossier)
        verifier(nom, dossier)
sys.exit(1 if ECHECS else 0)
