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

**The review builder:** after the crash, Arthur writes a review from three slots of canned phrases, a Mad Libs for grumps:

> **[ NO SOUL. ]** **[ HITBOXES OF A POTATO. ]** **[ ★☆☆☆☆ ]**

The phrase lists grow each day. On **Day 3** a new kind of option appears in every slot ("HERE'S HOW TO FIX THE BALL SPEED.", "DM ME IF YOU WANT HELP."). Arthur can still pick the grumpy ones, but the constructive ones are what pixelkid_07 remembers in the finale.

### 4.3 The Night: Yelling at the Cloud (160A)

**Look:** side view. Arthur on his porch at the bottom left, rocking chair behind him, with the Cloud filling the upper sky. It gets darker and grayer as it absorbs his anger.

**Controls:**

- **Joystick:** aims the yell (an arc from the porch).
- **Button 1:** **YELL.** Fires a speech bubble ("NO SOUL!", "IT'S JUST PONG!", "6502 OR DIE!").
- **Button 2 (hold, then release):** **SHAKE FIST.** Hold to wind up and release for a big hit.

**The tension (no failure, only friction):**

1. **The beat.** The Cloud *breathes*, swelling and shrinking in time with the POKEY music. Yells and fist releases that land on the beat fill the **Catharsis Meter** much more than ones that don't.
2. **Blood pressure.** Every yell raises Arthur's **BP gauge**, and it drops when he pauses. Mash the button and he gets dizzy, stumbles back into the rocking chair, and sits for a few seconds while the meter drains slightly. Pacing wins.
3. **Drift.** The Cloud slowly drifts and changes shape, so you have to keep re-aiming. The "soft spot" that counts double moves around.

When the Catharsis Meter fills, the Cloud breaks into warm POKEY rain music and a filtered-noise downpour. The rain is drawn as animated character tiles, plus a few large drops as sprites near Arthur. The night's line is written in the rain:

- **Night 1:** *"…"* (the Cloud just rains)
- **Night 2:** *"You yell like someone who used to laugh a lot."*
- **Night 3:** *"You don't hate the future, Arthur. You just miss making things with your friends."*

Arthur's yell phrases change over the nights. By Night 3 a few are quieter: *"WHY DOESN'T ANYONE ANSWER?"*, *"…I MISS THE OLD THREADS."*

**As built (prototype 2):**
- The Cloud is an 80 × 64 sprite in two breathing frames. It swells for the first 10 frames of each beat. A yell or fist let go within about 5 frames of the beat counts double, and so does a soft-spot hit.
- Points: a yell is worth 2 and a fist 3 + power / 8, against a CALM of 128. Perfect play breaks the Cloud in about 13 seconds; a typical player takes closer to a minute.
- BP: +12 a yell (a fist +6 + power / 4), and it falls by 16 a beat. One yell on every beat holds steady, while mashing makes Arthur dizzy in about 2 seconds. Dizzy lasts 2½ seconds and costs 8 CALM.
- The music builds with CALM: bass and drums first, then harmony at 32, lead at 64, and everything at 96.
- The Cloud's line is typed out in the rain, a page at a time (night 3 has two pages). The TIA hisses the rain.

### 4.4 The Finale: `0x7800_MIRROR.BIN` (160A)

**Look:** top-down 8-bit rooms. Arthur's living room is first. Each TV is a doorway into another regular's room, so the TVs form a little world map of connected rooms.

**Goal:** the Cloud left behind a program split into four cards. **SolderSue, Hal and DocMaria each have one** (half-punched, and each stuck on it). **pixelkid_07 has the fourth** and is hiding in the hub room, a forum-themed room with the big card reader.

**Gathering the cards:** each regular's room is a short puzzle in their own style, using skills the player already has:

- **SolderSue:** finish her card by fixing three bad columns, a short punch puzzle.
- **Hi_Score_Hal:** a two-paddle Pong rally, played properly for once, cooperating to keep the ball alive for 20 hits. This is the one game in the story you play straight, and it's a good one. With one joystick, Hal plays the other paddle (a forgiving CPU partner). With two, **Player 2 takes Hal's paddle.**
- **DocMaria:** a punch-card puzzle using `SHIFT` tricks to produce her card's characters.

**pixelkid_07:** Arthur finds them in the hub. The dialogue depends on which reviews Arthur wrote, but every branch ends with pixelkid admitting they didn't know how to start and were afraid to ask. Arthur realizes the target of his anger was a kid who wanted in. Then pixelkid joins and follows Arthur for the rest of the chapter.

