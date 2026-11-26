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
NGLYPHS = 112


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
    rows = ["".join(g[i][y] for i in range(NGLYPHS)) for y in range(ZONE)]
    image(rows).save(GFX / "font.png", bits=2)


# The player's paddle: shiny, 28 lines (its hitbox is the whole thing).
PAD_P = ["aaaa", "abba"] + ["bccb"] * 24 + ["abba", "aaaa"]
# The CPU's paddle doesn't match: plain, 20 lines, and only its top half
# hits the ball (the "terrible hitbox", src/myac.bas).
PAD_C = ["aaaa"] * 20
# The ball: 4 pixels by 6 lines, about round on a TV.
BALL = [".aa.", "abba", "abba", "abba", "abba", ".aa."]
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
    for i, s in enumerate(SPARK):
        sprite(f"spark{i}", s)
    print(f"wrote {GFX.relative_to(ROOT)}/: font, padp, padc, ball, spark0-2")


if __name__ == "__main__":
    main()
