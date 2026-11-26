#!/bin/sh
# The evening works: a bot reads the forum, downloads and breaks the slop
# ROM, writes and posts the review, and logs off; day 1 with the grumpy
# phrases, day 3 with the constructive ones (all 3 must count). Screenshots
# in build/forum/dayN/.
ROOT=$(cd "$(dirname "$0")/.." && pwd)
A7800=${A7800:-$HOME/Software/a7800/mame64}
cd "$(dirname "$A7800")"
FAIL=0
for d in 1 3; do
  OUT="$ROOT/build/forum/day$d"
  rm -rf "$OUT"; mkdir -p "$OUT"
  LOG=$(DAY=$d "$A7800" a7800 -cart "$ROOT/build/myac.a78" -video none -sound none -nothrottle \
    -snapshot_directory "$OUT" -autoboot_script "$ROOT/tools/emu/forumtest.lua" \
    -skip_gameinfo -nomouse 2>&1 | grep -E "^day|^result|^timed")
  echo "$LOG" | grep -v "^result"
  R=$(echo "$LOG" | sed -n 's/^result //p')
  WANT="1 0 1"; [ $d = 3 ] && WANT="1 3 1"
  [ "$R" = "$WANT" ] || { echo "day $d: FAIL ($R)"; FAIL=1; }
done
[ $FAIL = 0 ] && echo "forum test: PASS" || { echo "forum test: FAIL"; exit 1; }
