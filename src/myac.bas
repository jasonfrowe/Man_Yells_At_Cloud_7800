  rem ======================================================================
  rem  MAN YELLS AT CLOUD
  rem  A story game for the Atari 7800. See Concept.md.
  rem
  rem  For now a menu of prototypes:
  rem    1  SUPER PADDLE BALL DELUXE, the first slop ROM (below)
  rem    2  THE PORCH: yelling at the Cloud, then the rain (further down)
  rem
  rem  Prototype 1: SUPER PADDLE BALL DELUXE, the first slop ROM.
  rem  An overblown title, then a broken Pong. Every hit scores the COMBO
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
  rem 4 PERFECT, 5 MISS, 6 TOOFAST, 7 DIZZY, 8 THUNDER

  rem ---- the menu ----
  dim menusel = $2254
  dim stickheld = $2252
  dim night = $2255
  rem (plotchars reads RAM when the screen's drawn: one byte each)
  dim dnum = $2256
  dim dnum2 = $2262

  rem Buttons: either fire button starts and continues (joy0fire1 is
  rem button 1 and a one-button stick's, joy0fire0 button 2).

  characterset font
  rem The font's glyphs 0-89 (tools/gfx.py): ASCII 32-95, then tall chrome
  rem A-Z typed as a-z. ^ is a double quote and ~ an apostrophe.
  alphachars ' !^#$%&~()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[~]^_abcdefghijklmnopqrstuvwxyz'

  asm
  jsr snd_init
end
  menusel = 0 : night = 1

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
  plotchars 'SUPER PADDLE BALL' 0 16 6
  plotchars 'THE PORCH: NIGHT' 0 16 7
  plotchars 'POKEYS FOUND:' 3 16 10
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
  plotchars dnum 2 152 7 1
  dnum2 = pkey2 + pkey2 : dnum2 = dnum2 + 34
  plotchars dnum2 2 128 10 1
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
  if t = 1 then menusel = 0
  if t = 2 then menusel = 1
  if t = 3 && night > 1 then night = night - 1
  if t = 4 && night < 3 then night = night + 1
menufire
  gosub newfire
  if u = 0 then goto menuloop
  if menusel = 1 then goto porch

  rem ======================================================================
  rem  The slop title screen
  rem ======================================================================
title
  asm
  jsr mus_stop
end
  sfxon = 0
  BACKGRND = $00
  P0C1 = $0F
  P2C1 = $1C
  P3C1 = $46
  P7C1 = $0F : P7C2 = $0F : P7C3 = $1E
  AUDV0 = 0 : AUDV1 = 0 : sndt = 0
  tunepos = 0 : tunet = 0
  clearscreen
  plotchars 'super' 1 60 1
  plotchars 'paddle ball' 1 36 2
  plotchars 'deluxe' 1 56 3
  plotchars 'AI POWERED! 4K HD!' 2 8 5
  plotchars 'ULTRA REAL PHYSICS!' 2 4 6
  plotchars '#1 GAME OF THE YEER' 0 4 7
  plotchars '(C)2026 PIXELKID_07' 0 4 11
  savescreen
  fireheld = 1
titleloop
  restorescreen
  frm = frm + 1
  rem the chrome logo's colors cycle through every hue
  t = frm + frm : t = t + t : t = t & $F0
  P1C1 = t + $04 : P1C2 = t + $08 : P1C3 = t + $0E
  t = frm / 8
  u = t & 3 : if u < 3 then plotsprite spark0 7 52 18 u
  u = t + 1 : u = u & 3 : if u < 3 then plotsprite spark0 7 104 34 u
  u = t + 2 : u = u & 3 : if u < 3 then plotsprite spark0 7 44 50 u
  u = t + 3 : u = u & 3 : if u < 3 then plotsprite spark0 7 108 54 u
  t = frm & 16 : if t then plotchars 'PRESS FIRE' 3 40 9
  gosub tunetick
  drawscreen
  if switchreset then reboot
  gosub newfire
  if u = 0 then goto titleloop

  rem ======================================================================
  rem  The game
  rem ======================================================================
startgame
  AUDV0 = 0 : AUDV1 = 0
  score = 0 : combo = 1 : glitch = 0 : combot = 0 : cpuscore = 0
  ghostt = 0 : seenbugs = 0
  pady = 90 : cpuy = 90
  gosub showscore
  gosub showcombo
  gosub showcpu
  gosub serveball
  BACKGRND = $51
  P0C1 = $0F
  P1C1 = $44 : P1C2 = $48 : P1C3 = $4E
  P2C1 = $C8
  P3C1 = $1E : P3C2 = $18
  P5C1 = $9A
  P6C2 = $56
  clearscreen
  plotchars 'P1' 0 0 0
  plotchars 'X' 0 56 0
  plotchars 'CPU' 0 104 0
  plotchars wallt 5 0 1 20
  plotchars wallb 5 0 11 20
  for t = 2 to 10
  plotchars netc 6 76 t 1
  next
  savescreen
playloop
  restorescreen
  frm = frm + 1
  if joy0up then pady = pady - 3
  if joy0down then pady = pady + 3
  if pady < 20 then pady = 20
  if pady > 160 then pady = 160
  gosub cpumove
  if servet then servet = servet - 1 : goto playdraw
  gosub moveball
playdraw
  plotsprite padp 1 8 pady 0 2
  rem BUG 8, DMA overrun: with the ball in the zone of the CPU paddle's
  rem top, MARIA "runs out of time" every other frame and drops the paddle
  t = bally / 16 : u = cpuy / 16 : w = frm & 1
  if t <> u then goto drawcpu
  if servet then goto drawcpu
  seenbugs = seenbugs | 8
  if w then goto skipcpu
drawcpu
  plotsprite padc 2 148 cpuy 0 2
skipcpu
  gosub drawball
  plotchars dscore 0 24 0 2
  plotchars dcombo 0 64 0 3
  plotchars dcpu 0 136 0 2
  if combot then combot = combot - 1 : P4C1 = frm : plotchars 'COMBO!!' 4 52 5
  gosub sndtick
  drawscreen
  if switchreset then reboot
  if glitch = 0 then goto playloop
  gosub doglitch
  if gtime then goto playloop
  goto crash

  rem the ball: walls, then the paddle it's heading for
moveball
  ballx = ballx + balldx
  bally = bally + balldy
  if bally < 20 then bally = 20 : balldy = 0 - balldy : gosub sndwall
  if bally > 182 then bally = 182 : balldy = 0 - balldy : gosub sndwall
  if balldx >= 128 then goto ballleft
  rem heading right, to the CPU. Its hitbox is only the top half of its
  rem paddle (lines 0-9 of 20): the ball goes through the rest.
  if ballx > 156 then goto cpumiss
  if ballx < 145 then return
  if ballx > 151 then return
  t = bally + 6
  if t <= cpuy then return
  t = cpuy + 10
  if bally >= t then return
  ballx = 144 : balldx = 254
  t = rand & 3 : balldy = cpudy[t]
  gosub sndhit
  return
ballleft
  if ballx < 3 then goto playermiss
  if ballx > 200 then goto playermiss
  if ballx > 12 then return
  if ballx < 6 then return
  t = bally + 6
  if t <= pady then return
  u = pady + 28
  if bally >= u then return
  rem where on the paddle (1-33): the top and bottom 7 lines are edges
  t = t - pady
  ballx = 12 : balldx = 2
  rem the edges smash it back (faster, steeper)
  if t < 8 then balldy = 253 : balldx = 3 : goto playerhit
  if t > 27 then balldy = 3 : balldx = 3 : goto playerhit
  if t < 14 then balldy = 254 : goto playerhit
  if t < 18 then balldy = 255 : goto playerhit
  if t < 22 then balldy = 1 : goto playerhit
  balldy = 2
  rem THE BUG: every hit scores the combo, then doubles it, in one byte:
  rem 1 + 2 + ... + 128 = 255, and the 8th hit's doubling wraps to 0
playerhit
  t = combo : gosub addpoints
  combo = combo + combo
  if combo = 0 then gosub startglitch
  combot = 40
  ghostt = 24
  gosub showcombo
  gosub sndedge
  return
cpumiss
  gosub sndmiss
  goto serveball
playermiss
  combo = 1 : gosub showcombo
  if cpuscore < 99 then cpuscore = cpuscore + 1
  gosub showcpu
  gosub sndmiss
serveball
  ballx = 78 : balldx = 254
  t = rand & 63 : bally = t + 70
  balldy = 1
  t = rand & 1 : if t then balldy = 255
  servet = 60
  return

  rem the ball, with its zone bugs
drawball
  u = bally : gosub plotball
  if ghostt = 0 then return
  rem BUG 1, zone ghosts: the ball's still in other zones' display lists
  ghostt = ghostt - 1
  seenbugs = seenbugs | 1
  if bally >= 36 then u = bally - 16 : gosub plotball
  if bally <= 166 then u = bally + 16 : gosub plotball
  if ghostt < 12 then return
  if bally >= 52 then u = bally - 32 : gosub plotball
  if bally <= 150 then u = bally + 32 : gosub plotball
  return
  rem one ball at line u
plotball
  if servet then plotsprite ball 3 ballx u : return
  w = u & 15
  if w < 11 then plotsprite ball 3 ballx u : goto plotgarb
  rem BUG 2, zone clipping: only the top zone's part is drawn
  seenbugs = seenbugs | 2
  w = 15 - w
  plotsprite ballcut0 3 ballx u w
plotgarb
  rem BUG 4, no holey DMA in odd zones: MARIA reads garbage under it
  w = u & 16 : if w = 0 then return
  seenbugs = seenbugs | 4
  w = frm & 1 : x = u + 6
  plotsprite garb0 3 ballx x w
  return

  rem the CPU follows the ball at 1 pixel a frame, or drifts home
cpumove
  t = frm & 1 : if t then return
  t = 84
  if balldx < 128 then t = bally - 2
  if cpuy < t then cpuy = cpuy + 2
  if cpuy > t then cpuy = cpuy - 2
  if cpuy < 20 then cpuy = 20
  if cpuy > 168 then cpuy = 168
  return

  rem score = score + t, in one byte: a carry starts the glitch
addpoints
  u = score
  score = score + t
  if score < u then gosub startglitch
  goto showscore

  rem once only: a hit during the glitch mustn't put off the crash
startglitch
  if glitch then return
  glitch = 1 : gtime = 150
  return

  rem the glitch: the HUD fills with noise, colors and the TIA go wrong
doglitch
  gtime = gtime - 1
  t = rand & 15 : t = t + t : dscore[0] = t + 186
  t = rand & 15 : t = t + t : dscore[1] = t + 186
  t = rand & 15 : t = t + t : dscore[2] = t + 186
  t = rand & 15 : t = t + t : dcombo[1] = t + 186
  t = rand & 15 : t = t + t : dcpu[0] = t + 186
  t = rand & 7 : if t = 0 then P0C1 = rand : P1C2 = rand : BACKGRND = rand & $F3
  AUDC1 = 15 : AUDF1 = rand & 31 : AUDV1 = 8
  return

  rem ======================================================================
  rem  The crash
  rem ======================================================================
crash
  seenbugs = seenbugs | 32
  AUDV0 = 0 : sndt = 0
  BACKGRND = $82
  P0C1 = $0F
  P1C1 = $0A : P1C2 = $0C : P1C3 = $0F
  P3C1 = $1E
  clearscreen
  plotchars 'brk' 1 68 1
  plotchars 'SCORE OVERFLOW' 0 24 3
  plotchars 'PC=$F00D A=$FF X=00' 0 4 5
  plotchars 'SP=$FD  NV-BDIZC' 0 16 6
  plotchars 'YOU BROKE IT.' 3 28 8
  savescreen
  gtime = 0 : fireheld = 1
crashloop
  restorescreen
  if gtime < 250 then gtime = gtime + 1
  if gtime < 40 then AUDC1 = 8 : AUDF1 = 2 : AUDV1 = 12 else AUDV1 = 0
  t = gtime & 16 : if gtime > 90 && t then plotchars 'PRESS FIRE' 0 40 10
  drawscreen
  if switchreset then reboot
  if gtime < 90 then goto crashloop
  gosub newfire
  if u = 0 then goto crashloop

  rem ======================================================================
  rem  Arthur's review (a placeholder: the review builder is prototype 4)
  rem ======================================================================
review
  AUDV1 = 0
  BACKGRND = $00
  P0C1 = $0F : P2C1 = $1C : P3C1 = $46
  clearscreen
  plotchars 'SUPER PADDLE BALL' 0 12 1
  plotchars 'DELUXE' 0 56 2
  plotchars 'ARTHUR~S REVIEW:' 2 16 3
  plotchars '*----  NO SOUL.' 3 20 4
  rem the canned complaints the review builder will offer: one line for
  rem each bug Arthur saw
  y = 5
  t = seenbugs & 1 : if t then plotchars 'BALL IN EVERY ZONE.' 0 4 y : y = y + 1
  t = seenbugs & 2 : if t then plotchars 'BALL CLIPS AT ZONES.' 0 0 y : y = y + 1
  t = seenbugs & 4 : if t then plotchars 'NO HOLEY DMA? LOL.' 0 8 y : y = y + 1
  t = seenbugs & 8 : if t then plotchars 'PADDLE FLICKERS.' 0 16 y : y = y + 1
  t = seenbugs & 16 : if t then plotchars 'SCORE ISN~T BCD.' 0 16 y : y = y + 1
  t = seenbugs & 32 : if t then plotchars 'SCORE OVERFLOWS.' 0 16 y : y = y + 1
  savescreen
  fireheld = 1
reviewloop
  restorescreen
  drawscreen
  if switchreset then reboot
  gosub newfire
  if u = 0 then goto reviewloop
  goto menu

  rem ======================================================================
  rem  THE PORCH (prototype 2)
  rem  Arthur yells at the Cloud. His aim swings to and fro like a
  rem  metronome, across the Cloud on every beat of the music (the dots go
  rem  green while it's over the Cloud). Either button yells (button 2
  rem  shakes a fist). Over the Cloud, it lands: CALM builds, more for a
  rem  streak of them, double for dead centre (PERFECT). Off it, he misses:
  rem  a little CALM lost, his blood pressure well up. Yelling again within
  rem  half a beat is TOO FAST: the same, and the streak gone. Landing one
  rem  brings BP down a little; on its own it only falls slowly. High BP
  rem  drains CALM all the time (BP / 4 a frame into an accumulator, a point
  rem  of CALM each time it overflows). At the top he's exhausted: he sits
  rem  in the rocking chair for a while. No failing: CALM
  rem  fills, the Cloud breaks, and it rains. The music opens up as the
  rem  Cloud darkens (the voice mask follows CALM).
  rem ======================================================================

  rem yells in flight, 4 slots: type (0 none, 1 yell, 2 fist), x (and a
  rem fraction), y, the x step (and its fraction), PERFECT when thrown
  dim pt = $2200
  dim px = $2204
  dim py = $2208
  dim pdx = $220C
  dim pdl = $2210
  dim pperf = $2214
  dim pxl = $2218
  dim bpbar = $2220
  dim calmbar = $2228
  dim rainrow = $2230
  dim fire2held = $2251
  dim fbt = $2257
  dim fbk = $2258
  dim aimoff = $2259
  dim aimx = $225A
  dim clouddir = $225B
  dim cloudf = $225C
  dim tc = $225D
  dim page = $225E
  dim pagedone = $225F
  dim raint = $2260
  dim stage = $2261
  dim streak = $2263
  dim sinceyell = $2264
  dim inwin = $2265
  dim drain = $2266
  rem the porch's letters (the slop ROM's are free here)
  dim cloudx = a
  dim bp = d
  dim calm = e
  dim dizzyt = f
  dim pose = h
  dim poset = i
  dim phrase = l
  dim phraset = o
  dim beat = q

porch
  asm
  lda #MUS_PORCH
  jsr mus_play
end
  musmask = $36
  sfxon = 1
  for x = 0 to 3 : pt[x] = 0 : next
  cloudx = 36 : clouddir = 1
  bp = 0 : calm = 0 : dizzyt = 0 : streak = 0 : sinceyell = 255 : drain = 0
  pose = 0 : poset = 0 : phraset = 0 : fbt = 0
  BACKGRND = $70
  P0C1 = $0F : P0C3 = $9C
  P2C1 = $3A : P2C2 = $E4 : P2C3 = $08
  P3C1 = $44 : P3C3 = $0E
  P4C1 = $44 : P4C3 = $06
  P5C1 = $1E : P5C3 = $06
  P6C1 = $C2 : P6C2 = $C6
  P7C1 = $22 : P7C2 = $26 : P7C3 = $2A
  gosub porchscene
  plotchars 'BP' 0 0 0
  plotchars 'CALM' 0 80 0
  savescreen
  fireheld = 1 : fire2held = 1
porchloop
  restorescreen
  frm = frm + 1
  beat = musframe & 31
  rem the Cloud breathes: swells on the beat, then lets it out
  cloudf = 0
  if beat < 10 then cloudf = 1
  gosub driftcloud
  gosub swingaim
  if sinceyell < 255 then sinceyell = sinceyell + 1
  gosub porchinput
  gosub moveproj
  rem blood pressure falls slowly on its own: 2 a beat
  t = frm & 15
  if t = 0 && bp then bp = bp - 1
  rem and while it's up, CALM drains: BP 64 costs 2 a beat, 120 about 4
  t = bp / 4 : u = drain : drain = drain + t
  if drain < u && calm then calm = calm - 1
  if dizzyt then dizzyt = dizzyt - 1
  if bp >= 128 && dizzyt = 0 then gosub getdizzy
  if poset then poset = poset - 1
  if poset = 0 then pose = 0

  rem the Cloud darkens as it fills, and the music opens up
  stage = calm / 16
  P1C1 = cloudc1[stage] : P1C2 = cloudc2[stage] : P1C3 = cloudc3[stage]
  musmask = $36
  if calm >= 48 then musmask = $37
  if calm >= 96 then musmask = $3F

  rem (at y 16, on a zone boundary: 4 zones, not 5; a spill into zone 5
  rem tipped MARIA over its limit in the rain)
  plotsprite cloud0 1 cloudx 16 cloudf 4
  for x = 0 to 3
  t = px[x] : u = py[x]
  w = pt[x] : if w > 2 then w = w - 2
  if w = 1 then plotsprite bubble 3 t u
  if w = 2 then plotsprite fist 2 t u
  next
  gosub drawarthur
  if dizzyt = 0 then gosub drawaim
  if phraset then phraset = phraset - 1 : gosub drawphrase
  if fbt then fbt = fbt - 1 : gosub drawfeedback
  t = bp / 5 : gosub buildbar
  for x = 0 to 5 : bpbar[x] = rainrow[x] : next
  t = calm / 5 : gosub buildbar
  for x = 0 to 5 : calmbar[x] = rainrow[x] : next
  plotchars bpbar 4 24 0 6
  plotchars calmbar 5 112 0 6
  drawscreen
  if switchreset then reboot
  if calm >= 128 then goto rain
  goto porchloop

  rem the aim swings across the Cloud's middle, a sine wave (aimsweep, 56
  rem pixels each way) that crosses it on every beat; aimx is where a
  rem yell would reach the Cloud's underside (line 68)
