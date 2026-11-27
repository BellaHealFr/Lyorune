# Lyorune (c) 2026 BellaDroode. Tous droits réservés, voir LICENSE.
# Dessine les images de partage du site (1200 x 630, une par langue) : site/src/images/partage-fr.png et -en.png.
# À relancer seulement pour changer ces images ; elles se remplacent aussi à la main par n'importe quelle image
# de même nom et de même taille. Demande Pillow (pip install pillow) et les polices Palatino de Windows.
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ICI = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
POLICES = os.path.join(os.environ.get('WINDIR', r'C:\Windows'), 'Fonts')
L, H = 1200, 630
OR, OR_CLAIR, NUIT = (212, 169, 78), (240, 212, 138), (10, 15, 29)
TEXTES = {
    'fr': ('La lumière qui guide chaque soigneur', 'Cadres de soin pour World of Warcraft: Forever',
           'Gratuit · Prêtre, druide, paladin, chaman'),
    'en': ('The light that guides every healer', 'Healing frames for World of Warcraft: Forever',
           'Free · Priest, druid, paladin, shaman'),
}
# Cinq cases : couleur de classe du jeu, vie, soin en route, type à dissiper
CASES = [
    ('Bella', (255, 124, 10), 0.82, 0.10, None),
    ('Yops', (198, 155, 109), 0.46, 0.22, (51, 153, 255)),
    ('Orion', (135, 136, 238), 1.0, 0, None),
    ('Traqueuse', (170, 211, 114), 0.63, 0, (26, 217, 51)),
    ('Azuriel', (0, 112, 221), 0.91, 0, None),
]


def police(nom, taille):
    return ImageFont.truetype(os.path.join(POLICES, nom), taille)


def fond():
    image = Image.new('RGB', (L, H), NUIT)
    halo = Image.new('RGB', (L, H), NUIT)
    d = ImageDraw.Draw(halo)
    d.ellipse((-200, -260, 700, 640), fill=(30, 42, 74))
    d.ellipse((760, 120, 1360, 760), fill=(22, 34, 60))
    return Image.blend(image, halo.filter(ImageFilter.GaussianBlur(120)), 0.9)


def case(d, x, y, l, h, nom, couleur, vie, entrant, dissip, texte):
    d.rectangle((x, y, x + l, y + h), fill=(18, 18, 23))
    d.rectangle((x + 2, y + 2, x + 2 + int((l - 4) * vie), y + h - 9), fill=couleur)
    if entrant:
        x0 = x + 2 + int((l - 4) * vie)
        d.rectangle((x0, y + 2, min(x + l - 2, x0 + int((l - 4) * entrant)), y + h - 9), fill=(115, 255, 153))
    d.rectangle((x + 2, y + h - 7, x + l - 2, y + h - 2), fill=(30, 60, 160))
    d.rectangle((x, y, x + l, y + h), outline=dissip or (0, 0, 0), width=3 if dissip else 1)
    d.text((x + l / 2, y + (h - 9) / 2), nom, font=texte, fill=(255, 255, 255), anchor='mm',
           stroke_width=2, stroke_fill=(0, 0, 0))


def dessiner(lang):
    devise, sous_titre, infos = TEXTES[lang]
    image = fond()
    d = ImageDraw.Draw(image)
    logo = Image.open(os.path.join(ICI, 'docs', 'images', 'logo.png')).convert('RGBA').resize((250, 250), Image.LANCZOS)
    lueur = Image.new('RGBA', (L, H), (0, 0, 0, 0))
    ImageDraw.Draw(lueur).ellipse((60, 70, 380, 390), fill=OR + (70,))
    image.paste(lueur.filter(ImageFilter.GaussianBlur(40)), (0, 0), lueur.filter(ImageFilter.GaussianBlur(40)))
    image.paste(logo, (95, 105), logo)
    d = ImageDraw.Draw(image)
    d.text((410, 92), 'Lyorune', font=police('palab.ttf', 120), fill=OR_CLAIR)
    d.text((414, 236), devise, font=police('palai.ttf', 38), fill=(214, 220, 236))
    d.text((414, 292), sous_titre, font=police('pala.ttf', 30), fill=(160, 172, 198))
    d.text((414, 336), infos, font=police('pala.ttf', 26), fill=OR)
    texte = police('palab.ttf', 22)
    for i, (nom, couleur, vie, entrant, dissip) in enumerate(CASES):
        case(d, 414 + i * 146, 404, 134, 62, nom, couleur, vie, entrant, dissip, texte)
    runes = Image.open(os.path.join(ICI, 'docs', 'images', 'runes.png')).convert('RGBA')
    runes = runes.resize((1100, int(runes.height * 1100 / runes.width)), Image.LANCZOS)
    image.paste(runes, ((L - runes.width) // 2, 520), runes)
    d.rectangle((0, 0, L - 1, H - 1), outline=(60, 72, 104), width=2)
    sortie = os.path.join(ICI, 'site', 'src', 'images', 'partage-%s.png' % lang)
    os.makedirs(os.path.dirname(sortie), exist_ok=True)
    image.save(sortie, optimize=True)
    print(sortie)


if __name__ == '__main__':
    for lang in TEXTES:
        dessiner(lang)
