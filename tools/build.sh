#!/bin/sh
# Build Man Yells at Cloud with the vendored 7800basic (needs wasmtime on the PATH).
#
#   tools/build.sh   -> build/myac.a78
#
# 7800basic writes its intermediate files next to the source, so the build
# runs in a copy of src/ under build/work and copies the results out.
# The graphics PNGs in src/gfx are committed; remake them with
# .venv/bin/python tools/gfx.py after changing the art.
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BASDIR="$ROOT/tools/7800basic"
WORK="$ROOT/build/work"
PATH="$HOME/.wasmtime/bin:$PATH"

python3 "$ROOT/tools/music.py"
python3 "$ROOT/tools/forum.py"

rm -rf "$WORK"
mkdir -p "$WORK"
cp -R "$ROOT/src/." "$WORK/"
# 7800basic turns an inline file's path into a symbol name, so a "/" in
# it breaks the assembly: assembly files go flat into the work directory.
cp "$ROOT"/src/asm/*.asm "$ROOT"/src/gen/*.asm "$WORK/"
# (and a file can be inlined once: the forum's bank gets its own copy of
# the 40-column font)
cp "$WORK/font320.asm" "$WORK/font320b.asm"
cd "$WORK"
bas7800dir="$BASDIR" PATH="$BASDIR:$PATH" sh "$BASDIR/7800basic.sh" myac.bas > build.log 2>&1 || true
if [ ! -f myac.bas.a78 ] || grep -q -i -E "error|unresolved|Compilation failed" build.log; then
    grep -i -E -B2 -A2 "error|unresolved|failed" build.log | head -60
    echo "BUILD FAILED (full log: build/work/build.log)"
    exit 1
fi
python3 "$ROOT/tools/a78header.py" myac.bas.a78 "$ROOT/build/myac.a78"
grep -E "bytes of ROM space left|used as zone memory" build.log || true
echo "built build/myac.a78"
