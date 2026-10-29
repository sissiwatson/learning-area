#!/usr/bin/env python3
"""Génère les graphismes provisoires (originaux) de la carte de Mahana.

Sorties (dans assets/) :
  tiles/terrain_atlas.png  8 tuiles iso 128×64 : océan, lagon, sable, herbe,
                           jungle, chemin, parcelle constructible, voile verrouillé
  tiles/decor_atlas.png    2 décors 128×160 : palmier, buisson
  buildings/bungalow_hibiscus.png  bungalow sur 2×2 cellules (256×256, pied du
                           bâtiment = centre de l'emprise au pixel (128, 192))
  ui/icon_shells.png, ui/icon_pineapple.png, ui/icon_welcome_basket.png
                           icônes 96×96 de l'interface

Le tirage aléatoire est fixé : relancer le script redonne les mêmes images.
Usage : python3 tools/generate_placeholder_art.py   (nécessite Pillow)
"""
from pathlib import Path
import math
import random

from PIL import Image, ImageDraw

TW, TH = 128, 64
ROOT = Path(__file__).resolve().parent.parent / "assets" / "tiles"


def inside(x, y, shrink=0.0):
    """Le pixel (x, y) est-il dans le losange iso (bords jointifs) ?"""
    return abs(x + 0.5 - TW / 2) / (TW / 2 - shrink * 2) + abs(y + 0.5 - TH / 2) / (TH / 2 - shrink) <= 1.0 + 1e-6


def base_tile(color, rng, speckle=None, speckle_count=0, shade=10):
    img = Image.new("RGBA", (TW, TH), (0, 0, 0, 0))
    px = img.load()
    r0, g0, b0 = color
    for y in range(TH):
        for x in range(TW):
            if inside(x, y):
                # léger dégradé vertical pour donner du relief
                k = 1.0 + (TH / 2 - y) / TH * shade / 100
                n = rng.randint(-4, 4)
                px[x, y] = (clamp(r0 * k + n), clamp(g0 * k + n), clamp(b0 * k + n), 255)
    if speckle:
        for _ in range(speckle_count):
            x, y = rng.randrange(TW), rng.randrange(TH)
            if inside(x, y, shrink=3) and inside(x + 2, y, shrink=3):
                px[x, y] = speckle + (255,)
                px[x + 1, y] = speckle + (255,)
    return img


def clamp(v):
    return max(0, min(255, int(v)))


def ocean(rng):
    img = base_tile((29, 111, 163), rng, shade=6)
    d = ImageDraw.Draw(img)
    for _ in range(5):
        x, y = rng.randrange(20, 100), rng.randrange(14, 50)
        if inside(x, y, 6) and inside(x + 14, y, 6):
            d.arc((x, y, x + 14, y + 6), 200, 340, fill=(120, 190, 225, 255), width=2)
    return img


def lagoon(rng):
    return base_tile((60, 193, 200), rng, speckle=(150, 230, 230), speckle_count=40, shade=6)


def sand(rng):
    return base_tile((240, 217, 160), rng, speckle=(212, 184, 125), speckle_count=60)


def grass(rng):
    img = base_tile((108, 191, 79), rng, shade=8)
    d = ImageDraw.Draw(img)
    for _ in range(45):
        x, y = rng.randrange(TW), rng.randrange(TH)
        if inside(x, y, 4) and inside(x, y - 4, 4):
            d.line((x, y, x + rng.choice((-1, 1)), y - 3), fill=(76, 150, 58, 255))
    return img


def jungle(rng):
    return base_tile((63, 154, 69), rng, speckle=(40, 115, 50), speckle_count=90, shade=8)


def path(rng):
    img = base_tile((210, 168, 107), rng, shade=4)
    d = ImageDraw.Draw(img)
    for _ in range(14):
        x, y = rng.randrange(TW), rng.randrange(TH)
        if inside(x, y, 6) and inside(x + 4, y + 2, 6):
            d.ellipse((x, y, x + 4, y + 2), fill=(178, 140, 92, 255))
    return img


