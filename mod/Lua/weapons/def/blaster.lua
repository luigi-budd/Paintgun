freeslot("S_PAINT_GUN_BLASTER")
states[S_PAINT_GUN_BLASTER] = {
	sprite = SPR_PAINT_GUN,
	frame = E,
	tics = -1,
	nextstate = S_PAINT_GUN_BLASTER
}
for i = 0,2
	sfxinfo[freeslot("sfx_p_s3_"..i)].caption = "Splatter"
end
sfxinfo[sfx_p_s3_0] = {
	caption = "Paint fired",
	flags = SF_X4AWAYSOUND,
}

Paint:registerWeapon({
	realname = "Blaster",
	
	name = "blaster",
	--subtype = "autobomb",
	handoffset = 5*FU,
	range = 400*FU,
	damage = 125*FU,
	firerate = 28,
	shootspeed = tofixed("0.45"),
	startlag = 7,
	endlag = 14,
	lifespan = 6,
	inertia = false,
	neverspreadonground = true,
	shotstate = S_PAINT_SHOT_BIG,
	dropoff = 0,
	
	inkcost = 10*FU,
	inkdelay = 33,
	
	h_spread = {4*FU, 4*FU},
	v_spread = {4*FU, 4*FU},
	spread_recovery = 0, -- how many tics to wait before recovering spread
	spread_jumpspread = 7*FU, -- how many degrees does jump inaccuracy add?
	spread_jump = 56, -- how many tics until jump spread decays?
	spread_jumpchance = (FU * 50), -- set spread chance to this when jumping

	spawnspeed = FixedMul(FixedMul(tofixed("0.945"), Paint.DU2FU), Paint.SIXTY2THIRTYFIVE),
	str_tics = 4, -- straight state lasts this many tics
	str2brk_maxspeed = FixedMul(FixedMul(tofixed("0.9131"), Paint.DU2FU), Paint.SIXTY2THIRTYFIVE), -- when ending straight state, cap xyspeed to this
	brk_airresist = FU * 64/100, -- xy AND z moms are affected by air resistance
	brk_gravity = 0, --FixedMul(tofixed("0.07"), Paint.DU2FU),
	brk2fre_tics = 3, -- or when brake state lasts this many tics
	crs_guideframe = 7, -- crosshair is placed at this frame in the shot's lifetime
	
	guntype = WPT_BLASTER,
	
	weaponstate = S_PAINT_GUN_BLASTER,
	weaponstate_scale = FU/4,
	
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
