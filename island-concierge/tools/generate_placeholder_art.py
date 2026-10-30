#!/usr/bin/env python3
"""Génère les graphismes provisoires (originaux) de la carte de Mahana.

Sorties (dans assets/) :
  tiles/terrain_atlas.png  8 tuiles iso 128×64 : océan, lagon, sable, herbe,
                           jungle, chemin, parcelle constructible, voile verrouillé
  tiles/decor_atlas.png    2 décors 128×160 : palmier, buisson
  buildings/bungalow_hibiscus.png  bungalow sur 2×2 cellules (256×256, pied du
                           bâtiment = centre de l'emprise au pixel (128, 192))
  buildings/<id>.png       autres bâtiments de Mahana (bureau, atelier, plantation 3×3,
                           emplacement et tiki bar, Bungalow Corail) ; pied au pixel
                           (fp × 64, 128 + fp × 32) pour une emprise fp × fp
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


class Canvas:
    """Image pour un bâtiment d'emprise fp × fp, avec 128 px de hauteur libre."""

    def __init__(self, fp=2, extra=128):
        self.fp, self.extra = fp, extra
        self.img = Image.new("RGBA", (fp * 128, extra + fp * 64), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)

    def iso(self, x, y, z=0.0):
        return (self.fp * 64 + (x - y) * 64, self.extra + (x + y) * 32 - z)

    def box(self, x0, y0, x1, y1, z0, z1, top, right, left):
        i, d = self.iso, self.d
        d.polygon([i(x1, y0, z0), i(x1, y1, z0), i(x1, y1, z1), i(x1, y0, z1)], fill=right)
        d.polygon([i(x0, y1, z0), i(x1, y1, z0), i(x1, y1, z1), i(x0, y1, z1)], fill=left)
        d.polygon([i(x0, y0, z1), i(x1, y0, z1), i(x1, y1, z1), i(x0, y1, z1)], fill=top)

    def shadow(self, m=0.1):
        f = self.fp
        self.d.polygon([self.iso(m, m), self.iso(f - m / 2, m), self.iso(f - m / 2, f - m / 2), self.iso(m, f - m / 2)], fill=(0, 0, 0, 45))

    def hip_roof(self, e0, e1, ze, height, colors):
        i, d = self.iso, self.d
        c = (e0 + e1) / 2
        apex = i(c, c, ze + height)
        d.polygon([i(e0, e0, ze), i(e1, e0, ze), apex], fill=colors[0])
        d.polygon([i(e0, e0, ze), i(e0, e1, ze), apex], fill=colors[0])
        d.polygon([i(e1, e0, ze), i(e1, e1, ze), apex], fill=colors[1])
        d.polygon([i(e0, e1, ze), i(e1, e1, ze), apex], fill=colors[2])
        return apex


def bungalow(walls, walls_dark, trim, roof):
    c = Canvas()
    c.shadow()
    c.box(0.15, 0.15, 1.85, 1.85, 0, 10, (196, 150, 98, 255), (150, 108, 66, 255), (170, 124, 78, 255))
    c.box(0.4, 0.4, 1.6, 1.6, 10, 80, walls, walls_dark, walls)
    i, d = c.iso, c.d
    d.polygon([i(0.85, 1.6, 10), i(1.15, 1.6, 10), i(1.15, 1.6, 54), i(0.85, 1.6, 54)], fill=trim)
    d.polygon([i(1.6, 0.75, 34), i(1.6, 1.25, 34), i(1.6, 1.25, 62), i(1.6, 0.75, 62)], fill=trim)
    d.polygon([i(1.6, 0.8, 37), i(1.6, 1.2, 37), i(1.6, 1.2, 59), i(1.6, 0.8, 59)], fill=(170, 225, 240, 255))
    c.hip_roof(0.2, 1.8, 76, 70, roof)
    return c.img


def bungalow_corail():
    return bungalow((244, 160, 140, 255), (214, 128, 110, 255), (250, 240, 220, 255),
                    ((170, 120, 70, 255), (186, 134, 78, 255), (214, 160, 96, 255)))


