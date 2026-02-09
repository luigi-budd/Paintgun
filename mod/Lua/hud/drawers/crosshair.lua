local MID_X = BASEVIDWIDTH*FU / 2
local MID_Y = BASEVIDHEIGHT*FU / 2
local SCALE = FU

local CMD_ANGLE = 0
local CMD_AIMING = 0
local ANGLE_CAP = FixedAngle(70*FU) >> 16
addHook("PlayerCmd",function(p,cmd)
	CMD_ANGLE = cmd.angleturn << 16
	local aiming = cmd.aiming
	if aiming > ANGLE_CAP
		aiming = ANGLE_CAP
	elseif aiming < -ANGLE_CAP
		aiming = -ANGLE_CAP
	end
	CMD_AIMING = aiming << 16
end)

local brella_vfx = 0

local CRBASE_TRANS = V_10TRANS
local CRTYPE_BASEONLY		= 0
local CRTYPE_BLOCKED		= 1
local CRTYPE_DIRECT			= 2
local CRTYPE_STANDBY		= 3
local CRTYPE_CHARGERBASE	= 4
local CRTYPE_BRELLAVFX      = 5
local function drawReticle(v,x,y, p, type)
	local prefix = "PAINT_CR_"
	local wep = Paint.weapons[p.paint.weapon_id]
	local pt = p.paint
	local crossscale = wep:get(pt,"crs_scale")
	
	-- when brella-class loses its shield
	if (wep.guntype == WPT_BRELLA)
	and (pt.shield and pt.shield.valid and pt.shield.paint_hp <= 0 or pt.shieldlost)
		prefix = "PAINT_CROPEN_"
	end
	
	if type == CRTYPE_BASEONLY
		v.drawScaled(x,y, crossscale/4, v.cachePatch(prefix.."BASE"), CRBASE_TRANS)
	elseif type == CRTYPE_BLOCKED
		v.drawScaled(x,y, crossscale/4, v.cachePatch("PAINT_CR_RET"), 0)
		v.drawScaled(x,y, crossscale/4, v.cachePatch(prefix.."BLOCKED"), 0, v.getColormap(TC_DEFAULT, Paint:getPlayerColor(p)))
	elseif type == CRTYPE_DIRECT
		v.drawScaled(x,y, crossscale/4, v.cachePatch(wep.guntype == WPT_CHARGER and "PAINT_CR_CHIT" or "PAINT_CR_HIT"), 0, v.getColormap(nil,Paint:getPlayerColor(p)))		
	elseif type == CRTYPE_STANDBY
		v.drawScaled(x,y, crossscale/4, v.cachePatch("PAINT_CR_RET"))
		v.drawScaled(x,y, crossscale/4, v.cachePatch(prefix.."BASE"), CRBASE_TRANS)
	elseif type == CRTYPE_CHARGERBASE
		v.drawScaled(x,y, crossscale/4, v.cachePatch(prefix.."CBASE"), V_50TRANS)
	elseif type == CRTYPE_BRELLAVFX
		v.drawScaled(x,y, crossscale/4, v.cachePatch("PAINT_CR_BRES"), V_ADD|((10 - brella_vfx)<<V_ALPHASHIFT), v.getColormap(TC_DEFAULT, Paint:getPlayerColor(p)))
	end
end

local d_raycast, r_raycast, dh_raycast, dh_raycast2 /*"Direct Hit"*/
rawset(_G, "local_raycasts", {
	rangecast = nil,
	drangecast = nil,
	hitcast = nil,
	dhitcast = nil
})
-- weapontypes that use bulletsimple
local function is_shooter(type)
	return (
		type == WPT_SHOOTER or
		type == WPT_BRELLA or
		type == WPT_DUALIES or
		type == WPT_BLASTER or
		type == WPT_KATANA
	)
end

local function getrange(ray, pt, cur_weapon, chargerdupe)
	local range = cur_weapon:get(pt,"range")
	if chargerdupe
		range = cur_weapon.range
	end
	
	if is_shooter(type)
		range = FixedMul(cur_weapon:get(pt,"spawnspeed") * cur_weapon:get(pt,"str_tics"), proj.scale)
	end
	
	return range
