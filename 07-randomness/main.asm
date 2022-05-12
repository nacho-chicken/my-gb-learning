/*
	Section 7
	Randomness

After trying to do some other stuff, I realized that I wasn't going to get
very far without creating a (psuedo) random number generator. There were
a lot of things that just weren't possible with a deterministic input.

I'm going to try and keep it simple here and focus entirely on the RNG
rather than some implementation of it. In this project, it will run
every frame for debugging purposes.

I decided to go for a 16-bit algo because they're everywhere by now, in every
language imaginable. Thankfully, I found an LFSR algorithm ready-to-go for
Z80 assembly, which was able to be ported 1:1 to GB thanks to the similarities.

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
	; Disable audio hardware
	xor	a
	ldh	[hSOUND_ON], a ; LDH is more efficient for I/O registers
	SETCHARMAP commode ; The character map for this font
	; Disable LCD to immediately start changing graphics
	xor	a ; Just a faster way to set A to 0
	ldh	[hLCD_CONTROL], a
	; Set normal palette
	ld	a, %11100100
	ld	[BG_PAL], a
	; Initialize RNG
	call	rand_init
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

; This is just a little for-fun function using the random number generator
; to draw noise to the tiles
RandomTiles:
	ld	hl, BG_RAM1
	ld	bc, BG_RAM2 - BG_RAM1
.loop:
	push	hl
	call	rand
	pop	hl
	ld	[hli], a
	dec	bc
	ld	a, b
	or	c
	jr	nz, .loop

; And then draw those tiles to the screen
RandomBG:
	ld	hl, SCREEN_RAM0
	push	hl
	ld	b, DISPLAY_W_TILES
	ld	c, DISPLAY_H_TILES
	xor	a
; This is far from optimized
; I didn't bother doing it because it's kind of pointless
.loop:
	add	$80
	ld	[hli], a
	sub	$80
	inc	a
	and	$7F
	dec	b
	jr	nz, .loop
	pop	hl
	ld	de, SCREEN_WIDTH
	add	hl, de
	push	hl
	ld	b, DISPLAY_W_TILES
	dec	c
	jr	nz, .loop
	pop	hl


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
	; Start the sprite in the middle of the screen
	ld	a, ((DISPLAY_HEIGHT >> 1) + SPRITE_YOFFSET) - 4
	ld	[hli], a ; Y Position
	ld	a, (DISPLAY_WIDTH >> 1) + 4
	ld	[hli], a ; X Position
	ld	a, 1
	ld	[hli], a ; Tile ID
	ld	a, %00000000
	ld	[hli], a ; Attributes
	; ^ I didn't actually add this previous line in the sprite topic lol

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

Main: ; The main gameplay code loop
	call	joypad_read
	call	MoveSprite
	call	rand
	jp	WaitForNextFrame

WaitForNextFrame:
	; Reset the VBlank flag after code is finished processing
	ld	hl, wVBlankFlag
	xor	a
	ld	[hl], a
	halt
	nop
	jp	Main

MoveSprite:
	ld	a, [wJoypadState]
	; Only need to check the D-Pad
	and	(BUTTON_LEFT | BUTTON_RIGHT | BUTTON_UP | BUTTON_DOWN)
	cp	0
	jr	nz, .isMoving
	ret
.isMoving:
	ld	hl, OAM_RAM
.up:
	bit	bBUTTON_UP, a
	jr	z, .down
	dec	[hl] ; Since Y Position is the first data in OAM, read directly
	jr	.left ; Skip down so opposite directions are mutually exclusive
.down:
	bit	bBUTTON_DOWN, a
	jr	z, .left
	inc	[hl]
.left:
	inc	l ; Change to X position data in OAM
	bit	bBUTTON_LEFT, a
	jr	z, .right
	dec	[hl]
	jr	.checkWrap
.right:
	bit	bBUTTON_RIGHT, a
	jr	z, .checkWrap
	inc	[hl]
.checkWrap:
	; X position wrapping
	ld	a, [hl]
	ld	b, 1
	ld	c, (DISPLAY_WIDTH + SPRITE_XOFFSET) - 1
	call	in_bounds
	or	a
	jr	z, .yWrap
	call	wrap_value
	ld	[hl], a
.yWrap:
	; Y position wrapping
	dec	l
	ld	a, [hl]
	ld	b, (SPRITE_YOFFSET - TILE_SIZE) + 1
	ld	c, (DISPLAY_HEIGHT + SPRITE_YOFFSET) - 1
	call	in_bounds
	or	a
	jr	z, .end
	call	wrap_value
	ld	[hl], a
.end:
	ret

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

	Parameters:
	hl	- Location in VRAM
	bc	- location of text in ROM

	Registers changed:
	a, de*
	*if effect is triggered
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

	Parameters:
	hl	- Location in RAM
	bc	- Bytes to wipe

	Registers changed:
	a
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

	Registers changed:
	a
*/
vblank_interrupt_handler:
	ld	a, 1
	ld	[wVBlankFlag], a
	; An interrupt being processed will disable interrupts in the process
	; Using RETI instead of RET re-enables them
	reti

