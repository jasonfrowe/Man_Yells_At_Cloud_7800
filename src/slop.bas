  rem ======================================================================
  rem  The slop ROMs (bank 2): the day's title (night: 1 SUPER PADDLE BALL
  rem  DELUXE, 2 CYBER NEON BLASTER, 3 7800 SKYWOLFENDOOMRIM), then the
  rem  same broken Pong, with the day's "content" crashing through it. See
  rem  the notes at the top of myac.bas.
  rem ======================================================================

  rem the day's extras (scene RAM)
  dim exp = $2200
  dim exy = $2201
  dim shx = $2202
  dim astx = $2203
  dim asty = $2204
  dim nhue = $2205
  rem day 2's crash: the ball speeds up (spd 0-6), then tunnels (tunnel),
  rem then it's gone (lostt counts the empty court)
  dim spd = $2206
  dim tunnel = $2207
  dim lostt = $2208
  rem day 3's: each flip of the left difficulty switch grows the paddle
  rem (padg flips, padlen lines; swlast the switch)
  dim padg = $2209
  dim padlen = $220A
  dim swlast = $220B
  dim wraps = $220C
  rem day 3, the court full of paddle: two volleys, then the ball sticks
  dim padfull = $220D
  dim fullhits = $220E
  dim stuckf = $220F

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
  if night = 2 then goto title2
  if night = 3 then goto title3
  plotchars 'super' 1 60 1
  plotchars 'paddle ball' 1 36 2
  plotchars 'deluxe' 1 56 3
  plotchars 'AI POWERED! 4K HD!' 2 8 5
  plotchars 'ULTRA REAL PHYSICS!' 2 4 6
  plotchars '#1 GAME OF THE YEER' 0 4 7
  plotchars '120 FPS!!!' 2 40 8
  goto title9
title2
  plotchars 'cyber' 1 60 1
  plotchars 'neon' 1 64 2
  plotchars 'blaster' 1 52 3
  plotchars 'NEON RAY TRACING!' 2 12 5
  plotchars 'ROBOTS! LAZERS! WOW!' 2 0 6
  plotchars '#1 GAME OF THE YEER' 0 4 7
  plotchars 'NOW 240 FPS!!!' 2 24 8
  goto title9
title3
  plotchars '7800' 3 64 1
  plotchars 'skywolfendoomrim' 1 16 2
  plotchars 'goty' 1 64 3
  plotchars 'OPEN WORLD! 900 HRS!' 2 0 5
  plotchars 'DRAGONS! DEMONS!' 2 16 6
  plotchars 'TANKS! SPACE ROCKS!' 0 4 7
  plotchars '8K RTX AT 480 FPS!' 2 8 8
