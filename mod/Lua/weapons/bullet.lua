local CV = Paint.CV

freeslot("MT_PAINT_SHOT", "S_PAINT_SHOT", "S_PAINT_SHOT_BIG", "SPR_PAINT_SHOT")
states[S_PAINT_SHOT] = {
	sprite = SPR_PAINT_SHOT,
	frame = A,
	tics = -1,
	nextstate = S_PAINT_SHOT
}
states[S_PAINT_SHOT_BIG] = {
	sprite = SPR_PAINT_SHOT,
	frame = 5|FF_FULLBRIGHT,
	tics = -1,
	nextstate = S_PAINT_SHOT_BIG
}
mobjinfo[MT_PAINT_SHOT] = {
	doomednum = -1,
	radius = 16*FU,
	height = 24*FU,
	flags = MF_NOGRAVITY,
	spawnstate = S_PAINT_SHOT
}
freeslot("MT_PAINT_GUN", "S_PAINT_GUN", "SPR_PAINT_GUN")
states[S_PAINT_GUN] = {
	sprite = SPR_PAINT_GUN,
	frame = A,
	tics = -1,
	nextstate = S_PAINT_GUN
}
mobjinfo[MT_PAINT_GUN] = {
	doomednum = -1,
	radius = 16*FU,
	height = 24*FU,
	flags = MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOCLIPTHING|MF_NOBLOCKMAP,
	spawnstate = S_PAINT_GUN
}
freeslot("MT_PAINT_SPLATTER", "MT_PAINT_WALLSPLAT", "S_PAINT_SPLATTER")
states[S_PAINT_SPLATTER] = {
	sprite = SPR_PAINT_SHOT,
	frame = C,
	tics = -1,
	nextstate = S_PAINT_SPLATTER
}
local REAL_SPLATRAD = 38*FU
mobjinfo[MT_PAINT_SPLATTER] = {
	doomednum = -1,
	radius = 3*FU,
	height = 2*FU,
	flags = MF_SPECIAL,
	spawnstate = S_PAINT_SPLATTER,
	spawnhealth = 1,
	deathstate = S_PAINT_SPLATTER,
}
mobjinfo[MT_PAINT_WALLSPLAT] = {
	doomednum = -1,
	radius = 38*FU,
	height = 2*FU,
	flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOCLIPTHING|MF_NOGRAVITY,
	spawnstate = S_PAINT_SPLATTER,
	spawnhealth = 1,
	deathstate = S_PAINT_SPLATTER,
}

