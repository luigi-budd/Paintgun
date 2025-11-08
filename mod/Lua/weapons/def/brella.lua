for i = 0,8
	sfxinfo[freeslot("sfx_p_s5_"..i)].caption = "Paint fired"
end
sfxinfo[sfx_p_s5_4].caption = "/"
sfxinfo[sfx_p_s5_5].caption = "Brella deployed"
sfxinfo[sfx_p_s5_6].caption = "/"
sfxinfo[sfx_p_s5_7].caption = "Brella breaks"
sfxinfo[sfx_p_s5_8].caption = "Brella recovered!"

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
	name = "brella",
	handoffset = 8*FU,
	range = 355 * FU,
	dropoff = 310*FU,
	h_spread = {10, 10},
	v_spread = {8, 8},
	falloff = {2,2},
	maxdamage = 16*FU + (FU/5),
	damage = MIN_DAMAGE,
	guntype = WPT_BRELLA,
	firerate = TR/2,
	shootspeed = tofixed("0.45"),
	inkcost = tofixed("6.325"),
	inkdelay = TR,
	dragmul = FU*58/100,
	
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
		onfire = function(p,pt,wep, proj, mom_vec, angle, aiming, dospread, doaiming)
			local spread = wep:get(pt,"pelletspread")
			local noise = wep:get(pt,"pelletnoise")
			for i = -2,2
				if i == 0 then continue end
				local frac = FixedDiv((i*FU), 2*FU)
				local ang = FixedMul(spread,frac) - FixedMul(noise, P_RandomFixed())
				local aim = FixedMul(noise, P_RandomFixed())
				local proj = Paint:fireWeapon(p,wep, angle, aiming, false, true, ang,aim)
				if not proj then continue end
				
				--Paint:aimProjectile(p,proj, ang, aim, nil,mom_vec,false,false)
			end
			for i = -1,1
				for j = -1,1,2
					local h_frac = FixedDiv((i*FU), 2*FU)
					local v_frac = FixedDiv((j*FU), 2*FU)
					local ang = FixedMul(spread,h_frac) - FixedMul(noise, P_RandomFixed())
					local aim = FixedMul(spread,v_frac) + FixedMul(noise, P_RandomFixed())
					
					local proj = Paint:fireWeapon(p,wep, angle, aiming, false, true, ang,aim)
					if not proj then continue end
					
					--Paint:aimProjectile(p,proj, ang, aim, nil,mom_vec,false,false)
				end
			end
		end
	},
	abilitywrap = function(p,pt, weapon, key,value)
		local firing = false
		if (pt.fireheld or p.cmd.buttons & BT_ATTACK)
			firing = true
		end
		if (pt.deployshield or pt.shieldlag)
		or (pt.firewait or pt.fireheld or pt.endlag)
			firing = true
		end
		if not firing then return end
		if (key == "handoffset")
			return 0
		end
	end
})