def concierge_office():
    c = Canvas()
    c.shadow()
    c.box(0.2, 0.2, 1.8, 1.8, 0, 8, (210, 200, 180, 255), (170, 160, 140, 255), (190, 180, 160, 255))
    c.box(0.35, 0.35, 1.65, 1.65, 8, 92, (246, 244, 236, 255), (214, 210, 200, 255), (236, 232, 222, 255))
    i, d = c.iso, c.d
    for k in range(4):  # auvent rayé sur la façade +y
        x0, x1 = 0.45 + k * 0.3, 0.6 + k * 0.3
        d.polygon([i(x0, 1.65, 70), i(x0 + 0.3, 1.65, 70), i(x0 + 0.3, 1.95, 52), i(x0, 1.95, 52)],
                  fill=(30, 150, 160, 255) if k % 2 == 0 else (250, 250, 245, 255))
    d.polygon([i(0.9, 1.65, 8), i(1.2, 1.65, 8), i(1.2, 1.65, 50), i(0.9, 1.65, 50)], fill=(30, 110, 130, 255))
    for y0 in (0.6, 1.1):  # fenêtres façade +x
        d.polygon([i(1.65, y0, 40), i(1.65, y0 + 0.3, 40), i(1.65, y0 + 0.3, 66), i(1.65, y0, 66)], fill=(150, 210, 230, 255))
    c.hip_roof(0.25, 1.75, 90, 40, ((24, 120, 130, 255), (28, 136, 146, 255), (36, 156, 166, 255)))
    sx, sy = i(1.8, 1.0, 120)  # enseigne : clé dorée
    d.rounded_rectangle((sx - 26, sy - 18, sx + 26, sy + 18), 8, fill=(250, 246, 230, 255), outline=(30, 110, 130, 255), width=3)
    d.ellipse((sx - 16, sy - 8, sx - 2, sy + 6), outline=(220, 170, 40, 255), width=4)
    d.line((sx - 2, sy - 1, sx + 16, sy - 1), fill=(220, 170, 40, 255), width=4)
    d.line((sx + 12, sy - 1, sx + 12, sy + 7), fill=(220, 170, 40, 255), width=3)
    return c.img


def amenities_workshop():
    c = Canvas()
    c.shadow()
    c.box(0.15, 0.15, 1.85, 1.85, 0, 6, (190, 160, 120, 255), (150, 120, 84, 255), (170, 140, 100, 255))
    i, d = c.iso, c.d
    for px, py in ((0.3, 0.3), (1.7, 0.3), (0.3, 1.7), (1.7, 1.7)):  # poteaux
        d.line((i(px, py, 6), i(px, py, 84)), fill=(120, 80, 44, 255), width=7)
    c.box(0.55, 0.9, 1.45, 1.3, 6, 40, (160, 112, 64, 255), (130, 90, 52, 255), (146, 102, 58, 255))  # établi
    for bx, by in ((0.7, 1.0), (1.05, 1.05), (1.3, 1.0)):  # paniers tressés
        x, y = i(bx, by, 40)
        d.ellipse((x - 12, y - 14, x + 12, y + 4), fill=(206, 160, 90, 255), outline=(150, 104, 52, 255), width=2)
    x, y = i(1.6, 1.75, 0)
    d.ellipse((x - 18, y - 30, x + 18, y + 2), fill=(206, 160, 90, 255), outline=(150, 104, 52, 255), width=2)
    c.hip_roof(0.1, 1.9, 82, 66, ((196, 150, 60, 255), (206, 160, 66, 255), (232, 190, 92, 255)))
    return c.img


def pineapple_farm():
    c = Canvas(fp=3, extra=96)
    i, d = c.iso, c.d
    d.polygon([i(0.05, 0.05), i(2.95, 0.05), i(2.95, 2.95), i(0.05, 2.95)], fill=(150, 104, 66, 255))
    for row in range(5):  # rangées de plants
        y = 0.35 + row * 0.55
        for col in range(5):
            x = 0.35 + col * 0.55
            px, py = i(x, y, 0)
            for a in (-60, -30, 0, 30, 60):
                r = math.radians(a - 90)
                d.line((px, py, px + math.cos(r) * 14, py + math.sin(r) * 16), fill=(56, 150, 64, 255), width=3)
            d.ellipse((px - 5, py - 14, px + 5, py - 2), fill=(240, 186, 50, 255), outline=(176, 120, 30, 255))
    for fx, fy in ((0, 0), (3, 0), (0, 3), (3, 3), (1.5, 0), (1.5, 3), (0, 1.5), (3, 1.5)):  # piquets
        x, y = i(fx, fy, 0)
        d.line((x, y, x, y - 22), fill=(120, 80, 44, 255), width=4)
    return c.img


