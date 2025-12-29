for i = 0,9
	sfxinfo[freeslot("sfx_p_s5_"..i)].caption = "Paint fired"
end
sfxinfo[sfx_p_s5_4].caption = "/"
sfxinfo[sfx_p_s5_5].caption = "Brella deployed"
sfxinfo[sfx_p_s5_6].caption = "/"
sfxinfo[sfx_p_s5_7].caption = "Brella breaks"
sfxinfo[sfx_p_s5_8].caption = "Brella recovered!"
sfxinfo[sfx_p_s5_9].caption = "Brella released"
sfxinfo[freeslot("sfx_p_s5_a")].caption = "/" -- canopy flying

freeslot("S_PAINT_GUN_BRELLA_CLS")
states[S_PAINT_GUN_BRELLA_CLS] = {
	sprite = SPR_PAINT_GUN,
	frame = 7,
	tics = -1,
	nextstate = S_PAINT_GUN_BRELLA_CLS
}

freeslot("S_PAINT_GUN_BRELLA_OPN")
states[S_PAINT_GUN_BRELLA_OPN] = {
	sprite = SPR_PAINT_GUN,
	frame = 8,
	tics = -1,
	nextstate = S_PAINT_GUN_BRELLA_OPN
}

local MIN_DAMAGE = 10*FU + (FU*8/10)
Paint:registerWeapon({
	realname = "Splat Brella",
	
	name = "brella",
	--subtype = "sprinkler",
	handoffset = 8*FU,
	range = 355 * FU,
	dropoff = 310*FU,
	h_spread = {10*FU, 10*FU},
	v_spread = {8*FU, 8*FU},
	verticalspread = true,
	falloff = {2,2},
	maxdamage = 16*FU + (FU/5),
	damage = MIN_DAMAGE,
	guntype = WPT_BRELLA,
	firerate = TR/2,
	shootspeed = tofixed("0.45"),
	inkcost = tofixed("6.325"),
	inkdelay = TR,
	dragmul = FU*58/100,
	tapfire = false,
	
	startlag = 5,
	endlag = 12,
	
	weaponstate = S_PAINT_GUN_BRELLA_CLS,
	open_weaponstate = S_PAINT_GUN_BRELLA_OPN,
	weaponstate_scale = FU/2,
	shotstate = S_PAINT_SHOT_PELLET,
	
	-- brellas dont have jump spread
	spread_jumpspread = 0,
	spread_jump = 0,
	spread_jumpchance = 0,
	
	-- brellas dont have much spread either
	spread_base = 0, -- chance to spread, similar to accelstart
	spread_pershot = 0, -- add this much chance to spread per shot
	spread_max = 0, -- max chance to spread
	spread_recovery = 4, -- how many tics to wait before recovering spread
	spread_decay = (FU*3/2),
	neverspreadatall = true,
	
	falloffdamage = MIN_DAMAGE, --damage falloff when the bullet does
	fallofftime = 14, --how many tics to reach falloffdamage?
	
	sounds = {
		sfx_p_s5_0, sfx_p_s5_1, sfx_p_s5_2, sfx_p_s5_3
	},
	readysound = sfx_p_s5_4,
	deploysound = sfx_p_s5_5,
	stowsound = sfx_p_s5_6,
	breaksound = sfx_p_s5_7,
	recoversound = sfx_p_s5_8,
	soundvolume = 255 * 4/5,
	splatvolume = 255/2,
	
	callbacks = {
		onfire = Paint.wcallback_brella_onfire
	},
	abilitywrap = Paint.wtemplate_brella,
})