#!/bin/sh
# The porch plays fair: mashing makes Arthur dizzy, yelling off the beat
# misses and loses CALM, and yelling on the beat breaks the Cloud within
# 40 s without making him dizzy. Screenshots of
# the porch and the rain land in build/porch/a7800/.
#   tools/test_porch.sh            two POKEYs
#   ONEPOKEY=1 tools/test_porch.sh one POKEY (the fallback)
ROOT=$(cd "$(dirname "$0")/.." && pwd)
A7800=${A7800:-$HOME/Software/a7800/mame64}
OUT="$ROOT/build/porch"
ROM="$ROOT/build/myac.a78"
if [ -n "$ONEPOKEY" ]; then
    python3 "$ROOT/tools/a78header.py" --one "$ROOT/build/work/myac.bas.a78" "$ROOT/build/myac1.a78" > /dev/null
    ROM="$ROOT/build/myac1.a78"
fi
rm -rf "$OUT"; mkdir -p "$OUT"
cd "$(dirname "$A7800")"
LOG=$("$A7800" a7800 -cart "$ROM" -video none -sound none -nothrottle \
  -snapshot_directory "$OUT" -autoboot_script "$ROOT/tools/emu/porchtest.lua" \
  -wavwrite "$OUT/sound.wav" -skip_gameinfo -nomouse 2>&1 | grep -E "^mashing|^off|^on|^result")
echo "$LOG" | grep -v "^result"
echo "$LOG" | sed -n 's/^result //p' | awk '{ if ($1 > 0 && $2 >= 0 && $2 < 40 && $3 == 0 && $4 > 0 && $4 <= 2400) { print "porch test: PASS"; exit 0 } print "porch test: FAIL"; exit 1 }'