def plot(rng):
    img = base_tile((181, 134, 90), rng, speckle=(150, 108, 70), speckle_count=50, shade=4)
    d = ImageDraw.Draw(img)
    # pointillés intérieurs : signale une parcelle constructible
    pts = [(64, 9), (110, 32), (64, 55), (18, 32), (64, 9)]
    for (x1, y1), (x2, y2) in zip(pts, pts[1:]):
        for i in range(0, 10, 2):
            a, b = i / 10, (i + 1) / 10
            d.line((x1 + (x2 - x1) * a, y1 + (y2 - y1) * a, x1 + (x2 - x1) * b, y1 + (y2 - y1) * b),
                   fill=(248, 236, 210, 255), width=2)
    return img


def locked(rng):
    img = Image.new("RGBA", (TW, TH), (0, 0, 0, 0))
    px = img.load()
    for y in range(TH):
        for x in range(TW):
            if inside(x, y):
                hatch = (x + 2 * y) % 16 < 3
                px[x, y] = (40, 40, 60, 150) if hatch else (20, 20, 35, 110)
    return img


def palm(rng):
    img = Image.new("RGBA", (TW, 160), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    base = (64, 128)  # pied du palmier = centre de la tuile (128 - 32 + 32)
    d.ellipse((40, 120, 88, 136), fill=(0, 0, 0, 60))  # ombre
    top = (74, 40)
    prev = base
    for i in range(1, 11):  # tronc légèrement courbé
        t = i / 10
        x = base[0] + (top[0] - base[0]) * t + math.sin(t * math.pi) * 6
        y = base[1] + (top[1] - base[1]) * t
        d.line((prev, (x, y)), fill=(122, 75, 42, 255), width=int(9 - 4 * t))
        prev = (x, y)
    for ang in (200, 240, 290, 330, 20, 160):
        a = math.radians(ang)
        tip = (top[0] + math.cos(a) * 40, top[1] + math.sin(a) * 22 + 12)
        mid = (top[0] + math.cos(a) * 22, top[1] + math.sin(a) * 12 - 6)
        d.polygon([top, mid, tip, (mid[0], mid[1] + 9)], fill=(50, 150, 62, 255))
        d.line((top, mid, tip), fill=(34, 112, 48, 255), width=2)
    d.ellipse((68, 38, 76, 46), fill=(110, 70, 30, 255))  # noix de coco
    return img


def bush(rng):
    img = Image.new("RGBA", (TW, 160), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse((38, 118, 90, 136), fill=(0, 0, 0, 60))
    for cx, cy, r in ((52, 114, 16), (76, 114, 16), (64, 102, 18), (64, 118, 16)):
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(58, 140, 60, 255), outline=(36, 104, 44, 255), width=2)
    for cx, cy in ((56, 100), (74, 108), (60, 116)):
        d.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=(232, 72, 110, 255))  # fleurs d'hibiscus
    return img


def iso(x, y, z=0.0):
    """Coordonnées d'emprise (0..2 cellules) et hauteur → pixels d'une image 256×256."""
    return (128 + (x - y) * 64, 128 + (x + y) * 32 - z)


def box(d, x0, y0, x1, y1, z0, z1, top, right, left):
    """Pavé iso : dessine les faces visibles (dessus, face +x, face +y)."""
    d.polygon([iso(x1, y0, z0), iso(x1, y1, z0), iso(x1, y1, z1), iso(x1, y0, z1)], fill=right)
    d.polygon([iso(x0, y1, z0), iso(x1, y1, z0), iso(x1, y1, z1), iso(x0, y1, z1)], fill=left)
    d.polygon([iso(x0, y0, z1), iso(x1, y0, z1), iso(x1, y1, z1), iso(x0, y1, z1)], fill=top)


