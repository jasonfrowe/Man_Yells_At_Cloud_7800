  rem ======================================================================
  rem  THE EVENING FORUM (prototype 4, bank 5): the 7800 homebrew forum's
  rem  new-releases board, in 320A, 40 columns (forum.asm on text40.asm).
  rem  The evening (the menu's day) has up to four threads, from the
  rem  script (storyboard/forum.txt, tools/forum.py). The first is
  rem  pixelkid_07's latest release: 1 downloads it (the slop ROM, bank 2),
  rem  and after its crash Arthur writes the review (forumrev, below) and
  rem  posts it to the thread, where a regular answers him.
  rem    thread list   up/down pick, 1 read, 2 log off (to the menu)
  rem    a thread      up/down scroll, 1 download (the release), 2 back
  rem    the review    up/down the line, left/right the words, 1 post
  rem ======================================================================

  rem forum.asm's
  dim fday = $2280
  dim fthr = $2281
  dim ftop = $2282
  dim fsel = $2284
  dim fmore = $2285
  dim fslot = $2299
  dim fview = $229A
  dim fdir = $229B
  dim ffire1 = $229C
  dim ffire2 = $229D
  dim flast = $229E
  dim fisrel = $229F
  dim fhp2 = $22D6
  rem row 11 from column 30: where DOWN: MORE blinks
  dim fmoretxt = $24D6

forum
  fday = night - 1
  gosub fenter
  fsel = 0
  goto flist

  rem from the slop ROM's crash: the review
forumrev
  fday = night - 1
  gosub fenter
  asm
  jsr f_rev_build
end
  clearscreen
  asm
  jsr f_rev_draw
  jsr f_draw
end
  savescreen
frevloop
  gosub fframe
  gosub fstick
  if w = 1 && fslot > 0 then fslot = fslot - 1 : gosub frevtext
  if w = 2 && fslot < 2 then fslot = fslot + 1 : gosub frevtext
  if w = 3 then gosub frevprev
  if w = 4 then gosub frevnext
  gosub fbuttons
  if w <> 1 then goto frevloop
  rem posted: to the thread, the review on screen
  sfxid = 11 : gosub playsfx
  asm
  jsr f_rev_post
end
  asm
  jsr f_open_rev
end
  goto fthread

frevtext
  asm
  jsr f_rev_text
end
  return
frevprev
  asm
  jsr f_rev_prev
end
  sfxid = 10 : goto playsfx
frevnext
  asm
  jsr f_rev_next
end
  sfxid = 10 : goto playsfx

  rem ---- the thread list ----
flist
  clearscreen
  asm
  jsr f_list_draw
  jsr f_draw
end
  savescreen
flistloop
  asm
  jsr f_list_mark
end
  gosub fframe
  gosub fstick
  asm
  jsr f_info
end
  if w = 1 && fsel > 0 then fsel = fsel - 1
  if w = 2 && fsel < flast then fsel = fsel + 1
  gosub fbuttons
  if w = 2 then goto fleave
  if w = 0 then goto flistloop
  asm
  jsr f_open
end

  rem ---- a thread ----
fthread
  clearscreen
  asm
  jsr f_thread_draw
  jsr f_draw
end
  savescreen
fthreadloop
  rem more posts below: DOWN: MORE, blinking (gold)
  if fmore = 0 then goto fthreadmore
  t = frm & 32
  for x = 0 to 9 : fmoretxt[x] = 0 : next
  if t = 0 then goto fthreadmore
  for x = 0 to 9 : fmoretxt[x] = moretxt[x] : next
fthreadmore
  frm = frm + 1
  gosub fframe
  gosub fstick
  if w = 1 && ftop > 0 then ftop = ftop - 1 : goto fthread
  if w = 2 && fmore then ftop = ftop + 1 : goto fthread
  gosub fbuttons
  if w = 2 then goto flist
  if w = 0 then goto fthreadloop
  asm
  jsr f_info
end
  if fisrel = 0 then goto fthreadloop
  rem download it: the slop ROM (its crash comes back to forumrev)
  asm
  jsr c_leave
end
  goto title bank2

  rem "DOWN: MORE"
  data moretxt
  72, 94, 110, 92, 52, 0, 90, 94, 100, 74
end

fleave
  asm
  jsr c_leave
end
  goto scenedone

  rem ---- helpers ----
  rem the 40-column screen, the forum's palettes and its music
fenter
  asm
  lda #MUS_FORUM
  jsr mus_play
  jsr c_enter
end
  musmask = $37
  sfxon = 1 : AUDV0 = 0 : AUDV1 = 0
  BACKGRND = $00
  P0C1 = $0F : P0C2 = $0F : P0C3 = $0F
  P1C1 = $1C : P1C2 = $1C : P1C3 = $1C
  P2C1 = $06 : P2C2 = $06 : P2C3 = $06
  P3C1 = $98 : P3C2 = $98 : P3C3 = $98
  P4C1 = $5C : P4C2 = $5C : P4C3 = $5C
  P5C1 = $3C : P5C2 = $3C : P5C3 = $3C
  P6C1 = $CC : P6C2 = $CC : P6C3 = $CC
  P7C1 = $6C : P7C2 = $6C : P7C3 = $6C
  fslot = 0 : fdir = 0 : ffire1 = 1 : ffire2 = 1 : fhp2 = 2
  return

fframe
  drawscreen
  if switchreset then reboot
  return

  rem the stick: w = 1 up, 2 down, 3 left, 4 right, on a new push (and
  rem repeating every 8 frames while held, after 20)
fstick
  w = 0
  if joy0up then w = 1
  if joy0down then w = 2
  if joy0left then w = 3
  if joy0right then w = 4
  if w = 0 then fdir = 0 : return
  if w <> fdir then fdir = w : fview = 20 : return
  fview = fview - 1
  if fview then w = 0 : return
  fview = 8
  return

  rem the buttons: w = 1 on a new press of button 1, 2 of button 2
fbuttons
  w = 0
  if !joy0fire1 then ffire1 = 0
  if !joy0fire0 then ffire2 = 0
  if joy0fire1 && !ffire1 then ffire1 = 1 : w = 1 : return
  if joy0fire0 && !ffire2 then ffire2 = 1 : w = 2
  return

  inline forum.asm
  inline forumtxt.asm
  asm
  if . > $A000
  echo "bank 5: the code reaches the font's place ($A000)"
  err
  endif
  ds $A000 - ., 0
end
  rem (font320.asm again: tools/build.sh copies it)
  inline font320b.asm
