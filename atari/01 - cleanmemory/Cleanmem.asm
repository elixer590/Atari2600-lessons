	processor 6502
	
	seg code
	org $F000			; define the code origin at $F000
	
Start:
	sei					; disable interupts
	cld					; disable BCD decimal math mode
	ldx #$FF				; load X with #FF
	txs					; transfer X to Stack register
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Clear the zero page region ($00 to $FF)
; Meaning the entire TIA Regster space
; and also RAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	lda #0 				; A = 0
	ldx #$FF			; X = #$FF
	
MemLoop:
	sta $0,X			; store A at address $0 offset by X
	dex					; decrement X (if this becomes zero, z flag will be set)
	bne	MemLoop			; if X did not become 0 (z flag not set) go back to top of loop
	sta $0,X			; obiwan error fix

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Fill rom size to 4K
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	org $FFFC
	.word Start			; Reset vector at $FFFC
	.word Start			; interupt vector at $FFFE (unused by Atari but we need to fill the rom to FFFF)