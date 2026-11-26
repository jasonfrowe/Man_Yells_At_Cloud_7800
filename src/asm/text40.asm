; ===========================================================================
; The 40-column text screens (the fixed bank, for any scene's bank): 320A,
; 1-byte characters, 12 rows of 40 in RAM (c_text), drawn once as display
; objects that MARIA reads live: writing a byte changes the screen. The
; font (font320: gen/font320.asm, tools/gfx.py) sits at $A000 in each bank
; that uses these (the day job's, the forum's): even codes are ASCII text
; (32 up, code = 2 x (ch - 32)), odd codes and 128 up are each scene's
; glyphs (the card's cells, the forum's avatars).
;
; From Cosmic Arc II's 40-column screens (text40.asm, sector.asm's
; sv_enter / sv_leave).
; ===========================================================================

c_text    = $2300   ; [480] 12 rows of 40 (character codes)
c_prow    = $2277   ; c_puts / c_num: where
c_pcol    = $2278
c_tmp     = $2279
c_tmp2    = $227A
c_ptr     = $F2     ; (7800basic's m and n: text scenes mustn't use them)

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

; c_draw: the display objects listed at (c_ptr): 4-byte records (row,
; first column, length (1-32), palette), ended by a row of $FF. Once a
; screen: MARIA reads c_text live. (Uses c_ptr, temp1-5.)
c_draw
    ldy #0
c_draw_l
    sty c_tmp2
    lda (c_ptr),y
    bmi c_draw_r
    sta temp5
    tax
    iny
    lda c_rowlo,x
    clc
    adc (c_ptr),y
    sta temp1
    lda c_rowhi,x
    adc #0
    sta temp2
    lda (c_ptr),y
    asl
    asl                     ; (a 320A character: 4 of the 160-pixel x)
    sta temp4
    iny
    lda #32
    sec
    sbc (c_ptr),y
    and #31
    sta temp3
    iny
    lda (c_ptr),y
    asl
    asl
    asl
    asl
    asl
    ora temp3
    sta temp3
    lda c_ptr
    pha
    lda c_ptr+1
    pha
    jsr plotcharacters
    pla
    sta c_ptr+1
    pla
    sta c_ptr
    ldy c_tmp2
    iny
    iny
    iny
    iny
    bne c_draw_l
c_draw_r
    rts

c_rowlo
    .byte <(c_text+0), <(c_text+40), <(c_text+80), <(c_text+120)
    .byte <(c_text+160), <(c_text+200), <(c_text+240), <(c_text+280)
    .byte <(c_text+320), <(c_text+360), <(c_text+400), <(c_text+440)
c_rowhi
    .byte >(c_text+0), >(c_text+40), >(c_text+80), >(c_text+120)
    .byte >(c_text+160), >(c_text+200), >(c_text+240), >(c_text+280)
    .byte >(c_text+320), >(c_text+360), >(c_text+400), >(c_text+440)
