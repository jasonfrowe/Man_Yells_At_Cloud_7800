#!/bin/sh
# The day job works, a day a run: day 1 goes home (GO HOME) and back, then
# a bot punches HELLO's rest by hand; days 2 and 3 Cloud Assist (the Konami
# code). Each must match and go home. Screenshots in build/cards/dayN/.
ROOT=$(cd "$(dirname "$0")/.." && pwd)
A7800=${A7800:-$HOME/Software/a7800/mame64}
cd "$(dirname "$A7800")"
FAIL=0
for d in 1 2 3; do
  OUT="$ROOT/build/cards/day$d"
  rm -rf "$OUT"; mkdir -p "$OUT"
  LOG=$(DAY=$d "$A7800" a7800 -cart "$ROOT/build/myac.a78" -video none -sound none -nothrottle \
    -snapshot_directory "$OUT" -autoboot_script "$ROOT/tools/emu/cardtest.lua" \
    -skip_gameinfo -nomouse 2>&1 | grep -E "^day|^went|^result")
  echo "$LOG" | grep -v "^result"
  R=$(echo "$LOG" | sed -n 's/^result //p')
  WANT="1 0 1"; [ $d = 1 ] && WANT="1 1 1"
  [ "$R" = "$WANT" ] || { echo "day $d: FAIL ($R)"; FAIL=1; }
done
[ $FAIL = 0 ] && echo "cards test: PASS" || { echo "cards test: FAIL"; exit 1; }
