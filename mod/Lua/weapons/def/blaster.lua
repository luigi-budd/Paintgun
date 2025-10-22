freeslot("S_PAINT_GUN_BLASTER")
states[S_PAINT_GUN_BLASTER] = {
	sprite = SPR_PAINT_GUN,
	frame = E,
	tics = -1,
	nextstate = S_PAINT_GUN_BLASTER
}
for i = 0,3
	sfxinfo[freeslot("sfx_p_s3_"..i)].caption = "Splatter"
end
sfxinfo[sfx_p_s3_0] = {
	caption = "Paint fired",
	flags = SF_X4AWAYSOUND,
}

Paint:registerWeapon({
	name = "blaster",
	handoffset = 10*FU,
	range = 470*FU,
	damage = 125*FU,
	firerate = 28,
	shootspeed = tofixed("0.45"),
	startlag = 7,
	endlag = 29,
	lifespan = 6,
	inertia = false,
	falloff = {0,0},
	neverspreadonground = true,
	shotstate = S_PAINT_SHOT_BIG,
	
	inkcost = 10*FU,
	inkdelay = 33,
	
	h_spread = {3, 3},
	v_spread = {3, 3},
	spread_recovery = 0, -- how many tics to wait before recovering spread
	spread_jumpspread = 7*FU, -- how many degrees does jump inaccuracy add?
	spread_jump = 56, -- how many tics until jump spread decays?
	spread_jumpchance = (FU * 50), -- set spread chance to this when jumping

	guntype = WPT_BLASTER,
	
	weaponstate = S_PAINT_GUN_BLASTER,
	
	sounds = {
		sfx_p_s3_2
	},
	blast_sounds = {
		sfx_p_s3_0
	},
	explode_sounds = {
		sfx_p_s3_1
	},
	soundvolume = 255,
	/*
	sounds = {
		sfx_p_s1_0, sfx_p_s1_1, sfx_p_s1_2, sfx_p_s1_3, sfx_p_s1_4, sfx_p_s1_5, sfx_p_s1_6
	}
	*/
})
