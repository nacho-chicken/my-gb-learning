/*
	Section 2
	Character Maps

After learning about how the screen works and printing text to it,
I decided to make a character map. That lets me print the same text
easily, with a string instead of having to manually input string bytecode.

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
	ld	bc, HelloWorld
	ld	hl, _SCRN0 + $21
.loop:
	ld	a, [bc]
	cp	$FF ; Finish if 0xFF terminator is reached
	jp	nc, EnableLCD
	inc	bc
	ld	[hli], a
	jr	.loop

EnableLCD:
	ld	a, %10000001
	ld	[rLCDC], a

Done:
	nop
	jr	Done

HelloWorld: ; "Hello World!" in an 0xFF-terminated string
	; This character map uses the "@" character for 0xFF
	; As well as "#" for a newline
	db "Hello World!@"

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


SECTION "Main Font", ROM0[$2000]

; My custom hand-drawn font.
FontMain:
	INCBIN "../INCLUDES/commode32.2bpp"
FontMain_END:


; vim:ft=rgbds

