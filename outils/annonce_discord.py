# Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
# Annonce une nouvelle version dans le salon des nouveautés du Discord, avec ses notes en français et en anglais.
#
#   python outils/annonce_discord.py v1.4.0
#       lit RELEASE.md (écrit par « publier.py --notes ») et l'envoie au webhook Discord en deux encadrés
#       (français puis anglais), avec la mention du rôle des alertes.
#       L'adresse du webhook est lue dans la variable d'environnement DISCORD_WEBHOOK (secret du dépôt).
#       Sans cette variable, rien n'est envoyé et la publication continue.
#
#   python outils/annonce_discord.py v1.4.0 --essai
#       affiche le message prêt à envoyer, sans rien envoyer
import io, json, os, re, sys, urllib.request

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
DEPOT = 'https://github.com/BellaHealFr/Lyorune'
ROLE_ALERTES = '1572192211754422413'  # rôle « Alertes Lyorune » du serveur Discord
COULEUR = 0x7C4DFF
LIMITE = 4000  # un encadré Discord accepte 4096 caractères


def notes_markdown(partie):
    # Garde seulement les rubriques (### Ajouté, ### Amélioré...) et leurs lignes, mises en forme pour Discord
    lignes, dedans = [], False
    for ligne in partie.splitlines():
        if ligne.startswith('### '):
            dedans = True
            if lignes:
                lignes.append('')
            lignes.append('**%s**' % ligne[4:].strip())
        elif ligne.startswith('**') or ligne.startswith('# '):
            dedans = False
        elif dedans and ligne.startswith('- '):
            lignes.append('▸ ' + ligne[2:].strip())
    return '\n'.join(lignes)


def couper(texte, suite):
    if len(texte) <= LIMITE:
        return texte
    coupe = texte[:LIMITE].rsplit('\n', 1)[0]
    return coupe + '\n\n' + suite


def message(version):
    texte = io.open(os.path.join(ROOT, 'RELEASE.md'), encoding='utf-8').read()
    numero = version.lstrip('v')
    page = '%s/releases/tag/v%s' % (DEPOT, numero)
    parties = re.split(r'\n---\n', texte, maxsplit=1)
    encadres = [{
        'title': 'Lyorune %s' % numero,
        'url': page,
        'color': COULEUR,
        'description': couper(notes_markdown(parties[0]), '[Toutes les nouveautés](%s)' % page)
                       + '\n\n[Télécharger](%s)' % page,
    }]
    if len(parties) > 1:
        encadres.append({
            'title': 'Lyorune %s (English)' % numero,
            'url': page,
            'color': COULEUR,
            'description': couper(notes_markdown(parties[1]), '[All changes](%s)' % page)
                           + '\n\n[Download](%s)' % page,
        })
    return {
        'content': '<@&%s> Lyorune %s est disponible !' % (ROLE_ALERTES, numero),
        'embeds': encadres,
        'allowed_mentions': {'roles': [ROLE_ALERTES]},
    }


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    if not args:
        sys.exit('Version attendue, par exemple : python outils/annonce_discord.py v1.4.0')
    donnees = message(args[0])
    if '--essai' in sys.argv:
        print(json.dumps(donnees, ensure_ascii=False, indent=2))
        return
    adresse = os.environ.get('DISCORD_WEBHOOK', '').strip()
    if not adresse:
        print('DISCORD_WEBHOOK absent : pas d\'annonce sur Discord.')
        return
    demande = urllib.request.Request(adresse, data=json.dumps(donnees).encode('utf-8'), method='POST',
                                     headers={'Content-Type': 'application/json', 'User-Agent': 'Lyorune-publication'})
    with urllib.request.urlopen(demande, timeout=30) as reponse:
        print('Annonce envoyée sur Discord (code %d).' % reponse.status)


if __name__ == '__main__':
    main()