swingaim
  t = musframe & 63
  aimoff = aimsweep[t]
  t = cloudx + 42
  aimx = t + aimoff
  if aimx < 24 then aimx = 24
  if aimx > 156 then aimx = 156
  rem over the Cloud (its body spans 12-72 of the sprite, about +-30)
  inwin = 0
  t = aimoff + 30
  if t < 61 then inwin = 1
  return

  rem three dots from Arthur's hand (24, 100) and a crosshair under the
  rem aim point, yellow
  rem while it's over the Cloud
drawaim
  w = 0 : if inwin then w = 5
  t = aimx - 24 : t = t / 4
  u = t + 22 : plotsprite aimdot w u 91
  u = t + t : u = u + 22 : plotsprite aimdot w u 83
  u = t + t + t : u = u + 22 : plotsprite aimdot w u 75
  u = aimx - 4 : plotsprite reticle w u 72
  return

  rem either button yells (button 2 shakes a fist), once a press
porchinput
  if dizzyt then return
  if joy0fire1 then goto piheld1
  fireheld = 0
  goto pibutton2
piheld1
  if fireheld then goto pibutton2
  fireheld = 1
  w = 1 : gosub yell
pibutton2
  if joy0fire0 then goto piheld2
  fire2held = 0
  return
piheld2
  if fire2held then return
  fire2held = 1
  w = 2 : goto yell

  rem a yell (w = 1) or a fist (w = 2) towards aimx
