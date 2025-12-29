freeslot("S_PAINT_GUN_DUAL_L")
states[S_PAINT_GUN_DUAL_L] = {
	sprite = SPR_PAINT_GUN,
	frame = 5,
	tics = -1,
	nextstate = S_PAINT_GUN_DUAL_L
}
freeslot("S_PAINT_GUN_DUAL_R")
states[S_PAINT_GUN_DUAL_R] = {
	sprite = SPR_PAINT_GUN,
	frame = 6,
	tics = -1,
	nextstate = S_PAINT_GUN_DUAL_R
}

for i = 0,5
	sfxinfo[freeslot("sfx_p_s4_"..i)].caption = "Paint fired"
end
sfxinfo[freeslot("sfx_p_s4_6")].caption = "Dualies merge"
sfxinfo[freeslot("sfx_p_s4_7")].caption = "Dualies split"

--squelchers
Paint:registerWeapon({
	realname = "Dualie Squelchers",
	
	name = "dualies",
	handoffset = 5*FU,
	h_spread = {6*FU, 6*FU},
	v_spread = {4*FU, 4*FU},
	damage = 25*FU,
	guntype = WPT_DUALIES,
	lifespan = 4,
	shootspeed = FU*78/100,
	falloffdamage = 14*FU,
	fallofftime = 6,
	-- a bit lower than splat3's since the higher
	-- firerate here makes you use a bit more ink
	inkcost = (FU*6/5)*8/10,
	range = 430*FU,
	firerate = 2,
	
	spread_base = (FU * 4), -- chance to spread, similar to accelstart
	spread_pershot = (FU * 2), -- add this much chance to spread per shot
	spread_max = (FU * 30), -- max chance to spread
	spread_decay = (FU),
	spread_jumpspread = 4*FU, -- how many degrees does jump inaccuracy add?
	spread_jump = 56, -- how many tics until jump spread decays?
	spread_jumpchance = (FU * 40), -- set spread chance to this when jumping
	
	--turret_range = 500*FU,
	--turret_firerate = 1,
	
	turret_startsound = sfx_p_s4_6,
	turret_endsound = sfx_p_s4_7,
	
	weaponstate = S_PAINT_GUN_DUAL_R,
	weaponstate_scale = FU*6/10,
	dualie_weaponstate = S_PAINT_GUN_DUAL_L,
	
	abilitywrap = Paint.wtemplate_dualies,
	sounds = {
		sfx_p_s4_0, sfx_p_s4_1, sfx_p_s4_2, sfx_p_s4_3, sfx_p_s4_4, sfx_p_s4_5
	}
})
