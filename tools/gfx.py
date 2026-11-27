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
# The day job's 320A font (src/gen/font320.asm, bank 4 at $A000): 1-byte
# characters, 8 hi-res pixels, 16 lines. MARIA reads a 16-line zone's
# character line L from page 15 - L above CHARBASE, so page p holds glyph
# line 15 - p, and character code c is byte c. Bit 7 is the leftmost pixel.
#   even codes 2n      text: ASCII 32 + n (n 0-63), lines 4-11, so the
#                      7800basic alphadata codes (2 x index) still work
#   odd codes 2i + 1   the punch card (the card is "on" pixels, cream; a
#                      hole is "off", the dark background through it):
#     i 0-11    a column's cell pair: top punched (1), bottom (2), the
#               cursor on the top (4) or the bottom (8): i = t + 2b + 4c,
#               c 0 none, 1 top, 2 bottom
#     i 12-35   the row labels, two card rows a character (12 + 4r + k:
#               text row r, column k), ink ("off") on the card
#     i 36-45   ruler digits 0-9, ink on the card
#     i 46      plain card
# The forum's avatars (codes 128 + 8a + k: 4 characters by 2 rows, k = 4 x
# row + column): 16 x 16 art, each pixel doubled both ways (32 x 32 of
# 320A). One colour each (the poster's palette). Order: tools/forum.py's
# AVATARS.
AVATARS = {
    "arthur": """
................
.....######.....
...##########...
..##........##..
..#..........#..
.##.###..###.##.
.#.#..#..#..#.#.
.#..###..###..#.
.#............#.
.#.....##.....#.
..#..........#..
..#..######..#..
...#.#....#.#...
....#......#....
.....######.....
................""",
    "pixelkid": """
................
....########....
...##########...
...##########...
..############..
...#........#...
...#.##..##.#...
...#.##..##.#...
...#........#...
...#........#...
...#.#....#.#...
...#..####..#...
....#......#....
.....######.....
................
................""",
    "sue": """
................
.....######.....
....#......#....
...#........#...
..############..
..#.##.##.##.#..
..############..
...#........#...
...#........#...
...#...##...#...
...#........#...
...#.######.#...
....#......#....
.....######.....
................
................""",
    "hal": """
................
.....######.....
...##......##...
..#..........#..
.##..........##.
.##.##....##.##.
.##.##....##.##.
.##..........##.
..#....##....#..
..#..........#..
..#.#......#.#..
..#..######..#..
...#........#...
....########....
................
................""",
    "maria": """
................
..#.#.#.#.#.#.#.
.##############.
.#............#.
.#.##.........#.
.#.##.........#.
.#............#.
.#..#.#.###...#.
.#..###.#.#...#.
.#..#.#.###...#.
.#............#.
.#............#.
.##############.
..#.#.#.#.#.#.#.
................
................""",
}

CARD_LABELS = ["LOAD", "ADD ", "CNT ", "LOOP", "OUT ", "  64", "  32", "  16",
               "   8", "   4", "   2", "   1"]


