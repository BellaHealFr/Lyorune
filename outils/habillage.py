# Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
# Dessine les images des thèmes de fenêtre (Media/Theme*.tga) : plaques, onglets, champs et cases.
#   pip install pillow
#   python outils/habillage.py
# Chaque image est découpée en 9 par le jeu (SetTextureSliceMargins, marge MARGE) : les bords gardent leur
# taille, le milieu s'étire. Les couleurs sont dans l'image (pas de teinte en jeu), tailles en puissances de 2.
#   MMORPG    : ThemeMMOPlaque, ThemeMMOPlaqueClic, ThemeMMOOnglet, ThemeMMOOngletActif, ThemeMMOChamp, ThemeMMOCase
#   Classique : ThemeClassiqueOnglet, ThemeClassiqueOngletActif, ThemeClassiqueChamp
import os, random
from PIL import Image, ImageDraw

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
MARGE = 6     # doit rester égale à SLICE dans UI.lua
LOUPE = 4     # dessin en grand puis réduction : bords nets et doux


def degrade(largeur, hauteur, haut, bas):
    image = Image.new('RGBA', (largeur, hauteur))
    for y in range(hauteur):
        t = y / max(1, hauteur - 1)
        couleur = tuple(int(haut[i] + (bas[i] - haut[i]) * t) for i in range(3)) + (255,)
        ImageDraw.Draw(image).line([(0, y), (largeur, y)], fill=couleur)
    return image


def grain(image, force, graine):
    """Léger grain de pierre, toujours le même (graine fixe)."""
    hasard = random.Random(graine)
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            d = hasard.randint(-force, force)
            pixels[x, y] = (max(0, min(255, r + d)), max(0, min(255, g + d)), max(0, min(255, b + d)), a)
    return image


def cadre(dessin, boite, couleurs, rayon=0):
    """Cadre en couches : liste de (épaisseur, couleur haut-gauche, couleur bas-droite)."""
    x0, y0, x1, y1 = boite
    for epaisseur, clair, sombre in couleurs:
        for i in range(epaisseur):
            dessin.line([(x0, y1), (x0, y0), (x1, y0)], fill=clair, width=1)
            dessin.line([(x1, y0), (x1, y1), (x0, y1)], fill=sombre, width=1)
            x0, y0, x1, y1 = x0 + 1, y0 + 1, x1 - 1, y1 - 1
    return x0, y0, x1, y1


def arrondir(image, rayon, haut=True, bas=True):
    masque = Image.new('L', image.size, 0)
    ImageDraw.Draw(masque).rounded_rectangle((0, 0, image.width - 1, image.height - 1 + (0 if bas else rayon * 2)),
                                             radius=rayon, fill=255)
    if not haut:
        ImageDraw.Draw(masque).rectangle((0, 0, image.width, rayon * 2), fill=255)
    image.putalpha(masque)
    return image


def finir(image, nom, taille):
    image.resize(taille, Image.LANCZOS).save(os.path.join(ROOT, 'Media', nom + '.tga'))
    print('Media/%s.tga : %d x %d' % (nom, taille[0], taille[1]))


OR_CLAIR, OR_SOMBRE, NUIT = (236, 196, 108, 255), (128, 88, 34, 255), (16, 11, 7, 255)


def plaque_mmo(nom, haut, bas, enfoncee=False):
    """Bouton du grimoire : bronze patiné, liseré noir, biseau doré, rivets aux angles."""
    l, h = 64 * LOUPE, 32 * LOUPE
    image = grain(degrade(l, h, haut, bas), 6, 11)
    dessin = ImageDraw.Draw(image)
    clair, sombre = (OR_SOMBRE, OR_CLAIR) if enfoncee else (OR_CLAIR, OR_SOMBRE)
    cadre(dessin, (0, 0, l - 1, h - 1), [(LOUPE, NUIT, NUIT), (2 * LOUPE, clair, sombre), (LOUPE, (0, 0, 0, 120), (255, 230, 160, 60))])
    for cx in (5 * LOUPE, l - 5 * LOUPE):
        for cy in (5 * LOUPE, h - 5 * LOUPE):
            dessin.ellipse((cx - LOUPE, cy - LOUPE, cx + LOUPE, cy + LOUPE), fill=OR_CLAIR)
    finir(arrondir(image, 3 * LOUPE), nom, (64, 32))


