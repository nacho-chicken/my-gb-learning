; At some point I figured out I should probably comment some of these.

DEF DISPLAY_WIDTH	EQU 160
DEF DISPLAY_HEIGHT	EQU 144

; Tile data constants
DEF OBJ_RAM0		EQU $8000
; I'm not 100% happy with the name "OBJ_RAM". A bit too close to OAM_RAM for
; my liking
DEF OBJ_RAM1		EQU $8800
; These are duplicate addresses, yes.
; The intention is to clarify, so even though BG_RAM0 is the same VRAM as
; OBJ_RAM0, it helps to know exactly what I'm doing.
DEF BG_RAM0		EQU $8000
DEF BG_RAM1		EQU $8800
DEF BG_RAM2		EQU $9000
; The screen buffer
DEF SCREEN_RAM0 	EQU $9800
DEF SCREEN_RAM1		EQU $9C00
; The size of graphics data for one tile, in bytes
DEF TILE_DATA_SIZE	EQU $10
; The dimensions of one tile, in pixels (square, w=h)
DEF TILE_SIZE		EQU 8

; Sprite constants
DEF OAM_RAM		EQU $FE00
; Each sprite is 4 bytes of data
DEF SPRITE_YPOS		EQU 0
DEF SPRITE_XPOS		EQU 1
DEF SPRITE_TILE		EQU 2
DEF SPRITE_FLAGS	EQU 3
; This is useful for iterating on OAM data, e.g. initialization
DEF SPRITE_DATA_SIZE	EQU $04
; Sprites are offset a few tiles, so this helps align them later
DEF SPRITE_YOFFSET	EQU 16
DEF SPRITE_XOFFSET	EQU 8
DEF OAM_RAM_END		EQU $FEA0

; Joypad constants
; For help reading one or the other
DEF JOYPAD_ACTION	EQU %00100000
DEF JOYPAD_DIRECTION	EQU %00010000
; These definitions are specifically for my implementation of input handling
DEF BUTTON_A		EQU %00000001
DEF BUTTON_B		EQU %00000010
DEF BUTTON_SELECT	EQU %00000100
DEF BUTTON_START	EQU %00001000
DEF BUTTON_RIGHT	EQU %00010000
DEF BUTTON_LEFT		EQU %00100000
DEF BUTTON_UP		EQU %01000000
DEF BUTTON_DOWN		EQU %10000000
; Alternate definitions for the BIT operations
DEF bBUTTON_A		EQU 0
DEF bBUTTON_B		EQU 1
DEF bBUTTON_SELECT	EQU 2
DEF bBUTTON_START	EQU 3
DEF bBUTTON_RIGHT       EQU 4
DEF bBUTTON_LEFT	EQU 5
DEF bBUTTON_UP		EQU 6
DEF bBUTTON_DOWN	EQU 7

; I/O registers
DEF JOYPAD_STATUS	EQU $FF00
DEF INTERRUPT_FLAG	EQU $FF0F
DEF SOUND_ON		EQU $FF26
DEF LCD_CONTROL		EQU $FF40
DEF LCD_Y		EQU $FF44
DEF BG_PAL		EQU $FF47
DEF OBJ_PAL0		EQU $FF48
DEF OBJ_PAL1		EQU $FF49
DEF INTERRUPT_ENABLE	EQU $FFFF
; Alternate I/O register definitions for access with LDH
DEF hJOYPAD_STATUS	EQU $00
DEF hINTERRUPT_FLAG	EQU $0F
DEF hSOUND_ON		EQU $26
DEF hLCD_CONTROL	EQU $40
DEF hLCD_Y		EQU $44
DEF hBG_PAL		EQU $47
DEF hOBJ_PAL0		EQU $48
DEF hOBJ_PAL1		EQU $49
DEF hINTERRUPT_ENABLE	EQU $FF

; vim:ft=rgbds

