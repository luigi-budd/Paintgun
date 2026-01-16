local CV = Paint.CV

Paint.splatterid = 0
addHook("MapLoad",function()
	Paint.splatterid = 0
end)
addHook("NetVars",function(n)
	Paint.splatterid = n($)
end)

freeslot(
	"MT_PAINT_SHOT",
	"SPR_PAINT_SHOT",
	
	"MT_BRELLA_SHIELD",
	"S_BRELLA_SHIELD",
	
	"S_PAINT_SHOT",
	"S_PAINT_SHOT_BIG", 
	"S_PAINT_SHOT_PELLET",
	
	"SPR_PAINT_MISC",
	"SPR_PAINT_GUN"
)
states[S_PAINT_SHOT] = {
	sprite = SPR_PAINT_SHOT,
	frame = 0|FF_SEMIBRIGHT,
	tics = -1,
	nextstate = S_PAINT_SHOT
}
states[S_PAINT_SHOT_BIG] = {
	sprite = SPR_PAINT_SHOT,
	frame = 1|FF_FULLBRIGHT,
	tics = -1,
	nextstate = S_PAINT_SHOT_BIG
}
states[S_PAINT_SHOT_PELLET] = {
	sprite = SPR_PAINT_SHOT,
	frame = 3|FF_SEMIBRIGHT,
	tics = -1,
	nextstate = S_PAINT_SHOT_PELLET
}
mobjinfo[MT_PAINT_SHOT] = {
	doomednum = -1,
	radius = 12*FU,
	height = 24*FU,
	flags = MF_NOGRAVITY,
	spawnstate = S_PAINT_SHOT
}

states[S_BRELLA_SHIELD] = {
	sprite = SPR_PAINT_GUN,
	frame = 9,
	tics = -1,
	nextstate = S_BRELLA_SHIELD
}
mobjinfo[MT_BRELLA_SHIELD] = {
	doomednum = -1,
	radius = 30*FU,
	height = 62*FU,
	spawnhealth = 1,
	flags = MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_SHOOTABLE,
	spawnstate = S_BRELLA_SHIELD,
	deathstate = S_BRELLA_SHIELD,
	painstate = S_BRELLA_SHIELD,
}

freeslot("MT_PAINT_GUN", "S_PAINT_GUN")
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

