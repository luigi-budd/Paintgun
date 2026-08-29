freeslot("SPR_RNGC")
freeslot("S_ZE2_ACCEL_HELD")
states[S_ZE2_ACCEL_HELD] = {
	sprite = SPR_RNGC,
	frame = A,
	tics = -1,
	nextstate = S_ZE2_ACCEL_HELD
}
freeslot("S_ZE2_ACCEL_FIRED")
states[S_ZE2_ACCEL_FIRED] = {
	sprite = SPR_RNGC,
	frame = FF_ANIMATE|FF_FULLBRIGHT,
	tics = -1,
	var1 = 3,
	var2 = 1,
	nextstate = S_ZE2_ACCEL_FIRED,
}

sfxinfo[freeslot("sfx_rs_cro")].caption = "Accel ring fires"

local SPREAD = 12*FU
Paint:registerWeapon({
	realname = "Accel Ring",
	icon = "PTMAIN_ACCELRING",
	icon_scale = FU * 8/10,
	
	name = "accel_ring",
	subtype = "burstbomb",
	handoffset = 6*FU,
	damage = 16*FU,
	falloffdamage = 12*FU,
	fallofftime = 8,
	shotscale = FU,
	shotstretch = false,
	shotstate = S_ZE2_ACCEL_FIRED,
	tapfire = true,
	weightclass = WEI_MID,
	
	startlag = 7,
	endlag = 14,
	squidlag = 8,
	shootspeed = tofixed("0.45"),
	splatvolume = 255/4,
	
	critsound = true,
	shotsforcrit = 9,
	
	spawnspeed = 14*FU,
	crs_guideframe = 16,
	str_tics = 12, -- straight state lasts this many tics
	str2brk_maxspeed = FixedMul(tofixed("1.652"), Paint.DU2FU), -- when ending straight state, cap xyspeed to this
	brk_airresist = FU * 64/100, -- xy AND z moms are affected by air resistance
	brk_gravity = FixedMul(tofixed("0.06"), Paint.DU2FU),
	brk2fre_minz = FixedMul(tofixed("-0.15"), Paint.DU2FU), -- go to free when momz is below this
	brk2fre_minxy = FixedMul(tofixed("0.2355"), Paint.DU2FU), -- or go to free when xyspeed is below this
	brk2fre_tics = 4, -- or when brake state lasts this many tics
	fre_airresist = FU * 78/100,
	fre_gravity = FixedMul(tofixed("0.06"), Paint.DU2FU),
	
	firerate = 8,
	h_spread = {SPREAD,SPREAD},
	v_spread = {3*FU, 3*FU},
	neverspreadatall = true,
	
	inkcost = 100*FU / 8,
	inkdelay = TR / 2,
	
	spread_base = (FU * 6), -- chance to spread, similar to accelstart
	spread_pershot = (FU * 3), -- add this much chance to spread per shot
	spread_max = (FU * 50), -- max chance to spread
	spread_decay = (FU),
	spread_jumpspread = 2*FU, -- how many degrees does jump inaccuracy add?
	
	weaponstate = S_ZE2_ACCEL_HELD,
	weaponstate_scale = FU,
	
	sounds = {
		sfx_rs_cro
	},
	
	callbacks = {
		onfire = function(p,pt,cur_weapon, baseproj, mom_vec, angle, aiming, dospread, doaiming, newpos)
			for j = 0,2
				for i = -1,1
					if i == 0 and j == 0 then continue end
					
					local ang = angle + FixedAngle(SPREAD*i)
					local proj = Paint:fireWeapon(p,cur_weapon, ang, aiming, false, true)
					if not (proj and proj.valid) then continue end
					proj.damage = baseproj.damage
					
					/*
					proj.momx = baseproj.momx
					proj.momy = baseproj.momy
					proj.momz = baseproj.momz
					*/
					
					proj.scale = FRACUNIT * 4/5
					proj.momx = $ * (2+j)/2
					proj.momy = $ * (2+j)/2
					proj.momz = $ * (2+j)/2
					proj.str_tics = $ + j
				end
			end
		end,
		
		bulletthinker = function(p,pt,wep, shot)
			if shot.s_state ~= SS_STRAIGHT then return end
			
			shot.momx = $ * 12/11
			shot.momy = $ * 12/11
			shot.momz = $ * 12/11
			
			if not (leveltime % 3) then
				P_SpawnGhostMobj(shot)
			end
		end,
		
		crosshaironfire = function(p,pt,cur_weapon, ray, angle,aiming, rangecaster)
			local j = 2
			
			ray.scale = FRACUNIT * 4/5
			ray.momx = $ * (2+j)/2
			ray.momy = $ * (2+j)/2
			ray.momz = $ * (2+j)/2
			ray.str_tics = $ + j
		end,
		crosshairthinker = function(p,pt,wep, ray)
			if ray.s_state ~= SS_STRAIGHT then return end
			
			ray.momx = $ * 12/11
			ray.momy = $ * 12/11
			ray.momz = $ * 12/11
		end
	}
})
