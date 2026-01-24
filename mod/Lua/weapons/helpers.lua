-- helper funcs for general painting stuff

-- spawns a spray droplet at the given coordinates
-- if x,y, or z are nil, coordinates fall back to the mobj's position
-- color falls back to source_player's color, mobj's color, or SKINCOLOR_GREEN
-- returns the spawned droplet
function Paint.spawnDroplet(mobj, source_player, color, nosound, x,y,z, ox,oy,oz)
	ox = $ or 0
	oy = $ or 0
	oz = $ or 0
	
	if (x == nil or y == nil or z == nil)
	and (mobj and mobj.valid)
		x,y,z = mobj.x, mobj.y, mobj.z
	end
	
	if (color == nil or color == SKINCOLOR_NONE)
		color = SKINCOLOR_GREEN
		if (source_player and source_player.valid)
			color = Paint:getPlayerColor(source_player)
		elseif (mobj and mobj.valid)
			color = mobj.color
		end
	end
	
	local drop
	if (mobj and mobj.valid)
		drop = P_SpawnMobjFromMobj(mobj, ox,oy,oz, MT_PAINT_SHOT)
	else
		drop = P_SpawnMobj(x + ox, y + oy, z + oz, MT_PAINT_SHOT)
	end
	drop.target = mobj
	drop.color = color
	drop.trail = true
	drop.nosound = nosound
	drop.lifespan = 0
	drop.flags = $|MF_NOCLIPTHING &~MF_NOGRAVITY
	drop.tracer_player = source_player
	drop.frame = ($ &~FF_FRAMEMASK)|2
	
	return drop
end

-- spawns a bullet droplet at the given coordinates
-- if x,y, or z are nil, coordinates fall back to the mobj's position
-- color falls back to source_player's color, mobj's color, or SKINCOLOR_GREEN
-- returns the spawned bullet
-- These cant cause damage to anything!!
function Paint.spawnBulletDrop(mobj, source_player, color, h_angle,v_angle,thrust, x,y,z, ox,oy,oz)
	ox = $ or 0
	oy = $ or 0
	oz = $ or 0
	
	h_angle = $ or 0
	v_angle = $ or 0
	thrust = $ or 0
	
	if (x == nil or y == nil or z == nil)
	and (mobj and mobj.valid)
		x,y,z = mobj.x, mobj.y, mobj.z
	end
	
	if (color == nil or color == SKINCOLOR_NONE)
		color = SKINCOLOR_GREEN
		if (source_player and source_player.valid)
			color = Paint:getPlayerColor(source_player)
		elseif (mobj and mobj.valid)
			color = mobj.color
		end
	end
	
	local drop
	if (mobj and mobj.valid)
		drop = P_SpawnMobjFromMobj(mobj, ox,oy,oz + FU, MT_PAINT_SHOT)
	else
		drop = P_SpawnMobj(x + ox, y + oy, z + oz, MT_PAINT_SHOT)
	end
	drop.target = mobj
	drop.color = color
	drop.trail = true
	drop.lifespan = 0
	drop.flags = $|MF_NOCLIPTHING &~MF_NOGRAVITY
	drop.tracer_player = source_player
	
	P_3DThrust(drop, h_angle,v_angle, thrust)
	return drop
end

function Paint.explosionVFX(mo, radius, angle, color)
	angle = $ or mo.angle
	color = $ or mo.color
	
	local bam = P_SpawnMobjFromMobj(mo, 0,0,0, MT_THOK)
	P_SetMobjStateNF(bam, S_TNTBARREL_EXPL3)
	bam.spritexscale = FixedDiv(radius, 208*FU) * 2
	bam.spriteyscale = bam.spritexscale
	bam.renderflags = $|RF_FULLBRIGHT|RF_NOCOLORMAPS
	bam.blendmode = AST_ADD
	bam.colorized = true
	bam.color = color
	
	for i = 0,2
		local outline = P_SpawnMobjFromMobj(mo, 0,0,0, MT_PAINT_SHOT)
		outline.visualfadestupidshit = true
		outline.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOCLIPTHING
		outline.fuse = 9
		outline.radius = 40*mo.scale
		outline.sprite = SPR_PAINT_MISC
		outline.frame = ($ &~FF_FRAMEMASK)|18
		outline.spritexscale = FixedDiv(radius, 80*FU) * 2
		outline.spriteyscale = outline.spritexscale
		outline.renderflags = $|RF_FULLBRIGHT|RF_NOCOLORMAPS|RF_PAPERSPRITE|RF_NOSPLATBILLBOARD
		outline.blendmode = AST_ADD
		outline.colorized = true
		outline.color = color
		outline.angle = angle + (ANGLE_90 * i)
		if i == 2
			outline.renderflags = $|RF_FLOORSPRITE &~RF_PAPERSPRITE
		end
	end
end

function Paint.inkShockVFX(me, dist, color, scale, count)
	scale = $ or FU
	count = $ or 16
	
	local speed = FixedMul(6*FU, scale)
	local angstep = FixedDiv(360*FU, count*FU)
	for i = 0, count - 1
		local fa = FixedAngle(angstep * i)
		local s = P_SpawnMobjFromMobj(me,
			P_ReturnThrustX(nil, fa, dist),
			P_ReturnThrustY(nil, fa, dist),
			0, MT_PARTICLE
		)
		s.spritexscale = FU / 4
		s.renderflags = $|RF_FLOORSPRITE|RF_NOSPLATBILLBOARD|RF_SLOPESPLAT
		P_CreateFloorSpriteSlope(s)
		s.angle = fa
		s.aiming = 70*FU
		s.fuse = states[S_PAINT_SHOCK].var1
		s.state = S_PAINT_SHOCK
		s.color = color
		
		P_SetScale(s, scale, true)
		P_Thrust(s, fa, speed)
	end
end