# Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
# Range les captures d'écran dans la page du projet (README.md et README.en.md).
#
#   pip install pillow
#   python outils/captures.py
#
# Mode d'emploi :
#   1. Déposez vos captures dans docs/images/captures/ avec les noms de la liste CAPTURES ci-dessous
#      (extension .jpg ou .png). Seules celles qui existent sont affichées.
#   2. Lancez cette commande : les images trop larges sont réduites, et la galerie est réécrite
#      entre les lignes « captures:debut » et « captures:fin » des deux pages.
# Ne jamais inventer d'image : ce sont de vraies captures du jeu, prises par l'auteur.
import io, os, sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
DOSSIER = os.path.join(ROOT, 'docs', 'images', 'captures')
LARGEUR_MAX = 1600

# (nom du fichier sans extension, légende française, légende anglaise)
CAPTURES = [
    ('groupe', 'En donjon : tout le groupe sous les yeux', 'In a dungeon: the whole group at a glance'),
    ('raid', 'En raid : 25 ou 40 joueurs, toujours lisibles', 'In a raid: 25 or 40 players, still readable'),
    ('dissipation', 'Une case se colore : vous pouvez dissiper', 'A frame lights up: you can dispel'),
    ('options', 'Les options : chaque réglage a sa case à cocher', 'The options: every setting has its checkbox'),
    ('clics', 'Vos sorts sur vos clics, en choisissant leur icône', 'Your spells on your clicks, picked by icon'),
    ('themes', 'Cinq thèmes pour accorder Lyorune à votre interface', 'Five themes to match your interface'),
    ('minicarte', 'Le bouton de la mini-carte', 'The minimap button'),
    ('runes', 'Les runes et leur traduction', 'The runes and their translation'),
]


def fichier(nom):
    for extension in ('.jpg', '.jpeg', '.png'):
        if os.path.exists(os.path.join(DOSSIER, nom + extension)):
            return nom + extension
    return None


def reduire(nom):
    from PIL import Image
    chemin = os.path.join(DOSSIER, nom)
    image = Image.open(chemin)
    if image.width > LARGEUR_MAX:
        hauteur = round(image.height * LARGEUR_MAX / image.width)
        image = image.resize((LARGEUR_MAX, hauteur), Image.LANCZOS)
        image.save(chemin, quality=90)
        print('  réduite :', nom)


def galerie(presentes, langue):
    if not presentes:
        return ''
    titre = '## 📸 En images' if langue == 'fr' else '## 📸 Screenshots'
    lignes = [titre, '', '<table>']
    for debut in range(0, len(presentes), 2):
        lignes.append('<tr>')
        for nom, francais, anglais in presentes[debut:debut + 2]:
            legende = francais if langue == 'fr' else anglais
            lignes.append('<td width="50%%" align="center"><img src="docs/images/captures/%s" alt="%s"><br><em>%s</em></td>' % (nom, legende, legende))
        lignes.append('</tr>')
    lignes += ['</table>', '']
    return '\n'.join(lignes)


def ecrire(page, bloc):
    chemin = os.path.join(ROOT, page)
    texte = io.open(chemin, encoding='utf-8').read()
    debut, fin = '<!-- captures:debut -->\n', '<!-- captures:fin -->'
    if debut not in texte or fin not in texte:
        sys.exit('%s : les lignes « captures:debut » et « captures:fin » sont introuvables.' % page)
    avant, reste = texte.split(debut, 1)
    apres = reste.split(fin, 1)[1]
    io.open(chemin, 'w', encoding='utf-8', newline='\n').write(avant + debut + bloc + fin + apres)


def main():
    os.makedirs(DOSSIER, exist_ok=True)
    presentes = []
    for nom, francais, anglais in CAPTURES:
        trouve = fichier(nom)
        if trouve:
            reduire(trouve)
            presentes.append((trouve, francais, anglais))
    ecrire('README.md', galerie(presentes, 'fr'))
    ecrire('README.en.md', galerie(presentes, 'en'))
    print('%d capture(s) affichée(s) sur %d attendues.' % (len(presentes), len(CAPTURES)))
    manquantes = [nom for nom, _, _ in CAPTURES if not fichier(nom)]
    if manquantes:
        print('Pas encore fournies : ' + ', '.join(manquantes))


if __name__ == '__main__':
    main()
