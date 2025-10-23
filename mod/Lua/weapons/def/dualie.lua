for i = 0,5
	sfxinfo[freeslot("sfx_p_s4_"..i)].caption = "Paint fired"
end
sfxinfo[freeslot("sfx_p_s4_6")].caption = "Dualies merge"
sfxinfo[freeslot("sfx_p_s4_7")].caption = "Dualies split"

--squelchers
Paint:registerWeapon({
	name = "dualies",
	handoffset = 5*FU,
	h_spread = {4, 4},
	v_spread = {3, 3},
	damage = 25*FU,
	guntype = WPT_DUALIES,
	lifespan = 4,
	shootspeed = FU*78/100,
	
	inkcost = FU*6/5,
	
	spread_base = (FU * 4), -- chance to spread, similar to accelstart
	spread_pershot = (FU * 2), -- add this much chance to spread per shot
	spread_max = (FU * 30), -- max chance to spread
	spread_decay = (FU),
	spread_jumpspread = 4*FU, -- how many degrees does jump inaccuracy add?
	spread_jump = 56, -- how many tics until jump spread decays?
	spread_jumpchance = (FU * 40), -- set spread chance to this when jumping
	
	turret_range = 500*FU,
	turret_firerate = 1,
	
	turret_startsound = sfx_p_s4_6,
	turret_endsound = sfx_p_s4_7,
	
	abilitywrap = Paint.wtemplate_dualies,
	sounds = {
		sfx_p_s4_0, sfx_p_s4_1, sfx_p_s4_2, sfx_p_s4_3, sfx_p_s4_4, sfx_p_s4_5
	}
})
