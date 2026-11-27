  rem ======================================================================
  rem  0x7800_MIRROR.BIN (prototype 5, bank 6): the finale's rooms, top-down
  rem  in 160A. Arthur's living room; its TV leads to the hub (the forum as
  rem  a room), whose TVs lead to the regulars' rooms. pixelkid_07 hides in
  rem  the hub: talk to them (what they say depends on Arthur's reviews)
  rem  and they follow. Button 2: wait here / follow me. Joystick 2's fire,
  rem  any time: a second player takes pixelkid. The hub's door needs both
  rem  plates held at once; Hal's room has the rally (20 hits together:
  rem  joystick 2 takes Hal's paddle). Sue and Maria hand over their cards
  rem  (their puzzles come next). Select goes back to the menu.
  rem  The engine: mirror.asm; the rooms and talk: storyboard/mirror.txt.
  rem ======================================================================

  rem mirror.asm's: actors (0 Arthur, 1 pixelkid), the step, the room
  dim ax = $2200
  dim kx = $2201
  dim ay = $2202
  dim ky = $2203
  dim mdx = $2204
  dim mdy = $2205
  dim mpx = $2206
  dim mpy = $2207
  dim room = $2209
  dim mnpcx = $220A
  dim mnpcy = $220B
  dim mnpc = $220C
  dim mdroom = $220F
  dim mdsx = $2210
  dim mdsy = $2211
  dim mwho = $2213
  dim mmap = $2300
  dim mstage = $2600
  dim mprint = m_print
  rem this file's
  dim adir = $2216
  dim astep = $2217
  dim kdir = $2218
  dim kstep = $2219
  rem pixelkid: 0 hiding, 1 following, 2 waiting, 3 player 2's
  dim kmode = $221A
  dim kroom = $221B
  dim talkid = $221C
  dim lat1 = $221D
  dim lat2 = $221E
  dim trp = $221F
  rem Arthur's trail, for pixelkid to follow (32 steps)
  dim trx = $2220
  dim trxy = $2280
  dim mfire1 = $2263
  dim mfire2 = $2264
  dim p2want = $2265
  dim mtv = $2266
  dim hubseen = $2267
  dim hits = $2268
  dim hy = $2269
  dim rpady = $226A
  dim rbx = $226B
  dim rby = $226C
  dim rbdx = $226D
  dim rbdy = $226E
  dim rmsg = $226F
  dim dhits = $22A0
  dim halagain = $22A2
  dim intalk = $22A3
  dim facing = $22A4
  dim hudnow = $22A5
  rem the new display lists are done: m_stage to the screen after drawscreen
  dim mcommit = $22A6
  dim lever = $22A7
  dim paper = $22A8
  dim psi = $22A9
  dim pdi = $22AA
  rem kept for the finale: the cards (1 Sue, 2 Hal, 4 Maria, 8 pixelkid),
  rem the door; the card engine's job and result (cards.bas)
  dim mcards = $2710
  dim mdoor = $2711
  dim cmirror = $2712
  dim cresult = $2713
  rem where everyone was, while a card's punched (bank 4)
  dim sv = $2720

mirror
  gosub mmusic
  characterset mfont
  sfxon = 1 : AUDV0 = 0 : AUDV1 = 0
  room = 0 : kmode = 0 : kroom = 1 : mcards = 0 : mdoor = 0
  p2want = 0 : hubseen = 0 : lat1 = 0 : lat2 = 0 : intalk = 0 : mcommit = 0
  lever = 0 : paper = 0
  kx = 8 : ky = 92 : kdir = 0 : kstep = 0
  ax = 72 : ay = 140 : adir = 1 : astep = 0
  mfire1 = 1 : mfire2 = 1
  gosub mroom
  talkid = 0 : gosub talk

mloop
  restorescreen
  frm = frm + 1
  gosub mplayer
  gosub mkid
  if room = 1 then gosub mplates
  gosub mhud
  gosub mdraw
  drawscreen
  if mcommit then gosub mdocommit
  if switchreset then reboot
  if switchselect then characterset font : goto menu
  gosub mp2
  gosub mbuttons
  if w = 1 then gosub mact
  if w = 2 then gosub mtoggle
  goto mloop

  rem ---- the room ----
  rem load it (map, colours, who's there) and draw it once
  rem (the map changes only after the frame's been drawn, and the display
  rem lists are rebuilt from the top at once, ahead of MARIA: no frame of
  rem the new map in the old palettes)
mroom
  drawwait
  asm
  jsr m_blankall
  jsr m_load
end
  P0C1 = $0F : P0C2 = $80 : P0C3 = $0F
  P1C1 = $3A : P1C2 = $D4 : P1C3 = $08
  P2C1 = $3A : P2C2 = $56 : P2C3 = $84
  rem the hub: the door (row 6, column 15) once it's open; pixelkid once
  rem they've joined isn't the hub's regular any more
  if room = 1 && mdoor then mstage[135] = 138
  if room = 1 && kmode then mnpc = 0
  if mnpc = 1 then P3C1 = $3A : P3C2 = $14 : P3C3 = $26
  if mnpc = 2 then P3C1 = $3A : P3C2 = $46 : P3C3 = $02
  if mnpc = 3 then P3C1 = $3A : P3C2 = $74 : P3C3 = $0C
  hudnow = 0
  gosub mredraw
  for x = 0 to 31 : trx[x] = ax : trxy[x] = ay : next
  return

  rem ---- Arthur ----
mplayer
  mdx = 0 : mdy = 0
  if joy0left then mdx = 255 : adir = 2
  if joy0right then mdx = 1 : adir = 3
  if joy0up then mdy = 254 : adir = 1
  if joy0down then mdy = 2 : adir = 0
  if mdx = 0 && mdy = 0 then astep = 0 : return
  mwho = 0
  asm
  jsr m_move
  sta mtv
end
  if mtv = 0 then return
  t = frm / 8 : astep = t & 1
  trp = trp + 1 : trp = trp & 31
  trx[trp] = ax : trxy[trp] = ay
  return

  rem ---- pixelkid ----
mkid
  if kroom <> room then return
  if kmode = 0 then return
  if kmode = 2 then kstep = 0 : return
  mdx = 0 : mdy = 0
  if kmode = 3 then goto mkidp2
  rem following: walk to where Arthur was 10 steps ago
  t = trp - 10 : t = t & 31
  u = trx[t] : v = trxy[t]
  if u < kx then mdx = 255 : kdir = 2
  if u > kx then mdx = 1 : kdir = 3
  t = v + 1 : if t < ky then mdy = 254 : kdir = 1
  t = ky + 1 : if v > t then mdy = 2 : kdir = 0
  goto mkidgo
mkidp2
  if joy1left then mdx = 255 : kdir = 2
  if joy1right then mdx = 1 : kdir = 3
  if joy1up then mdy = 254 : kdir = 1
  if joy1down then mdy = 2 : kdir = 0
mkidgo
  if mdx = 0 && mdy = 0 then kstep = 0 : return
  mwho = 1
  asm
  jsr m_move
  sta mtv
end
  if mtv then t = frm / 8 : kstep = t & 1
  return

  rem joystick 2's fire: a second player is pixelkid (once they've joined)
mp2
  if kmode = 3 then return
  t = 0
  if joy1fire0 then t = 1
  if joy1fire1 then t = 1
  if t = 0 then return
  if kmode = 0 then p2want = 1 : return
  kmode = 3
  if kroom <> room then kroom = room : kx = ax : ky = ay
  talkid = 7 : goto talk

  rem button 2: wait here / follow me (pixelkid must be in the room)
mtoggle
  if kroom <> room then return
  if kmode = 1 then kmode = 2 : sfxid = 10 : goto playsfx
  if kmode = 2 then kmode = 1 : sfxid = 10 : goto playsfx
  return

  rem ---- the hub's door: both plates at once ----
  rem a plate stays down a second after you step off (plates: row 4
  rem column 13, map index 93; row 9 column 3, 183; the door 135)
mplates
  if mcommit then return
  u = 0 : v = 0
  mpx = ax + 4 : mpy = ay + 12
  asm
  jsr m_at
  stx mtv
end
  if mtv = 93 then u = 1
  if mtv = 183 then v = 1
  if kmode = 0 then goto mplates2
  mpx = kx + 4 : mpy = ky + 12
  asm
  jsr m_at
  stx mtv
end
  if mtv = 93 then u = 1
  if mtv = 183 then v = 1
mplates2
  if u then lat1 = 60
  if v then lat2 = 60
  t = 134 : u = 134
  if lat1 then lat1 = lat1 - 1 : t = 136
  if lat2 then lat2 = lat2 - 1 : u = 136
  mmap[93] = t : mstage[93] = t : mmap[183] = u : mstage[183] = u
  rem the feed lever (row 6, column 18: 138) is down while pixelkid stands
  rem in front of it (column 17: 137); Arthur can't hold it and feed too
  lever = 0
  if kmode = 0 then goto mlever
  mpx = kx + 4 : mpy = ky + 12
  asm
  jsr m_at
  stx mtv
end
  if mtv = 137 then lever = 1
mlever
  t = 182 : if lever then t = 184
  mmap[138] = t : mstage[138] = t
  if mdoor then return
  if lat1 = 0 || lat2 = 0 then return
  mdoor = 1 : mmap[135] = 138 : mstage[135] = 138
  sfxid = 4 : gosub playsfx
  talkid = 14 : goto talk

  rem ---- drawing: the regular, pixelkid, Arthur ----
mdraw
  if paper then return
  rem (while talking, no one's drawn over the box: rows 9-11, lines 144 up)
  if intalk then goto mdrawt
  if mnpc = 1 then plotsprite msue 3 mnpcx mnpcy
  if mnpc = 2 then plotsprite mhal 3 mnpcx mnpcy
  if mnpc = 3 then plotsprite mmaria 3 mnpcx mnpcy
  if mnpc = 4 then plotsprite mkid0 2 mnpcx mnpcy
  if kmode = 0 then goto mdrawa
  if kroom <> room then goto mdrawa
  t = kdir + kdir : t = t + kstep
  plotsprite mkid0 2 kx ky t
mdrawa
  t = adir + adir : t = t + astep
  plotsprite marthur0 1 ax ay t
  return
mdrawt
  if mnpc = 1 && mnpcy < 129 then plotsprite msue 3 mnpcx mnpcy
  if mnpc = 2 && mnpcy < 129 then plotsprite mhal 3 mnpcx mnpcy
  if mnpc = 3 && mnpcy < 129 then plotsprite mmaria 3 mnpcx mnpcy
  if mnpc = 4 && mnpcy < 129 then plotsprite mkid0 2 mnpcx mnpcy
  if kmode = 0 then goto mdrawta
  if kroom <> room then goto mdrawta
  if ky >= 129 then goto mdrawta
  t = kdir + kdir : t = t + kstep
  plotsprite mkid0 2 kx ky t
mdrawta
  if ay >= 129 then return
  t = adir + adir : t = t + astep
  plotsprite marthur0 1 ax ay t
  return

  rem ---- button 1: talk to whoever's there, or use what's in front ----
mact
  gosub mfacing
  if facing = 1 then goto mtalknpc
  if facing = 2 then goto mgo
  if facing = 3 then talkid = 13 : goto talk
  if facing = 4 then goto mreader
  if facing = 5 then goto mtalkkidcard
  return

  rem what's in front of Arthur: facing = 0 nothing, 1 the room's regular,
  rem 2 a TV (mdroom: where it goes), 3 the closed door, 4 the card reader
mfacing
  facing = 0
  mpx = ax + 4 : mpy = ay + 12
  if adir = 0 then mpy = mpy + 12
  if adir = 1 then mpy = mpy - 14
  if adir = 2 then mpx = mpx - 8
  if adir = 3 then mpx = mpx + 8
  if mnpc = 0 then goto mfacingt
  t = mnpcx + 4 : u = mnpcy + 12
  if mpx < t then t = t - mpx else t = mpx - t
  if mpy < u then u = u - mpy else u = mpy - u
  if t < 10 && u < 16 then facing = 1 : return
mfacingt
  rem pixelkid, once they're with Arthur
  if kmode = 0 || kroom <> room then goto mfacingd
  t = kx + 4 : u = ky + 12
  if mpx < t then t = t - mpx else t = mpx - t
  if mpy < u then u = u - mpy else u = mpy - u
  if t < 10 && u < 16 then facing = 5 : return
mfacingd
  asm
  jsr m_door
end
  if mdroom <> 255 then facing = 2 : return
  asm
  jsr m_at
  sta mtv
end
  if mtv = 172 then facing = 3
  if mtv >= 174 && mtv <= 180 then facing = 4
  return

  rem the top row: the room's name, or what button 1 would do (it's the
  rem map's row 0: writing it changes the screen)
mhud
  gosub mfacing
  t = facing
  if facing = 3 || facing = 4 then t = 3
  if facing = 5 then t = 1
  if t = hudnow then return
  hudnow = t
  asm
  lda hudnow
  jsr m_hud
end
  return

  rem through a TV: pixelkid comes along unless they're waiting
mgo
  sfxid = 3 : gosub playsfx
  rem (stepping out facing away from the TV: down from a TV above)
  room = mdroom : ax = mdsx : ay = mdsy : adir = 0
  if mdsy >= 96 then adir = 1
  if kmode = 1 || kmode = 3 then kroom = room : kx = ax : ky = ay
  gosub mroom
  if room = 1 && hubseen = 0 then hubseen = 1 : talkid = 1 : goto talk
  return

mtalknpc
  if mnpc = 4 then goto mtalkkid
  if mnpc = 2 then goto mtalkhal
  rem Sue's card (job 1) and Maria's (job 2): punched in the card engine
  if mnpc = 3 then goto mtalkmaria
  t = mcards & 1
  if t then talkid = 12 : goto talk
  talkid = 8 : gosub talk
  t = 1 : goto mcardgo
mtalkmaria
  t = mcards & 4
  if t then talkid = 18 : goto talk
  talkid = 11 : gosub talk
  t = 2 : goto mcardgo
  rem pixelkid's own card (job 3), once they're following
mtalkkidcard
  t = mcards & 8
  if t then talkid = 21 : goto talk
  talkid = 19 : gosub talk
  t = 3 : goto mcardgo
mtalkhal
  halagain = mcards & 2
  talkid = 9
  if halagain then talkid = 16
  gosub talk
  gosub rally
  if u = 0 then return
  if halagain then return
  mcards = mcards | 2
  talkid = 10 : goto talk
  rem pixelkid: what they say depends on Arthur's reviews (the kind
  rem phrases he posted, all three evenings)
mtalkkid
  t = rev_kind[0] + rev_kind[1] : t = t + rev_kind[2]
  talkid = 2
  if t then talkid = 3
  if t >= 3 then talkid = 4
  gosub talk
  talkid = 5 : gosub talk
  kmode = 1 : kroom = 1 : kx = mnpcx : ky = mnpcy : mnpc = 0
  talkid = 6 : gosub talk
  if p2want then kmode = 3 : talkid = 7 : goto talk
  return

  rem ---- the big card reader: all four cards, and someone on the lever ----
mreader
  if mcards <> 15 then talkid = 15 : goto talk
  if lever = 0 then talkid = 22 : goto talk
  talkid = 23 : gosub talk
  rem the printout: the room goes, the paper comes, a line a card
  drawwait
  paper = 1
  asm
  jsr m_paper
end
  BACKGRND = $0C : P0C1 = $00
  gosub mredraw
  for x = 0 to 60 : gosub mframe : next
  rem (rows 2, 4, 6, 8: the talk box after is rows 9-11)
  psi = 0 : pdi = 40
  for v = 0 to 3
  for u = 0 to 19
  w = mprint[psi] : psi = psi + 1
  if w = 0 then goto mprintnext
  t = pdi + u : mmap[t] = w : mstage[t] = w
  sfxid = 10 : gosub playsfx
  for x = 0 to 5 : gosub mframe : next
mprintnext
  next
  pdi = pdi + 40
  for x = 0 to 30 : gosub mframe : next
  next
  for x = 0 to 60 : gosub mframe : next
  talkid = 24 : gosub talk
  rem (the potluck is next: prototype 6)
  characterset font
  goto menu
  rem a frame with nothing but the screen
mframe
  restorescreen
  drawscreen
  if mcommit then gosub mdocommit
  return

  rem ---- a card in the card engine (bank 4): t = 1 Sue's, 2 Maria's, 3
  rem pixelkid's. Everyone's place is kept; mirrorback picks up ----
mcardgo
  cmirror = t
  sv[0] = room : sv[1] = ax : sv[2] = ay : sv[3] = adir : sv[4] = kx
  sv[5] = ky : sv[6] = kdir : sv[7] = kmode : sv[8] = kroom : sv[9] = p2want
  sv[10] = hubseen
  rem (from mact: its return's dropped)
  pop
  goto cardsm bank4
mirrorback
  room = sv[0] : ax = sv[1] : ay = sv[2] : adir = sv[3] : kx = sv[4]
  ky = sv[5] : kdir = sv[6] : kmode = sv[7] : kroom = sv[8] : p2want = sv[9]
  hubseen = sv[10]
  gosub mmusic
  characterset mfont
  sfxon = 1 : AUDV0 = 0 : AUDV1 = 0
  lat1 = 0 : lat2 = 0 : intalk = 0 : mcommit = 0 : lever = 0 : paper = 0
  astep = 0 : kstep = 0 : mfire1 = 1 : mfire2 = 1
  gosub mroom
  if cresult = 0 then talkid = 25 : gosub talk : goto mloop
  if cmirror = 1 then mcards = mcards | 1 : talkid = 12
  if cmirror = 2 then mcards = mcards | 4 : talkid = 18
  if cmirror = 3 then mcards = mcards | 8 : talkid = 20
  sfxid = 11 : gosub playsfx
  gosub talk
  goto mloop

  rem the mirror's song (tools/music.py: generated)
mmusic
  asm
  lda #MUS_MIRROR
  jsr mus_play
end
  musmask = $3F
  return

  rem ---- the talk box: rows 9-11 ----
  rem (the box is the room's bottom three rows, written over: m_boxsave
  rem keeps them, m_boxback puts them back, and the room's redrawn)
talk
  drawwait
  asm
  jsr m_boxsave
  jsr m_blankbox
  lda talkid
  jsr m_talk
end
  gosub mredraw
  mfire1 = 1 : mfire2 = 1 : intalk = 1
talkloop
  restorescreen
  gosub mdraw
  drawscreen
  if mcommit then gosub mdocommit
  if switchreset then reboot
  gosub mbuttons
  if w = 0 then goto talkloop
  asm
  jsr m_next
  sta mtv
  jsr m_commitbox
end
  if mtv then goto talkloop
  intalk = 0
  drawwait
  asm
  jsr m_blankbox
  jsr m_boxback
end
  if room = 1 && mdoor then mstage[135] = 138
  rem (the display lists from m_stage; it goes on screen after drawscreen)
mredraw
  clearscreen
  asm
  jsr m_draw
end
  savescreen
  mcommit = 1
  return
mdocommit
  mcommit = 0
  asm
  jsr m_commit
end
  return

  rem w = 1 on a new press of button 1, 2 of button 2
mbuttons
  w = 0
  if !joy0fire1 then mfire1 = 0
  if !joy0fire0 then mfire2 = 0
  if joy0fire1 && !mfire1 then mfire1 = 1 : w = 1 : return
  if joy0fire0 && !mfire2 then mfire2 = 1 : w = 2
  return

  rem ======================================================================
  rem  Hal's rally: two paddles, one ball, 20 hits in a row together. Hal
  rem  (the CPU) never misses; joystick 2 takes his paddle. Button 2 gives
  rem  up. u = 1 if you made it.
  rem ======================================================================
rally
  BACKGRND = $00
  P1C1 = $44 : P1C2 = $48 : P1C3 = $4E
  P3C1 = $C4 : P3C2 = $C8 : P3C3 = $CE
  P6C1 = $1E : P6C2 = $18
  P5C1 = $04 : P5C2 = $06 : P5C3 = $08
  clearscreen
  plotchars 'HITS' 0 0 0
  plotchars '/ 20' 0 64 0
  plotchars mwall 5 0 1 20
  plotchars mwall 5 0 11 20
  savescreen
  rpady = 90 : hy = 90 : hits = 0 : rmsg = 0
  gosub rserve
  mfire1 = 1 : mfire2 = 1
rloop
  restorescreen
  frm = frm + 1
  if joy0up then rpady = rpady - 3
  if joy0down then rpady = rpady + 3
  if rpady < 32 then rpady = 32
  if rpady > 148 then rpady = 148
  if kmode = 3 then goto rhalp2
  rem Hal follows the ball on its way to him, and drifts home
  t = 90
  if rbdx < 128 then t = rby - 11
  if hy < t then hy = hy + 2
  if hy > t then hy = hy - 2
  goto rhalgo
rhalp2
  if joy1up then hy = hy - 3
  if joy1down then hy = hy + 3
rhalgo
  if hy < 32 then hy = 32
  if hy > 148 then hy = 148
  if rmsg then rmsg = rmsg - 1 : plotchars 'OOF. AGAIN!' 0 104 0 : goto rdraw
  gosub rball
rdraw
  plotsprite padp 1 8 rpady 0 2
  plotsprite padp 3 148 hy 0 2
  plotsprite ball 6 rbx rby
  t = hits : gosub todec
  dhits[0] = x + x + 32 : dhits[1] = y + y + 32
  plotchars dhits 0 40 0 2
  drawscreen
  if switchreset then reboot
  if hits >= 20 then u = 1 : goto rallydone
  gosub mbuttons
  if w <> 2 then goto rloop
  u = 0
rallydone
  gosub mroom
  return

rball
  rbx = rbx + rbdx : rby = rby + rbdy
  if rby < 32 then rby = 32 : rbdy = 0 - rbdy
  if rby > 170 then rby = 170 : rbdy = 0 - rbdy
  if rbdx >= 128 then goto rballl
  if rbx < 142 then return
  t = rby + 6 : u = hy + 28
  if t > hy && rby < u then goto rhit
  if rbx < 156 then return
  goto rmiss
rballl
  if rbx > 12 then return
  t = rby + 6 : u = rpady + 28
  if t > rpady && rby < u then goto rhit
  if rbx > 2 then return
rmiss
  hits = 0 : rmsg = 60
  sfxid = 5 : gosub playsfx
rserve
  rbx = 76 : rby = 96 : rbdx = 2 : rbdy = 1
  return
rhit
  rbdx = 0 - rbdx
  if rbdx < 128 then rbx = 13 else rbx = 141
  t = rand & 3 : rbdy = rdy[t]
  hits = hits + 1
  sfxid = 3 : goto playsfx

  data rdy
  255, 1, 254, 2
end
  data mwall
  140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140, 140
end

  rem the rooms and the talk, then the graphics at $A000, then the engine
  rem in $B000-$BFFF: the DMA hole above them, which MARIA never reads
  inline mirrordat.asm
  asm
  if . > $A000
  echo "bank 6: the code reaches the graphics' place ($A000)"
  err
  endif
  ds $A000 - ., 0
end
  inline mirrorgfx.asm
  inline mirror.asm
