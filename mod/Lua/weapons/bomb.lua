freeslot(
	"SPR_PAINT_BOMB",
	"S_PAINT_BOMB",
	"MT_PAINT_BOMB"
)
states[S_PAINT_BOMB] = {
	frame = 0|FF_SEMIBRIGHT,
	sprite = SPR_PAINT_BOMB,
	tics = -1,
}

mobjinfo[MT_PAINT_BOMB] = {
	doomednum = -1,
	radius = 16*FU,
	height = 32*FU,
	flags = MF_NOGRAVITY,
	spawnstate = S_PAINT_BOMB
}
sfxinfo[freeslot("sfx_pb_fly")] = {
	caption = "/",
}
for i = 0,4
	sfxinfo[freeslot("sfx_pb_ht"..i)].caption = "Clatter"
end

sfxinfo[freeslot("sfx_pb_alm")].caption = "/"
sfxinfo[freeslot("sfx_pb_exp")].caption = "Explosion"

local function clattersound(mo)
	if not mo.extravalue2
		S_StartSound(mo, sfx_pb_ht0)
		mo.extravalue2 = 1
	else
		S_StartSound(mo, P_RandomRange(sfx_pb_ht1,sfx_pb_ht4))
	end
end

local function splash_blockmap(ray, mo)
	if not (ray and ray.valid) then return end
	if not (mo and mo.valid) then return end
	if (mo == ray.donthit and ray.forcehit ~= mo) then return end
	if (ray.donthit and ray.donthit.paint_shield and (mo == ray.donthit.tracer))
		return
	end
	if not mo.health then return end
	if not P_CheckSight(ray,mo) then return end
	local sub_t = Paint.subs[ray.subtype]
	local splashrad = FixedMul(sub_t.outer_radius, ray.scale)
	if abs(ray.x - mo.x) > splashrad + mo.radius
	or abs(ray.y - mo.y) > splashrad + mo.radius
		return
	end
	local dist = R_PointTo3DDist(ray.x, ray.y, ray.z, mo.x,mo.y,mo.z)
	if dist > splashrad then return end
	
	local damage = sub_t.outer_damage
	if dist <= FixedMul(sub_t.inner_radius, ray.scale)
		damage = sub_t.inner_damage
	end
	
	if Paint_canHurtEnemy(ray.target.player, mo)
	or mo.type == MT_TNTBARREL
		P_DamageMobj(mo, ray, ray.target, damage)
		if ray.allowhitmarkers
			Paint:doProjHitmarker(ray, mo, false)
		end
		Paint.HUD:damageNumber(ray.target.player, mo, damage)
		return
	end
	
	local me = ray.target
	local p = me.player
	
	if mo.type == MT_PLAYER
	and mo ~= me
		if Paint_canHurtPlayer(p, mo.player)
			Paint:damagePlayer(mo.player, ray, p, damage)
			Paint:playHurtSound(mo.player)
			if ray.allowhitmarkers
				Paint:doProjHitmarker(ray, mo, false)
				Paint.HUD:damageNumber(ray.target.player, mo, damage)
			end
		elseif Paint_canHurtPlayer(p, mo.player, true)
		and not Paint:isFriendlyFire(p,mo.player)
		and ray.allowhitmarkers
			Paint:doProjHitmarker(ray, mo, false, true)
		end
	end
