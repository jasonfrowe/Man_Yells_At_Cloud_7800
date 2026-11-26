# Man Yells at Cloud (Atari 7800)

A story game for the Atari 7800. Arthur, a retired mainframe programmer,
spends his days punching cards, his evenings breaking the AI-generated
Pong clones flooding the AtariAge forums, and his nights yelling at a very
patient cloud. Then a strange ROM shows him his own living room, and the
people he's been arguing with every night.

Everyone is welcome in retrogaming. Don't just leave slop and run: stay
and enjoy the meal.

**Status:** prototype 1, *SUPER PADDLE BALL DELUXE*: the first slop ROM,
from its overblown title screen to its crash. See [Concept.md](Concept.md)
for the design ([Concept_v1.md](Concept_v1.md) is the original pitch).

## Building

Needs [wasmtime](https://wasmtime.dev) (7800basic is vendored in
`tools/7800basic` as WebAssembly) and Python 3:

```sh
tools/build.sh        # -> build/myac.a78
tools/test_break.sh   # a bot breaks the slop ROM, headless (a7800 fork)
```

The graphics in `src/gfx/` are committed. After changing the art, remake
them with Pillow: `python3 -m venv .venv && .venv/bin/pip install pillow`,
then `.venv/bin/python tools/gfx.py`.

| Path | |
|---|---|
| `src/myac.bas` | The game (7800basic) |
| `tools/gfx.py` | The art, drawn as text, and the font |
| `tools/test_break.sh`, `tools/emu/breaktest.lua` | Headless test: break the slop ROM |
| `tools/snap.sh` | Headless screenshots, with scripted inputs |

## Hardware

- Atari 7800, two-button joystick (a second joystick for the co-op finale
  is optional)
- SuperGame-style cart with dual POKEY ($0450 + $0440)
- No AstroCart Math Unit needed: the game is meant to run for everyone
- Plays fully on a single POKEY (e.g. the 7800GD); the second POKEY adds layers
- Saves to the High Score Cart or SaveKey/AtariVox (optional)
- Tested on real hardware with the AstroCart V4 and the 7800GD

## Related projects

- [AtariGammaForce](https://github.com/jasonfrowe/AtariGammaForce): toolchain, cutscenes, jukebox
- [Cosmic_Arc_II_7800](https://github.com/jasonfrowe/Cosmic_Arc_II_7800): dual-POKEY music
- [a7800 fork](https://github.com/jasonfrowe/a7800): headless emulation and scripted testing

## License

GPL-3.0, as for the other projects in the series.
