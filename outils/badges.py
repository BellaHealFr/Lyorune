# Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
# Écrit les chiffres des badges des README et de la page de profil (version, téléchargements GitHub).
#
#   python outils/badges.py DOSSIER
#
# Lancé toutes les heures et après chaque publication par .github/workflows/badges.yml, qui range les fichiers
# sur la branche « badges ». shields.io lit ces petits fichiers : une seule lecture, toujours rapide, au lieu
# d'interroger GitHub à chaque affichage (trop lent, le badge s'affichait cassé).
import io, json, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import telechargements

COULEUR = 'd4a94e'


def badge(dossier, nom, label, message):
    with io.open(os.path.join(dossier, nom + '.json'), 'w', encoding='utf-8', newline='\n') as fichier:
        fichier.write(json.dumps({'schemaVersion': 1, 'label': label, 'message': message, 'color': COULEUR},
                                 ensure_ascii=False) + '\n')


def main():
    if len(sys.argv) != 2:
        sys.exit('Usage : python outils/badges.py DOSSIER')
    dossier = sys.argv[1]
    os.makedirs(dossier, exist_ok=True)
    liste = [r for r in telechargements.releases() if not r['draft'] and not r['prerelease']]
    if not liste:
        sys.exit('Aucune version publiée.')
    total = sum(asset['download_count'] for release in liste for asset in release['assets'])
    version = max(liste, key=lambda r: r['published_at'])['tag_name']
    badge(dossier, 'version', 'version', version)
    badge(dossier, 'telechargements', 'téléchargements', '{:,}'.format(total).replace(',', ' '))  # 12 458
    badge(dossier, 'downloads', 'downloads', '{:,}'.format(total))  # 12,458 (README anglais)
    print('Badges : %s, %d téléchargement(s).' % (version, total))


if __name__ == '__main__':
    main()
