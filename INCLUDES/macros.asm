MACRO HEADER
	db	$CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D ; Nintendo Logo
	db	$00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
	db	$BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E
	db	\1	; Game title info
	db	0	; GBC support
	db	0,0	; Licensee code
	db	0	; SGB support
	db	0	; Cart type
	db	0	; ROM size
	db	0	; RAM size
	db	0	; Destination code
	db	0	; Old licensee code
	db	0	; Mask ROM version
	db	0	; Complement check
	dw	0	; Checksum
ENDM

; vim:ft=rgbds

