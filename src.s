
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

	// change the element that does 2x on grass
	.org HEAT_2x_GRASS_COMPARE_ADDR
	cmp r1, ELEM_ELEC

	// change the element that removes grass
	.org HEAT_REMOVE_GRASS_COMPARE_ADDR
	cmp r0, ELEM_ELEC

	// change the element that does 2x against bubbled
	.org ELEC_2x_BUBBLE_COMPARE_ADDR
	cmp r0, ELEM_HEAT

	.headersize 0x8000000
	// increase iwram code size (overwrites some garbage directly after)
	.org 0x8000210
	.word IWRAM_BLOB_SIZE + (ReverseSecondaryElementWeaknessesHookEnd - ReverseSecondaryElementWeaknessesHook)

	// change the offset that is read to check if the element
	// that removes bblwrap has any damage
	.org BBLWRAP_ELEM_DAMAGE_OFFSET_ADDR
	mov r1, 0x96 // base is 0x94, 0x94 + ELEM_HEAT * 2

	// change the element that hits through riskyhoney's hive
	.org HIVE_HEAT_PANEL_DAMAGE_OFFSET_ADDR
	mov r1, 0x88 // base is 0x82, 0x82 + ELEM_ELEC * 2

	// have heat damage count towards bee spawning
	.org HIVE_HEAT_PANEL_DAMAGE_OFFSET_ADDR + 14
	ldrh r1, [r0, 0x84 - 0x82] // base is 0x82, 0x82 + ELEM_HEAT * 2 - 0x82

	// test battle for heat on bubble
	.if 0
		.org readu32(INPUT_FILE, HEATMAN_OR_SPOUTMAN_BATTLE_SETTINGS_ADDR + 0xc - 0x8000000) + 0x4
		.byte 0x11
		.byte 0x25
		.halfword 0x55
		.byte 0x11
		.byte 0x26
		.halfword 0x61
		.byte 0x11
		.byte 0x14
		.halfword 0x2b
		.byte 0xf0
	.endif

	.org SHUFFLE_FOLDER_SLICE_ADDR
ShuffleFolderSlice:
	push {r4-r6,lr}
	sub r4, r1, 1
	beq @@done
@@loop:
	push {r0}
	bl GetPositiveSignedRNG1
	add r1, r4, 1
	swi 6 // r1 = rand() % (r1 + 1)
	pop {r0}

	add r1, r1, r1
	add r3, r4, r4
	ldrh r5, [r0,r1]
	ldrh r6, [r0,r3]
	strh r6, [r0,r1]
	strh r5, [r0,r3]
	sub r4, 1
	bne @@loop
@@done:
	pop {r4-r6,pc}

	.close
