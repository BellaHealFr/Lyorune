# Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
# Dessine les images des angles arrondis des cases (réglage « Angles des cases ») :
#   Media/Angle.tga   un rectangle plein aux coins arrondis (fond de la case, fond d'un groupe)
#   Media/Angle1.tga  son contour, 1 pixel d'épaisseur (bordure)
#   Media/Angle2.tga  son contour, 2 pixels d'épaisseur (bordure épaisse, contour lumineux)
#   pip install pillow
#   python outils/angles.py
# Blanc sur fond transparent : la couleur est donnée en jeu. Le jeu étire le milieu de l'image et garde les coins
# à leur taille (SetTextureSliceMargins), MARGE doit donc rester la même que dans UI.lua.
import os
from PIL import Image, ImageDraw

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
TAILLE, RAYON, MARGE, LOUPE = 16, 5, 6, 8


def dessiner(epaisseur):
    grand = TAILLE * LOUPE
    image = Image.new('L', (grand, grand), 0)
    dessin = ImageDraw.Draw(image)
    dessin.rounded_rectangle((0, 0, grand - 1, grand - 1), radius=RAYON * LOUPE, fill=255)
    if epaisseur:
        creux = epaisseur * LOUPE
        dessin.rounded_rectangle((creux, creux, grand - 1 - creux, grand - 1 - creux),
                                 radius=(RAYON - epaisseur) * LOUPE, fill=0)
    masque = image.resize((TAILLE, TAILLE), Image.BOX)
    sortie = Image.new('RGBA', (TAILLE, TAILLE), (255, 255, 255, 0))
    sortie.putalpha(masque)
    return sortie


def main():
    for nom, epaisseur in (('Angle', 0), ('Angle1', 1), ('Angle2', 2)):
        chemin = os.path.join(ROOT, 'Media', nom + '.tga')
        dessiner(epaisseur).save(chemin)
        print('Media/%s.tga : %d x %d, rayon %d' % (nom, TAILLE, TAILLE, RAYON))


if __name__ == '__main__':
    main()
