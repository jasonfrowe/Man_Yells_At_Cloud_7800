  rem ======================================================================
  rem  THE STORM (prototype 6, bank 8): Friday night, after the porch. The
  rem  Cloud, heavy with everything Arthur yelled, drifts over the
  rem  NimbusWorks data centre, darkens, and lets go. Each strike writes a
  rem  row of hex into the machines (typed along the bottom): real 7800
  rem  boot code, then words for anyone who reads hex. The racks light one
  rem  by one; then 0X7800_MIRROR.BIN, WRITTEN, FOR: ARTHUR. Button 1 at
  rem  the end goes on (scenedone). Its graphics: gen/stormgfx.asm
  rem  (tools/gfx.py S_TILES), its own block at $A000.
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

  asm
  if . > $A000
  echo "bank 8: the code reaches the graphics' place ($A000)"
  err
  endif
  ds $A000 - ., 0
end
  inline stormgfx.asm
