; ===========================================================================
; The story's cutscenes (bank 7): teletype text in the 40-column engine
; (text40.asm). A page: the header (row 0), the speaker's portrait and name
; (rows 2-3, the forum's avatars), up to six lines (rows 5-10) typed a
; letter at a time. The words: gen/cuttxt.asm (tools/script.py,
; storyboard/script.txt).
; ===========================================================================

cu_page   = $2280   ; the page; pages left in the cutscene
cu_left   = $2281
cu_line   = $2282   ; typing: the line, column, lines on the page
cu_col    = $2283
cu_n      = $2284
cu_plo    = $2285   ; the next letter's address
cu_phi    = $2286
cu_done   = $2287   ; 1: the page is all typed
cu_spk    = $2288
cu_rec    = $2600   ; the page's display objects (c_draw's records)

; cut_begin: cutscene A from its first page
cut_begin
    tax
    lda cut_first,x
    sta cu_page
    lda cut_count,x
    sta cu_left
    rts

; cut_next: on to the next page (A = 0 if there isn't one)
cut_next
    dec cu_left
    bne cut_next_p
    lda #0
    rts
cut_next_p
    inc cu_page
    lda #1
    rts

; cut_pageset: the page on the screen, its lines still to type, and its
; display objects in cu_rec (c_draw them after)
cut_pageset
    jsr c_cls
    ldx cu_page
    lda cut_pglo,x
    sta cu_plo
    lda cut_pghi,x
    sta cu_phi
    ldy #0
    lda cu_plo
    sta temp1
    lda cu_phi
    sta temp2
    lda (temp1),y
    sta cu_spk
    iny
    lda (temp1),y           ; the header
    bmi cut_ps_h
    tax
    lda cut_hdrlo,x
    sta temp1
    lda cut_hdrhi,x
    sta temp2
    lda #0
    sta c_prow
    sta c_pcol
    jsr c_puts
    lda cu_plo
    sta temp1
    lda cu_phi
    sta temp2
cut_ps_h
    ldy #2
    lda (temp1),y
    sta cu_n
    lda cu_plo              ; the first letter: past the 3 bytes
    clc
    adc #3
    sta cu_plo
    bcc *+5
    inc cu_phi
    lda #0
    sta cu_line
    sta cu_col
    sta cu_done
    ; the speaker: portrait (codes 128 + 8a + 4 x row + column), name
    lda cu_spk
    bmi cut_ps_r
    asl
    asl
    asl
    ora #128
    ldx #0
cut_ps_a
    sta c_text+80,x         ; row 2
    clc
    adc #4
    sta c_text+120,x        ; row 3
    sec
    sbc #3
    inx
    cpx #4
    bne cut_ps_a
    ldx cu_spk
    lda cut_namelo,x
    sta temp1
    lda cut_namehi,x
    sta temp2
    lda #2
    sta c_prow
    lda #5
    sta c_pcol
    jsr c_puts
cut_ps_r
    ; the display objects: rows 0, 5-11 in two halves (32 + 8), the
    ; speaker's rows
    ldx #0
    lda #0
    ldy #1                  ; the header: palette 1
    jsr cut_row
    lda #5
cut_ps_t
    pha
    ldy #0
    jsr cut_row
    pla
    clc
    adc #1
    cmp #12
    bcc cut_ps_t
    lda cu_spk
    bmi cut_ps_e
    tay
    lda cut_spkpal,y
    sta cu_spk+1            ; (a spare byte: the speaker's palette)
    lda #2
    ldy cu_spk+1
    jsr cut_row
    lda #3
    ldy cu_spk+1
    jsr cut_row
cut_ps_e
    lda #$FF
    sta cu_rec,x
    rts
; a row (A) as two records, palette Y, at cu_rec,x (X moves on)
cut_row
    sta cu_rec,x
    sta cu_rec+4,x
    lda #0
    sta cu_rec+1,x
    lda #32
    sta cu_rec+2,x
    sta cu_rec+5,x
    lda #8
    sta cu_rec+6,x
    tya
    sta cu_rec+3,x
    sta cu_rec+7,x
    txa
    clc
    adc #8
    tax
    rts

; cut_tick: type a letter (A = 1 when the page is done)
cut_tick
    lda cu_done
    bne cut_t_r
    lda cu_plo
    sta temp1
    lda cu_phi
    sta temp2
    ldy #0
    lda (temp1),y
    bne cut_t_l
    ; the end of a line
    inc cu_line
    lda #0
    sta cu_col
    jsr cut_t_adv
    lda cu_line
    cmp cu_n
    bcc cut_t_r0
    lda #1
    sta cu_done
    rts
cut_t_l
    sec
    sbc #32
    asl
    pha
    lda cu_line
    clc
    adc #5
    tax
    lda c_rowlo,x
    clc
    adc cu_col
    sta temp1
    lda c_rowhi,x
    adc #0
    sta temp2
    pla
    ldy #0
    sta (temp1),y
    inc cu_col
    jsr cut_t_adv
cut_t_r0
    lda #0
    rts
cut_t_r
    lda #1
    rts
cut_t_adv
    inc cu_plo
    bne *+5
    inc cu_phi
    rts

; cut_finish: type the rest of the page at once
cut_finish
    jsr cut_tick
    beq cut_finish
    rts

cut_namelo .byte <cut_n0,<cut_n1,<cut_n2,<cut_n3,<cut_n4,<cut_n5
cut_namehi .byte >cut_n0,>cut_n1,>cut_n2,>cut_n3,>cut_n4,>cut_n5
cut_n0 .byte "ARTHUR",0
cut_n1 .byte "PIXELKID_07",0
cut_n2 .byte "SOLDERSUE",0
cut_n3 .byte "HI_SCORE_HAL",0
cut_n4 .byte "DOCMARIA",0
cut_n5 .byte "THE CLOUD",0
; the speakers' palettes (cut.bas sets them: the forum's colours)
cut_spkpal .byte 3, 4, 5, 6, 7, 2
