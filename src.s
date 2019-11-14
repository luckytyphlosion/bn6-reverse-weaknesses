
	.gba

	.include ver
	IWRAM_CODE_ROM_START equ 0x81d6000
	IWRAM_CODE_RAM_START equ 0x3005B00

	ELEM_BREAK  equ 0x10
	ELEM_WIND   equ 0x20
	ELEM_CURSOR equ 0x40
	ELEM_SWORD  equ 0x80

	.open INPUT_FILE, OUTPUT_FILE, 0x3005B00 - 0x1d6000
	.org 0x3007444
	// row is defending element, col is attacking element
	//    NULL  HEAT  AQUA  ELEC  WOOD
	.byte 0x0,  0x0,  0x0,  0x0,  0x0   // NULL 
	.byte 0x0,  0x0,  0x0,  0x0,  0x1   // HEAT
    .byte 0x0,  0x1,  0x0,  0x0,  0x0   // AQUA
    .byte 0x0,  0x0,  0x1,  0x0,  0x0   // ELEC
    .byte 0x0,  0x0,  0x0,  0x1,  0x0   // WOOD

	.org 0x30074e2
	// hook secondary element weakness function
	b ReverseSecondaryElementWeaknessesHook
ReverseSecondaryElementWeaknessesPostHook:

	// fix secondary sword beating break
	.org 0x30074e8
	cmp r0, #ELEM_CURSOR // r0 holds the defending collision's secondary element weakness, the element weak to cursor is break, and sword beats break, so change this element to cursor (from wind)

	// iwram code freespace
	.org 0x30079d4
ReverseSecondaryElementWeaknessesHook:
	mov r2, 0
	push {r3}
	mov r3, (ELEM_CURSOR | ELEM_BREAK)
	tst r1, r3 // is attacking element cursor or break?
	pop {r3}
	beq @@notCursorOrBreak
	lsl r1, r1, 1
	b ReverseSecondaryElementWeaknessesPostHook
@@notCursorOrBreak:
	lsr r1, r1, 1
	b ReverseSecondaryElementWeaknessesPostHook
	.align 4, 0
ReverseSecondaryElementWeaknessesHookEnd:

	.headersize 0x8000000
	// increase iwram code size (overwrites some garbage directly after)
	.org 0x8000210
	.word 0x1ED4 + (ReverseSecondaryElementWeaknessesHookEnd - ReverseSecondaryElementWeaknessesHook)

	.close