end
function Paint:bombExplosion(mo, subtype)
	if not (mo and mo.valid) then return end
	local sub_t = Paint.subs[subtype]

	local sfx = P_SpawnGhostMobj(mo)
	sfx.flags2 = $|MF2_DONTDRAW
	sfx.fuse = 2 * TR; sfx.tics = sfx.fuse
	local sound = sub_t.explodesound
	S_StartSound(sfx, sound)
	S_StartSound(sfx, sound)
	
	local splashrad = sub_t.outer_radius
	P_StartQuake(sub_t.quakeforce, 10, {mo.x,mo.y,mo.z}, splashrad * 6/5)
	
	local bam = P_SpawnMobjFromMobj(mo, 0,0,0, MT_THOK)
	P_SetMobjStateNF(bam, S_TNTBARREL_EXPL3)
	bam.spritexscale = FixedDiv(sub_t.inner_radius, 208*FU) * 2
	bam.spriteyscale = bam.spritexscale
	bam.renderflags = $|RF_FULLBRIGHT|RF_NOCOLORMAPS
	bam.blendmode = AST_ADD
	bam.colorized = true
	bam.color = mo.color
	
	for i = 0,2
		local outline = P_SpawnMobjFromMobj(mo, 0,0,0, MT_PAINT_SHOT)
		outline.visualfadestupidshit = true
		outline.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOCLIPTHING
		outline.fuse = 9
		outline.radius = 40*mo.scale
		outline.sprite = SPR_PAINT_MISC
		outline.frame = ($ &~FF_FRAMEMASK)|18
		outline.spritexscale = FixedDiv(sub_t.inner_radius, 80*FU) * 2
		outline.spriteyscale = outline.spritexscale
		outline.renderflags = $|RF_FULLBRIGHT|RF_NOCOLORMAPS|RF_PAPERSPRITE|RF_NOSPLATBILLBOARD
		outline.blendmode = AST_ADD
		outline.colorized = true
		outline.color = mo.color
		outline.angle = mo.angle + (ANGLE_90 * i)
		if i == 2
			outline.renderflags = $|RF_FLOORSPRITE &~RF_PAPERSPRITE
		end
	end

	local step = FixedDiv(360*FU, 9*FU)
	local inner_step = FixedMul(sub_t.inner_radius - 64*FU, mo.scale)
	for i = 0,8
		local angle = FixedAngle(P_RandomFixedRange(0,360*FU))
		local drop = P_SpawnMobjFromMobj(mo,0,0,FU, MT_PAINT_SHOT)
		if drop and drop.valid
			drop.target = mo.target
			drop.angle = angle
			drop.color = mo.color
			drop.trail = true
			drop.lifespan = 0
			drop.flags = $|MF_NOCLIPTHING &~MF_NOGRAVITY
			drop.tracer_player = mo.target.player
			P_SetObjectMomZ(drop, P_RandomFixedRange(4*FU,16*FU))
			P_Thrust(drop, angle, P_RandomFixedRange(4*FU,16*FU))
		end
		-- cover the base of the bomb too
		local ox = P_ReturnThrustX(nil, FixedAngle(step*i), inner_step)
		local oy = P_ReturnThrustY(nil, FixedAngle(step*i), inner_step)
		for j = 0,1
			local drop = P_SpawnMobjFromMobj(mo,ox,oy,FU, MT_PAINT_SHOT)
			if drop and drop.valid
				drop.target = mo.target
				drop.angle = mo.angle
				drop.color = mo.color
				drop.trail = true
				drop.nosound = true
				drop.lifespan = 0
				drop.flags = $|MF_NOCLIPTHING &~MF_NOGRAVITY
				drop.tracer_player = mo.target.player
			end
		end
	end
	local drop = P_SpawnMobjFromMobj(mo,0,0,FU, MT_PAINT_SHOT)
	if drop and drop.valid
		drop.target = mo.target
		drop.angle = mo.angle
		drop.color = mo.color
		drop.trail = true
		drop.nosound = true
		drop.lifespan = 0
		drop.flags = $|MF_NOCLIPTHING &~MF_NOGRAVITY
		drop.tracer_player = mo.target.player
	end
	
	/*
	for i = -1,1,2
		local z = splashrad * i
		P_SpawnMobjFromMobj(mo, splashrad, splashrad, z, MT_THOK)
		P_SpawnMobjFromMobj(mo, splashrad, -splashrad, z, MT_THOK)
		P_SpawnMobjFromMobj(mo, -splashrad, splashrad, z, MT_THOK)
		P_SpawnMobjFromMobj(mo, -splashrad, -splashrad, z, MT_THOK)
	end
	local max = 16
	local fa = FixedDiv(360*FU, max*FU)
	local inner = sub_t.inner_radius
	for i = 0,max-1
		for j = 0, (max*2)-1
			local v = SphereToCartesian(FixedAngle(fa*i), FixedAngle(fa*j))
			local part = P_SpawnMobjFromMobj(mo,
				FixedMul(splashrad,v.x),
				FixedMul(splashrad,v.y),
				FixedMul(splashrad,v.z),
				MT_THOK
			)
			part.color = ColorOpposite(mo.color)
			part.scale = $ / 2
			
			part = P_SpawnMobjFromMobj(mo,
				FixedMul(inner,v.x),
				FixedMul(inner,v.y),
				FixedMul(inner,v.z),
				MT_THOK
			)
			part.color = mo.color
		end
	end
	*/
	local px = mo.x
	local py = mo.y
	local br = splashrad * 7/5
	searchBlockmap("objects",splash_blockmap, mo, px-br, px+br, py-br, py+br)
