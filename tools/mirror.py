#!/usr/bin/env python3
"""0x7800_MIRROR.BIN: storyboard/mirror.txt (rooms and talk) to
src/gen/mirrordat.asm (bank 6). See mirror.txt for the format and
src/asm/mirror.asm for how the tables are read.

Text is stored as the 160A font's codes (2 x (ASCII - 32)), padded with
spaces: a room's name 20, a page's speaker and two lines 20 each.
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "storyboard" / "mirror.txt"
OUT = ROOT / "src" / "gen" / "mirrordat.asm"

# the map legend: character -> (glyph, palette). tools/gfx.py's M_TILES:
# glyphs 64-69 walkable, 70 up solid (code 140 up: src/asm/mirror.asm)
LEGEND = {
    ".": (64, 4), "~": (65, 4), ",": (66, 4), "p": (67, 7), "d": (69, 5),
    "#": (70, 5), "=": (71, 5), "w": (72, 5), "P": (73, 5), "T": (74, 7), "t": (75, 7),
    "[": (76, 6), "-": (77, 6), "]": (78, 6), "h": (79, 6), "o": (80, 6), "B": (81, 6),
    "W": (82, 6), "A": (83, 6), "a": (84, 6), "S": (85, 7), "D": (86, 5),
    "R": (87, 7), "r": (88, 7), "Q": (89, 7), "q": (90, 7), "L": (91, 7), "*": (93, 6), "l": (94, 6),
}
NPCS = ["none", "sue", "hal", "maria", "pixelkid"]
# the hub's machinery, at fixed places (mirror.bas): two plates and the door
HUB_FIXED = {(13, 4): "p", (3, 9): "p", (15, 6): "D"}


def fail(n, msg):
    sys.exit(f"{SRC.name}:{n}: {msg}")


def codes(text, n, width=20):
    if len(text) > width:
        fail(n, f"over {width} characters ({len(text)}): {text}")
    for ch in text:
        if not 32 <= ord(ch) <= 95:
            fail(n, f"{ch!r} isn't in the font: {text}")
    return [2 * (ord(c) - 32) for c in text.ljust(width)]


def main():
    rooms, talks, speakers, prompts = [], {}, [], []
    cur, mode, page, speaker = None, None, [], None
    lines = SRC.read_text().splitlines()

    def endpage(n):
        nonlocal page
        if page:
            talks[cur_talk]["pages"].append((speaker, page))
            page = []

    cur_talk = None
    for n, raw in enumerate(lines, 1):
        line = raw.rstrip()
        if line.startswith("#") and mode != "map":
            continue
        if mode == "map":
            if len(line) != 20:
                fail(n, f"a map row of {len(line)}, not 20")
            for ch in line:
                if ch not in LEGEND:
                    fail(n, f"{ch!r} isn't in the legend")
            cur["map"].append(line)
            if len(cur["map"]) == 11:
                mode = None
            continue
        if mode == "talk":
            if line.startswith("@"):
                endpage(n)
                mode = None
            elif not line.strip():
                endpage(n)
                continue
            elif line.startswith("= "):
                endpage(n)
                speaker = line[2:].strip()
                codes(speaker, n)
                if speaker not in speakers:
                    speakers.append(speaker)
                continue
            else:
                if speaker is None:
                    fail(n, "a line before its speaker (= NAME)")
                codes(line, n)
                page.append(line)
                if len(page) > 2:
                    fail(n, "a page over 2 lines")
                continue
        if not line.strip():
            continue
        head, _, text = line.partition("|")
        w = head.split()
        cmd = w[0]
        if cmd == "@room":
            cur = dict(key=w[1], name=text.strip(), pal=None, bg=0, map=[], doors=[], npc=(0, 0, 0))
            codes(cur["name"], n)
            rooms.append(cur)
        elif cmd == "@pal":
            cur["pal"] = [int(v.replace("$", "0x"), 16) for v in w[1:]]
            if len(cur["pal"]) != 12:
                fail(n, "@pal: 12 colours")
            mode = "map"
        elif cmd == "@bg":
            cur["bg"] = int(w[1].replace("$", "0x"), 16)
        elif cmd == "@door":
            cur["doors"].append((int(w[1]), int(w[2]), w[3], int(w[4]), int(w[5]), n))
        elif cmd == "@npc":
            cur["npc"] = (NPCS.index(w[1]), int(w[2]), int(w[3]))
        elif cmd == "@prompt":
            prompts.append(text.strip())
            codes(prompts[-1], n)
        elif cmd == "@talk":
            cur_talk = int(w[1])
            if cur_talk != len(talks):
                fail(n, f"talk {cur_talk}: number them in order (next is {len(talks)})")
            talks[cur_talk] = dict(key=w[2], pages=[])
            speaker, page, mode = None, [], "talk"
        else:
            fail(n, f"unknown {cmd}")
    endpage(len(lines))

    keys = [r["key"] for r in rooms]
    tile = lambda r, c, row: r["map"][row - 1][c]
    for r in rooms:
        for (c, row, to, sc, sr, n) in r["doors"]:
            if tile(r, c, row) != "T" or tile(r, c + 1, row) != "t":
                fail(n, f"@door {c} {row}: not a TV's left half (Tt)")
            dest = rooms[keys.index(to)]
            if LEGEND[tile(dest, sc, sr)][0] >= 70:
                fail(n, f"@door: steps out onto a solid tile in {to}")
    hub = rooms[keys.index("hub")]
    for (c, row), ch in HUB_FIXED.items():
        if tile(hub, c, row) != ch:
            sys.exit(f"mirror.txt: the hub needs {ch!r} at column {c}, row {row} (mirror.bas)")

    out = ["; Generated by tools/mirror.py from storyboard/mirror.txt. Do not edit.", ""]
    out.append(f"M_NROOMS = {len(rooms)}")
    for i, r in enumerate(rooms):
        out.append(f"M_{r['key'].upper()} = {i}")
    for i, t in talks.items():
        out.append(f"T_{t['key'].upper()} = {i}")

    def table(name, vals):
        vals = list(vals)
        for k in range(0, max(1, len(vals)), 16):
            out.append(f"{name if k == 0 else ''} .byte " + ",".join(str(v) for v in vals[k:k + 16]))

    for x in ("map", "name", "doors"):
        table(f"m_r{x}lo", [f"<m_{x}{i}" for i in range(len(rooms))])
        table(f"m_r{x}hi", [f">m_{x}{i}" for i in range(len(rooms))])
    table("m_rbg", [r["bg"] for r in rooms])
    table("m_rnpc", [r["npc"][0] for r in rooms])
    table("m_rnpcx", [r["npc"][1] * 8 for r in rooms])
    table("m_rnpcy", [r["npc"][2] * 16 - 4 for r in rooms])
    out.append("m_rpal")
    for r in rooms:
        table("", r["pal"])
    for i, r in enumerate(rooms):
        table(f"m_map{i}", [2 * LEGEND[ch][0] for row in r["map"] for ch in row])
        table(f"m_name{i}", codes(r["name"], 0))
        d = []
        for (c, row, to, sc, sr, _) in r["doors"]:
            d += [c, row, keys.index(to), sc * 8, sr * 16 - 4]
        table(f"m_doors{i}", d + [255])
    # the top row's prompts (what button 1 would do), 1 up
    table("m_prlo", [f"<m_pr{k}" for k in range(len(prompts))])
    table("m_prhi", [f">m_pr{k}" for k in range(len(prompts))])
    for k, t in enumerate(prompts):
        table(f"m_pr{k}", codes(t, 0))
    # each tile's palette (by glyph, 64-95): m_draw groups a row's tiles
    # into runs of one palette
    tp = [0] * 32
    for ch, (gl, pal) in LEGEND.items():
        tp[gl - 64] = pal
    table("m_tpal", tp)
    # talk: pages of speaker, line 1, line 2 (41 bytes)
    first, cnt, pages = [], [], []
    for i in range(len(talks)):
        first.append(len(pages))
        cnt.append(len(talks[i]["pages"]))
        pages += talks[i]["pages"]
    if len(pages) > 255:
        sys.exit("mirror.txt: over 255 pages")
    table("m_tfirst", first)
    table("m_tcount", cnt)
    table("m_pglo", [f"<m_pg{k}" for k in range(len(pages))])
    table("m_pghi", [f">m_pg{k}" for k in range(len(pages))])
    table("m_spklo", [f"<m_spk{k}" for k in range(len(speakers))])
    table("m_spkhi", [f">m_spk{k}" for k in range(len(speakers))])
    for k, s in enumerate(speakers):
        table(f"m_spk{k}", codes(s, 0))
    for k, (spk, pg) in enumerate(pages):
        pg = pg + [""] * (2 - len(pg))
        table(f"m_pg{k}", [speakers.index(spk)] + codes(pg[0], 0) + codes(pg[1], 0))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(out) + "\n")
    print(f"mirror: {len(rooms)} rooms, {len(talks)} talks, {len(pages)} pages")


if __name__ == "__main__":
    main()