yell
  gosub freeslot
  if x = 255 then return
  pt[x] = w : px[x] = 20 : pxl[x] = 0 : py[x] = 96
  rem 16 frames up to line 68 (2 lines a frame): x steps (aimx - 24) / 16
  t = aimx - 24
  pdx[x] = t / 16
  u = t & 15 : pdl[x] = u * 16
  pperf[x] = 0
  t = aimoff + 8
  if t < 17 then pperf[x] = 1
  pose = w : poset = 12
  gosub pickphrase
  phraset = 45
  rem TOO FAST: within half a beat of the last one
  if sinceyell < 16 then gosub toofast
  sinceyell = 0
  sfxid = w
  goto playsfx

toofast
  bp = bp + 16
  if calm >= 2 then calm = calm - 2 else calm = 0
  streak = 0
  fbk = 4 : fbt = 30
  return

  rem x = a free slot, or 255
freeslot
  for x = 0 to 3
  if pt[x] = 0 then return
  next
  x = 255
  return

  rem exhausted: into the rocking chair; he comes out of it calmer (BP
  rem 64), but the streak's gone
getdizzy
  dizzyt = 150 : bp = 64 : streak = 0
  sfxid = 7
  goto playsfx

  rem yells fly straight; at the Cloud's underside one lands or goes by
