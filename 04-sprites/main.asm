/*
	Section 4
	Sprites

After doing some basic background layer manipulation, it's finally time
to learn about sprites. I'll just be drawing a simple sprite.
Thankfully, there is a lot of very good information about how sprites work
on the GB. They're not too complicated, so it's nice to get
a bit of a breather.

Please check out the comment at the end next to the sprite data
if you want to know more info about my process making graphics.

*/

; Making my own .inc hardware constants file because some of the ones in
; hardware.inc are really stupid and hard to remember.
INCLUDE "../INCLUDES/hardware-constants.inc"
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
	ld	a, [LCD_Y]
	cp	144
	jr	c, WaitForVBlank

Main:
	ld	a, 0
	ld	[LCD_CONTROL], a
	ld	a, %11100100 ; Set normal palette
	ld	[BG_PAL], a
	; Setting parameters for LoadTiles call
	ld	hl, BG_RAM2
	ld	bc, FontMain_Data
	ld	de, FontMain_DataEnd - FontMain_Data
	call	load_tiles

CleanVRAM:
; Screen RAM
	ld	hl, SCREEN_RAM0
	ld	bc, SCREEN_RAM1 - SCREEN_RAM0 ; All tiles
	call	wipe_ram ; This is now in a function in order to reuse easily
; OAM
	ld	hl, OAM_RAM
	ld	bc, OAM_RAM_END - OAM_RAM ; All OAM
	call	wipe_ram

SpriteInit:
	; Set the sprite palette to the default
	ld	a, %11100100
	ld	[OBJ_PAL0], a
	; I'm keeping the first tile in VRAM empty
	ld	hl, OBJ_RAM0 + TILE_DATA_SIZE
	ld	bc, CharacterSprite_Data
	ld	de, CharacterSprite_DataEnd - CharacterSprite_Data
	call	load_tiles
	; Set OAM
	ld	hl, OAM_RAM
	ld	a, 84
	ld	[hli], a ; Y Position
	ld	a, 84
	ld	[hli], a ; X Position
	ld	a, 1
	ld	[hli], a ; Tile ID
	ld	a, %00000000 ; Attributes

EnableLCD:
	; This has changed since the last project in order to enable sprites
	ld	a, %10000011
	ld	[LCD_CONTROL], a

Done:
	nop
	jr	Done

/*	load_tiles
This function loads tiles into VRAM.
Data in register A will be lost.

	Parameters:
	hl	- Location in VRAM
	bc	- Location of tiles in ROM
	de	- Amount of tiles to copy from ROM
*/
load_tiles:
	ld	a, [bc]
	ld	[hli], a
	inc	bc
	dec	de
	ld	a, d
	or	e
	jr	nz, load_tiles
	ret


/*	load_text
This function loads an 0xFF-terminated string into VRAM.
It will also handle various text-based functions like newlines.
Data in register A will be lost.
Data in registers D and E may be lost if an effect is triggered.

	Parameters:
	hl	- Location in VRAM
	bc	- location of tiles in ROM
*/
load_text:
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
	pop	hl
	ld	de, $20
	add	hl, de
	push	hl
	jp	.loop

/*	wipe_ram
This function zeroes out a section in RAM.
Data in register A will be lost.

	Parameters:
	hl	- Location in RAM
	bc	- Bytes to wipe
*/
wipe_ram:
	ld	a, $00
	ld	[hli], a
	dec	bc
	ld	a, b
	or	c
	jr	nz, wipe_ram
	ret


SECTION "Graphics Data", ROM0[$2000]

; My custom hand-drawn font.
FontMain_Data: ; Changed the name of this label for ease of understanding
	INCBIN "../INCLUDES/commode32.2bpp"
FontMain_DataEnd:

/*
I'll use this section to explain a bit about how to do the graphics!
You'll want to use a graphics editor that lets you easily create indexed PNGs.
GIMP is perfectly suitable for this, as well as being easily accessible.

Then I use rgbgfx to generate the data.
*/
CharacterSprite_Data:
	INCBIN "../INCLUDES/gfx/smile.2bpp"
CharacterSprite_DataEnd:


; vim:ft=rgbds

