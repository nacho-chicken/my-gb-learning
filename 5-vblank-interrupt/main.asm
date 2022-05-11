/*
	Section 5
	VBlank Interrupt and WRAM

This whole time I've been using a naive manual method of detecting vblank.
There's a much easier way, which is letting the console hardware do it for me.
When VBlank is reached, an interrupt request flag is sent to 0xFF0F.
If interrupts are enabled, I can use this to handle stuff on a per-frame basis.
Also going to be the first time messing with WRAM, since I need that area
to store the flag after VBlank has been triggered.

*/

INCLUDE "../INCLUDES/hardware-constants.inc" ; Hardware-related definitions
INCLUDE "../INCLUDES/macros.asm" ; My custom macros
INCLUDE "../INCLUDES/commode32.charmap" ; Font character map


SECTION "VBlank Interrupt", ROM0[$0040]

	jp	vblank_interrupt_handler


SECTION "Entry Point", ROM0[$0100]

	nop ; nop is needed to keep ROM the correct size
	jp	Begin


SECTION "Header", ROM0[$0104]

	HEADER "HELLOWORLD01234" ; Max 15 chars


SECTION "Main", ROM0[$0150]

Begin:
	di
	SETCHARMAP commode ; The character map for this font

Main:
	; Disable LCD to immediately start changing graphics
	xor	a ; Just a faster way to set A to 0
	ldh	[hLCD_CONTROL], a
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
	call	wipe_ram
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
	ei
	ld	a, %10000011
	ldh	[hLCD_CONTROL], a
	; Enable VBlank interrupts
	; If this bit isn't set, the CPU will hang permanently after HALTing
	ld	a, %00000001
	ldh	[hINTERRUPT_ENABLE], a
	; Reset interrupt flags to prevent immediate interrupts
	xor	a
	ldh	[hINTERRUPT_FLAG], a

WaitForNextFrame:
	; Reset the VBlank flag after code is finished processing
	ld	hl, VBlankFlag
	xor	a
	ld	[hl], a
	; This stops the CPU until an enabled interrupt is fired
	; Saves a potentially huge amount of battery life, as well as being
	; far cleaner than looping a million times waiting for VBlank
	halt
	; Due to a CPU bug, NOP is required after a HALT
	; RGBDS' compiler does this for you unless you specify the -h flag,
	; which I have done
	nop

MoveSprite:
	; Move the sprite left one pixel per frame
	ld	hl, OAM_RAM + SPRITE_XPOS
	dec	[hl]
	; Wrap the sprite's position if it has moved off-screen
	ld	a, [hl]
	or	a
	jr	z, .wrap
	jp	WaitForNextFrame
.wrap:
	ld	a, DISPLAY_WIDTH + TILE_SIZE
	ld	[hl], a
	jr	MoveSprite

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

/*	vblank_interrupt_handler
If you need help figuring out what this does, you are beyond help.
Called by the VBlank interrupt.
Data in register A will be lost.
*/
vblank_interrupt_handler:
	ld	a, 1
	ld	[VBlankFlag], a
	; An interrupt being processed will disable interrupts in the process
	; Using RETI instead of RET re-enables them
	reti


SECTION "Graphics Data", ROM0[$2000]

; My custom hand-drawn font.
FontMain_Data:
	INCBIN "../INCLUDES/commode32.2bpp"
FontMain_DataEnd:

CharacterSprite_Data:
	INCBIN "../INCLUDES/gfx/smile.2bpp"
CharacterSprite_DataEnd:


SECTION "WRAM", WRAM0[$C000]

VBlankFlag: ; Bit 0 is set high when VBlank has been entered
	ds	1


; vim:ft=rgbds

