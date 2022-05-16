SECTION "RNG", ROM0

/*	random_init
Initializes the psuedo-RNG system.
This project uses a 16-bit LFSR (Xorshift) mechanism.

	Registers changed:
	a, hl
*/
random_init::
	ld	hl, wRNG
	; The random seed
	; This can be any 16-bit number EXCEPT 0x0000
	ld	[hl], $FF
	inc	hl ; Can only do LD [HLI] with A register
	ld	[hl], $FF
	ret

/*	random
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
random::
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

; vim:ft=rgbds

