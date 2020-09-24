	processor 6502
	
	include "vcs.h"
	include "macro.h"
	
	seg code
	org $F000			; define the code origin at $F000
	
START:
	CLEAN_START			; macro to clean memory

MAIN_LOOP:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set background luminosity color to yellow
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	lda #$1e			; load color into A ($1e s NTSC yellow)
	sta COLUBK			; store a to backgroundcolor address $09 defined in vcs.h
	
	jmp MAIN_LOOP		; repeat from start
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fill rom size to 4K
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	org $FFFC			; jump to last 4 bytes of rom
	.word START			; Reset vector
	.word START			; interrupt vector
	