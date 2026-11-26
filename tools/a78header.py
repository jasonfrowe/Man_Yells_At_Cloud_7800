#!/usr/bin/env python3
"""Finish the .a78 header that 7800basic wrote: add what it can't say.

  - a second POKEY at $0440 beside the one at $0450 (7800basic's
    "set pokeysupport $450" sets cart type bit 6): cart type bit 10, and the
    v4 audio field (byte 67) = 3, $0440 + $0450 (as Cosmic Arc II)

No AstroCart math unit: this game runs on any SuperGame cart with a POKEY
(the second POKEY is optional, see Concept.md).

usage: a78header.py [--one] IN.a78 OUT.a78
  --one: declare only the POKEY at $0450 (to test the one-POKEY fallback)
"""
import sys

one = "--one" in sys.argv
if one:
    sys.argv.remove("--one")
data = bytearray(open(sys.argv[1], "rb").read())
h = data
assert h[1:10] == b"ATARI7800", "not an .a78 file"
cart = (h[53] << 8) | h[54]
assert cart & 0x0040, "expected POKEY at $0450 (set pokeysupport $450)"
assert cart & 0x0002, "expected SuperGame bank switching"
if not one:
    cart |= 0x0400
h[53], h[54] = cart >> 8, cart & 0xFF
if h[0] >= 4:
    h[67] = 1 if one else 3
open(sys.argv[2], "wb").write(data)
size = (h[49] << 24) | (h[50] << 16) | (h[51] << 8) | h[52]
pokeys = "$0450" if one else "$0450+$0440"
print(f"{sys.argv[2]}: {size // 1024}K, cart type ${cart:04X}, POKEYs {pokeys}")