end

local function rangecaster(p,me,pt,cur_weapon, dualieflip, chargerdupe)
	local workray = r_raycast
	if (dualieflip or chargerdupe)
		workray = d_raycast
	end
	if not (workray and workray.valid)
		local angle = CMD_ANGLE
		local ray = P_SpawnMobjFromMobj(me,
			2*cos(angle), 2*sin(angle),
			41*FixedDiv(p.mo.height,p.mo.scale)/48 - 8*FU,
			MT_THOK
		)
		local range = getrange(ray, pt, cur_weapon, chargerdupe)
		ray.target = me
		ray.weapon_id = pt.weapon_id
		ray.lifespan = 0
		ray.s_state = SS_STRAIGHT
		local weaponoffset = {Paint:getWeaponOffset(me,pt, angle - ANGLE_90, cur_weapon, dualieflip, false)}
		if /*( and (cur_weapon.guntype == WPT_DUALIES))
		or */(cur_weapon.guntype == WPT_BRELLA)
			weaponoffset[1],weaponoffset[2] = 0,0
		end
		local aimoffset_vec = SphereToCartesian(angle,CMD_AIMING)
		local aimoffset_dist = 5 * me.scale
		P_SetOrigin(ray,
			me.x + weaponoffset[1] + FixedMul(aimoffset_dist, aimoffset_vec.x),
			me.y + weaponoffset[2] + FixedMul(aimoffset_dist, aimoffset_vec.y),
			ray.z + FixedMul(aimoffset_dist, aimoffset_vec.z)
		)
		ray.finalpos = Paint:aimProjectile(p,ray, angle, CMD_AIMING, false,nil, dualieflip, true, nil,nil, chargerdupe)
		ray.origin = {x = me.x, y = me.y, z = ray.z}
		local aimvec = SphereToCartesian(ray.angle, CMD_AIMING)
		ray.finalpos.x = ray.x + FixedMul(range, aimvec.x)
		ray.finalpos.y = ray.y + FixedMul(range, aimvec.y)
		ray.finalpos.z = ray.z + FixedMul(range, aimvec.z)
		ray.range = range
		ray.baseangle = angle
		ray.turret = pt.turretmode
		
		ray.radius = FixedMul(mobjinfo[MT_PAINT_SHOT].radius, ray.scale)
		ray.height = FixedMul(mobjinfo[MT_PAINT_SHOT].height, ray.scale)
		ray.flags = mobjinfo[MT_PAINT_SHOT].flags|MF_NOCLIP|MF_NOCLIPHEIGHT &~MF_SLIDEME
		ray.target = me
		ray.sprite = SPR_NULL
		
		ray.str_tics			= cur_weapon:get(pt,"str_tics")
		ray.str2brk_maxspeed	= FixedMul(cur_weapon:get(pt,"str2brk_maxspeed"), ray.scale)
		ray.brk_airresist		= cur_weapon:get(pt,"brk_airresist")
		ray.brk_gravity			= cur_weapon:get(pt,"brk_gravity")
		ray.brk2fre_minz		= FixedMul(cur_weapon:get(pt,"brk2fre_minz"), ray.scale)
		ray.brk2fre_minxy		= FixedMul(cur_weapon:get(pt,"brk2fre_minxy"), ray.scale)
		ray.brk2fre_tics		= cur_weapon:get(pt,"brk2fre_tics")
		ray.fre_airresist		= cur_weapon:get(pt,"fre_airresist")
		ray.fre_gravity			= cur_weapon:get(pt,"fre_gravity")
		ray.crs_guideframe		= cur_weapon:get(pt,"crs_guideframe")
		
		if (dualieflip or chargerdupe)
			d_raycast = ray
			local_raycasts.drangecast = ray
		else
			r_raycast = ray
			local_raycasts.rangecast = ray
		end
		workray = ray
	end
	if (workray and workray.valid)
		local ray = workray
		local range = ray.range
		
		if is_shooter(Paint.weapons[ray.weapon_id].guntype)
			while true
				ray.lifespan = $ + 1
				if (ray.lifespan >= ray.crs_guideframe)
				or (ray.turret and ray.s_state ~= SS_STRAIGHT)
					ray.momx,ray.momy,ray.momz = 0,0,0
					ray.fuse = 1
					break
				else
					Paint.bulletSimpleState(ray)
					P_RailThinker(ray)
				end
				
				/*
				local g = P_SpawnMobjFromMobj(ray, 0,0,0,MT_THOK)
				g.scale = $ / 4
				g.fuse = 1
				g.tics = 1
				g.frame = $ &~FF_TRANSMASK
				g.alpha = FU * 3/4
				if (ray.s_state == SS_STRAIGHT)
					g.color = SKINCOLOR_EMERALD
				elseif (ray.s_state == SS_BRAKE)
					g.color = SKINCOLOR_RED
				else
					g.color = SKINCOLOR_YELLOW
				end
				P_SetOrigin(g, g.x,g.y,g.z)
				*/
			end
		else
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
	or mo.paint_forcehit
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
		local angle = CMD_ANGLE
		local ray = P_SpawnMobjFromMobj(me,
			2*cos(angle), 2*sin(angle),
			41*FixedDiv(p.mo.height,p.mo.scale)/48 - 8*FU,
			MT_THOK
		)
		local range = getrange(ray, pt, cur_weapon, false)
		ray.flags = $ &~(MF_NOCLIP|MF_NOCLIPTHING|MF_NOBLOCKMAP|MF_SLIDEME)
		ray.target = me
		ray.weapon_id = pt.weapon_id
		ray.lifespan = 0
		ray.s_state = SS_STRAIGHT
		local weaponoffset = {Paint:getWeaponOffset(me,pt, angle - ANGLE_90, cur_weapon, dualieflip, false)}
		if (cur_weapon.guntype == WPT_BRELLA)
			weaponoffset[1],weaponoffset[2] = 0,0
		end
		P_SetOrigin(ray,
			me.x + weaponoffset[1],
			me.y + weaponoffset[2],
			ray.z
		)
		ray.finalpos = Paint:aimProjectile(p,ray, angle, CMD_AIMING, false,nil,dualieflip, true)
		ray.origin = {x = me.x, y = me.y, z = ray.z}
		local aimvec = SphereToCartesian(angle, CMD_AIMING)
		ray.finalpos.x = ray.x + FixedMul(range, aimvec.x)
		ray.finalpos.y = ray.y + FixedMul(range, aimvec.y)
		ray.finalpos.z = ray.z + FixedMul(range, aimvec.z)
		ray.range = range
		ray.baseangle = angle
		
		ray.radius = FixedMul(mobjinfo[MT_PAINT_SHOT].radius, ray.scale)
		ray.height = FixedMul(mobjinfo[MT_PAINT_SHOT].height, ray.scale)
		ray.target = me
		if not is_shooter(cur_weapon.guntype)
			ray.momx,ray.momy,ray.momz = $1/5, $2/5, $3/5
		end
		ray.sprite = SPR_NULL
		
		ray.str_tics			= cur_weapon:get(pt,"str_tics")
		ray.str2brk_maxspeed	= FixedMul(cur_weapon:get(pt,"str2brk_maxspeed"), ray.scale)
		ray.brk_airresist		= cur_weapon:get(pt,"brk_airresist")
		ray.brk_gravity			= cur_weapon:get(pt,"brk_gravity")
		ray.brk2fre_minz		= FixedMul(cur_weapon:get(pt,"brk2fre_minz"), ray.scale)
		ray.brk2fre_minxy		= FixedMul(cur_weapon:get(pt,"brk2fre_minxy"), ray.scale)
		ray.brk2fre_tics		= cur_weapon:get(pt,"brk2fre_tics")
		ray.fre_airresist		= cur_weapon:get(pt,"fre_airresist")
		ray.fre_gravity			= cur_weapon:get(pt,"fre_gravity")
		ray.crs_guideframe		= cur_weapon:get(pt,"crs_guideframe")

		if (dualieflip)
			dh_raycast2 = ray
			local_raycasts.dhitcast = ray
		else
			dh_raycast = ray
			local_raycasts.hitcast = ray
		end
		workray = ray
	end
	if (workray and workray.valid)
		local ray = workray
		local doblockmap = Paint.CV.directhit_crosshair.value
		local accurate = Paint.CV.directhit_crosshair.value == 1
		local range = ray.range
		local br = ray.radius + 16*ray.scale

		if is_shooter(Paint.weapons[ray.weapon_id].guntype)
			while true
				ray.lifespan = $ + 1
				Paint.bulletSimpleState(ray)
				
				if doblockmap
					local px = ray.x
					local py = ray.y
					searchBlockmap("objects",directhit_blockmap, ray, px-br, px+br, py-br, py+br)
				end
				
				if P_RailThinker(ray)
				or (ray.z + ray.height >= ray.ceilingz or ray.z <= ray.floorz)
				or (ray.momx == 0 and ray.momy == 0)
				and (ray and ray.valid)
					ray.momx,ray.momy,ray.momz = 0,0,0
					ray.fuse = 1
					ray.hit = true
					break
				end
				
				if (ray.lifespan >= ray.crs_guideframe)
					ray.momx,ray.momy,ray.momz = 0,0,0
					ray.fuse = 1
					break
				end
			end
		else
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
					if accurate and doblockmap
						local px = ray.x
						local py = ray.y
						searchBlockmap("objects",directhit_blockmap, ray, px-br, px+br, py-br, py+br)
					end
				end
				if doblockmap
					local px = ray.x
					local py = ray.y
					searchBlockmap("objects",directhit_blockmap, ray, px-br, px+br, py-br, py+br)
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
		end
		if ray and ray.valid
			ray.momx,ray.momy,ray.momz = 0,0,0
			ray.fuse = 1
		end
	end
