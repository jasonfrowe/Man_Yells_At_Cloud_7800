  rem ======================================================================
  rem  THE CUTSCENES (prototype 6, bank 7): the story's linking scenes,
  rem  teletype text in 40 columns (cut.asm, on text40.asm). cutid says
  rem  which (storyboard/script.txt). Button 1 finishes a page, then turns
  rem  it; after the last, the story goes on (scenedone).
  rem ======================================================================

  dim cutid = $2716
  rem row 11 from column 33 (the hint); cut.asm's page done
  dim cuthint = $24D9
  dim cudone = $2287

cutscene
  asm
  jsr c_enter
end
  sfxon = 1 : AUDV0 = 0 : AUDV1 = 0
  BACKGRND = $00
  P0C1 = $0F : P0C2 = $0F : P0C3 = $0F
  P1C1 = $1C : P1C2 = $1C : P1C3 = $1C
  P2C1 = $0C : P2C2 = $0C : P2C3 = $0C
  P3C1 = $98 : P3C2 = $98 : P3C3 = $98
  P4C1 = $5C : P4C2 = $5C : P4C3 = $5C
  P5C1 = $3C : P5C2 = $3C : P5C3 = $3C
  P6C1 = $CC : P6C2 = $CC : P6C3 = $CC
  P7C1 = $6C : P7C2 = $6C : P7C3 = $6C
  fireheld = 1
  asm
  lda cutid
  jsr cut_begin
end
cutpage
  drawwait
  asm
  jsr cut_pageset
end
  clearscreen
  asm
  lda #<cu_rec
  sta c_ptr
  lda #>cu_rec
  sta c_ptr+1
  jsr c_draw
end
  savescreen
cutloop
  frm = frm + 1
  rem two letters a frame
  asm
  jsr cut_tick
  jsr cut_tick
end
  rem "1: NEXT", blinking, once the page is typed
  for x = 0 to 6 : cuthint[x] = 0 : next
  t = frm & 32
  if cudone = 0 || t = 0 then goto cuthintoff
  for x = 0 to 6 : cuthint[x] = hintstr[x] : next
cuthintoff
  drawscreen
  if switchreset then reboot
  gosub newfire
  if u = 0 then goto cutloop
  if cudone then goto cutturn
  asm
  jsr cut_finish
end
  goto cutloop
cutturn
  asm
  jsr cut_next
  sta temp7
end
  if temp7 then goto cutpage
  asm
  jsr c_leave
end
  goto scenedone

  rem "1: NEXT" in the font's codes
  data hintstr
  34, 52, 0, 92, 74, 112, 104
end

  inline cut.asm
  inline cuttxt.asm
  asm
  if . > $A000
  echo "bank 7: the code reaches the font's place ($A000)"
  err
  endif
  ds $A000 - ., 0
end
  rem (font320.asm again: tools/build.sh copies it)
  inline font320c.asm
