freeslot("S_PAINT_GUN_TEST")
states[S_PAINT_GUN_TEST] = {
	sprite = SPR_PAINT_GUN,
	frame = 5,
	tics = -1,
	nextstate = S_PAINT_GUN_TEST
}

Paint:registerWeapon({
	name = "basic",
	handoffset = 8*FU,
	h_spread = {6, 6},
	v_spread = {4, 4},
	damage = 35*FU,
	inkcost = FU * 92/100,
	
	weaponstate = S_PAINT_GUN_TEST,
	weaponstate_scale = FU/2,
	
	/*
	firerate = 2,
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
			
			local proj = Paint:fireWeapon(p,wep, angle, false)
			pt.shotsfired = $ - 1
			if not proj then return end
			
			Paint:aimProjectile(p,proj, angle,aim, false,mom_vec,false,false)
		end
	}
	*/
})
