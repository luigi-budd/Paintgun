local CV = Paint.CV
local MID_X = BASEVIDWIDTH*FU / 2
local MID_Y = BASEVIDHEIGHT*FU / 2
local SCALE = FU
local CRBASE_TRANS = V_10TRANS

local d_raycast, r_raycast, dh_raycast, dh_raycast2 /*"Direct Hit"*/
local function rangecaster(p,me,pt,cur_weapon, dualieflip)
	local workray = r_raycast
	if (dualieflip)
		workray = d_raycast
	end
	if not (workray and workray.valid)
		local angle = p.cmd.angleturn << 16
		local ray = P_SpawnMobjFromMobj(me,
			2*cos(angle), 2*sin(angle),
			41*FixedDiv(P_GetPlayerHeight(p),p.mo.scale)/48 - 8*FU,
			MT_THOK
		)
		ray.flags = $ &~(MF_SLIDEME)
		ray.target = me
		ray.origin = {x = me.x, y = me.y, z = ray.z}
		ray.weapon_id = pt.weapon_id
		local weaponoffset = {Paint:getWeaponOffset(me, angle - ANGLE_90, cur_weapon, dualieflip)}
		if (pt.turretmode and (cur_weapon.guntype == WPT_DUALIES))
			weaponoffset[1],weaponoffset[2] = 0,0
		end
		P_SetOrigin(ray,
			me.x + weaponoffset[1],
			me.y + weaponoffset[2],
			ray.z
		)
		P_InstaThrust(ray, angle, FixedMul(FixedDiv(cur_weapon:get(pt,"range"), cur_weapon:get(pt,"lifespan") * FU), ray.scale))
		ray.finalpos = Paint:aimProjectile(p,ray, angle, p.aiming, false,nil, dualieflip, true)
		
		ray.radius = FixedMul(mobjinfo[MT_PAINT_SHOT].radius, ray.scale)
		ray.height = FixedMul(mobjinfo[MT_PAINT_SHOT].height, ray.scale)
		ray.target = me
		--ray.momx,ray.momy,ray.momz = $1/5, $2/5, $3/5
		ray.sprite = SPR_NULL
		
		if (dualieflip)
			d_raycast = ray
		else
			r_raycast = ray
		end
		workray = ray
	end
	if (workray and workray.valid)
		local ray = workray
		local wep = Paint.weapons[ray.weapon_id]
		
		local range = FixedMul(wep:get(pt,"range"), ray.scale)
		
		for i = 0,25 do
			for j = 0,5
				if P_RailThinker(ray)
					ray.momx,ray.momy,ray.momz = 0,0,0
					ray.fuse = 1
					break
				end
				if not (ray and ray.valid)
					return
				end
			end
			if R_PointTo3DDist(ray.origin.x, ray.origin.y, ray.origin.z, ray.x,ray.y,ray.z) >= range
				ray.momx,ray.momy,ray.momz = 0,0,0
				P_SetOrigin(ray, ray.finalpos.x, ray.finalpos.y, ray.finalpos.z)
				ray.fuse = 1
				break
			end
		end
		ray.fuse = 1
	end
end

local function directhit_blockmap(ray, mo)
	if not (ray and ray.valid) then return end
	if not (mo and mo.valid) then return end
	if not mo.health then return end
	if abs(ray.x - mo.x) > mo.radius + ray.radius
	or abs(ray.y - mo.y) > mo.radius + ray.radius
		return
	end
	if not L_ZCollide(ray,mo) then return end
	
	if Paint_canHurtEnemy(ray.target.player, mo)
	or mo.type == MT_TNTBARREL
		ray.direct = true
		ray.momx,ray.momy,ray.momz = 0,0,0
		ray.fuse = 1
		ray.hit = true
		return
	end
	
	local me = ray.target
	local p = me.player
	
	if mo.type == MT_PLAYER
	and mo ~= me
	and Paint_canHurtPlayer(p, mo.player)
		ray.direct = true
		ray.momx,ray.momy,ray.momz = 0,0,0
		ray.fuse = 1
		ray.hit = true
	end
