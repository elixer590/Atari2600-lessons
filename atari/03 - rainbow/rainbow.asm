	processor 6502
	
	include "vcs.h"
	include "macro.h"
	
	seg code
	org $F000
	
START:
	CLEAN_START				; macro to clean address space
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start new frame by turning on vblank and vsync
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NextFrame:
	lda #2					; load decimal 2 into A (00000010)
	sta VBLANK				; turn on VBLANK
	sta VSYNC				; turn on vsync

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Generate 3 lines of vsync
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	sta WSYNC				; first scanline
	sta WSYNC				; Second scanline
	sta WSYNC				; third scanline
	
	lda #0
	sta VSYNC				; turn off vsync
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Let the TIA output the recommended 37 blank scanlines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ldx #37					; load decimal 37 into X
LoopVBlank:
	sta WSYNC				; hit wsync and wait for next scanline
	dex						; decrement X
	bne LoopVBlank			; loop while X not equal to 0

	lda #0
	sta VBLANK				; turn off vblank
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw 192 visible scanlines (kernel)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ldx #192				; counter for scanline count (192 lines)
LoopVisible:
	stx COLUBK				; set the BG color
	sta WSYNC				; wait for the next scanline
	dex						; decrement X
	bne LoopVisible			; loop if not all 192 lines complete

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; output 30 more VBLANK LINES (overscan) to complete our frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	lda #2					; hit and turn on vblank
	sta VBLANK
	
	ldx #30					; counter for 30 scanlines
LoopOverscan:
	sta WSYNC				; wait for the next scanline
	dex						; decrment loop counter
	bne LoopOverscan		; loop while X != 0
	
	jmp NextFrame
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Pack Rom (reset and interrupt vector)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	org $FFFC
	.word START
	.word START
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	