# Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
# Dessine l'anneau du temps de recharge global autour du curseur (réglage « Temps de recharge global ») :
#   Media/Anneau.tga  un anneau blanc sur fond transparent, la couleur est donnée en jeu
#   pip install pillow
#   python outils/anneau.py
import os
from PIL import Image, ImageDraw

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
TAILLE, EPAISSEUR, LOUPE = 64, 7, 8


def main():
    grand = TAILLE * LOUPE
    image = Image.new('L', (grand, grand), 0)
    dessin = ImageDraw.Draw(image)
    bord = LOUPE
    dessin.ellipse((bord, bord, grand - 1 - bord, grand - 1 - bord), fill=255)
    creux = bord + EPAISSEUR * LOUPE
    dessin.ellipse((creux, creux, grand - 1 - creux, grand - 1 - creux), fill=0)
    masque = image.resize((TAILLE, TAILLE), Image.BOX)
    sortie = Image.new('RGBA', (TAILLE, TAILLE), (255, 255, 255, 0))
    sortie.putalpha(masque)
    sortie.save(os.path.join(ROOT, 'Media', 'Anneau.tga'))
    print('Media/Anneau.tga : %d x %d, épaisseur %d' % (TAILLE, TAILLE, EPAISSEUR))


if __name__ == '__main__':
    main()
