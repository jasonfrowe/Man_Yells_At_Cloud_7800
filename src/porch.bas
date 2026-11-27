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
  dim reply = $2267
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
  rem what he yelled stays up until he yells the next (phraset: its age,
  rem 1-255; 0 none yet)
  if phraset then gosub drawphrase : if phraset < 255 then phraset = phraset + 1
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
  rem every yell is a new phrase (it stays up until the next)
  gosub pickphrase : phraset = 1
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
  rem (rows 7 and 8, right of Arthur: rows 5 and 6 are what he yells)
  if fbk = 1 then plotchars 'GOOD!' 5 96 7
  if fbk = 2 then plotchars 'PERFECT!' 5 88 7
  if fbk = 3 then plotchars 'MISSED' 4 96 7
  if fbk = 4 then plotchars 'TOO FAST!' 4 80 7
  if fbk > 2 then return
  if streak < 4 then return
  t = streak : gosub todec
  dnum = x + x : dnum = dnum + 32 : dnum2 = y + y : dnum2 = dnum2 + 32
  plotchars 'STREAK' 0 88 8
  if x then plotchars dnum 0 144 8 1
  plotchars dnum2 0 152 8 1
  return

  rem what he yells (one or two lines of 20, rows 5 and 6):
  rem   0-7    night 1: the classic grumbles
  rem   8-15   night 2 adds the hardware rants
  rem   16-19  night 3: the quieter ones, a quarter of the time
  rem never the same one twice running
pickphrase
  t = phrase
pickagain
  phrase = rand & 7
  if night = 2 then phrase = rand & 15
  if night < 3 then goto pickcheck
  phrase = rand & 15
  u = rand & 3
  if u = 0 then phrase = rand & 3 : phrase = phrase + 16
pickcheck
  if phrase = t then goto pickagain
  return
drawphrase
  if phrase = 0 then plotchars 'NO SOUL!' 0 0 5
  if phrase = 1 then plotchars 'IT~S JUST PONG!' 0 0 5
  if phrase = 2 then plotchars '6502 OR DIE!' 0 0 5
  if phrase = 3 then plotchars 'GET OFF MY CART!' 0 0 5
  if phrase = 4 then plotchars 'WHERE~S THE MANUAL?' 0 0 5
  if phrase = 5 then plotchars 'WHO NEEDS 4K HD?' 0 0 5
  if phrase = 6 then plotchars 'BLOW ON THE CART!' 0 0 5
  if phrase = 7 then plotchars 'PROSYSTEM FOREVER!' 0 0 5
  if phrase = 8 then plotchars 'TRAMIEL SHOULD HAVE' 0 0 5 : plotchars 'RELEASED THE 7800!' 0 0 6
  if phrase = 9 then plotchars 'THE 7800 WOULD HAVE' 0 0 5 : plotchars 'BEAT THE NES!' 0 0 6
  if phrase = 10 then plotchars 'MARIA DMA IS SPECIAL' 0 0 5
  if phrase = 11 then plotchars 'POKEY HAD SOUL!' 0 0 5
  if phrase = 12 then plotchars 'HOLEY DMA ISN~T A' 0 0 5 : plotchars 'BUG, IT~S A FEATURE!' 0 0 6
  if phrase = 13 then plotchars 'IN MY DAY WE COUNTED' 0 0 5 : plotchars 'EVERY CYCLE!' 0 0 6
  if phrase = 14 then plotchars 'YOUR ZONES ARE' 0 0 5 : plotchars 'A MESS!' 0 0 6
  if phrase = 15 then plotchars '128 BYTES OF RAM' 0 0 5 : plotchars 'WAS ENOUGH FOR US!' 0 0 6
  if phrase = 16 then plotchars 'WHY WON~T THEY REPLY' 0 0 5
  if phrase = 17 then plotchars 'I MISS THE OLD DAYS' 0 0 5
  if phrase = 18 then plotchars 'WE USED TO MAKE' 0 0 5 : plotchars 'THINGS TOGETHER...' 0 0 6
  if phrase = 19 then plotchars 'IS ANYONE OUT THERE?' 0 0 5
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
  raint = 0 : tc = 0 : page = 0 : pagedone = 0 : reply = 0
  rem Arthur's words, in his own colour
  P3C1 = $1C
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
  rem when Arthur answers, the rain has stopped
  if reply then AUDV1 = 0
rainsky
  rem the Cloud lightens as it empties
  t = raint / 16
  stage = 8
  if t < 8 then stage = 8 - t else stage = 0
  P1C1 = cloudc1[stage] : P1C2 = cloudc2[stage] : P1C3 = cloudc3[stage]
  plotsprite cloud0 1 cloudx 16 1 4
  if raint < 20 then goto rainarthur
  if reply then goto rainarthur
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
  if reply = 0 then goto rainloop
  if pagedone < 90 then goto rainloop
  gosub newfire
  if u = 0 then goto rainloop
  goto scenedone

  rem one page of the Cloud's words; when it's typed, hold it, then turn
raintext
  if reply then goto arthurtext
  if night = 1 then gosub night1text
  if night = 2 then gosub night2text
  if night = 3 then gosub night3text
  if pagedone then pagedone = pagedone + 1
  if pagedone < 150 then return
  if page = 0 && night = 3 then page = 1 : tc = 0 : pagedone = 0 : return
  rem the Cloud has said its piece: the rain stops, and Arthur answers
  reply = 1 : tc = 0 : pagedone = 0
  return
arthurtext
  if night = 2 then goto arthur2
  if night = 3 then goto arthur3
  t = 0 : u = 7 : gosub typed : if x then plotchars arhuh 3 0 5 x
  t = 7 : u = 18 : gosub typed : if x then plotchars arfeel 3 0 6 x
  v = 25 : goto arthurdone
arthur2
  t = 0 : u = 18 : gosub typed : if x then plotchars arfeel 3 0 5 x
  t = 18 : u = 10 : gosub typed : if x then plotchars arthanks 3 0 6 x
  v = 28 : goto arthurdone
arthur3
  t = 0 : u = 18 : gosub typed : if x then plotchars arfeel 3 0 5 x
  t = 18 : u = 17 : gosub typed : if x then plotchars arcloud 3 0 6 x
  v = 35
arthurdone
  if tc >= v && pagedone = 0 then pagedone = 1
  if pagedone && pagedone < 200 then pagedone = pagedone + 1
  if pagedone < 90 then return
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
  rem and what Arthur says back
  alphadata arhuh font
  '...HUH.'
end
  alphadata arfeel font
  'I FEEL BETTER NOW.'
end
  alphadata arthanks font
  '...THANKS.'
end
  alphadata arcloud font
  'THANK YOU, CLOUD.'
end

