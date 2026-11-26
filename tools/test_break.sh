#!/bin/sh
# The slop ROM can be broken: a bot steering for paddle-edge hits must
# overflow the score and reach the crash within a minute of play, having
# seen all six MARIA bugs (seenbugs = 63) on the way.
# Screenshots of the glitch and the crash land in build/break/a7800/.
ROOT=$(cd "$(dirname "$0")/.." && pwd)
A7800=${A7800:-$HOME/Software/a7800/mame64}
OUT="$ROOT/build/break"
rm -rf "$OUT"; mkdir -p "$OUT"
cd "$(dirname "$A7800")"
LOG=$("$A7800" a7800 -cart "$ROOT/build/myac.a78" -video none -sound none -nothrottle \
  -snapshot_directory "$OUT" -autoboot_script "$ROOT/tools/emu/breaktest.lua" \
  -skip_gameinfo -nomouse "$@" 2>&1 | grep -E "^frame|^result")
echo "$LOG" | grep -v "^result"
echo "$LOG" | sed -n 's/^result //p' | awk '{ if ($1 > 0 && $1 <= 3600 && $2 == 63) { printf "break test: PASS (%.1f s of play, all 6 bugs seen)\n", $1 / 60; exit 0 } printf "break test: FAIL (frames %d, seenbugs %d of 63)\n", $1, $2; exit 1 }'
