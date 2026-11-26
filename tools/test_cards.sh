#!/bin/sh
# The day job works: a bot punches job 1 by hand and matches it, then
# Cloud Assists (the Konami code) through jobs 2 and 3, to the end of the
# shift. Screenshots land in build/cards/a7800/.
ROOT=$(cd "$(dirname "$0")/.." && pwd)
A7800=${A7800:-$HOME/Software/a7800/mame64}
OUT="$ROOT/build/cards"
rm -rf "$OUT"; mkdir -p "$OUT"
cd "$(dirname "$A7800")"
LOG=$("$A7800" a7800 -cart "$ROOT/build/myac.a78" -video none -sound none -nothrottle \
  -snapshot_directory "$OUT" -autoboot_script "$ROOT/tools/emu/cardtest.lua" \
  -skip_gameinfo -nomouse 2>&1 | grep -E "^job|^the shift|^result")
echo "$LOG" | grep -v "^result"
echo "$LOG" | sed -n 's/^result //p' | awk '{ if ($1 == 3) { print "cards test: PASS"; exit 0 } print "cards test: FAIL"; exit 1 }'
