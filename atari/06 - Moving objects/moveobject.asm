	processor 6502

	processor 6502
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; include required files
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	include "vcs.h"
	include "macro.h"
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start an uninitialized segment at $80 for variable declaration
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

	seg.u VARIABLES
	org $80
P0Height	byte		; player sprite heigh
PlayerYPos	byte		; player sprite Y coordinate
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start rom at $F000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	seg code
	org $F000

RESET:
	CLEAN_START
	
	ldx #$00
	stx COLUBK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	lda #180
	sta PlayerYPos		; PlayerYPos =180
	
	lda #9
	sta P0Height		; player 0 = 9
	

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
;; Draw 192 visible scanlines (kernel)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ldx #192			; Our remaining scanline counter / beam location
	
Scanline:
	txa					; move X to A
	sec					; set carry flag
	sbc PlayerYPos		; Subtract the player Y location from 
	cmp P0Height		; Are we inside the spright height bounds
	bcc LoadBitmap		; if result of the compare is less than spright jump
	lda #0				; else set index to 0

LoadBitmap:
	tay					; transfer A to Y
	lda P0Bitmap,Y		;load bitmap slice at Y offset
	
	sta WSYNC			; Wait for next scanline
	
	sta GRP0			; Set current scanline player slice
	lda P0Color,y		; Load current player color at Y offset
	sta COLUP0			; set current player color
	
	dex					; decrement scanline counter
	bne Scanline		; restart scanline loop
	
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
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Make the player move
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	dec PlayerYPos
	lda #%00000010
	sta HMP0
	;lda PlayerYPos
	;cmp #0
	;bne NEW_FRAME
	;lda #
	jmp NEW_FRAME		; restart loop
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; -------------------------DATA------------------------------------
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

P0Bitmap:
	.byte #%00000000	; --------
	.byte #%00101000	; --#-#---
	.byte #%01110100	; -###-#--
	.byte #%11111010	; #####-#-
	.byte #%11111010	; #####-#-
	.byte #%11111010	; #####-#-
	.byte #%11111110	; #######-
	.byte #%01101100	; -##-##--
	.byte #%00110000	; --##----
	
P0Color:
	.byte #$00
	.byte #$40
	.byte #$40
	.byte #$40
	.byte #$40
	.byte #$42
	.byte #$44
	.byte #$44
	.byte #$D2

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Pack Rom (reset and interrupt vector)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	org $FFFC
	.word RESET
	.word RESET
