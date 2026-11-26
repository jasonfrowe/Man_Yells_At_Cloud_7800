; ===========================================================================
; The day job's screen (bank 4), on the 40-column text screen (text40.asm,
; in the fixed bank).
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
; ===========================================================================

c_op      = $2200   ; [20] each card column's opcode rows: 1 LOAD, 2 ADD,
                    ;   4 CNT, 8 LOOP, 16 OUT
c_val     = $2214   ; [20] ... its operand rows (7 bits, 64 at the top)
c_col     = $2269   ; the cursor's column (0-19) and card row (0-11)
c_row     = $226A   ;   (12: GO HOME, below the card)
c_curon   = $2274   ; draw the cursor (it blinks)

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

; the display objects (c_draw): row, first column, length, palette
;   palettes: 0 white, 1 card, 2 green (the printer), 3 gold
c_segs
    .byte 0,0,32,3, 0,32,8,3, 1,0,32,0, 1,32,8,0, 2,0,8,0, 2,8,32,2
    .byte 3,0,26,1, 4,0,26,1, 5,0,26,1, 6,0,26,1, 7,0,26,1, 8,0,26,1, 9,0,26,1
    .byte 4,27,13,0, 5,27,13,0, 6,27,13,0, 7,27,13,0, 8,27,13,0, 9,27,13,0
    .byte 10,0,32,0, 10,32,8,3, 11,0,32,3, 11,32,8,3, $FF
