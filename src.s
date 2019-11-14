
	.gba

	.include ver
	IWRAM_CODE_ROM_START equ 0x81d6000
	IWRAM_CODE_RAM_START equ 0x3005B00

	ELEM_NULL equ 0x00
	ELEM_HEAT equ 0x01
	ELEM_AQUA equ 0x02
	ELEM_ELEC equ 0x03
	ELEM_WOOD equ 0x04

	ELEM_BREAK  equ 0x10
	ELEM_WIND   equ 0x20
	ELEM_CURSOR equ 0x40
	ELEM_SWORD  equ 0x80

	.open INPUT_FILE, OUTPUT_FILE, 0x3005B00 - 0x1d6000
	.org PRIMARY_ELEM_WEAKNESS_ADDR
	// row is defending element, col is attacking element
	//    NULL  HEAT  AQUA  ELEC  WOOD
	.byte 0x0,  0x0,  0x0,  0x0,  0x0   // NULL 
	.byte 0x0,  0x0,  0x0,  0x0,  0x1   // HEAT
    .byte 0x0,  0x1,  0x0,  0x0,  0x0   // AQUA
    .byte 0x0,  0x0,  0x1,  0x0,  0x0   // ELEC
    .byte 0x0,  0x0,  0x0,  0x1,  0x0   // WOOD

	.org SECONDARY_ELEM_WEAKNESS_ADDR
	// hook secondary element weakness function
	b ReverseSecondaryElementWeaknessesHook
ReverseSecondaryElementWeaknessesPostHook:

	// fix secondary sword beating break
	.org SECONDARY_ELEM_WEAKNESS_ADDR + 6
	cmp r0, #ELEM_CURSOR // r0 holds the defending collision's secondary element weakness, the element weak to cursor is break, and sword beats break, so change this element to cursor (from wind)

	// iwram code freespace
	.org IWRAM_FREESPACE
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

	// change the element that does 2x against bblwrap
	.org BBLWRAP_ELEM_COMPARE_ADDR
	cmp r1, ELEM_HEAT
	
	.headersize 0x8000000
	// increase iwram code size (overwrites some garbage directly after)
	.org 0x8000210
	.word IWRAM_BLOB_SIZE + (ReverseSecondaryElementWeaknessesHookEnd - ReverseSecondaryElementWeaknessesHook)

	// change the offset that is read to check if the element
	// that removes bblwrap has any damage
	.org BBLWRAP_ELEM_DAMAGE_OFFSET_ADDR
	mov r1, 0x96 // base is 0x94, 0x94 + ELEM_HEAT * 2

	.close
