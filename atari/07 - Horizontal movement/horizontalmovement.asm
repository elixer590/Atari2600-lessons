	processor 6502

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Include required files with register mapping
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	include "vcs.h"
	include "macro.h"
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start uninitialized segment for var declaration at $80
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	seg.u Variables
	org $80
P0XPos	.byte				; sprite x coords

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start our ROM code segment starting at $F000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	seg Code
	org $F000

RESET:
	CLEAN_START				; Macro to clean memory and tia
	
	ldx #$00				; load value for black background
	stx COLUBK
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	lda #40
	sta P0XPos				; initialize player x coordinate
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start a new frame by configuring VBLANK and VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartFrame:
	lda #2
	sta VBLANK				; turn on vblank
	sta VSYNC				; turn on vsync
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display 3 vertical lines of VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	sta WSYNC
	sta WSYNC
	sta WSYNC
	lda #0
	sta VSYNC				; turn off Vsync
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set player horizontal position while in VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	lda P0XPos				; Load play 0 x position into A
	and #%01111111			; player position will be a signed integer
							; remove the 8th bit top stay positive
	
	sta WSYNC				; wait for next scanline
	sta HMCLR				; clear horizontal movement
	
	sec						; set the carry flag before subtracting
DivideLoop
	sbc #15					; subtract 15 from A
	bcs DivideLoop			; restart loop if remainder less than 15
	
	eor #7					; exclusive or with 7
	asl						; shift bits left as hmp0 register for
	asl						; fine horizontal movement control needs
	asl						; values in the top 4 bits
	asl						;
	sta HMP0				; store fine position
	sta RESP0				; resp0 is a strobe register, we are setting 
							; our horizontal position based on the number
							; of times we could divide by 15
	
	sta WSYNC				; wait for next frame
	sta HMOVE				; applies fine value coontrols to player. Strobe.
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Let the TIA output the remaining 35 recommended lines of vblank
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ldx #35					; load scanline count
VBLANK_LOOP:
	sta WSYNC				; wait for next scanline
	dex						; X--
	bne VBLANK_LOOP			; loop back if not 0
	
	lda #0
	sta VBLANK				; turn off vblank
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw 192 scanlines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ldx #59					; wait for 60 empty scanlines
BLANK_LOOP:
	sta WSYNC				; wait for next scanline
	dex						; X--
	bne BLANK_LOOP			; loop back if not 0
	sta WSYNC				; to ensure following code starts at beginning of scanline
	
	ldy #9					; counter for sprite
DrawBitmap:
	lda P0Bitmap,Y			; Load player bitmap slice
	sta GRP0				; set P0 graphics
	
	lda P0Color,Y			; load color slice for P0
	sta COLUP0				; set graphics color
	
	sta WSYNC				; wait for next scanline
	
	dey						; Y--
	bne DrawBitmap			; repeat until there are no more rows to draw
	
	lda #0
	sta GRP0				; disable p0 bitmap graphics
	
	ldx #123				; remaining scanline count
BLANK_LOOP2:
	sta WSYNC				; wait for next scanline
	dex						; X--
	bne BLANK_LOOP2			; loop back if not 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Output 30 more VBLANK Overscan lines to complete the frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OVERSCAN:
	lda #2
	sta VBLANK				; turn vblank on
	
	ldx #29					; 29 loops plus one trailing wsync
BLANK_LOOP3:
	sta WSYNC				; wait for next scanline
	dex						; X--
	bne BLANK_LOOP3			; loop back if not 0
	sta WSYNC
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Increment X coordinate before next frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	inc P0XPos

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Ensure xpos between 40 and 80
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	lda P0XPos				; load x position
							; check if value greater than 80
	sec
	sbc #$50
	bcc ENDTEST
	lda #40
	sta P0XPos
	
;looking at 40 and 80
;40 $28 %0010 1000
;80 $50 %0101 0000
	
ENDTEST:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Loop to next frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	jmp StartFrame

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
;; wrap cart
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.org $FFFC
	.word RESET
	.word RESET