end

function Paint:bombPhysics(mo, subtype, aimline)
	if not (mo and mo.valid) then return end
	local sub_t = Paint.subs[subtype]
	
	if sub_t.physicsthink ~= nil
		if sub_t.physicsthink(mo, subtype, aimline)
			return true
		end
	end

	if not P_IsObjectOnGround(mo)
	and not mo.nophysics
		mo.momx = FixedMul($, mo.airdrag)
		mo.momy = FixedMul($, mo.airdrag)
		mo.momz = $ - (FixedMul(mo.scale, mo.gravmul) * P_MobjFlip(mo))
		mo.momz = FixedMul($, mo.airdrag)
	end
end

addHook("MobjThinker",function(sub)
	if not (sub and sub.valid) then return end
	local sub_t = Paint.subs[sub.subtype]
	
	--P_ButteredSlope(sub)
	if Paint:bombPhysics(sub, sub.subtype, false)
		return
	end
	
	if sub.fusetimer <= 32
		local timer = sub.fusetimer
		local flashtime = 1 << (timer * 3/5)
		flashtime = $ * 3/5
		flashtime = min(8, max($ >> 4, 2))
		if (timer % flashtime ~= 0)
			sub.translation = nil
		else
			sub.translation = "AllWhite"
		end
	end
	
	if not sub.guidedrot
		sub.angle = $ + FixedAngle(R_PointToDist2(0,0, sub.momx,sub.momy))
	else
		sub.angle = R_PointToAngle2(0,0, sub.momx, sub.momy)
	end
	if sub.forceangle ~= nil
		sub.angle = sub.forceangle
	end
	
	local dofuse = sub.forcefuse
	if sub.z + sub.momz + sub.height >= sub.ceilingz
		if sub_t.blockedfunc ~= nil
			if sub_t.blockedfunc(sub, true)
				return
			end
			if not (sub and sub.valid) then return end
		end
		if sub.explodeoncontact
			Paint:bombExplosion(sub, sub.subtype)
			P_KillMobj(sub)
			return
		end
		
		clattersound(sub)
		sub.momz = -$
	end
	
	if P_IsObjectOnGround(sub)
		sub.extravalue1 = $ + 1
		if sub.extravalue1 >= 4
			S_StopSoundByID(sub, sfx_pb_fly)
		end
		
		sub.flags = $ &~MF_NOGRAVITY
		if not sub.wasgrounded
			if sub_t.blockedfunc ~= nil
				if sub_t.blockedfunc(sub, false)
					if sub and sub.valid
						sub.wasgrounded = true
					end
					return
				end
				if not (sub and sub.valid) then return end
			end
			if sub.explodeoncontact
				Paint:bombExplosion(sub, sub.subtype)
				P_KillMobj(sub)
				return
			end
			
			clattersound(sub)
			if R_PointToDist2(0,0, sub.momx,sub.momy) >= 20 * sub.scale
				sub.momz = 3 * sub.scale * P_MobjFlip(sub)
			end
			
			sub.momx = $ / 3
			sub.momy = $ / 3
		else
			if R_PointToDist2(0,0, sub.momx,sub.momy) < 10 * sub.scale
				dofuse = true
			end
		end
	else
		sub.flags = $|MF_NOGRAVITY
		if not sub.nophysics
			if sub.guidedrot
				sub.rollangle = 0
				local angle = R_PointToAngle2(0,0, sub.momx,sub.momy)
				local mang = R_PointToAngle2(0,0, FixedHypot(sub.momx, sub.momy), sub.momz)
				mang = InvAngle($)
				
				sub.roll = FixedMul(mang, sin(angle))
				sub.pitch = FixedMul(mang, cos(angle))
			else
				sub.rollangle = $ + FixedAngle(abs(sub.momz) + 10*FU)
			end
		else
			sub.roll = 0
			sub.pitch = 0
		end
	end
	
	if dofuse
		if sub.fusetimer <= TR
		and not sub.playedalarm
			S_StartSound(sub, sfx_pb_alm)
			sub.playedalarm = true
		elseif sub.fusetimer == 0
			Paint:bombExplosion(sub, sub.subtype)
			P_KillMobj(sub)
			return
		end
		
		sub.fusetimer = $ - 1
	end
	
	sub.wasgrounded = P_IsObjectOnGround(sub)
end,MT_PAINT_BOMB)

