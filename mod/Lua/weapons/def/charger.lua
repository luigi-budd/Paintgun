freeslot("S_PAINT_GUN_CHARGER")
states[S_PAINT_GUN_CHARGER] = {
	sprite = SPR_PAINT_GUN,
	frame = C,
	tics = -1,
	nextstate = S_PAINT_GUN_CHARGER
}

Paint:registerWeapon({
	name = "charger",
	handoffset = 6*FU,
	range = 1224*FU,
	damage = 40*FU, -- damage here is the minimum damage
	firerate = 4,
	shootspeed = FU/6,
	
	inkdelay = 12,
	squidlag = 14,
	
	guntype = WPT_CHARGER,

	neverspreadonground = true,
	neverspreadatall = true,
	h_spread = {0, 0},
	v_spread = {0, 0},
	
	weaponstate = S_PAINT_GUN_CHARGER,
	abilitywrap = Paint.wtemplate_charger,
	/*
	sounds = {
		sfx_p_s1_0, sfx_p_s1_1, sfx_p_s1_2, sfx_p_s1_3, sfx_p_s1_4, sfx_p_s1_5, sfx_p_s1_6
	}
	*/
})
