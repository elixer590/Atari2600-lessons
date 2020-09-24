	processor 6502
	
	include "vcs.h"
	include "macro.h"
	
	seg code
	org $F000
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Clean memory to start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START:
	CLEAN_START
	
	ldx #$80
	stx COLUBK
	
	lda #$1C
	sta COLUPF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start new frame by turning on vblank and vsync
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NEW_FRAME:
	lda #%00000010		; load 2 into A. Binary format for visualization of active bits
	sta VBLANK			; store 2 into VBLANK (enable vblank)
	sta VSYNC			; Store 2 into VSYNC (enable vsync)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Generate 3 scanlines of vsync
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	REPEAT 3			; do the following 3 times
		sta WSYNC		; storing anyvalue to the WSYNC address waits for next scanline
	REPEND    			; end repeat
	
	lda #0
	sta VSYNC			; disable VSYNC
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Let the TIA output the recommended 37 blank scanlines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ldx #37				; load decimal 37 into X
LOOP_VBLANK:
	sta WSYNC			; wait for next scanline
	dex					; decrement X
	bne LOOP_VBLANK		; Loop if more lines left
	
	lda #0
	sta VBLANK
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; set the CTRLPF register to allow playfield reflection (control playfield)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ldx #%00000001		; in CTRLPF register this means reflect Play field
	stx CTRLPF
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw 192 visible scanlines (kernel)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	; skip 7 scanlines with no PF set
	ldx #0
	stx PF0
	stx PF1
	stx PF2
	REPEAT 7
		sta WSYNC
	REPEND
	
	; set the PF0 to 1110 and PF1&2 to 1111 1111 for 7 frames
	ldx #%11100000
	stx PF0
	ldX #%11111111
	stx PF1
	stx PF2
	REPEAT 7
		sta WSYNC
	REPEND
	
	; set the next 164 scanlines with only the pf0 third bit enabled
	ldx #%01100000
	stx PF0
	ldx #0
	stx PF1
	ldx #%10000000
	stx PF2
	REPEAT 164
		sta WSYNC
	REPEND
	
	; set the pf0 to 1110 and pf1&2 to 1111 1111 for next 7 frames
	ldx #%11100000
	stx PF0
	ldX #%11111111
	stx PF1
	stx PF2
	REPEAT 7
		sta WSYNC
	REPEND
	
	; skip 7 scanlines with no pf set
	ldx #0
	stx PF0
	stx PF1
	stx PF2
	REPEAT 7
		sta WSYNC
	REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; output 30 more VBLANK LINES (overscan) to complete our frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	lda #%00000010		; load binary 2
	sta VBLANK			; enable VBLANK
	
	ldx #30				; load decimal 30, overscan count
LOOP_OVERSCAN:
	sta WSYNC
	dex
	bne LOOP_OVERSCAN
	stx VBLANK			; turn off vblank
	jmp NEW_FRAME		; restart loop
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Pack Rom (reset and interrupt vector)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	org $FFFC
	.word START
	.word START
