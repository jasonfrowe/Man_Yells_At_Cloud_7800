  rem ======================================================================
  rem  MAN YELLS AT CLOUD
  rem  A story game for the Atari 7800. See Concept.md.
  rem
  rem  Prototype 1: SUPER PADDLE BALL DELUXE, the first slop ROM.
  rem  An overblown title, then a broken Pong. Edge hits double the COMBO
  rem  and add it to the score; the score is one byte, so past 255 it
  rem  overflows, the HUD turns to garbage, and the game crashes (BRK).
  rem  Slop ROMs use TIA sound only (the POKEYs stay quiet).
  rem ======================================================================

  rem 128K SuperGame: the code in bank 1 (switched in at $8000), the
  rem graphics in bank 8 (fixed at $C000). tools/a78header.py adds the
  rem second POKEY ($0440) to the header.
  set romsize 128k
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
  rem t, u, w, x, y: scratch (todec writes w x y)
  rem the HUD's digits, character codes (glyph * 2)
  dim dscore = var40
  dim dcombo = var43

  rem Buttons: either fire button starts and continues (joy0fire1 is
  rem button 1 and a one-button stick's, joy0fire0 button 2).

  characterset font
  rem The font's glyphs 0-89 (tools/gfx.py): ASCII 32-95, then tall chrome
  rem A-Z typed as a-z. ^ is a double quote and ~ an apostrophe.
  alphachars ' !^#$%&~()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[~]^_abcdefghijklmnopqrstuvwxyz'

  rem ======================================================================
  rem  The slop title screen
  rem ======================================================================
title
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
  score = 0 : combo = 1 : glitch = 0 : combot = 0
  pady = 90 : cpuy = 90
  gosub showscore
  gosub showcombo
  gosub serveball
  BACKGRND = $51
  P0C1 = $0F
  P1C1 = $44 : P1C2 = $48 : P1C3 = $4E
  P2C1 = $C8
  P3C1 = $1E : P3C2 = $18
  P5C1 = $9A
  P6C2 = $56
  clearscreen
  plotchars 'SCORE' 0 0 0
  plotchars 'COMBO X' 0 80 0
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
  plotsprite padc 2 148 cpuy 0 2
  plotsprite ball 3 ballx bally
  plotchars dscore 0 48 0 3
  plotchars dcombo 0 136 0 3
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
  if t < 8 then balldy = 253 : goto edgehit
  if t > 27 then balldy = 3 : goto edgehit
  if t < 14 then balldy = 254 : goto centrehit
  if t < 18 then balldy = 255 : goto centrehit
  if t < 22 then balldy = 1 : goto centrehit
  balldy = 2
centrehit
  t = 1 : gosub addpoints
  gosub sndhit
  return
  rem THE BUG: an edge hit scores the combo, then doubles it
edgehit
  balldx = 3
  t = combo : gosub addpoints
  combo = combo + combo
  combot = 40
  gosub showcombo
  gosub sndedge
  return
cpumiss
  t = 1 : gosub addpoints
  gosub sndmiss
  goto serveball
playermiss
  combo = 1 : gosub showcombo
  gosub sndmiss
serveball
  ballx = 78 : balldx = 254
  t = rand & 63 : bally = t + 70
  balldy = 1
  t = rand & 1 : if t then balldy = 255
  servet = 60
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
  if score < u then glitch = 1 : gtime = 150
  goto showscore

  rem the glitch: the HUD fills with noise, colors and the TIA go wrong
doglitch
  gtime = gtime - 1
  t = rand & 15 : t = t + t : dscore[0] = t + 186
  t = rand & 15 : t = t + t : dscore[1] = t + 186
  t = rand & 15 : t = t + t : dscore[2] = t + 186
  t = rand & 15 : t = t + t : dcombo[1] = t + 186
  t = rand & 7 : if t = 0 then P0C1 = rand : P1C2 = rand : BACKGRND = rand & $F3
  AUDC1 = 15 : AUDF1 = rand & 31 : AUDV1 = 8
  return

  rem ======================================================================
  rem  The crash
  rem ======================================================================
crash
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
  plotchars 'ARTHUR~S REVIEW:' 2 16 4
  plotchars '*----' 3 60 5
  plotchars '^NO SOUL.^' 0 40 6
  plotchars '(REVIEW BUILDER' 0 20 8
  plotchars 'COMING SOON)' 0 32 9
  savescreen
  fireheld = 1
reviewloop
  restorescreen
  drawscreen
  if switchreset then reboot
  gosub newfire
  if u = 0 then goto reviewloop
  goto title

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
showscore
  t = score : gosub todec
  dscore[0] = w + w + 32 : dscore[1] = x + x + 32 : dscore[2] = y + y + 32
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

  bank 2
  bank 3
  bank 4
  bank 5
  bank 6
  bank 7

  bank 8
  incgraphic gfx/font.png 160A 0 1 2 3
  incgraphic gfx/padp.png 160A 0 1 2 3
  incgraphic gfx/padc.png 160A 0 1 2 3
  incgraphic gfx/ball.png 160A 0 1 2 3
  incgraphic gfx/spark0.png 160A 0 1 2 3
  incgraphic gfx/spark1.png 160A 0 1 2 3
  incgraphic gfx/spark2.png 160A 0 1 2 3
