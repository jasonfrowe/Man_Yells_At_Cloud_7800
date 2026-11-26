#!/usr/bin/env python3
"""The game's graphics: writes the 160A PNGs in src/gfx/ that 7800basic imports.

Run it after changing the art (needs Pillow: .venv/bin/python tools/gfx.py).
The PNGs are committed, so a normal build doesn't need Pillow.

Art is ASCII: '.' = transparent (color 0), 'a' 'b' 'c' = colors 1, 2, 3 of
the sprite's palette. 160A pixels are about twice as wide as they are tall.
Widths must be multiples of 4 (one byte holds four 160A pixels). Sprites are
padded to the 16-line zone height (or a multiple of it).

The font (doublewide: 8 pixels a glyph, 16 lines, one zone), glyph n is
character code 2n:
    0-63    ASCII 32-95 (Spacewar 7800's 8x8 menufont), color 1, lines 4-11
    64-89   tall chrome A-Z for slop title screens: each font line doubled,
            colors 3 / 2 / 1 from the top down (a fake chrome gradient)
    90      the top wall (lines 0-3)
    91      the bottom wall (lines 12-15)
    92      the net (a dash)
    93-111  noise for crash screens
    112-127 the porch: grass, dirt, planks, house wall, rain (4 frames),
            meter bars (empty, 1/4, 1/2, 3/4, full), a star, a lit window
The alphachars line in src/myac.bas must match 0-89.
"""

import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
GFX = ROOT / "src" / "gfx"
FONT_SRC = ROOT / "assets" / "menufont.png"

# Index colors only tell 7800basic which of a palette's colors a pixel uses;
# these RGB values are just for looking at the files.
PNG_PALETTE = [0, 0, 0, 255, 255, 255, 120, 200, 255, 255, 120, 200]
ZONE = 16
NGLYPHS = 128


def image(rows):
    w = len(rows[0])
    assert w % 4 == 0, f"width {w} not a multiple of 4"
    im = Image.new("P", (w, len(rows)), 0)
    im.putpalette(PNG_PALETTE)
    px = im.load()
    for y, r in enumerate(rows):
        assert len(r) == w, f"row {y}: {len(r)} != {w}"
        for x, ch in enumerate(r):
            px[x, y] = ".abc".index(ch)
    return im