title9
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
  exp = 0 : shx = 0 : astx = 0
  spd = 0 : tunnel = 0 : lostt = 0 : wraps = 0
  padfull = 0 : fullhits = 0 : stuckf = 0 : padg = 0 : padlen = 28
  gosub readsw : swlast = t
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
  if night = 2 then P6C1 = $46 : P6C3 = $CC : nhue = $50
  if night = 3 then gosub arena
  rem (day 3's crash is the switch: the game says so, in the bottom wall)
  savescreen
playloop
  restorescreen
  frm = frm + 1
  if joy0up then pady = pady - 3
  if joy0down then pady = pady + 3
  if pady < 20 then pady = 20
  t = 188 - padlen : if pady > t then pady = t
  if night = 3 then gosub swcheck
  if padfull then pady = 30
  if stuckf then goto hang
  gosub cpumove
  if servet then servet = servet - 1 : goto playdraw
  gosub moveball
playdraw
  gosub drawpad
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
  if night = 2 then gosub parade
  if night = 3 then gosub flyby
  plotchars dscore 0 24 0 2
  plotchars dcombo 0 64 0 3
  plotchars dcpu 0 136 0 2
  if combot then combot = combot - 1 : P4C1 = frm : plotchars 'COMBO!!' 4 52 5
  rem day 3's crash is the switch: the game says so, in the bottom wall,
  rem and once it's flipped, to keep going
  if night <> 3 then goto nohint
  if padg = 0 then plotchars 'FLIP LEFT DIFFICULTY' 0 0 11 : goto nohint
  if padfull then goto nohint
  t = frm & 16
  if t then plotchars 'KEEP FLIPPING IT!' 0 12 11
nohint
  gosub sndtick
  drawscreen
  if switchreset then reboot
  if lostt then lostt = lostt + 1 : if lostt > 90 then goto crash
  if glitch = 0 then goto playloop
  gosub doglitch
  if gtime then goto playloop
  goto crash

  rem the ball: walls, then the paddle it's heading for
moveball
  if lostt then return
  ballx = ballx + balldx
  bally = bally + balldy
  rem day 2, at top speed: the wall checks miss it. It flies through the
  rem walls and wraps round the screen, top to bottom and side to side,
  rem a few times; then it's gone
  if tunnel = 0 then goto walls
  if ballx > 200 then ballx = 152
  if ballx > 156 then ballx = 4
  if bally > 4 then return
  wraps = wraps + 1
  if wraps >= 8 then lostt = 1 : return
  bally = 186
  return
walls
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
  ballx = 144 : t = spd / 2 : balldx = 254 - t
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
  u = pady + padlen
  if bally >= u then return
  rem where on the paddle (1-33): the top and bottom 7 lines are edges
  t = t - pady
  ballx = 12 : balldx = 2
  rem the edges smash it back (faster, steeper)
  if t < 8 then balldy = 253 : balldx = 3 : goto playerhit
  u = padlen - 1
  if t > u then balldy = 3 : balldx = 3 : goto playerhit
  if padg = 0 then goto padmid
  rem (a grown paddle: just its halves)
  u = padlen / 2
  if t < u then balldy = 255 : goto playerhit
  balldy = 1 : goto playerhit
padmid
  if t < 14 then balldy = 254 : goto playerhit
  if t < 18 then balldy = 255 : goto playerhit
  if t < 22 then balldy = 1 : goto playerhit
  balldy = 2
  rem THE BUG: every hit scores the combo, then doubles it, in one byte:
  rem 1 + 2 + ... + 128 = 255, and the 8th hit's doubling wraps to 0
playerhit
  if night = 2 then gosub speedup
  rem (the full court: the third hit's the one that sticks)
  if padfull then fullhits = fullhits + 1 : if fullhits >= 3 then stuckf = 1
  t = combo : gosub addpoints
  combo = combo + combo
  rem (days 2 and 3 crash their own way: the combo just sticks)
  if combo = 0 && night > 1 then combo = 128
  if combo = 0 then gosub startglitch
  combot = 40
  ghostt = 24
  gosub showcombo
  gosub sndedge
  return
cpumiss
  gosub sndmiss
  goto serveball
  rem a miss halves the combo (it used to start again at 1x: a long game)
playermiss
  if tunnel then return
  combo = combo / 2 : if combo = 0 then combo = 1
  spd = spd / 2
  gosub showcombo
  if cpuscore < 99 then cpuscore = cpuscore + 1
  gosub showcpu
  gosub sndmiss
  rem the serve comes straight at the player's paddle, wherever it is,
  rem so it's always in reach
serveball
  ballx = 78 : balldx = 254
  u = padlen / 2 : bally = pady + u : bally = bally - 6
  t = rand & 7 : bally = bally + t
  if bally > 182 then bally = 182
  balldy = 0
  servet = 60
  return

  rem day 2: every hit's faster; the 6th (top speed) sends it up so fast
  rem the top wall's check never sees it
speedup
  if spd < 6 then spd = spd + 1
  t = spd / 2 : balldx = balldx + t
  if spd < 6 then return
  tunnel = 1 : balldy = 251
  return

  rem day 3: the left difficulty switch (t = 1 on B)
readsw
  t = 0 : if switchleftb then t = 1
  return
swcheck
  gosub readsw
  if t = swlast then return
  swlast = t
  if padfull then return
  rem (the sixth flip: six paddles, the court full, top to bottom)
  if padg = 5 then padfull = 1 : pady = 30 : gosub sndedge : return
  padg = padg + 1 : padlen = padlen + 24
  gosub sndedge
  return

  rem the player's paddle: a grown one is more paddles, end to end
drawpad
  plotsprite padp 1 8 pady 0 2
  if padg = 0 then return
  u = pady
  for x = 1 to padg
  u = u + 24 : plotsprite padp 1 8 u 0 2
  next
  return

  rem day 3: the paddle fills the court, the ball's stuck inside it, and
  rem the game hangs
hang
  rem (drawn as 6 paddles from line 30: the 7th would run off the screen)
  ballx = 9 : pady = 30 : padg = 5 : gtime = 0
  AUDV0 = 0
hangloop
  restorescreen
  frm = frm + 1
  gosub drawpad
  t = frm & 2 : t = t / 2 : ballx = 9 + t
  plotsprite ball 3 ballx bally
  plotchars dscore 0 24 0 2
  plotchars dcombo 0 64 0 3
  plotchars dcpu 0 136 0 2
  AUDC1 = 7 : AUDF1 = 28 : AUDV1 = 6
  drawscreen
  if switchreset then reboot
  rem (300 frames: gtime counts every other one)
  t = frm & 1 : if t then gtime = gtime + 1
  if gtime < 150 then goto hangloop
  goto crash

  rem the ball, with its zone bugs
drawball
  if lostt then return
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

  rem ---- the day's extras ----
  rem day 2: neon, and every 256 frames a robot marches through with a
  rem smiley bouncing after it (exp: the march, 1-200; exy its line)
parade
  t = frm & 31
  if t = 0 then nhue = nhue + $10 : BACKGRND = nhue + $02 : P5C1 = nhue + $0A : P6C2 = nhue + $0C
  if exp = 0 && frm = 0 then exp = 1 : t = rand & 63 : exy = t + 60
  if exp = 0 then return
  t = frm & 1 : if t then exp = exp + 1
  if exp > 200 then exp = 0 : return
  t = frm / 8 : t = t & 1
  u = exp - 8
  if t then plotsprite robot1 6 u exy else plotsprite robot0 6 u exy
  u = exp - 40
  t = frm & 15 : w = bounce[t] : w = exy + w
  plotsprite smiley 3 u w
  return

  rem day 3: a tank arena (plotted once, under savescreen)
arena
  BACKGRND = $C2
  P7C1 = $28 : P6C2 = $26
  P4C2 = $06 : P4C3 = $0A
  plotchars blockh 7 32 3 3
  plotchars blockh 7 104 3 3
  plotchars blockh 7 32 9 3
  plotchars blockh 7 104 9 3
  for t = 4 to 8
  plotchars blockh 7 48 t 1
  plotchars blockh 7 104 t 1
  next
  plotsprite tankr 1 28 98
  plotsprite tankl 2 124 98
  return

  rem the tanks trade a shell now and then, and an asteroid drifts by
flyby
  if shx = 0 && frm = 128 then shx = 36
  if shx then shx = shx + 2 : plotsprite shell 0 shx 101
  if shx > 118 then shx = 0
  if astx = 0 && frm = 0 then astx = 1 : t = rand & 31 : asty = t + 24
  if astx = 0 then return
  astx = astx + 1
  t = frm & 1 : if t then asty = asty + 1
  if astx > 172 then astx = 0 : return
  u = astx - 12
  t = frm & 16
  if t then plotsprite rock1 4 u asty else plotsprite rock0 4 u asty
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
  if night > 1 then return
  glitch = 1 : gtime = 150
  return

  rem the glitch: the HUD fills with noise, colors and the TIA go wrong
doglitch
  rem (300 frames: gtime counts every other one)
  t = frm & 1 : if t then gtime = gtime - 1
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
  rem (each ROM its own: 1 the overflow, 2 the lost ball, 3 the hang)
crash
  AUDV0 = 0 : sndt = 0
  BACKGRND = $82
  P0C1 = $0F
  P1C1 = $0A : P1C2 = $0C : P1C3 = $0F
  P3C1 = $1E
  clearscreen
  if night = 2 then goto crash2
  if night = 3 then goto crash3
  seenbugs = seenbugs | 32
  plotchars 'brk' 1 68 1
  plotchars 'SCORE OVERFLOW' 0 24 3
  plotchars 'PC=$F00D A=$FF X=00' 0 4 5
  plotchars 'SP=$FD  NV-BDIZC' 0 16 6
  plotchars 'YOU BROKE IT.' 3 28 8
  goto crash9
crash2
  seenbugs = seenbugs | 64
  plotchars 'err' 1 68 1
  plotchars 'BALL NOT FOUND' 0 24 3
  plotchars 'PC=$BA11 Y=$FF' 0 24 5
  plotchars 'BALLY=255?' 0 40 6
  plotchars 'WHERE DID IT GO?' 3 16 8
  goto crash9
crash3
  seenbugs = seenbugs | 128
  BACKGRND = $02
  plotchars 'hang' 1 64 1
  plotchars 'PADDLE OVERFLOW' 0 20 3
  plotchars 'PC=$CAFE A=$FF' 0 24 5
  plotchars 'THE BALL IS INSIDE.' 0 4 6
  plotchars 'YOU BROKE IT.' 3 28 8
crash9
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
  rem  Arthur's review: the forum's review builder (forum.bas, bank 5),
  rem  which offers a complaint for each bug he saw (seenbugs)
  rem ======================================================================
review
  AUDV0 = 0 : AUDV1 = 0
  goto forumrev bank5

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
  rem the arena's blocks (glyph 113, solid colour 1)
  data blockh
  226, 226, 226
end
  rem the smiley's bounce
  data bounce
  0, 2, 6, 10, 14, 16, 18, 18, 18, 16, 14, 10, 6, 2, 0, 0
end

