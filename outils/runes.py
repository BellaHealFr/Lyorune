# Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
# Dessine Media/Runes.tga : les 24 runes de l'ancien futhark (alphabet historique), tracées trait par trait.
#   pip install pillow
#   python outils/runes.py
# Grille de 8 colonnes sur 4 lignes, cases de 16 pixels, blanc sur fond transparent (la couleur est donnée en jeu).
# L'ordre des runes doit rester celui de la table « letters » de Runes.lua.
import os
from PIL import Image, ImageDraw

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
CASE, COLONNES, LIGNES, LOUPE = 16, 8, 4, 8

# Chaque rune : une liste de traits, chaque trait une suite de points (x, y) entre 0 et 1, y vers le bas
RUNES = [
    ('f',  [[(.3, 0), (.3, 1)], [(.3, .5), (.8, .2)], [(.3, .25), (.7, 0)]]),
    ('u',  [[(.25, 1), (.25, 0), (.75, .4), (.75, 1)]]),
    ('th', [[(.3, 0), (.3, 1)], [(.3, .25), (.7, .5), (.3, .75)]]),
    ('a',  [[(.3, 0), (.3, 1)], [(.3, 0), (.75, .3)], [(.3, .3), (.75, .6)]]),
    ('r',  [[(.3, 0), (.3, 1)], [(.3, 0), (.7, .25), (.3, .5), (.75, 1)]]),
    ('k',  [[(.7, .15), (.3, .5), (.7, .85)]]),
    ('g',  [[(.2, 0), (.8, 1)], [(.8, 0), (.2, 1)]]),
    ('w',  [[(.3, 0), (.3, 1)], [(.3, 0), (.7, .25), (.3, .5)]]),
    ('h',  [[(.25, 0), (.25, 1)], [(.75, 0), (.75, 1)], [(.25, .35), (.75, .65)]]),
    ('n',  [[(.5, 0), (.5, 1)], [(.25, .35), (.75, .65)]]),
    ('i',  [[(.5, 0), (.5, 1)]]),
    ('j',  [[(.55, .1), (.25, .35), (.55, .6)], [(.45, .4), (.75, .65), (.45, .9)]]),
    ('p',  [[(.3, 0), (.3, 1)], [(.3, 0), (.55, .2), (.8, 0)], [(.3, 1), (.55, .8), (.8, 1)]]),
    ('s',  [[(.7, 0), (.3, .33), (.7, .66), (.3, 1)]]),
    ('t',  [[(.5, 0), (.5, 1)], [(.5, 0), (.2, .3)], [(.5, 0), (.8, .3)]]),
    ('b',  [[(.3, 0), (.3, 1)], [(.3, 0), (.7, .25), (.3, .5), (.7, .75), (.3, 1)]]),
    ('e',  [[(.2, 1), (.2, 0), (.5, .3), (.8, 0), (.8, 1)]]),
    ('m',  [[(.2, 1), (.2, 0), (.8, .5)], [(.8, 1), (.8, 0), (.2, .5)]]),
    ('l',  [[(.35, 1), (.35, 0), (.7, .35)]]),
    ('ng', [[(.5, .2), (.8, .5), (.5, .8), (.2, .5), (.5, .2)]]),
    ('d',  [[(.2, 0), (.2, 1)], [(.8, 0), (.8, 1)], [(.2, 0), (.8, 1)], [(.2, 1), (.8, 0)]]),
    ('o',  [[(.5, 0), (.8, .35), (.2, 1)], [(.5, 0), (.2, .35), (.8, 1)]]),
    ('z',  [[(.5, 0), (.5, 1)], [(.5, .45), (.2, .05)], [(.5, .45), (.8, .05)]]),
    ('y',  [[(.5, 0), (.5, 1)], [(.5, 0), (.75, .25)], [(.5, 1), (.25, .75)]]),
]


def main():
    grand = CASE * LOUPE
    marge, trait = grand * 0.14, int(grand * 0.105)
    image = Image.new('L', (COLONNES * grand, LIGNES * grand), 0)
    dessin = ImageDraw.Draw(image)
    for index, (_, traits) in enumerate(RUNES):
        ox, oy = (index % COLONNES) * grand, (index // COLONNES) * grand
        for points in traits:
            pixels = [(ox + marge + x * (grand - 2 * marge), oy + marge + y * (grand - 2 * marge)) for x, y in points]
            dessin.line(pixels, fill=255, width=trait, joint='curve')
            for px, py in pixels:  # bouts arrondis
                dessin.ellipse((px - trait / 2, py - trait / 2, px + trait / 2, py + trait / 2), fill=255)
    alpha = image.resize((COLONNES * CASE, LIGNES * CASE), Image.LANCZOS)
    sortie = Image.new('RGBA', alpha.size, (255, 255, 255, 0))
    sortie.putalpha(alpha)
    os.makedirs(os.path.join(ROOT, 'Media'), exist_ok=True)
    sortie.save(os.path.join(ROOT, 'Media', 'Runes.tga'))
    print('Media/Runes.tga : %d runes, %d x %d' % (len(RUNES), sortie.width, sortie.height))


if __name__ == '__main__':
    main()
