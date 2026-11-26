; ===========================================================================
; The day job's screen (bank 4): 320A, 1-byte characters, 40 columns, 12
; rows of text in RAM (c_text), drawn once as display objects that MARIA
; reads live: writing a byte changes the screen. The font (font320, gen/
; font320.asm, tools/gfx.py) is at $A000 in this bank.
;
;   row 0       the header                      gold
;   row 1       the target                      white
;   row 2       OUTPUT: and the printer strip   white, then green
;   rows 3-9    the card (columns 0-25)         cream
;               the column's decode (27-39)     white
;   row 10      the help line, GO HOME (32-39)  white, gold
;   row 11      messages                        gold
;
; The card: rows 3 (the ruler) and 4-9 (six text rows, two card rows
; each: tools/gfx.py's cell glyphs). Columns 0-3 the row labels, 4 plain
; card, 5-24 the card's 20 columns, 25 plain card.
;
; From Cosmic Arc II's 40-column screens (text40.asm, sector.asm's
; sv_enter / sv_leave).
; ===========================================================================

c_text    = $2300   ; [480] 12 rows of 40 (character codes)
c_op      = $2200   ; [20] each card column's opcode rows: 1 LOAD, 2 ADD,
                    ;   4 SHIFT, 8 JMP, 16 OUT
