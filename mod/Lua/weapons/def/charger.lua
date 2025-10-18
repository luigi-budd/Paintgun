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
	damage = 36*FU, -- damage here is the minimum damage
	firerate = 11,
	shootspeed = FU/4,
	
	guntype = WPT_CHARGER,
	
	weaponstate = S_PAINT_GUN_CHARGER,
	abilitywrap = Paint.wtemplate_charger,
	/*
	sounds = {
		sfx_p_s1_0, sfx_p_s1_1, sfx_p_s1_2, sfx_p_s1_3, sfx_p_s1_4, sfx_p_s1_5, sfx_p_s1_6
	}
	*/
})