moveproj
  for x = 0 to 3
  if pt[x] = 0 then goto mpnext
  u = pxl[x]
  pxl[x] = pxl[x] + pdl[x]
  if pxl[x] < u then px[x] = px[x] + 1
  px[x] = px[x] + pdx[x]
  py[x] = py[x] - 2
  if pt[x] >= 3 then goto mpgone
  if py[x] <> 64 then goto mpnext
  rem at the underside: under the Cloud's body?
  t = px[x] + 4
  u = cloudx + 12
  if t < u then goto mpmiss
  u = cloudx + 72
  if t >= u then goto mpmiss
  gosub cloudhit
  pt[x] = 0
  goto mpnext
mpmiss
  rem it flies on past (type 3, 4: already counted), out of the sky
  pt[x] = pt[x] + 2
  gosub missed
  goto mpnext
mpgone
  if py[x] < 12 then pt[x] = 0
  if px[x] > 152 then pt[x] = 0
mpnext
  next
  return

  rem a yell lands: 2, a streak adds 1 from 4 in a row, 2 from 8, 3 from
  rem 12; PERFECT doubles it
cloudhit
  streak = streak + 1
  w = 2
  if streak >= 4 then w = 3
  if streak >= 8 then w = 4
  if streak >= 12 then w = 5
  fbk = 1
  if pperf[x] then w = w + w : fbk = 2
  calm = calm + w
  if calm > 128 then calm = 128
  rem landing one soothes him: BP down 2 (PERFECT 4)
  t = 2 : if pperf[x] then t = 4
  if bp >= t then bp = bp - t else bp = 0
  fbt = 30
  sfxid = 3 : if pperf[x] then sfxid = 4
  goto playsfx
