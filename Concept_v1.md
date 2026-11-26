# MAN YELLS AT CLOUD

**Platform:** Atari 7800 (Homebrew Cartridge)

**Genre:** Meta-Narrative Arcade / Logic Puzzle / Anti-Pong Simulator

**Controllers:** Standard Atari 7800 Two-Button ProLine Joystick

---

### High Concept

An aging retro-gaming purist wages a one-man war against the flood of soulless, AI-generated homebrew games ruining his favorite classic console. Taking the classic meme literally, he steps onto his porch every evening to scream at the sky—unaware that the massive cumulus cloud absorbing his rage is actually a benevolent manifestation of "The Cloud," acting as his reluctant therapist and quietly trying to reconnect him with the community he’s pushing away.

---

### The Narrative & Story Arc

You play as Arthur, a retired mainframe programmer who spends his days doing legacy punch-card data entry and his evenings lurking on the *AtariAge* forums. Lately, the homebrew scene has been flooded with hyped-up, algorithmically generated games with flashy box art and names like *Super Mega Fun* or *Cyber Neon Blast*—only for every single ROM to turn out to be a barely functional clone of *Pong*.

Every night, Arthur walks onto his porch and yells at the sky about the state of modern computing. Instead of striking him down, the Cloud listens, absorbs his vitriol, and gently rains on him until his blood pressure drops—offering quiet, comforting therapy prompts in the falling droplets.

Midway through the week, Arthur downloads a mysterious, unpolished ROM from the forums (`0x7800_MIRROR.BIN`). Instead of *Pong*, the TV displays a top-down, 8-bit recreation of Arthur’s own living room. As he moves his joystick, his digital avatar mimics him—and soon, tiny sprites representing other cranky forum regulars begin appearing in the digital room with him. They realize they are all staring into the exact same shared portal. The "rogue" game isn't trying to trap them; it’s a subroutine built by the Cloud to show these isolated purists they aren't alone, ultimately guiding them to solve a real-world puzzle that brings them together on Arthur's front porch.

---

### Gameplay Loop (The Three Phases)

The game progresses across seven in-game days, cycling through three distinct gameplay styles tailored to the Atari 7800’s hardware:

#### 1. The Day Job: Punch-Card Logic Puzzles

* **Visuals:** Crisp, high-resolution monochrome aesthetics (utilizing the 7800’s `320B` graphics mode) mimicking an old IBM-style terminal and physical cardstock.
* **Mechanics:** You are given a target output (e.g., printing `"HELLO WORLD"` or sorting an array) and a physical punch-card grid. Using an included mini-manual of 5 simple opcodes (`LOAD`, `ADD`, `SHIFT`, `JMP`, `OUT`), you punch holes into the card and feed it into the reader.
* **The Twist:** As the days go on, the inputs look suspiciously like training weights and game-generation prompts—revealing that Arthur’s day job is unknowingly feeding the exact slop machine he hates.
* **The "LLM" Shortcut:** Players can press a dedicated "Cloud Assist" button to have an AI solve the punch-card instantly. Doing so skips the puzzle, but drains Arthur's "Soul Meter" and makes the forum games even worse the next night.

#### 2. The Evening: *AtariAge* Forums & "Slop Pong"

* **Visuals:** Chunky, vibrant `160A` pixel art recreating a nostalgic early-2000s web forum complete with user avatars, post counts, and hype threads.
* **Mechanics:** Scroll through threads praising revolutionary new releases (*"Ultra Hyper Dungeon 7800!"*, *"Quantum Pixel Quest!"*). Launching a ROM boots up an elaborate, colorful title screen—only to drop you into a broken version of **Pong** with mismatched paddles and terrible hitboxes.
* **The Goal:** You don't win these games; you have to intentionally break them (clipping the ball out of bounds or overflowing the score counter) so you can exit back to the forum and type out a grumpy, 1-star review.

#### 3. The Catharsis: Yelling at the Cloud

* **Visuals:** Side-view yard screen. Arthur stands on his porch on the bottom left; a massive, expressive cumulus cloud fills the upper sky.
* **Mechanics:** A rhythmic, single-screen arcade shooter. Mash the fire buttons and aim upward to launch pixelated speech bubbles, shaking fists, and pure retro vitriol (*"NO SOUL!"*, *"IT'S JUST PONG!"*, *"6502 OR DIE!"*) into the Cloud.
* **The Resolution:** The Cloud never attacks back. It absorbs your words, swells, and turns deep storm-gray. Once the Catharsis Meter maxes out, the Cloud breaks into a soothing chiptune rainstorm. As the rain washes over Arthur, a single line of calm, empathetic text appears in the sky (e.g., *"You don't hate the future, Arthur. You just miss making things with your friends."*), resetting his stress for the next day.

---

### Why the Atari 7800?

* **Maria Chip Sprite Power:** The 7800's custom graphics processor excels at pushing dozens of simultaneous sprites without flicker—ideal for flooding the screen with floating text insults, individual raindrops, and multi-avatar living room scenes.
* **Resolution Switching:** The hardware can switch between `320` wide mode (for readable punch-card code and forum threads) and `160` wide mode (for colorful arcade action and chunky *Pong* clones) on the fly.
* **Audio Contrast:** Using the classic TIA sound chip, the "Slop Pong" games feature harsh, grating, out-of-tune square waves, contrasting sharply with soothing white-noise rainfall and warm basslines during the Cloud's therapy sessions.

---

### Pitch Hook / Tagline

> *"7800 bytes of pure, unfiltered nostalgia. Come for the punch cards, stay for the broken Pong, and scream at the sky until it rains."*
