#!/usr/bin/env python3
"""Génère les graphismes provisoires (originaux) de la carte de Mahana.

Sorties (dans assets/) :
  tiles/terrain_atlas.png  8 tuiles iso 128×64 : océan, lagon, sable, herbe,
                           jungle, chemin, parcelle constructible, voile verrouillé
  tiles/decor_atlas.png    2 décors 128×160 : palmier, buisson

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
    print("Écrit :", ROOT / "terrain_atlas.png", ROOT / "decor_atlas.png")


if __name__ == "__main__":
    main()