end
local function raycaster(p,me,pt, cur_weapon, dualieflip)
	local workray = dh_raycast
	if (dualieflip)
		workray = dh_raycast2
	end
	
	if not (workray and workray.valid)
		local angle = p.cmd.angleturn << 16
		local ray = P_SpawnMobjFromMobj(me,
			2*cos(angle), 2*sin(angle),
			41*FixedDiv(P_GetPlayerHeight(p),p.mo.scale)/48 - 8*FU,
			MT_THOK
		)
		ray.flags = $ &~(MF_NOCLIP|MF_NOCLIPTHING|MF_NOBLOCKMAP|MF_SLIDEME)
		ray.target = me
		ray.origin = {x = me.x, y = me.y, z = ray.z}
		ray.weapon_id = pt.weapon_id
		local weaponoffset = {Paint:getWeaponOffset(me, angle - ANGLE_90, cur_weapon, dualieflip)}
		P_SetOrigin(ray,
			me.x + weaponoffset[1],
			me.y + weaponoffset[2],
			ray.z
		)
		P_InstaThrust(ray, angle, FixedMul(FixedDiv(cur_weapon:get(pt,"range"), cur_weapon:get(pt,"lifespan") * FU), ray.scale))
		ray.finalpos = Paint:aimProjectile(p,ray, angle, p.aiming, false,nil,dualieflip, true)
		
		ray.radius = FixedMul(mobjinfo[MT_PAINT_SHOT].radius, ray.scale)
		ray.height = FixedMul(mobjinfo[MT_PAINT_SHOT].height, ray.scale)
		ray.target = me
		ray.momx,ray.momy,ray.momz = $1/5, $2/5, $3/5
		ray.sprite = SPR_NULL
		
		if (dualieflip)
			dh_raycast2 = ray
		else
			dh_raycast = ray
		end
		workray = ray
	end
	if (workray and workray.valid)
		local ray = workray
		local wep = Paint.weapons[ray.weapon_id]
		local doblockmap = Paint.CV.directhit_crosshair.value
		
		local range = FixedMul(wep:get(pt,"range"), ray.scale)
		
		local br = ray.radius + 16*ray.scale
		for i = 0,25 do
			for j = 0,5
				if P_RailThinker(ray)
				or (ray.z + ray.height >= ray.ceilingz or ray.z <= ray.floorz)
				or (ray.momx == 0 and ray.momy == 0)
				and (ray and ray.valid)
					ray.momx,ray.momy,ray.momz = 0,0,0
					ray.fuse = 1
					ray.hit = true
					break 2
				end
				if doblockmap
					local px = ray.x
					local py = ray.y
					searchBlockmap("objects",directhit_blockmap, ray, px-br, px+br, py-br, py+br)
				end
			end
			if not (ray and ray.valid)
				break
			end
			
			if R_PointTo3DDist(ray.origin.x, ray.origin.y, ray.origin.z, ray.x,ray.y,ray.z) >= range
				P_SetOrigin(ray, ray.finalpos.x, ray.finalpos.y, ray.finalpos.z)
				ray.momx,ray.momy,ray.momz = 0,0,0
				ray.fuse = 1
				break
			end
		end
		if ray and ray.valid
			ray.fuse = 1
		end
	end
end

addHook("PostThinkFrame",do
	local p = displayplayer
	if not (p and p.valid) then return end
	if not (p.paint) then return end
	if not (CV.paintguns.value) then return end
	local pt = p.paint
	local me = p.mo
	if not (me and me.valid and me.health) then return end
	local cur_weapon = Paint.weapons[pt.weapon_id]
	if cur_weapon == nil then return end
	
	rangecaster(p,me,pt,cur_weapon, false)
	if (cur_weapon.guntype == WPT_DUALIES)
		rangecaster(p,me,pt,cur_weapon, true)
	end
	
	raycaster(p,me,pt,cur_weapon, false)
	if (cur_weapon.guntype == WPT_DUALIES)
		raycaster(p,me,pt,cur_weapon, true)
	end
end)

local old_fov, old_spreadadd, old_camdist, old_chase
local cv_fov
local cv_camdist
local cross_x,cross_y = 0,0
local interptag = 0
local range_cache = {}
local charger_vfx = 0
local function drawCharger(v,p,cam, dx,dy)
	local pt = p.paint
	local wep = Paint.weapons[pt.weapon_id]
	if wep.guntype == WPT_CHARGER
	and pt.charge
		if pt.charge == wep.chargetime
			charger_vfx = 10
		end
		local progress = FixedDiv(min(pt.charge, wep.chargetime)*FU, wep.chargetime*FU)
		local maxsegs = 50
		local rad = 3
		progress = FixedDiv(FixedMul(360*FU,$), maxsegs*FU)
		for i = 0,maxsegs,1
			local fakeangle = FixedAngle(FixedMul(progress, i*FU)) - ANGLE_90
			
			local x = cross_x + (rad * cos(fakeangle))
			local y = cross_y + (rad * sin(fakeangle))
			v.dointerp(5 + interptag + (i + 1))
			v.drawScaled(x,y,
				FU/5,
				v.cachePatch("PAINT_BALL"), V_20TRANS, v.getColormap(nil,SKINCOLOR_GREY)
			)
		end
		v.dointerp(5 + interptag)
	end
	if charger_vfx
		v.drawScaled(cross_x,cross_y,
			FU,
			v.cachePatch("PAINT_BALL"), (10 - charger_vfx)<<V_ALPHASHIFT, v.getColormap(nil,Paint:getPlayerColor(p))
		)
		charger_vfx = $ - 1
	end
