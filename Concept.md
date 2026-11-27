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

**Add more than you take away.** The game never asks the player to fix the kid's code. That would just hand the slop's laziness to the player. It's about being present: a bad game and a chat about it beats a good game and an empty chair. Arthur's kind options are welcomes and "me too"s, not patches.

**pixelkid_07 never replies, until the community reaches them.** Through the three evenings pixelkid only posts releases ("PIXELKID_07 IS VIEWING THIS THREAD." is all we see of them). After the mirror chapter, in the wrap-up, pixelkid is in the threads: taking feedback, posting better games (with source), and joining the other discussions.

The game ends at a potluck on Arthur's porch. "Stay for the meal" is literal.

There is no game over. It's a story game, and the ending is always happy.

---

## 2. Story

**Arthur** is a retired mainframe programmer. He does part-time punch-card data entry for a company called **NimbusWorks** and spends his evenings on AtariAge. Lately the new-releases forum is full of hyped games with glossy box art (*SUPER PADDLE BALL DELUXE*, *CYBER NEON BLASTER*, *7800 SKYWOLFENDOOMRIM*). Every one turns out to be a broken Pong clone, posted by a user named **pixelkid_07** who never answers a single reply.

Arthur tears into each game, writes a 1-star review, then walks onto his porch and yells at the sky.

The sky listens. A great cumulus cloud absorbs his anger, swells, and rains on him until he calms down. It leaves one quiet line of text in the rain each night.

On the third night the Cloud, heavy with everything Arthur has yelled into it, drifts across town and stops over the **NimbusWorks data centre**: the machine Arthur's punch cards have been feeding, the one turning out the slop. It lets go. Lightning walks down the server racks, and with every strike the Cloud writes **hex** straight into the machines, byte by byte. Not slop this time: one game, made for one player.

Saturday morning a thread appears with no hype, no box art and zero replies: **`0x7800_MIRROR.BIN`**. It boots into Arthur's own living room, drawn in 8-bit. Through the TV in that room he can walk into other rooms belonging to the forum regulars he argues with every night. And pixelkid_07 is there too.

### The Cloud

The Cloud is **mystical, not technological**. It is not an AI, not a server, not a metaphor anyone explains. It's the same cloud that has hung over every porch where someone sat alone at dusk. Arthur jokes that it's "The Cloud" in the computer sense, and it never confirms or denies that.

Rules for writing the Cloud:

1. It never fights back and never lectures.
2. It speaks only in the rain: **one line per night**, written in 40 columns or fewer.
3. It never tells Arthur he's wrong to love old things. It reminds him why he loves them.
4. It made the mirror ROM, with lightning, writing hex into the NimbusWorks data centre: the slop machine, used once to make something with soul. The player sees it happen. Nobody ever asks how a cloud knows 6502.
5. The charge it lets go is everything Arthur yelled into it. His anger, given back as a gift.

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
| **Day 1 (Mon)** | 1 punch-card job | Break *SUPER PADDLE BALL DELUXE* | Yell. Cloud's first line. |
| **Day 2 (Wed)** | 1 job | Break *CYBER NEON BLASTER* | Yell. Arthur's lines get softer. |
| **Day 3 (Fri)** | 1 job (the whole card) | Break *7800 SKYWOLFENDOOMRIM*. | Yell. The Cloud's key line. Then **the storm** over the data centre. |
| **Finale (Sat)** | The MIRROR thread, then **the mirror ROM:** gather the cards, solve the two-person puzzles, run the deck. | | **Potluck on the porch.** Ending. |

Totals: 3 punch-card jobs, 3 slop ROMs, 3 porch nights, 1 mirror chapter, the ending. Short cutscenes (picture or portrait over 40-column teletype text, as in Gamma Force) link the scenes.

---

## 4. Scene Design

### 4.1 The Day Job: Punch Cards (320A)

**Look:** Crisp monochrome **320A**, the whole screen in one mode. Cream cardstock on a dark terminal, with the reader's output on a printer strip above.

**The card:** **20 columns by 12 rows.** Each column is one instruction.

- **Rows 0–4: opcode.** Punch exactly one: `LOAD`, `ADD`, `CNT`, `LOOP`, `OUT`.
- **Rows 5–11: operand,** 7 bits, 0–127. That's 7-bit ASCII, so `OUT` really does print a letter, and the manual includes an ASCII chart.

**The machine:** two registers: **A** (7 bits, wraps at 128) and the counter **C**.

