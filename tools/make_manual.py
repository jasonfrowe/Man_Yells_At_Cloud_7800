#!/usr/bin/env python3
"""Build the game's manual: docs/manual/manual.html -> a PDF.

    .venv/bin/python tools/make_manual.py           # the images and the PDF
    .venv/bin/python tools/make_manual.py --shots   # run the tests for the
                                                    # screenshots first (minutes)

A 16-page pocket booklet, 5 x 7 inches, in the style of the manuals that
came with computers (Concept.md: the hints live here). Edit the words in
docs/manual/manual.html; Chrome prints it (docs/manual/*.pdf). The
screenshots come from the headless tests' snapshots (SHOTS below), the
cover's Cloud from src/gfx at the 7800's pixel shape.
From Atari Gamma Force's tools/make_manual.py.
"""

import argparse
import shutil
import subprocess
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
MAN = ROOT / "docs" / "manual"
IMG = MAN / "img"
BUILD = ROOT / "build"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# the test runs that make the screenshots, and the frames the manual uses
RUNS = [("tools/test_story.sh", {}), ("tools/test_forum.sh", {}), ("tools/test_mirror.sh", {}),
        ("tools/test_break.sh", {"DAY": "2"}, "break2"), ("tools/test_break.sh", {"DAY": "3"}, "break3")]
SHOTS = {
    "title": "story/a7800/0000.png",
    "cutscene": "story/a7800/0011.png",
    "card": "story/a7800/0002.png",
    "forum": "story/a7800/0004.png",
    "thread": "forum/day3/a7800/0001.png",
    "review": "forum/day3/a7800/0002.png",
    "slop": "break2/a7800/0000.png",
    "slopgame": "break2/a7800/0001.png",
    "crash": "break3/a7800/0003.png",
    "porch": "story/a7800/0006.png",
    "rain": "story/a7800/0007.png",
    "storm": "story/a7800/0022.png",
    "mirror": "mirror/a7800/0002.png",
}


def shots():
    for run in RUNS:
        script, env = run[0], run[1]
        e = dict(**__import__("os").environ, **env)
        subprocess.run([str(ROOT / script)], env=e, check=True, stdout=subprocess.DEVNULL)
        if len(run) > 2:                       # (test_break.sh's folder is build/break)
            dst = BUILD / run[2]
            shutil.rmtree(dst, ignore_errors=True)
            shutil.copytree(BUILD / "break", dst)


def images():
    for name, src in SHOTS.items():
        im = Image.open(BUILD / src).convert("RGB")
        im.save(IMG / f"{name}.png")
    # the cover's Cloud: the sprite, its colours, 2:1 pixels, big
    cloud = Image.open(ROOT / "src" / "gfx" / "cloud1.png")
    pal = {0: (0, 0, 0, 0), 1: (150, 160, 178, 255), 2: (208, 214, 226, 255), 3: (255, 255, 255, 255)}
    w, h = cloud.size
    out = Image.new("RGBA", (w * 2, h))
    px = cloud.load()
    for y in range(h):
        for x in range(w):
            c = pal[px[x, y]]
            out.putpixel((2 * x, y), c)
            out.putpixel((2 * x + 1, y), c)
    out.resize((out.width * 4, out.height * 4), Image.NEAREST).save(IMG / "cloud.png")


def pdf():
    out = MAN / "Man_Yells_at_Cloud_Manual.pdf"
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
                    "--run-all-compositor-stages-before-draw", "--virtual-time-budget=4000",
                    f"--print-to-pdf={out}", (MAN / "manual.html").as_uri()],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print(out.relative_to(ROOT))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--shots", action="store_true", help="run the tests for the screenshots")
    ap.add_argument("--no-pdf", action="store_true")
    args = ap.parse_args()
    IMG.mkdir(parents=True, exist_ok=True)
    if args.shots:
        shots()
    images()
    if not args.no_pdf:
        pdf()


if __name__ == "__main__":
    main()