c_val     = $2214   ; [20] ... its operand rows (7 bits, 64 at the top)
c_col     = $2269   ; the cursor's column (0-19) and card row (0-11)
c_row     = $226A   ;   (12: GO HOME, below the card)
c_curon   = $2274   ; draw the cursor (it blinks)
c_prow    = $2277   ; c_puts / c_num: where
c_pcol    = $2278
c_tmp     = $2279
c_tmp2    = $227A
c_ptr     = $F2     ; (7800basic's m and n: not used by the day job)

; ---- the screen mode -------------------------------------------------------
c_enter
    lda #%01000011          ; 320A, 1-byte characters (DMA on)
    sta sCTRL
    lda #>font320
    sta sCHARBASE
    rts
c_leave
    lda #%01010000          ; the game's: 160A, 2-byte characters
    sta sCTRL
    lda #>font
    sta sCHARBASE
    rts

; ---- the text --------------------------------------------------------------
; c_cls: all spaces
c_cls
    lda #<c_text
    sta c_ptr
    lda #>c_text
    sta c_ptr+1
    ldx #2                  ; 480 = 2 x 240
c_cls_p
    lda #0
    ldy #239
c_cls_l
    sta (c_ptr),y
    dey
    cpy #255
    bne c_cls_l
    lda c_ptr
    clc
    adc #240
    sta c_ptr
    bcc *+4
    inc c_ptr+1
    dex
    bne c_cls_p
    rts

; c_at: c_ptr = row c_prow, column c_pcol
c_at
    ldx c_prow
    lda c_rowlo,x
    clc
    adc c_pcol
    sta c_ptr
    lda c_rowhi,x
    adc #0
    sta c_ptr+1
    rts

; c_puts: the zero-ended ASCII string at (temp1, temp2) to c_prow, c_pcol
; (the font's text is ASCII from 32, a glyph at every other code)
c_puts
    jsr c_at
    ldy #0
c_puts_l
    lda (temp1),y
    beq c_puts_r
    sec
    sbc #32
    asl
    sta (c_ptr),y
    iny
    bne c_puts_l
c_puts_r
    rts

; c_num: A as 3 digits (leading zeros as spaces) at c_prow, c_pcol
c_num
    sta c_tmp
    jsr c_at
    lda #0
    sta temp6               ; a digit's been written
    ldx #0
    lda c_tmp
c_num_h
    cmp #100
    bcc c_num_h2
    sbc #100
    inx
    bne c_num_h
c_num_h2
    sta c_tmp
    ldy #0
    txa
    jsr c_lead
    ldx #0
    lda c_tmp
c_num_t
    cmp #10
    bcc c_num_t2
    sbc #10
    inx
    bne c_num_t
c_num_t2
    sta c_tmp
    iny
    txa
    jsr c_lead
    iny
    lda c_tmp
    jmp c_digit
; digit A at (c_ptr),y, or a space while it's a leading zero
c_lead
    bne c_lead_d
    ldx temp6
    bne c_digit
    sta (c_ptr),y           ; (A = 0: a space)
    rts
c_lead_d
    ldx #1
    stx temp6
c_digit                     ; digit A at (c_ptr),y
    clc
    adc #16
    asl
    sta (c_ptr),y
    rts

; c_draw: the rows' display objects (once a screen: MARIA reads c_text live)
c_draw
    ldx #0
c_draw_l
    stx c_tmp2
    lda c_seg_row,x
    bmi c_draw_r
    sta temp5
    tay
    lda c_rowlo,y
    clc
    adc c_seg_col,x
    sta temp1
    lda c_rowhi,y
    adc #0
    sta temp2
    lda #32
    sec
    sbc c_seg_len,x
    and #31
    sta temp3
    lda c_seg_pal,x
    asl
    asl
    asl
    asl
    asl
    ora temp3
    sta temp3
    lda c_seg_col,x
    asl
    asl                     ; (a 320A character: 4 of the 160-pixel x)
    sta temp4
    jsr plotcharacters
    ldx c_tmp2
    inx
    bne c_draw_l
c_draw_r
    rts

; ---- the card --------------------------------------------------------------
; c_frame: the card's fixed parts: the labels, the plain edges, the ruler
c_frame
    ldx #0                  ; rows 4-9: labels (columns 0-3), plain (4, 25)
c_fr_r
    stx c_tmp
    txa
    clc
    adc #4
    tay
    lda c_rowlo,y
    sta c_ptr
    lda c_rowhi,y
    sta c_ptr+1
    txa
    asl
    asl
    clc
    adc #12                 ; label glyph 12 + 4r + k: code 2i + 1
    asl
    ora #1
    ldy #0
c_fr_k
    sta (c_ptr),y
    clc
    adc #2
    iny
    cpy #4
    bne c_fr_k
    lda #93                 ; plain card (glyph 46)
    sta (c_ptr),y
    ldy #25
    sta (c_ptr),y
    ldx c_tmp
    inx
    cpx #6
    bne c_fr_r
    lda c_rowlo+3           ; row 3: plain, then the ruler 1-9, 0, 1-9, 0
    sta c_ptr
    lda c_rowhi+3
    sta c_ptr+1
    ldy #0
    lda #93
c_fr_p
    sta (c_ptr),y
    iny
    cpy #26
    bne c_fr_p
    rts

; c_card: the 20 columns' cells, and the ruler (the cursor's column's
; digit stands out: drawn in plain text, light on dark)
c_card
    ldx #0
c_cd_c
    stx c_tmp               ; the column
    ; the ruler: digit (column + 1) mod 10
    lda c_rowlo+3
    sta c_ptr
    lda c_rowhi+3
    sta c_ptr+1
    lda c_ruler,x
    cpx c_col
    bne c_cd_rul
    asl                     ; the cursor's: the text digit
    clc
    adc #32
    jmp c_cd_rs
c_cd_rul
    clc
    adc #36                 ; ink digit glyph 36 + d
    asl
    ora #1
c_cd_rs
    pha
    txa
    clc
    adc #5
    tay
    pla
    sta (c_ptr),y
    ; the six cells
    lda #0
    sta c_tmp2              ; the text row (0-5)
c_cd_r
    lda c_tmp2
    asl
    tay                     ; the top card row (2r)
    ldx c_tmp
    lda #0
    sta temp6
    lda c_op,x
    and c_mop,y
    bne c_cd_t1
    lda c_val,x
    and c_mval,y
    beq c_cd_t0
c_cd_t1
    inc temp6               ; top punched: 1
c_cd_t0
    iny                     ; the bottom card row (2r + 1)
    lda c_op,x
    and c_mop,y
    bne c_cd_b1
    lda c_val,x
    and c_mval,y
    beq c_cd_b0
c_cd_b1
    lda temp6
    ora #2                  ; bottom punched: 2
    sta temp6
c_cd_b0
    ; the cursor: in this column, on one of these rows, and blinking on
    lda c_curon
    beq c_cd_g
    cpx c_col
    bne c_cd_g
    lda c_row
    lsr
    cmp c_tmp2
    bne c_cd_g
    lda c_row
    and #1
    beq c_cd_ct
    lda temp6
    ora #8                  ; on the bottom: + 4 x 2
    bne c_cd_cs
c_cd_ct
    lda temp6
    ora #4                  ; on the top: + 4 x 1
c_cd_cs
    sta temp6
c_cd_g
    lda c_tmp2
    clc
    adc #4
    tay
    lda c_rowlo,y
    sta c_ptr
    lda c_rowhi,y
    sta c_ptr+1
    lda c_tmp
    clc
    adc #5
    tay
    lda temp6
    asl
    ora #1
    sta (c_ptr),y
    inc c_tmp2
    lda c_tmp2
    cmp #6
    beq c_cd_next
    jmp c_cd_r
c_cd_next
    ldx c_tmp
    inx
    cpx #20
    beq c_cd_x
    jmp c_cd_c
c_cd_x
    rts

; the card rows' masks: rows 0-4 opcodes, 5-11 the operand's bits
c_mop   .byte 1, 2, 4, 8, 16, 0, 0, 0, 0, 0, 0, 0
c_mval  .byte 0, 0, 0, 0, 0, 64, 32, 16, 8, 4, 2, 1
c_ruler .byte 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0

c_rowlo
    .byte <(c_text+0), <(c_text+40), <(c_text+80), <(c_text+120)
    .byte <(c_text+160), <(c_text+200), <(c_text+240), <(c_text+280)
    .byte <(c_text+320), <(c_text+360), <(c_text+400), <(c_text+440)
c_rowhi
    .byte >(c_text+0), >(c_text+40), >(c_text+80), >(c_text+120)
    .byte >(c_text+160), >(c_text+200), >(c_text+240), >(c_text+280)
    .byte >(c_text+320), >(c_text+360), >(c_text+400), >(c_text+440)

; the display objects: row, first column, length (at most 32), palette
;   palettes: 0 white, 1 card, 2 green (the printer), 3 gold
c_seg_row .byte 0, 0, 1, 1, 2, 2, 3, 4, 5, 6, 7, 8, 9, 4, 5, 6, 7, 8, 9, 10, 10, 11, 11, $FF
c_seg_col .byte 0, 32, 0, 32, 0, 8, 0, 0, 0, 0, 0, 0, 0, 27, 27, 27, 27, 27, 27, 0, 32, 0, 32
c_seg_len .byte 32, 8, 32, 8, 8, 32, 26, 26, 26, 26, 26, 26, 26, 13, 13, 13, 13, 13, 13, 32, 8, 32, 8
c_seg_pal .byte 3, 3, 0, 0, 0, 2, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 3, 3, 3
