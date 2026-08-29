freeslot("sfx_dsclwh", "sfx_dsclwm")
freeslot("S_ZE2_FISTVFX")

sfxinfo[sfx_dsclwh].caption = "Whiff"
sfxinfo[sfx_dsclwm].caption = "Punch"

states[S_ZE2_FISTVFX] = {
	sprite = SPR_BARX,
	frame = FF_TRANS90|FF_FULLBRIGHT,
	tics = 5,
	action = function(actor)
		actor.destscale = actor.scale*6
		actor.scalespeed = $ * 2
		actor.color = SKINCOLOR_RED
		actor.colorized = true
		actor.blendmode = AST_ADD
	end
}

Paint:registerWeapon({
	realname = "Fists",
	icon = "PTMAIN_FISTS",
	icon_scale = FU * 8/10,
	
	name = "fists",
	subtype = "burstbomb",
	handoffset = 6*FU,
	damage = 16*FU,
	falloffdamage = 12*FU,
	fallofftime = 8,
	shotscale = FU,
	shotstretch = false,
	shottype = MT_RAY,
	tapfire = true,
	weightclass = WEI_LIGHT,
	guntype = WPT_KATANA,
	
	tapfire = true,
	endlag = 14,
	squidlag = 8,
	shootspeed = FU,
	charging_shootspeed = FU,
	splatvolume = 255/4,
	
	critsound = true,
	shotsforcrit = 9,
	
	spawnspeed = 70*FU,
	crs_guideframe = 2,
	str_tics = 12, -- straight state lasts this many tics
	str2brk_maxspeed = FixedMul(tofixed("1.652"), Paint.DU2FU), -- when ending straight state, cap xyspeed to this
	brk_airresist = FU * 64/100, -- xy AND z moms are affected by air resistance
	brk_gravity = FixedMul(tofixed("0.06"), Paint.DU2FU),
	brk2fre_minz = FixedMul(tofixed("-0.15"), Paint.DU2FU), -- go to free when momz is below this
	brk2fre_minxy = FixedMul(tofixed("0.2355"), Paint.DU2FU), -- or go to free when xyspeed is below this
	brk2fre_tics = 4, -- or when brake state lasts this many tics
	fre_airresist = FU * 78/100,
	fre_gravity = FixedMul(tofixed("0.06"), Paint.DU2FU),
	
	dodgerolls = 1, -- use endlag variable
	dodgeslide = false, -- dualie squelchers
	dodgelength = 4,
	dodgedist = FixedMul(tofixed("2.0"), Paint.DU2FU),
	dodgeendlag = 0, -- wait this many tics AFTER rolling to start firing
	dodgecamlag = 6,
	dodgegetup = 8, -- you can get up after this many tics
	dodgeinkcost = 0, -- use this much ink for dodge rolls
	dodgesound = sfx_pt_lug,
	
	melee_damage = 22*FU,
	melee_radius = 64*FU,
	melee_height = 32*FU,
	melee_offset = 14*FU,
	
	vmelee_damage = 48*FU,
	vmelee_radius = 64*FU,
	vmelee_height = 32*FU,
	vmelee_offset = 14*FU,
	
	chargetime = 0,
	crs_chargedguideframe = 2,
	
	firerate = 4,
	h_spread = {60*FU,60*FU},
	v_spread = {3*FU, 3*FU},
	neverspreadatall = true,
	
	inkcost = 0,
	inkdelay = 0,
	
	weaponstate = S_INVISIBLE,
	weaponstate_scale = FU,
	
	sounds = {
		sfx_dsclwh
	},
	strong_sounds = {
		sfx_dsclwh,
	},
	
	callbacks = {
		onfire = Paint.wcallback_splatana_onfire,
		ondryfire = Paint.wcallback_splatana_ondryfire,
		onhit = Paint.wcallback_splatana_onhit,
	},
	abilitywrap = Paint.wtemplate_splatana,
})
