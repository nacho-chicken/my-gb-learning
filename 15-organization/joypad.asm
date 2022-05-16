INCLUDE "../INCLUDES/hardware-constants.inc"

SECTION "Joypad", ROM0

/*	joypad_read
Processes joypad input data into a single byte, saving it into RAM afterwards.

	Registers changed:
	abc
*/
joypad_read::
	; This is necessary for checking button states beyond a binary on/off
	; For any given bit, if x=current and y=prev,
	; Not held	: !x & !y
	; Pressed	: x & !y
	; Held		: x & y
	; Released	: !x & y
	ld	a, [wJoypadState]
	ld	[wJoypadStatePrevious], a
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
	ld	a, JOYPAD_DIRECTION
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

; vim:ft=rgbds

