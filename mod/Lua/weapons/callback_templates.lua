function Paint.wcallback_brella_onfire(p,pt,wep, proj, mom_vec, angle, aiming, dospread, doaiming)
	local maxdamage = wep:get(pt,"totaldamage")
	
	proj.fired_at = leveltime
	proj.totaldamage = maxdamage
	proj.centerpellet = true
	local p_rad = FixedMul(wep:get(pt,"pelletradius"), proj.scale)
	local p_hei = FixedMul(wep:get(pt,"pelletheight"), proj.scale)
	
	local groups = wep:get(pt,"groups")
	for i = 1, wep:get(pt,"groupnum")
		local info = groups[i]
		
		local totalnum = info.numprojs
		local hadj = FixedDiv(info.h_degree, (totalnum*FU)/2)
		for j = 1, totalnum
			local ang = FixedMul(info.h_noise * 3, P_RandomFixedSigned())
			local adjust = hadj * ((j <= totalnum/2) and j or -((totalnum/2) - j))
			ang = $ - (-info.h_degree/2 + adjust) + hadj/2
			
			local aim = FixedMul(info.v_noise * 6, P_RandomFixedSigned())
			if j <= totalnum/2
				aim = $ - info.v_degree
			else
				aim = $ + info.v_degree
			end
			
			local proj = Paint:fireWeapon(p,wep, angle, aiming, false, true, ang,aim)
			if not (proj and proj.valid) then continue end
			proj.fired_at = leveltime
			proj.radius = p_rad
			proj.height = p_hei
			proj.totaldamage = maxdamage
		end
	end
end

local whiff_scale = tofixed("1.8")
function Paint.wcallback_splatana_onfire(p,pt,wep, baseproj, mom_vec, angle, aiming, dospread, doaiming, newpos)
	local me = p.realmo
	pt.swinganim = Paint.SWING_ANIM + max(wep:get(pt,"firerate") - Paint.SWING_ANIM, 0) * 3
	pt.swingoffset = pt.swinganim - Paint.SWING_ANIM
	
	-- melee hitbox
	local mradius = FixedMul(wep:get(pt,"melee_radius"), me.scale)
	local mheight = FixedMul(wep:get(pt,"melee_height"), me.scale)
	local mdamage = wep:get(pt,"melee_damage")
	print(mdamage/FU)
	
	local mdist = FixedDiv(me.radius, me.scale) + mradius
	local mzoff = FixedDiv(me.height,me.scale)/2 - (mheight/2)
	
	local melee = P_SpawnMobjFromMobj(me,
		P_ReturnThrustX(nil,angle,mdist) + FixedDiv(me.momx, me.scale),
		P_ReturnThrustY(nil,angle,mdist) + FixedDiv(me.momy, me.scale),
		mzoff,
		MT_RAY
	)
	melee.radius = mradius
	melee.height = mheight
	melee.target = me
	melee.color = baseproj.color
	melee.pellet = true -- hack for smaller hitmarker
	melee.powerful = pt.maxchargeshot -- hack again
	local fakerange = mradius * 4
	local range = melee.radius
	local gravflip = P_MobjFlip(me)
	searchBlockmap("objects", function(ref, found)
		if found == me then return end
		if R_PointToDist2(found.x, found.y, melee.x, melee.y) > range + found.radius
			return
		end
		if not L_ZCollide(found,melee) then return end
		if not (found.health) then return end
		if not P_CheckSight(me,found) then return end
		
		if (found.type == MT_TNTBARREL)
		or Paint_canHurtEnemy(p, found)
			P_DamageMobj(found, melee, me, mdamage)
			Paint:doProjHitmarker(melee, found, false, false, true)
			Paint.HUD:damageNumber(p, found, mdamage)
			found.hitbymelee = true
			found.hitmeleetic = leveltime
		elseif (found.type == MT_PLAYER)
			if Paint_canHurtPlayer(p, found.player)
				local newdamage = Paint:damagePlayer(found.player, melee, p, mdamage)
				Paint:playHurtSound(found.player)
				Paint:doProjHitmarker(melee, found, false, true)
				Paint.HUD:damageNumber(p, found, newdamage)
				found.hitbymelee = true
				found.hitmeleetic = leveltime
			elseif Paint_canHurtPlayer(p, found.player, true, true)
			and not Paint:isFriendlyFire(p,found.player)
				Paint:doProjHitmarker(melee, found, false, true, true)
			end
		end
	end, 
		melee,
		melee.x-fakerange, melee.x+fakerange,
		melee.y-fakerange, melee.y+fakerange
	)
	local fx = P_SpawnMobjFromMobj(me,0,0,0, MT_PAINT_GUN)
	P_SetOrigin(fx, melee.x,melee.y,melee.z)
	fx.zoff = melee.z - me.z
	fx.target = me
	fx.state = S_PAINT_WHIFF
	fx.color = baseproj.color
	fx.angle = angle
	fx.aiming = aiming
	fx.scale = FixedMul(FixedDiv(mradius, 64*me.scale), whiff_scale)
	fx.renderflags = $|RF_NOSPLATBILLBOARD|RF_SLOPESPLAT|(pt.shotsfired % 2 and RF_HORIZONTALFLIP or 0)
	fx.maxchargeshot = pt.maxchargeshot
	P_CreateFloorSpriteSlope(fx)
	
	local maxdamage = wep:get(pt,"totaldamage")
	baseproj.fired_at = leveltime
	baseproj.totaldamage = maxdamage
	baseproj.centerpellet = true
	baseproj.groupmembers = {}
	
	baseproj.flags = $|MF_NOBLOCKMAP
	baseproj.radius = FixedMul(wep:get(pt,"c_radius"), baseproj.scale)
	if not (baseproj and baseproj.valid) then return end
	baseproj.height = FixedMul(wep:get(pt,"c_height"), baseproj.scale)
	if not (baseproj and baseproj.valid) then return end
	
	local spawned = {}
	local vertical = false --pt.maxchargeshot
	
	local side = angle + ANGLE_90
	local groups = wep:get(pt,"groups")
	for i = 1, wep:get(pt,"groupnum")
		local info = groups[i]
		
		local p_rad = FixedMul(info.radius, baseproj.scale)
		local p_hei = FixedMul(info.height, baseproj.scale)
		local offset = FixedMul(info.offset, baseproj.scale) + p_rad
		
		for j = -1,1, 2
			local proj = Paint:fireWeapon(p,wep, angle, aiming, false, true)
			if not (proj and proj.valid) then continue end
			proj.fired_at = leveltime
			proj.radius = p_rad
			proj.height = p_hei
			proj.totaldamage = maxdamage
			
			proj.momx = baseproj.momx
			proj.momy = baseproj.momy
			proj.momz = baseproj.momz
			proj.groupmembers = {baseproj}
			if info.state ~= nil
				proj.state = info.state
			end
			-- the projectile on the left is mirrored
			proj.mirrored = j == 1
			
			if vertical
				P_SetOrigin(proj,
					newpos.x + P_ReturnThrustX(nil,side, offset * j),
					newpos.y + P_ReturnThrustY(nil,side, offset * j),
					newpos.z + (baseproj.height - proj.height)/2
				)
			else
				proj.spriteyoffset = -(baseproj.height - proj.height)/2
				P_SetOrigin(proj,
					newpos.x + P_ReturnThrustX(nil,side, offset * j),
					newpos.y + P_ReturnThrustY(nil,side, offset * j),
					newpos.z + (baseproj.height - proj.height)/2
				)
			end
			table.insert(baseproj.groupmembers, proj)
			table.insert(spawned, proj)
		end
	end
	
	for k, proj in ipairs(spawned)
		if not (proj and proj.valid) then continue end
		for _, p in ipairs(spawned)
			if p == proj then continue end
			table.insert(proj.groupmembers, p)
		end
	end
	baseproj.flags = $ &~MF_NOBLOCKMAP