def bungalow_hibiscus():
    img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon([iso(0.1, 0.1), iso(1.95, 0.1), iso(1.95, 1.95), iso(0.1, 1.95)], fill=(0, 0, 0, 50))  # ombre
    box(d, 0.15, 0.15, 1.85, 1.85, 0, 10, (196, 150, 98, 255), (150, 108, 66, 255), (170, 124, 78, 255))  # terrasse
    for i in range(1, 7):  # lames de la terrasse
        t = 0.15 + i * 1.7 / 7
        d.line((iso(t, 0.15, 10), iso(t, 1.85, 10)), fill=(170, 126, 80, 255), width=1)
    box(d, 0.45, 0.45, 1.55, 1.55, 10, 78, (230, 200, 150, 255), (205, 168, 116, 255), (232, 196, 142, 255))  # murs
    # porte (face +y) et fenêtre (face +x), encadrements turquoise
    d.polygon([iso(0.85, 1.55, 10), iso(1.15, 1.55, 10), iso(1.15, 1.55, 54), iso(0.85, 1.55, 54)], fill=(40, 150, 160, 255))
    d.polygon([iso(0.9, 1.55, 12), iso(1.1, 1.55, 12), iso(1.1, 1.55, 50), iso(0.9, 1.55, 50)], fill=(120, 72, 40, 255))
    d.polygon([iso(1.55, 0.75, 34), iso(1.55, 1.25, 34), iso(1.55, 1.25, 62), iso(1.55, 0.75, 62)], fill=(40, 150, 160, 255))
    d.polygon([iso(1.55, 0.8, 37), iso(1.55, 1.2, 37), iso(1.55, 1.2, 59), iso(1.55, 0.8, 59)], fill=(170, 225, 240, 255))
    # toit de chaume à quatre pans
    e0, e1, ze, apex = 0.25, 1.75, 74, iso(1.0, 1.0, 150)
    back = (196, 150, 60, 255)
    d.polygon([iso(e0, e0, ze), iso(e1, e0, ze), apex], fill=back)
    d.polygon([iso(e0, e0, ze), iso(e0, e1, ze), apex], fill=back)
    d.polygon([iso(e1, e0, ze), iso(e1, e1, ze), apex], fill=(206, 160, 66, 255))
    d.polygon([iso(e0, e1, ze), iso(e1, e1, ze), apex], fill=(232, 190, 92, 255))
    for k in range(1, 6):  # rangs de chaume
        t = k / 6
        a = (apex[0] + (iso(e0, e1, ze)[0] - apex[0]) * t, apex[1] + (iso(e0, e1, ze)[1] - apex[1]) * t)
        b = (apex[0] + (iso(e1, e1, ze)[0] - apex[0]) * t, apex[1] + (iso(e1, e1, ze)[1] - apex[1]) * t)
        c = (apex[0] + (iso(e1, e0, ze)[0] - apex[0]) * t, apex[1] + (iso(e1, e0, ze)[1] - apex[1]) * t)
        d.line((a, b, c), fill=(190, 140, 50, 255), width=2)
    # massif d'hibiscus devant la terrasse
    for cx, cy in (iso(1.95, 1.2), iso(1.95, 1.55), iso(1.75, 1.85)):
        d.ellipse((cx - 13, cy - 22, cx + 13, cy + 2), fill=(58, 140, 60, 255), outline=(36, 104, 44, 255), width=2)
        d.ellipse((cx - 5, cy - 16, cx + 3, cy - 8), fill=(232, 60, 100, 255))
    return img


def icon_shells():
    img = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # coquille en éventail : secteur centré sur la charnière, côtes rayonnantes
    hinge = (48, 80)
    d.pieslice((6, 38, 90, 122), 200, 340, fill=(248, 196, 150, 255), outline=(196, 120, 80, 255), width=3)
    for k in range(-3, 4):
        a = math.radians(270 + k * 18)
        d.line((hinge, (hinge[0] + math.cos(a) * 40, hinge[1] + math.sin(a) * 40)), fill=(218, 146, 100, 255), width=3)
    d.polygon([(36, 92), (40, 78), (56, 78), (60, 92)], fill=(232, 164, 120, 255), outline=(196, 120, 80, 255))
    return img


