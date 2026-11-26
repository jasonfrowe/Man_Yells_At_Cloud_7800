# MAN YELLS AT CLOUD

**Platform:** Atari 7800 homebrew (SuperGame-style bank-switched cart + dual POKEY at `$0450` + `$0440`)
**Genre:** Story game: punch-card puzzles, Pong-breaking, porch catharsis
**Controllers:** ProLine two-button joystick (optional second joystick for the finale)
**Audience:** The AtariAge community. Free, never sold, source on GitHub.
**Built with:** 7800basic + assembly, using the Atari Gamma Force toolchain and the a7800 fork for headless scripted testing.
**Real hardware:** tested on the AstroCart V4. **No AstroCart Math Unit**, so the game runs for the whole community.

> *"7800 bytes of pure, unfiltered nostalgia. Come for the punch cards, stay for the broken Pong, and scream at the sky until it rains."*

*(Revision 2. The original pitch is in `Concept_v1.md`.)*

---

## 1. The Heart of It

**Everyone is welcome in retrogaming. Don't just leave slop and run: stay and enjoy the meal.**

The message goes both ways:

- **To the purists:** gatekeeping drives away the people who might become the next generation of homebrewers. Arthur's 1-star reviews aren't protecting the hobby. They're emptying it.
- **To the newcomers:** dumping a generated ROM and vanishing isn't joining the community. Stay, ask, learn, and make something with people.

The game ends at a potluck on Arthur's porch. "Stay for the meal" is literal.

There is no game over. It's a story game, and the ending is always happy.

---

## 2. Story

**Arthur** is a retired mainframe programmer. He does part-time punch-card data entry for a company called **NimbusWorks** and spends his evenings on AtariAge. Lately the new-releases forum is full of hyped games with glossy box art (*SUPER PADDLE BALL DELUXE*, *CYBER NEON BLAST*, *QUANTUM PIXEL QUEST*). Every one turns out to be a broken Pong clone, posted by a user named **pixelkid_07** who never answers a single reply.

Arthur tears into each game, writes a 1-star review, then walks onto his porch and yells at the sky.

The sky listens. A great cumulus cloud absorbs his anger, swells, and rains on him until he calms down. It leaves one quiet line of text in the rain each night.

Then a thread appears with no hype, no box art and zero replies: **`0x7800_MIRROR.BIN`**. It boots into Arthur's own living room, drawn in 8-bit. Through the TV in that room he can walk into other rooms belonging to the forum regulars he argues with every night. And pixelkid_07 is there too.

### The Cloud

The Cloud is **mystical, not technological**. It is not an AI, not a server, not a metaphor anyone explains. It's the same cloud that has hung over every porch where someone sat alone at dusk. Arthur jokes that it's "The Cloud" in the computer sense, and it never confirms or denies that.

Rules for writing the Cloud:

1. It never fights back and never lectures.
2. It speaks only in the rain: **one line per night**, written in 40 columns or fewer.
3. It never tells Arthur he's wrong to love old things. It reminds him why he loves them.
4. It made the mirror ROM. Nobody ever asks how.

### Cast

| Name | Who they are | In the mirror |
|---|---|---|
| **Arthur** | The grump. Wrote COBOL for 30 years. Knows 6502 cold. Lonely and won't say so. | Player 1 |
| **pixelkid_07** | A teenager who wanted to make a 7800 game, didn't know where to start, and was too nervous to ask. Used a generator, posted, and ran. Read every one of Arthur's reviews. | NPC follower, or **Player 2** |
| **SolderSue** | Hardware hacker. Builds carts and mods consoles. Blunt, generous. | Holds card 1 |
| **Hi_Score_Hal** | Leaderboard obsessive. Lives for the twin-stick high score threads. | Holds card 2 |
| **DocMaria** | Chip historian. Named after the graphics chip and won't stop telling you. | Holds card 3 |

The regulars are the same people Arthur argues with in the forum scenes, so the player already knows them by the time they meet in the mirror.

**The names are placeholders.** The regulars stay generic "types" for now. Later, AtariAge members will be invited to lend their forum names to the cast: walk-on posters in the forum threads, and possibly the named regulars. Keep every forum name in one table in the script so swapping names is a one-line change.

---

## 3. Structure (Reduced Scope)

**Three days plus a finale.** Each day has three scenes, and the finale is the mirror ROM plus the potluck.

| | Day job | Evening forum | Night porch |
|---|---|---|---|
| **Day 1 (Mon)** | 3 punch-card puzzles | Break *SUPER PADDLE BALL DELUXE* | Yell. Cloud's first line. |
| **Day 2 (Wed)** | 3 puzzles | Break *CYBER NEON BLAST* | Yell. Arthur's lines get softer. |
| **Day 3 (Fri)** | 3 puzzles | Break *QUANTUM PIXEL QUEST*. Then the MIRROR thread appears. | Yell. The Cloud's key line. |
| **Finale (Sat)** | **The mirror ROM:** gather the cards, solve the two-person puzzles, run the deck. | | **Potluck on the porch.** Ending. |

