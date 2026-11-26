#!/usr/bin/env python3
"""The music and the TIA effects: writes src/gen/music.asm (the songs, in the
fixed bank) and src/gen/sfx.asm (the effects).

From Cosmic Arc II's tools/music.py (the same stream format, see
src/asm/sound.asm). Six voices: lead and bass on POKEY 1, harmony, pad,
drums and hats on POKEY 2. With one POKEY the driver plays the lead, the
bass (an octave up) and the drums (voice 4) only, so every song must stand
on those three: keep the beat in voice 4 (kick, snare, tom), and treat
voices 2, 3 and 5 as extra colour.

Songs are whole bars of 16 sixteenths; at speed 8 a bar is 128 frames, so
the driver's mus_frame (wrapping at 256) keeps the beat: a quarter is 32
frames, beat = mus_frame & 31 (the porch's on-beat window).

  MUS_PORCH  E minor, 112 BPM, tense: Arthur yells, the Cloud breathes on
             every quarter (a clean thump on each; the aim crosses the Cloud
             on it)
  MUS_RAIN   C major, slower, warm: the rain

The generated songs (Cosmic Arc II's tools/musicgen) can come in later.
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GEN = ROOT / "src" / "gen"

NAMES = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}
BASE = 24          # note 0 = C1


def midi(s):
    s = s.strip()
    name, octv = s[:-1], int(s[-1])
    return 12 * (octv + 1) + NAMES[name]


def note(s):
    return midi(s) - BASE


def parse(text):
    """'E5:2 A5:2 r:4' -> [(note or None, sixteenths)]"""
    out = []
    for tok in text.split():
        n, d = tok.split(":")
        out.append((None if n == "r" else note(n), int(d)))
    return out


# ---------------------------------------------------------------------------
# Instruments: envelope (volumes a frame, last held), arpeggio (offsets a frame, looped)
INSTR = [
    ("lead", [12, 13, 12, 11, 10, 10, 9, 9, 9, 8, 8, 8, 8, 7], None),
    ("bass", [13, 12, 11, 10, 9, 8, 7, 7, 6], None),
    ("arpmin", [7, 7, 6, 6, 6, 5, 5, 5, 5, 4], [0, 0, 3, 3, 7, 7, 12, 12]),
    ("arpmaj", [7, 7, 6, 6, 6, 5, 5, 5, 5, 4], [0, 0, 4, 4, 7, 7, 12, 12]),
    ("pluck", [13, 11, 9, 7, 6, 5, 4, 3, 2, 0], None),
    ("pad", [3, 4, 5, 6, 6, 6, 6, 5], None),
    ("stab", [14, 12, 9, 7, 5, 4, 3, 2, 1, 0], None),
    # the generated songs' (the composer writes its own arpeggios)
    ("glead", [11, 12, 11, 10, 10, 9, 9, 9, 8, 8, 8, 8, 8, 7], None),
    ("gbass", [13, 12, 11, 10, 10, 9, 9, 8, 8, 8, 7], None),
    ("garp", [9, 8, 7, 6, 5, 5, 4, 4, 3], None),
    ("gpad", [2, 3, 4, 5, 6, 6, 6, 6, 6, 5], None),
]
INS = {n: i for i, (n, _, _) in enumerate(INSTR)}

# Drums on POKEY 2 channels 3 (kick, snare, tom) and 4 (hats), at the 64 kHz
# clock: (AUDC, AUDF) a frame. AUDC: $A_ pure tone, $C_ poly4 (a low buzz),
# $8_ noise; AUDF: the pitch, 64 kHz / 2 / (AUDF + 1). The kick: a poly4
# thump, then a tone falling to 125 Hz.
DRUMS = [
    ("kick", [(0xCF, 50), (0xAE, 150), (0xAC, 185), (0xAA, 215), (0xA8, 240), (0xA6, 255), (0xA4, 255), (0xA2, 255)]),
    ("snare", [(0x8F, 5), (0x8D, 7), (0x8B, 9), (0x89, 10), (0x87, 11), (0x85, 12), (0x83, 13), (0x82, 14), (0x81, 15)]),
    ("hat", [(0x85, 0), (0x83, 0), (0x81, 0)]),
    ("ohat", [(0x85, 0), (0x84, 0), (0x84, 0), (0x83, 0), (0x83, 0), (0x82, 0), (0x82, 0), (0x81, 0)]),
    ("tom", [(0xAD, 100), (0xAB, 120), (0xA9, 140), (0xA7, 160), (0xA5, 180), (0xA3, 200)]),
    # the porch's: a clean kick (pure tone falling, no poly4 burst) on every
    # beat, and a quiet short tick between (voice 5: two POKEYs only)
    ("thump", [(0xAC, 120), (0xAB, 150), (0xAA, 185), (0xA8, 215), (0xA6, 240), (0xA4, 255), (0xA2, 255)]),
    ("tick", [(0x84, 1), (0x82, 1)]),
]
HATS = {"hat", "ohat", "tick"}
DR = {n: i for i, (n, _) in enumerate(DRUMS)}

ROOT_OF = {"Dm": "D", "Bb": "A#", "C": "C", "Am": "A", "Gm": "G", "A": "A"}
MINOR = {"Dm", "Am", "Gm"}


def drum_parse(text):
    out = []
    for tok in text.split():
        n, d = tok.split(":")
        out.append((None if n == "r" else DR[n], int(d)))
    return out


SPEED = [7]       # the song being written's frames a sixteenth (Stream.notes)


class Stream:
    def __init__(self, label):
        self.label = label
        self.lines = []
        self.marks = {}

    def mark(self, name):
        self.lines.append(f"{self.label}_{name}")

    def ins(self, name):
        self.lines.append(f"    .byte $81,{INS[name]}")

    def trans(self, t):
        self.lines.append(f"    .byte $85,{t & 255}")

    def notes(self, seq, maxd=None):
        """notes (n, sixteenths): the stream holds frames (sixteenths * the
        song's speed, SPEED[0]), at most 255 a byte"""
        sp = SPEED[0]
        maxd = 255 // sp
        for n, d in seq:
            while d > 0:
                dd = min(d, maxd)
                if n is None:
                    self.lines.append(f"    .byte $80,{dd * sp}")
                else:
                    self.lines.append(f"    .byte {n},{dd * sp}")
                d -= dd

    def call(self, label):
        self.lines.append(f"    .byte $83,<{label},>{label}")

    def jump(self, name):
        self.lines.append(f"    .byte $82,<{self.label}_{name},>{self.label}_{name}")

    def end(self):
        self.lines.append("    .byte $86")

    def ret(self):
        self.lines.append("    .byte $84")




ROOT_OF.update({"F": "F", "G": "G", "E": "E", "Em": "E", "B": "B"})


def bars(text):
    """One bar a line: check each is 16 sixteenths."""
    out = []
    for ln in text.strip().splitlines():
        seq = parse(ln)
        assert sum(d for _, d in seq) == 16, ln
        out += seq
    return out


def bass_low(r):
    """The bass's root and octave: low roots an octave down."""
    if r in ("A", "A#", "G", "B", "G#"):
        return note(r + "1"), note(r + "2")
    return note(r + "2"), note(r + "3")


def song(pre, form, lead, lead_ins, bass_bar, harm_bar, drums):
    """A looping song: form (chords a bar), the lead (bars), a bass bar and a
    harmony bar for a chord, drum phrase names a bar."""
    v0, v1, v2, v3, v4, v5 = (Stream(f"{pre}_v{k}") for k in range(6))
    seq = bars(lead)
    assert sum(d for _, d in seq) == 16 * len(form), pre
    v0.ins(lead_ins)
    v0.mark("loop")
    v0.notes(seq)
    v0.jump("loop")
    v1.ins("bass")
    v1.mark("loop")
    for ch in form:
        v1.notes(bass_bar(ch))
    v1.jump("loop")
    v2.mark("loop")
    cur = None
    for ch in form:
        ins = "arpmin" if ch in MINOR else "arpmaj"
        if ins != cur:
            v2.ins(ins)
            cur = ins
        v2.notes(harm_bar(note(ROOT_OF[ch] + "4")))
    v2.jump("loop")
    v3.end()                          # (no pad)
    v4.mark("loop")
    v5.mark("loop")
    for i in range(len(form)):
        v4.call(drums(i) + "_k")      # kick, snare, tom
        v5.call(drums(i) + "_h")      # the hats
    v4.jump("loop")
    v5.jump("loop")
    return [v0, v1, v2, v3, v4, v5]




# ---------------------------------------------------------------------------
# The porch: E minor, a drum on every quarter (the Cloud's breath), a
# stalking bass, a lead that comes in as the Cloud darkens (the game opens
# the voice mask with the catharsis meter).
PORCH_FORM = ["Em", "Em", "C", "D", "Em", "Em", "C", "B"]
PORCH_LEAD = """
E5:6 G5:2 F#5:4 E5:4
B4:8 r:8
C5:6 E5:2 G5:4 E5:4
D5:6 F#5:2 A5:8
E5:4 G5:4 B5:4 A5:2 G5:2
F#5:4 E5:4 B4:8
C5:2 E5:2 G5:2 C6:6 B5:4
B5:4 A5:4 F#5:4 D#5:4
"""
# A clean thump on every beat (the Cloud breathes to it, the aim crosses
# it), a quiet tick between: no white-noise snare.
DRUM_PORCH = "thump:2 tick:2 thump:2 tick:2 thump:2 tick:2 thump:2 tick:2"
DRUM_PORCHFILL = "thump:2 tick:2 thump:2 tick:2 thump:2 tick:2 thump:2 tick:1 tick:1"


def song_porch():
    def bass(ch):
        lo, hi = bass_low(ROOT_OF[ch])
        return [(lo, 3), (lo, 1), (None, 2), (lo, 2), (hi, 2), (lo, 2), (None, 2), (lo, 2)]
    return song("mp", PORCH_FORM, PORCH_LEAD, "lead", bass,
                lambda n: [(n, 8), (n, 8)],
                lambda i: "drum_porchfill" if i % 4 == 3 else "drum_porch")


# The rain: C major, warm and slow, the pad doing the comforting
RAIN_FORM = ["C", "Am", "F", "G", "C", "Am", "F", "G"]
RAIN_LEAD = """
E5:8 D5:4 C5:4
C5:8 E5:4 A5:4
A5:6 G5:2 F5:4 E5:4
D5:12 r:4
E5:4 G5:4 C6:8
B5:4 A5:4 E5:8
F5:4 A5:4 C6:4 A5:4
G5:12 r:4
"""
DRUM_RAIN = "thump:8 tick:4 tick:4"
DRUM_RAINFILL = "thump:8 tick:4 tom:4"


def song_rain():
    def bass(ch):
        lo, hi = bass_low(ROOT_OF[ch])
        return [(lo, 8), (hi, 4), (lo, 4)]
    return song("mr", RAIN_FORM, RAIN_LEAD, "pluck", bass,
                lambda n: [(n, 16)],
                lambda i: "drum_rainfill" if i % 4 == 3 else "drum_rain")


ROOT_OF.update({"F": "F", "G": "G", "E": "E", "Em": "E", "B": "B", "D": "D"})
MINOR.update({"Em"})

# ---------------------------------------------------------------------------
# TIA effects: (AUDC, AUDF, AUDV) a frame; channel; priority
def notes_fx(c, fs, each, v):
    out = []
    for f in fs:
        out += [(c, f, v)] * each
    return out


def sweep(c, f0, f1, v0, v1, n):
    return [(c, round(f0 + (f1 - f0) * i / (n - 1)), round(v0 + (v1 - v0) * i / (n - 1))) for i in range(n)]


SFX = [
    ("YELL", 0, 2, sweep(12, 10, 16, 9, 3, 8)),           # a yell: a short bark
    ("FIST", 0, 2, sweep(12, 16, 10, 9, 3, 8)),           # a fist shaken
    ("GOOD", 1, 3, notes_fx(4, [14, 11], 3, 7)),          # it lands
    ("PERFECT", 1, 4, notes_fx(4, [14, 11, 8], 3, 8)),    # dead centre
    ("MISS", 1, 3, sweep(12, 18, 26, 6, 1, 10)),          # it goes by
    ("TOOFAST", 1, 4, notes_fx(12, [20, 24], 4, 7)),      # mashing
    ("DIZZY", 1, 5, [(4, f, 7) for f in (12, 16, 12, 16, 14, 18, 14, 18, 16, 20, 16, 20)]),
    ("THUNDER", 1, 6, sweep(8, 28, 31, 12, 0, 60)),       # the Cloud breaks
    # the day job
    ("PUNCH", 0, 2, [(8, 2, 12), (8, 4, 10), (15, 28, 9), (15, 30, 6), (15, 31, 3)]),  # ka-chunk
    ("CLACK", 1, 1, [(8, 1, 6), (8, 3, 3)]),               # the reader steps
    ("BELL", 1, 4, notes_fx(4, [11, 8, 6], 5, 10)),       # a match
    ("JAM", 1, 5, sweep(15, 20, 31, 13, 2, 30)),          # the reader jams
]


def f8(n):
    """the 8-bit voices: POKEY's 64 kHz clock (1.79 MHz / 28)"""
    f = 440.0 * 2 ** ((n + BASE - 69) / 12)
    v = round(1789773 / 28 / (2 * f) - 1)
    return max(0, min(255, v))


def f16(n):
    f = 440.0 * 2 ** ((n + BASE - 69) / 12)
    v = round(1789773 / (2 * f) - 7)
    return max(0, min(65535, v))


def main():
    out = ["; Generated by tools/music.py. Do not edit. The songs (the fixed bank).", ""]
    sfx = ["; Generated by tools/music.py. Do not edit. The effects (the fixed bank).", ""]
    hand = [("porch", 8, "mp", song_porch), ("rain", 9, "mr", song_rain)]
    names = [h[0] for h in hand]
    for i, nm in enumerate(names):
        sfx.append(f"MUS_{nm.upper()} = {i}")
    out.append("song_lo .byte " + ",".join(f"<song_{i}" for i in range(len(names))))
    out.append("song_hi .byte " + ",".join(f">song_{i}" for i in range(len(names))))
    streams = []
    for i, (nm, speed, p, fn) in enumerate(hand):
        out.append(f"song_{i} .byte {speed},$3F")
        out.append("    .word " + ",".join(f"{p}_v{k}" for k in range(6)))
        SPEED[0] = speed
        streams += fn()
    for st in streams:
        if not (st.lines and st.lines[0] == st.label):
            out.append(st.label)
        out += st.lines
    # drum phrases: kick/snare/tom (_k), hats (_h); waits in frames
    for name, txt, sp in (("drum_porch", DRUM_PORCH, 8), ("drum_porchfill", DRUM_PORCHFILL, 8),
                          ("drum_rain", DRUM_RAIN, 9), ("drum_rainfill", DRUM_RAINFILL, 9)):
        seq = drum_parse(txt)
        assert sum(d for _, d in seq) == 16, name
        hats = {DR[h] for h in HATS}
        for suffix, keep in (("_k", lambda n: n is not None and n not in hats),
                             ("_h", lambda n: n is not None and n in hats)):
            part = []
            for n, d in seq:
                n = n if keep(n) else None
                if part and n is None and part[-1][0] is None:
                    part[-1] = (None, part[-1][1] + d)
                else:
                    part.append((n, d))
            out.append(name + suffix)
            for n, d in part:
                out.append(f"    .byte {'$80' if n is None else n},{d * sp}")
            out.append("    .byte $84")
    for i, (nm, env, arp) in enumerate(INSTR):
        out.append(f"ins_env_{i} .byte " + ",".join(str(v) for v in env) + ",$FF")
        if arp:
            out.append(f"ins_arp_{i} .byte " + ",".join(str(v) for v in arp) + ",$FF")
    out.append("ins_env_lo .byte " + ",".join(f"<ins_env_{i}" for i in range(len(INSTR))))
    out.append("ins_env_hi .byte " + ",".join(f">ins_env_{i}" for i in range(len(INSTR))))
    out.append("ins_arp_lo .byte " + ",".join(f"<ins_arp_{i}" if a else "0" for i, (_, _, a) in enumerate(INSTR)))
    out.append("ins_arp_hi .byte " + ",".join(f">ins_arp_{i}" if a else "0" for i, (_, _, a) in enumerate(INSTR)))
    for i, (nm, mac) in enumerate(DRUMS):
        out.append(f"drum_{i} .byte " + ",".join(f"${c:02X},{f}" for c, f in mac) + ",0")
    out.append("drum_lo .byte " + ",".join(f"<drum_{i}" for i in range(len(DRUMS))))
    out.append("drum_hi .byte " + ",".join(f">drum_{i}" for i in range(len(DRUMS))))
    fr = [f16(n) for n in range(108)]
    out.append("f16lo")
    for i in range(0, 108, 12):
        out.append("    .byte " + ",".join(str(v & 255) for v in fr[i:i + 12]))
    out.append("f16hi")
    for i in range(0, 108, 12):
        out.append("    .byte " + ",".join(str(v >> 8) for v in fr[i:i + 12]))
    out.append("f8tab")
    for i in range(0, 108, 12):
        out.append("    .byte " + ",".join(str(f8(n)) for n in range(i, i + 12)))
    for i, (nm, ch, pri, data) in enumerate(SFX):
        sfx.append(f"SFX_{nm} = {i + 1}")
        sfx.append(f"sfxd_{i + 1}")
        for k in range(0, len(data), 12):
            sfx.append("    .byte " + ",".join(f"{c},{f},{v}" for c, f, v in data[k:k + 12]))
        sfx.append("    .byte $FF")
    ids = range(len(SFX) + 1)
    sfx.append("sfx_chan .byte 0," + ",".join(str(s[1]) for s in SFX))
    sfx.append("sfx_pri .byte 0," + ",".join(str(s[2]) for s in SFX))
    sfx.append("sfx_dlo .byte 0," + ",".join(f"<sfxd_{i}" for i in ids if i))
    sfx.append("sfx_dhi .byte 0," + ",".join(f">sfxd_{i}" for i in ids if i))
    GEN.mkdir(parents=True, exist_ok=True)
    (GEN / "music.asm").write_text("\n".join(out) + "\n")
    (GEN / "sfx.asm").write_text("\n".join(sfx) + "\n")
    size = sum(len(l.split(",")) for l in out if ".byte" in l)
    print(f"music: about {size} bytes; {len(names)} songs, {len(SFX)} effects")


if __name__ == "__main__":
    main()