def icon_pineapple():
    img = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for dx, h in ((-14, 30), (0, 38), (14, 30), (-7, 34), (7, 34)):  # couronne
        d.polygon([(48 + dx - 6, 36), (48 + dx, 36 - h), (48 + dx + 6, 36)], fill=(60, 160, 70, 255), outline=(36, 110, 46, 255))
    d.ellipse((24, 32, 72, 92), fill=(240, 186, 50, 255), outline=(176, 120, 30, 255), width=3)
    for k in range(-3, 4):  # motif en losanges
        d.line(((48 + k * 10 - 20, 36), (48 + k * 10 + 20, 90)), fill=(196, 140, 36, 255), width=2)
        d.line(((48 + k * 10 + 20, 36), (48 + k * 10 - 20, 90)), fill=(196, 140, 36, 255), width=2)
    d.ellipse((24, 32, 72, 92), outline=(176, 120, 30, 255), width=3)
    img2 = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    mask = Image.new("L", (96, 96), 0)
    ImageDraw.Draw(mask).ellipse((24, 32, 72, 92), fill=255)
    ImageDraw.Draw(mask).rectangle((0, 0, 96, 33), fill=255)
    img2.paste(img, (0, 0), mask)
    return img2


def icon_welcome_basket():
    img = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.arc((22, 10, 74, 70), 180, 360, fill=(150, 100, 50, 255), width=6)  # anse
    d.ellipse((30, 30, 52, 52), fill=(240, 186, 50, 255))  # fruits
    d.ellipse((46, 28, 68, 50), fill=(232, 60, 100, 255))
    d.ellipse((38, 24, 56, 42), fill=(120, 190, 70, 255))
    d.polygon([(14, 44), (82, 44), (72, 88), (24, 88)], fill=(196, 146, 80, 255), outline=(130, 86, 40, 255))
    for y in range(50, 88, 8):  # tressage
        d.line(((16 + (y - 44) * 0.2, y), (80 - (y - 44) * 0.2, y)), fill=(150, 104, 52, 255), width=2)
    for x in range(26, 74, 10):
        d.line(((x, 46), (x + (48 - x) * 0.15, 86)), fill=(170, 120, 62, 255), width=2)
    return img


def main():
    ROOT.mkdir(parents=True, exist_ok=True)
    rng = random.Random(1987)
    tiles = [ocean, lagoon, sand, grass, jungle, path, plot, locked]
    atlas = Image.new("RGBA", (TW * 4, TH * 2), (0, 0, 0, 0))
    for i, fn in enumerate(tiles):
        atlas.paste(fn(rng), ((i % 4) * TW, (i // 4) * TH))
    atlas.save(ROOT / "terrain_atlas.png")

    decor = Image.new("RGBA", (TW * 2, 160), (0, 0, 0, 0))
    for i, fn in enumerate((palm, bush)):
        decor.paste(fn(rng), (i * TW, 0))
    decor.save(ROOT / "decor_atlas.png")
    buildings = ROOT.parent / "buildings"
    buildings.mkdir(parents=True, exist_ok=True)
    bungalow_hibiscus().save(buildings / "bungalow_hibiscus.png")
    ui = ROOT.parent / "ui"
    ui.mkdir(parents=True, exist_ok=True)
    icon_shells().save(ui / "icon_shells.png")
    icon_pineapple().save(ui / "icon_pineapple.png")
    icon_welcome_basket().save(ui / "icon_welcome_basket.png")
    print("Écrit : assets/tiles/*.png, assets/buildings/*.png, assets/ui/icon_*.png")


if __name__ == "__main__":
    main()
