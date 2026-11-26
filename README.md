# Man Yells at Cloud (Atari 7800)

A story game for the Atari 7800. Arthur, a retired mainframe programmer,
spends his days punching cards, his evenings breaking the AI-generated
Pong clones flooding the AtariAge forums, and his nights yelling at a very
patient cloud. Then a strange ROM shows him his own living room, and the
people he's been arguing with every night.

Everyone is welcome in retrogaming. Don't just leave slop and run: stay
and enjoy the meal.

**Status:** two prototypes, picked from a menu:

1. *SUPER PADDLE BALL DELUXE*: the first slop ROM, from its overblown title
   screen to its crash, showing off the MARIA mistakes a first 7800 program
   makes.
2. *The porch*: Arthur yells at the Cloud on the beat of the POKEY music
   until it breaks into rain and says one thing to him (nights 1 to 3).

The menu shows how many POKEYs it found: the music plays on two, or falls
back to lead, bass and drums on one. See [Concept.md](Concept.md)
for the design ([Concept_v1.md](Concept_v1.md) is the original pitch).

## Building

Needs [wasmtime](https://wasmtime.dev) (7800basic is vendored in
`tools/7800basic` as WebAssembly) and Python 3:

```sh
tools/build.sh        # -> build/myac.a78
tools/test_break.sh   # a bot breaks the slop ROM, headless (a7800 fork)
tools/test_porch.sh   # a bot plays the porch (ONEPOKEY=1: one POKEY)
```

The porch's controls: the stick aims (left and right), button 1 yells,
button 2 winds up a fist (hold) and throws it (let go). Yell on the beat
(the Cloud swells), hit the blue soft spot, and pace yourself: mash, and
Arthur's blood pressure sends him to the rocking chair.

The graphics in `src/gfx/` are committed. After changing the art, remake
them with Pillow: `python3 -m venv .venv && .venv/bin/pip install pillow`,
then `.venv/bin/python tools/gfx.py`.

| Path | |
|---|---|
| `src/myac.bas` | The game (7800basic) |
| `tools/gfx.py` | The art, drawn as text, and the font |
| `tools/test_break.sh`, `tools/emu/breaktest.lua` | Headless test: break the slop ROM |
| `src/asm/sound.asm` | The POKEY music player and TIA effects (from Cosmic Arc II), with the one-POKEY fallback |
| `tools/music.py` | The songs and effects, to `src/gen/` |
| `tools/test_porch.sh`, `tools/emu/porchtest.lua` | Headless test: the porch |
| `tools/dmalog.py` | MARIA's DMA load per line (`A7800_DMA_LOG`, from the a7800 fork) |
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