/*	joypad_read
Processes joypad input data into a single byte, saving it into RAM afterwards.

	Registers changed:
	abc
*/
joypad_read:
	; Only the low nibble of 0xFF00 contains joypad info
	; First half of read is just the D-Pad
	; Setting the bit specified by JOYPAD_ACTION high ignores those inputs
	ld	a, JOYPAD_ACTION
	; Using LHD with C instead of an address saves 4 cycles per call
	ld	c, hJOYPAD_STATUS
	ldh	[c], a
	; All non-SP GB models use capacitive rubber pads for button inputs
	; This apparently causes some noise, which is why it's good practice to
	; delay the read so the status register can stabilize
	ldh	a, [hJOYPAD_STATUS]
	ldh	a, [hJOYPAD_STATUS]
	ldh	a, [hJOYPAD_STATUS]
	; Set up high nibble of RAM
	and	$F
	swap	a
	ld	b, a
	; Second half of read (A, B, Select, Start)
	ld	a, JOYPAD_ACTION
	ldh	[c], a
	ldh	a, [hJOYPAD_STATUS]
	ldh	a, [hJOYPAD_STATUS]
	ldh	a, [hJOYPAD_STATUS]
	and	$F
	or	b
	; By default, 0=held 1=not-held
	; Flipping all bits with CPL makes the output easier to read
	cpl
	ld	[wJoypadState], a
	ret

/*	in_bounds
Checks if the value in register A is within the bounds specified by
registers B and C.

	Parameters:
	a	- Value
	b	- Min
	c	- Max

	Return values:
	a	- Status
		0 = In bounds
		1 = Under min
		2 = Over max
*/
in_bounds:
	cp	b
	jr	c, .less
	cp	c
	jr	c, .in
	jr	z, .in
.greater:
	ld	a, 2
	ret
.less:
	ld	a, 1
	ret
.in:
	xor	a
	ret

/*	wrap_value
Wraps a value around a boundary specified by registers B and C.
Usually called immediately after "in_bounds", as the return values from that
are set as the parameters here expect.

	Parameters:
	a	- Status
		1 = Under min
		2 = Over max
	b	- Min
	c	- Max

	Return values:
	a	- Wrapped value
*/
wrap_value:
	dec	a
	jp	nz, .greater
.less:
	ld	a, c
	ret
.greater
	ld	a, b
	ret

/*	rand_init
Initializes the psuedo-RNG system.
This project uses a 16-bit LFSR (Xorshift) mechanism.

	Registers changed:
	a, hl
*/
rand_init:
	ld	hl, wRNG
	; The random seed
	; This can be any 16-bit number EXCEPT 0x0000
	ld	[hl], $FF
	inc	hl ; Can only do LD [HLI] with A register
	ld	[hl], $FF
	ret

/*	rand
Performs one step of the RNG cycle.
This should provide a period of (2^16)-1 before repeating.
This huge variance should be more than enough for most games.
Since the return value is only the high 8 bits of the output,
it's honestly pretty overkill.

	Registers changed:
	a, de, hl

	Return values:
	a	- 8-bit RNG value
*/
rand:
	; Load RNG from RAM
	ld	hl, wRNG
	ld	a, [hli]
	ld	d, a
	ld	a, [hld] ; Decrement HL here to make writing to RAM easier
	ld	e, a
	; Actual 16-bit xorshift code
	; Shamelessly lifted from John Metcalf at retroprogramming.com
	; ...not like I'm going to come up with a better implementation
	; What it's apparently doing is:
	; x = seed
	; x = x ^ x<<7
	; x = x ^ x>>9
	; x = x ^ x<<8
	; seed = x
.xorshift:
	ld	a, d
	rra
	ld	a, e
	rra
	xor	d
	ld	d, a
	ld	a, e
	rra
	ld	a, d
	rra
	xor	e
	ld	e, a
	xor	d
	ld	[hli], a
	ld	[hl], e
	ret


SECTION "Graphics Data", ROM0[$2000]

; My custom hand-drawn font.
FontMain_Data:
	INCBIN "../INCLUDES/commode32.2bpp"
FontMain_DataEnd:

CharacterSprite_Data:
	INCBIN "../INCLUDES/gfx/smile.2bpp"
CharacterSprite_DataEnd:


SECTION "WRAM", WRAM0[$C000]

wVBlankFlag: ; Bit 0 is set high when VBlank has been entered
	ds	1

; Might move the following to HRAM to help optimize reads
wJoypadState: ; The current status of the joypad input
	ds	1

; Will DEFINITELY move this to HRAM later
wRNG:
	ds	2
wRNGEnd:


; vim:ft=rgbds