def sprite(name, rows):
    """Save a sprite, padded at the bottom to a whole number of zones."""
    w = len(rows[0])
    h = -(-len(rows) // ZONE) * ZONE
    rows = rows + ["." * w] * (h - len(rows))
    image(rows).save(GFX / f"{name}.png", bits=2)


def font():
    src = Image.open(FONT_SRC)
    sp = src.load()
    glyph = lambda c, x, y: bool(sp[c * 8 + x, y])
    g = [["." * 8 for _ in range(ZONE)] for _ in range(NGLYPHS)]
    for i in range(64):
        for y in range(8):
            g[i][4 + y] = "".join("a" if glyph(32 + i, x, y) else "." for x in range(8))
    for i in range(26):
        for y in range(ZONE):
            col = "c" if y < 6 else ("b" if y < 11 else "a")
            g[64 + i][y] = "".join(col if glyph(65 + i, x, y // 2) else "." for x in range(8))
    g[90] = ["aaaaaaaa"] * 4 + ["." * 8] * 12
    g[91] = ["." * 8] * 12 + ["aaaaaaaa"] * 4
    g[92] = ["." * 8] * 4 + ["...bb..."] * 8 + ["." * 8] * 4
    rnd = random.Random(7800)
    for i in range(93, NGLYPHS):
        g[i] = ["".join(rnd.choice("..abc") for _ in range(8)) for _ in range(ZONE)]
    # the porch
    g[112] = ["bbbbbbbb", "abababab", "aaaaaaaa"] + ["aaaaaaaa"] * 13          # grass
    g[113] = ["aaaaaaaa"] * 16                                                # dirt
    g[114] = ["cccccccc", "bbbbbbbb", "bbbbbbbb", "aaaaaaaa"] * 4              # planks
    g[115] = ["bbbbbbba", "bbbbbbba", "aaaaaaaa", "bbbabbbb"] * 4              # siding
    for f in range(4):                                                        # rain
        rows = ["........"] * 16
        for (x, y0) in ((1, 0), (5, 8)):
            for k in range(5):
                y = (y0 + f * 4 + k) % 16
                rows[y] = rows[y][:x] + "c" + rows[y][x + 1:]
        g[116 + f] = rows
    for k in range(5):                                                        # bars
        w = (0, 2, 4, 6, 8)[k]
        bar = "a" * w + "c" * (8 - w) if k else "c" * 8
        g[120 + k] = ["." * 8] * 4 + ["c" + "." * 7 if k == 0 else bar] + [bar] * 6 + ["." * 8] * 5
    g[120] = ["." * 8] * 4 + ["cccccccc"] + ["c......."] * 5 + ["cccccccc"] + ["." * 8] * 5
    g[125] = ["." * 8] * 6 + ["...c....", "..ccc...", "...c...."] + ["." * 8] * 7   # star
    g[126] = ["aaaaaaaa", "accaccca", "accaccca", "aaaaaaaa", "accaccca", "accaccca", "aaaaaaaa"] + ["bbbbbbba"] * 9  # window
    g[127] = ["." * 8] * 16
    rows = ["".join(g[i][y] for i in range(NGLYPHS)) for y in range(ZONE)]
    image(rows).save(GFX / "font.png", bits=2)


# The player's paddle: shiny, 28 lines (its hitbox is the whole thing).
PAD_P = ["aaaa", "abba"] + ["bccb"] * 24 + ["abba", "aaaa"]
# The CPU's paddle doesn't match: plain, 20 lines, and only its top half
# hits the ball (the "terrible hitbox", src/myac.bas).
PAD_C = ["aaaa"] * 20
# The ball: 4 pixels by 6 lines, about round on a TV.
BALL = [".aa.", "abba", "abba", "abba", "abba", ".aa."]
# The ball cut off at a zone's bottom edge (the "forgot the next zone"
# bug): frame n shows the top n + 1 lines.
BALLCUT = [BALL[:n] for n in range(1, 6)]
# What MARIA reads below the ball where holey DMA isn't on: garbage.
GARB = [
    ["abca", "c.b.", ".aca", "b..c", "aacb", ".b.a"],
    ["c.ab", "bca.", "a..c", ".cba", "b.c.", "ca.b"],
]
# ---------------------------------------------------------------------------
# The porch. Arthur, 16 x 32: a skin, b cardigan, c grey (hair, trousers).
ARTHUR_IDLE = [
    "....cccc........", "...cccccc.......", "...caaaac.......", "...aaaaaa.......",
    "...aaacaa.......", "...aaaaaa.......", "....aaaa........", ".....aa.........",
    "...bbbbbb.......", "..bbbbbbbb......", "..bbbbbbbb......", ".bbbbbbbbbb.....",
    ".bb.bbbb.bb.....", ".bb.bbbb.bb.....", ".bb.bbbb.bb.....", ".aa.bbbb.aa.....",
    "....bbbb........", "....bbbb........", "...cccccc.......", "...ccc.ccc......",
    "...ccc.ccc......", "...ccc.ccc......", "...ccc.ccc......", "...ccc.ccc......",
    "...ccc.ccc......", "...ccc.ccc......", "...ccc.ccc......", "...ccc.ccc......",
    "...ccc.ccc......", "...ccc.ccc......", "..bbbb.bbbb.....", "..bbbb.bbbb.....",
]
# yelling: head back, mouth open, a fist up at the sky
ARTHUR_YELL = [
    "....cccc....aa..", "...cccccc...aa..", "...caaaac...bb..", "...aaaaaa...bb..",
    "...aaacaa..bb...", "...aaa..a..bb...", "....aa.a..bb....", ".....aa..bb.....",
    "...bbbbbbbb.....", "..bbbbbbbb......", "..bbbbbbb.......", ".bbbbbbbb.......",
    ".bb.bbbb........", ".bb.bbbb........", ".bb.bbbb........", ".aa.bbbb........",
] + ARTHUR_IDLE[16:]
# winding up: the fist drawn back
ARTHUR_WIND = [
    "....cccc........", "...cccccc.......", "...caaaac.......", "...aaaaaa.......",
    "...aaacaa.......", "...aaaaaa.......", "....aaaa........", ".....aa.........",
    "aa.bbbbbb.......", "abbbbbbbbb......", ".bbbbbbbbb......", "...bbbbbbbb.....",
    "...bbbbb.bb.....", "...bbbbb.bb.....", "....bbbb.bb.....", "....bbbb.aa.....",
] + ARTHUR_IDLE[16:]
# dizzy in the rocking chair (drawn over it)
ARTHUR_SIT = ["................"] * 6 + [
    "....cccc........", "...cccccc.......", "...caaaac.......", "...aaaaaa.......",
    "...acaaca.......", "...aaaaaa.......", "....aaaa........", "...bbbbbb.......",
    "..bbbbbbbb......", "..bbbbbbbb......", ".aabbbbbbaa.....", "...bbbbbb.......",
    "...ccccccccc....", "...cccccccccc...", ".........ccc....", ".........ccc....",
    ".........ccc....", ".........ccc....", "........bbbb....", "........bbbb....",
    "................", "................",
]
CHAIR = (["..cc............"] + ["..cbc..........."] * 17 + ["..cccccccccc...."]
         + ["..c........c...."] * 9 + [".cccccccccccc...", "cc..........cc..", "................", "................"])
# what he yells: a grawlix bubble, 8 x 8
BUBBLE = ["..cccc..", ".cccccc.", "ccaccacc", "cacaacac", "ccaccacc", ".cccccc.", "..cc....", ".c......"]
FIST = ["..aaaa..", ".aaaaaa.", "aacacaca", "aaaaaaaa", "aaaaaaaa", ".aaaaaa.", "..bbbb..", "..bbbb.."]
AIMDOT = ["aa..", "aa.."]
DROP = [".c..", ".c..", "cc..", "cc..", "cc..", ".c.."]
SPLASH = [["....", "....", "c..c", ".cc."], ["c..c", "....", "....", "c..c"]]
SOFTSPOT = ["..aaaa..", ".aaaaaa.", "aaaaaaaa", ".aaaaaa.", "..aaaa.."]


def cloud(scale):
    """The Cloud, 80 x 64 (4 zones; 20 bytes a line, two frames: with the
    font that's two 4K graphics blocks): puffs of circles, lit from the
    upper left: c highlight, b body, a shadow; closed, kind eyes."""
    import math
    W, H = 80, 64
    k = 160 / 192
    puffs = [(round(x * k), y, round(r * 0.9)) for x, y, r in
             [(44, 46, 18), (72, 32, 24), (104, 24, 28), (138, 32, 24), (160, 46, 18),
              (98, 44, 24), (64, 50, 14), (134, 50, 14)]]
    rows = []
    for y in range(H):
        r = ""
        for x in range(W):
            X, Y = x * 2 + 1, y + 0.5
            best = None
            for cx, cy, rad in puffs:
                cx = 80 + (cx - 80) * scale
                cy = 36 + (cy - 36) * scale
                rad *= scale
                d = math.hypot(X - cx, Y - cy)
                if d <= rad and (best is None or (d / rad) < best[0]):
                    best = (d / rad, (X - cx) / rad, (Y - cy) / rad)
            if best is None or Y > 36 + 22 * scale:
                r += "."
                continue
            _, nx, ny = best
            lit = -0.55 * nx - 0.8 * ny
            r += "c" if lit > 0.45 else ("a" if lit < -0.35 or Y > 36 + 17 * scale else "b")
        rows.append(r)
    # eyes: two small closed arcs, and a soft smile
    for (ex, ey) in ((31, 34), (46, 34)):
        rows[ey] = rows[ey][:ex] + "aaaa" + rows[ey][ex + 4:]
        rows[ey - 1] = rows[ey - 1][:ex - 1] + "a" + rows[ey - 1][ex:ex + 4] + "a" + rows[ey - 1][ex + 5:]
    rows[41] = rows[41][:36] + "a" + rows[41][37:43] + "a" + rows[41][44:]
    rows[42] = rows[42][:37] + "aaaaaa" + rows[42][43:]
    return rows


# Lens-flare sparkles for the title screens, three frames.
SPARK = [
    ["....", ".a..", "....", "...."],
    [".a..", "aca.", ".a..", "...."],
    [".a..", ".a..", "acca", ".a..", ".a.."],
]


def main():
    GFX.mkdir(parents=True, exist_ok=True)
    font()
    sprite("padp", PAD_P)
    sprite("padc", PAD_C)
    sprite("ball", BALL)
    for i, s in enumerate(BALLCUT):
        sprite(f"ballcut{i}", s)
    for i, s in enumerate(GARB):
        sprite(f"garb{i}", s)
    for i, s in enumerate(SPARK):
        sprite(f"spark{i}", s)
    for i, sc in enumerate((0.92, 1.0)):
        sprite(f"cloud{i}", cloud(sc))
    for i, a in enumerate((ARTHUR_IDLE, ARTHUR_YELL, ARTHUR_WIND, ARTHUR_SIT)):
        sprite(f"arthur{i}", a)
    sprite("chair", CHAIR)
    sprite("bubble", BUBBLE)
    sprite("fist", FIST)
    sprite("aimdot", AIMDOT)
    sprite("drop", DROP)
    for i, sp in enumerate(SPLASH):
        sprite(f"splash{i}", sp)
    sprite("softspot", SOFTSPOT)
    print(f"wrote {GFX.relative_to(ROOT)}/: font, padp, padc, ball, ballcut0-4, garb0-1, spark0-2, porch")


if __name__ == "__main__":
    main()
