/*
	Section 15
	Organization and Linking in RGBLink

This project is really just meant to test out how linking works with these
tools. It's not going to be anything complicated since cutting apart this
monolithic project and reassembling it in a cohesive way would be a
mammoth undertaking. Any simple functions without much in the way of
external calls are getting put in a separate object. Some sections that
are big enough are also getting shoved into another file.

The most different part of this by far compared to linking for other languages
is having to create a script specifically for the linker. Since space in ROM
is so limited, knowing exactly where things are going is key. And to do that,
you have to tell the linker where things go. I basically just listed the
different SECTIONs in order starting from "Main", and made sure to set
"Main" to start at $0150 to coincide with where it's located in the
section label.
*/

INCLUDE "../INCLUDES/hardware-constants.inc" ; Hardware-related definitions
INCLUDE "../INCLUDES/macros.asm" ; My custom macros
INCLUDE "../INCLUDES/commode32.charmap" ; Font character map
SETCHARMAP commode ; The character map for this font


SECTION "VBlank Interrupt", ROM0[$0040]

	jp	vblank_interrupt_handler


SECTION "LCD Stat Interrupt", ROM0[$0048]

	jp	lcd_stat_interrupt_handler


SECTION "Entry Point", ROM0[$0100]

	nop ; Apparently this isn't required, just used in most games
	jp	Begin


SECTION "Header", ROM0[$0104]

	; I figured out I could handle the header in RGBFIX
	; This just makes sure nothing else takes its spot in ROM
	ds	($150 - $104)


SECTION "Main", ROM0[$0150]

Begin:
	di
	; This is to detect CGB after turning off LCD
	ld	b, a
	; Disable LCD to immediately start changing graphics
	xor	a
	ldh	[hLCD_CONTROL], a
	ld	a, b
	call	DetectCGB
	; Start audio hardware
	ld	a, %10000000
	ldh	[hSOUND_ON], a
	; Initialize RNG
	call	random_init
	; Setting parameters for LoadTiles call
	ld	hl, BG_RAM2
	ld	bc, FontMain_Data
	ld	de, FontMain_DataEnd - FontMain_Data
	call	load_tiles
	jp	PaletteInit

DetectCGB:
	cp	$11
	jp	nz, .notCGB
	ld	a, 1
	ld	[wIsCGB], a
	ret
.notCGB:
	xor	a
	ld	[wIsCGB], a
	ret

PaletteInit:
	ld	a, [wIsCGB]
	or	a
	jr	z, .dmg
.cgb:
; BG palettes
	ld	hl, _cgbPaletteData.bg
	ld	a, %10000000 ; Automatically increase palette register on write
	ldh	[$68], a
	ld	b, 8 ; Bytes per palette
.bgloop:
	ld	a, [hli]
	ldh	[$69], a
	dec	b
	jr	nz, .bgloop
	ld	hl, _cgbPaletteData
; OBJ palettes
	ld	b, 5 ; Number of palettes
	ld	a, %10000000 ; Automatically increase palette register on write
	ldh	[$6A], a
.objloop:
	ld	c, 8 ; Bytes per palette
.objloop2:
	ld	a, [hli]
	ldh	[$6B], a
	dec	c
	jr	nz, .objloop2
	dec	b
	jr	nz, .objloop
	jp	CleanRAM
.dmg:
	; Set normal palette for DMG mode
	ld	a, %11100100
	ld	[BG_PAL], a
	; Set the sprite palette to the default
	ld	a, %11100100
	ld	[OBJ_PAL0], a
	; Secondary palette for some sprites to look better
	ld	a, %11100000
	ld	[OBJ_PAL1], a
	jp	CleanRAM

CleanRAM:
; Screen RAM
	ld	hl, SCREEN_RAM0
	ld	bc, SCREEN_RAM1 - SCREEN_RAM0 ; All tiles
	call	wipe_ram
