; ===========================================================================
; Sound: music on the POKEYs, effects on the TIA.
;
; Two POKEYs (pk2 = 1):
;   voice 0  lead      POKEY 1 ($0450) channels 1+2 joined, 16 bits, 1.79 MHz
;   voice 1  bass      POKEY 1 channels 3+4 joined, 16 bits, 1.79 MHz
;   voice 2  harmony   POKEY 2 ($0440) channel 1, 8 bits, 64 kHz (f8tab)
;   voice 3  pad       POKEY 2 channel 2, 8 bits, 64 kHz
;   voice 4  drums     POKEY 2 channel 3: kick, snare, tom (drum macros)
;   voice 5  hats      POKEY 2 channel 4 (drum macros)
; One POKEY (pk2 = 0, the fallback: a 7800GD, most carts):
;   voice 0  lead      POKEY 1 channels 1+2 joined, 16 bits, 1.79 MHz
;   voice 1  bass      POKEY 1 channel 3, 8 bits, 64 kHz, an octave up
;   voice 4  drums     POKEY 1 channel 4 (the beat survives)
;   voices 2, 3, 5     not played
;   effects            TIA channels 0 and 1 (sfx_on = 0: left alone, for
;                      slop ROMs that drive the TIA themselves)
;
; mus_frame counts the frames since the song started (wrapping at 256): the
; game reads the beat from it (songs are whole bars of 128 frames).
;
; The player and its data live in the fixed bank (no switching).
;
; Music data (gen/music.asm, from tools/music.py), per voice a stream:
;   $00-$7F n d   note n (plus the voice's transpose) for d frames
;   $80 d         rest (d frames)
;   $81 i         instrument i (envelope, arpeggio)
;   $82 lo hi     jump      $83 lo hi   call (one level)   $84 return
;   $85 t         transpose $86         end of the voice
; A song: speed (frames a sixteenth), voice mask, six stream addresses.
; Runs in the NMI (snd_tick, from 7800basic's userinterrupt), in vblank.
;
; From Cosmic Arc II (src/asm/sound.asm), from Super Mega Pinball 7800.
; Zero page $B0-$B5 is in 7800basic's tracker block, unused here.
; ===========================================================================

PKA     = $0450     ; POKEY 1
PKB     = $0440     ; POKEY 2 (cart type bit 10: tools/a78header.py)

PKA_AUDF1 = PKA+0
PKA_AUDC1 = PKA+1
PKA_AUDF2 = PKA+2
PKA_AUDC2 = PKA+3
PKA_AUDF3 = PKA+4
PKA_AUDC3 = PKA+5
PKA_AUDF4 = PKA+6
PKA_AUDC4 = PKA+7
PKA_AUDCTL = PKA+8
PKA_SKCTL = PKA+15
PKB_AUDF1 = PKB+0
PKB_AUDC1 = PKB+1
PKB_AUDF2 = PKB+2
PKB_AUDC2 = PKB+3
PKB_AUDF3 = PKB+4
PKB_AUDC3 = PKB+5
PKB_AUDF4 = PKB+6
PKB_AUDC4 = PKB+7
PKB_AUDCTL = PKB+8
PKB_SKCTL = PKB+15

musp    = $B0   ; 2
musq    = $B2   ; 2
mtmp    = $B4
mtmp2   = $B5


mus_on    = $2500
mus_speed = $2501
mus_mask  = $2502
m_ptrlo   = $2504 ; [6]
m_ptrhi   = $250A
m_wait    = $2510
m_note    = $2516
m_trans   = $251C
m_envlo   = $2522
m_envhi   = $2528
m_arplo   = $252E
m_arphi   = $2534
m_arpblo  = $253A
m_arpbhi  = $2540
m_retlo   = $2546
m_rethi   = $254C
m_ins     = $2552
m_vol     = $2558
m_off     = $255E ; arpeggio offset this frame
m_done    = $2564
m_guard   = $256A
sfx_id    = $257A ; [2] per TIA channel
sfx_lo    = $257C
sfx_hi    = $257E
pk2       = $2580 ; 1: a second POKEY at $0440
mus_frame = $2581
sfx_on    = $2582

snd_init
    jsr snd_detect
    lda #1
    sta sfx_on
    lda #0
    sta mus_on
    sta sfx_id
    sta sfx_id+1
    sta AUDV0
    sta AUDV1
mus_silence
    lda #0
    sta PKA_SKCTL
    sta PKB_SKCTL
    ldx #7
mus_silence_s
    sta PKA,x
    sta PKB,x
    dex
    bpl mus_silence_s
    lda #3
    sta PKA_SKCTL
    sta PKB_SKCTL
    lda #$78                ; 1+2 and 3+4 joined, both at 1.79 MHz
    ldx pk2
    bne mus_silence_2
    lda #$50                ; one POKEY: 1+2 joined at 1.79 MHz, 3 and 4 at 64 kHz
mus_silence_2
    sta PKA_AUDCTL
    lda #$00                ; four 8-bit channels on the 64 kHz clock
    sta PKB_AUDCTL
    rts

; mus_stop: the music off, both POKEYs quiet
mus_stop
    lda #0
    sta mus_on
    jmp mus_silence

; snd_detect: is there a second POKEY at $0440, apart from the one at $0450?
; With POKEY 1 held in reset (SKCTL 0, its RANDOM frozen) and POKEY 2
; running, $044A (POKEY 2's RANDOM) changes from read to read only if a
; chip is there: open bus, or POKEY 1 mirrored at $0440, stays put.
snd_detect
    lda #0
    sta pk2
    sta PKA_SKCTL
    sta PKB_SKCTL
    lda #3
    sta PKB_SKCTL
    lda PKB+10
    ldx #16
snd_detect_l
    cmp PKB+10
    bne snd_detect_yes
    nop
    nop
    nop
    dex
    bne snd_detect_l
    beq snd_detect_out
snd_detect_yes
    lda #1
    sta pk2
snd_detect_out
    lda #3
    sta PKA_SKCTL
    rts

; mus_play: song A
mus_play
    tax
    lda #0
    sta mus_on              ; keep the NMI out
    sta mus_frame
    lda song_lo,x
    sta musp
    lda song_hi,x
    sta musp+1
    ldy #0
    lda (musp),y
    sta mus_speed
    iny
    lda (musp),y
    sta mus_mask
    ldx #0
mus_play_v
    iny
    lda (musp),y
    sta m_ptrlo,x
    iny
    lda (musp),y
    sta m_ptrhi,x
    lda #0
    sta m_wait,x
    sta m_trans,x
    sta m_vol,x
    sta m_done,x
    sta m_arphi,x
    lda #<env_off
    sta m_envlo,x
    lda #>env_off
    sta m_envhi,x
    inx
    cpx #6
    bne mus_play_v
    jsr mus_silence
    lda #1
    sta mus_on
    rts

env_off .byte 0, $FF

; ---------------------------------------------------------------------------
snd_tick
    lda sfx_on
    beq snd_tick_nosfx
    jsr sfx_tick
snd_tick_nosfx
    lda mus_on
    bne snd_tick_go
    rts
snd_tick_go
    inc mus_frame
    ldx #5
snd_tick_voice
    lda m_done,x
    beq *+5
    jmp snd_tick_next
    lda m_wait,x
    beq snd_tick_read
    dec m_wait,x
    beq *+5
    jmp snd_tick_next
snd_tick_read
    lda #16
    sta m_guard
    lda m_ptrlo,x
    sta musp
    lda m_ptrhi,x
    sta musp+1
snd_tick_cmd
    dec m_guard
    bne *+5
    jmp snd_tick_store
    ldy #0
    lda (musp),y
    bmi snd_tick_ctl
    ; a note
    clc
    adc m_trans,x
    sta m_note,x
    iny
    lda (musp),y
    jsr snd_tick_setwait
    jsr snd_tick_newnote
    lda #2
    jmp snd_tick_adv_store
snd_tick_ctl
    cmp #$80
    bne snd_tick_c1
    ; rest
    iny
    lda (musp),y
    jsr snd_tick_setwait
    lda #<env_off
    sta m_envlo,x
    lda #>env_off
    sta m_envhi,x
    lda #2
    jmp snd_tick_adv_store
snd_tick_c1
    cmp #$81
    bne snd_tick_c2
    iny
    lda (musp),y
    sta m_ins,x
    lda #2
    jsr snd_tick_adv
    jmp snd_tick_cmd
snd_tick_c2
    cmp #$82
    bne snd_tick_c3
    iny
    lda (musp),y
    pha
    iny
    lda (musp),y
    sta musp+1
    pla
    sta musp
    jmp snd_tick_cmd
snd_tick_c3
    cmp #$83
    bne snd_tick_c4
    clc
    lda musp
    adc #3
    sta m_retlo,x
    lda musp+1
    adc #0
    sta m_rethi,x
    iny
    lda (musp),y
    pha
    iny
    lda (musp),y
    sta musp+1
    pla
    sta musp
    jmp snd_tick_cmd
snd_tick_c4
    cmp #$84
    bne snd_tick_c5
    lda m_retlo,x
    sta musp
    lda m_rethi,x
    sta musp+1
    jmp snd_tick_cmd
snd_tick_c5
    cmp #$85
    bne snd_tick_c6
    iny
    lda (musp),y
    sta m_trans,x
    lda #2
    jsr snd_tick_adv
    jmp snd_tick_cmd
snd_tick_c6
    ; end
    lda #1
    sta m_done,x
    lda #0
    sta m_vol,x
    lda #<env_off
    sta m_envlo,x
    lda #>env_off
    sta m_envhi,x
    jmp snd_tick_next
snd_tick_adv_store
    jsr snd_tick_adv
snd_tick_store
    lda musp
    sta m_ptrlo,x
    lda musp+1
    sta m_ptrhi,x
snd_tick_next
    dex
    bmi snd_tick_out
    jmp snd_tick_voice
snd_tick_out
    jmp mus_output

snd_tick_adv
    clc
    adc musp
    sta musp
    bcc snd_tick_a1
    inc musp+1
snd_tick_a1
    rts

; the wait: the stream holds it in frames (tools/music.py multiplies)
snd_tick_setwait
    sta m_wait,x
    ldy #1
    rts

; start the instrument's envelope and arpeggio
snd_tick_newnote
    cpx #4                  ; voices 4 and 5: drums
    bcs snd_tick_drum
    ldy m_ins,x
    lda ins_env_lo,y
    sta m_envlo,x
    lda ins_env_hi,y
    sta m_envhi,x
    lda ins_arp_lo,y
    sta m_arplo,x
    sta m_arpblo,x
    lda ins_arp_hi,y
    sta m_arphi,x
    sta m_arpbhi,x
    ldy #1
    rts
snd_tick_drum
    ldy m_note,x
    lda drum_lo,y
    sta m_envlo,x
    lda drum_hi,y
    sta m_envhi,x
    ldy #1
    rts

; ---------------------------------------------------------------------------
mus_output
    ldx #3
mus_output_v
    lda m_done,x            ; (a finished voice: silent, nothing to do)
    bne mus_output_on
    ; volume: the envelope's next value (held at $FF)
    lda m_envlo,x
    sta musq
    lda m_envhi,x
    sta musq+1
    ldy #0
    lda (musq),y
    sta m_vol,x
    iny
    lda (musq),y
    cmp #$FF
    beq mus_output_hold
    inc m_envlo,x
    bne mus_output_hold
    inc m_envhi,x
mus_output_hold
    ; arpeggio offset
    lda #0
    sta m_off,x
    lda m_arphi,x
    beq mus_output_noarp
    sta musq+1
    lda m_arplo,x
    sta musq
    ldy #0
    lda (musq),y
    cmp #$FF
    bne mus_output_ao
    lda m_arpblo,x
    sta m_arplo,x
    sta musq
    lda m_arpbhi,x
    sta m_arphi,x
    sta musq+1
    lda (musq),y
mus_output_ao
    sta m_off,x
    inc m_arplo,x
    bne mus_output_noarp
    inc m_arphi,x
mus_output_noarp
    lda mus_mask
    and voicebit,x
    bne mus_output_on
    lda #0
    sta m_vol,x
mus_output_on
    dex
    bpl mus_output_v

    ; voice 0 -> POKEY 1 ch 1+2
    lda m_note
    clc
    adc m_off
    tay
    lda f16lo,y
    sta PKA_AUDF1
    lda f16hi,y
    sta PKA_AUDF2
    lda #0
    sta PKA_AUDC1
    lda m_vol
    ora #$A0
    sta PKA_AUDC2
    lda pk2
    bne mus_output_two
    jmp mus_output_one
mus_output_two
    ; voice 1 -> POKEY 1 ch 3+4
    lda m_note+1
    clc
    adc m_off+1
    tay
    lda f16lo,y
    sta PKA_AUDF3
    lda f16hi,y
    sta PKA_AUDF4
    lda #0
    sta PKA_AUDC3
    lda m_vol+1
    ora #$A0
    sta PKA_AUDC4
    ; voice 2 -> POKEY 2 ch 1, voice 3 -> ch 2 (8 bits, 64 kHz)
    lda m_note+2
    clc
    adc m_off+2
    tay
    lda f8tab,y
    sta PKB_AUDF1
    lda m_vol+2
    ora #$A0
    sta PKB_AUDC1
    lda m_note+3
    clc
    adc m_off+3
    tay
    lda f8tab,y
    sta PKB_AUDF2
    lda m_vol+3
    ora #$A0
    sta PKB_AUDC2
    ; voices 4 and 5: drum macros (AUDC/AUDF pairs, AUDC 0 = over) on POKEY
    ; 2 channels 3 and 4 (written out: the NMI's time is tight on a planet)
    lda mus_mask
    and #16
    beq mus_od4z
    lda m_envlo+4
    sta musq
    lda m_envhi+4
    sta musq+1
    ldy #0
    lda (musq),y
    sta PKB_AUDC3
    beq mus_od4
    iny
    lda (musq),y
    sta PKB_AUDF3
    lda musq
    clc
    adc #2
    sta m_envlo+4
    bcc mus_od4
    inc m_envhi+4
    bcs mus_od4
mus_od4z
    sta PKB_AUDC3
mus_od4
    lda mus_mask
    and #32
    beq mus_od5z
    lda m_envlo+5
    sta musq
    lda m_envhi+5
    sta musq+1
    ldy #0
    lda (musq),y
    sta PKB_AUDC4
    beq mus_od5
    iny
    lda (musq),y
    sta PKB_AUDF4
    lda musq
    clc
    adc #2
    sta m_envlo+5
    bcc mus_od5
    inc m_envhi+5
    rts
mus_od5z
    sta PKB_AUDC4
mus_od5
    rts


; one POKEY: voice 1 (bass) on channel 3, 8 bits, an octave up; voice 4
; (drums) on channel 4
mus_output_one
    lda m_note+1
    clc
    adc m_off+1
    adc #12
    tay
    lda f8tab,y
    sta PKA_AUDF3
    lda m_vol+1
    ora #$A0
    sta PKA_AUDC3
    lda mus_mask
    and #16
    beq mus_o1z
    lda m_envlo+4
    sta musq
    lda m_envhi+4
    sta musq+1
    ldy #0
    lda (musq),y
    sta PKA_AUDC4
    beq mus_o1r
    iny
    lda (musq),y
    sta PKA_AUDF4
    lda musq
    clc
    adc #2
    sta m_envlo+4
    bcc mus_o1r
    inc m_envhi+4
    rts
mus_o1z
    sta PKA_AUDC4
mus_o1r
    rts

voicebit .byte 1,2,4,8,16,32

; ---------------------------------------------------------------------------
; Effects on the TIA: sfx A. Each effect: AUDC, AUDF, AUDV a frame, AUDC $FF ends.
; Channel and priority from sfx_chan / sfx_pri.
sfx
    tay
    ldx sfx_chan,y
    lda sfx_id,x
    beq sfx_take
    tax
    lda sfx_pri,x
    ldx sfx_chan,y
    cmp sfx_pri,y
    beq sfx_take
    bcs sfx_r
sfx_take
    lda #0
    sta sfx_id,x            ; (the NMI leaves the channel alone meanwhile)
    lda sfx_dlo,y
    sta sfx_lo,x
    lda sfx_dhi,y
    sta sfx_hi,x
    tya
    sta sfx_id,x
sfx_r
    rts

sfx_tick
    ldx #1
sfx_tick_c
    lda sfx_id,x
    beq sfx_tick_off
    lda sfx_lo,x
    sta musq
    lda sfx_hi,x
    sta musq+1
    ldy #0
    lda (musq),y
    cmp #$FF
    beq sfx_tick_end
    sta AUDC0,x
    iny
    lda (musq),y
    sta AUDF0,x
    iny
    lda (musq),y
    sta AUDV0,x
    clc
    lda sfx_lo,x
    adc #3
    sta sfx_lo,x
    bcc sfx_tick_n
    inc sfx_hi,x
    jmp sfx_tick_n
sfx_tick_end
    lda #0
    sta sfx_id,x
sfx_tick_off
    lda #0
    sta AUDV0,x
sfx_tick_n
    dex
    bpl sfx_tick_c
    rts

; ---------------------------------------------------------------------------
; mu_switch: play song A, unless it's already playing
mu_song   = $24FF
mu_switch
    cmp mu_song
    beq mu_sw_r
    sta mu_song
    jmp mus_play
mu_sw_r
    rts
