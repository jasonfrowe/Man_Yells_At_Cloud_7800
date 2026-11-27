#!/bin/sh
# The story holds together: a bot plays from the title's STORY through
# three days (cutscenes, the day job, the evening, the porch) and the
# storm, to the mirror. ENDING=1: from after the mirror, the potluck,
# Sunday's forum and the credits, to the end. Screenshots in build/story/a7800/.
ROOT=$(cd "$(dirname "$0")/.." && pwd)
A7800=${A7800:-$HOME/Software/a7800/mame64}
OUT="$ROOT/build/story"
rm -rf "$OUT"; mkdir -p "$OUT"
cd "$(dirname "$A7800")"
LOG=$("$A7800" a7800 -cart "$ROOT/build/myac.a78" -video none -sound none -nothrottle \
  -snapshot_directory "$OUT" -autoboot_script "$ROOT/tools/emu/storytest.lua" \
  -skip_gameinfo -nomouse 2>&1 | grep -E "^frame|^result")
echo "$LOG" | grep -v "^result"
R=$(echo "$LOG" | sed -n 's/^result //p')
WANT=20; [ -n "$ENDING" ] && WANT=26
case "$R" in
  "$WANT "[0-9]*) echo "story test: PASS (step $WANT in $(echo "$R" | awk '{printf "%.0f", $2 / 60}') s)" ;;
  *) echo "story test: FAIL ($R)"; exit 1 ;;
esac