| Opcode | Effect |
|---|---|
| `LOAD n` | A = n |
| `ADD n` | A = A + n (mod 128). `ADD 127` subtracts 1, a trick the manual hints at. |
| `CNT n` | C = n |
| `LOOP n` | C = C − 1; if C ≠ 0, go to column n (the Z80's `DJNZ`) |
| `OUT` | Print A as an ASCII character |

*(Revised after play-testing: with SHIFT and JMP-if-A, every job could be done with LOAD and OUT alone. A loop needs its own counter so A is free to hold the character; and since LOAD + OUT is two columns a character, any target over 10 characters can't fit on a card without a loop.)*

Running past column 20 halts. A step limit stops infinite loops, and the reader jams with a comic *KA-CHUNK*.

**Controls:** the joystick moves the cursor, button 1 punches or un-punches a hole, and button 2 feeds the card into the reader. The output prints, and if it matches the target, the puzzle is done.

**Puzzle arc:** one job a day (revised after play-testing).

- **Day 1: `HELLO`.** The card comes with `HE` punched (LOAD 72, OUT, LOAD 69, OUT). Teaches LOAD and OUT, and that OUT twice prints the L twice.
- **Day 2: `CART 123456789`.** Text and a simple count: the text by hand, then LOAD '1', CNT 9, OUT, ADD 1, LOOP back to the OUT. Too long for the card without the loop. (NimbusWorks is numbering cartridges. Why?)
- **Day 3: `PONG PONG PONG PONG 54321!`.** The whole card (19 of 20 columns) and every instruction: a counted loop for the PONGs, a countdown loop with ADD 127, and the "!". Arthur realizes NimbusWorks is feeding the slop machine. **A hard challenge on purpose:** no on-screen hint about ADD 127 (the hint line is just "...PONG? WHAT DO THEY WANT WITH PONG?"). The manual has it, and Cloud Assist is always there.

**Hints live in the manual.** A throwback to when computers came with full manuals: the on-screen hints stay short, and the manual has the real help. It's a NimbusWorks operator's guide with the opcode table, an ASCII chart, worked examples (printing a word, a counted loop), the `ADD 127` trick ("the reader has no SUBTRACT; A wraps at 128"), and the coffee-stained Konami note.

**Going home:** below the card's last row is **GO HOME** (back to the menu for now; in the story, home to the porch to yell it out and come back). The card isn't kept.

**Cloud Assist (the Konami code):** on the puzzle screen, enter **↑ ↑ ↓ ↓ ← → ← → B A**, where B is button 2 and A is button 1. Stray cursor moves or punches during the code don't matter, because the solution overwrites the card. The reader solves the card instantly, and the Soul Meter dips (see 4.5). **We want people to try it, so it's hinted in two places:** the manual has a coffee-stained margin note (*"heard you can make the reader do it for you… ask a Contra fan"*), and on Day 1 a forum regular posts it as a rumor. Neither spells out the whole code.

**As built (prototype 3):**
- **The screen:** 320A, 40 columns of text in RAM that MARIA reads live. The font sits at $A000 in the day job's own bank.
- **The card:** the 12 card rows fit in 6 text rows, two to a character. The cell, label and ruler glyphs use the font's odd codes. The card is cream "on" pixels, and a hole is "off" pixels, so the dark screen shows through.
- **The panel:** beside the card, it decodes the cursor's column (OP, VAL and its character) and shows A and the step count while the card runs.
- **Running:** the reader steps through the card every 6 frames with a clack. The output prints in green under the target, and a match rings a bell. Two opcodes in one column, a JMP to nowhere, or 200 steps jams the reader with a KA-CHUNK.
- **The jobs:** one a day, picked on the menu, as in the puzzle arc above. A match ends the shift.
- **Cloud Assist:** the Konami code, ending with B (button 2) and A (button 1). The B is held back so it doesn't run the card, and the card punches itself and runs.
- **GO HOME:** the cursor goes below row 11 onto GO HOME (gold, at the help line's end); button 1 there goes back to the menu.
- **Music:** `MUS_OFFICE`, F major muzak (F, Dm, Gm, C) with a soft thump and tick, under the TIA clacks.
- The Soul Meter comes later.

### 4.2 The Evening: AtariAge Forum and Slop Pong (320A forum, 160A slop)

**Forum look:** an early-2000s forum layout: avatars, post counts, hype threads, and **40-column text in 320A** (the day job's text screen: 20 columns of 160A was too few for posts), each poster in their own colour. The joystick scrolls and selects threads.

**Replies are clues.** Regulars post hints without knowing it ("anyone else get weird symbols when the score gets high?"). Their posts also introduce them before the mirror chapter.

**Slop ROMs:** each boots into an overblown title screen, all palette cycling and logo, and then into a broken Pong clone with **deliberately harsh TIA-only sound**. You don't win. You **break it**. Each game has one signature bug, plus some fake ones that only look broken.

| ROM | The exploit | Crash screen |
|---|---|---|
| *SUPER PADDLE BALL DELUXE* | Every hit scores the combo (1, 2, 4, 8…) and doubles it, while the CPU only ever scores 1. The score is a single byte, so about 8 hits in a row **overflow** it. The digits turn to garbage tiles, and the game crashes. | `SCORE: ▒▓░` → `BRK` |
| *CYBER NEON BLASTER* | The ball speeds up on every hit. At top speed it **tunnels through the top wall** and leaves the screen. | `ERR: BALL NOT FOUND` |
| *7800 SKYWOLFENDOOMRIM* | Flip the **left difficulty switch** mid-rally. The paddle grows each time until it fills the screen and the ball gets stuck inside it. | Paddle fills the screen, then hangs |

**Every ROM is the same Pong, dressed up.** The titles promise the moon (120 FPS, then 240, then "8K RTX AT 480 FPS"); the game behind each is the same broken Pong with something bolted on for no reason, a parody of the era it borrows from:

- *SUPER PADDLE BALL DELUXE*: plain Pong.
- *CYBER NEON BLASTER*: the court's colours slowly cycle through neon hues, and every few seconds a robot marches across the court with a bouncing smiley face chasing it.
- *7800 SKYWOLFENDOOMRIM* (Skyrim, Wolfenstein and Doom in one title, "OPEN WORLD! 900 HRS!"): the court is a tank arena with blocks, two tanks trade shells across the net, and an asteroid drifts by. It's still Pong.

The cameos are drawn fresh for this game, as nods to the arcade era, not copies of the originals' sprites.

**The serve is always in reach.** Each serve comes straight at the player's paddle, and a miss halves the combo instead of resetting it to 1x, so even a sloppy player breaks a ROM in under half a minute. Nobody should have to play slop for ten minutes.

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

The phrase lists grow each day. On **Day 3** a new kind of option appears in every slot ("WELCOME TO THE 7800, KID.", "POST YOUR NEXT ONE. STICK AROUND."). They're welcomes, not fixes. Arthur can still pick the grumpy ones, but the kind ones are what pixelkid_07 remembers in the finale.

**As built (prototype 4):**
- **The script** is one text file, `storyboard/forum.txt`: the regulars (handle, tag, colour, avatar), each evening's threads and posts, the review phrases and the replies. `tools/forum.py` checks it (line lengths, the font's characters) and builds the tables. Swapping in an AtariAge member's name is one line.
- **The thread list:** up to four threads an evening, with who started each and how many replies. The first is always pixelkid_07's release.
- **A thread:** posts with a 4 × 2 character avatar (16 × 16 art, doubled), the name in the poster's colour, a tag ("NEW MEMBER - 3 POSTS", "6502 OR DIE"), and up to four lines. Up and down scroll a post at a time; MORE... says there's more. The release thread says "PIXELKID_07 IS VIEWING THIS THREAD." pixelkid reads every review.
- **Clues and the rumor:** Hal asks about weird symbols when the score gets high (day 1), the ball going through the wall (day 2), and says to try the left difficulty switch (day 3). On day 1, in "NIMBUSWORKS HIRING CARD PUNCHERS??", Hal's uncle knows the card readers have a secret ("UP, UP, DOWN, DOWN... HE NEVER TOLD ME THE REST") and DocMaria says that's a Contra thing.
- **Story beats in the threads:** Sue's "@PIXELKID_07 - YOU THERE?" and DocMaria pointing at the pinned 7800basic thread (day 2), Sue tracing the slop to a generator at NimbusWorks, where Arthur works (day 3), and "HOW DID YOU ALL START?". pixelkid never replies to anyone.
- **Download:** button 1 in the release thread runs the slop ROM. Its crash goes to the review builder.
- **The review builder:** three lines (the opener, the bugs, the verdict). Up and down pick the line, left and right the words. Each slot offers its day's phrases and earlier ones. The bugs slot offers a complaint only for a bug Arthur actually saw. On day 3 every slot gets a kind option, and for the bugs it's a "me too" for a bug he saw ("GHOST BALLS! WE'VE ALL BEEN THERE.", "THE SWITCH TRICK MADE ME LAUGH."), never a fix. The screen's help line: "LEFT-RIGHT: SELECT RESPONSE   1: POST". Button 1 posts it.
- **After posting:** the thread shows Arthur's review and a regular's reply (Hal's "OOF. TOUGH CROWD, ARTHUR.", Sue's "WE WERE ALL NEW ONCE, ARTHUR. THE KID NEEDS A HELLO, NOT A GRADE.", Hal's "SAME OLD ARTHUR."). On day 3 a kind review gets DocMaria's "...ARTHUR? ARE YOU FEELING OK?". The game keeps each day's phrases and how many were kind (`rev_ph`, `rev_kind`) for pixelkid's dialogue in the finale.
- The forum plays its own POKEY loop (`MUS_FORUM`: C major, Am F C G, a modem-handshake chirp at the top).
- Each slop ROM crashes its own way (see the slop ROM table): day 1 the overflow, day 2 the ball speeds up with every hit and on the 6th flies through the walls, wrapping round the screen top to bottom and side to side four times before it's gone ("ERR / BALL NOT FOUND"), day 3 each flip of the left difficulty switch adds a paddle until six fill the court with the ball stuck inside ("HANG / PADDLE OVERFLOW"). Day 3's bottom wall says FLIP LEFT DIFFICULTY. On days 2 and 3 the score and combo overflow only look broken (the combo sticks at 128).

### 4.3 The Night: Yelling at the Cloud (160A)

**Look:** side view. Arthur on his porch at the bottom left, rocking chair behind him, with the Cloud filling the upper sky. It gets darker and grayer as it absorbs his anger.

**Controls:**

- **Joystick:** aims the yell (an arc from the porch).
- **Button 1:** **YELL.** Fires a speech bubble ("NO SOUL!", "IT'S JUST PONG!", "6502 OR DIE!").
- **Button 2 (hold, then release):** **SHAKE FIST.** Hold to wind up and release for a big hit.

**The tension (no failure, only friction):**

1. **The beat.** The Cloud *breathes*, swelling and shrinking in time with the POKEY music, and Arthur's aim swings across it on every beat. A yell lands only when it's let go on the beat. (See "As built" below.)
2. **Blood pressure.** Every yell raises Arthur's **BP gauge**, and it drops when he pauses. Mash the button and he gets dizzy, stumbles back into the rocking chair, and sits for a few seconds while the meter drains slightly. Pacing wins.
3. **Drift.** The Cloud slowly drifts and changes shape, so you have to keep re-aiming. The "soft spot" that counts double moves around.

When the Catharsis Meter fills, the Cloud breaks into warm POKEY rain music and a filtered-noise downpour. The rain is drawn as animated character tiles, plus a few large drops as sprites near Arthur. The night's line is written in the rain:

- **Night 1:** *"…"* (the Cloud just rains)
- **Night 2:** *"You yell like someone who used to laugh a lot."*
- **Night 3:** *"You don't hate the future, Arthur. You just miss making things with your friends."*

Arthur's yell phrases change over the nights. By Night 3 a few are quieter: *"WHY DOESN'T ANYONE ANSWER?"*, *"…I MISS THE OLD THREADS."*

**As built (prototype 2), after the first play test:** aiming *and* timing was too hard, so the aim now does the timing.
- Arthur's aim swings back and forth across the Cloud on a sine wave, 56 pixels each way. It crosses the Cloud's middle on every beat of the music, and the aim dots and crosshair turn yellow while they're over the Cloud. Either button yells: button 1 shouts, button 2 shakes a fist.
- **Hit:** CALM +2, rising to +3, +4 and +5 for a streak of 4, 8 or 12 hits in a row. Dead centre is PERFECT and doubles it. A hit soothes Arthur: BP −2 (PERFECT −4).
- **Miss:** CALM −2, BP +16, and the streak resets.
- **Too fast** (yelling within half a beat of the last yell): CALM −2, BP +16, and the streak resets.
- On its own, BP falls only slowly, by 2 a beat. **While BP is up, CALM drains:** at BP 64 it loses 2 a beat, and near the top about 4. Eight misses in a row, or about a second of mashing, and Arthur is **exhausted**. He sits in the rocking chair for 2½ seconds and comes out at BP 64, still draining, until some hits bring him down.
- The soft spot and the fist wind-up were removed.
- The Cloud is an 80 × 64 sprite in two breathing frames, swelling on each beat. The music builds with CALM: bass, harmony and the beat to start, the lead at 48, everything at 96. The beat is now a clean POKEY thump with a quiet tick between, with no white-noise snare. Perfect play breaks the Cloud in about 9 seconds; mostly-GOOD play takes about 40.
- What Arthur yells: 20 lines, one or two rows each, grouped by night.
  - Night 1 is the classic grumbles: "NO SOUL!", "BLOW ON THE CART!", "PROSYSTEM FOREVER!"…
  - Night 2 adds the hardware rants: "TRAMIEL SHOULD HAVE / RELEASED THE 7800!", "THE 7800 WOULD HAVE / BEAT THE NES!", "MARIA DMA IS SPECIAL", "HOLEY DMA ISN'T A / BUG, IT'S A FEATURE!"…
  - Night 3 mixes in quieter ones about a quarter of the time: "WE USED TO MAKE / THINGS TOGETHER...", "IS ANYONE OUT THERE?"
  - The same line never comes up twice in a row.
- The Cloud's line is typed out in the rain, a page at a time (night 3 has two pages), while the TIA hisses the rain. Then the rain stops and Arthur answers in his own colour: "...HUH. / I FEEL BETTER NOW." (night 1), "I FEEL BETTER NOW. / ...THANKS." (night 2), "I FEEL BETTER NOW. / THANK YOU, CLOUD." (night 3).

### 4.3b The Storm (cutscene, end of Night 3)

After the night 3 rain and Arthur's reply, the Cloud drifts off the porch screen. Cut to the **NimbusWorks data centre** at night: a low building, a humming sign, rows of blinking racks through the windows. The Cloud rolls over it and darkens.

- **Lightning:** bolts strike the roof one at a time (TIA thunder, a POKEY crackle, a white flash of the background colour).
- **The hex:** each strike types a row of hex across a 40-column strip at the bottom of the screen, the Cloud writing the program. They're real 7800 bytes, starting with the boot code every homebrewer knows: `78 D8 A9 07 85 01` (SEI, CLD, LDA #$07, STA INPTCTRL)... Homebrewers will recognise them; nobody else needs to.
- **The end:** the last strike, the racks all light at once, and one line: `0x7800_MIRROR.BIN  WRITTEN.  FOR: ARTHUR`. The Cloud thins out and drifts away. Saturday morning, the thread is on the forum.

It's the one time the player sees the Cloud *do* something rather than rain. It stays mystical: no explanation, no dialogue. The irony is the point: the slop machine Arthur's cards fed, used once to make something with soul.

### 4.4 The Finale: `0x7800_MIRROR.BIN` (160A)

**Look:** top-down 8-bit rooms. Arthur's living room is first. Each TV is a doorway into another regular's room, so the TVs form a little world map of connected rooms.

**Goal:** the Cloud left behind a program split into four cards. **SolderSue, Hal and DocMaria each have one** (half-punched, and each stuck on it). **pixelkid_07 has the fourth** and is hiding in the hub room, a forum-themed room with the big card reader.

**Gathering the cards:** each regular's room is a short puzzle in their own style, using skills the player already has:

- **SolderSue:** finish her card by fixing three bad columns, a short punch puzzle.
- **Hi_Score_Hal:** a two-paddle Pong rally, played properly for once, cooperating to keep the ball alive for 20 hits. This is the one game in the story you play straight, and it's a good one. With one joystick, Hal plays the other paddle (a forgiving CPU partner). With two, **Player 2 takes Hal's paddle.**
- **DocMaria:** a punch-card puzzle using loop and `ADD 127` tricks to produce her card's characters.

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

**Epilogue screen:** the new-releases board again, and pixelkid_07 is everywhere on it: replying in Hal's high-score thread, answering DocMaria's "how did you all start?", thanking people for feedback, and posting a better game with its source. The top thread: *"Our first game. Made by five of us (and a cloud?)"*, posted by pixelkid_07, with replies from everyone. Arthur's review: ★★★★★. Then the credits.

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
| Punch cards | Mechanical clacks and reader *KA-CHUNK*s over POKEY office muzak (`MUS_OFFICE`). |
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
- **Graphics modes, one per scene:** **320A** for the punch cards and the forum (one 40-column text engine, `text40.asm`); **160A** for the slop ROMs, porch and mirror. Modes switch only between scenes, never mid-screen. No display-list interrupt tricks needed.
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
6. **The story pass:** script, cutscenes (including the storm over the data centre), potluck, credits, manual.
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
- **The day job:** one job a day, CNT and LOOP in place of SHIFT and JMP, hints in the manual (a full manual, as computers used to come with), Cloud Assist always there.
- **Where the mirror ROM comes from:** the Cloud's lightning over the NimbusWorks data centre, writing hex into the slop machine: a game made just for the player (the storm cutscene, 4.3b).

## 9. Open Questions

- None right now. Next: prototype step 4, the forum and the review builder.
