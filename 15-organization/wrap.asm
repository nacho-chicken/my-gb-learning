SECTION "Wrapping", ROM0

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
in_bounds::
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
wrap_value::
	dec	a
	jp	nz, .greater
.less:
	ld	a, c
	ret
.greater:
	ld	a, b
	ret

; vim:ft=rgbds

