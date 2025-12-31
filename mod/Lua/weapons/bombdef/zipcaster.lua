freeslot("sfx_z_fire")
freeslot("sfx_z_hit")
freeslot("sfx_z_mve0")
freeslot("sfx_z_mve1")
freeslot("sfx_z_rech")

freeslot("S_ZIPCAST")
states[S_ZIPCAST] = {
	sprite = SPR_THOK,
	frame = A|FF_SEMIBRIGHT,
	action = function(mo)
		local g = P_SpawnGhostMobj(mo)
		g.fuse = TR
		g.tics = g.fuse
		g.scale = $ / 2
	end,
	tics = 1,
	nextstate = S_ZIPCAST
}

Paint:registerSubWeapon({
	realname = "Zipcaster",
	name = "zipcaster",
	spawnstate = S_ZIPCAST,

	fuse = 2*TR,
	
	inkcost = FU,
	inner_radius = 0*FU,
	inner_damage = 0*FU,
	outer_radius = 0*FU,
	outer_damage = 0*FU,
	quakeforce = 0*FU,
	guidedrot = true,
	nophysics = true,
	
	physicsthink = function(bomb, subtype, aimline)
		if not bomb.extravalue2
			bomb.base_momx = bomb.momx
			bomb.base_momy = bomb.momy
			bomb.base_momz = bomb.momz
			bomb.radius = 16*FU
			bomb.height = 32*FU
			
			bomb.extravalue2 = 1
			if not aimline
				S_StartSound(bomb.target, sfx_z_fire)
				bomb.tracer_player.zipcast_line = nil
			end
		end
		bomb.momx = bomb.base_momx
		bomb.momy = bomb.base_momy
		bomb.momz = bomb.base_momz
		
		if aimline then return end
		S_StopSoundByID(bomb, sfx_pb_fly)
		for i = 0,2
			P_TryMove(bomb, bomb.x + bomb.momx, bomb.y + bomb.momy, true)
			P_ZMovement(bomb)
		end
	end,
	blockedfunc = function(bomb, hitceiling, line)
		local p = bomb.tracer_player
		local me = p.mo
		p.zipcast_start = {x = me.x + me.momx, y = me.y + me.momy, z = me.z + me.momz}
		p.zipcast_end = {x = bomb.x, y = bomb.y, z = bomb.z}
		local cast_tics = 5
		local dist = R_PointTo3DDist(
			me.x + me.momx, me.y + me.momy, me.z + me.momz,
			bomb.x, bomb.y, bomb.z
		) / FU
		cast_tics = $ + abs(dist / 128)
		
		p.zipcast_startup = 8
		p.zipcast_tics = cast_tics
		p.zipcast_starttic = p.zipcast_tics
		p.zipcast_line = line
		
		S_StopSoundByID(me, sfx_z_fire)
		S_StartSound(me, sfx_z_hit)
		
		P_RemoveMobj(bomb)
		return true
	end
})

addHook("PlayerThink",function(p)
	local me = p.realmo
	if not (me and me.valid) then return end
	local pt = p.paint
	
	if not me.health
		p.zipcast_startup = nil
		p.zipcast_tics = nil
		p.zipcast_start = nil
		p.zipcast_end = nil
		p.zipcast_line = nil
		return
	end
	
	local zipping = false
	if p.zipcast_startup
	or p.zipcast_tics
		p.powers[pw_nocontrol] = 3
		p.pflags = $|PF_FULLSTASIS
		p.cmd.buttons = 0
		zipping = true
	end
	
	if p.zipcast_startup
		p.zipcast_startup = $ - 1
		local st = p.zipcast_start
		
		me.flags = $|MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT
		me.momx, me.momy, me.momz = 0,0,0
		me.state = S_PLAY_SPRING
		P_MoveOrigin(me,
			st.x,st.y,st.z
		)
		
		if p.zipcast_startup == 0
			S_StartSound(me, sfx_z_mve0)
			S_StartSound(me, sfx_z_mve1)
		end
	elseif p.zipcast_tics
		p.zipcast_tics = $ - 1
		local progress = ease.inquad(FU - ((FU/p.zipcast_starttic) * p.zipcast_tics), 0, FU)
		local st = p.zipcast_start
		local ed = p.zipcast_end
		local ox = st.x + FixedMul(ed.x - st.x, progress)
		local oy = st.y + FixedMul(ed.y - st.y, progress)
		local oz = st.z + FixedMul(ed.z - st.z, progress)
		me.flags = $|MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT
		me.momx, me.momy, me.momz = 0,0,0
		me.state = S_PLAY_GLIDE
		
		pt.fovadd = 28 * progress
		P_MoveOrigin(me,
			ox,oy,oz
		)
		Paint.HUD:cameraLag(p,12)
		me.angle = R_PointToAngle2(st.x,st.y, ed.x,ed.y)
		p.drawangle = me.angle
	elseif (p.zipcast_starttic)
		me.flags = $ &~(MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT)
		p.zipcast_start = nil
		p.zipcast_end = nil
		p.zipcast_starttic = nil
		
		S_StopSoundByID(me, sfx_z_mve0)
		S_StopSoundByID(me, sfx_z_mve1)
		S_StartSound(me, sfx_z_rech)
		
		if not (p.zipcast_line and p.zipcast_line.valid)
			me.state = S_PLAY_ROLL
		end
		if P_IsObjectOnGround(me)
			me.state = S_PLAY_WALK
		end
		P_ResetPlayer(p)
		P_MovePlayer(p)
	end
	
	if not zipping
	and (p.zipcast_line and p.zipcast_line.valid)
		local line = p.zipcast_line
		me.flags = $|MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT
		me.state = S_PLAY_CLING
		me.momx, me.momy, me.momz = 0,0,0
		p.powers[pw_nocontrol] = 3
		p.pflags = $|PF_FULLSTASIS
		
		local line_ang = R_PointToAngle2(
			line.v1.x, line.v1.y, line.v2.x, line.v2.y
		) - ANGLE_90*(P_PointOnLineSide(me.x,me.y, line) and 1 or -1)
		p.drawangle = line_ang
		
		local ox,oy = P_ClosestPointOnLine(me.x,me.y, line)
		ox = $ + P_ReturnThrustX(nil, p.drawangle, -(me.radius*2 + 2*me.scale))
		oy = $ + P_ReturnThrustY(nil, p.drawangle, -(me.radius*2 + 2*me.scale))
		P_MoveOrigin(me, ox,oy, me.z)
		
		if (p.cmd.buttons & BT_JUMP)
		or (pt.fireheld)
			p.powers[pw_nocontrol] = 0
			p.pflags = $ &~PF_FULLSTASIS
			if (p.cmd.buttons & BT_JUMP)
				P_DoJump(p, true)
			else
				me.state = S_PLAY_FALL
			end
			
			p.zipcast_line = nil
			me.flags = $ &~(MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT)
		end
	end
end)