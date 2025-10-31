for i = 0,3
	sfxinfo[freeslot("sfx_p_s5_"..i)].caption = "Paint fired"
end

local MIN_DAMAGE = 10*FU + (FU*8/10)
Paint:registerWeapon({
	name = "brella",
	handoffset = 8*FU,
	range = 355 * FU,
	h_spread = {8, 8},
	v_spread = {6, 6},
	maxdamage = 16*FU + (FU/5),
	damage = MIN_DAMAGE,
	guntype = WPT_BRELLA,
	firerate = TR/2,
	shootspeed = tofixed("0.45"),
	inkcost = tofixed("6.325"),
	inkdelay = TR,
	
	startlag = 5,
	endlag = 12,
	
	weaponstate = S_PAINT_GUN,
	weaponstate_scale = FU/2,
	
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
	soundvolume = 255 * 4/5,
	
	callbacks = {
		onfire = function(p,pt,wep, proj, mom_vec, angle, aiming, dospread, doaiming)
			local spread = wep:get(pt,"pelletspread")
			local noise = wep:get(pt,"pelletnoise")
			for i = -2,2
				if i == 0 then continue end
				local frac = FixedDiv((i*FU), 2*FU)
				local ang = angle - FixedAngle(FixedMul(spread,frac)) - FixedAngle(FixedMul(noise, P_RandomFixed()))
				local aim = aiming + FixedAngle(FixedMul(noise, P_RandomFixed()))
				local proj = Paint:fireWeapon(p,wep, ang, aim, false, true)
				if not proj then continue end
				
				--Paint:aimProjectile(p,proj, ang, aim, nil,mom_vec,false,false)
			end
			for i = -1,1
				for j = -1,1,2
					local h_frac = FixedDiv((i*FU), 2*FU)
					local v_frac = FixedDiv((j*FU), 2*FU)
					local ang = angle - FixedAngle(FixedMul(spread,h_frac)) - FixedAngle(FixedMul(noise, P_RandomFixed()))
					local aim = aiming + FixedAngle(FixedMul(spread,v_frac)) + FixedAngle(FixedMul(noise, P_RandomFixed()))
					
					local proj = Paint:fireWeapon(p,wep, ang, aim, false, true)
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
		if (pt.endlag or pt.firewait)
			firing = true
		end
		if not firing then return end
		if (key == "handoffset")
			return 0
		end
	end
})