; No longer need to clean the OAM because if the buffer is cleaned,
; that will happen automatically
; OAM Buffer
	ld	hl, wOAMBuffer
	ld	bc, wOAMBufferEnd - wOAMBuffer
	call	wipe_ram

SRAMInit:
	; Enable SRAM
	ld	a, $0A
	ld	[$0000], a
	; Since the game autoloads, need to check if a file already exists
	ld	hl, sFileCreated
	ld	a, [hli]
	cp	$DE
	jr	nz, .create
	ld	a, [hli]
	cp	$AD
	jr	nz, .create
	ld	a, [hli]
	cp	$BE
	jr	nz, .create
	ld	a, [hl]
	cp	$EF
	jr	nz, .create
	jr	.end
.create:
	; Creates a new save file
	; This first section is the save file header,
	; which is used to check for an existing save file
	ld	hl, sFileCreated
	ld	a, $DE
	ld	[hli], a
	ld	a, $AD
	ld	[hli], a
	ld	a, $BE
	ld	[hli], a
	ld	a, $EF
	ld	[hl], a
	; Initialize the player's position to the center of the screen
	ld	hl, sPlayerPos
	ld	a, ((DISPLAY_HEIGHT >> 1) + SPRITE_YOFFSET) - 4
	ld	[hli], a
	ld	a, (DISPLAY_WIDTH >> 1) + 4
	ld	[hl], a
	jr	.end
.end:
	; Disable SRAM after done
	xor	a
	ld	[$0000], a

LoadDMARoutineToHRAM:
	ld	de, _DMARoutineCode
	ld	hl, DMATransfer_HRAM
	ld	b, DMATransfer_HRAMEnd - DMATransfer_HRAM
.loop:
	ld	a, [de]
	inc	de
	ld	[hli], a
	dec	b
	jr	nz, .loop
	jr	LoadSpriteTiles

; This routine taken directly from the Pan Docs
_DMARoutineCode:
LOAD "HRAM DMA Routine", HRAM[$FF80]
DMATransfer_HRAM:
	ldh	[c], a ; 1 byte
.wait:
	dec	b ; 1 byte
	jr	nz, .wait ; 2 bytes
	ret ; 1 byte
DMATransfer_HRAMEnd:
ENDL

LoadSpriteTiles:
	; I'm keeping the first tile in VRAM empty
	ld	hl, OBJ_RAM0 + TILE_DATA_SIZE
	; 1-tile Character sprites
	ld	bc, CharacterSprite_Data
	ld	de, CharacterSprite_DataEnd - CharacterSprite_Data
	call	load_tiles
	; 2x2 Animated Egg tiles
	; There are 3 tiles per frame because one tile is mirrored
	ld	bc, AnimatedSprite_Data
	ld	de, AnimatedSprite_DataEnd - AnimatedSprite_Data
	call	load_tiles

BGBankText:
	; Writing anywhere from $2000 to $2FFF swaps the active bank
	; I shouldn't have to do this initial swap to bank 1,
	; but it doesn't hurt to be safe
	; Remember that setting the swappable bank register to $00
	; does different things depending on your selected mapper
	ld	a, 1
	ld	[$2000], a
	ld	hl, SCREEN_RAM0
	ld	bc, BankWord0
	call	load_text
	; Swap to bank 2
	ld	a, 2
	ld	[$2000], a
	ld	hl, SCREEN_RAM0 + $20
	ld	bc, BankWord1
	call	load_text
	; Swap to bank 3
	ld	a, 3
	ld	[$2000], a
	ld	hl, SCREEN_RAM0 + $40
	ld	bc, BankWord2
	call	load_text
	; Return to bank 1
	ld	a, 1
	ld	[$2000], a

