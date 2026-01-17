function Paint.wcallback_brella_onfire(p,pt,wep, proj, mom_vec, angle, aiming, dospread, doaiming)
	local spread = wep:get(pt,"pelletspread")
	local noise = wep:get(pt,"pelletnoise")
	local maxdamage = wep:get(pt,"totaldamage")
	
	proj.fired_at = leveltime
	proj.totaldamage = maxdamage
	proj.centerpellet = true
	local p_rad = FixedMul(wep:get(pt,"pelletradius"), proj.scale)
	local p_hei = FixedMul(wep:get(pt,"pelletheight"), proj.scale)
	
	/*
		  - - -
		x x - x x
		  - - -
	*/
	for i = -2,2
		if i == 0 then continue end
		local frac = FixedDiv((i*FU), 2*FU)
		local ang = FixedMul(spread,frac) - FixedMul(noise, P_RandomFixed())
		local aim = FixedMul(noise, P_RandomFixed())
		
		local proj = Paint:fireWeapon(p,wep, angle, aiming, false, true, ang,aim)
		if not (proj and proj.valid) then continue end
		proj.fired_at = leveltime
		proj.radius = p_rad
		proj.height = p_hei
		proj.totaldamage = maxdamage
		
		--Paint:aimProjectile(p,proj, ang, aim, nil,mom_vec,false,false)
	end
	/*
		  x x x
		- - - - -
		  x x x
	*/
	for i = -1,1
		for j = -1,1,2
			local h_frac = FixedDiv((i*FU), 2*FU)
			local v_frac = FixedDiv((j*FU), 2*FU)
			local ang = FixedMul(spread,h_frac) - FixedMul(noise, P_RandomFixed())
			local aim = FixedMul(spread,v_frac) + FixedMul(noise, P_RandomFixed())
			
			local proj = Paint:fireWeapon(p,wep, angle, aiming, false, true, ang,aim)
			if not (proj and proj.valid) then continue end
			proj.fired_at = leveltime
			proj.radius = p_rad
			proj.height = p_hei
			proj.totaldamage = maxdamage
			
			--Paint:aimProjectile(p,proj, ang, aim, nil,mom_vec,false,false)
		end
	end
end