end

local function drawCrosshair(v,p,cam, y, dflip)
	local workray = dh_raycast
	if (dflip)
		workray = dh_raycast2
	end
	if not (workray and workray.valid) then return drawCharger(v,p,cam); end
	if not workray.hit then return drawCharger(v,p,cam); end
	local result = K_GetScreenCoords(v,p,cam, workray, {dontclip = true})
	if not result then return; end
	
	cross_x,cross_y = result.x,result.y
	drawCharger(v,p,cam);
	v.dointerp(6 + interptag)
	v.drawScaled(MID_X,y,FU/4,v.cachePatch("PAINT_CR_BASE"), CRBASE_TRANS)
	v.drawScaled(result.x,result.y,FU/4, v.cachePatch("PAINT_CR_RET"), 0)
	v.drawScaled(result.x,result.y,FU/4, v.cachePatch("PAINT_CR_BLOCKED"), 0, v.getColormap(TC_DEFAULT, Paint:getPlayerColor(p)))
	return true
end
local function crosshairdrawer(v,p,cam, pt, dflip)
	local wep = Paint.weapons[pt.weapon_id]
	interptag = 0
	
	SCALE = FU
	MID_X = 160*FU
	local y = MID_Y
	local workray = r_raycast
	local dh_workray = dh_raycast
	if (dflip)
		workray = d_raycast
		dh_workray = dh_raycast2
		interptag = 4
	end
	if (workray and workray.valid)
		local result = K_GetScreenCoords(v,p,cam, workray, {dontclip = true})
		--if not result.onscreen then return end
		SCALE = result.scale
		MID_X = result.x
		y = result.y
	end
	
	--120 fov == 4 mult
	if (old_fov ~= cv_fov.value)
	or (old_camdist ~= cv_camdist.value)
	or (old_chase ~= cam.chase)
		range_cache = {}
	end
	if wep.guntype == WPT_SHOOTER
	or wep.guntype == WPT_BLASTER
	or (wep.guntype == WPT_DUALIES)
		--local fov_fact = FixedDiv(240*FU - cv_fov.value, 27*FU)
		local fov_fact = 5*FU + (FU/2)
		local range = wep:get(pt,"range")
		local L_hspread, R_hspread
		local B_vspread, T_vspread
		if not (range_cache[range] and range_cache[range][pt.spreadadd])
			L_hspread = -wep.h_spread[1]*FU - pt.spreadadd
			R_hspread = wep.h_spread[2]*FU + pt.spreadadd
			B_vspread = -wep.v_spread[1]*FU
			T_vspread = wep.v_spread[2]*FU
			
			-- Project a "point" out to the very tip of our range
			local t_aim = FixedAngle(T_vspread)
			local b_aim = FixedAngle(B_vspread)
			local ang = 0
			
			local C_point = {x = P_ReturnThrustX(nil, ang, range), y = P_ReturnThrustY(nil, ang, range),
				z = P_ReturnThrustY(nil, 0, range),
			}
			
			-- Left and right point offsets
			ang = FixedAngle(L_hspread)
			local L_point = {x = P_ReturnThrustX(nil, ang, range), y = P_ReturnThrustY(nil, ang, range),
				z = P_ReturnThrustY(nil, t_aim, range),
			}
			ang = FixedAngle(R_hspread)
			local R_point = {x = P_ReturnThrustX(nil, ang, range), y = P_ReturnThrustY(nil, ang, range),
				z = P_ReturnThrustY(nil, b_aim, range)
			}
			
			-- yikes...
			local cam_dist = (cam.chase) and -cv_camdist.value or 0
			local override = {
				angle = 0, aiming = 0, x = P_ReturnThrustX(nil,0,cam_dist), y = P_ReturnThrustY(nil,0,cam_dist), z = 0
			}
			local C_result = K_GetScreenCoords(v,p,cam, {x=C_point.x, y=C_point.y, z=0}, {dontclip = true, viewoverride = override})
			local L_result = K_GetScreenCoords(v,p,cam, {x=L_point.x, y=L_point.y, z=0}, {dontclip = true, viewoverride = override})
			local R_result = K_GetScreenCoords(v,p,cam, {x=R_point.x, y=R_point.y, z=0}, {dontclip = true, viewoverride = override})
			
			L_result = K_GetScreenCoords(v,p,cam, {x=L_point.x, y=L_point.y, z=L_point.z}, {dontclip = true, viewoverride = override})
			R_result = K_GetScreenCoords(v,p,cam, {x=R_point.x, y=R_point.y, z=R_point.z}, {dontclip = true, viewoverride = override})
			local LEFT = abs(L_result.x - C_result.x)
			local RIGHT = abs(R_result.x - C_result.x)
			local TOP = abs(L_result.y - C_result.y)
			local BOT = abs(R_result.y - C_result.y)
			
			-- Left and Right W2Ss are on opposing corners (top-left and bottom-right respectively)
			if range_cache[range] == nil
				range_cache[range] = {
					[pt.spreadadd] = {
						left = -LEFT,
						right = RIGHT,
						top = TOP,
						bottom = -BOT,
						scalefact = C_result.scale
					}
				}
			else
				range_cache[range][pt.spreadadd] = {
					left = -LEFT,
					right = RIGHT,
					top = TOP,
					bottom = -BOT,
					scalefact = C_result.scale
				}
			end
		end
		SCALE = FixedDiv($, range_cache[range][pt.spreadadd].scalefact)
		L_hspread = FixedMul(range_cache[range][pt.spreadadd].left, SCALE)
		R_hspread = FixedMul(range_cache[range][pt.spreadadd].right, SCALE)
		B_vspread = FixedMul(range_cache[range][pt.spreadadd].bottom, SCALE)
		T_vspread = FixedMul(range_cache[range][pt.spreadadd].top, SCALE)
		
		old_fov = cv_fov.value
		old_spreadadd = pt.spreadadd
		old_camdist = cv_camdist.value
		old_chase = cam.chase
		
		local dual = wep.guntype == WPT_DUALIES
		v.dointerp(5 + interptag)
		do
			local suffix = (dh_workray.direct and "H" or (dh_workray.hit and "B" or "N"))
			local clr = v.getColormap(TC_DEFAULT, Paint:getPlayerColor(p))
			if (not dual) or (dual and dflip)
				v.drawScaled(
					MID_X + L_hspread,
					y - T_vspread,
					FU/4, v.cachePatch("PAINT_CR_TOP_"..suffix), 0,
					clr
				)
				v.drawScaled(
					MID_X + L_hspread,
					y - B_vspread,
					FU/4, v.cachePatch("PAINT_CR_BOT_"..suffix), 0,
					clr
				)
			end
			if (not dual) or (dual and not dflip)
				v.drawScaled(
					MID_X + R_hspread,
					y - T_vspread,
					FU/4, v.cachePatch("PAINT_CR_TOP_"..suffix), V_FLIP,
					clr
				)
				v.drawScaled(
					MID_X + R_hspread,
					y - B_vspread,
					FU/4, v.cachePatch("PAINT_CR_BOT_"..suffix), V_FLIP,
					clr
				)
			end
		end
	end
	
	--if cv_crosshair.value == 0 then return end
	cross_x,cross_y = MID_X,y
	local crosshair_result = drawCrosshair(v,p,cam, y, dflip)
	if crosshair_result == -1 then return end
	if not crosshair_result
		v.dointerp(5 + interptag)
		v.drawScaled(MID_X,y,FU/4,v.cachePatch("PAINT_CR_RET"))
		v.drawScaled(MID_X,y,FU/4,v.cachePatch("PAINT_CR_BASE"), CRBASE_TRANS)
	end
	
	if (dh_workray and dh_workray.valid)
	and dh_workray.direct
		v.drawScaled(cross_x,cross_y,FU/2,v.cachePatch("PAINT_CR_HIT"), 0, v.getColormap(nil,Paint:getPlayerColor(p)))
	end
	/*
	if not dflip
		--v.drawString(MID_X, y + 4*FU, ("%.1f%%"):format(pt.spread + wep:get(pt,"spread_base")), 0, "thin-fixed")
		v.drawString(MID_X, y + 4*FU, ("%.1f%%"):format(pt.inktank), 0, "thin-fixed")
	end
	*/
	v.dointerp(false)
end

addHook("HUD",function(v,p,cam)
	v.dointerp = function(id)
		if v.interpolate ~= nil
			v.interpolate(id)
		end
	end
	
	local me = p.mo
	if not (me and me.valid) then return end
	if not Paint:playerIsActive(p) then hud.enable("crosshair"); return end
	local pt = p.paint
	-- if cam.chase then return end
	
	if not me.health then return end
	
	if not cv_fov
		cv_fov = CV_FindVar("fov")
	end
	if not cv_camdist
		cv_camdist = CV_FindVar("cam_dist")
	end
	hud.disable("crosshair")
	
	local wep = Paint.weapons[pt.weapon_id]
	if wep == nil then return end
	
	crosshairdrawer(v,p,cam, pt, false)
	if (wep.guntype == WPT_DUALIES)
		crosshairdrawer(v,p,cam, pt, true)
	end
end,"game")