Totals: 9 puzzles, 3 slop ROMs, 3 porch nights, 1 mirror chapter, the ending. Short cutscenes (picture or portrait over 40-column teletype text, as in Gamma Force) link the scenes.

---

## 4. Scene Design

### 4.1 The Day Job: Punch Cards (320A)

**Look:** Crisp monochrome **320A**, the whole screen in one mode. Cream cardstock on a dark terminal, with the reader's output on a printer strip above.

**The card:** **20 columns by 12 rows.** Each column is one instruction.

- **Rows 0–4: opcode.** Punch exactly one: `LOAD`, `ADD`, `SHIFT`, `JMP`, `OUT`.
- **Rows 5–11: operand,** 7 bits, 0–127. That's 7-bit ASCII, so `OUT` really does print a letter, and the manual includes an ASCII chart.

**The machine:** one register, **A** (7 bits, wraps at 128).

| Opcode | Effect |
|---|---|
| `LOAD n` | A = n |
| `ADD n` | A = A + n (mod 128). `ADD 127` subtracts 1, a trick the manual hints at. |
| `SHIFT` | A = A × 2 (mod 128) |
| `JMP n` | If A ≠ 0, go to column n |
| `OUT` | Print A as an ASCII character |

Running past column 20 halts. A step limit stops infinite loops, and the reader jams with a comic *KA-CHUNK*.

**Controls:** the joystick moves the cursor, button 1 punches or un-punches a hole, and button 2 feeds the card into the reader. The output prints, and if it matches the target, the puzzle is done.

**Puzzle arc:**

- **Day 1** teaches LOAD/OUT/ADD: print `HI`, then `HELLO`, then `ABCDE` cheaply using ADD.
- **Day 2** teaches SHIFT and loops with JMP: print `AAAAAAAA` in fewer columns than letters.
- **Day 3** uses everything. The targets turn uncomfortable: `PONG`, `PONG PONG`, `MAKE GAME=PONG`. Arthur realizes NimbusWorks is feeding the slop machine.

**Cloud Assist (the Konami code):** on the puzzle screen, enter **↑ ↑ ↓ ↓ ← → ← → B A**, where B is button 2 and A is button 1. Stray cursor moves or punches during the code don't matter, because the solution overwrites the card. The reader solves the card instantly, and the Soul Meter dips (see 4.5). **We want people to try it, so it's hinted in two places:** the manual has a coffee-stained margin note (*"heard you can make the reader do it for you… ask a Contra fan"*), and on Day 1 a forum regular posts it as a rumor. Neither spells out the whole code.

### 4.2 The Evening: AtariAge Forum and Slop Pong (160A)

**Forum look:** chunky, colorful **160A** with an early-2000s forum layout: avatars, post counts, hype threads, and 40-column text. The joystick scrolls and selects threads.

**Replies are clues.** Regulars post hints without knowing it ("anyone else get weird symbols when the score gets high?"). Their posts also introduce them before the mirror chapter.

**Slop ROMs:** each boots into an overblown title screen, all palette cycling and logo, and then into a broken Pong clone with **deliberately harsh TIA-only sound**. You don't win. You **break it**. Each game has one signature bug, plus some fake ones that only look broken.

| ROM | The exploit | Crash screen |
|---|---|---|
| *SUPER PADDLE BALL DELUXE* | Every hit scores the combo (1, 2, 4, 8…) and doubles it, while the CPU only ever scores 1. The score is a single byte, so about 8 hits in a row **overflow** it. The digits turn to garbage tiles, and the game crashes. | `SCORE: ▒▓░` → `BRK` |
| *CYBER NEON BLAST* | The ball speeds up on every hit. At top speed it **tunnels through the top wall** and leaves the screen. | `ERR: BALL NOT FOUND` |
| *QUANTUM PIXEL QUEST* | Flip the **left difficulty switch** mid-rally. The paddle grows each time until it fills the screen and the ball gets stuck inside it. | Paddle fills the screen, then hangs |

The difficulty-switch trick is a nod to 2600 paddle games, where the A/B switches set paddle size, and it gets players flipping real console switches.

**Real 7800 programming mistakes.** Besides its signature crash, each slop ROM shows the MARIA mistakes a first 7800 program makes. Homebrewers will recognise them, and each one becomes a canned complaint in the review builder, offered only if Arthur actually saw it. *SUPER PADDLE BALL DELUXE* has:

| Bug | What you see | Review line |
|---|---|---|
| Zone ghosts | After a hit, copies of the ball appear 16 and 32 lines away, still sitting in other zones' display lists | "BALL IN EVERY ZONE." |
| Zone clipping | The ball is cut off where it crosses a zone's bottom edge | "BALL CLIPS AT ZONES." |
| No holey DMA | Garbage appears under the ball in odd zones | "NO HOLEY DMA? LOL." |
| DMA overrun | The CPU's paddle flickers when the ball is in its zone | "PADDLE FLICKERS." |
| Not BCD | The score's digits run 0–9, then `: ; < = > ?` | "SCORE ISN'T BCD." |
| Overflow | The crash | "SCORE OVERFLOWS." |

The other two slop ROMs get their own mix, for example palette writes landing at the wrong time, a sprite wrapping at x = 160, or a forgotten `drawscreen`.