end

addHook("PostThinkFrame",do
	local p = displayplayer
	if not (p and p.valid) then return end
	if not (p.paint) then return end
	if not Paint:playerIsActive(p) then return end
	local pt = p.paint
	local me = p.mo
	if not (me and me.valid and me.health) then return end
	local cur_weapon = Paint.weapons[pt.weapon_id]
	if cur_weapon == nil then return end
	
	if (p ~= consoleplayer)
		CMD_ANGLE = p.cmd.angleturn << 16
		CMD_AIMING = p.aiming
	end
	
	rangecaster(p,me,pt,cur_weapon, false)
	if (cur_weapon.guntype == WPT_DUALIES)
		rangecaster(p,me,pt,cur_weapon, true)
	elseif (cur_weapon.guntype == WPT_CHARGER)
		rangecaster(p,me,pt,cur_weapon, false, true)
	end
	
	raycaster(p,me,pt,cur_weapon, false)
	if (cur_weapon.guntype == WPT_DUALIES)
		raycaster(p,me,pt,cur_weapon, true)
	end
end)

local old_fov, old_spreadadd, old_camdist, old_chase, old_scale, old_weapon
local cv_fov
local cv_camdist
local cross_x,cross_y = 0,0
local interptag = 0
local range_cache = {}
local charger_vfx = 0
local function drawWeaponEVFX(v,p,cam)
	local pt = p.paint
	local wep = Paint.weapons[pt.weapon_id]
	local crossscale = wep:get(pt,"crs_scale")
	
	if charger_vfx
		v.drawScaled(cross_x,cross_y,
			crossscale,
			v.cachePatch("PAINT_BALL"), (10 - charger_vfx)<<V_ALPHASHIFT, v.getColormap(nil,Paint:getPlayerColor(p))
		)
		charger_vfx = $ - 1
	end
	if wep.guntype == WPT_CHARGER
	and (pt.charge or pt.storedcharge)
		local chargetime = wep:get(pt,"chargetime")
		if pt.justcharged
			charger_vfx = 10
		end
		local progress = FixedDiv(min(max(pt.charge, pt.storedcharge), chargetime), chargetime)
		local maxsegs = 50
		local rad = 3
		progress = FixedDiv(FixedMul(360*FU,$), maxsegs*FU)
		for i = 0,maxsegs,1
			local fakeangle = FixedAngle(FixedMul(progress, i*FU)) - ANGLE_90
			
			local x = cross_x + (rad * cos(fakeangle))
			local y = cross_y + (rad * sin(fakeangle))
			v.dointerp(5 + interptag + (i + 1))
			v.drawScaled(x,y,
				crossscale/5,
				v.cachePatch("PAINT_BALL"), V_20TRANS, v.getColormap(nil,SKINCOLOR_GREY)
			)
		end
		v.dointerp(5 + interptag)
	elseif wep.guntype == WPT_BRELLA
		if pt.shieldjustregened
			brella_vfx = 10
		end
		
		if brella_vfx
			drawReticle(v, cross_x,cross_y, p, CRTYPE_BRELLAVFX)
			brella_vfx = $ - 1
		end
	end
