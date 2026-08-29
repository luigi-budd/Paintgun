freeslot("S_PAINT_GUN_52GAL")
states[S_PAINT_GUN_52GAL] = {
	sprite = SPR_PAINT_GUN,
	frame = 15,
	tics = -1,
	nextstate = S_PAINT_GUN_52GAL
}
for i = 0,5
	sfxinfo[freeslot("sfx_p_s9_"..i)].caption = "Paint fired"
end

Paint:registerWeapon({
	realname = ".52 Gal",
	icon = "PTMAIN_52GAL",
	
	name = "52gal",
	--subtype = "splashwall",
	handoffset = 6*FU,
	range = 188*FU,
	dropoff = 103*FU,
	dropoffmul = FU,
	lifespan = 3,
	damage = 52*FU,
	falloffdamage = 30*FU,
	fallofftime = 9,
	weightclass = WEI_MID,
	shootspeed = FixedDiv(tofixed("0.06"), Paint.SPLAT2WALKSPEED),
	
	startlag = 2,
	endlag = 2,
	
	spawnspeed = FixedMul(tofixed("3.06"), Paint.DU2FU), -- 2.266 splat3 distance units
	str_tics = 2, -- straight state lasts this many tics
	str2brk_maxspeed = FixedMul(tofixed("1.667"), Paint.DU2FU), -- when ending straight state, cap xyspeed to this
	fre_gravity = FixedMul(tofixed("0.016"), Paint.DU2FU),
	fre_airresist = FixedMul(tofixed("0.02"), Paint.DU2FU),
	crs_guideframe = 6, -- crosshair is placed at this frame in the shot's lifetime

	firerate = 4,
	h_spread = {12*FU, 12*FU},
	v_spread = {5*FU, 5*FU},
	
	inkcost = FU*3/2,
	inkdelay = TR / 5,
	
	spread_base = (FU * 2), -- chance to spread, similar to accelstart
	spread_pershot = (FU * 3), -- add this much chance to spread per shot
	spread_max = (FU * 25), -- max chance to spread
	spread_recovery = 5, -- how many tics to wait before recovering spread
	spread_decay = (FU*3/2),
	spread_jumpspread = 6*FU, -- how many degrees does jump inaccuracy add?
	spread_jump = 55, -- how many tics until jump spread decays?
	
	weaponstate = S_PAINT_GUN_52GAL,
	weaponstate_scale = FU*12/10,
	
	sounds = {
		sfx_p_s9_0, sfx_p_s9_1, sfx_p_s9_2, sfx_p_s9_3, sfx_p_s9_4, sfx_p_s9_5, sfx_p_s9_6
	}
})
