INCLUDE "../INCLUDES/hardware-constants.inc"

SECTION "WRAM", WRAM0[$C000]

; The VBlank flag has been removed since it was no longer necessary

; For DMA transfer
wOAMBuffer::
	ds SPRITE_DATA_SIZE * 40
wOAMBufferEnd::

wIsCGB::
	ds	1

; Might move the following to HRAM to help optimize reads
wJoypadState:: ; The current status of the joypad input
	ds	1
wJoypadStatePrevious:: ; Previous joypad status, used for checking presses
	ds	1

; Will DEFINITELY move this to HRAM later
wRNG::
	ds	2
wRNGEnd::

; Animation data for Egg sprites
; 	Bits:
;	0-4 - Animation timer
;	5 - Frame
;	6 - Unused
;	7-8 - CGB Palette data
wEgg::
	ds	9
wEggEnd::

; Scratch RAM
wScratch::
	ds	8

; vim:ft=rgbds