end

local function drawCrosshair(v,p,cam, y, dflip)
	local workray = dh_raycast
	if (dflip)
		workray = dh_raycast2
	end
	if not (workray and workray.valid) then return drawWeaponEVFX(v,p,cam); end
	if not workray.hit then return drawWeaponEVFX(v,p,cam); end
	local result = K_GetScreenCoords(v,p,cam, workray, {dontclip = true})
	if not result then return; end
	
	local pt = p.paint
	cross_x,cross_y = result.x,result.y
	v.dointerp(6 + interptag)
	
	drawReticle(v, MID_X,y, p, CRTYPE_BASEONLY)
	drawWeaponEVFX(v,p,cam);
	drawReticle(v, result.x,result.y, p, CRTYPE_BLOCKED)
	
	return true
end
local function crosshairdrawer(v,p,cam, pt, dflip, chargerdupe)
	local wep = Paint.weapons[pt.weapon_id]
	interptag = 0
	
	SCALE = FU
	MID_X = 160*FU
	local y = MID_Y
	local workray = r_raycast
	local dh_workray = dh_raycast
	if (dflip or chargerdupe)
		workray = d_raycast
		dh_workray = dh_raycast2
		interptag = 4
	end
	if (workray and workray.valid)
		local result = K_GetScreenCoords(v,p,cam, workray, {dontclip = true})
		--if not result.onscreen then return end
		SCALE = FixedDiv(result.scale, p.realmo.scale)
		MID_X = result.x
		y = result.y
	end
	local crossscale = wep:get(pt,"crs_scale")
	SCALE = FixedMul($, crossscale)
	
	--120 fov == 4 mult
	if (old_fov ~= cv_fov.value + p.fovadd)
	or (old_camdist ~= cv_camdist.value)
	or (old_chase ~= cam.chase)
	or (old_scale ~= p.mo.scale)
	or (old_weapon ~= pt.weapon_id)
		range_cache = {}
	end
	if (wep.guntype == WPT_SHOOTER)
	or (wep.guntype == WPT_BLASTER)
	or (wep.guntype == WPT_DUALIES)
	or (wep.guntype == WPT_BRELLA)
	or (wep.guntype == WPT_KATANA)
		local range = getrange(p.realmo, pt, wep, false)
		if (is_shooter(wep.guntype))
		and (workray and workray.valid)
			local o = workray.origin
			range = R_PointTo3DDist(
				o.x,o.y,o.z, workray.x,workray.y,workray.z
			)
		end
		
		local L_hspread, R_hspread
		local B_vspread, T_vspread
		if not (range_cache[range] and range_cache[range][pt.spreadadd])
			L_hspread = -wep.h_spread[1] - pt.spreadadd
			R_hspread = wep.h_spread[2] + pt.spreadadd
			B_vspread = -wep.v_spread[1]
			T_vspread = wep.v_spread[2]
			local scale = p.mo.scale
			L_hspread = FixedMul($, scale)
			R_hspread = FixedMul($, scale)
			B_vspread = FixedMul($, scale)
			T_vspread = FixedMul($, scale)
			
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
			local centered = false --not cam.chase
			local override = {
				angle = 0, aiming = 0, x = P_ReturnThrustX(nil,0,cam_dist), y = P_ReturnThrustY(nil,0,cam_dist), z = 0
			}
			local C_result = K_GetScreenCoords(v,p,cam, {x=C_point.x, y=C_point.y, z=0}, {dontclip = true, viewoverride = override, centered = centered})
			local L_result = K_GetScreenCoords(v,p,cam, {x=L_point.x, y=L_point.y, z=0}, {dontclip = true, viewoverride = override, centered = centered})
			local R_result = K_GetScreenCoords(v,p,cam, {x=R_point.x, y=R_point.y, z=0}, {dontclip = true, viewoverride = override, centered = centered})
			
			L_result = K_GetScreenCoords(v,p,cam, {x=L_point.x, y=L_point.y, z=L_point.z}, {dontclip = true, viewoverride = override, centered = centered})
			R_result = K_GetScreenCoords(v,p,cam, {x=R_point.x, y=R_point.y, z=R_point.z}, {dontclip = true, viewoverride = override, centered = centered})
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
		
		old_fov = cv_fov.value + p.fovadd
		old_spreadadd = pt.spreadadd
		old_camdist = cv_camdist.value
		old_chase = cam.chase
		old_scale = p.mo.scale
		old_weapon = pt.weapon_id
		
		local dual = wep.guntype == WPT_DUALIES
		v.dointerp(5 + interptag)
		local clr = v.getColormap(TC_DEFAULT, Paint:getPlayerColor(p))
		if (wep.guntype ~= WPT_KATANA)
			local suffix = (dh_workray.direct and "H" or (dh_workray.hit and "B" or "N"))
			local prefix = (wep.guntype == WPT_BRELLA) and "PAINT_CR_B_" or "PAINT_CR_S_"
			if (not dual) or (dual and dflip)
				v.drawScaled(
					MID_X + L_hspread,
					y - T_vspread,
					crossscale/4, v.cachePatch(prefix.."TOP_"..suffix), 0,
					clr
				)
				v.drawScaled(
					MID_X + L_hspread,
					y - B_vspread,
					crossscale/4, v.cachePatch(prefix.."BOT_"..suffix), 0,
					clr
				)
			end
			if (not dual) or (dual and not dflip)
				v.drawScaled(
					MID_X + R_hspread,
					y - T_vspread,
					crossscale/4, v.cachePatch(prefix.."TOP_"..suffix), V_FLIP,
					clr
				)
				v.drawScaled(
					MID_X + R_hspread,
					y - B_vspread,
					crossscale/4, v.cachePatch(prefix.."BOT_"..suffix), V_FLIP,
					clr
				)
			end
		else
			local prefix = "PAINT_CR_K_"
			local suffix = (dh_workray.direct and "B" or "N")
			local sections = 3
			local pad = 4 * SCALE
			local l_sprd = min(FixedDiv(L_hspread, sections*FU) + pad, 0)
			local r_sprd = max(FixedDiv(R_hspread, sections*FU) - pad, 0)
			for i = 1, sections
				v.drawScaled(
					MID_X - pad + (l_sprd * i),
					y,
					crossscale/4, v.cachePatch(prefix.."UNC_"..suffix), V_FLIP,
					clr
				)
				v.drawScaled(
					MID_X + pad + (r_sprd * i),
					y,
					crossscale/4, v.cachePatch(prefix.."UNC_"..suffix), V_FLIP,
					clr
				)
			end
		end
	end
	
	--if cv_crosshair.value == 0 then return end
	if chargerdupe
		v.dointerp(6 + interptag)
		drawReticle(v,MID_X,y, p, CRTYPE_CHARGERBASE)
		v.dointerp(false)
		return
	end
	
	cross_x,cross_y = MID_X,y
	local crosshair_result = drawCrosshair(v,p,cam, y, dflip)
	if not crosshair_result
		v.dointerp(5 + interptag)
		drawReticle(v,MID_X,y, p, CRTYPE_STANDBY)
	end
	
	if (dh_workray and dh_workray.valid)
	and dh_workray.direct
		drawReticle(v, cross_x,cross_y, p, CRTYPE_DIRECT)
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
	if pt.aimingsub then return end
	if pt.disable.main then return end
	
	crosshairdrawer(v,p,cam, pt, false, wep.guntype == WPT_CHARGER)
	if (wep.guntype == WPT_DUALIES)
		crosshairdrawer(v,p,cam, pt, true)
	elseif (wep.guntype == WPT_CHARGER)
		crosshairdrawer(v,p,cam, pt, false, false)
	end
end,"game")