**Two-person puzzles:** the hub's machinery needs two people:

- A **door with two pressure plates**: both must be held at once.
- The **card reader**: one person holds the feed lever while the other drops in the cards, in order.
- One **timing lock**: a pair of switches that must be pressed on the same beat.

**One player:** pixelkid_07 follows Arthur. Button 2 toggles **"Wait here" / "Follow me,"** so you can park them on a plate or the lever.
**Two players:** plug in a second joystick and press fire at any time during the finale. **Player 2 becomes pixelkid_07.** Welcoming a second player into your game is the theme, literally.

**Design rule for every two-person moment:** one person holding two joysticks must be able to do it alone. That means:

- At any moment, one role is **"hold"** (stand on a plate, push and hold a lever, or hold a direction) and the other is **"act"**. Never ask for precise movement on both sticks at once.
- A held role latches for a few seconds after it's let go, so a solo player can switch hands.
- Timing locks give a generous window (about half a second), not frame-perfect.
- Hal's rally uses slow, wide paddles. It's a duet, not a contest.

The aim is that someone playing alone *wants* to pass the second stick to a friend, but never *needs* to.

**The output:** the four cards run as one deck, and the printer strip slowly types:

```
SAT 6PM. ARTHUR'S PORCH.
BRING A DISH. BRING A CART.
EVERYONE WELCOME.
```

That's the "real-world puzzle": the community's combined program turns out to be an invitation, and it only works because everyone contributed a card.

### 4.5 The Ending: The Potluck

The porch at dusk, side view again. Arthur, SolderSue, Hal, DocMaria and pixelkid_07 are there with casserole dishes, a CRT on an extension cord, a stack of carts, and a 7800 on a card table.

The Cloud drifts overhead. For the first time Arthur doesn't yell. He waves. The Cloud rains one last, very light shower, then parts to show the stars. Its final line:

> *"Stay for the meal."*

**Epilogue screen:** a new forum thread, *"Our first game. Made by five of us (and a cloud?)"*, posted by pixelkid_07, with replies from everyone. Arthur's review: ★★★★★. Then the credits.

### 4.6 The Soul Meter

The Soul Meter is **flavor, not a fail state.**

- It dips a little when Arthur uses Cloud Assist or picks the harshest review phrases.
- It rises a little from on-beat catharsis and constructive reviews.
- Its only effects are **jokes and flavor**: slop ROMs get extra-sloppy title screens (more lens flares, worse spelling), some forum replies change, and pixelkid_07's first lines in the finale vary.
- **In the potluck it fills by itself, all the way, whatever happened.** The ending is the same for everyone.

### 4.7 Free Play (after the credits)

Finishing the story unlocks **FREE PLAY** on the title screen, an arcade-cabinet menu in the style of Gamma Force's jukebox:

- **The three slop ROMs**, playable on their own, with their title screens and the bugs left in. A small "BUGS FOUND: 1/1" tag shows whether you've found each crash. Hidden extra bugs are a stretch goal.
- **Hal's co-op rally**, for one player with the CPU or two players. It keeps a best-rally count, saved to the High Score Cart or SaveKey if present.
- **The jukebox:** every POKEY tune from the game.

The unlock is kept in the High Score Cart or SaveKey if one is present. Without one, a code on the credits screen unlocks it.

---

## 5. Audio

| Scene | Sound |
|---|---|
| Slop ROMs | **TIA only**, deliberately harsh: off-key square waves and rude buzzes. TIA's natural detuning is the joke. Both POKEYs go silent, so the contrast is total. |
| Punch cards | Mechanical clacks and reader *KA-CHUNK*s, with a quiet POKEY office hum. |
| Forum | A light POKEY "dial-up nostalgia" loop. |
| Porch (yelling) | A POKEY beat that drives the Cloud's breathing, and gets tenser as the Cloud darkens. |
| Rain | Warm POKEY bass and pads plus a filtered noise downpour. |
| Potluck and credits | The full theme, warm. |

**Dual POKEY,** laid out like Cosmic Arc II: POKEY 1 at `$0450` (`set pokeysupport $450`) and POKEY 2 at `$0440`, with the a78 header's dual-POKEY flag set. The music comes from Cosmic Arc II's `tools/music.py` stream format and the vendored `musicgen` composer: six voices.

| Voice | Where |
|---|---|
| Lead | POKEY 1, channels 1+2 (16-bit) |
| Bass | POKEY 1, channels 3+4 (16-bit) |
| Harmony / arpeggio | POKEY 2, channel 1 |
| Pad | POKEY 2, channel 2 |
| Drums | POKEY 2, channel 3 |
| Hats | POKEY 2, channel 4 |

