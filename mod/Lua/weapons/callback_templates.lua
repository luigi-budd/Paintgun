function Paint.wcallback_brella_onfire(p,pt,wep, proj, mom_vec, angle, aiming, dospread, doaiming)
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