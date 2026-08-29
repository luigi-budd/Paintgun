for i = 0,3
	sfxinfo[freeslot("sfx_p_s7_"..i)].caption = "Paint fired"
end
sfxinfo[sfx_p_s7_2].caption = "/"
sfxinfo[sfx_p_s7_3].caption = "Brella deployed"

freeslot("S_PAINT_GUN_UCBRELLA_CLS")
states[S_PAINT_GUN_UCBRELLA_CLS] = {
	sprite = SPR_PAINT_GUN,
	frame = 11,
	tics = -1,
	nextstate = S_PAINT_GUN_UCBRELLA_CLS
}

freeslot("S_PAINT_GUN_UCBRELLA_OPN")
states[S_PAINT_GUN_UCBRELLA_OPN] = {
	sprite = SPR_PAINT_GUN,
	frame = 12,
	tics = -1,
	nextstate = S_PAINT_GUN_UCBRELLA_OPN
}

freeslot("S_PAINT_GUN_UCBRELLA_CAN")
states[S_PAINT_GUN_UCBRELLA_CAN] = {
	sprite = SPR_PAINT_GUN,
	frame = 13,
	tics = -1,
	nextstate = S_PAINT_GUN_UCBRELLA_CAN
}

local MIN_DAMAGE = 9*FU
Paint:registerWeapon({
	realname = "Undercover Brella",
	icon = "PTMAIN_UBRELLA",
	
	name = "undercover_brella",
	--subtype = "inkmine",
	handoffset = 8*FU,
	range = 355 * FU,
	dropoff = 310*FU,
	h_spread = {6*FU, 6*FU},
	v_spread = {6*FU, 6*FU},
	verticalspread = true,
	maxdamage = 12*FU,
	damage = MIN_DAMAGE,
	totaldamage = 40*FU,
	guntype = WPT_BRELLA,
	firerate = TR/2,
	shootspeed = tofixed("0.72"),
	shieldingspeed = tofixed("0.72"),
	inkcost = tofixed("4.00"),
	inkdelay = TR * 2/3,
	dragmul = FU*58/100,
	tapfire = false,
	capdamage = true,
	weightclass = WEI_LIGHT,
	
	firerate = 14,
	startlag = 5,
	endlag = 12,
	
	weaponstate = S_PAINT_GUN_UCBRELLA_CLS,
	open_weaponstate = S_PAINT_GUN_UCBRELLA_OPN,
	shieldstate = S_PAINT_GUN_UCBRELLA_CAN,
	weaponstate_scale = FU/3,
	shieldscale = FU/3,
	shotstate = S_PAINT_SHOT_PELLET,
	
	deploywait = 6,
	shieldhp = 200*FU,
	shieldregen = 30*FU, -- heal this much hp per second
	shootwhiledeployed = true,
	shieldrelease = -1,
	shieldrecover = 3*TR + (TR*7/10),
	shieldinkuse = 0,
	shieldspan = 45*FU,
	slowturnmul = FU/4,
	regenonkill = true,
	localalpha = FU/2,
	
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
	
	groupnum = 2,
	groups = {
		{
			h_degree = 4*FU * 2,
			h_noise = FU*12/100,
			v_degree = (2*FU + (FU*7/10))/2,
			v_noise = FU/10,
			numprojs = 2
		},
		{
			h_degree = 2*FU * 2,
			h_noise = FU*5/100,
			v_degree = (2*FU + (FU*3/5))/2,
			v_noise = FU*5/100,
			numprojs = 4
		}
	},
	
	-- brellas actually do use bulletsimple params...
	-- just labelled as "MoveParam: Object" 
	spawnspeed = FixedMul(tofixed("2.0"), Paint.DU2FU), -- 2.266 splat3 distance units
	str_tics = 4, -- straight state lasts this many tics
	str2brk_maxspeed = FixedMul(tofixed("1.9085"), Paint.DU2FU), -- when ending straight state, cap xyspeed to this
	brk_airresist = FU * 64/100, -- xy AND z moms are affected by air resistance
	brk_gravity = FixedMul(tofixed("0.06"), Paint.DU2FU),
	brk2fre_minz = FixedMul(tofixed("-0.15"), Paint.DU2FU), -- go to free when momz is below this
	brk2fre_minxy = FixedMul(tofixed("0.2355"), Paint.DU2FU), -- or go to free when xyspeed is below this
	brk2fre_tics = 4, -- or when brake state lasts this many tics
	fre_airresist = FU * 98/100,
	fre_gravity = FixedMul(tofixed("0.016"), Paint.DU2FU),
	crs_guideframe = 8, -- crosshair is placed at this frame in the shot's lifetime

	falloffdamage = MIN_DAMAGE, --damage falloff when the bullet does
	fallofftime = 14, --how many tics to reach falloffdamage?
	
	sounds = {
		sfx_p_s7_0, sfx_p_s7_1
	},
	readysound = sfx_p_s7_2,
	deploysound = sfx_p_s7_3,
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