The rain's noise and the porch beat's kick get their own channels, so the beat the Cloud breathes to always comes through the music.

**Single-POKEY fallback (required):** many players will run this on a **7800GD** or another one-POKEY setup rather than an AstroCart. At boot the game checks for POKEY 2. If it's missing, the music plays lead and bass only, and the porch beat moves to POKEY 1. The game sounds thinner but loses nothing you need to play it. Test on both the AstroCart V4 (dual) and the 7800GD (single). Every song must sound complete on POKEY 1 alone, so POKEY 2 only adds harmony, pad, drums and hats on top.

---

## 6. Technical Plan

- **Cart:** SuperGame-style bank switching: **144K**, with bank 1 fixed at $4000 (code and the sound driver) and bank 9 fixed at $C000 (graphics), as in Gamma Force and Cosmic Arc II. It can grow to 272K. Dual POKEY at `$0450` + `$0440`. Add cart RAM only if a scene needs it. The forum text and puzzle state should fit in the 7800's 4K.
- **Hardware rules:** nothing that only the AstroCart has. **No Math Unit:** the game's arithmetic (Pong physics, aiming arcs) uses tables and 8-bit math. Real-hardware testing is on the AstroCart V4. The emulator tests use the a7800 fork with only the features a stock cart has.
- **Saves:** both the **High Score Cart and SaveKey / AtariVox**, through 7800basic's built-in support. They hold the Free Play unlock and Hal's best rally, and both are optional. The HSC game slot and the SaveKey address range will be assigned when save code is written (a free range is still to be found).
- **Graphics modes, one per scene:** **320A** for the punch cards; **160A** for the forum, slop ROMs, porch and mirror. Modes switch only between scenes, never mid-screen. No display-list interrupt tricks needed.
- **Rain and text effects:** the rain is **animated character tiles** (cheap for MARIA), with a few sprite drops near Arthur. Speech bubbles are sprites, with a small cap on how many exist at once. Measure the DMA load per line with `tools/dmalog.py`.
- **Text:** 40-column teletype text in the Gamma Force cutscene style. The script lives in one file (`storyboard/script.txt`) and is generated into banks.
- **Bank layout (rough):** core and title; punch-card engine and puzzles; forum and review builder; the slop ROMs (one engine with each game's bug as a flag); porch; mirror; cutscenes and text; music.
- **Testing:** headless scripted play with the a7800 fork (`play.sh`-style input scripts, screenshots and memory peeks). Each slop ROM's exploit and each puzzle's solution should be an automated test.
- **Reused from Gamma Force:** the build script, vendored 7800basic, text-art sprite pipeline, palette preview, cutscene generator, jukebox, profiler, and the manual generator.
- **Reused from Cosmic Arc II:** the dual-POKEY sound driver, `tools/music.py` and `musicgen`, and the a78 header tool.

### Development

- **Public on GitHub** from day one, GPL-3.0 like the rest of the series, with regular pushes as work progresses.
- **Commit messages are short one-line stubs** (e.g. `Add punch-card reader`).
- A progress post on AtariAge at each milestone, with a playable `.a78`.

---

## 7. Prototype Order

1. **One slop ROM, start to crash:** *SUPER PADDLE BALL DELUXE* and the overflow exploit. This proves the core joke and the Pong engine.
2. **The porch:** aiming, beat, BP gauge, catharsis, rain. This proves the POKEY beat sync and the rain DMA budget.
3. **The punch-card engine** in 320A with 3 puzzles.
4. **The forum and review builder.**
5. **The mirror ROM:** rooms, follower AI, two-player join.
6. **The story pass:** script, cutscenes, potluck, credits, manual.
7. **Free Play:** the menu, the jukebox, saves.

---

## 8. Decisions Log

- **Regulars:** generic types for now. AtariAge members will be invited to lend their forum names later.
- **Konami code:** hinted in both the manual and the forum.
- **Hal's rally:** Player 2 if a second joystick is present, a CPU partner otherwise. Every two-person moment can be done by one person with two sticks.
- **Free Play:** yes, after the credits: the slop ROMs, Hal's rally and the jukebox.
- **Hardware:** dual POKEY yes, AstroCart Math Unit no.
- **POKEY fallback:** kept. The game must play fully on a single-POKEY 7800GD.
- **Saves:** both the High Score Cart and SaveKey. A free SaveKey range is to be found when needed.

## 9. Open Questions

- None right now. Next: prototype step 1, *SUPER PADDLE BALL DELUXE*.
