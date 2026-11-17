# Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
# Dessine Media/Runes.tga : les 24 runes de l'ancien futhark (alphabet historique), tracées trait par trait.
#   pip install pillow
#   python outils/runes.py
# Elle dessine aussi les images des effets magiques (Media/MagieCercle.tga, Media/MagieEtincelle.tga).
# La même commande dessine aussi les images de la page du projet : docs/images/runes.png (l'inscription)
# et docs/images/runes/<lettre>.png (une médaille par rune, pour le tableau des fonctions).
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

    # Media/RunesHalo.tga : les mêmes runes, rétrécies puis floues, pour le halo qui les entoure en jeu
    # (affiché deux fois plus grand que la rune, en mode additif)
    from PIL import ImageFilter
    halo = Image.new('L', image.size, 0)
    for index in range(len(RUNES)):
        ox, oy = (index % COLONNES) * grand, (index // COLONNES) * grand
        case = image.crop((ox, oy, ox + grand, oy + grand)).resize((grand // 2, grand // 2), Image.LANCZOS)
        halo.paste(case, (ox + grand // 4, oy + grand // 4))
    halo = halo.filter(ImageFilter.GaussianBlur(grand * 0.06)).point(lambda v: min(255, int(v * 1.6)))
    alpha = halo.resize((COLONNES * CASE * 2, LIGNES * CASE * 2), Image.LANCZOS)
    sortie = Image.new('RGBA', alpha.size, (255, 255, 255, 0))
    sortie.putalpha(alpha)
    sortie.save(os.path.join(ROOT, 'Media', 'RunesHalo.tga'))
    print('Media/RunesHalo.tga : halo flou, %d x %d' % (sortie.width, sortie.height))


INSCRIPTION = 'whomsoever takes up this blade shall wield power eternal'
OR, NUIT, LUEUR = (240, 200, 105), (9, 12, 26), (110, 180, 255)


def tracer(dessin, traits, x, y, largeur, hauteur, epaisseur):
    for points in traits:
        pixels = [(x + px * largeur, y + py * hauteur) for px, py in points]
        dessin.line(pixels, fill=255, width=epaisseur, joint='curve')
        for px, py in pixels:
            dessin.ellipse((px - epaisseur / 2, py - epaisseur / 2, px + epaisseur / 2, py + epaisseur / 2), fill=255)


def dorer(fond, masque, flou):
    """Pose le tracé en or sur le fond, avec une lueur bleutée autour."""
    from PIL import ImageFilter
    lueur = Image.new('RGBA', fond.size, LUEUR + (0,))
    lueur.putalpha(masque.filter(ImageFilter.GaussianBlur(flou)).point(lambda v: int(v * 0.75)))
    trait = Image.new('RGBA', fond.size, OR + (0,))
    trait.putalpha(masque)
    return Image.alpha_composite(Image.alpha_composite(fond, lueur), trait)


def page():
    traits = dict(RUNES)
    dossier = os.path.join(ROOT, 'docs', 'images', 'runes')
    os.makedirs(dossier, exist_ok=True)

    # Une médaille ronde par rune
    taille, k = 96, 4
    grand = taille * k
    for nom, forme in RUNES:
        masque = Image.new('L', (grand, grand), 0)
        tracer(ImageDraw.Draw(masque), forme, grand * 0.31, grand * 0.24, grand * 0.38, grand * 0.52, int(grand * 0.055))
        fond = Image.new('RGBA', (grand, grand), (0, 0, 0, 0))
        dessin = ImageDraw.Draw(fond)
        dessin.ellipse((k, k, grand - k, grand - k), fill=NUIT + (255,), outline=(120, 92, 40, 255), width=3 * k)
        dessin.ellipse((7 * k, 7 * k, grand - 7 * k, grand - 7 * k), outline=(236, 190, 90, 255), width=k)
        dorer(fond, masque, 4 * k).resize((taille, taille), Image.LANCZOS).save(os.path.join(dossier, nom + '.png'), optimize=True)

    # L'inscription complète, sur un bandeau
    signes, i = [], 0
    while i < len(INSCRIPTION):
        if INSCRIPTION[i:i + 2] in traits:
            signes.append(INSCRIPTION[i:i + 2])
            i += 2
        else:
            lettre = INSCRIPTION[i]
            signes.append(None if lettre == ' ' else {'c': 'k', 'q': 'k', 'v': 'u', 'x': 'k'}.get(lettre, lettre))
            i += 1
    case, pas, espace, marge = 30 * k, 25 * k, 17 * k, 28 * k
    largeur = sum(espace if signe is None else pas for signe in signes) + 2 * marge
    hauteur = case + 2 * marge
    masque = Image.new('L', (largeur, hauteur), 0)
    dessin, x = ImageDraw.Draw(masque), marge
    for signe in signes:
        if signe is None:
            x += espace
        else:
            tracer(dessin, traits[signe], x + case * 0.12, marge + case * 0.06, case * 0.76, case * 0.88, int(case * 0.085))
            x += pas
    fond = Image.new('RGBA', (largeur, hauteur), (0, 0, 0, 0))
    ImageDraw.Draw(fond).rounded_rectangle((0, 0, largeur - 1, hauteur - 1), radius=18 * k, fill=NUIT + (255,), outline=(120, 92, 40, 255), width=k)
    image = dorer(fond, masque, 5 * k)
    image.resize((1600, round(hauteur * 1600 / largeur)), Image.LANCZOS).save(os.path.join(ROOT, 'docs', 'images', 'runes.png'), optimize=True)
    print('docs/images : inscription et %d médailles' % len(RUNES))


def magie():
    """Images des effets magiques des fenêtres, blanches sur fond transparent (la couleur du thème est donnée en jeu).
    Media/MagieCercle.tga : cercle runique tournant derrière le logo (deux anneaux, huit runes entre eux).
    Media/MagieEtincelle.tga : point de lumière doux à quatre rayons (particules de l'en-tête, étincelle de soin)."""
    from PIL import ImageFilter
    import math
    traits = dict(RUNES)

    taille, k = 128, 4
    grand = taille * k
    masque = Image.new('L', (grand, grand), 0)
    dessin = ImageDraw.Draw(masque)
    centre = grand / 2
    for rayon, epaisseur in ((0.47, 2.2), (0.30, 1.6)):
        r = grand * rayon
        dessin.ellipse((centre - r, centre - r, centre + r, centre + r), outline=255, width=int(epaisseur * k))
    cote, rayon = grand * 0.12, grand * 0.385
    for n, nom in enumerate(('f', 'u', 'th', 'a', 'r', 'k', 'g', 'w')):
        angle = n * math.pi / 4
        x, y = centre + rayon * math.sin(angle) - cote / 2, centre - rayon * math.cos(angle) - cote / 2
        tracer(dessin, traits[nom], x, y, cote, cote, int(1.8 * k))
    lueur = masque.filter(ImageFilter.GaussianBlur(3 * k)).point(lambda v: int(v * 0.6))
    alpha = Image.composite(masque, lueur, masque).resize((taille, taille), Image.LANCZOS)
    sortie = Image.new('RGBA', alpha.size, (255, 255, 255, 0))
    sortie.putalpha(alpha)
    sortie.save(os.path.join(ROOT, 'Media', 'MagieCercle.tga'))

    taille = 32
    grand = taille * k
    masque = Image.new('L', (grand, grand), 0)
    dessin = ImageDraw.Draw(masque)
    centre = grand / 2
    for rayon, valeur in ((0.40, 60), (0.24, 140), (0.12, 255)):
        r = grand * rayon
        dessin.ellipse((centre - r, centre - r, centre + r, centre + r), fill=valeur)
    masque = masque.filter(ImageFilter.GaussianBlur(grand * 0.08))
    rayons = Image.new('L', (grand, grand), 0)
    dessin = ImageDraw.Draw(rayons)
    for dx, dy in ((1, 0), (0, 1)):
        dessin.line((centre - dx * grand * 0.46, centre - dy * grand * 0.46, centre + dx * grand * 0.46, centre + dy * grand * 0.46), fill=200, width=k)
    rayons = rayons.filter(ImageFilter.GaussianBlur(k * 0.8))
    from PIL import ImageChops
    alpha = ImageChops.lighter(masque, rayons).resize((taille, taille), Image.LANCZOS)
    sortie = Image.new('RGBA', alpha.size, (255, 255, 255, 0))
    sortie.putalpha(alpha)
    sortie.save(os.path.join(ROOT, 'Media', 'MagieEtincelle.tga'))
    print('Media/MagieCercle.tga et Media/MagieEtincelle.tga : effets magiques')


if __name__ == '__main__':
    main()
    magie()
    page()