PlayerInit:
	; Set OAM
	ld	hl, wOAMBuffer
	; Load starting position from SRAM
	ld	a, $0A
	ld	[$0000], a
	ld	bc, sPlayerPos
	; Start the sprite in the middle of the screen
	ld	a, [bc]
	ld	[hli], a ; Y Position
	inc	bc
	ld	a, [bc]
	ld	[hli], a ; X Position
	ld	a, 1
	ld	[hli], a ; Tile ID
	ld	a, %00000000
	ld	[hli], a ; Attributes
	xor	a
	ld	[$0000], a

EggInit:
	ld	de, wEgg ; Animation frame data in RAM
	; Egg 1
	; Y
	ld	b, SPRITE_YOFFSET
	; X
	ld	c, 134 + SPRITE_XOFFSET
	call	EggInit_single
	; Egg 2
	ld	b, 19 + SPRITE_YOFFSET
	ld	c, 17 + SPRITE_XOFFSET
	call	EggInit_single
	; Egg 3
	ld	b, 20 + SPRITE_YOFFSET
	ld	c, 70 + SPRITE_XOFFSET
	call	EggInit_single
	; Egg 4
	ld	b, 53 + SPRITE_YOFFSET
	ld	c, 121 + SPRITE_XOFFSET
	call	EggInit_single
	; Egg 5
	ld	b, 59 + SPRITE_YOFFSET
	ld	c, 36 + SPRITE_XOFFSET
	call	EggInit_single
	; Egg 6
	ld	b, 96 + SPRITE_YOFFSET
	ld	c, 59 + SPRITE_XOFFSET
	call	EggInit_single
	; Egg 7
	ld	b, 98 + SPRITE_YOFFSET
	ld	c, 140 + SPRITE_XOFFSET
	call	EggInit_single
	; Egg 8
	ld	b, 113 + SPRITE_YOFFSET
	ld	c, 7 + SPRITE_XOFFSET
	call	EggInit_single
	; Egg 9
	ld	b, 124 + SPRITE_YOFFSET
	ld	c, 100 + SPRITE_XOFFSET
	call	EggInit_single
	call	UpdateEggs
	jp	EnableLCD

EggInit_single:
	; Randomize starting animation frame and palette
	push	de
	push	hl
	call	random
	pop	hl
	pop	de
	ld	[de], a
	inc	de
	push	de
	; Shift right 6 times to turn top 2 MSB into bottom 2 LSB
	swap	a
	rrca
	rrca
	and	%00000011
	ld	d, a
	; Egg animates in a 64-frame period
	; Every 32nd frame changes the sprites
	; Top-left sprite
	; Y
	ld	a, b
	ld	[hli], a
	; X
	ld	a, c
	ld	[hli], a
	; Tile
	inc	l ; Skip for now, it gets randomized later
	; Attributes
	; Register D now holds CGB palette data
	ld	a, %00010000
	or	d
	inc	a ; Stupid hack to skip the player palette
	ld	[hli], a
	; Top-right sprite
	ld	a, b
	ld	[hli], a ; Y
	ld	a, c
	add	TILE_SIZE
	ld	[hli], a ; X
	inc	l ; Tile
	ld	a, %00110000 ; X is flipped
	or	d
	inc	a
	ld	[hli], a ; Attributes
	; Bottom-left sprite
	ld	a, b
	add	TILE_SIZE
	ld	[hli], a ; Y
	ld	a, c
	ld	[hli], a ; X
	inc	l ; Tile
	ld	a, %00010000
	or	d
	inc	a
	ld	[hli], a ; Attributes
	; Bottom-right sprite
	ld	a, b
	add	TILE_SIZE
	ld	[hli], a ; Y
	ld	a, c
	add	TILE_SIZE
	ld	[hli], a ; X
	inc	l ; Tile
	ld	a, %00010000
	or	d
	inc	a
	ld	[hli], a ; Attributes
	pop	de
	ret

UpdateEggs:
	; Set the initial frame of animation
	ld	de, wEgg
	ld	hl, wOAMBuffer + SPRITE_DATA_SIZE ; Skip player sprite
	; Select the tile ID from OAM
	inc	l
	inc	l
	; How many objects to init
	ld	b, 9
