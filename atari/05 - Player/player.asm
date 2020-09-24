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
	
	lda #%1111			; white playfield color
	sta COLUPF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set the TIA Registers for player colors for P0 (player 1) and p1 (player 2)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	lda #$48			; player 0 color - light red
	sta COLUP0			; P0 color register
	
	lda #$C6			; Player 2 color light green
	sta COLUP1
	
	ldy #%00000010		; ctrlpf d1 set to 1 means pl is for score
	sty CTRLPF
	

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; skip 10 scanlines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VisibleScanlines:
	REPEAT 10
		sta WSYNC
	REPEND
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display 10 scanlines for the scoreboard number
;; Pull data from number bitmap
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ldy #0
LOOP_SCORE:
	lda numBitmap,Y		; get current line from number bitmap
	sta PF1				; store in playfield (draw this to screen)
	sta WSYNC			; wait for next scanline
	iny					; increment index
	cpy #10				; compare index to 10
	bne LOOP_SCORE		; loop if not 10
	
	lda #0				
	sta PF1				; clear playfield1
	
	; Draw 50 scanlines between score and players
	REPEAT 50
		sta WSYNC
	REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display 10 scanlines for player 0 graphics
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ldy #0
LOOP_PLAYER0:
	lda playerBMap,Y	; get current line from number bitmap
	sta GRP0			; store in playfield (draw this to screen)
	sta WSYNC			; wait for next scanline
	iny					; increment index
	cpy #10				; compare index to 10
	bne LOOP_PLAYER0	; loop if not 10
	
	lda #0				
	sta GRP0			; clear playfield1
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display 10 scanlines for player 1 graphics
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ldy #0
LOOP_PLAYER1:
	lda playerBMap,Y	; get current line from number bitmap
	sta GRP1			; store in playfield (draw this to screen)
	sta WSYNC			; wait for next scanline
	iny					; increment index
	cpy #10				; compare index to 10
	bne LOOP_PLAYER1	; loop if not 10
	
	lda #0				
	sta GRP1			; clear playfield1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw the remaining 102 scanlines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	REPEAT 102
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
;; -------------------------DATA------------------------------------
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	org $FFE8
playerBMap:
	.byte #%01111110	; -######-
	.byte #%11111111	; ########
	.byte #%10011001	; #--##--#
	.byte #%11111111	; ########
	.byte #%11111111	; ########
	.byte #%11111111	; ########
	.byte #%10111101	; #-####-#
	.byte #%11000011	; ##----##
	.byte #%11111111	; ########
	.byte #%01111110	; -######-

	org $FFF2
numBitmap:
	.byte #%00001110	; ----###-
	.byte #%00001110	; ----###-
	.byte #%00000010	; ------#-
	.byte #%00000010	; ------#-
	.byte #%00001110	; ----###-
	.byte #%00001110	; ----###-
	.byte #%00001000	; ----#---
	.byte #%00001000	; ----#---
	.byte #%00001110	; ----###-
	.byte #%00001110	; ----###-


	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Pack Rom (reset and interrupt vector)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	org $FFFC
	.word START
	.word START
