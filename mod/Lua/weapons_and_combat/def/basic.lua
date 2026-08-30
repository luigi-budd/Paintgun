local hsprd = tofixed("4.86")

Paint:registerWeapon({
	realname = "Splattershot",
	icon = "PTMAIN_SSHOT",
	
	name = "basic",
	subtype = "suctionbomb",
	handoffset = 8*FU,
	h_spread = {hsprd,hsprd},
	spread_jumpspread = tofixed("11.66") - hsprd,
	v_spread = {3*FU, 3*FU},
	damage = 36*FU,
	weightclass = WEI_MID,
	shootspeed = FixedDiv(tofixed("0.072"), Paint.SPLAT2WALKSPEED),
	
	inkcost = FU * 92/100,
	
	weaponstate = S_PAINT_GUN,
	weaponstate_scale = FU/2,
	
	spawnspeed = FixedMul(tofixed("2.266"), Paint.DU2FU), -- 2.266 splat3 distance units
	str_tics = 4, -- straight state lasts this many tics
	str2brk_maxspeed = FixedMul(tofixed("1.493"), Paint.DU2FU), -- when ending straight state, cap xyspeed to this
	brk_airresist = FU * 64/100, -- xy AND z moms are affected by air resistance
	brk_gravity = FixedMul(tofixed("0.07"), Paint.DU2FU),
	brk2fre_minz = FixedMul(tofixed("-0.15"), Paint.DU2FU), -- go to free when momz is below this
	brk2fre_minxy = FixedMul(tofixed("0.2355"), Paint.DU2FU), -- or go to free when xyspeed is below this
	brk2fre_tics = 4, -- or when brake state lasts this many tics
	fre_airresist = FU * 98/100,
	fre_gravity = FixedMul(tofixed("0.016"), Paint.DU2FU),
	crs_guideframe = 8, -- crosshair is placed at this frame in the shot's lifetime
	
	/*
	inkcost = (FU * 92/100)/6,
	callbacks = {
		onfire = function(p,pt,wep, proj,mom_vec,angle,dospread)
			local s = (pt.shotsfired % 2 == 0) and 1 or -1
			local maxrot = 32
			local adjangle = FixedAngle(360 * FixedDiv((pt.shotsfired % maxrot)*FU, maxrot*FU))
			local adjustx = cos(adjangle)
			local adjusty = sin(adjangle)
			
			angle = $ - FixedMul(ANG10*s, adjustx)
			local aim = p.aiming + FixedMul(ANG10*s, adjusty)
			
			local proj = Paint:fireWeapon(p,wep, angle, aim, false)
			pt.shotsfired = $ - 1
			if not proj then return end
			
			Paint:aimProjectile(p,proj, angle,aim, false,mom_vec,false,false)
		end
	}
	*/
})

-- nova
/*
Paint:registerWeapon({
	name = "basic",
	handoffset = 8*FU,
	h_spread = {7, 7},
	v_spread = {4, 4},
	damage = 24*FU,
	inkcost = FU * 96/100,
	range = 570*FU,
	
	weaponstate = S_PAINT_GUN_TEST,
	weaponstate_scale = FU/2,

	spread_base = (FU * 10), -- chance to spread, similar to accelstart
	spread_pershot = (FU * 3), -- add this much chance to spread per shot
	spread_max = (FU * 25), -- max chance to spread
	spread_decay = (FU * 2),
	spread_jumpspread = 4*FU, -- how many degrees does jump inaccuracy add?
	spread_jump = 56, -- how many tics until jump spread decays?
	spread_jumpchance = (FU * 40), -- set spread chance to this when jumping
})
*/