.loop:
	ld	a, [de]
	ld	c, 0 ; Tile offset for second frame of animation
	bit	4, a
	jr	nz, .frameInit
	; Start from the second frame
	ld	c, 3
.frameInit:
	; Top-left
	ld	a, 3
	add	c ; Sets frame depending on animation cycle
	ld	[hl], a
	ld	a, SPRITE_DATA_SIZE
	add	l
	ld	l, a
	; Top-right
	ld	a, 3
	add	c
	ld	[hl], a
	ld	a, SPRITE_DATA_SIZE
	add	l
	ld	l, a
	; Bottom-left
	ld	a, 4
	add	c
	ld	[hl], a
	ld	a, SPRITE_DATA_SIZE
	add	l
	ld	l, a
	; Bottom-right
	ld	a, 5
	add	c
	ld	[hl], a
	ld	a, SPRITE_DATA_SIZE
	add	l
	ld	l, a
	inc	e
	dec	b
	jr	nz, .loop
	ret

EnableLCD:
	; Initialize OAM before enabling LCD
	call	DMATransfer
	ei
	ld	a, %10000011
	ldh	[hLCD_CONTROL], a
	; Reset interrupt flags to prevent immediate interrupts
	xor	a
	ldh	[hINTERRUPT_FLAG], a
	; Enable VBlank and LCD Stat interrupts
	; If this flag isn't set, the CPU will hang permanently after HALTing
	ld	a, %00000011
	ldh	[hINTERRUPT_ENABLE], a
	; Set LCD Stat interrupt to trigger at the end of VBlank
	xor	a
	ldh	[hLCD_Y_COMPARE], a
	ld	a, %01000000
	ldh	[hLCD_STAT], a
	jp	WaitForNextFrame ; To make sure Main starts at next VBlank

Main: ; The main gameplay code loop
	call	joypad_read
	call	PlayerMove
	call	SaveGame
	call	PlaySFX
	call	AnimateEggs
	call	UpdateEggs
	jp	WaitForVBlank

Draw: ; The code run after VBlank starts
	call	DMATransfer
	jp	WaitForNextFrame

SaveGame:
	ld	a, [wJoypadStatePrevious]
	ld	b, a
	ld	a, [wJoypadState]
	cpl
	or	b
	bit	bBUTTON_START, a
	jr	nz, .end
	; Enable SRAM
	; GB uses a janky method of enabling/disabling this
	; You write to a section of ROM
	; Writing $0A anywhere from $0000 to $1FFF will enable SRAM
	; Writing $00 to the same location will disable SRAM
	; Make sure to disable SRAM when not in use to prevent memory errors
	ld	a, $0A
	ld	[$0000], a
	; Write player data to SRAM
	ld	hl, wOAMBuffer ; Player is first in OAM
	ld	bc, sPlayerPos
	ld	a, [hli]
	ld	[bc], a
	inc	bc
	ld	a, [hl]
	ld	[bc], a
	xor	a
	; Disable SRAM
	ld	[$0000], a
.end:
	ret

PlaySFX:
	ld	a, [wJoypadStatePrevious]
	ld	b, a
	ld	a, [wJoypadState]
	; The following two instructions check if button is
	; pressed, but not held
	cpl
	or	b
	bit	bBUTTON_A, a
	jp	nz, .end
	; NR10
	; This controls the sweep register; FOR PULSE CH 1 ONLY
	xor	a
	ldh	[$10], a
	; NR11
	; This controls the sound length and the wave duty cycle
	; NOTE: Longer length value = shorter sound
	ld	a, %10110000
	ldh	[$11], a
	; NR12
	; This controls starting volume and the volume envelope
	ld	a, %01110000
	ldh	[$12], a
	; NR13/14
	; Internal frequency is stored as an 11-bit value (0-2047)
	; Note frequency is 131072/(2048-[internal frequency])
	; This note is %11100000110 (1798), which should come out to
	; 524.288Hz, or roughly a C5 note (523.25Hz)
	ld	a, %00000110
	ldh	[$13], a
	ld	a, %11000111
	ldh	[$14], a