end

function Paint.wcallback_splatana_ondryfire(p,pt,wep, angle, aiming, dospread, doaiming)
	local me = p.realmo
	pt.swinganim = Paint.SWING_ANIM + max(wep:get(pt,"firerate") - Paint.SWING_ANIM, 0) * 3
	pt.swingoffset = pt.swinganim - Paint.SWING_ANIM
	
	local mradius = FixedMul(wep:get(pt,"melee_radius"), me.scale)
	local mheight = FixedMul(wep:get(pt,"melee_height"), me.scale)
	
	local mdist = FixedDiv(me.radius, me.scale) + mradius
	local mzoff = FixedDiv(me.height,me.scale)/2 - (mheight/2)
	
	local melee = P_SpawnMobjFromMobj(me,
		P_ReturnThrustX(nil,angle,mdist) + FixedDiv(me.momx, me.scale),
		P_ReturnThrustY(nil,angle,mdist) + FixedDiv(me.momy, me.scale),
		mzoff,
		MT_RAY
	)
	melee.radius = mradius
	melee.height = mheight
	melee.target = me
	melee.color = me.color
	
	local fx = P_SpawnMobjFromMobj(me,0,0,0, MT_PAINT_GUN)
	P_SetOrigin(fx, melee.x,melee.y,melee.z)
	fx.zoff = melee.z - me.z
	fx.target = me
	fx.state = S_PAINT_WHIFF
	fx.color = me.color
	fx.angle = angle
	fx.aiming = aiming
	fx.scale = FixedMul(FixedDiv(mradius, 64*me.scale), whiff_scale)
	fx.renderflags = $|RF_NOSPLATBILLBOARD|RF_SLOPESPLAT|(pt.shotsfired % 2 and RF_HORIZONTALFLIP or 0)
	fx.translation = "Grayscale"
	fx.alpha = FU/2
	fx.maxchargeshot = pt.maxchargeshot
	P_CreateFloorSpriteSlope(fx)
end

function Paint.wcallback_splatana_onhit(p,pt,wep, proj, inf, target, damage)
	if not (proj and proj.valid) then return end
	if proj.groupmembers == nil then return end
	for k, gproj in ipairs(proj.groupmembers)
		if not (gproj and gproj.valid) then continue end
		gproj.nohitmarker = true
	end
	/*
	if target.hitbymelee
	and abs(leveltime - target.hitmeleetic) <= 2
		Paint:doProjHitmarker(proj, target, false, false, false, true)
	end
	*/
end