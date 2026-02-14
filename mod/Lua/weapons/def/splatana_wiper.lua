freeslot("S_PAINT_GUN_WIPER")
states[S_PAINT_GUN_WIPER] = {
	sprite = SPR_PAINT_GUN,
	frame = 3,
	tics = -1,
	nextstate = S_PAINT_GUN_WIPER
}
freeslot("S_PAINT_GUN_WIPER_S")
states[S_PAINT_GUN_WIPER_S] = {
	sprite = SPR_PAINT_GUN,
	frame = 14,
	tics = -1,
	nextstate = S_PAINT_GUN_WIPER_S
}

for i = 0,9
	sfxinfo[freeslot("sfx_p_s8_"..i)].caption = "Paint slash"
end
sfxinfo[      sfx_p_s8_9      ].caption = "Dry fire"
sfxinfo[freeslot("sfx_p_s8_a")].caption = "Dry fire"
sfxinfo[freeslot("sfx_p_s8_b")].caption = "Charging"
sfxinfo[freeslot("sfx_p_s8_c")].caption = "Charging"

local pshot = mobjinfo[MT_PAINT_SHOT]
Paint:registerWeapon({
	realname = "Splatana Wiper",
	icon = "PTMAIN_SWIPER",
	
	name = "wiper",
	--subtype = "torpedo",
	guntype = WPT_KATANA,
	h_spread = {14*FU, 14*FU},
	v_spread = {14*FU, 14*FU},
	handoffset = 8*FU,
	damage = 30*FU,
	maxdamage = 60*FU,
	totaldamage = 30*FU,
	capdamage = true,
	firerate = 9,
	endlag = 11,
	tapfire = true,
	shootspeed = FU * 3/5,
	spread_jumpspread = 0,
	spread_jump = 0,
	spread_jumpchance = 0,
	neverspreadatall = true,
	nodryfirelag = true,
	dofireanim = false,
	allowdrycolor = true,
	swipeangleoffset = 180*FU,
	shotstate = S_PAINT_HSLASH_C,
	vshotstate = S_PAINT_HSLASH_V,
	
	chargetime = 8*FU, -- takes 8 tics to fully charge
	mincharge = 4,
	
	inkcost = FU * 3,
	inkdelay = TR/2,
	
	weaponstate = S_PAINT_GUN_WIPER,
	weaponstate_swipe = S_PAINT_GUN_WIPER_S,
	weaponstate_scale = FU/4,
	
	spawnspeed = FixedMul(tofixed("3.3"), Paint.DU2FU), -- 2.266 splat3 distance units
	str_tics = 50, -- straight state lasts this many tics
	str2brk_maxspeed = 0, -- when ending straight state, cap xyspeed to this
	brk_airresist = FU, -- xy AND z moms are affected by air resistance
	brk_gravity = 0,
	brk2fre_minz = 0, -- go to free when momz is below this
	brk2fre_minxy = 0, -- or go to free when xyspeed is below this
	brk2fre_tics = 0, -- or when brake state lasts this many tics
	fre_airresist = FU,
	fre_gravity = 0,
	crs_guideframe = 4, -- crosshair is placed at this frame in the shot's lifetime
	crs_scale = FU * 4/5,
	
	sounds = {
		sfx_p_s8_0, sfx_p_s8_1, sfx_p_s8_2, sfx_p_s8_3, sfx_p_s8_4, sfx_p_s8_5
	},
	drysounds = {
		sfx_p_s8_9, sfx_p_s8_a,
	},
	strong_sounds = {
		sfx_p_s8_6, sfx_p_s8_7, sfx_p_s8_8,
	},
	
	charging_sound = sfx_p_s8_b,
	slow_charging_sound = sfx_p_s8_c,

	groupnum = 1,
	groups = {
		-- TODO: only the center projectile should have
		--		 a slash sprite
		{
			offset = pshot.radius + 4*FU,
			radius = pshot.radius,
			height = pshot.height,
			state = S_PAINT_HSLASH_L,
		}
	},
	groupnum2 = 3,
	groups2 = {
		{
			offset = pshot.height * 3/5,
			radius = pshot.radius * 4/5,
			height = pshot.height * 4/5,
			state = S_INVISIBLE,
		},
		{
			offset = pshot.height * 7/5,
			radius = pshot.radius * 3/5,
			height = pshot.height * 3/5,
			state = S_INVISIBLE,
		},
		{
			offset = pshot.height * 10/5,
			radius = pshot.radius * 2/5,
			height = pshot.height * 2/5,
			state = S_INVISIBLE,
		},
	},
	
	callbacks = {
		onfire = Paint.wcallback_splatana_onfire,
		ondryfire = Paint.wcallback_splatana_ondryfire,
		onhit = Paint.wcallback_splatana_onhit,
	},
	abilitywrap = Paint.wtemplate_splatana,
})