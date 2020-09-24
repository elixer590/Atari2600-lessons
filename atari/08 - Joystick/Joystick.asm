	processor 6502
	
	include "vcs.h"
	include "macro.h"
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	seg.u Variables
	org $80
P0XPos byte						;player 0 location

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Begin code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	seg Code
	org $F000

Reset:
	CLEAN_START
	
	lda #$80						; load color value for Background
	sta COLUBK
	
	lda #$D0						; load color value for playfield (ground)
	sta COLUPF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	lda #20						; load some value into P0XPos
	sta P0XPos					

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VSync 3 scanlines - 3 scanlines used
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartFrame:
	lda #2						; enable vsync and vblank
	sta VSYNC
	sta VBLANK
	
	sta WSYNC					; wait 3 scanlines for vsync
	sta WSYNC
	sta WSYNC
	
	lda #0						; disable vsync
	sta VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculate and place play horizontally - 2 scanlines used
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	lda P0XPos
	and #$7F					; load player position and remove sign value
	
	sta WSYNC					; wait for next scanlines
	sta HMCLR					; clear H-movement
	
	
	; every 5 cycles is 15 pixels, this divide loop can get us to an area that 
	; is within 15 pixes of the player location
	sec							; set carry
DivideLoop:
	sbc #15						; subtract 15 from player horizontal position
	bcs DivideLoop				; keep looping until A is less than 15
	
	eor #7						; exclusive or against %00000111 
	asl							; shift A 4 bits right
	asl
	asl
	asl		
	sta HMP0					; store bit-shifter player position data to Horizontal Motion Player 0
	sta RESP0					; strobe register - tell the TIA that the location the scanbeam is
								; at now is where the player is located
	
	sta WSYNC					; wait for next frame
	sta HMOVE					; applies fine value controls from hmp0 - strobe register
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VBlank 37 (-2=35) scanlines #35
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ldx #35						; load the count of scanlines for this section
VBLANK_LOOP:
	sta WSYNC					; wait for next scanlines
	dex
	bne VBLANK_LOOP				; loop until 0
	
	lda #0
	sta VBLANK					; turn off vblank
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; - 192 scanlines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ldx #159					; wait 160 scanlines (159 loops and a final wsync to start
SKIP_UPPER:						; next section on new scanline)
	sta WSYNC
	dex
	bne SKIP_UPPER
	sta WSYNC
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; current scanline: 160
	;; scanlines remaining: 32
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
	ldy #17						; player sprite is 17 lines long
DRAW_BITMAP:
	lda P0Bitmap,Y				; pload data from player 0 bitmap location offset by Y
	sta GRP0					; set graphics for player 0 (GRP0)
	
	lda P0Color,Y				; Load data from player 0 color table offset by Y
	sta COLUP0					; store to color luminance player 0
	
	sta WSYNC					; wait for next scanline
	
	dey
	bne DRAW_BITMAP				; decrement Y and loop is not 0
	
	lda #0
	sta GRP0					; clear the graphics for player 0
	
	lda #$FF					; set playfield values to all ones for grass
	sta PF0
	sta PF1
	sta PF2
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; current scanline: 177
	;; scanlines remaining: 15
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	ldx #14						; skip remaining 15-1 scanlines
SKIP_LOWER:
	sta WSYNC
	dex
	bne SKIP_LOWER
	sta WSYNC					; skip last scanline in graphics section
	
	lda #0						; clear playfield data
	sta PF0
	sta PF1
	sta PF2
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Overscan 30 - 30 frames
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	lda #2					; enable VBLANK
	sta VBLANK				
	
	ldx #29					; skip remaining 30-1 scanlines
LOOP_OVERSCAN:
	sta WSYNC
	dex
	bne LOOP_OVERSCAN
	sta WSYNC				; last scanline in loop
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Joystick input test for P0 up/down/left/right
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		; Joystick data is accessible in the register SWCHA (Located at $0280).
		; The field represents the data for both p0 and p1.
		; The upper bits represent player 0 and the lower bits represent player 0
		; p0   R   L   D   U
		;      0   0   0   0   ||   0   0   0   0
		; p1                        R   L   D   U

CheckP0Up:					; checking for input from joystick up
	lda #%00010000			; P0 Up
	bit SWCHA				; compare SWCHA to A
	bne CheckP0Down			; break to next section if not equal
	inc P0XPos				; move player right

CheckP0Down:
	lda #%00100000			; P0 down
	bit SWCHA				; compare SWCHA to A
	bne CheckP0Left			; break to next section if not equal
	dec P0XPos				; move player left
	
CheckP0Left:
	lda #%01000000			; P0 Left
	bit SWCHA				; compare SWCHA to A
	bne CheckP0Right		; break to next if not equal
	dec P0XPos				; move player left
	
CheckP0Right:
	lda #%10000000			; P0 right
	bit SWCHA				; compare SWCHA to A
	bne NoInput			; break to next section if not equal
	inc P0XPos				; move player right

NoInput:
	; fallback for no input performed

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Restart loop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	jmp StartFrame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Lookup table for the player graphics bitmap
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
P0Bitmap:
    byte #%00000000
    byte #%00010100
    byte #%00010100
    byte #%00010100
    byte #%00010100
    byte #%00010100
    byte #%00011100
    byte #%01011101
    byte #%01011101
    byte #%01011101
    byte #%01011101
    byte #%01111111
    byte #%00111110
    byte #%00010000
    byte #%00011100
    byte #%00011100
    byte #%00011100

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Lookup table for the player colors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
P0Color:
    byte #$00
    byte #$F6
    byte #$F2
    byte #$F2
    byte #$F2
    byte #$F2
    byte #$F2
    byte #$C2
    byte #$C2
    byte #$C2
    byte #$C2
    byte #$C2
    byte #$C2
    byte #$3E
    byte #$3E
    byte #$3E
    byte #$24

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Complete ROM size
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC
    word Reset
    word Reset

	