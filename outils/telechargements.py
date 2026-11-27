# Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
# Affiche le nombre de téléchargements de Lyorune sur GitHub, version par version.
#
#   python outils/telechargements.py
#
# GitHub compte chaque téléchargement d'une archive publiée dans « Releases ». Les copies du dépôt
# (git clone) et les téléchargements faits sur CurseForge ou Wago ne sont pas comptés ici : ces
# plateformes affichent leurs propres chiffres sur la page du projet.
import json, os, sys, urllib.request

DEPOT = 'BellaHealFr/Lyorune'


def releases():
    """Versions publiées sur GitHub, avec le nombre de téléchargements de leurs archives (erreur si GitHub ne répond pas)."""
    liste, page = [], 1
    while True:  # GitHub donne au plus 100 versions par page
        url = 'https://api.github.com/repos/%s/releases?per_page=100&page=%d' % (DEPOT, page)
        headers = {'Accept': 'application/vnd.github+json', 'User-Agent': 'lyorune-stats'}
        if os.environ.get('GITHUB_TOKEN'):  # circuit des badges : limite d'appels plus large
            headers['Authorization'] = 'Bearer ' + os.environ['GITHUB_TOKEN']
        request = urllib.request.Request(url, headers=headers)
        morceau = json.load(urllib.request.urlopen(request, timeout=20))
        liste += morceau
        if len(morceau) < 100:
            return liste
        page += 1


def total():
    """Tous les téléchargements GitHub (sert aussi à outils/publier.py pour la page « Les amis de Lyorune »)."""
    return sum(asset['download_count'] for release in releases() for asset in release['assets'])


def main():
    try:
        liste = releases()
    except Exception as error:
        sys.exit('Impossible de lire les versions publiées de %s : %s' % (DEPOT, error))

    somme = 0
    print('%-12s %-12s %s' % ('Version', 'Date', 'Téléchargements'))
    for release in liste:
        count = sum(asset['download_count'] for asset in release['assets'])
        somme += count
        print('%-12s %-12s %d' % (release['tag_name'], release['published_at'][:10], count))
    print('\nTotal : %d téléchargement(s) sur %d version(s).' % (somme, len(liste)))


if __name__ == '__main__':
    main()