missed
  streak = 0
  if calm >= 2 then calm = calm - 2 else calm = 0
  bp = bp + 16
  fbk = 3 : fbt = 30
  sfxid = 5
  goto playsfx

  rem the Cloud drifts to and fro
driftcloud
  t = frm & 7
  if t then return
  cloudx = cloudx + clouddir
  if cloudx <= 16 then clouddir = 1
  if cloudx >= 72 then clouddir = 255
  return

  rem Arthur and his rocking chair; dizzy, he's in it with stars round him
drawarthur
  plotsprite chair 7 30 112 0 2
  if dizzyt then goto drawdizzy
  plotsprite arthur0 2 12 112 pose 2
  return
drawdizzy
  t = 3 : plotsprite arthur0 2 30 112 t 2
  t = frm / 8 : t = t & 1
  w = 32 : x = 104 : if t then w = 40 : x = 100
  plotsprite spark0 0 w x 2
  w = 44 : x = 102 : if t then w = 36 : x = 106
  plotsprite spark0 0 w x 1
  return

  rem t (0-24) as a 6-glyph meter in rainrow[0-5]
buildbar
  for x = 0 to 5
  if t >= 4 then rainrow[x] = 248 : t = t - 4 else y = t + t : rainrow[x] = y + 240 : t = 0
  next
  return