def onglet(nom, haut, bas, bord_clair, bord_sombre, filet=None):
    """Onglet : coins hauts arrondis, ouvert en bas, filet lumineux en haut s'il est actif."""
    l, h = 64 * LOUPE, 32 * LOUPE
    image = grain(degrade(l, h, haut, bas), 4, 23)
    dessin = ImageDraw.Draw(image)
    cadre(dessin, (0, 0, l - 1, h + 4 * LOUPE), [(LOUPE, NUIT, NUIT), (LOUPE, bord_clair, bord_sombre)])
    if filet:
        dessin.rectangle((3 * LOUPE, 2 * LOUPE, l - 3 * LOUPE, 3 * LOUPE), fill=filet)
    finir(arrondir(image, 4 * LOUPE, bas=False), nom, (64, 32))


def champ(nom, fond, ombre, bord_haut, bord_bas):
    """Champ creusé : fond sombre, ombre intérieure en haut à gauche, liseré."""
    l, h = 64 * LOUPE, 32 * LOUPE
    image = degrade(l, h, fond, tuple(min(255, c + 6) for c in fond))
    dessin = ImageDraw.Draw(image)
    x0, y0, x1, y1 = cadre(dessin, (0, 0, l - 1, h - 1), [(LOUPE, bord_haut, bord_bas)])
    for i in range(2 * LOUPE):
        a = int(150 * (1 - i / (2 * LOUPE)))
        dessin.line([(x0 + i, y1), (x0 + i, y0 + i), (x1, y0 + i)], fill=ombre[:3] + (a,))
    finir(image, nom, (64, 32))


def case_mmo(nom):
    """Case à cocher du grimoire : creux sombre aux angles doux, cerclé d'or."""
    c = 32 * LOUPE
    image = Image.new('RGBA', (c, c), (0, 0, 0, 0))
    dessin = ImageDraw.Draw(image)
    dessin.rounded_rectangle((0, 0, c - 1, c - 1), radius=6 * LOUPE, fill=NUIT)
    dessin.rounded_rectangle((LOUPE, LOUPE, c - 1 - LOUPE, c - 1 - LOUPE), radius=5 * LOUPE, fill=OR_SOMBRE)
    dessin.rounded_rectangle((2 * LOUPE, 2 * LOUPE, c - 1 - 2 * LOUPE, c - 1 - 2 * LOUPE), radius=4 * LOUPE, fill=OR_CLAIR)
    dessin.rounded_rectangle((4 * LOUPE, 4 * LOUPE, c - 1 - 4 * LOUPE, c - 1 - 4 * LOUPE), radius=3 * LOUPE, fill=(22, 16, 10, 255))
    finir(image, nom, (32, 32))


def main():
    os.makedirs(os.path.join(ROOT, 'Media'), exist_ok=True)
    plaque_mmo('ThemeMMOPlaque', (88, 64, 38), (38, 26, 16))
    plaque_mmo('ThemeMMOPlaqueClic', (30, 21, 13), (62, 45, 27), enfoncee=True)
    onglet('ThemeMMOOnglet', (52, 38, 24), (26, 18, 11), OR_SOMBRE, (70, 48, 20, 255))
    onglet('ThemeMMOOngletActif', (104, 76, 44), (46, 32, 19), OR_CLAIR, OR_SOMBRE, filet=(255, 214, 120, 255))
    champ('ThemeMMOChamp', (14, 11, 8), (0, 0, 0, 255), (70, 50, 22, 255), (150, 108, 46, 255))
    case_mmo('ThemeMMOCase')
    onglet('ThemeClassiqueOnglet', (58, 58, 58), (24, 24, 24), (120, 120, 120, 255), (40, 40, 40, 255))
    onglet('ThemeClassiqueOngletActif', (92, 84, 66), (36, 34, 30), (170, 170, 170, 255), (60, 60, 60, 255), filet=(255, 209, 0, 255))
    champ('ThemeClassiqueChamp', (8, 8, 8), (0, 0, 0, 255), (44, 44, 44, 255), (128, 128, 128, 255))


if __name__ == '__main__':
    main()
