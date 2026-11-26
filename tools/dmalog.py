#!/usr/bin/env python3
"""Summarize the a7800 fork's per-line DMA log (run with A7800_DMA_LOG=<file>).

    tools/dmalog.py <log> [-z 16] [--from F] [--to F]

MARIA has 430 cycles of DMA a line; a line that needs more is cut short
(objects late in its display lists are not drawn: one-line gaps). Shows the
average and peak load by band of lines (-z, default 16), and the frames in
which lines were cut short."""
import argparse

ap = argparse.ArgumentParser()
ap.add_argument('log')
ap.add_argument('-z', type=int, default=16, help='lines per band')
ap.add_argument('--from', dest='lo', type=int, default=0, help='first emulator frame')
ap.add_argument('--to', dest='hi', type=int, default=1 << 60, help='last emulator frame')
a = ap.parse_args()

frames, over = [], []
for line in open(a.log):
    if line.startswith('#'):
        continue
    head, lines = line.split(':')
    f, cyc, stolen, nover, peak, pline = map(int, head.split())
    if not a.lo <= f <= a.hi:
        continue
    lines = list(map(int, lines.split()))
    frames.append((f, cyc, stolen, lines))
    if nover:
        over.append((f, nover, [i for i, c in enumerate(lines) if c >= 430]))

n = len(frames)
print(f"{n} frames: MARIA {sum(x[1] for x in frames) / n:.0f} cycles a frame, "
      f"CPU loses {sum(x[2] for x in frames) / n:.0f} of 29830")
print(f"\n{'lines':>9s} {'avg':>5s} {'peak':>5s}  (MARIA cycles a line, limit 430)")
for b in range(0, 243, a.z):
    rng = range(b, min(b + a.z, 243))
    avg = sum(x[3][i] for x in frames for i in rng) / (n * len(rng))
    peak = max(x[3][i] for x in frames for i in rng)
    print(f"{b:4d}-{rng[-1]:<4d} {avg:5.0f} {peak:5d}  {'#' * int(avg / 10)}")
print(f"\n{len(over)} frames with lines cut short")
for f, k, ls in over[:20]:
    print(f"  frame {f}: {k} lines: {ls[:12]}{' ...' if len(ls) > 12 else ''}")