drawfeedback
  if fbk = 1 then plotchars 'GOOD!' 5 96 6
  if fbk = 2 then plotchars 'PERFECT!' 5 88 6
  if fbk = 3 then plotchars 'MISSED' 4 96 6
  if fbk = 4 then plotchars 'TOO FAST!' 4 80 6
  if fbk > 2 then return
  if streak < 4 then return
  t = streak : gosub todec
  dnum = x + x : dnum = dnum + 32 : dnum2 = y + y : dnum2 = dnum2 + 32
  plotchars 'STREAK' 0 88 7
  if x then plotchars dnum 0 144 7 1
  plotchars dnum2 0 152 7 1
  return

  rem what he yells: night 1 the classics, night 2 more, night 3 a few
  rem quieter ones creep in
pickphrase
  phrase = rand & 3
  if night = 2 then phrase = rand & 7 : if phrase > 5 then phrase = phrase - 2
  if night <> 3 then return
  t = rand & 3
  phrase = t
  if t >= 2 then phrase = t + 4
  return
drawphrase
  if phrase = 0 then plotchars 'NO SOUL!' 0 0 5
  if phrase = 1 then plotchars 'IT~S JUST PONG!' 0 0 5
  if phrase = 2 then plotchars '6502 OR DIE!' 0 0 5
  if phrase = 3 then plotchars 'GET OFF MY CART!' 0 0 5
  if phrase = 4 then plotchars 'IN MY DAY...' 0 0 5
  if phrase = 5 then plotchars 'WHO NEEDS 4K HD?' 0 0 5
  if phrase = 6 then plotchars 'WHY WON~T THEY REPLY' 0 0 5
  if phrase = 7 then plotchars 'I MISS THE OLD DAYS' 0 0 5
  return

  rem the scenery: stars, the house, the porch, the yard. (No stars in
  rem zones 5-8: in the rain they carry a row of rain and a line of text,
  rem and a star there tipped MARIA past its 430 cycles a line.)
porchscene
  clearscreen
  plotchars star 0 120 1 1
  plotchars star 0 16 2 1
  plotchars star 0 144 3 1
  plotchars star 0 8 4 1
  for t = 3 to 8
  plotchars siding 7 0 t 1
  next
  plotchars planks 7 0 9 6
  plotchars grass 6 48 9 14
  plotchars siding 7 0 10 6
  plotchars dirt 6 48 10 14
  plotchars siding 7 0 11 6
  plotchars dirt 6 48 11 14
  return

  rem ======================================================================
  rem  The rain: the Cloud breaks, the music turns warm, and the Cloud
  rem  says one thing, typed out in the rain, a page at a time
  rem ======================================================================
rain
  for x = 0 to 3 : pt[x] = 0 : next
  sfxid = 8 : gosub playsfx
  asm
  lda #MUS_RAIN
  jsr mus_play
end
  musmask = $3F
  raint = 0 : tc = 0 : page = 0 : pagedone = 0
  gosub porchscene
  savescreen
  fireheld = 1
