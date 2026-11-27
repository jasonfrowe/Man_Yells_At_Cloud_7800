  rem ======================================================================
  rem  MAN YELLS AT CLOUD
  rem  A story game for the Atari 7800. See Concept.md.
  rem
  rem  For now a menu of prototypes:
  rem    1  SLOP ROM FOR DAY n: pixelkid_07's Pong, a new title each day
  rem       (slop.bas)
  rem    2  THE PORCH: yelling at the Cloud, then the rain (porch.bas)
  rem    3  THE DAY JOB: punch cards at NimbusWorks, a job a day (cards.bas)
  rem    4  THE EVENING: the forum, the day's slop ROM, the review (forum.bas)
  rem    5  THE MIRROR: the finale's rooms, pixelkid, the rally (mirror.bas)
  rem  Left and right pick the night / day (1-3) for both.
  rem
  rem  Prototype 1: the slop ROMs. Day 1 SUPER PADDLE BALL DELUXE, day 2
  rem  CYBER NEON BLASTER (neon, robots marching through), day 3 7800
  rem  SKYWOLFENDOOMRIM (a tank arena, an asteroid): each an overblown
  rem  title, then the same broken Pong. Every hit scores the COMBO
  rem  (1, 2, 4, 8...) and doubles it; the CPU only ever scores 1. Score
  rem  and combo are bytes, so on the 8th hit in a row they overflow, the
  rem  HUD turns to garbage, and the game crashes (BRK).
  rem  On the way it shows the MARIA mistakes a first 7800 program makes
  rem  (seenbugs records which, for the review builder):
  rem    1  zone ghosts: after a hit the ball is drawn 16 and 32 lines away
  rem    2  zone clipping: the ball's cut off at a zone's bottom edge
  rem    4  no holey DMA: garbage under the ball in odd zones
  rem    8  DMA overrun: the CPU's paddle flickers when the ball's in its zone
  rem   16  not BCD: the score's digits run 0-9 then : ; < = > ?
  rem   32  the score overflow and the crash
  rem  Slop ROMs use TIA sound only (the POKEYs stay quiet).
  rem ======================================================================

  rem 144K SuperGame (as Atari Gamma Force and Cosmic Arc II): bank 1
  rem fixed at $4000 (the code and the sound driver, which runs in the NMI),
  rem banks 2-8 switched in at $8000 (unused so far), bank 9 fixed at $C000
  rem (the graphics). tools/a78header.py adds the second POKEY ($0440).
  set romsize 144k
  set zoneheight 16
  set zoneprotection on
  set screenheight 192
  set doublewide on
  displaymode 160A
  set 7800header 'name Man Yells at Cloud'
  set pokeysupport $450

  rem ---- variables ----
  dim pady = a
  dim cpuy = b
  dim ballx = c
  dim bally = d
  dim balldx = e
  dim balldy = f
  dim score = g
  dim combo = h
  dim fireheld = j
  dim frm = k
  dim gtime = l
  dim sndt = m
  dim sndsl = n
  dim tunepos = o
  dim tunet = p
  dim combot = q
  dim servet = r
  dim glitch = s
  dim sndf = z
  dim cpuscore = i
  dim ghostt = v
  rem t, u, w, x, y: scratch (todec writes w x y)
  rem the HUD's digits, character codes (glyph * 2)
  dim dscore = var40
  dim dcombo = var43
  dim dcpu = var46
  dim seenbugs = var50

  rem ---- the sound driver's (src/asm/sound.asm) ----
  dim musmask = $2502
  dim pkey2 = $2580
  dim musframe = $2581
  dim sfxon = $2582
  dim sfxid = $2253
  rem TIA effects (tools/music.py SFX): 1 YELL, 2 FIST, 3 GOOD,
  rem 4 PERFECT, 5 MISS, 6 TOOFAST, 7 DIZZY, 8 THUNDER, 9 PUNCH, 10 CLACK,
  rem 11 BELL, 12 JAM

  rem ---- the menu ----
  dim menusel = $2254
  dim stickheld = $2252
  dim night = $2255
  rem (plotchars reads RAM when the screen's drawn: one byte each)
  dim dnum = $2256
  dim dnum2 = $2262

  rem ---- the story so far (kept between scenes) ----
  rem the reviews Arthur posted: rev_ph the phrases (3 a day), rev_done,
  rem rev_kind (how many constructive phrases: the finale remembers)
  dim rev_ph = $2700
  dim rev_done = $2709
  dim rev_kind = $270C
  rem the story: on (1), its step; the cutscene to show; the title's pick
  dim story = $2714
  dim chap = $2715
  dim cutid = $2716
  dim titlesel = $2717
  dim mcards = $2710
  dim mdoor = $2711

  rem Buttons: either fire button starts and continues (joy0fire1 is
  rem button 1 and a one-button stick's, joy0fire0 button 2).

  characterset font
  rem The font's glyphs 0-89 (tools/gfx.py): ASCII 32-95, then tall chrome
  rem A-Z typed as a-z. ^ is a double quote and ~ an apostrophe.
  alphachars ' !^#$%&~()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[~]^_abcdefghijklmnopqrstuvwxyz'

  asm
  jsr snd_init
end
  menusel = 0 : night = 1 : story = 0 : titlesel = 0
  for x = 0 to 14 : rev_ph[x] = 0 : next

  rem ======================================================================
  rem  The title: STORY (the whole thing, a scene after another) or
  rem  PROTOTYPES (the menu, a scene at a time)
  rem ======================================================================
gametitle
  story = 0
  asm
  lda #MUS_TITLE
  jsr mus_play
end
  musmask = $3F
  sfxon = 1 : AUDV0 = 0 : AUDV1 = 0
  BACKGRND = $80
  P0C1 = $0F : P2C1 = $1C : P3C1 = $96
  P5C1 = $08 : P5C2 = $0C : P5C3 = $0F
  clearscreen
  plotchars 'man yells' 1 44 5
  plotchars 'at cloud' 1 48 6
  plotchars 'STORY' 0 60 8
  plotchars 'PROTOTYPES' 0 60 9
  savescreen
  fireheld = 1 : stickheld = 1
titleloop0
  restorescreen
  frm = frm + 1
  t = frm + frm : t = t + t : t = t & $F0
  P1C1 = t + $04 : P1C2 = t + $08 : P1C3 = t + $0E
  rem the Cloud, breathing
  t = frm / 32 : t = t & 1
  plotsprite cloud0 5 40 4 t 4
  t = titlesel + 8
  plotchars '>' 2 48 t
  drawscreen
  if switchreset then reboot
  t = 0
  if joy0up then t = 1
  if joy0down then t = 2
  if t = 0 then stickheld = 0
  if stickheld = 0 && t = 1 then titlesel = 0 : stickheld = 1
  if stickheld = 0 && t = 2 then titlesel = 1 : stickheld = 1
  gosub newfire
  if u = 0 then goto titleloop0
  if titlesel = 1 then goto menu
  rem a new story: everything from the start
  story = 1 : chap = 0 : night = 1
  for x = 0 to 14 : rev_ph[x] = 0 : next
  mcards = 0 : mdoor = 0

  rem ======================================================================
  rem  The story: its steps in order (storystep: kind, then its day or
  rem  cutscene). Each scene, when it's done, comes to scenedone: the next
  rem  step, or (prototypes) the menu.
  rem    1 a cutscene (bank 7)   2 the day job   3 the evening (forum)
  rem    4 the porch   5 the storm (bank 8)   6 the mirror   7 the end
  rem    8 the potluck (bank 8, with the storm)
  rem ======================================================================
storyrun
  t = chap + chap
  u = storystep[t] : t = t + 1 : v = storystep[t]
  if u = 1 then cutid = v : goto cutscene bank7
  if u = 2 then night = v : goto cards bank4
  if u = 3 then night = v : goto forum bank5
  if u = 4 then night = v : goto porch bank3
  if u = 5 then goto storm bank8
  if u = 6 then goto mirror bank6
  if u = 8 then goto potluck bank8
  goto gametitle
scenedone
  characterset font
  if story = 0 then goto menu
  chap = chap + 1
  goto storyrun

  data storystep
  1, 0, 2, 1, 1, 1, 3, 1, 1, 2, 4, 1
  1, 3, 2, 2, 1, 4, 3, 2, 1, 5, 4, 2
  1, 6, 2, 3, 1, 7, 3, 3, 1, 8, 4, 3
  5, 0, 1, 9, 6, 0, 1, 10, 8, 0, 1, 11, 3, 4, 1, 12, 7, 0
end

  rem ======================================================================
  rem  The prototype menu
  rem ======================================================================
menu
  asm
  jsr mus_stop
end
  sfxon = 1 : AUDV0 = 0 : AUDV1 = 0
  BACKGRND = $00
  P0C1 = $0F : P2C1 = $1C : P3C1 = $96
  clearscreen
  plotchars 'man yells' 1 44 1
  plotchars 'at cloud' 1 48 2
  plotchars 'PROTOTYPES' 3 40 4
  plotchars 'SLOP ROM FOR DAY' 0 16 6
  plotchars 'THE PORCH: NIGHT' 0 16 7
  plotchars 'THE DAY JOB: DAY' 0 16 8
  plotchars 'THE EVENING: DAY' 0 16 9
  plotchars 'THE MIRROR' 0 16 10
  plotchars 'POKEYS FOUND:' 3 16 11
  savescreen
  fireheld = 1 : stickheld = 1
menuloop
  restorescreen
  frm = frm + 1
  t = frm + frm : t = t + t : t = t & $F0
  P1C1 = t + $04 : P1C2 = t + $08 : P1C3 = t + $0E
  t = menusel + 6
  plotchars '>' 2 4 t
  dnum = night + night : dnum = dnum + 32
  plotchars dnum 2 152 6 1
  plotchars dnum 2 152 7 1
  plotchars dnum 2 152 8 1
  plotchars dnum 2 152 9 1
  dnum2 = pkey2 + pkey2 : dnum2 = dnum2 + 34
  plotchars dnum2 2 128 11 1
  drawscreen
  if switchreset then reboot
  t = 0
  if joy0up then t = 1
  if joy0down then t = 2
  if joy0left then t = 3
  if joy0right then t = 4
  if t = 0 then stickheld = 0
  if stickheld then goto menufire
  if t then stickheld = 1
  if t = 2 && menusel < 4 then menusel = menusel + 1
  if t = 1 && menusel > 0 then menusel = menusel - 1
  if t = 3 && night > 1 then night = night - 1
  if t = 4 && night < 3 then night = night + 1
menufire
  gosub newfire
  if u = 0 then goto menuloop
  if menusel = 1 then goto porch bank3
  if menusel = 2 then goto cards bank4
  if menusel = 3 then goto forum bank5
  if menusel = 4 then goto mirror bank6
  goto title bank2


  rem ======================================================================
  rem  Helpers
  rem ======================================================================

  rem u = 1 on a new press of either button
newfire
  u = 0
  if joy0fire0 then u = 1
  if joy0fire1 then u = 1
  if u = 0 then fireheld = 0 : return
  if fireheld then u = 0 : return
  fireheld = 1
  return

  rem t (0-255) to decimal digits w x y
todec
  w = 0 : x = 0
todec1
  if t >= 100 then t = t - 100 : w = w + 1 : goto todec1
todec2
  if t >= 10 then t = t - 10 : x = x + 1 : goto todec2
  y = t
  return

  rem play TIA effect sfxid (tools/music.py SFX)
playsfx
  asm
  lda sfxid
  jsr sfx
end
  return

  rem the sound driver: runs every frame from 7800basic's NMI, off screen
userinterrupt
  asm
  jmp snd_tick
end
  inline sound.asm
  inline music.asm
  inline sfx.asm
  inline text40.asm
  rem (the mirror's words: bank 6's code copies them, from here)
  inline mirrortalk.asm

  rem ======================================================================
  rem  The scenes, a bank each (MARIA reads a scene's text from its bank,
  rem  which is switched in at $8000 while the scene runs)
  rem ======================================================================
  bank 2
  incbasic slop.bas

  bank 3
  incbasic porch.bas

  bank 4
  incbasic cards.bas

  bank 5
  incbasic forum.bas

  bank 6
  incbasic mirror.bas

  bank 7
  incbasic cut.bas

  bank 8
  incbasic storm.bas

  bank 9
  rem the fixed bank at $C000: the graphics

  incgraphic gfx/font.png 160A 0 1 2 3
  incgraphic gfx/padp.png 160A 0 1 2 3
  incgraphic gfx/padc.png 160A 0 1 2 3
  incgraphic gfx/ball.png 160A 0 1 2 3
  incgraphic gfx/ballcut0.png 160A 0 1 2 3
  incgraphic gfx/ballcut1.png 160A 0 1 2 3
  incgraphic gfx/ballcut2.png 160A 0 1 2 3
  incgraphic gfx/ballcut3.png 160A 0 1 2 3
  incgraphic gfx/ballcut4.png 160A 0 1 2 3
  incgraphic gfx/garb0.png 160A 0 1 2 3
  incgraphic gfx/garb1.png 160A 0 1 2 3
  incgraphic gfx/spark0.png 160A 0 1 2 3
  incgraphic gfx/spark1.png 160A 0 1 2 3
  incgraphic gfx/spark2.png 160A 0 1 2 3
  incgraphic gfx/cloud0.png 160A 0 1 2 3
  incgraphic gfx/cloud1.png 160A 0 1 2 3
  incgraphic gfx/arthur0.png 160A 0 1 2 3
  incgraphic gfx/arthur1.png 160A 0 1 2 3
  incgraphic gfx/arthur2.png 160A 0 1 2 3
  incgraphic gfx/arthur3.png 160A 0 1 2 3
  incgraphic gfx/chair.png 160A 0 1 2 3
  incgraphic gfx/bubble.png 160A 0 1 2 3
  incgraphic gfx/fist.png 160A 0 1 2 3
  incgraphic gfx/aimdot.png 160A 0 1 2 3
  incgraphic gfx/reticle.png 160A 0 1 2 3
  incgraphic gfx/drop.png 160A 0 1 2 3
  incgraphic gfx/robot0.png 160A 0 1 2 3
  incgraphic gfx/robot1.png 160A 0 1 2 3
  incgraphic gfx/smiley.png 160A 0 1 2 3
  incgraphic gfx/tankr.png 160A 0 1 2 3
  incgraphic gfx/tankl.png 160A 0 1 2 3
  incgraphic gfx/shell.png 160A 0 1 2 3
  incgraphic gfx/rock0.png 160A 0 1 2 3
  incgraphic gfx/rock1.png 160A 0 1 2 3
