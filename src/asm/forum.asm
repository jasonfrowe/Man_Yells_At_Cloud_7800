; ===========================================================================
; The evening forum (bank 5), on the 40-column text screen (text40.asm):
; the thread list, a thread, and the review builder. The script's tables
; (gen/forumtxt.asm, from storyboard/forum.txt by tools/forum.py) say who
; posted what.
;
; The thread list                    A thread
;   0  header, the evening  gold       0  its title                 gold
;   2  > title                         1  "PIXELKID_07 IS VIEWING"  dim
;   3      by NAME   n REPLIES         2- posts: an avatar (4 x 2
;   ... (up to 4 threads)                 characters), the name and
;  11  help                 dim           tag, then the lines (white)
;                                     11  help (and MORE...)
; Palettes: 0 white, 1 gold, 2 dim, 3-7 the posters' (f_upal).
;
; The review builder: three lines, a slot each (opener, the bugs, the
; verdict), from the script's phrases: a slot offers the phrases of its
; day or earlier, a bug's only if Arthur saw that bug (seenbugs).
; ===========================================================================

f_day     = $2280   ; the evening (0-2)
f_thr     = $2281   ; the thread (an index into the f_t tables)
f_top     = $2282   ; its first post on the screen
f_np      = $2283   ; its posts (with Arthur's review and the reply)
f_sel     = $2284   ; the list's selection
f_more    = $2285   ; more posts below the screen
f_row     = $2286
f_seg     = $2287   ; the display object list's length (bytes)
f_rel     = $2288
f_who     = $2289   ; the post being drawn: who, how many lines
f_lns     = $228A
f_t       = $228B
f_t2      = $228C
fs_r      = $228D   ; f_addseg: row, column, length, palette
fs_c      = $228E
fs_l      = $228F
fs_p      = $2290
f_lplo    = $2291   ; [4] the post's lines
f_lphi    = $2295   ; [4]
f_slot    = $2299   ; the review builder's line
f_list    = $22A0   ; [48] each slot's phrases (16 a slot)
f_listn   = $22D0   ; [3]
f_pick    = $22D3   ; [3] each slot's pick (in f_list)
f_segs    = $2600   ; the display objects (c_draw's records)
f_last    = $229E
f_isrel   = $229F

; the reviews (the whole game's: dims in myac.bas)
;   rev_ph   [9] the phrases picked, 3 a day
;   rev_done [3] a review posted that day
;   rev_kind [3] how many constructive phrases in it

; ---- small helpers ---------------------------------------------------------
; f_addseg: a display object (fs_r, fs_c, fs_l, fs_p)
f_addseg
    ldx f_seg
    lda fs_r
    sta f_segs,x
    lda fs_c
    sta f_segs+1,x
    lda fs_l
    sta f_segs+2,x
    lda fs_p
    sta f_segs+3,x
    lda #$FF
    sta f_segs+4,x          ; (the end, until the next)
    txa
    clc
    adc #4
    sta f_seg
    rts
; f_row2: a whole row in palette A (two objects: 0-31, 32-39), row X
f_row2
    sta fs_p
    stx fs_r
    lda #0
    sta fs_c
    lda #32
    sta fs_l
    jsr f_addseg
    lda #32
    sta fs_c
    lda #8
    sta fs_l
    jmp f_addseg
; f_print: the string at (A lo, Y hi) at c_prow, c_pcol
f_print
    sta temp1
    sty temp2
    jmp c_puts
; f_start: a clear screen, no display objects
f_start
    jsr c_cls
    lda #0
    sta f_seg
    lda #$FF
    sta f_segs
    rts
; f_draw: the display objects to the screen (7800basic's clearscreen first)
f_draw
    lda #<f_segs
    sta c_ptr
    lda #>f_segs
    sta c_ptr+1
    jmp c_draw
; f_help: help string (A lo, Y hi) on row 11, dim
f_help
    pha
    lda #11
    sta c_prow
    lda #0
    sta c_pcol
    pla
    jsr f_print
    lda #2
    ldx #11
    jmp f_row2

; ---- the thread list -------------------------------------------------------
f_list_draw
    jsr f_start
    lda #0
    sta c_prow
    sta c_pcol
    lda #<f_hdr
    ldy #>f_hdr
    jsr f_print
    lda #32
    sta c_pcol
    ldx f_day
    lda f_dnlo,x
    ldy f_dnhi,x
    jsr f_print
    lda #1
    ldx #0
    jsr f_row2
    lda #0
    sta f_rel               ; the thread on the list (0-3)
f_ld_t
    ldx f_day
    lda f_rel
    cmp f_dthn,x
    bcc f_ld_t1
    jmp f_ld_x
f_ld_t1
    clc
    adc f_dth0,x
    sta f_t                 ; its index
    lda f_rel
    asl
    clc
    adc #2
    sta f_row
    sta c_prow              ; the title
    lda #2
    sta c_pcol
    ldx f_t
    lda f_ttlo,x
    ldy f_tthi,x
    jsr f_print
    lda #0
    ldx f_row
    jsr f_row2
    inc f_row               ; by NAME, n REPLIES
    lda f_row
    sta c_prow
    lda #4
    sta c_pcol
    ldx f_t
    ldy f_tby,x
    sty f_who
    lda f_unlo,y
    pha
    lda f_unhi,y
    tay
    pla
    jsr f_print
    lda f_row
    sta fs_r
    lda #4
    sta fs_c
    lda #13
    sta fs_l
    ldx f_who
    lda f_upal,x
    sta fs_p
    jsr f_addseg
    lda #17
    sta c_pcol
    ldx f_t
    jsr f_count
    jsr c_num
    lda #21
    sta c_pcol
    lda #<f_replies
    ldy #>f_replies
    jsr f_print
    lda #17
    sta fs_c
    lda #23
    sta fs_l
    lda #2
    sta fs_p
    jsr f_addseg
    inc f_rel
    jmp f_ld_t
f_ld_x
    lda #<f_hlist
    ldy #>f_hlist
    jmp f_help

; f_count: thread X's replies in A (its posts but the first, and Arthur's
; review and the reply once he's posted it)
f_count
    lda f_tpn,x
    sta f_t2
    dec f_t2
    lda f_trel,x
    beq f_cnt_r
    ldy f_day
    lda rev_done,y
    beq f_cnt_r
    inc f_t2
    inc f_t2
f_cnt_r
    lda f_t2
    rts

; f_list_mark: the selection's arrow
f_list_mark
    lda #0
    sta f_t
f_lm_l
    lda f_t
    asl
    adc #2
    sta c_prow
    lda #0
    sta c_pcol
    jsr c_at
    lda #0
    ldx f_t
    cpx f_sel
    bne f_lm_s
    lda #(62 - 32) * 2      ; >
f_lm_s
    ldy #0
    sta (c_ptr),y
    inc f_t
    lda f_t
    cmp #4
    bne f_lm_l
    rts

; ---- a thread --------------------------------------------------------------
f_thread_draw
    jsr f_start
    lda #0
    sta c_prow
    sta c_pcol
    ldx f_thr
    lda f_ttlo,x
    ldy f_tthi,x
    jsr f_print
    lda #1
    ldx #0
    jsr f_row2
    ldx f_thr
    lda f_trel,x
    beq f_td_nv
    lda #1
    sta c_prow
    lda #0
    sta c_pcol
    lda #<f_viewing
    ldy #>f_viewing
    jsr f_print
    lda #2
    ldx #1
    jsr f_row2
f_td_nv
    ldx f_thr
    jsr f_count
    clc
    adc #1
    sta f_np
    lda #0
    sta f_more
    lda #2
    sta f_row
    lda f_top
    sta f_rel
f_td_p
    lda f_rel
    cmp f_np
    bcs f_td_x
    jsr f_getpost
    lda f_lns               ; its rows: the name's and the lines (2 at least)
    clc
    adc #1
    cmp #2
    bcs f_td_r
    lda #2
f_td_r
    sta f_t
    clc
    adc f_row
    cmp #12
    bcc f_td_fits
    lda #1
    sta f_more
    bne f_td_x
f_td_fits
    jsr f_post
    lda f_row
    sec
    adc f_t                 ; (and a blank row)
    sta f_row
    inc f_rel
    cmp #11
    bcc f_td_p
    lda f_rel
    cmp f_np
    bcs f_td_x
    lda #1
    sta f_more
f_td_x
    ldx f_thr
    lda f_trel,x
    beq f_td_h2
    lda #<f_hrel
    ldy #>f_hrel
    bne f_td_h
f_td_h2
    lda #<f_hthr
    ldy #>f_hthr
f_td_h
    jsr f_help
    lda f_more
    beq f_td_r2
    lda #11
    sta c_prow
    lda #32
    sta c_pcol
    lda #<f_moretxt
    ldy #>f_moretxt
    jsr f_print
f_td_r2
    rts

; f_getpost: post f_rel of the thread: f_who, f_lns, f_lplo/hi
f_getpost
    ldx f_thr
    lda f_rel
    cmp f_tpn,x
    bcs f_gp_extra
    adc f_tp0,x
    tax
f_gp_rom                    ; post X of the script
    lda f_pby,x
    sta f_who
    lda f_pn,x
    sta f_lns
    lda f_pl0,x
    tax
    ldy #0
f_gp_l
    cpy f_lns
    beq f_gp_r
    lda f_lnlo,x
    sta f_lplo,y
    lda f_lnhi,x
    sta f_lphi,y
    inx
    iny
    bne f_gp_l
f_gp_r
    rts
f_gp_extra
    sec
    sbc f_tpn,x
    bne f_gp_reply
    lda #F_ARTHUR           ; Arthur's review: his three phrases
    sta f_who
    lda #3
    sta f_lns
    lda f_day
    sta f_t2
    asl
    adc f_t2
    tax                     ; rev_ph + 3 x day
    ldy #0
f_gp_rv
    lda rev_ph,x
    sty f_t2
    tay
    lda f_phlo,y
    pha
    lda f_phhi,y
    ldy f_t2
    sta f_lphi,y
    pla
    sta f_lplo,y
    inx
    iny
    cpy #3
    bne f_gp_rv
    rts
f_gp_reply                  ; the reply to it (a kinder one for a kind review)
    lda f_day
    asl
    tax
    ldy f_day
    lda rev_kind,y
    beq f_gp_rp
    inx
f_gp_rp
    lda f_after,x
    tax
    jmp f_gp_rom

; f_post: draw the post (f_who, f_lns, f_lp) at row f_row
f_post
    lda f_row               ; the avatar
    sta c_prow
    lda #0
    sta c_pcol
    jsr c_at
    ldx f_who
    lda f_uav,x
    ldy #0
f_po_a1
    sta (c_ptr),y
    clc
    adc #1
    iny
    cpy #4
    bne f_po_a1
    ldy #40
f_po_a2
    sta (c_ptr),y
    clc
    adc #1
    iny
    cpy #44
    bne f_po_a2
    lda f_row
    sta fs_r
    lda #0
    sta fs_c
    lda #4
    sta fs_l
    lda f_upal,x
    sta fs_p
    jsr f_addseg
    inc fs_r
    jsr f_addseg
    lda #5                  ; the name, the tag
    sta c_pcol
    ldx f_who
    lda f_unlo,x
    ldy f_unhi,x
    jsr f_print
    lda #18
    sta c_pcol
    ldx f_who
    lda f_utlo,x
    ldy f_uthi,x
    jsr f_print
    lda f_row
    sta fs_r
    lda #5
    sta fs_c
    lda #13
    sta fs_l
    ldx f_who
    lda f_upal,x
    sta fs_p
    jsr f_addseg
    lda #18
    sta fs_c
    lda #22
    sta fs_l
    lda #2
    sta fs_p
    jsr f_addseg
    lda #0                  ; the lines
    sta f_t2
f_po_l
    lda f_t2
    cmp f_lns
    beq f_po_r
    sec
    adc f_row
    sta c_prow
    sta fs_r
    lda #5
    sta c_pcol
    ldx f_t2
    lda f_lplo,x
    ldy f_lphi,x
    jsr f_print
    lda #5
    sta fs_c
    lda #32
    sta fs_l
    lda #0
    sta fs_p
    jsr f_addseg
    lda #37
    sta fs_c
    lda #3
    sta fs_l
    jsr f_addseg
    inc f_t2
    bne f_po_l
f_po_r
    lda f_row
    sta c_prow
    rts

; ---- the review builder ----------------------------------------------------
; f_rev_build: each slot's phrases for the day (and the bugs Arthur saw)
f_rev_build
    ldx #0
f_rb_s
    stx f_t                 ; the slot
    lda #0
    sta f_listn,x
    sta f_pick,x
    ldy #0
f_rb_p
    lda f_phslot,y
    cmp f_t
    bne f_rb_n
    lda f_day
    cmp f_phday,y
    bcc f_rb_n              ; (not offered yet)
    lda f_phbug,y
    beq f_rb_ok
    and seenbugs
    beq f_rb_n              ; (a bug he didn't see)
f_rb_ok
    ldx f_t
    lda f_listn,x
    cmp #16
    bcs f_rb_n
    inc f_listn,x
    sta f_t2
    txa
    asl
    asl
    asl
    asl
    clc
    adc f_t2
    tax
    tya
    sta f_list,x
f_rb_n
    iny
    cpy #F_NPHRASES
    bne f_rb_p
    ldx f_t
    inx
    cpx #3
    bne f_rb_s
    lda #0
    sta f_slot
    rts

f_rev_draw
    jsr f_start
    lda #0
    sta c_prow
    sta c_pcol
    lda #<f_revhdr
    ldy #>f_revhdr
    jsr f_print
    lda #8
    sta c_pcol
    ldx f_day
    lda f_dglo,x
    ldy f_dghi,x
    jsr f_print
    lda #1
    ldx #0
    jsr f_row2
    ldx #0
f_rd_l
    stx f_t
    txa
    asl
    adc f_t
    adc #2
    sta f_row
    sta c_prow
    lda #2
    sta c_pcol
    ldx f_t
    lda f_slotlo,x
    ldy f_slothi,x
    jsr f_print
    lda #2
    ldx f_row
    jsr f_row2
    lda #0
    ldx f_row
    inx
    jsr f_row2
    ldx f_t
    inx
    cpx #3
    bne f_rd_l
    lda #<f_hrev
    ldy #>f_hrev
    jsr f_help
    ; (then the lines)
; f_rev_text: the three lines as picked, the arrow on the slot
f_rev_text
    ldx #0
f_rt_l
    stx f_t
    txa
    asl
    adc f_t
    adc #3
    sta c_prow
    lda #0
    sta c_pcol
    jsr c_at
    ldy #39
    lda #0
f_rt_c
    sta (c_ptr),y
    dey
    bpl f_rt_c
    ldx f_t
    cpx f_slot
    bne f_rt_p
    ldy #2
    lda #(62 - 32) * 2      ; >
    sta (c_ptr),y
f_rt_p
    lda #4
    sta c_pcol
    jsr f_picked
    lda f_phlo,y
    pha
    lda f_phhi,y
    tay
    pla
    jsr f_print
    ldx f_t
    inx
    cpx #3
    bne f_rt_l
    rts

; f_picked: slot f_t's phrase in Y
f_picked
    lda f_t
    asl
    asl
    asl
    asl
    ldx f_t
    clc
    adc f_pick,x
    tax
    ldy f_list,x
    rts

; f_rev_next / f_rev_prev: the slot's next / previous phrase (round)
f_rev_next
    ldx f_slot
    inc f_pick,x
    lda f_pick,x
    cmp f_listn,x
    bcc f_rn_r
    lda #0
    sta f_pick,x
f_rn_r
    jmp f_rev_text
f_rev_prev
    ldx f_slot
    lda f_pick,x
    bne f_rp_d
    lda f_listn,x
    sta f_pick,x
f_rp_d
    dec f_pick,x
    jmp f_rev_text

; f_rev_post: the review, kept (rev_ph, rev_kind, rev_done)
f_rev_post
    lda f_day
    sta f_t2
    asl
    adc f_t2
    sta f_row               ; rev_ph + 3 x day
    ldx f_day
    lda #0
    sta rev_kind,x
    lda #1
    sta rev_done,x
    ldx #0
f_rv_l
    stx f_t
    jsr f_picked
    tya
    ldx f_row
    sta rev_ph,x
    inc f_row
    lda f_phkind,y
    beq f_rv_n
    ldx f_day
    inc rev_kind,x
f_rv_n
    ldx f_t
    inx
    cpx #3
    bne f_rv_l
    rts

; ---- for the basic -------------------------------------------------------
; f_open: f_thr = the day's thread f_sel, from its first post
f_open
    ldx f_day
    lda f_dth0,x
    clc
    adc f_sel
    sta f_thr
    lda #0
    sta f_top
    rts
; f_open_rev: the day's release thread, from its last post (then the review)
f_open_rev
    ldx f_day
    lda f_dth0,x
    sta f_thr
    tax
    lda f_tpn,x
    sec
    sbc #1
    sta f_top
    rts
; f_info: f_last = the day's last thread (0-3), f_isrel = this thread's
; the release
f_info
    ldx f_day
    lda f_dthn,x
    sec
    sbc #1
    sta f_last
    ldx f_thr
    lda f_trel,x
    sta f_isrel
    rts

; ---- the strings -------------------------------------------------------------
f_hdr      .byte "7800 HOMEBREW > NEW RELEASES",0
f_replies  .byte "REPLIES",0
f_hlist    .byte "UP/DOWN, 1: READ, 2: LOG OFF",0
f_hthr     .byte "UP/DOWN: SCROLL   2: BACK",0
f_hrel     .byte "UP/DOWN, 1: DOWNLOAD, 2: BACK",0
f_moretxt  .byte "MORE...",0
f_viewing  .byte "PIXELKID_07 IS VIEWING THIS THREAD.",0
f_revhdr   .byte "REVIEW:",0
f_hrev     .byte "STICK: PICK THE WORDS   1: POST",0
f_slot0    .byte "THE OPENER",0
f_slot1    .byte "THE BUGS",0
f_slot2    .byte "THE VERDICT",0
f_slotlo   .byte <f_slot0, <f_slot1, <f_slot2
f_slothi   .byte >f_slot0, >f_slot1, >f_slot2