def font320():
    src = Image.open(FONT_SRC)
    sp = src.load()

    def glyph8(ch):
        c = ord(ch)
        return [[bool(sp[c * 8 + x, y]) for x in range(8)] for y in range(8)]

    glyphs = [[[False] * 8 for _ in range(16)] for _ in range(256)]
    for n in range(64):
        g = glyph8(chr(32 + n))
        for y in range(8):
            glyphs[2 * n][4 + y] = g[y]

    def cell(punched, cursor):
        """8 x 8: card, a 4 x 4 hole when punched, a dot when not; the
        cursor: a frame of ink."""
        rows = [[True] * 8 for _ in range(8)]
        if punched:
            for y in range(2, 6):
                for x in range(2, 6):
                    rows[y][x] = False
        else:
            rows[3][3] = rows[3][4] = rows[4][3] = rows[4][4] = False
        if cursor:
            for k in range(8):
                rows[0][k] = rows[7][k] = rows[k][0] = rows[k][7] = False
        return rows

    for i in range(12):
        t, b, c = i & 1, (i >> 1) & 1, i >> 2
        top, bot = cell(t, c == 1), cell(b, c == 2)
        glyphs[2 * i + 1] = top + bot
    inv = lambda g: [[not v for v in row] for row in g]
    for r in range(6):
        for k in range(4):
            i = 12 + 4 * r + k
            glyphs[2 * i + 1] = inv(glyph8(CARD_LABELS[2 * r][k])) + inv(glyph8(CARD_LABELS[2 * r + 1][k]))
    for d in range(10):
        g = glyph8(str(d))
        glyphs[2 * (36 + d) + 1] = [[True] * 8 for _ in range(4)] + inv(g) + [[True] * 8 for _ in range(4)]
    glyphs[2 * 46 + 1] = [[True] * 8 for _ in range(16)]
    for a, art in enumerate(AVATARS.values()):
        rows = art.strip().splitlines()
        assert len(rows) == 16 and all(len(r) == 16 for r in rows), a
        big = [[rows[y // 2][x // 2] == "#" for x in range(32)] for y in range(32)]
        for r in range(2):
            for k in range(4):
                glyphs[128 + 8 * a + 4 * r + k] = [big[16 * r + y][8 * k:8 * k + 8] for y in range(16)]
    out = ["; Generated by tools/gfx.py (font320). Do not edit.",
           "; The 40-column screens' 320A font: page p holds glyph line 15 - p; code c",
           "; is byte c. (At $A000 in each bank that uses it: the day job's, the forum's.)"]
    for p in range(16):
        line = 15 - p
        bytes_ = []
        for c in range(256):
            v = 0
            for x in range(8):
                if glyphs[c][line][x]:
                    v |= 0x80 >> x
            bytes_.append(v)
        for k in range(0, 256, 32):
            out.append("    .byte " + ",".join(str(v) for v in bytes_[k:k + 32]))
    gen = ROOT / "src" / "gen"
    gen.mkdir(exist_ok=True)
    (gen / "font320.asm").write_text("\n".join(out) + "\n")


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
AIMDOT = [".aa.", "aaaa", ".aa."]
# where the yell will reach the Cloud: a crosshair
RETICLE = ["...aa...", "...aa...", "aa....aa", "...aa...", "...aa..."]
DROP = [".c..", ".c..", "cc..", "cc..", "cc..", ".c.."]


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


# The day 2 and 3 slop ROMs' gatecrashers (pixelkid's "content"), drawn
# fresh as nods to the arcade era, not copies of anyone's sprites.
# A robot marching through (day 2), two walking frames: c body, a eyes.
ROBOT = [
    "..cccc..", ".cccccc.", ".caccac.", ".cccccc.", "..cccc..", "...cc...",
    ".cccccc.", "cccccccc", "c.cccc.c", "c.cccc.c", "..cccc..", "..c..c..",
]
ROBOT_LEGS = [
    ["..c..c..", "..c..c..", "..c..c..", ".cc..cc."],
    ["..c..c..", ".c....c.", "c......c", "cc....cc"],
]
# a smiley bouncing after it: a face, b features
# (each line doubled: 160A pixels are wide)
SMILEY = [r for r in ["..aaaa..", ".aaaaaa.", "aabaabaa", "aaaaaaaa", "abaaaaba", "aabbbbaa", ".aaaaaa.", "..aaaa.."]
          for _ in (0, 1)]
# day 3's arena: two tanks facing off, a shell, and an asteroid going by
TANK_R = ["aaaaaa..", "aaaaaa..", ".aaaa...", ".aaaaaaa", ".aaaa...", "aaaaaa..", "aaaaaa.."]
TANK_L = [r[::-1] for r in TANK_R]
SHELL = [".aa.", ".aa."]
ROCK = [
    "....bbbb....", "..bbbcbbbb..", ".bbcccbbbbb.", ".bbcbbbbbbb.", "bbbbbbbbcbbb", "bbbbbbbbbbbb",
    "bbbcbbbbbbb.", ".bbbbbbbcbbb", ".bbbbbbbbbb.", "..bbbbcbbb..", "...bbbbbb...", "............",
]
ROCK2 = ["".join(ROCK[11 - x][y] for x in range(12)) for y in range(12)]


# ---------------------------------------------------------------------------
# The mirror ROM (bank 6, with its code): top-down rooms in 160A.
# Its own font, mfont: glyphs 0-63 the same ASCII as the game's font (so the
# alphachars codes still work), 64 up the rooms' tiles. Walkable tiles come
# first (64-69): every code from 2 x 70 up is solid (tools/mirror.py, the
# map legend, must match).
M_TILES = {
    64: ("floor", ["bbbbbbbb", "bbbbbbbb", "bbbbbbbb", "aaaaaaaa"] * 2 + ["bbbbabbb", "bbbbabbb", "bbbbabbb", "aaaaaaaa"] * 2),
    65: ("rug", ["cccccccc", "cbcccbcc", "cccbcccc", "cccccccc"] * 4),
    66: ("grid", ["a......."] + ["........"] * 7 + ["a......."] + ["........"] * 7),
    67: ("plate", ["........", ".cccccc.", "cbbbbbbc", "cbbbbbbc", "cbbbbbbc", "cbbbbbbc", "cbbbbbbc", "cbbbbbbc",
                   "cbbbbbbc", "cbbbbbbc", "cbbbbbbc", "cbbbbbbc", "cbbbbbbc", ".cccccc.", "aaaaaaaa", "........"]),
    68: ("plated", ["........"] * 3 + [".cccccc.", "cccccccc"] + ["cccccccc"] * 9 + [".cccccc.", "........"]),
    69: ("dooropen", ["a......a"] * 16),
    70: ("wallcap", ["aaaaaaaa"] * 16),
    71: ("wall", ["bcbbbcbb"] * 13 + ["aaaaaaaa", "aaaaaaaa", "aaaaaaaa"]),
    72: ("window", ["bbbbbbbb", "baaaaaab", "bacccaab", "bacccaab", "baacccab", "baacccab", "baaaaaab", "baacccab",
                    "bacccaab", "baaaaaab", "bbbbbbbb", "bcbbbcbb", "bcbbbcbb", "aaaaaaaa", "aaaaaaaa", "aaaaaaaa"]),
    73: ("poster", ["bcbbbcbb", "cccccccc", "caaaaaac", "cabbbbac", "cabccbac", "cabbbbac", "caaaaaac", "caccccac",
                    "caaaaaac", "cccccccc", "bcbbbcbb", "bcbbbcbb", "bcbbbcbb", "aaaaaaaa", "aaaaaaaa", "aaaaaaaa"]),
    74: ("tvl", ["........", "aaaaaaaa", "accccccc", "acbbbbbb", "acbcbbbb", "acbbbbbb", "acbbbbcb", "acbbbbbb",
                 "acbbcbbb", "acbbbbbb", "accccccc", "aaaaaaaa", "aaaaaaaa", ".a......", ".a......", "........"]),
    75: ("tvr", ["........", "aaaaaaaa", "cccccca.", "bbbbbca.", "bbbbbca.", "bcbbbca.", "bbbbbca.", "bbcbbca.",
                 "bbbbbca.", "bbbbbca.", "cccccca.", "aaaaaaa.", "aacaca..", "......a.", "......a.", "........"]),
    76: ("couchl", ["........", "........", "..aaaaaa", ".abbbbbb", "abbbbbbb", "abbbbbbb", "abbbbbbb", "abcccccc",
                    "abcccccc", "abcccccc", "abbbbbbb", "abbbbbbb", "aaaaaaaa", ".a......", "........", "........"]),
    77: ("couchm", ["........", "........", "aaaaaaaa", "bbbbbbbb", "bbbbbbbb", "bbbbbbbb", "bbbbbbbb", "cccccccc",
                    "cccbcccc", "cccccccc", "bbbbbbbb", "bbbbbbbb", "aaaaaaaa", "........", "........", "........"]),
    78: ("couchr", [r[::-1] for r in ["........", "........", "..aaaaaa", ".abbbbbb", "abbbbbbb", "abbbbbbb", "abbbbbbb", "abcccccc",
                                      "abcccccc", "abcccccc", "abbbbbbb", "abbbbbbb", "aaaaaaaa", ".a......", "........", "........"]]),
    79: ("chair", ["........", ".aaaaaa.", "abbbbbba", "abbbbbba", "abbbbbba", "abbbbbba", "abccccba", "abccccba",
                   "abccccba", "abbbbbba", "abbbbbba", "aaaaaaaa", ".a....a.", ".a....a.", "........", "........"]),
    80: ("table", ["........", "........", "aaaaaaaa", "cccccccc", "cbbbbbbc", "cbbbbbbc", "cbbbbbbc", "cccccccc",
                   "aaaaaaaa", ".a....a.", ".a....a.", ".a....a.", ".a....a.", "........", "........", "........"]),
    81: ("shelf", ["aaaaaaaa", "abcbcabc", "abcbcabc", "abcbcabc", "abcbcabc", "aaaaaaaa", "acbbcacb", "acbbcacb",
                   "acbbcacb", "acbbcacb", "aaaaaaaa", "abccbbca", "abccbbca", "abccbbca", "aaaaaaaa", "a......a"]),
    82: ("bench", ["........", "..c..b..", ".ccc.b..", "..c.bbb.", "aaaaaaaa", "cccccccc", "abbbbbba", "abbbbbba",
                   "abaaaaba", "abbbbbba", "aaaaaaaa", "a......a", "a......a", "a......a", "a......a", "........"]),
    83: ("cabtop", [".aaaaaa.", "aaaaaaaa", "acccccca", "aaaaaaaa", "abbbbbba", "abaaaaba", "abaccaba", "abacaaba",
                    "abaaaaba", "abaaacba", "abaaaaba", "abbbbbba", "aaaaaaaa", "acbaacba", "aaaaaaaa", "abbbbbba"]),
    84: ("cabbot", ["abbbbbba", "aaaaaaaa", "abbbbbba", "abbbbbba", "abbccbba", "abbbbbba", "abbbbbba", "abbbbbba",
                    "abbbbbba", "abbbbbba", "abbbbbba", "abbbbbba", "aaaaaaaa", "aaaaaaaa", "........", "........"]),
    85: ("rack", ["aaaaaaaa", "abbbbbba", "abcbabba", "abbbbbba", "aaaaaaaa", "abbbbbba", "abbacbba", "abbbbbba",
                  "aaaaaaaa", "abbbbbba", "abcbbcba", "abbbbbba", "aaaaaaaa", "abbbbbba", "aaaaaaaa", "a......a"]),
    86: ("door", ["aaaaaaaa", "acbcbcba", "acbcbcba", "acbcbcba", "acbcbcba", "acbcbcba", "acbcbcba", "acbcbcba",
                  "acbcbcba", "acbcbcba", "acbcbcba", "acbcbcba", "acbcbcba", "acbcbcba", "acbcbcba", "aaaaaaaa"]),
    87: ("readtl", ["aaaaaaaa", "abbbbbbb", "abcccccc", "abcaaaaa", "abcacccc", "abcacccc", "abcaaaaa", "abcccccc",
                    "abbbbbbb", "abbbbbbb", "abbcbcbb", "abbbbbbb", "abbbbbbb", "abbbbbbb", "abbbbbbb", "abbbbbbb"]),
    88: ("readtr", ["aaaaaaaa", "bbbbbbba", "ccccccba", "aaaaacba", "ccccacba", "ccccacba", "aaaaacba", "ccccccba",
                    "bbbbbbba", "bbbbbbba", "bbbbbbba", "bbcbbbba", "bbbbbbba", "bbbbbbba", "bbbbbbba", "bbbbbbba"]),
    89: ("readbl", ["abbbbbbb", "abaaaaaa", "abacccca", "abaaaaaa", "abbbbbbb", "abbbbbbb", "abbbbbbb", "aaaaaaaa",
                    ".a......", ".a......", "........", "........", "........", "........", "........", "........"]),
    90: ("readbr", ["bbbbbbba", "aaaaaaba", "acccccba", "aaaaaaba", "bbbbbbba", "bbbbbbba", "bbbbbbba", "aaaaaaaa",
                    "......a.", "......a.", "........", "........", "........", "........", "........", "........"]),
    91: ("lever", ["........", "...cc...", "...cc...", "...a....", "...a....", "...a....", "...a....", "...a....",
                   "..aaa...", ".abbba..", ".abbba..", ".aaaaa..", "........", "........", "........", "........"]),
    92: ("leverd", ["........"] * 5 + [".cc.....", ".cca....", "...a....", "....a...", "..aaa...", ".abbba..", ".abbba..",
                                       ".aaaaa..", "........", "........", "........"]),
    93: ("plant", ["...c....", ".c.cc.c.", ".cccccc.", "cc.cc.cc", ".cccccc.", "..cccc..", "...c....", "..aaaa..",
                   "..abba..", "..abba..", "..abba..", "...aa...", "........", "........", "........", "........"]),
    94: ("lamp", ["..cccc..", ".cccccc.", "cccccccc", "........", "...a....", "...a....", "...a....", "...a....",
                  "...a....", "...a....", "...a....", "..aaa...", ".aaaaa..", "........", "........", "........"]),
    95: ("box", ["bbbbbbbb"] * 16),
}
M_LEGEND = {}


def mirror_gfx(sprites):
    """src/gen/mirrorgfx.asm: the mirror's 4K graphics block (bank 6, $A000):
    MARIA's layout, page p holding line 15 - p. Bytes 0-191 the font (96
    glyphs, 2 bytes each, doublewide); then the sprites side by side, each
    with the symbols 7800basic's plotsprite wants (frames: consecutive
    sprites of one width)."""
    src = Image.open(FONT_SRC)
    sp = src.load()
    glyph = lambda c, x, y: bool(sp[c * 8 + x, y])
    g = [["." * 8 for _ in range(ZONE)] for _ in range(96)]
    for i in range(64):
        for y in range(8):
            g[i][4 + y] = "".join("a" if glyph(32 + i, x, y) else "." for x in range(8))
    for n, (_, rows) in M_TILES.items():
        assert len(rows) == 16 and all(len(r) == 8 for r in rows), n
        g[n] = rows
    cols = [g[i] for i in range(96)]                  # 8-pixel columns
    syms = ["mfont = $A000", "mfont_mode = $00", "mfont_width = 192"]
    off = 192
    for name, rows in sprites:
        w = len(rows[0])
        assert w % 8 == 0 and len(rows) == 16, name
        syms += [f"{name} = $A000 + {off}", f"{name}_mode = $00",
                 f"{name}_width = {w // 4}", f"{name}_width_twoscompliment = ${(32 - w // 4) & 31:02x}"]
        for k in range(0, w, 8):
            cols.append([r[k:k + 8] for r in rows])
        off += w // 4
    assert off <= 256, f"the mirror's graphics: {off} bytes wide"
    out = ["; Generated by tools/gfx.py (the mirror). Do not edit.", "; The mirror's graphics block, at $A000 in bank 6."]
    out += syms
    for p in range(16):
        line = 15 - p
        bs = []
        for col in cols:
            r = col[line]
            for half in (r[:4], r[4:]):
                v = 0
                for ch in half:
                    v = v * 4 + ".abc".index(ch)
                bs.append(v)
        bs += [0] * (256 - len(bs))
        for k in range(0, 256, 32):
            out.append("    .byte " + ",".join(str(v) for v in bs[k:k + 32]))
    (ROOT / "src" / "gen" / "mirrorgfx.asm").write_text("\n".join(out) + "\n")


# The mirror's people, 8 x 16 (a skin, b clothes, c hair / trousers), drawn
# front (down), back (up), left and right, two steps each.
def person(hair, face_down, body, legs2=None):
    """hair/face 5 lines, body 6, legs 4 (+1 blank): a front view"""
    return hair + face_down + body


def walkers(top_d, top_u, top_s, body_d, body_s, legs):
    """frames: down 0 1, up 0 1, left 0 1, right 0 1"""
    out = []
    flip = lambda rows: [r[::-1] for r in rows]
    for top, body in ((top_d, body_d), (top_u, body_d)):
        for lg in legs:
            out.append(top + body + lg + ["........"])
    for lg in legs:
        out.append(top_s + body_s + lg + ["........"])
    for f in out[4:6]:
        out.append(flip(f))
    return out


LEGS = [["..c..c..", "..c..c..", "..c..c..", ".cc..cc."], ["..c..c..", "..c..c..", ".cc...c.", "......cc"]]
LEGS_S = [["...cc...", "...cc...", "..c..c..", ".cc..cc."], ["...cc...", "...cc...", "...cc...", "..ccc..."]]

ARTHUR_M = walkers(
    ["..cccc..", ".cccccc.", ".caaaac.", ".aacaaa.", "..aaaa.."],
    ["..cccc..", ".cccccc.", ".cccccc.", ".cccccc.", "..aaaa.."],
    ["..cccc..", ".cccccc.", "..caaaa.", "..caaca.", "..aaaa.."],
    [".bbbbbb.", "bbbbbbbb", "abbbbbba", "abbbbbba", ".bbbbbb.", "..cccc.."],
    ["..bbbb..", ".bbbbbb.", ".bbbbbb.", ".bbabbb.", "..bbbb..", "..cccc.."],
    LEGS)
ARTHUR_M[4:8] = ARTHUR_M[4:8]
PIXELKID_M = walkers(
    [".bbbbbb.", "bbbbbbbb", ".caaaac.", ".aacaca.", "..aaaa.."],
    [".bbbbbb.", ".bbbbbb.", ".cccccc.", ".cccccc.", "..aaaa.."],
    ["..bbbb..", ".bbbbbbb", "..caaaa.", "..caaca.", "..aaaa.."],
    [".bbbbbb.", "bbbbbbbb", "abbbbbba", "abbbbbba", ".bbbbbb.", "..cccc.."],
    ["..bbbb..", ".bbbbbb.", ".bbbbbb.", ".bbabbb.", "..bbbb..", "..cccc.."],
    LEGS)
# the regulars stand facing you: Sue (goggles), Hal (headphones), Maria
# (glasses, a long coat)
SUE_M = ["..cccc..", ".cccccc.", ".bbabba.", ".aaaaaa.", "..aaaa..", ".bbbbbb.", "bbbbbbbb", "abbbbbba",
         "abbbbbba", ".bbbbbb.", "..cccc..", "..c..c..", "..c..c..", "..c..c..", ".cc..cc.", "........"]
HAL_M = ["..cccc..", "bcccccb.", "baaaaab.", "bacaca.b"[:8], "..aaaa..", ".bbbbbb.", "bbbbbbbb", "abbbbbba",
         "abbbbbba", ".bbbbbb.", "..cccc..", "..c..c..", "..c..c..", "..c..c..", ".cc..cc.", "........"]
MARIA_M = [".cccccc.", "cccccccc", "cbabbabc", "caaaaaac", "c.aaaa.c", ".bbbbbb.", "bbbbbbbb", "abbbbbba",
           "abbbbbba", "bbbbbbbb", "bbbbbbbb", "bbbbbbbb", "..a..a..", "..a..a..", ".cc..cc.", "........"]


def main():
    GFX.mkdir(parents=True, exist_ok=True)
    font()
    font320()
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
    sprite("reticle", RETICLE)
    sprite("drop", DROP)
    for i, legs in enumerate(ROBOT_LEGS):
        sprite(f"robot{i}", ROBOT + legs)
    sprite("smiley", SMILEY)
    sprite("tankr", TANK_R)
    sprite("tankl", TANK_L)
    sprite("shell", SHELL)
    sprite("rock0", ROCK)
    sprite("rock1", ROCK2)
    mirror_gfx([(f"marthur{i}", f) for i, f in enumerate(ARTHUR_M)]
               + [(f"mkid{i}", f) for i, f in enumerate(PIXELKID_M)]
               + [("msue", SUE_M), ("mhal", HAL_M), ("mmaria", MARIA_M)])

    print(f"wrote {GFX.relative_to(ROOT)}/: font, padp, padc, ball, ballcut0-4, garb0-1, spark0-2, porch")


if __name__ == "__main__":
    main()
