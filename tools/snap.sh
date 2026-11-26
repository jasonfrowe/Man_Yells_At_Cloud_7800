#!/bin/sh
# Run a ROM headless in the a7800 emulator, save screenshots (and the sound).
#   tools/snap.sh build/myac.a78 out_dir 60,120,180 [more mame options]
# Screenshots land in out_dir/a7800/, the sound in out_dir/sound.wav.
# A7800 points at the emulator binary (default: ~/Software/a7800/mame64).
ROOT=$(cd "$(dirname "$0")/.." && pwd)
A7800=${A7800:-$HOME/Software/a7800/mame64}
ROM=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
OUT=$2
FRAMES=$3
shift 3
mkdir -p "$OUT"
OUT=$(cd "$OUT" && pwd)
rm -rf "$OUT/a7800"
cd "$(dirname "$A7800")"
SNAP_FRAMES=$FRAMES "$A7800" a7800 -cart "$ROM" -video none -sound none -nothrottle \
  -seconds_to_run 120 -snapshot_directory "$OUT" -autoboot_script "$ROOT/tools/emu/snap.lua" \
  -wavwrite "$OUT/sound.wav" -skip_gameinfo -nomouse "$@" > "$OUT/emu.log" 2>&1
ls "$OUT/a7800" 2>/dev/null