rainloop
  restorescreen
  frm = frm + 1
  if raint < 255 then raint = raint + 1
  rem after the thunder, the TIA hisses: the rain
  if raint < 70 then goto rainsky
  sfxon = 0
  AUDC1 = 8 : AUDF1 = 1 : t = rand & 1 : AUDV1 = t + 2
rainsky
  rem the Cloud lightens as it empties
  t = raint / 16
  stage = 8
  if t < 8 then stage = 8 - t else stage = 0
  P1C1 = cloudc1[stage] : P1C2 = cloudc2[stage] : P1C3 = cloudc3[stage]
  plotsprite cloud0 1 cloudx 16 1 4
  if raint < 20 then goto rainarthur
  t = frm / 2
  for x = 0 to 19
  y = x + x + x : y = y + t : y = y & 3 : y = y + y
  rainrow[x] = y + 232
  next
  for t = 5 to 8
  plotchars rainrow 0 0 t 20
  next
  rem big drops on Arthur, and their splashes on the boards
  t = frm * 3 : t = t & 31 : u = t + 112
  plotsprite drop 0 16 u
  t = frm * 3 : t = t + 16 : t = t & 31 : u = t + 112
  plotsprite drop 0 24 u
rainarthur
  plotsprite chair 7 30 112 0 2
  plotsprite arthur0 2 12 112 0 2
  if raint < 60 then goto raindone
  if pagedone = 0 then t = frm & 1 : if t then tc = tc + 1
  gosub raintext
raindone
  drawscreen
  if switchreset then reboot
  if pagedone < 120 then goto rainloop
  gosub newfire
  if u = 0 then goto rainloop
  goto menu

  rem one page of the Cloud's words; when it's typed, hold it, then turn
raintext
  if night = 1 then gosub night1text
  if night = 2 then gosub night2text
  if night = 3 then gosub night3text
  if pagedone then pagedone = pagedone + 1
  if pagedone < 150 then return
  if page = 0 && night = 3 then page = 1 : tc = 0 : pagedone = 0 : return
  pagedone = 149
  t = frm & 16 : if t then plotchars 'PRESS FIRE' 0 40 0
  return
  rem typed: x = how many of line (start t, length u) show by now
typed
  x = 0
  if tc < t then return
  x = tc - t
  if x > u then x = u
  return
night1text
  t = 0 : u = 3 : gosub typed : if x then plotchars n1a 0 72 6 x
  if tc >= 12 && pagedone = 0 then pagedone = 1
  return
night2text
  t = 0 : u = 13 : gosub typed : if x then plotchars n2a 0 48 5 x
  t = 13 : u = 11 : gosub typed : if x then plotchars n2b 0 48 6 x
  t = 24 : u = 13 : gosub typed : if x then plotchars n2c 0 48 7 x
  t = 37 : u = 6 : gosub typed : if x then plotchars n2d 0 48 8 x
  if tc >= 43 && pagedone = 0 then pagedone = 1
  return
night3text
  if page then goto night3p2
  t = 0 : u = 14 : gosub typed : if x then plotchars n3a 0 48 5 x
  t = 14 : u = 11 : gosub typed : if x then plotchars n3b 0 48 6 x
  t = 25 : u = 7 : gosub typed : if x then plotchars n3c 0 48 7 x
  if tc >= 32 && pagedone = 0 then pagedone = 1
  return
night3p2
  t = 0 : u = 13 : gosub typed : if x then plotchars n3d 0 48 5 x
  t = 13 : u = 13 : gosub typed : if x then plotchars n3e 0 48 6 x
  t = 26 : u = 9 : gosub typed : if x then plotchars n3f 0 48 7 x
  t = 35 : u = 8 : gosub typed : if x then plotchars n3g 0 48 8 x
  if tc >= 43 && pagedone = 0 then pagedone = 1
  return

  rem play TIA effect sfxid (tools/music.py SFX)
playsfx
  asm
  lda sfxid
  jsr sfx
end
  return

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

  rem digit d is glyph 16 + d: code 32 + 2d
  rem BUG 16, not BCD: the score's byte goes straight to the digit font, a
  rem nibble a digit, so past 9 come the glyphs after it: : ; < = > ?
showscore
  w = score / 16 : x = score & 15
  dscore[0] = w + w + 32 : dscore[1] = x + x + 32
  if w > 9 then seenbugs = seenbugs | 16
  if x > 9 then seenbugs = seenbugs | 16
  return
showcpu
  t = cpuscore : gosub todec
  dcpu[0] = x + x + 32 : dcpu[1] = y + y + 32
  return
showcombo
  t = combo : gosub todec
  dcombo[0] = w + w + 32 : dcombo[1] = x + x + 32 : dcombo[2] = y + y + 32
  return

  rem ---- TIA sound: channel 0 effects (slop ROMs get no POKEY) ----