def tiki_bar_site():
    c = Canvas()
    i, d = c.iso, c.d
    d.polygon([i(0.15, 0.15), i(1.85, 0.15), i(1.85, 1.85), i(0.15, 1.85)], fill=(226, 200, 150, 255))
    corners = [(0.25, 0.25), (1.75, 0.25), (1.75, 1.75), (0.25, 1.75)]
    for (ax, ay), (bx, by) in zip(corners, corners[1:] + corners[:1]):  # corde
        d.line((i(ax, ay, 18), i(bx, by, 18)), fill=(230, 120, 60, 255), width=3)
    for px, py in corners:
        d.line((i(px, py, 0), i(px, py, 26)), fill=(120, 80, 44, 255), width=5)
    x, y = i(1.0, 1.0, 0)  # panneau
    d.line((x, y, x, y - 60), fill=(120, 80, 44, 255), width=6)
    d.rounded_rectangle((x - 34, y - 92, x + 34, y - 52), 6, fill=(196, 150, 98, 255), outline=(120, 80, 44, 255), width=3)
    d.line((x - 20, y - 78, x + 20, y - 78), fill=(120, 80, 44, 255), width=3)
    d.line((x - 20, y - 66, x + 10, y - 66), fill=(120, 80, 44, 255), width=3)
    return c.img


def tiki_bar():
    c = Canvas()
    c.shadow()
    i, d = c.iso, c.d
    d.polygon([i(0.15, 0.15), i(1.85, 0.15), i(1.85, 1.85), i(0.15, 1.85)], fill=(196, 150, 98, 255))
    for px, py in ((0.35, 0.35), (1.65, 0.35), (0.35, 1.65), (1.65, 1.65)):
        d.line((i(px, py, 0), i(px, py, 78)), fill=(110, 72, 40, 255), width=7)
    c.box(0.5, 1.1, 1.5, 1.45, 0, 44, (150, 100, 56, 255), (120, 80, 44, 255), (136, 90, 50, 255))  # comptoir
    for k in range(3):  # bambou du comptoir
        x0 = 0.6 + k * 0.32
        d.line((i(x0, 1.45, 4), i(x0, 1.45, 40)), fill=(190, 160, 90, 255), width=3)
    for sx in (0.7, 1.05, 1.4):  # tabourets
        x, y = i(sx, 1.75, 0)
        d.line((x, y, x, y - 22), fill=(110, 72, 40, 255), width=4)
        d.ellipse((x - 10, y - 28, x + 10, y - 18), fill=(232, 60, 100, 255))
    for tx, ty in ((1.95, 0.4), (0.4, 1.95)):  # torches
        x, y = i(tx, ty, 0)
        d.line((x, y, x, y - 70), fill=(110, 72, 40, 255), width=4)
        d.polygon([(x - 7, y - 70), (x, y - 92), (x + 7, y - 70)], fill=(250, 150, 40, 255))
    c.hip_roof(0.15, 1.85, 76, 60, ((196, 150, 60, 255), (206, 160, 66, 255), (232, 190, 92, 255)))
    return c.img


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


def icon_level():
    img = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pts = []
    for k in range(10):
        r = 44 if k % 2 == 0 else 19
        a = math.radians(-90 + k * 36)
        pts.append((48 + math.cos(a) * r, 50 + math.sin(a) * r))
    d.polygon(pts, fill=(250, 196, 50, 255), outline=(190, 120, 20, 255))
    d.line(pts + [pts[0]], fill=(190, 120, 20, 255), width=3)
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
    for fn in (bungalow_corail, concierge_office, amenities_workshop, pineapple_farm, tiki_bar_site, tiki_bar):
        fn().save(buildings / f"{fn.__name__}.png")
    ui = ROOT.parent / "ui"
    ui.mkdir(parents=True, exist_ok=True)
    icon_shells().save(ui / "icon_shells.png")
    icon_pineapple().save(ui / "icon_pineapple.png")
    icon_welcome_basket().save(ui / "icon_welcome_basket.png")
    icon_level().save(ui / "icon_level.png")
    print("Écrit : assets/tiles/*.png, assets/buildings/*.png, assets/ui/icon_*.png")


if __name__ == "__main__":
    main()
