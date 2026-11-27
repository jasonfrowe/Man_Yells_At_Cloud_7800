; ===========================================================================
; 0x7800_MIRROR.BIN's engine (bank 6): rooms of 20 x 11 tiles in RAM
; (m_map, row 0 the room's name), drawn once as runs of one palette that
; MARIA reads live (a door that opens is one byte); collision against the
; tiles (codes 140 up are solid); the talk box's text. Data:
; gen/mirrordat.asm (tools/mirror.py, storyboard/mirror.txt).
; ===========================================================================

m_map     = $2300   ; [240] 12 rows of 20 tile codes: on screen
m_stage   = $2600   ; [240] the same, as it's meant to be: what the walls,
                    ; the palettes and the display lists go by. A change
                    ; that needs new display lists blanks those rows of
                    ; m_map, rebuilds from m_stage, and copies m_stage to
                    ; m_map (m_commit) after the drawscreen that finishes
                    ; them: no frame of new tiles in old palettes
m_tn      = m_stage+180 ; the talk box: rows 9-11 of the room, who and two
m_t1      = m_stage+200 ; lines (what was there kept in m_save)
m_t2      = m_stage+220
m_save    = $2400   ; [60]
m_x       = $2200   ; [2] Arthur, pixelkid: x (0-152)
m_y       = $2202   ; [2] and y (the sprite's top; feet at +10 to +15)
m_dx      = $2204   ; m_move: the step (signed)
m_dy      = $2205
m_px      = $2206   ; m_solid: the pixel
m_py      = $2207
m_room    = $2209
m_npc     = $220C   ; the room's regular: 0 none, 1 sue, 2 hal, 3 maria, 4 pixelkid
m_npcx    = $220A
m_npcy    = $220B
m_page    = $220D   ; the talk: its page, pages left
m_pages   = $220E
m_droom   = $220F   ; m_door: where a TV leads (255: it doesn't)
m_dsx     = $2210
m_dsy     = $2211
m_ptr     = $F2     ; (7800basic's m, n)
m_tmp     = $2212
m_who     = $2213   ; m_move: which actor (0 Arthur, 1 pixelkid)
m_nx      = $2214   ; m_move's new x, y
m_ny      = $2215
m_dr      = $22B0   ; m_draw: the row, run start and end, index, palette
m_dk      = $22B1
m_dj      = $22B2
m_di      = $22B3
m_dp      = $22B4
m_dy2     = $22B5

M_SOLID   = 140

; ---- a room ----------------------------------------------------------------
; m_load: m_room's map (and name, row 0) into m_map, its colours
m_load
    ldx m_room
    lda m_rmaplo,x
    sta m_ptr
    lda m_rmaphi,x
    sta m_ptr+1
    ldy #219
m_load_m
    lda (m_ptr),y
    sta m_stage+20,y
    dey
    cpy #255
    bne m_load_m
    lda m_rnamelo,x
    sta m_ptr
    lda m_rnamehi,x
    sta m_ptr+1
    ldy #19
m_load_n
    lda (m_ptr),y
    sta m_map,y
    sta m_stage,y
    dey
    bpl m_load_n
    lda m_rnpc,x
    sta m_npc
    lda m_rnpcx,x
    sta m_npcx
    lda m_rnpcy,x
    sta m_npcy
    lda m_rbg,x
    sta BACKGRND
    ; the colours: 12 a room, palettes 4-7 (P4C1 $31, P5C1 $35, ...)
    lda #0
    ldy m_room
m_load_p0
    beq m_load_p1
    clc
    adc #12
    dey
    jmp m_load_p0
m_load_p1
    tax
    ldy #0
m_load_p2
    lda m_rpal,x
    sta $31,y
    inx
    iny
    tya
    and #3
    cmp #3
    bne m_load_p2
    iny                     ; (skip the gap between palettes)
    cpy #16
    bcc m_load_p2
    rts

; m_hud: row 0 (the top line): A = 0 the room's name, else prompt A
m_hud
    tax
    beq m_hud_n
    lda m_prlo-1,x
    sta m_ptr
    lda m_prhi-1,x
    sta m_ptr+1
    jmp m_hud_c
m_hud_n
    ldx m_room
    lda m_rnamelo,x
    sta m_ptr
    lda m_rnamehi,x
    sta m_ptr+1
m_hud_c
    ldy #19
m_hud_l
    lda (m_ptr),y
    sta m_map,y
    dey
    bpl m_hud_l
    rts

; m_draw: the room's display objects (after clearscreen): the name, then
; each row's tiles in runs of one palette (m_tpal: a tile's palette)
m_draw
    lda #<m_map
    sta temp1
    lda #>m_map
    sta temp2
    lda #12                 ; 20 wide, palette 0
    sta temp3
    lda #0
    sta temp4
    sta temp5
    jsr plotcharacters
    lda #1
    sta m_dr
m_draw_row
    lda #0
    sta m_dk
m_draw_run
    ; the run from column m_dk: its palette, then how far it goes
    ldx m_dr
    lda m_rowoff,x
    clc
    adc m_dk
    sta m_di
    tax
    jsr m_tilepal
    sta m_dp
    ldy m_dk
m_draw_len
    iny
    cpy #20
    beq m_draw_plot
    inx
    jsr m_tilepal
    cmp m_dp
    beq m_draw_len
m_draw_plot
    sty m_dj
    lda m_di
    clc
    adc #<m_map
    sta temp1
    lda #>m_map
    adc #0
    sta temp2
    lda m_dk
    asl
    asl
    asl
    sta temp4
    lda m_dk
    sec
    sbc m_dj                ; -(length)
    and #31
    sta temp3
    lda m_dp
    asl
    asl
    asl
    asl
    asl
    ora temp3
    sta temp3
    lda m_dr
    sta temp5
    jsr plotcharacters
    lda m_dj
    sta m_dk
    cmp #20
    bcc m_draw_run
    inc m_dr
    lda m_dr
    cmp #12
    bcc m_draw_row
    rts
; A = the palette of the tile at m_map,x (keeps X and Y): text, 0
m_tilepal
    sty m_dy2
    lda m_stage,x
    bpl m_tilepal_t
    lsr
    sec
    sbc #64
    tay
    lda m_tpal,y
    ldy m_dy2
    rts
m_tilepal_t
    lda #0
    rts

m_rowoff
    .byte 0, 20, 40, 60, 80, 100, 120, 140, 160, 180, 200, 220

; m_at: A = the tile code at pixel (m_px, m_py), X its index (off the map: solid)
m_at
    lda m_py
    cmp #192
    bcs m_at_off
    lsr
    lsr
    lsr
    lsr
    tax
    lda m_px
    cmp #160
    bcs m_at_off
    lsr
    lsr
    lsr
    clc
    adc m_rowoff,x
    tax
    lda m_stage,x
    rts
m_at_off
    ldx #0
    lda #255
    rts

; m_solid: carry set if the pixel (m_px, m_py) is solid
m_solid
    jsr m_at
    cmp #M_SOLID
    rts

; m_box: carry set if actor feet at (m_nx, m_ny) hit a wall: the feet are
; x+1 to x+6, y+10 to y+15
m_box
    lda m_nx
    cmp #153
    bcs m_box_r
    clc
    adc #1
    sta m_px
    lda m_ny
    clc
    adc #10
    sta m_py
    jsr m_solid
    bcs m_box_r
    lda m_px
    adc #5
    sta m_px
    jsr m_solid
    bcs m_box_r
    lda m_py
    adc #5
    sta m_py
    jsr m_solid
    bcs m_box_r
    lda m_px
    sec
    sbc #5
    sta m_px
    jsr m_solid
    bcs m_box_r
    clc
m_box_r
    rts

; m_move: actor m_who steps (m_dx, m_dy), each axis on its own (so it
; slides along walls). A = 1 if it moved.
m_move
    lda #0
    sta m_tmp
    ldx m_who
    lda m_dx
    beq m_move_y
    clc
    adc m_x,x
    sta m_nx
    lda m_y,x
    sta m_ny
    jsr m_box2
    bcs m_move_y
    ldx m_who
    lda m_nx
    sta m_x,x
    inc m_tmp
m_move_y
    ldx m_who
    lda m_dy
    beq m_move_r
    clc
    adc m_y,x
    sta m_ny
    lda m_x,x
    sta m_nx
    jsr m_box2
    bcs m_move_r
    ldx m_who
    lda m_ny
    sta m_y,x
    inc m_tmp
m_move_r
    lda m_tmp
    rts
; m_box2: m_box, and the room's regular (standing there) blocks too
m_box2
    jsr m_box
    bcs m_box2_r
    lda m_npc
    beq m_box2_ok
    lda m_nx
    sec
    sbc m_npcx
    bcs *+6
    eor #255
    adc #1
    cmp #7
    bcs m_box2_ok
    lda m_ny
    sec
    sbc m_npcy
    bcs *+6
    eor #255
    adc #1
    cmp #12
    bcs m_box2_ok
    sec
    rts
m_box2_ok
    clc
m_box2_r
    rts

; m_door: is the tile at (m_px, m_py) one of this room's TVs? m_droom =
; where it leads (255 not), m_dsx, m_dsy where you step out
m_door
    lda #255
    sta m_droom
    jsr m_at
    cmp #2*74
    beq m_door_l
    cmp #2*75
    bne m_door_r
    dex                     ; (the right half: its left)
m_door_l
    ; X = the index: column, row
    txa
    ldy #0
m_door_rw
    cmp #20
    bcc m_door_cl
    sbc #20
    iny
    bne m_door_rw
m_door_cl
    sta m_nx                ; column
    sty m_ny                ; row
    ldx m_room
    lda m_rdoorslo,x
    sta m_ptr
    lda m_rdoorshi,x
    sta m_ptr+1
    ldy #0
m_door_f
    lda (m_ptr),y
    bmi m_door_r
    cmp m_nx
    bne m_door_n
    iny
    lda (m_ptr),y
    dey
    cmp m_ny
    bne m_door_n
    iny
    iny
    lda (m_ptr),y
    sta m_droom
    iny
    lda (m_ptr),y
    sta m_dsx
    iny
    lda (m_ptr),y
    sta m_dsy
    rts
m_door_n
    tya
    clc
    adc #5
    tay
    bne m_door_f
m_door_r
    rts

; ---- the talk ----------------------------------------------------------------
; The talk box is the room's rows 9-11, written over with the text (then
; redrawn: mirror.bas). m_boxsave keeps the rows, m_boxback puts them back.
m_boxsave
    ldx #59
m_bs_l
    lda m_stage+180,x
    sta m_save,x
    dex
    bpl m_bs_l
    rts
m_boxback
    ldx #59
m_bb_l
    lda m_save,x
    sta m_stage+180,x
    dex
    bpl m_bb_l
    rts

; m_blankbox, m_blankall: rows 9-11, 1-11 of the screen's map to spaces
; (blank in any palette, while the display lists are rebuilt)
m_blankbox
    ldx #59
    lda #0
m_bk_b
    sta m_map+180,x
    dex
    bpl m_bk_b
    rts
m_blankall
    ldx #219
    lda #0
m_bk_a
    sta m_map+20,x
    dex
    cpx #255
    bne m_bk_a
    rts
; m_commit: m_stage's rows 1-11 to the screen; m_commitbox rows 9-11
m_commit
    ldx #219
m_cm_l
    lda m_stage+20,x
    sta m_map+20,x
    dex
    cpx #255
    bne m_cm_l
    rts
m_commitbox
    ldx #59
m_cb_l
    lda m_stage+180,x
    sta m_map+180,x
    dex
    bpl m_cb_l
    rts

; m_talk: start talk A (m_page, m_pages), its first page into the box
m_talk
    tax
    lda m_tfirst,x
    sta m_page
    lda m_tcount,x
    sta m_pages
; m_pageload: page m_page into m_tn, m_t1, m_t2
m_pageload
    ldx m_page
    lda m_pglo,x
    sta m_ptr
    lda m_pghi,x
    sta m_ptr+1
    ldy #0
    lda (m_ptr),y
    tax
    lda m_spklo,x
    sta temp1
    lda m_spkhi,x
    sta temp2
    ldy #19
m_pl_n
    lda (temp1),y
    sta m_tn,y
    dey
    bpl m_pl_n
    ldy #40
m_pl_t
    lda (m_ptr),y
    sta m_t1-1,y
    dey
    bne m_pl_t
    rts
; m_next: the next page (A = 0 when the talk's over)
m_next
    dec m_pages
    bne m_next_p
    lda #0
    rts
m_next_p
    inc m_page
    jsr m_pageload
    lda #1
    rts