.end:
	ret

AnimateEggs:
	ld	hl, wEgg
	ld	b, 9 ; How many eggs
.loop:
	ld	a, [hl]
	and	%11000000 ; Keep CGB Palette data
	ld	c, a
	ld	a, [hl]
	inc	a
	and	$1F ; Only the first 5 bits are relevant for animation
	or	c
	ld	[hli], a
	dec	b
	jr	nz, .loop
	ret

DMATransfer:
	ld	a, HIGH(wOAMBuffer)
	; The following line is the only thing changed from the Pan Docs
	; Setting B to $28 caused the program to return before the transfer
	; completed; setting to $29 waits four more cycles to make sure the
	; GB is done transferring data to the OAM
	ld	bc, $2946
	jp	DMATransfer_HRAM

WaitForNextFrame:
	halt
	nop
	jp	Main

WaitForVBlank:
	halt
	nop
	jp	Draw

PlayerMove:
	ld	a, [wJoypadState]
	; Only need to check the D-Pad
	and	(BUTTON_LEFT | BUTTON_RIGHT | BUTTON_UP | BUTTON_DOWN)
	or	a
	jr	nz, .isMoving
	ret
.isMoving:
	ld	hl, wOAMBuffer
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

/*	vblank_interrupt_handler
If you need help figuring out what this does, you are beyond help.
Called by the VBlank interrupt.

	Registers changed:
	a
*/
vblank_interrupt_handler:
	; Enable LCD Stat interrupt, disable VBlank interrupt
	ld	a, %00000010
	ldh	[hINTERRUPT_ENABLE], a
	; An interrupt being processed will disable interrupts in the process
	; Using RETI instead of RET re-enables them
	reti

/*	lcd_stat_interrupt_handler
For right now, only handles the LCD Y = LCD STAT interrupt

	Registers changed:
	a
*/
lcd_stat_interrupt_handler:
	; Enable VBlank interrupt, disable LCD Stat
	ld	a, %00000001
	ldh	[hINTERRUPT_ENABLE], a
	reti


SECTION "Graphics Data", ROM0[$2000]

_cgbPaletteData:
	; player
	dw	$7FFF, $3636, $0066, $0044
	; egg0
	dw	$7FFF, $4916, $7FFF, $0000
	; egg1
	dw	$7FFF, $7C00, $7FFF, $0000
	; egg2
	dw	$7FFF, $03FF, $7FFF, $0000
	; egg3
	dw	$7FFF, $001F, $7FFF, $0000
.bg:
	; bg0
	dw	$01A0, $7FFF, $7FFF, $0000

; My custom hand-drawn font.
FontMain_Data:
	INCBIN "../INCLUDES/commode32.2bpp"
FontMain_DataEnd:

CharacterSprite_Data:
	INCBIN "smile.2bpp"
CharacterSprite_DataEnd:

AnimatedSprite_Data:
	INCBIN "egg.2bpp"
AnimatedSprite_DataEnd:


SECTION "Bank 0", ROMX[$4000], BANK[1]

BankWord0:
	db	"I like@"
BankWord0End:


SECTION "Bank 1", ROMX[$4000], BANK[2]

BankWord1:
	db	"to@"
BankWord1End:


SECTION "Bank 2", ROMX[$4000], BANK[3]

BankWord2:
	db	"bank!@"
BankWord2End:


SECTION "SRAM", SRAM[$A000]

sFileCreated:
	; These 4 bytes are checked to make sure there is a legitimate save
	; before automatically loading
	; Set to $DEADBEEF if a save is created
	; Otherwise it's apparently random
	ds	4

sPlayerPos:
	ds	2

; vim:ft=rgbds

