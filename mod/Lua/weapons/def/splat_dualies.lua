freeslot("S_PAINT_GUN_SDUAL")
states[S_PAINT_GUN_SDUAL] = {
	sprite = SPR_PAINT_GUN,
	frame = 10,
	tics = -1,
	nextstate = S_PAINT_GUN_SDUAL
}

for i = 0,5
	sfxinfo[freeslot("sfx_p_s6_"..i)].caption = "Paint fired"
end
sfxinfo[sfx_p_s6_5].caption = "Dodge roll"

Paint:registerWeapon({
	realname = "Splat Dualies",
	icon = "PTMAIN_SDUALIES",
	
	name = "splat_dualies",
	subtype = "suctionbomb",
	handoffset = 5*FU,
	h_spread = {4*FU, 4*FU},
	v_spread = {4*FU, 4*FU},
	damage = 30*FU,
	guntype = WPT_DUALIES,
	lifespan = 4,
	shootspeed = FixedDiv(tofixed("0.08"), Paint.SPLAT2WALKSPEED),
	falloffdamage = 15*FU,
	fallofftime = 4,
	inkcost = (FU*72/100),
	firerate = 2,
	weightclass = WEI_MID,
	
	spawnspeed = FixedMul(tofixed("2.37"), Paint.DU2FU), -- 2.266 splat3 distance units
	str_tics = 3, -- straight state lasts this many tics
	str2brk_maxspeed = FixedMul(tofixed("2.3425"), Paint.DU2FU), -- when ending straight state, cap xyspeed to this
	brk_airresist = FU * 64/100, -- xy AND z moms are affected by air resistance
	fre_gravity = FixedMul(tofixed("0.016"), Paint.DU2FU),
	crs_guideframe = 7, -- crosshair is placed at this frame in the shot's lifetime

	spread_base = (FU), -- chance to spread, similar to accelstart
	spread_pershot = (FU), -- add this much chance to spread per shot
	spread_max = (FU * 25), -- max chance to spread
	spread_decay = (FU/2),
	spread_jumpspread = 5*FU + (FU/2), -- how many degrees does jump inaccuracy add?
	spread_jump = 55, -- how many tics until jump spread decays?
	spread_jumpchance = (FU * 40), -- set spread chance to this when jumping
	spread_recovery = 3,
	
	dodgesound = sfx_p_s6_5,
	dodgelength = 7,
	dodgeendlag = 2,
	dodgeinkcost = 7*FU,
	dodgegetup = 16,
	dodgedist = (4 * Paint.DU2FU) * 3/4,
	turret_firerate = 1,
	
	weaponstate = S_PAINT_GUN_SDUAL,
	weaponstate_scale = FU/3,
	dualie_weaponmirror = true,
	
	abilitywrap = Paint.wtemplate_dualies,
	sounds = {
		sfx_p_s6_0, sfx_p_s6_1, sfx_p_s6_2, sfx_p_s6_3, sfx_p_s6_4
	}
})
