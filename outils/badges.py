# Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
# Dessine les badges des README et de la page de profil (version, téléchargements GitHub, Discord), en images SVG.
#
#   python outils/badges.py DOSSIER
#
# Lancé toutes les heures et après chaque publication par .github/workflows/badges.yml, qui range les images
# sur la branche « badges ». Les pages les affichent directement depuis raw.githubusercontent.com : aucun service
# extérieur à attendre (un service trop lent faisait abandonner GitHub, et le badge s'affichait cassé).
import io, os, sys
from xml.sax.saxutils import escape

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import telechargements

OR, BLEU, VERT, GRIS, DISCORD = '#d4a94e', '#1e90ff', '#3fb950', '#555', '#5865f2'


def largeur(texte):
    """Largeur approchée du texte en police de 11 pixels (assez juste pour des chiffres et des mots courts)."""
    etroits, larges = ' ,.:;!|il1', 'mwMW'
    return sum(3.5 if c in etroits else 9.5 if c in larges else 7.5 if c.isupper() else 6.8 for c in texte)


def svg(label, message, couleur):
    """Badge à deux parties (étiquette grise, valeur en couleur), ou une seule partie sans étiquette."""
    g = int(largeur(label) + 12) if label else 0
    d = int(largeur(message) + 12)
    w = g + d
    titre = escape('%s : %s' % (label, message) if label else message)
    parts = ['<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="20" role="img" aria-label="%s">' % (w, titre),
             '<title>%s</title>' % titre,
             '<clipPath id="r"><rect width="%d" height="20" rx="3"/></clipPath>' % w,
             '<g clip-path="url(#r)">']
    if label:
        parts.append('<rect width="%d" height="20" fill="%s"/>' % (g, GRIS))
    parts += ['<rect x="%d" width="%d" height="20" fill="%s"/>' % (g, d, couleur), '</g>',
              '<g fill="#fff" text-anchor="middle" font-family="Verdana,DejaVu Sans,sans-serif" font-size="11">']
    if label:
        parts.append('<text x="%.1f" y="14">%s</text>' % (g / 2, escape(label)))
    parts += ['<text x="%.1f" y="14">%s</text>' % (g + d / 2, escape(message)), '</g></svg>']
    return '\n'.join(parts) + '\n'


def ecrire(dossier, nom, texte):
    with io.open(os.path.join(dossier, nom + '.svg'), 'w', encoding='utf-8', newline='\n') as fichier:
        fichier.write(texte)


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
    fr, en = '{:,}'.format(total).replace(',', ' '), '{:,}'.format(total)  # 12 458 et 12,458
    ecrire(dossier, 'version', svg('version', version, OR))
    ecrire(dossier, 'telechargements', svg('téléchargements', fr, OR))
    ecrire(dossier, 'downloads', svg('downloads', en, OR))
    # Bouton Discord (le lien est dans les README), sans nombre de membres
    ecrire(dossier, 'discord', svg('Discord', 'rejoindre', DISCORD))
    ecrire(dossier, 'discord-en', svg('Discord', 'join', DISCORD))
    # Page de profil : sans étiquette, en couleur
    ecrire(dossier, 'profil-version', svg('', version, BLEU))
    ecrire(dossier, 'profil-telechargements', svg('', fr, VERT))
    print('Badges : %s, %d téléchargement(s).' % (version, total))


if __name__ == '__main__':
    main()
