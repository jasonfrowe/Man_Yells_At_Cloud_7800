#!/bin/sh
# The mirror works: a bot walks Arthur through the TVs, talks pixelkid into
# joining, joins as player 2, opens the hub's door (both plates) and wins
# Hal's rally, and gets Sue's and Maria's cards. Screenshots in build/mirror/a7800/.
ROOT=$(cd "$(dirname "$0")/.." && pwd)
A7800=${A7800:-$HOME/Software/a7800/mame64}
OUT="$ROOT/build/mirror"
rm -rf "$OUT"; mkdir -p "$OUT"
cd "$(dirname "$A7800")"
LOG=$("$A7800" a7800 -cart "$ROOT/build/myac.a78" -video none -sound none -nothrottle \
  -snapshot_directory "$OUT" -autoboot_script "$ROOT/tools/emu/mirrortest.lua" \
  -skip_gameinfo -nomouse 2>&1 | grep -E "^frame|^result|^stuck|^timed")
echo "$LOG" | grep -v "^result"
R=$(echo "$LOG" | sed -n 's/^result //p')
[ "$R" = "3 1 7" ] && echo "mirror test: PASS" || { echo "mirror test: FAIL ($R)"; exit 1; }