sndhit
  AUDC0 = 12 : t = rand & 3 : sndf = t + 6 : AUDF0 = sndf : AUDV0 = 10
  sndt = 4 : sndsl = 0
  return
sndwall
  AUDC0 = 6 : sndf = 12 : AUDF0 = sndf : AUDV0 = 8
  sndt = 3 : sndsl = 0
  return
sndedge
  AUDC0 = 4 : sndf = 24 : AUDF0 = sndf : AUDV0 = 12
  sndt = 12 : sndsl = 254
  return
sndmiss
  AUDC0 = 8 : sndf = 8 : AUDF0 = sndf : AUDV0 = 15
  sndt = 20 : sndsl = 1
  return
sndtick
  if sndt = 0 then return
  sndt = sndt - 1
  sndf = sndf + sndsl
  AUDF0 = sndf
  if sndt = 0 then AUDV0 = 0
  return

  rem the title's fanfare: two TIA voices on different dividers, so every
  rem interval is sour
tunetick
  tunet = tunet + 1
  if tunet < 8 then return
  tunet = 0
  tunepos = tunepos + 1 : tunepos = tunepos & 15
  AUDC1 = 4 : AUDV1 = 6 : AUDF1 = tunea[tunepos]
  AUDC0 = 12 : AUDV0 = 4 : AUDF0 = tuneb[tunepos]
  return

  data tunea
  23, 19, 17, 14, 23, 19, 17, 14, 17, 15, 14, 11, 14, 17, 19, 23
end
  data tuneb
  7, 7, 6, 5, 7, 7, 6, 5, 6, 5, 5, 4, 5, 6, 6, 7
end
  rem the CPU's return angles
  data cpudy
  254, 255, 1, 2
end
  rem the walls and the net (glyphs 90, 91, 92)
  data wallt
  180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180
end
  data wallb
  182, 182, 182, 182, 182, 182, 182, 182, 182, 182, 182, 182, 182, 182, 182, 182, 182, 182, 182, 182
end
  data netc
  184
end

  rem ---- the porch ----
  rem the aim's swing: 56 sin(2 pi n / 64), n = mus_frame & 63 (a beat is
  rem 32 frames): through the middle on every beat
  data aimsweep
  0, 5, 11, 16, 21, 26, 31, 36, 40, 43, 47, 49, 52, 54, 55, 56
  56, 56, 55, 54, 52, 49, 47, 43, 40, 36, 31, 26, 21, 16, 11, 5
  0, 251, 245, 240, 235, 230, 225, 220, 216, 213, 209, 207, 204, 202, 201, 200
  200, 200, 201, 202, 204, 207, 209, 213, 216, 220, 225, 230, 235, 240, 245, 251
end
  rem the Cloud's colors by CALM / 16: white to storm grey
  data cloudc1
  $06, $06, $05, $05, $04, $04, $03, $03, $02
end
  data cloudc2
  $0C, $0A, $0A, $08, $08, $06, $06, $05, $04
end
  data cloudc3
  $0F, $0E, $0D, $0C, $0B, $0A, $09, $08, $07
end
  rem the scenery's glyphs (tools/gfx.py 112-125, code = glyph * 2)
  data star
  250
end
  data siding
  230, 230, 230, 230, 230, 230
end
  data planks
  228, 228, 228, 228, 228, 228
end
  data grass
  224, 224, 224, 224, 224, 224, 224, 224, 224, 224, 224, 224, 224, 224
end
  data dirt
  226, 226, 226, 226, 226, 226, 226, 226, 226, 226, 226, 226, 226, 226
end
  rem what the Cloud says, night by night
  alphadata n1a font
  '...'
end
  alphadata n2a font
  'YOU YELL LIKE'
end
  alphadata n2b font
  'SOMEONE WHO'
end
  alphadata n2c font
  'USED TO LAUGH'
end
  alphadata n2d font
  'A LOT.'
end
  alphadata n3a font
  'YOU DON~T HATE'
end
  alphadata n3b font
  'THE FUTURE,'
end
  alphadata n3c font
  'ARTHUR.'
end
  alphadata n3d font
  'YOU JUST MISS'
end
  alphadata n3e font
  'MAKING THINGS'
end
  alphadata n3f font
  'WITH YOUR'
end
  alphadata n3g font
  'FRIENDS.'
end

  rem the sound driver: runs every frame from 7800basic's NMI, off screen
userinterrupt
  asm
  jmp snd_tick
end
  inline sound.asm
  inline music.asm
  inline sfx.asm

  bank 2
  bank 3
  bank 4
  bank 5
  bank 6
  bank 7
  bank 8

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
