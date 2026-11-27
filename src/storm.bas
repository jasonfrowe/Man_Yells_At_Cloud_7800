  rem ======================================================================
  rem  THE STORM (prototype 6, bank 8): Friday night, after the porch. The
  rem  Cloud, heavy with everything Arthur yelled, drifts over the
  rem  NimbusWorks data centre, darkens, and lets go. Each strike writes a
  rem  row of hex into the machines (typed along the bottom): real 7800
  rem  boot code, then words for anyone who reads hex. The racks light one
  rem  by one; then 0X7800_MIRROR.BIN, WRITTEN, FOR: ARTHUR. Button 1 at
  rem  the end goes on (scenedone). Its graphics: gen/stormgfx.asm
  rem  (tools/gfx.py S_TILES), its own block at $A000. The potluck (below)
  rem  lives here too, its people in the same block.
  rem ======================================================================

  dim stt = $2200
  dim stimer = $2201
  dim strikes = $2202
  dim scx = $2203
  dim sbolt = $2204
  dim sbx = $2205
  dim sflash = $2206
  dim tpos = $2207
  dim slit = $2208
  dim sdark = $2209
  dim shue = $220A
  dim sbg = $220B
  rem RAM rows MARIA reads live: the racks (rows 7, 8), the hex (10, 11)
  dim srow7 = $2300
  dim srow8 = $2314
  dim hex10 = $2328
  dim hex11 = $233C
  dim hstage = $2350

storm
  asm
  jsr mus_stop
end
  characterset sfont
  sfxon = 1 : AUDV0 = 0 : AUDV1 = 0
  BACKGRND = $80
  P0C1 = $C8
  P1C1 = $04 : P1C2 = $08 : P1C3 = $0C
  P2C1 = $44
  P5C1 = $00 : P5C2 = $04 : P5C3 = $CC
  P6C1 = $9C : P6C2 = $1C : P6C3 = $1E
  P7C1 = $00
  for x = 0 to 19
  srow7[x] = rackrow[x] : srow8[x] = rackrow[x]
  hex10[x] = 0 : hex11[x] = 0
  next
  clearscreen
  plotchars 'NIMBUSWORKS' 2 36 4
  plotchars mastc 5 112 5 1
  plotchars roofrow 5 0 6 20
  plotchars srow7 5 0 7 20
  plotchars srow8 5 0 8 20
  plotchars doorrow 5 0 9 20
  plotchars groundrow 7 0 10 20
  plotchars groundrow 7 0 11 20
  plotchars hex10 0 0 10 20
  plotchars hex11 0 0 11 20
  savescreen
  stt = 0 : stimer = 0 : strikes = 0 : scx = 150 : sbolt = 0 : sflash = 0
  tpos = 18 : slit = 0 : sdark = 0 : fireheld = 1