local REAL_SPLATRAD = 32*FU
local SPLAT_SIZEMUL = FU * 3/2
local SPLAT_MAXSIZE = (SPLAT_SIZEMUL)*2
local function splattersound(shot, collided)
	if shot.nosound
		return
	end
	
	local wep = Paint.weapons[shot.weapon_id]
	local sfx = P_SpawnGhostMobj(shot)
	sfx.flags2 = $|MF2_DONTDRAW
	sfx.fuse = TR; sfx.tics = sfx.fuse

	local startsound = sfx_p_sp0
	local endsound = sfx_p_sp8
	if collided
		startsound = sfx_p_sp9
		endsound = sfx_p_sp12
	end

	local sound = P_RandomRange(startsound,endsound)
	local volume = wep and wep.splatvolume or 255
	S_StartSoundAtVolume(sfx, sound, volume)
	if not shot.trail
		S_StartSoundAtVolume(sfx, sound, volume)
	end
	
	if collided then return end
	if not wep then return end
	if wep.guntype == WPT_BLASTER
	and not shot.trail
		local sound = wep.explode_sounds[P_RandomRange(1,#wep.explode_sounds)]
		S_StartSoundAtVolume(sfx, sound, volume)
		S_StartSoundAtVolume(sfx, sound, volume)
	end
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
	or (shot.eflags & MFE_JUSTSTEPPEDDOWN)
		local ceil = shot.z+shot.height >= shot.ceilingz
		
		local bull_z
		if ceil
			bull_z = P_CeilingzAtPos(shot.x,shot.y,shot.z,shot.height) - 1
		else
			bull_z = P_FloorzAtPos(shot.x,shot.y,shot.z,shot.height) + 1
		end
		do
			local hole = P_SpawnMobjFromMobj(shot, 0,0,0, MT_PAINT_SPLATTER)			
			hole.renderflags = $|RF_FLOORSPRITE|RF_NOSPLATBILLBOARD|RF_SLOPESPLAT
			hole.color = shot.color
			hole.mirrored = P_RandomChance(FU/2)
			hole.angle = shot.angle
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
			hole.dispoffset = -100
			hole.scale = FixedMul($, SPLAT_SIZEMUL)
			P_SetOrigin(hole, shot.x, shot.y, bull_z)
		end
		
		splattersound(shot, not shot.trail)
		P_RemoveMobj(shot); return true
	end
end

freeslot("MT_PAINT_SPLATTER", "MT_PAINT_WALLSPLAT", "S_PAINT_SPLATTER", "S_PAINT_WALLSPLAT")
states[S_PAINT_SPLATTER] = {
	sprite = SPR_PAINT_MISC,
	frame = 17,
	tics = 1,
	action = function(splat)
		if P_IsObjectInGoop(splat)
			P_RemoveMobj(splat)
			return
		end
		
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
			splat.collided = {}
		end
		splat.lifespan = $ + 1
		
		if (splat.lifespan % (3*TR)) == 0
			splat.collided = {}
		end
		
		local slope = splat.standingslope
		local skew = splat.floorspriteslope
		if (slope and slope.valid)
			if not (skew and skew.valid)
				P_CreateFloorSpriteSlope(splat); skew = splat.floorspriteslope
			end
			if slope ~= splat.lastslope
				SetSplatSkew(splat, slope, skew)
				splat.height = $ + abs(slope.zdelta)*5
			end
		elseif (skew and skew.valid)
			P_RemoveFloorSpriteSlope(splat)
		end
		if not (splat and splat.valid) then return end
		if (splat.scale ~= splat.lastscale)
			if (slope and slope.valid)
				splat.height = $ + abs(slope.zdelta)*5
			end
			splat.collided = {}
		end
		
		splat.lastslope = slope
		splat.lastscale = splat.scale
		
		splat.momx,splat.momy = 0,0
		splat.eflags = $|splat.revgrav
		if splat.lifespan == 0
			if splat.revgrav
				splat.z = P_CeilingzAtPos(splat.x,splat.y,splat.z,splat.height)
			else
				splat.z = P_FloorzAtPos(splat.x,splat.y,splat.z,splat.height)
			end
			if not (splat and splat.valid) then return end
		end
		splat.renderflags = $|RF_SEMIBRIGHT|RF_NOCOLORMAPS
		
		if not (splat.extravalue1)
			splat.extravalue1 = 1
			--P_TryMove(splat,splat.x,splat.y,true)
			--P_CheckPosition(splat, splat.x,splat.y,splat.z)
		elseif splat.extravalue1 == 1
			splat.extravalue1 = 2
			splat.flags = $|MF_NOCLIP
			splat.radius = FixedMul(REAL_SPLATRAD, splat.scale)
		end
	end,
	nextstate = S_PAINT_SPLATTER
}
states[S_PAINT_WALLSPLAT] = {
	sprite = SPR_PAINT_MISC,
	frame = 16|FF_PAPERSPRITE,
	tics = 1,
	action = function(splat)
		if P_IsObjectInGoop(splat)
			P_RemoveMobj(splat)
			return
		end
		
		splat.flags = $|MF_SPECIAL
		splat.health = splat.info.spawnhealth
		splat.renderflags = $|RF_SEMIBRIGHT|RF_NOCOLORMAPS
		
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
			splat.collided = {}
		end
		splat.lifespan = $ + 1
		
		if (splat.lifespan % (3*TR)) == 0
			splat.collided = {}
		end
	end,
	nextstate = S_PAINT_WALLSPLAT
}

-- these cant have MF_SCENERY otherwise the slopeskew effect doesnt work
mobjinfo[MT_PAINT_SPLATTER] = {
	doomednum = -1,
	radius = 3*FU,
	height = 12*FU,
	flags = MF_SPECIAL,
	spawnstate = S_PAINT_SPLATTER,
	spawnhealth = 1,
	deathstate = S_PAINT_SPLATTER,
}
mobjinfo[MT_PAINT_WALLSPLAT] = {
	doomednum = -1,
	radius = 32*FU,
	height = 55*FU,
	flags = MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_SPECIAL|MF_SCENERY,
	spawnstate = S_PAINT_WALLSPLAT,
	spawnhealth = 1,
	deathstate = S_PAINT_WALLSPLAT,
}

for i = 0,3
	sfxinfo[freeslot("sfx_pt_nm"..i)].caption = "Bullet whiz"
end

local hitmark_tic = 0
function Paint:doProjHitmarker(shot, mo, splatter, nullify, onmo)
	local hitmarker
	local startrange, endrange = sfx_pnt_h0, sfx_pnt_h5
	if (mo.paint_shield)
		startrange, endrange = sfx_pnt_s0, sfx_pnt_s5
	end
	if nullify
		startrange, endrange = sfx_pnt_n0, sfx_pnt_n5
	end
	if (mo.paint_lifesaver)
		startrange, endrange = sfx_pnt_r0, sfx_pnt_r0
	end
	hitmarker = P_RandomRange(startrange, endrange)
	
	if hitmark_tic ~= leveltime
		S_StartSound(nil, hitmarker, shot.target.player)
		if not mo.paint_lifesaver
			S_StartSoundAtVolume(nil, hitmarker, 255/2, shot.target.player) --Bruh
		end
	end
	hitmark_tic = leveltime
	
	if splatter and not nullify
		splattersound(shot, true)
		if not shot.pellet
			splattersound(shot, true)
		end
	end
	
	local pos = {
		x = shot.x,
		y = shot.y,
		z = shot.z + shot.height/2,
	}
	if onmo
		pos = {
			x = mo.x,
			y = mo.y,
			z = mo.z + mo.height/2,
		}
	end
	
	local rollangle = FixedAngle(360 * P_RandomFixed())
	Paint.HUD:hitMarker(shot.target.player, pos, rollangle, (shot.pellet and FU/2 or FU), shot.powerful, nullify)
end

--direct hits most likely wouldve been handled by the mobjcollide before this is ran
local function splash_blockmap(ray, mo)
	if not (ray and ray.valid) then return end
	if not (mo and mo.valid) then return end
	if (mo == ray.donthit) then return end
	if (ray.donthit and ray.donthit.paint_shield and (mo == ray.donthit.tracer))
		return
	end
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
		Paint:doProjHitmarker(ray, mo, false, false, true)
		Paint.HUD:damageNumber(ray.target.player, mo, damage)
		return
	end
	
	local me = ray.target
	local p = me.player
	
	if mo.type == MT_PLAYER
	and mo ~= me
		if Paint_canHurtPlayer(p, mo.player)
			local progress = FixedDiv(dist, splashrad)
			local damage = wep.splashdamage[1] + FixedMul(wep.splashdamage[2] - wep.splashdamage[1], progress)
			local newdamage = Paint:damagePlayer(mo.player, ray, p, damage)
			Paint:playHurtSound(mo.player)
			Paint:doProjHitmarker(ray, mo, false)
			Paint.HUD:damageNumber(ray.target.player, mo, newdamage)
		elseif Paint_canHurtPlayer(p, mo.player, true, true)
		and not Paint:isFriendlyFire(p,mo.player)
			Paint:doProjHitmarker(ray, mo, false, true, true)
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
		outline.sprite = SPR_PAINT_MISC
		outline.frame = ($ &~FF_FRAMEMASK)|18
		outline.spritexscale = FixedDiv(splashrad, 80*FU) * 2
		outline.spriteyscale = outline.spritexscale
		outline.renderflags = $|rflags|RF_PAPERSPRITE|RF_NOSPLATBILLBOARD
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
		drop.flags = $|MF_NOCLIPTHING &~(MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOCLIP)
		drop.frame = ($ &~FF_FRAMEMASK)|2
		drop.weapon_id = shot.weapon_id
		P_SetObjectMomZ(drop, -6*FU)
	end
	return drop
end

Paint.bulletSimpleState = function(shot)
	local state = shot.s_state
	if state == SS_STRAIGHT
		if shot.lifespan >= shot.str_tics
			shot.s_state = SS_BRAKE
			shot.braketic = shot.lifespan
		end
	elseif state == SS_BRAKE
		if R_PointToDist2(0,0, shot.momx,shot.momy) >= shot.str2brk_maxspeed
			local new = shot.str2brk_maxspeed
			shot.momx = P_ReturnThrustX(nil,shot.baseangle,new)
			shot.momy = P_ReturnThrustY(nil,shot.baseangle,new)
		end
		local resist = shot.brk_airresist
		shot.momx = FixedMul($, resist)
		shot.momy = FixedMul($, resist)
		shot.momz = FixedMul($, resist)
		shot.momz = $ - (shot.brk_gravity * P_MobjFlip(shot))
		if (shot.momz*P_MobjFlip(shot) <= shot.brk2fre_minz)
		and (
			(R_PointToDist2(0,0, shot.momx,shot.momy) <= shot.brk2fre_minxy)
			or
			(shot.lifespan - shot.braketic >= shot.brk2fre_tics)
		)
			shot.s_state = SS_FREE
		end
	elseif state == SS_FREE
		local resist = shot.fre_airresist
		shot.momx = FixedMul($, resist)
		shot.momy = FixedMul($, resist)
		shot.momz = FixedMul($, resist)
		shot.momz = $ - (shot.fre_gravity * P_MobjFlip(shot))
	end
end

addHook("MobjThinker",function(shot)
	shot.renderflags = $|RF_SEMIBRIGHT|RF_NOCOLORMAPS
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
	
	shot.eflags = $|MFE_NOPITCHROLLEASING
	shot.lifespan = $ + 1
	shot.spritexscale = shot.basescale or FU
	if (shot.frame & FF_FRAMEMASK == 0)
		--Fuck!
		shot.spritexscale = $ * 5/2
	end
	shot.spriteyscale = shot.spritexscale
	
	if HandleFloorSplat(shot) then return end
	
	if not (shot.trail and (shot.frame & FF_FRAMEMASK == 2))
		local ha, va = R_PointTo3DAngles(0,0,0, shot.momx,shot.momy,shot.momz)
		
		shot.pitch = FixedMul(va, -cos(ha))
		shot.roll = FixedMul(va, -sin(ha))
	else
		shot.roll, shot.pitch = 0,0
	end
	
	-- only works on trails but whatever
	if (shot.eflags & MFE_GOOWATER)
	or P_IsObjectInGoop(shot)
		P_SpawnMobj(shot.x,shot.y,shot.watertop,MT_SPLISH)
		splattersound(shot)
		P_RemoveMobj(shot); return
	end
	
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
	local range = FixedMul(wep.range, shot.scale)
	local dropoff = FixedMul(wep.dropoff, shot.scale)
	local dist = R_PointTo3DDist(shot.origin.x, shot.origin.y, shot.origin.z, shot.x,shot.y,shot.z)
	
	if wep.guntype == WPT_CHARGER
		local minrange = FixedMul(wep.minrange, shot.scale)
		local chargeprogress = shot.progress
		local disttocover = max(FixedMul(range, chargeprogress), minrange)
		local org = shot.origin
		shot.angle = shot.p_angle
		while true
			if not (shot and shot.valid and shot.health) then break end
			for j = 0,3
				if not (shot and shot.valid and shot.health) then break 2 end
				if P_RailThinker(shot) then break 2 end
				
				local g = P_SpawnGhostMobj(shot)
				P_SetOrigin(g,g.x,g.y,g.z)
				g.blendmode = AST_ADD
				g.destscale = 0
				if (j == 0)
					CreateTrail(shot)
				end
				
				if R_PointTo3DDist(org.x, org.y, org.z, shot.x,shot.y,shot.z) >= disttocover
					break 2
				end
				if HandleFloorSplat(shot)
					break 2
				end
			end
		end
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
		
		if dist >= range
			ExplodeShot(shot)
			return
		end
	else
		if shot.s_state ~= SS_FREE
			if shot.centerpellet
				CreateTrail(shot)
			elseif not shot.pellet
				if ((leveltime + shot.lifespan) % 3 == 0)
				and P_RandomChance(FU/2)
					CreateTrail(shot)
				end
			end
		end
		
		-- near miss
		local sfxid = P_RandomRange(sfx_pt_nm0,sfx_pt_nm3)
		local dp = displayplayer
		if (dp and dp.valid and dp.mo and dp.mo.valid and not dp.spectator and dp.mo ~= shot.target and dp.playerstate == PST_LIVE)
			local friendly = Paint.isFriendlyFire(p, dp)
			
			if not shot.whizzed
			and not friendly
				if R_PointTo3DDist(shot.x,shot.y,shot.z, dp.mo.x,dp.mo.y,dp.mo.z) <= 100*dp.mo.scale
					local sfx = P_SpawnGhostMobj(shot)
					sfx.flags2 = $|MF2_DONTDRAW
					sfx.fuse = TR
					sfx.tics = sfx.fuse
					S_StartSoundAtVolume(sfx, sfxid, 255 * 4/5, dp)
					shot.whizzed = true
				end
			end
		end
		
		Paint.bulletSimpleState(shot)
		
		if shot.lifespan >= shot.crs_guideframe
			shot.damage = shot.falloffdamage + ease.linear(
				min(
					abs((FU/wep.fallofftime) * (shot.lifespan - (shot.crs_guideframe))),
				FU),
				shot.basedamage - shot.falloffdamage, 0 
			)
		end
	end
	
	shot.angle = shot.baseangle + shot.angoffset
	shot.angoffset = $ * 6/7
	
	if shot.lifespan <= shot.str_tics
	and ((shot.frame & FF_FRAMEMASK == 0)
	or (shot.frame & FF_FRAMEMASK == 3))
		local stretch = 7*FU
		if shot.lifespan > 2
			stretch = $ - ((7*FU)/2) * (shot.lifespan - 2)
		end
		shot.spritexscale = $ + abs(FixedMul(stretch, sin(R_PointToAngle(shot.x,shot.y) - shot.angle)))
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
	
	if not (shot.target and shot.target.valid) then return end
	local me = shot.target
	local p = me.player
	local pt = p.paint
	local wep = Paint.weapons[shot.weapon_id]

	if Paint_canHurtEnemy(p, mo)
	or mo.type == MT_TNTBARREL
		P_DamageMobj(mo,shot,me, shot.damage)
		Paint:doProjHitmarker(shot, mo, true)
		Paint.HUD:damageNumber(p, mo, shot.damage)
		
		if (wep.guntype == WPT_CHARGER
		and shot.charge >= wep:get(pt,"chargetime"))
		or (wep.guntype == WPT_BLASTER)
			S_StartSound(nil, sfx_p_s2_4, p)
			if wep.guntype == WPT_BLASTER
				shot.donthit = mo
				ExplodeShot(shot)
				return
			end
		end
		
		if ((wep.guntype == WPT_CHARGER
		and shot.pierces)
		or (wep.pierces == -1))
		and shot.powerful
		and (not mo.paint_shield)
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
	
	if mo.type == MT_PLAYER
	and mo ~= me
		if Paint_canHurtPlayer(p, mo.player)
			local play = mo.player
			local newdamage = Paint:damagePlayer(play,shot,p, shot.damage)
			Paint:playHurtSound(play)
			Paint:doProjHitmarker(shot, mo, true)
			Paint.HUD:damageNumber(p, mo, newdamage)
			if (wep.guntype == WPT_CHARGER
			and shot.charge >= wep:get(pt,"chargetime"))
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
				return
			end
		-- invicible but not a teammate
		elseif Paint_canHurtPlayer(p, mo.player, true)
		and not Paint:isFriendlyFire(p,mo.player)
			Paint:doProjHitmarker(shot, mo, true, true)
			P_RemoveMobj(shot)
			return
		end
		P_RemoveMobj(shot)
	end
end,MT_PAINT_SHOT)

addHook("MobjMoveBlocked", function(mo, moagainst, line)
	if not (mo and mo.valid) then return end
	if not (line and line.valid) then return end
	
	--no puffs against thok barriers
	if P_CheckSkyHit(mo,line) then P_RemoveMobj(mo); return end
	
	local angle = R_PointToAngle2(line.v1.x, line.v1.y, line.v2.x, line.v2.y)
	
	local bull_x,bull_y = P_ClosestPointOnLine(mo.x,mo.y, line)
	local bull_z = mo.z
	if not (line.flags & ML_NOCLIMB)
		local hole = P_SpawnMobjFromMobj(mo, 0,0,0, MT_PAINT_WALLSPLAT)
		
		hole.color = mo.color
		hole.mirrored = P_RandomChance(FU/2)
		hole.scale = FixedMul($, SPLAT_SIZEMUL)
		hole.angle = angle
		hole.tracer_player = mo.target.player
		if CV.splatter_lifetime.value == -1
			hole.fuse = -1
		else
			hole.fuse = CV.splatter_lifetime.value * TICRATE
		end
		
		P_SetOrigin(hole,
			bull_x - P_ReturnThrustX(nil, mo.angle, mo.scale),
			bull_y - P_ReturnThrustY(nil, mo.angle, mo.scale),
			bull_z - mo.height/2
		)
	end
	
	splattersound(mo, true)
	P_RemoveMobj(mo)
end, MT_PAINT_SHOT)

addHook("MobjThinker",function(shot)
	local me = shot.target
	if not (me and me.valid and me.health)
		P_RemoveMobj(shot); return
	end
	if shot.state == S_PAINT_CHARGEDMAX
		local udata = shot.tracer
		if (shot.threshold)
			udata = shot.tracer.player
		end
		if not udata.paint.charge
			P_RemoveMobj(shot); return
		end
		local wep = Paint.weapons[shot.weapon_id]
		local vec = SphereToCartesian(me.angle, me.aiming)
		local dist = FixedMul(wep:get(udata.paint, "muzzleoffset"), shot.scale)
		local offset = {
			x = FixedMul(dist, vec.x),
			y = FixedMul(dist, vec.y),
			z = FixedMul(dist, vec.z),
		}
		P_MoveOrigin(shot,
			me.x + offset.x,
			me.y + offset.y,
			me.z + offset.z
		)
		local scaleadd = FixedDiv(R_PointToDist(shot.x,shot.y), 512*FU)
		shot.spritexscale = FU + scaleadd
		shot.spriteyscale = FU + scaleadd
	end
end,MT_PAINT_GUN)

addHook("MobjSpawn",function(splat)
	splat.splatid = Paint.splatterid
	Paint.splatterid = $ + 1
end,MT_PAINT_SPLATTER)
addHook("MobjSpawn",function(splat)
	splat.splatid = Paint.splatterid
	Paint.splatterid = $ + 1
end,MT_PAINT_WALLSPLAT)

addHook("MobjLineCollide",function(mo)
	return false
end,MT_PAINT_SPLATTER)

--man fuck this retarded ass game bro
local function nope(splat,mo)
	splat.health = mobjinfo[splat.type].spawnhealth
	splat.flags = $|MF_SPECIAL
	if (mo and mo.valid)
	and (mo.player and mo.player.paint)
	and mo.player.paint.squidtime
		splat.fuse = CV.splatter_lifetime.value * TR
	end
	return true
end

local MIN_INK_HP = 40*FU
addHook("TouchSpecial",function(splat,mo)
	if not (splat and splat.valid) then return end
	if not (mo and mo.valid and mo.health) then return nope(splat); end
	if mo.type ~= MT_PLAYER then return nope(splat); end
	
	local targp = mo.player
	local pnt = targp.paint
	if not Paint:playerIsActive(targp) then return nope(splat,mo); end
	if R_PointToDist2(splat.x,splat.y, mo.x,mo.y) > (splat.radius*6/7) then return nope(splat,mo); end
	if (pnt.inkleveltime == leveltime) then return nope(splat,mo); end
	pnt.inkleveltime = leveltime
	
	local p = splat.tracer_player
	local friendly = false

	if not (p and p.valid)
		friendly = Paint:mobjsOnTeam(mo, splat)
	else
		friendly = Paint:mobjsOnTeam(mo, p.mo)
	end
	
	if friendly
		Paint:setPlayerInInk(targp, Paint.ININK_FRIENDLY)
	elseif (pnt.inink ~= Paint.ININK_FRIENDLY) -- stepping in friendly ink should have precedence over enemy ink
		if pnt.hp >= MIN_INK_HP
			Paint:damagePlayer(targp, splat, p, FixedDiv(18*FU, TR*FU))
			pnt.hp = max($, MIN_INK_HP)
		end
		Paint:damagePlayer(targp, splat, p, 0)
		Paint:setPlayerInInk(targp, Paint.ININK_ENEMY)
	end
	return nope(splat,mo);
end,MT_PAINT_SPLATTER)

addHook("MobjCollide",function(splat,mo)
	if mo.type ~= splat.type then return end
	if (mo.revgrav ~= splat.revgrav) then return end
	if (splat.collided == nil) then return end
	if (mo.splatid == nil) then return end
	--if (splat.collided[mo.splatid] ~= nil) then return end
	
	do --if R_PointToDist2(mo.x,mo.y, splat.x,splat.y) <= splat.radius * 4/5
		local friendly = Paint:mobjsOnTeam(
			(splat.tracer_player and splat.tracer_player.valid) and splat.tracer_player.mo or splat,
			(mo.tracer_player and mo.tracer_player.valid) and mo.tracer_player.mo or mo
		)
		--table.insert(mo.checkedme, splat)
		
		if friendly
			if splat.scale < SPLAT_MAXSIZE
				splat.scale = $ + FU/4
			else
				splat.scale = max($, SPLAT_MAXSIZE)
			end
			P_RemoveMobj(mo)
			return false
		elseif (mo.lifespan ~= nil and splat.lifespan ~= nil)
		and (mo.lifespan < splat.lifespan or mo.splatid > splat.splatid)
			P_RemoveMobj(splat)
			return false
		end
	end
	splat.collided[mo.splatid] = true
end,MT_PAINT_SPLATTER)

addHook("MobjCollide",function(splat,mo)
	if mo.type ~= splat.type then return end
	if not L_ZCollide(splat,mo, splat.height * 3/5, mo.height * 3/5) then return end
	if (splat.collided == nil) then return end
	if (mo.splatid == nil) then return end
	--if (splat.collided[mo.splatid] ~= nil) then return end
	
	if R_PointToDist2(splat.x,splat.y, mo.x,mo.y) <= splat.radius * 3/5
		local friendly = Paint:mobjsOnTeam(
			(splat.tracer_player and splat.tracer_player.valid) and splat.tracer_player.mo or splat,
			(mo.tracer_player and mo.tracer_player.valid) and mo.tracer_player.mo or mo
		)
		
		if friendly
			if splat.scale < SPLAT_MAXSIZE
				splat.scale = $ + FU/4
				splat.z = $ - 4*FU
			else
				splat.scale = max($, SPLAT_MAXSIZE)
			end
			if mo and mo.valid
				P_RemoveMobj(mo)
			end
			return false
		elseif (mo.lifespan ~= nil and splat.lifespan ~= nil)
		and (mo.lifespan < splat.lifespan or mo.splatid > splat.splatid)
			P_RemoveMobj(splat)
			return false
		end
	end
	splat.collided[mo.splatid] = true
end,MT_PAINT_WALLSPLAT)

/*
local function splat_destruct(mo)
	if mo.checkedme == nil then return end
	for k, checked in ipairs(mo.checkedme)
		if not (checked and checked.valid) then continue end
		if checked.collided == nil then continue end --!?
		checked.collided[mo] = nil
	end
	mo.checkedme = nil
end
addHook("MobjFuse",splat_destruct,MT_PAINT_SPLATTER)
addHook("MobjRemoved",splat_destruct,MT_PAINT_SPLATTER)
--addHook("MobjDeath",splat_destruct,MT_PAINT_SPLATTER)
*/

addHook("TouchSpecial",function(splat,mo)
	if not (splat and splat.valid) then return end
	if not (mo and mo.valid and mo.health) then return nope(splat); end
	if mo.type ~= MT_PLAYER then return nope(splat); end
	
	local targp = mo.player
	local pnt = targp.paint
	if not Paint:playerIsActive(targp) then return nope(splat,mo); end
	--if R_PointToDist2(splat.x,splat.y, mo.x,mo.y) > (splat.radius*6/7) then return nope(splat,mo); end
	--if (pnt.inkleveltime == leveltime) then return nope(splat,mo); end
	
	local p = splat.tracer_player
	local friendly = false

	if not (p and p.valid)
		friendly = Paint:mobjsOnTeam(mo, splat)
	else
		friendly = Paint:mobjsOnTeam(mo, p.mo)
	end
	
	if friendly
		Paint:setPlayerWallInk(targp)
	end
	return nope(splat,mo);
end,MT_PAINT_WALLSPLAT)

local function brella_destroyfx(mo, p)
	local rad = FixedDiv(mo.radius, mo.scale)
	local hei = FixedDiv(mo.height, mo.scale)
	local ang_s = mo.angle - ANGLE_90
	local ang_f = mo.angle
	local clr = Paint:getPlayerColor(p)
	for i = 0, 15
		local push = FixedMul(rad, P_RandomFixedSigned())
		local nudge = FixedMul(rad/4, P_RandomFixedSigned())
		local zadj = FixedMul(hei, P_RandomFixed())
		local dust = P_SpawnMobjFromMobj(mo,
			P_ReturnThrustX(nil,ang_s, push) + P_ReturnThrustX(nil,ang_f, nudge),
			P_ReturnThrustY(nil,ang_s, push) + P_ReturnThrustY(nil,ang_f, nudge),
			zadj, MT_SPINDUST
		)
		dust.colorized = true
		dust.color = clr
		P_Thrust(dust, FixedAngle(P_RandomFixedRange(0,360*FU)), 5 * P_RandomFixed())
		P_SetObjectMomZ(dust, 2 * P_RandomFixed())
	end
end

local function brella_pain(mo, inf,sor, damage)
	mo.paint_healdelay = TR*3/2
	if not (inf.color == nil or inf.color == SKINCOLOR_NONE)
		mo.paint_color = inf.color
	end
	mo.paint_hp = max($ - damage, 0)
	if mo.paint_hp <= 0
		mo.paint_destroyed = true
		local wep = Paint.weapons[mo.weapon_id]
		local p = mo.tracer.player
		local pt = p.paint
		local soundid = wep:get(pt, "breaksound") or sfx_none
		S_StartSound(mo.tracer, soundid)
		brella_destroyfx(mo, p)
		pt.shieldjustbroke = true
	end
	--print(("DAMAGE: %f"):format(damage))
	return false
end
addHook("ShouldDamage",brella_pain, MT_BRELLA_SHIELD)

addHook("MobjMoveCollide",function(sh,mo)
	if not (sh and sh.valid) then return end
	if not (mo and mo.valid) then return end
	if (mo == sh.tracer) then return end
	if not mo.health then return end
	if not L_ZCollide(sh,mo) then return end
	if (sh.lasthit == mo) then return end
	sh.lasthit = mo
	
	local wep = Paint.weapons[sh.weapon_id]
	local me = sh.tracer
	if not (me and me.valid)
		me = sh.tracer_player.mo
	end
	local p = me.player
	local pt = p.paint
	
	local damage = wep:get(pt, "contactdamage")
	local cooldown = wep:get(pt, "contactcooldown")
	if sh.paint_released
		damage = FixedMul($, wep:get(pt, "releasedmultiplier"))
	end
	
	if Paint_canHurtEnemy(p, mo)
	or mo.type == MT_TNTBARREL
		if not sh.cooldown
			P_DamageMobj(mo,sh,me, damage)
			--P_DamageMobj(sh,mo,mo, damage*5) --debug
			Paint:doProjHitmarker(sh, mo, true)
			Paint.HUD:damageNumber(p, mo, damage)
			
			sh.cooldown = cooldown
			if not sh.paint_released
				Knockback.addKnockback(me, TR, R_PointToAngle2(me.x,me.y, mo.x,mo.y), -16*mo.scale)
			end
		end
		
		Knockback.addKnockback(mo, TR, R_PointToAngle2(mo.x,mo.y, me.x,me.y), -16*mo.scale)
		return
	end
	
	if mo.type == MT_PLAYER
	and mo ~= me
		if Paint_canHurtPlayer(p, mo.player)
			local play = mo.player
			if not sh.cooldown
				Paint:damagePlayer(play,sh,p, damage)
				Paint:playHurtSound(play)
				Paint:doProjHitmarker(sh, mo, true)
				Paint.HUD:damageNumber(p, mo, damage)
				sh.cooldown = cooldown
				if not sh.paint_released
					Knockback.addKnockback(me, TR, R_PointToAngle2(me.x,me.y, mo.x,mo.y), -16*mo.scale)
				end
			end
			Knockback.addKnockback(mo, TR, R_PointToAngle2(mo.x,mo.y, me.x,me.y), -16*mo.scale)
		end
	end
end,MT_BRELLA_SHIELD)

-- reused boatmode code lol
local PROPEL_EASE = Paint.CANOPY_ANIM
local function makeBlob(me, rad,hei)
	local blob = P_SpawnMobjFromMobj(me,
		P_RandomRange(-rad,rad)*FU,
		P_RandomRange(-rad,rad)*FU,
		P_RandomRange(0,hei)*FU,
		MT_PARTICLE
	)
	P_SetMobjStateNF(blob, S_GOOP1)
	blob.sprite = SPR_PAINT_MISC
	blob.frame = 15
	
	blob.tics = -1
	blob.fuse = TR*3/4
	
	blob.color = me.color
	blob.renderflags = $|RF_NOCOLORMAPS|RF_SEMIBRIGHT
	return blob
end
addHook("MobjThinker",function(b)
	if not (b and b.valid) then return end
	if not (b.tracer and b.tracer.valid and b.tracer.health)
	and not b.paint_released
		P_RemoveMobj(b)
		return
	end
	if b.paint_scale == nil then return end
	local me = b.tracer
	if not (me and me.valid)
		me = b.tracer_player.mo
	end
	local p = me.player
	local pt = p.paint
	
	if b.paint_released
		P_InstaThrust(b, b.angle, b.shieldspeed)
		if b.cooldown
			b.cooldown = $ - 1
		end
		if not S_SoundPlaying(b, b.shieldsound)
			S_StartSound(b, b.shieldsound)
		end

		if (P_IsObjectOnGround(b))
		and (leveltime % 3 == 0)
			local trail = P_SpawnMobjFromMobj(b, 0,0,FU, MT_PAINT_SHOT)
			trail.target = me
			trail.tracer_p = p
			trail.color = b.color
			trail.angle = b.angle
			trail.trail = true
			trail.lifespan = 0
			trail.nosound = true
			trail.flags = $|MF_NOCLIPTHING &~(MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOCLIP)
			trail.frame = ($ &~FF_FRAMEMASK)|2
			trail.weapon_id = b.weapon_id
			trail.flags2 = $|MF2_DONTDRAW
		end
		local blob = makeBlob(b, 0, (FixedDiv(b.height, b.scale)/FU)/2)
		local ha = b.angle + FixedAngle(P_RandomFixedRange(-45*FU,45*FU))
		local va = FixedAngle(P_RandomFixedRange(-45*FU,45*FU))
		P_3DInstaThrust(blob, ha,va, 3 * b.scale)
		blob.destscale = 0
		blob.fuse = 10
		blob.scalespeed = FixedDiv(blob.scale, blob.fuse*FU)
		blob.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT &~(MF_NOGRAVITY)

		if b.fuse == 1
			local soundid = Paint.weapons[b.weapon_id]:get(pt, "breaksound") or sfx_none
			S_StartSound(b, soundid)
			brella_destroyfx(b, p)
		end
	end
	
	local xscale,yscale = FU,FU
	
	if b.threshold ~= 0
		local threshold = PROPEL_EASE - b.threshold
		local func = ease.inoutback
		if (pt.shieldlag)
			threshold = b.threshold
		end
		
		local back = FU*3/5
		local frac = (FU/PROPEL_EASE)*threshold
		xscale = ease.inoutback(
			frac,
			FU*4/3, FU, back
		)
		if frac <= FU/2
			yscale = ease.insine(
				frac,
				0, 2*FU
			)
		else
			yscale = ease.outsine(
				frac,
				3*FU, FU
			)
		end
	end
	
	xscale = FixedMul($, b.paint_scale)
	yscale = FixedMul($, b.paint_scale)
	
	b.spritexscale = xscale
	b.spriteyscale = yscale
	
	if b.threshold > 0
		b.threshold = $ - 1
	elseif b.threshold < 0
		b.threshold = $ + 1
	end

	if (b.paint_overlay and b.paint_overlay.valid)
		local ov = b.paint_overlay
		if (b.paint_color == nil)
			ov.color = ColorOpposite(Paint:getPlayerColor(p))
		else
			ov.color = b.paint_color
		end
		ov.alpha = FU - FixedDiv(b.paint_hp, b.paint_maxhp)
		ov.sprite = b.sprite
		ov.frame = A
		ov.frame = b.frame
		ov.angle = b.angle
		ov.spritexscale = b.spritexscale
		ov.spriteyscale = b.spriteyscale
		ov.spritexoffset = b.spritexoffset
		ov.spriteyoffset = b.spriteyoffset
		ov.pitch = 0
		ov.roll = 0
		ov.dispoffset = b.dispoffset + 1
		ov.flags2 = ($ &~MF2_DONTDRAW)|(b.flags2 & MF2_DONTDRAW)
	end
end,MT_BRELLA_SHIELD)