local function splattersound(shot)
	local sfx = P_SpawnGhostMobj(shot)
	sfx.flags2 = $|MF2_DONTDRAW
	sfx.fuse = 2 * TR; sfx.tics = sfx.fuse
	local sound = P_RandomRange(sfx_pn_sp0,sfx_pn_sp8)
	S_StartSound(sfx, sound)
	if not shot.trail
		S_StartSound(sfx, sound)
	end
	
	local wep = Paint.weapons[shot.weapon_id]
	if wep == WPT_BLASTER
		local sound = wep.explode_sounds[P_RandomRange(1,#wep.explode_sounds)]
		S_StartSound(sfx, sound)
		S_StartSound(sfx, sound)
	end
end

function Paint:doProjHitmarker(shot, mo, splatter, nullify)
	local hitmarker
	if nullify
		hitmarker = P_RandomRange(sfx_pnt_n0,sfx_pnt_n5)
	else
		hitmarker = P_RandomRange(sfx_pnt_h0,sfx_pnt_h5)
	end
	
	S_StartSound(nil, hitmarker, shot.target.player)
	S_StartSoundAtVolume(nil, hitmarker, 255/2, shot.target.player) --Bruh
	
	if nullify then return end
	
	if splatter
		splattersound(shot)
	end
	
	local range = 6
	local pos = {
		x = shot.x + P_RandomRange(-range,range)*FU,
		y = shot.y + P_RandomRange(-range,range)*FU,
		z = shot.z + shot.height/2,
	}
	
	Paint.HUD:hitMarker(shot.target.player, pos, FixedAngle(P_RandomRange(0,230)*FU), P_RandomRange(FU * 4/5, FU * 7/4), shot.powerful)
	/*
	local spr_scale = FU/4 + P_RandomFixedSigned() / 4
	local tntstate = S_TNTBARREL_EXPL3
	local rflags = RF_FULLBRIGHT|RF_NOCOLORMAPS
	local fx = P_SpawnMobj(
		shot.x + P_RandomRange(-16,16)*FU,
		shot.y + P_RandomRange(-16,16)*FU,
		shot.z + P_RandomRange(-16,16)*FU,
		MT_THOK
	)
	P_SetMobjStateNF(fx, tntstate)
	fx.spritexscale = FixedMul($, spr_scale)
	fx.spriteyscale = fx.spritexscale
	fx.renderflags = $|rflags &~RF_PAPERSPRITE
	fx.frame = $ &~FF_PAPERSPRITE
	fx.color = shot.color
	fx.colorized = true
	fx.drawonlyforplayer = shot.target.player
	fx.dispoffset = 300
	*/
end

local function SetSplatSkew(splat,slope,skew)
	skew.o = {
		x = splat.x,
		y = splat.y,
		z = splat.floorz,
	}
	skew.xydirection = slope.xydirection
	skew.zdelta = slope.zdelta
	skew.zangle = slope.zangle
	--P_SetOrigin(splat, splat.x,splat.y,splat.z)
end
local function HandleFloorSplat(shot)
	if shot.z + shot.height >= shot.ceilingz
	or shot.z <= shot.floorz
		local ceil = shot.z+shot.height >= shot.ceilingz
		
		local bull_z = ceil and shot.ceilingz - 1 or shot.floorz + 1
		do
			local hole = P_SpawnMobjFromMobj(shot, 0,0,0, MT_PAINT_SPLATTER)			
			hole.renderflags = $|RF_FLOORSPRITE|RF_NOSPLATBILLBOARD|RF_SLOPESPLAT
			hole.color = shot.color
			hole.mirrored = P_RandomChance(FU/2)
			hole.spritexscale = ($ * 5/2) + P_RandomFixed()/5
			hole.spriteyscale = hole.spritexscale
			hole.angle = shot.angle
			hole.scale = $ * 5/4
			if CV.splatter_lifetime.value == -1
				hole.fuse = -1
			else
				hole.fuse = CV.splatter_lifetime.value * TICRATE
			end
			hole.target = shot.target
			hole.tracer_player = shot.target.player
			hole.weapon_id = shot.weapon_id
			hole.eflags = $|(ceil and MFE_VERTICALFLIP or 0)
			hole.revgrav = hole.eflags & MFE_VERTICALFLIP
			P_SetOrigin(hole, shot.x, shot.y, bull_z)
		end
		
		splattersound(shot)
		P_RemoveMobj(shot); return true
	end
end
--direct hits most likely wouldve been handled by the mobjcollide before this is ran
local function splash_blockmap(ray, mo)
	if not (ray and ray.valid) then return end
	if not (mo and mo.valid) then return end
	if (mo == ray.donthit) then return end
	if not mo.health then return end
	local wep = Paint.weapons[ray.weapon_id]
	local splashrad = FixedMul(wep:get(ray.target.player.paint,"splashradius"), ray.scale)
	if abs(ray.x - mo.x) > splashrad + mo.radius
	or abs(ray.y - mo.y) > splashrad + mo.radius
		return
	end
	local dist = R_PointTo3DDist(ray.x, ray.y, ray.z, mo.x,mo.y,mo.z)
	if dist > splashrad then return end
	
	if Paint_canHurtEnemy(ray.target.player, mo)
	or mo.type == MT_TNTBARREL
		local progress = FixedDiv(dist, splashrad)
		local damage = wep.splashdamage[1] + FixedMul(wep.splashdamage[2] - wep.splashdamage[1], progress)
		
		P_DamageMobj(mo, ray, ray.target, damage)
		Paint:doProjHitmarker(ray, mo, false)
		return
	end
	
	local me = ray.target
	local p = me.player
	
	if mo.type == MT_PLAYER
	and mo ~= me
		if Paint_canHurtPlayer(p, mo.player)
			local progress = FixedDiv(dist, splashrad)
			local damage = wep.splashdamage[1] + FixedMul(wep.splashdamage[2] - wep.splashdamage[1], progress)
			Paint:damagePlayer(mo.player, ray, p, damage)
			Paint:playHurtSound(mo.player)
			Paint:doProjHitmarker(ray, mo, false)
		elseif Paint_canHurtPlayer(p, mo.player, true)
		and not Paint:isFriendlyFire(p,mo.player)
			Paint:doProjHitmarker(ray, mo, false, true)
		end
	end
end
local function ExplodeShot(shot)
	P_SetOrigin(shot,shot.x,shot.y,shot.z)
	if not (shot and shot.valid) then return end
	local wep = Paint.weapons[shot.weapon_id]
	local sfx = P_SpawnGhostMobj(shot)
	sfx.flags2 = $|MF2_DONTDRAW
	sfx.fuse = 2 * TR; sfx.tics = sfx.fuse
	local sound = wep.blast_sounds[P_RandomRange(1,#wep.blast_sounds)]
	S_StartSound(sfx, sound)
	S_StartSound(sfx, sound)
	
	local splashrad = wep:get(shot.target.player.paint,"splashradius")
	local px = shot.x
	local py = shot.y
	local br = splashrad * 7/5
	searchBlockmap("objects",splash_blockmap, shot, px-br, px+br, py-br, py+br)
	
	local spr_scale = FU * 6/5
	local tntstate = S_TNTBARREL_EXPL3
	local rflags = RF_FULLBRIGHT|RF_NOCOLORMAPS
	local bam = P_SpawnMobjFromMobj(shot, 0,0,0, MT_THOK)
	P_SetMobjStateNF(bam, tntstate)
	bam.spritexscale = FixedMul($, spr_scale)
	bam.spriteyscale = bam.spritexscale
	bam.renderflags = $|rflags
	bam.blendmode = AST_ADD
	bam.colorized = true
	bam.color = shot.color
	
	for i = 0,2
		local outline = P_SpawnMobjFromMobj(shot, 0,0,0, MT_PAINT_SHOT)
		outline.visualfadestupidshit = true
		outline.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOCLIPTHING
		outline.fuse = 9
		outline.radius = 40*shot.scale
		outline.sprite = SPR_PAINT_SHOT
		outline.frame = ($ &~FF_FRAMEMASK)|3
		outline.spritexscale = FixedDiv(splashrad, 80*FU) * 2
		outline.spriteyscale = outline.spritexscale
		outline.renderflags = $|rflags|RF_PAPERSPRITE
		outline.blendmode = AST_ADD
		outline.colorized = true
		outline.color = shot.color
		outline.angle = shot.angle + (ANGLE_90 * i)
		if i == 2
			outline.renderflags = $|RF_FLOORSPRITE &~RF_PAPERSPRITE
		end
	end
	
	/*
	for i = -1,1,2
		local z = splashrad * i
		P_SpawnMobjFromMobj(shot, splashrad, splashrad, z, MT_THOK)
		P_SpawnMobjFromMobj(shot, splashrad, -splashrad, z, MT_THOK)
		P_SpawnMobjFromMobj(shot, -splashrad, splashrad, z, MT_THOK)
		P_SpawnMobjFromMobj(shot, -splashrad, -splashrad, z, MT_THOK)
	end
	local max = 16
	local fa = FixedDiv(360*FU, max*FU)
	for i = 0,max-1
		for j = 0, (max*2)-1
			local v = SphereToCartesian(FixedAngle(fa*i), FixedAngle(fa*j))
			P_SpawnMobjFromMobj(shot,
				FixedMul(splashrad,v.x),
				FixedMul(splashrad,v.y),
				FixedMul(splashrad,v.z),
				MT_THOK
			)
		end
	end
	*/
	P_KillMobj(shot)
end
local function CreateTrail(shot)
	local wep = Paint.weapons[shot.weapon_id]
	local drop = P_SpawnMobjFromMobj(shot,0,0,0, wep.shottype)
	if drop and drop.valid
		drop.target = shot.target
		drop.color = shot.color
		drop.angle = shot.angle
		drop.trail = true
		drop.lifespan = 0
		drop.flags = $|MF_NOCLIPTHING &~MF_NOGRAVITY
		drop.frame = ($ &~FF_FRAMEMASK)|4
		P_SetObjectMomZ(drop, -6*FU)
	end
	return drop
end
addHook("MobjThinker",function(shot)
	if shot.visualfadestupidshit then
		if shot.fuse < 10
			shot.alpha = $ - (FU/10) 
		end
		return
	end
	
	local me = shot.target
	if not (me and me.valid)
		P_RemoveMobj(shot); return
	end
	
	shot.lifespan = $ + 1
	if shot.lifespan == 1
	and (shot.frame & FF_FRAMEMASK == 0)
		--Fuck!
		shot.spritexscale = $ * 5/2
		shot.spriteyscale = shot.spritexscale
	end
	
	if HandleFloorSplat(shot) then return end
	
    local angle = R_PointToAngle2(0,0, shot.momx,shot.momy)
    local mang = R_PointToAngle2(0,0, FixedHypot(shot.momx, shot.momy), shot.momz)
    mang = InvAngle($)
	
	if not (shot.trail and (shot.frame & FF_FRAMEMASK == 4))
		shot.roll = FixedMul(mang, sin(angle))
		shot.pitch = FixedMul(mang, cos(angle))
	else
		shot.roll, shot.pitch = 0,0
	end
	
	local old_ng = (shot.flags & MF_NOGRAVITY)
	shot.flags = $ &~MF_NOGRAVITY
	if shot.eflags & MFE_GOOWATER
	or P_IsObjectInGoop(shot)
		P_SpawnMobj(shot.x,shot.y,shot.watertop,MT_SPLISH)
		splattersound(shot)
		P_RemoveMobj(shot); return
	end
	shot.flags = $|old_ng
	if shot.trail
		shot.flags = $ &~MF_NOGRAVITY
		shot.momz = $ + P_GetMobjGravity(shot)
		P_ZMovement(shot)
		return
	end
	
	if not (me.player and me.player.valid) then return end
	local p = me.player
	local pt = p.paint
	
	local wep = Paint.weapons[shot.weapon_id]
	local range = FixedMul(wep.range, shot.scale) + shot.falloff
	local dropoff = FixedMul(wep.dropoff, shot.scale)
	local dist = R_PointTo3DDist(shot.origin.x, shot.origin.y, shot.origin.z, shot.x,shot.y,shot.z)
	
	if wep.guntype == WPT_CHARGER
		local minrange = FixedMul(wep.minrange, shot.scale)
		range = $ - shot.falloff
		local chargeprogress = shot.progress
		local disttocover = max(FixedMul(range, chargeprogress), minrange)
		shot.momz = 0
		P_InstaThrust(shot,shot.angle, shot.radius * 2)
		Paint:aimProjectile(p, shot, shot.p_angle, shot.p_aiming)
		shot.angle = shot.p_angle
		shot.powerful = chargeprogress == FU
		local count = 0
		repeat
			for j = 0,3
				if P_RailThinker(shot) then return; end
				local g = P_SpawnGhostMobj(shot)
				g.blendmode = AST_ADD
				g.destscale = 0
				if (count % 3 == 0)
					CreateTrail(shot)
				end
				count = $ + 1
			end
			if not shot and shot.valid
				return
			end
		until (
			(not shot and shot.valid)
			or ((shot and shot.valid) and R_PointTo3DDist(shot.origin.x, shot.origin.y, shot.origin.z, shot.x,shot.y,shot.z) >= disttocover)
			or ((shot and shot.valid) and HandleFloorSplat(shot))
		)
		if (shot and shot.valid)
			P_RemoveMobj(shot)
		end
		return
	end
	if shot.quartersteps
		for i = 1,3
			if P_RailThinker(shot) then return end
			if HandleFloorSplat(shot) then return end
		end
	end
	
	if wep.guntype == WPT_BLASTER
		if (leveltime % 3 == 0)
			P_SpawnGhostMobj(shot).blendmode = AST_ADD
		end
		local d = CreateTrail(shot)
		if (d and d.valid)
			P_SetObjectMomZ(d,-30*FU)
		end
	else
		if (leveltime % 3 == 0)
		and P_RandomChance(FU/2)
			CreateTrail(shot)
		end
	end
	
	if dist >= range
		if wep.guntype == WPT_BLASTER
			ExplodeShot(shot)
			return
		end
		
		if (shot.flags & MF_NOGRAVITY)
			shot.fallofftime = shot.lifespan
		end
		shot.flags = $ &~MF_NOGRAVITY
		
		local dropoff = ((dropoff - range) / wep.lifespan)
		dropoff = FixedMul($, wep.dropoffmul)
		shot.momz = ($ - max(dropoff, wep.mindropoffgrav) * P_MobjFlip(shot)) + P_GetMobjGravity(shot)
		
		shot.damage = wep.falloffdamage + ease.linear(
			min(
				abs((FU/wep.fallofftime) * (shot.fallofftime - shot.lifespan)),
			FU),
			wep.damage - wep.falloffdamage, 0 
		)
		
		local drag = wep.dragmul
		shot.momx = FixedMul($, drag)
		shot.momy = FixedMul($, drag)
		if (shot.momz * P_MobjFlip(shot) > 0)
			shot.momz = FixedMul($, drag)
		end
	end
end,MT_PAINT_SHOT)

addHook("MobjMoveCollide",function(shot,mo)
	if not (shot and shot.valid) then return end
	if not shot.init then return false; end
	if shot.trail then return false; end
	if not (mo and mo.valid) then return end
	if not mo.health then return end
	if not L_ZCollide(shot,mo) then return end
	if (shot.lasthit == mo) then return end
	shot.lasthit = mo
	
	local wep = Paint.weapons[shot.weapon_id]
	if Paint_canHurtEnemy(shot.target.player, mo)
	or mo.type == MT_TNTBARREL
		P_DamageMobj(mo,shot,shot.target,shot.damage)
		Paint:doProjHitmarker(shot, mo, true)
		
		if (wep.guntype == WPT_CHARGER
		and shot.charge >= wep.chargetime)
		or (wep.guntype == WPT_BLASTER)
			S_StartSound(nil, sfx_p_s2_4, shot.target.player)
			if wep.guntype == WPT_BLASTER
				shot.donthit = mo
				ExplodeShot(shot)
				return
			elseif wep.guntype == WPT_CHARGER
				P_DamageMobj(mo,shot,shot.target)
			end
		end
		
		if (wep.guntype == WPT_CHARGER
		and shot.pierces)
		or (wep.pierces == -1)
			shot.pierces = $ - 1
		else
			P_RemoveMobj(shot)
		end
		return
	elseif Paint_canHurtEnemy(shot.target.player, mo, nil,nil, true)
		Paint:doProjHitmarker(shot, mo, true, true)
		P_RemoveMobj(shot)
		return
	end
	
	if not (shot.target and shot.target.valid) then return end
	local me = shot.target
	local p = me.player
	
	if mo.type == MT_PLAYER
	and mo ~= me
		if Paint_canHurtPlayer(p, mo.player)
			local play = mo.player
			Paint:damagePlayer(play,shot,p, shot.damage)
			Paint:playHurtSound(play)
			Paint:doProjHitmarker(shot, mo, true)
			if (wep.guntype == WPT_CHARGER
			and shot.charge >= wep.chargetime)
			or (wep.guntype == WPT_BLASTER)
				S_StartSound(nil, sfx_p_s2_4, p)
				if wep.guntype == WPT_BLASTER
					shot.donthit = mo
					ExplodeShot(shot)
					return
				end
			end
			if (wep.guntype == WPT_CHARGER
			and shot.pierces)
			or (wep.pierces == -1) -- infinite pierces
				shot.pierces = $ - 1
			else
				P_RemoveMobj(shot)
			end
		elseif Paint_canHurtPlayer(p, mo.player, true)
		and not Paint:isFriendlyFire(p,mo.player)
			Paint:doProjHitmarker(shot, mo, true, true)
			P_RemoveMobj(shot)
		end
	end
end,MT_PAINT_SHOT)

addHook("MobjMoveBlocked", function(mo, moagainst, line)
	if not (mo and mo.valid) then return end
	
	if (line and line.valid)
		--no puffs against thok barriers
		if P_CheckSkyHit(mo,line) then return end
	end
	local angle = mo.angle + ANGLE_90
	if (moagainst and moagainst.valid)
		angle = R_PointToAngle2(
			mo.x, mo.y,
			moagainst.x, moagainst.y
		) + ANGLE_90
	elseif (line and line.valid)
		angle = R_PointToAngle2(line.v1.x, line.v1.y, line.v2.x, line.v2.y)
	end
	
	local bull_x = mo.x
	local bull_y = mo.y
	local bull_z = mo.z
	local bull_frame = B
	if (line and line.valid)
		bull_x,bull_y = P_ClosestPointOnLine(bull_x,bull_y, line)
	end
	do
		local hole = P_SpawnMobjFromMobj(mo, 0,0,0, MT_PAINT_WALLSPLAT)
		hole.radius = mo.scale
		hole.height = 2 * mo.scale
		
		hole.frame = FF_PAPERSPRITE|bull_frame
		hole.color = mo.color
		hole.sprite = SPR_PAINT_SHOT
		hole.mirrored = P_RandomChance(FU/2)
		hole.spritexscale = ($ * 5/2) + P_RandomFixed()/5
		hole.spriteyscale = hole.spritexscale
		hole.angle = angle
		if CV.splatter_lifetime.value == -1
			hole.fuse = -1
		else
			hole.fuse = CV.splatter_lifetime.value * TICRATE
		end
		hole.tics = hole.fuse
		
		P_SetOrigin(hole,
			bull_x - P_ReturnThrustX(nil, mo.angle, mo.scale),
			bull_y - P_ReturnThrustY(nil, mo.angle, mo.scale),
			bull_z
		)
	end
	
	--MM.BulletDies(ring, m,l)
	splattersound(mo)
	P_RemoveMobj(mo)
end, MT_PAINT_SHOT)

addHook("MobjThinker",function(shot)
	local me = shot.target
	if not (me and me.valid and me.health)
		P_RemoveMobj(shot); return
	end
end,MT_PAINT_GUN)

addHook("MobjThinker",function(splat)
	splat.flags = $|MF_SPECIAL
	splat.health = splat.info.spawnhealth
	
	local CV_VALUE = CV.splatter_lifetime.value * TR
	if splat.fuse > CV_VALUE
		splat.fuse = CV_VALUE
	elseif splat.fuse <= -1 and CV.splatter_lifetime.value ~= -1
		splat.fuse = CV_VALUE
	elseif CV.splatter_lifetime.value == 0
		P_RemoveMobj(splat)
		return
	end
	
	if splat.lifespan == nil
		splat.lifespan = -1
	end
	splat.lifespan = $ + 1
	
	local slope = splat.standingslope
	local skew = splat.floorspriteslope
	if (slope and slope.valid)
		if not (skew and skew.valid)
			P_CreateFloorSpriteSlope(splat); skew = splat.floorspriteslope
		end
		if slope ~= splat.lastslope
			SetSplatSkew(splat, slope, skew)
		end
	--elseif (skew and skew.valid)
	--	P_RemoveFloorSpriteSlope(splat)
	end
	if not (splat and splat.valid) then return end
	
	splat.lastslope = slope
	
	splat.eflags = $|splat.revgrav
	if splat.revgrav
		splat.z = P_CeilingzAtPos(splat.x,splat.y,splat.z,splat.height)
	else
		splat.z = P_FloorzAtPos(splat.x,splat.y,splat.z,splat.height)
	end
	if not (splat and splat.valid) then return end
	
	if not (splat.extravalue1)
		splat.extravalue1 = 1
		--P_TryMove(splat,splat.x,splat.y,true)
		--P_CheckPosition(splat, splat.x,splat.y,splat.z)
	elseif splat.extravalue1 == 1
		splat.extravalue1 = 2
		splat.flags = $|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOCLIP
		splat.radius = FixedMul(REAL_SPLATRAD, splat.scale)
	end
end,MT_PAINT_SPLATTER)
addHook("MobjLineCollide",function(mo)
	return false
end,MT_PAINT_SPLATTER)

addHook("MobjThinker",function(splat)
	local CV_VALUE = CV.splatter_lifetime.value * TR
	
	if splat.fuse > CV_VALUE
		splat.fuse = CV_VALUE
	elseif splat.fuse <= -1 and CV.splatter_lifetime.value ~= -1
		splat.fuse = CV_VALUE
	elseif CV.splatter_lifetime.value == 0
		P_RemoveMobj(splat)
		return
	end
end,MT_PAINT_WALLSPLAT)

--man fuck this retarded ass game bro
local function nope(splat,mo)
	splat.health = mobjinfo[splat.type].spawnhealth
	splat.flags = $|MF_SPECIAL
	if (mo and mo.valid) and mo.player.paint.squidtime
		splat.fuse = CV.splatter_lifetime.value * TR
	end
	return true
end

local MIN_INK_HP = 40*FU
local function inkDamage(splat,mo, play, pnt)
	local p = splat.tracer_player
	if not Paint:playerIsActive(play) then return nope(splat,mo); end
	
	if (p and p.valid)
	and not Paint_canHurtPlayer(p, play)
		Paint:setPlayerInInk(p, Paint.ININK_FRIENDLY)
		return nope(splat,mo);
	end
	
	if pnt.hp >= MIN_INK_HP
		Paint:damagePlayer(play, splat, p, FixedDiv(18*FU, TR*FU))
		pnt.hp = max($, MIN_INK_HP)
	end
	Paint:damagePlayer(play, splat, p, 0)
	Paint:setPlayerInInk(play, Paint.ININK_ENEMY)
end
addHook("TouchSpecial",function(splat,mo)
	if not (splat and splat.valid) then return end
	if not (mo and mo.valid and mo.health) then return nope(splat); end
	if mo.type ~= MT_PLAYER then return nope(splat); end
	
	local play = mo.player
	local pnt = play.paint
	if not Paint:playerIsActive(play) then return nope(splat,mo); end
	if R_PointToDist2(splat.x,splat.y, mo.x,mo.y) > (splat.radius*6/7) then return nope(splat,mo); end
	if (pnt.inkleveltime == leveltime) then return nope(splat,mo); end
	pnt.inkleveltime = leveltime
	
	local p = splat.tracer_player
	if not (p and p.valid) then
		if (splat.color ~= Paint:getPlayerColor(mo.player))
			if inkDamage(splat,mo, play, pnt)
				return true
			end
		end
		return nope(splat,mo);
	end
	if p == play
		Paint:setPlayerInInk(p, Paint.ININK_FRIENDLY)
		return nope(splat,mo);
	end
	
	if inkDamage(splat,mo, play, pnt)
		return true
	end
end,MT_PAINT_SPLATTER)
addHook("MobjCollide",function(splat,mo)
	if mo.type ~= splat.type then return end
	if (mo.revgrav ~= splat.revgrav) then return end
	
	local friendly = false
	if splat.tracer_player == mo.tracer_player
		friendly = true
	elseif not Paint_canHurtPlayer(splat.tracer_player,mo.tracer_player)
	and splat.color == mo.color
		friendly = true
	end
	
	if R_PointToDist2(mo.x,mo.y, splat.x,splat.y) <= splat.radius * 4/5
		if friendly
			if splat.scale < 2*FU
				splat.scale = $ + FU/4
			end
			P_RemoveMobj(mo)
			return false
		elseif (mo.lifespan ~= nil and splat.lifespan ~= nil)
		and mo.lifespan < splat.lifespan
			P_RemoveMobj(mo)
			return false
		end
	end
end,MT_PAINT_SPLATTER)
