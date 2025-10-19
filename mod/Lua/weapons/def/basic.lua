freeslot("S_PAINT_GUN_TEST")
states[S_PAINT_GUN_TEST] = {
	sprite = SPR_PAINT_GUN,
	frame = 5,
	tics = -1,
	nextstate = S_PAINT_GUN_TEST
}

Paint:registerWeapon({
	name = "basic",
	handoffset = 8*FU,
	h_spread = {6, 6},
	v_spread = {4, 4},
	damage = 35*FU,
	inkcost = FU * 92/100,
	
	weaponstate = S_PAINT_GUN_TEST,
	weaponstate_scale = FU/2,
})
