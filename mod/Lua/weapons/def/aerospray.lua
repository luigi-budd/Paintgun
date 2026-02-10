freeslot("S_PAINT_GUN_AERO")
states[S_PAINT_GUN_AERO] = {
	sprite = SPR_PAINT_GUN,
	frame = B,
	tics = -1,
	nextstate = S_PAINT_GUN_AERO
}
for i = 0,6
	sfxinfo[freeslot("sfx_p_s1_"..i)].caption = "Paint fired"
end

local point63 = tofixed(".63")

Paint:registerWeapon({
	realname = "Aerospray MG",
	icon = "PTMAIN_AEROSPRAY",
	
	name = "rapid",
	subtype = "burstbomb",
	handoffset = 6*FU,
	range = 188*FU,
	dropoff = 103*FU,
	dropoffmul = FU,
	lifespan = 3,
	damage = 24*FU,
	falloffdamage = 12*FU,
	fallofftime = 8,
	shotscale = FU*3/4,
	
	spawnspeed = FixedMul(tofixed("2.266"), Paint.DU2FU), -- 2.266 splat3 distance units
	str_tics = 3, -- straight state lasts this many tics
	str2brk_maxspeed = FixedMul(tofixed("1.9513"), Paint.DU2FU), -- when ending straight state, cap xyspeed to this
	fre_gravity = FixedMul(tofixed("0.016"), Paint.DU2FU),
	crs_guideframe = 8, -- crosshair is placed at this frame in the shot's lifetime

	firerate = 2,
	h_spread = {12*FU+point63, 12*FU+point63},
	v_spread = {7*FU, 7*FU},
	
	inkcost = FU/2,
	inkdelay = TR / 4,
	
	spread_base = (FU * 6), -- chance to spread, similar to accelstart
	spread_pershot = (FU * 3), -- add this much chance to spread per shot
	spread_max = (FU * 50), -- max chance to spread
	spread_decay = (FU),
	spread_jumpspread = 2*FU, -- how many degrees does jump inaccuracy add?
	
	weaponstate = S_PAINT_GUN_AERO,
	weaponstate_scale = FU/2,
	
	sounds = {
		sfx_p_s1_0, sfx_p_s1_1, sfx_p_s1_2, sfx_p_s1_3, sfx_p_s1_4, sfx_p_s1_5, sfx_p_s1_6
	}
})
