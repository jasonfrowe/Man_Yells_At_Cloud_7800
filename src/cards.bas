  rem ======================================================================
  rem  THE DAY JOB (prototype 3, bank 4): punch cards at NimbusWorks.
  rem  320A, 40 columns (cards.asm). A card is 20 columns of 12 rows: rows
  rem  0-4 the opcode (one hole: LOAD, ADD, CNT, LOOP, OUT), rows 5-11 the
  rem  operand (7 bits, 64 down to 1: ASCII). Registers A (7 bits) and the
  rem  counter C.
  rem    LOAD n   A = n            ADD n   A = A + n (mod 128; 127 is -1)
  rem    CNT n    C = n            LOOP n  C = C - 1, to column n if C > 0
  rem    OUT      print A          (no hole: the column's skipped)
  rem  A job a day (the menu's day): 1 HELLO (HE comes punched), 2 text and
  rem  a count (a loop), 3 the whole card: two loops and a countdown.
  rem  The stick moves the cursor, button 1 punches (or un-punches) a hole,
  rem  button 2 runs the card: the reader steps through it, printing; the
  rem  output must match the target. Two holes in a column's opcode rows,
  rem  a loop to nowhere, or 200 steps jam the reader. Below the card's
  rem  last row is GO HOME (back to the menu: the porch is there).
  rem  The Konami code (up up down down left right left right, button 2,
  rem  button 1) is Cloud Assist: the card punches itself (the forum's
  rem  rumor; Concept.md 4.1).
  rem ======================================================================

  rem cards.asm's
  dim cop = $2200
  dim cval = $2214
  dim ccol = $2269
  dim crow = $226A
  dim ccuron = $2274
  dim cprow = $2277
  dim cpcol = $2278
  rem the target (row 1) and the output (row 2) from column 8
  dim ctarget = $2330
  dim coutrow = $2358
  dim cpanel = $2300
  rem (row 6 and row 8 from column 35, and row 11: past an array's 255)
  dim cq6 = $2413
  dim cq8 = $2463
  dim cmsgrow = $24B8
  rem the day job's
  dim coutn = $2268
  dim cpc = $226B
  dim cacc = $226C
  dim csteps = $226D
  dim cstate = $226E
  dim cjob = $226F
  dim ctimer = $2270
  dim ckon = $2271
  dim crep = $2272
  dim cdir = $2273
  dim cassist = $2275
  dim cstr = $2276
  dim cfire2 = $227B
  dim cbase = $227C
  dim ccnt = $227D
  rem row 10 from column 32 (GO HOME), row 7 from column 31 (C)
  dim chome = $24A0

cards
  asm
  lda #MUS_OFFICE
  jsr mus_play
  jsr c_enter
end
  musmask = $37
  sfxon = 1 : AUDV0 = 0 : AUDV1 = 0
  BACKGRND = $00
  P0C1 = $0F : P0C2 = $0F : P0C3 = $0F
  P1C1 = $2D : P1C2 = $2D : P1C3 = $2D
  P2C1 = $CA : P2C2 = $CA : P2C3 = $CA
  P3C1 = $1C : P3C2 = $1C : P3C3 = $1C
  cjob = night - 1

  rem ---- a job: the card, the target, the screen ----
cjobstart
  for x = 0 to 19 : cop[x] = 0 : cval[x] = 0 : next
  rem the first job's first columns come punched (the tutorial)
  cbase = cjobfirst[cjob]
  t = cjobpre[cjob]
  if t = 0 then goto cjobpre0
  t = t - 1
  for x = 0 to t
  u = cbase + x
  cop[x] = csolop[u] : cval[x] = csolval[u]
  next
cjobpre0
  ccol = 0 : crow = 0 : coutn = 0 : cstate = 0 : ckon = 0 : cassist = 0
  cacc = 0 : ccnt = 0 : csteps = 0
  cdir = 0 : crep = 0 : fireheld = 1 : cfire2 = 1
  asm
  jsr c_cls
  jsr c_frame
end
  cprow = 0 : cpcol = 0 : cstr = 0 : gosub say
  cprow = 0 : cpcol = 32 : cstr = 1 : gosub say
  t = cjob + 17 : cpanel[36] = t + t
  cprow = 1 : cpcol = 0 : cstr = 2 : gosub say
  cprow = 1 : cpcol = 8 : cstr = cjobtarget[cjob] : gosub say
  cprow = 2 : cpcol = 0 : cstr = 3 : gosub say
  cprow = 10 : cpcol = 0 : cstr = 4 : gosub say
  gosub clearmsg
  cprow = 11 : cpcol = 0 : cstr = cjobhint[cjob] : gosub say
  cprow = 4 : cpcol = 27 : cstr = 5 : gosub say
  cprow = 5 : cpcol = 27 : cstr = 6 : gosub say
  cprow = 6 : cpcol = 27 : cstr = 7 : gosub say
  cprow = 7 : cpcol = 27 : cstr = 33 : gosub say
  cprow = 8 : cpcol = 27 : cstr = 8 : gosub say
  cprow = 9 : cpcol = 27 : cstr = 9 : gosub say
  gosub homeupd
  clearscreen
  asm
  lda #<c_segs
  sta c_ptr
  lda #>c_segs
  sta c_ptr+1
  jsr c_draw
end
  savescreen

cloop
  frm = frm + 1
  if cstate = 1 then gosub crun : goto cshow
  if cstate = 2 then goto cwait
  gosub cstick
  gosub cbuttons
cshow
  rem the cursor blinks while editing, and stays on while the card runs
  ccuron = 1
  t = frm & 16 : if cstate = 0 && t then ccuron = 0
  asm
  jsr c_card
end
  gosub cpanelupd
  drawscreen
  if switchreset then reboot
  goto cloop

  rem a result's on the screen: button 1 goes on
cwait
  gosub newfire1
  if u = 0 then goto cshow
  if ctimer = 1 then goto cdone
  rem not a match, or a jam: back to the card
  cstate = 0 : gosub clearmsg
  goto cshow
cdone
  asm
  jsr c_leave
end
  goto menu

  rem ---- editing ----
  rem the stick: a press moves the cursor at once, then repeats
cstick
  w = 0
  if joy0up then w = 1
  if joy0down then w = 2
  if joy0left then w = 3
  if joy0right then w = 4
  if w = 0 then cdir = 0 : return
  if w = cdir then goto cstickrep
  cdir = w : crep = 14
  gosub konami
  goto cmove
cstickrep
  crep = crep - 1
  if crep then return
  crep = 4
cmove
  t = crow
  if cdir = 1 && crow > 0 then crow = crow - 1
  if cdir = 2 && crow < 12 then crow = crow + 1
  if cdir = 3 && ccol > 0 then ccol = ccol - 1
  if cdir = 4 && ccol < 19 then ccol = ccol + 1
  if t = crow then return
  if t < 12 && crow < 12 then return
  rem onto GO HOME, or back off it
  gosub homeupd
  gosub clearmsg
  cprow = 11 : cpcol = 0
  cstr = cjobhint[cjob] : if crow = 12 then cstr = 34
  goto say
  rem GO HOME, marked while the cursor's on it (row 12)
homeupd
  cprow = 10 : cpcol = 32 : cstr = 32
  if crow = 12 then cstr = 31
  goto say

  rem button 1 punches, button 2 runs the card; both feed the Konami code
cbuttons
  if joy0fire0 then goto cb2held
  cfire2 = 0
  goto cb1
cb2held
  if cfire2 then goto cb1
  cfire2 = 1
  w = 5 : gosub konami
  rem (B in the code: hold off running, wait for A)
  if ckon = 9 then goto cb1
  goto crunstart
cb1
  gosub newfire1
  if u = 0 then return
  w = 6 : gosub konami
  if ckon = 10 then goto cassistgo
  if crow = 12 then pop : goto cdone
  rem punch, or un-punch, the hole under the cursor
  if crow < 5 then cop[ccol] = cop[ccol] ^ cmop[crow] else cval[ccol] = cval[ccol] ^ cmval[crow]
  sfxid = 9 : goto playsfx

  rem the Konami code, one input (w) at a time: 1 up, 2 down, 3 left,
  rem 4 right, 5 button 2, 6 button 1
konami
  t = ckonseq[ckon]
  if w = t then ckon = ckon + 1 : return
  ckon = 0
  if w = 1 then ckon = 1
  return

  rem Cloud Assist: the card punches itself, and runs
cassistgo
  ckon = 0 : cassist = 1
  for x = 0 to 19 : cop[x] = 0 : cval[x] = 0 : next
  cbase = cjobfirst[cjob]
  t = cjobn[cjob] - 1
  for x = 0 to t
  u = cbase + x
  cop[x] = csolop[u] : cval[x] = csolval[u]
  next
  gosub clearmsg
  cprow = 11 : cpcol = 0 : cstr = 23 : gosub say
  sfxid = 12 : gosub playsfx

  rem ---- running the card ----
crunstart
  cpc = 0 : cacc = 0 : ccnt = 0 : csteps = 0 : coutn = 0 : ctimer = 0
  for x = 0 to 31 : coutrow[x] = 0 : next
  cstate = 1
  crow = 0 : gosub homeupd
  if cassist then return
  gosub clearmsg
  cprow = 11 : cpcol = 0 : cstr = 17 : gosub say
  return

  rem a step every 6 frames; the cursor shows the column being read
crun
  ctimer = ctimer + 1
  if ctimer < 6 then return
  ctimer = 0
  if cpc >= 20 then goto chalt
  ccol = cpc : crow = 0
  csteps = csteps + 1
  if csteps > 200 then cstr = 21 : goto cjam
  t = cop[cpc] : u = cval[cpc]
  sfxid = 10 : gosub playsfx
  if t = 0 then cpc = cpc + 1 : return
  rem two holes in the opcode rows jam it
  w = t - 1 : w = w & t
  if w then cstr = 20 : goto cjam
  if t = 1 then cacc = u
  if t = 2 then cacc = cacc + u : cacc = cacc & 127
  if t = 4 then ccnt = u
  if t = 16 then gosub cprint
  if t <> 8 then cpc = cpc + 1 : return
  rem LOOP n: C = C - 1, and to column n if C isn't 0 yet
  ccnt = ccnt - 1
  if ccnt = 0 then cpc = cpc + 1 : return
  if u = 0 || u > 20 then cstr = 22 : goto cjam
  cpc = u - 1
  return
cprint
  if coutn >= 32 then return
  w = 62
  if cacc >= 32 && cacc < 96 then w = cacc - 32 : w = w + w
  coutrow[coutn] = w
  coutn = coutn + 1
  return
  rem the end of the card: does the output match the target?
chalt
  cstate = 2 : ctimer = 2
  for x = 0 to 31
  if coutrow[x] <> ctarget[x] then goto cnomatch
  next
  ctimer = 1
  gosub clearmsg
  cprow = 11 : cpcol = 0 : cstr = 18 : gosub say
  sfxid = 11 : goto playsfx
cnomatch
  gosub clearmsg
  cprow = 11 : cpcol = 0 : cstr = 19 : gosub say
  return
cjam
  cstate = 2 : ctimer = 2
  gosub clearmsg
  cprow = 11 : cpcol = 0 : gosub say
  sfxid = 12 : goto playsfx

  rem ---- the column's decode, and the machine ----
cpanelupd
  cprow = 4 : cpcol = 35 : t = ccol + 1 : gosub num
  t = cop[ccol]
  cstr = 15
  if t = 1 then cstr = 10
  if t = 2 then cstr = 11
  if t = 4 then cstr = 12
  if t = 8 then cstr = 13
  if t = 16 then cstr = 14
  w = t - 1 : w = w & t
  if w then cstr = 16
  cprow = 5 : cpcol = 31 : gosub say
  t = cval[ccol]
  cprow = 6 : cpcol = 31 : gosub num
  gosub showchar
  t = ccnt
  cprow = 7 : cpcol = 31 : gosub num
  t = cacc
  cprow = 8 : cpcol = 31 : gosub num
  gosub showchar
  cprow = 9 : cpcol = 33 : t = csteps : gosub num
  return
  rem t as 'c' at column 35 of row 6 or 8, for t 32-95 (blanks if not;
  rem 14 is the font's apostrophe)
showchar
  u = 0 : y = 0
  if t >= 32 && t < 96 then u = 14 : y = t - 32 : y = y + y
  if cprow = 6 then cq6[0] = u : cq6[1] = y : cq6[2] = u : return
  cq8[0] = u : cq8[1] = y : cq8[2] = u
  return

clearmsg
  for x = 0 to 39 : cmsgrow[x] = 0 : next
  return

  rem button 1, a new press (u = 1)
newfire1
  u = 0
  if joy0fire1 then u = 1
  if u = 0 then fireheld = 0 : return
  if fireheld then u = 0 : return
  fireheld = 1
  return

  rem print string cstr (cards.asm c_strs) at cprow, cpcol
say
  asm
  ldx cstr
  lda c_strlo,x
  sta temp1
  lda c_strhi,x
  sta temp2
  jsr c_puts
end
  return
  rem t as 3 digits at cprow, cpcol
num
  asm
  lda t
  jsr c_num
end
  return

  rem ---- the jobs, one a day ----
  rem the solutions, one after another: opcode (1 LOAD, 2 ADD, 4 CNT,
  rem 8 LOOP, 16 OUT), operand
  rem  day 1 HELLO: H, E (punched), L twice (OUT, OUT), O
  rem  day 2 CART 123456789: the text, then LOAD '1', CNT 9, OUT, ADD 1,
  rem    LOOP 13
  rem  day 3 PONG PONG PONG PONG 54321!: CNT 4, PONG and a space, LOOP 2;
  rem    LOAD '5', CNT 5, OUT, ADD 127 (-1), LOOP 15; LOAD '!', OUT
  data csolop
  1, 16, 1, 16, 1, 16, 16, 1, 16
  1, 16, 1, 16, 1, 16, 1, 16, 1, 16, 1, 4, 16, 2, 8
  4, 1, 16, 1, 16, 1, 16, 1, 16, 1, 16, 8, 1, 4, 16, 2, 8, 1, 16
end
  data csolval
  72, 0, 69, 0, 76, 0, 0, 79, 0
  67, 0, 65, 0, 82, 0, 84, 0, 32, 0, 49, 9, 0, 1, 13
  4, 80, 0, 79, 0, 78, 0, 71, 0, 32, 0, 2, 53, 5, 0, 127, 15, 33, 0
end
  rem each job's first solution column, its length, how much comes punched,
  rem its target (c_strs), its hint
  data cjobfirst
  0, 9, 24
end
  data cjobn
  9, 15, 19
end
  data cjobpre
  4, 0, 0
end
  data cjobtarget
  25, 26, 27
end
  data cjobhint
  28, 29, 30
end
  rem the card rows' masks
  data cmop
  1, 2, 4, 8, 16, 0, 0, 0, 0, 0, 0, 0
end
  data cmval
  0, 0, 0, 0, 0, 64, 32, 16, 8, 4, 2, 1
end
  data ckonseq
  1, 1, 2, 2, 3, 4, 3, 4, 5, 6, 0
end

  rem the screen's code, its strings, and the font at $A000 (MARIA reads
  rem it from this bank, which is in while the day job runs)
  inline cards.asm
  inline cardstr.asm
  asm
  if . > $A000
  echo "bank 4: the code reaches the font's place ($A000)"
  err
  endif
  ds $A000 - ., 0
font320
end
  inline font320.asm
