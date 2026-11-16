# Zenith (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
# Affiche le nombre de téléchargements de Zenith sur GitHub, version par version.
#
#   python outils/telechargements.py
#
# GitHub compte chaque téléchargement d'une archive publiée dans « Releases ». Les copies du dépôt
# (git clone) et les téléchargements faits sur CurseForge ou Wago ne sont pas comptés ici : ces
# plateformes affichent leurs propres chiffres sur la page du projet.
import json, sys, urllib.request

DEPOT = 'BellaDroode/Zenith'


def main():
    url = 'https://api.github.com/repos/%s/releases?per_page=100' % DEPOT
    request = urllib.request.Request(url, headers={'Accept': 'application/vnd.github+json', 'User-Agent': 'zenith-stats'})
    try:
        releases = json.load(urllib.request.urlopen(request, timeout=20))
    except Exception as error:
        sys.exit('Impossible de lire les versions publiées de %s : %s' % (DEPOT, error))

    total = 0
    print('%-12s %-12s %s' % ('Version', 'Date', 'Téléchargements'))
    for release in releases:
        count = sum(asset['download_count'] for asset in release['assets'])
        total += count
        print('%-12s %-12s %d' % (release['tag_name'], release['published_at'][:10], count))
    print('\nTotal : %d téléchargement(s) sur %d version(s).' % (total, len(releases)))


if __name__ == '__main__':
    main()
