/*
	Section 3
	Loading text through a function

Drawing text is easy enough, but I want to make the text drawing a bit easier
to use in other places. Now it's inside an easily-callable function.
There is also added functionality for newlines.

*/

INCLUDE "../INCLUDES/hardware.inc" ; Basic GB hardware-related variables
INCLUDE "../INCLUDES/macros.asm" ; My custom macros
INCLUDE "../INCLUDES/commode32.charmap" ; Font character map


SECTION "Entry Point", ROM0[$0100]

	nop ; nop is needed to keep ROM the correct size
	jp	Begin


SECTION "Header", ROM0[$104]

	HEADER "HELLOWORLD01234" ; Max 15 chars


SECTION "Main", ROM0[$150]

Begin:
	di
	SETCHARMAP commode ; The character map for this font

WaitForVBlank: ; Need to wait for VBlank period before messing with graphics
	ld	a, [rLY]
	cp	144
	jr	c, WaitForVBlank

Main:
	ld	a, 0
	ld	[rLCDC], a
	ld	a, %11100100 ; Set normal palette
	ld	[rBGP], a
	; Setting parameters for LoadTiles call
	ld	hl, _VRAM9000
	ld	bc, FontMain
	ld	de, FontMain_END - FontMain
	call	LoadTiles

CleanTilemap:
	ld	hl, _SCRN0 ; Screen VRAM
	ld	bc, _SCRN1 - _SCRN0 ; All tiles
.loop:
	ld	a, $00
	ld	[hli], a
	dec	bc
	ld	a, b
	or	c
	jr	nz, .loop

DrawText:
	ld	hl, _SCRN0
	ld	bc, LongString
	call	LoadText
	jp	EnableLCD

EnableLCD:
	ld	a, %10000001
	ld	[rLCDC], a

Done:
	nop
	jr	Done

LongString: ; The string to draw
	; This character map uses the "#" character for 0xFF
	db "According to all#known laws of#aviation, there is#no way a bee should#be able to fly. Its#wings are too small#to get its fat#little body off the#ground. The bee, of#course, flies anyway#because bees don't#care what humans#think is impossible.#"
	db "Yellow, black.#Yellow, black.#Yellow, black.#Yellow, black. Ooh,#black and yellow! Le@"
	; I regret absolutely nothing about this

/*	LoadTiles
This function loads tiles into VRAM.
Data in register A will be lost.

	Parameters:
	hl	- Location in VRAM
	bc	- Location of tiles in ROM
	de	- Amount of tiles to copy from ROM
*/
LoadTiles:
	ld	a, [bc]
	ld	[hli], a
	inc	bc
	dec	de
	ld	a, d
	or	e
	jr	nz, LoadTiles
	ret

/*	LoadText
This function loads an 0xFF-terminated string into VRAM.
It will also handle various text-based functions like newlines.
Data in register A will be lost.
Data in registers D and E may be lost if an effect is triggered.

	Parameters:
	hl	- Location in VRAM
	bc	- location of tiles in ROM
*/
LoadText:
	; Push starting location in case a newline is reached
	push	hl
.loop
	ld	a, [bc]
	inc	bc
; 0xFF Terminator
	; Finish if 0xFF terminator is reached
	cp	"@"
	jr	z, .end
; Newline
	cp	"#"
	jr	z, .newline
; Ready to loop again
	ld	[hli], a
	jr	.loop
.end:
	pop	hl ; No stack overflows today
	ret
.newline:
	; The tilemap is 0x20B wide
	; Adding 0x20 to the original starting position achieves the effect
	; of a newline
	pop	hl
	ld	de, $20
	add	hl, de
	push	hl
	jp	.loop


SECTION "Main Font", ROM0[$2000]

; My custom hand-drawn font.
FontMain:
	INCBIN "../INCLUDES/commode32.2bpp"
FontMain_END:


; vim:ft=rgbds