addHook("MobjMoveCollide",function(bomb, thing)
	if not (bomb and bomb.valid) then return end
	if not (thing and thing.valid) then return end
	if not thing.health then return end
	if not L_ZCollide(bomb,thing) then return end
	if (bomb.lasthit == thing) then return end
	bomb.lasthit = thing
	
	local sub_t = Paint.subs[bomb.subtype]
	
	local forceexplosion = false
	if (thing.paint_explodebombs)
	and (thing.target ~= bomb.target)
		forceexplosion = true
	end
	
	if (bomb.explodeoncontact)
		if (Paint_canHurtEnemy(bomb.tracer_player, thing)
		or thing.type == MT_TNTBARREL)
		or (thing.type == MT_PLAYER and (thing ~= bomb.target)
		and Paint_canHurtPlayer(bomb.tracer_player, thing.player))
			forceexplosion = true
		end
	end
	
	if forceexplosion
		bomb.donthit = thing
		bomb.forcehit = thing
		Paint:bombExplosion(bomb, bomb.subtype)
		P_KillMobj(bomb)
		return
	end
end,MT_PAINT_BOMB)

addHook("MobjMoveBlocked",function(me, thing,line)
	local sub_t = Paint.subs[me.subtype]
	if sub_t.blockedfunc ~= nil
		if sub_t.blockedfunc(me, false, line)
			return
		end
		if not (me and me.valid) then return end
	end
	if me.explodeoncontact
		Paint:bombExplosion(me, me.subtype)
		P_KillMobj(me)
		return
	end
	clattersound(me)

	if (line and line.valid)
		local line_ang = R_PointToAngle2(
			line.v1.x, line.v1.y, line.v2.x, line.v2.y
		)
		local speed = FixedDiv(20*me.scale, me.friction)
		speed = $ + abs(FixedMul(
			R_PointToDist2(0,0,me.momx,me.momy) * 3/4,
			sin(line_ang - R_PointToAngle2(0,0,me.momx,me.momy))
		))
		
		--its ambiguous syntax to have the `func` definition on the same line
		--as the call, so :shrug:
		--C DOESNT COMPLAIN....
		local func = ((P_IsObjectOnGround(me)) and P_Thrust or P_InstaThrust)
		func(me,
			line_ang - ANGLE_90*(P_PointOnLineSide(me.x,me.y, line) and 1 or -1),
			-speed / 4
		)
		return true
	end
	P_BounceMove(me)
	return true	
end,MT_PAINT_BOMB)