stormloop
  restorescreen
  frm = frm + 1
  stimer = stimer + 1
  if stt = 0 then gosub senter
  if stt = 1 then gosub sdarken
  if stt = 2 then gosub sstrikes
  if stt = 3 then gosub swritten
  if stt = 4 then gosub sleave
  rem the Cloud (two puffs of breath), the bolt, the flash
  t = frm / 32 : t = t & 1
  plotsprite cloud0 1 scx 0 t 4
  if sbolt then sbolt = sbolt - 1 : gosub drawbolt
  sbg = $80
  if sflash then sflash = sflash - 1 : sbg = $0E
  gosub stype
  drawscreen
  rem (colours change in the vertical blank, before the next frame's drawn)
  BACKGRND = sbg
  rem the sign hums
  t = frm & 3 : if t = 0 then shue = rand & 3 : P2C1 = shue + $44
  if switchreset then reboot
  if stt < 5 then goto stormloop
  gosub newfire
  if u = 0 then goto stormloop
  characterset font
  goto scenedone

  rem 0: the Cloud drifts in from the right, over the building
senter
  t = frm & 1 : if t then scx = scx - 1
  if scx > 40 then return
  stt = 1 : stimer = 0
  return
  rem 1: it darkens
sdarken
  t = stimer & 15 : if t then return
  sdark = sdark + 1
  if sdark = 1 then P1C1 = $02 : P1C2 = $04 : P1C3 = $08
  if sdark = 2 then P1C1 = $00 : P1C2 = $02 : P1C3 = $06
  if sdark >= 3 then stt = 2 : stimer = 30
  return
  rem 2: the strikes, one every 45 frames: a bolt, a flash, thunder, a
  rem row of hex, two more racks lit
sstrikes
  if stimer < 45 then return
  stimer = 0
  if strikes >= 13 then stt = 3 : return
  sbolt = 10 : sflash = 3
  t = rand & 31 : sbx = scx + 16 : sbx = sbx + t
  sfxid = 8 : gosub playsfx
  rem the racks: the next two in rack order
  for x = 0 to 1
  if slit < 20 then t = rackorder[slit] : gosub light : slit = slit + 1
  next
  rem the hex: row 11 moves up, the new row is typed into 11
  for x = 0 to 19 : hex10[x] = hex11[x] : hex11[x] = 0 : next
  u = strikes * 6
  for x = 0 to 5
  v = hexbytes[u] : u = u + 1
  t = x + x : t = t + x
  w = v / 16 : gosub hexdigit : hstage[t] = w : t = t + 1
  w = v & 15 : gosub hexdigit : hstage[t] = w : t = t + 1
  hstage[t] = 0
  next
  tpos = 0
  strikes = strikes + 1
  return
  rem a nibble w as its font code (0-9: 32 + 2n, A-F: 46 + 2n)
hexdigit
  if w < 10 then w = w + w : w = w + 32 : return
  w = w + w : w = w + 46
  return
  rem rack t (0-9 row 7, 10-19 row 8: rackcol's columns) lit
light
  if t < 10 then u = rackcol[t] : srow7[u] = 134 : return
  t = t - 10 : u = rackcol[t] : srow8[u] = 134
  return
  rem the hex row types itself, a letter a frame, clicking
stype
  if tpos >= 18 then return
  hex11[tpos] = hstage[tpos]
  t = tpos & 3 : if t = 0 then sfxid = 10 : gosub playsfx
  tpos = tpos + 1
  return
  rem the bolt: from the Cloud's underside (56) to the roof (96)
drawbolt
  t = frm & 2 : t = t / 2
  plotsprite bolt0 6 sbx 56 t
  plotsprite bolt0 6 sbx 72 t
  t = t ^ 1
  plotsprite bolt0 6 sbx 80 t
  return
  rem 3: the last strike's done: everything lights, and the words
swritten
  if stimer < 40 then return
  for v = 0 to 19 : t = v : gosub light : next
  for x = 0 to 19 : hex10[x] = written1[x] : hex11[x] = written2[x] : next
  sbolt = 20 : sflash = 6
  sfxid = 8 : gosub playsfx
  P0C1 = $0E
  stt = 4 : stimer = 0
  return
  rem 4: the Cloud pales and drifts away
sleave
  if stimer = 60 then P1C1 = $06 : P1C2 = $0A : P1C3 = $0E
  if stimer < 90 then return
  t = frm & 1 : if t then scx = scx + 1
  if scx < 170 then return
  stt = 5
  return

  rem the building: rows 6 (roof), 7-8 (wall and racks), 9 (the door)
  data roofrow
  0, 0, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 0, 0
end
  data rackrow
  0, 0, 130, 132, 132, 130, 132, 132, 130, 132, 132, 130, 132, 132, 130, 132, 132, 130, 0, 0
end
  data doorrow
  0, 0, 130, 130, 130, 130, 130, 130, 130, 136, 130, 130, 130, 130, 130, 130, 130, 130, 0, 0
end
  data groundrow
  138, 138, 138, 138, 138, 138, 138, 138, 138, 138, 138, 138, 138, 138, 138, 138, 138, 138, 138, 138
end
  data mastc
  140
end
  rem a row's racks' columns, and the order they light in
  data rackcol
  3, 4, 6, 7, 9, 10, 12, 13, 15, 16
end
  data rackorder
  4, 15, 2, 11, 7, 18, 0, 13, 9, 5, 16, 1, 12, 8, 19, 3, 14, 6, 17, 10
end
  rem what the Cloud writes, six bytes a strike: a 7800's boot (SEI, CLD,
  rem LDA #7, STA INPTCTRL, the CTRL, the stack...), then ASCII
  data hexbytes
  $78, $D8, $A9, $07, $85, $01
  $A9, $7F, $85, $3C, $A9, $00
  $85, $38, $A2, $FF, $9A, $E8
  $95, $00, $E8, $D0, $FB, $A9
  $37, $38, $30, $30, $20, $4D
  $49, $52, $52, $4F, $52, $20
  $A9, $4C, $85, $23, $20, $00
  $F0, $4C, $00, $F0, $EA, $EA
  $53, $54, $41, $59, $20, $46
  $4F, $52, $20, $54, $48, $45
  $20, $4D, $45, $41, $4C, $2E
  $46, $4F, $52, $3A, $20, $41
  $52, $54, $48, $55, $52, $00
end
  rem "0X7800_MIRROR.BIN" and "WRITTEN. FOR: ARTHUR"
  data written1
  0, 32, 112, 46, 48, 32, 32, 126, 90, 82, 100, 100, 94, 100, 28, 68, 82, 92, 0, 0
end
  data written2
  110, 100, 82, 104, 104, 74, 92, 28, 0, 76, 94, 100, 52, 0, 66, 100, 104, 80, 106, 100
end

  rem ======================================================================
  rem  THE POTLUCK (prototype 6, bank 8, with the storm): Saturday, 6 PM, the porch at dusk. The
  rem  regulars and pixelkid on the grass, a card table with a CRT, the
  rem  7800 and the dishes. The Cloud comes; Arthur waves instead of
  rem  yelling; a last light shower; the Cloud parts for the stars and
  rem  says its last line. (Its people share the storm's graphics block: gen/stormgfx.asm.)
  rem ======================================================================

  dim pkt = $2200
  dim pkcx = $2201
  dim pkn = $2202
  dim pkbg = $2203
  dim pkline = $2300

potluck
  asm
  lda #MUS_POTLUCK
  jsr mus_play
end
  musmask = $3F
  sfxon = 1 : AUDV0 = 0 : AUDV1 = 0
  pkbg = $46 : BACKGRND = pkbg
  P0C1 = $0F
  P1C1 = $06 : P1C2 = $0A : P1C3 = $0E
  P2C1 = $3A : P2C2 = $E4 : P2C3 = $08
  P3C1 = $3A : P3C2 = $26 : P3C3 = $F4
  P4C1 = $3A : P4C2 = $46 : P4C3 = $02
  P5C1 = $3A : P5C2 = $0C : P5C3 = $74
  P0C1 = $3A : P0C2 = $56 : P0C3 = $84
  P6C1 = $C2 : P6C2 = $C6
  P7C1 = $22 : P7C2 = $26 : P7C3 = $2A
  for x = 0 to 19 : pkline[x] = 0 : next
  gosub pkscene
  plotsprite chair 7 30 112 0 2
  plotsprite ptablet 7 76 112
  plotsprite ptableb 7 76 128
  plotchars pkline 1 8 2 20
  savescreen
  pkt = 0 : pkcx = 160 : pkn = 0 : fireheld = 1

potloop
  restorescreen
  frm = frm + 1
  if pkt < 255 then pkt = pkt + 1
  rem the friends, breathing (a line's bob, out of step)
  t = frm / 32 : t = t & 1 : u = 112 + t : v = 113 - t
  plotsprite psuet 3 56 u
  w = u + 16 : plotsprite psueb 3 56 w
  plotsprite phalt 4 110 v
  w = v + 16 : plotsprite phalb 4 110 w
  plotsprite pmariat 5 126 u
  w = u + 16 : plotsprite pmariab 5 126 w
  plotsprite pkidt 0 142 v
  w = v + 16 : plotsprite pkidb 0 142 w
  gosub pkstage
  drawscreen
  BACKGRND = pkbg
  if switchreset then reboot
  if pkn < 99 then goto potloop
  gosub newfire
  if u = 0 then goto potloop
  goto scenedone

  rem the stages, by pkn: 0 the Cloud comes, 1 Arthur waves, 2 the shower,
  rem 3 the Cloud parts, 4 the stars and the line, 99 done
pkstage
  if pkn = 0 then goto pkcome
  if pkn = 1 then goto pkwave
  if pkn = 2 then goto pkshower
  if pkn = 3 then goto pkpart
  goto pkstars
pkcome
  gosub pkarthur
  t = frm & 1 : if t then pkcx = pkcx - 1
  t = frm / 32 : t = t & 1
  plotsprite cloud0 1 pkcx 8 t 4
  if pkcx > 40 then return
  pkn = 1 : pkt = 0
  return
pkwave
  rem he doesn't yell: he waves
  t = frm & 16
  if t = 0 then gosub pkarthur : goto pkwave2
  plotsprite pwavet 2 12 112
  plotsprite pwaveb 2 12 128
pkwave2
  gosub pkcloud
  if pkt < 150 then return
  pkn = 2 : pkt = 0
  return
pkshower
  gosub pkarthur
  gosub pkcloud
  rem a few drops, falling from under the Cloud
  for x = 0 to 5
  t = frm + dropoff[x] : t = t & 63 : t = t + t : t = t + 64
  u = dropx[x]
  if t < 176 then plotsprite drop 1 u t
  next
  if pkt < 200 then return
  pkn = 3 : pkt = 0
  return
pkpart
  rem the Cloud thins, and goes up and away: dusk becomes night
  gosub pkarthur
  t = frm & 1 : if t then pkcx = pkcx + 1
  if pkt = 40 then P1C1 = $04 : P1C2 = $06 : P1C3 = $08 : pkbg = $54
  if pkt = 80 then P1C1 = $02 : P1C2 = $04 : P1C3 = $06 : pkbg = $62
  if pkt = 120 then pkbg = $80
  t = frm / 32 : t = t & 1
  if pkt < 140 then plotsprite cloud0 1 pkcx 8 t 4
  if pkt < 150 then return
  rem (palette 1 is the sky's now: white text, white stars)
  P1C1 = $0E : P1C2 = $0E : P1C3 = $0E
  pkn = 4 : pkt = 0
  return
pkstars
  gosub pkarthur
  plotchars pkstar 1 120 0 1
  plotchars pkstar 1 16 1 1
  plotchars pkstar 1 144 3 1
  plotchars pkstar 1 72 4 1
  plotchars pkstar 1 40 5 1
  rem the line, a letter every 6 frames
  if pkt < 30 then return
  t = pkt - 30 : t = t / 6
  if t < 20 then pkline[t] = stayline[t]
  if pkt > 230 then pkn = 99
  return
pkcloud
  t = frm / 32 : t = t & 1
  plotsprite cloud0 1 pkcx 8 t 4
  return
pkarthur
  plotsprite arthur0 2 12 112 0 2
  return

  rem the shower's drops: their places, and how far each is behind
  data dropx
  52, 64, 76, 88, 100, 112
end
  data dropoff
  0, 11, 22, 33, 44, 55
end
  rem "STAY FOR THE MEAL." (centred in 18 of the 20)
  data stayline
  0, 102, 104, 66, 114, 0, 76, 94, 100, 0, 104, 80, 74, 0, 90, 74, 66, 88, 28, 0
end

  rem the porch's scenery (as porch.bas's porchscene: its rows must be in
  rem this bank, where MARIA reads them)
pkscene
  clearscreen
  for t = 3 to 8
  plotchars pksiding 7 0 t 1
  next
  plotchars pkplanks 7 0 9 6
  plotchars pkgrass 6 48 9 14
  plotchars pksiding 7 0 10 6
  plotchars pkdirt 6 48 10 14
  plotchars pksiding 7 0 11 6
  plotchars pkdirt 6 48 11 14
  return
  data pkstar
  250
end
  data pksiding
  230, 230, 230, 230, 230, 230
end
  data pkplanks
  228, 228, 228, 228, 228, 228
end
  data pkgrass
  224, 224, 224, 224, 224, 224, 224, 224, 224, 224, 224, 224, 224, 224
end
  data pkdirt
  226, 226, 226, 226, 226, 226, 226, 226, 226, 226, 226, 226, 226, 226
end

  asm
  if . > $A000
  echo "bank 8: the code reaches the graphics' place ($A000)"
  err
  endif
  ds $A000 - ., 0
end
  inline stormgfx.asm
