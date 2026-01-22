states[freeslot("S_PAINT_SUCTIONBOMB_F")] = {
	frame = 2|FF_SEMIBRIGHT,
	sprite = SPR_PAINT_BOMB,
	tics = -1,
}
states[freeslot("S_PAINT_SUCTIONBOMB_W")] = {
	frame = 3|FF_SEMIBRIGHT,
	sprite = SPR_PAINT_BOMB,
	tics = -1,
}

sfxinfo[freeslot("sfx_pb_ht5")].caption = "Suction"
Paint:registerSubWeapon({
	realname = "Suction Bomb",
	name = "suctionbomb",
	icon = "PTSUB_SUCTION",
	spawnstate = S_PAINT_SUCTIONBOMB_W,

	fuse = 2*TR,
	
	inner_radius = 210*FU,
	inner_damage = 180*FU,
	outer_radius = 340*FU,
	outer_damage = 30*FU,
	quakeforce = 12*FU,
	guidedrot = true,
	
	blockedfunc = function(bomb, hitceiling, line)
		if bomb.alreadyblocked then return true; end
		bomb.alreadyblocked = true
		bomb.nophysics = true
		bomb.forcefuse = true
		bomb.momx,bomb.momy,bomb.momz = 0,0,0
		S_StartSound(bomb, sfx_pb_ht5)
		S_StopSoundByID(bomb, sfx_pb_fly)
		
		bomb.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT
		bomb.state = S_PAINT_SUCTIONBOMB_F
		if (line and line.valid)
			local line_ang = R_PointToAngle2(
				line.v1.x, line.v1.y, line.v2.x, line.v2.y
			) - ANGLE_90*(P_PointOnLineSide(bomb.x,bomb.y, line) and 1 or -1)
			bomb.angle = line_ang
			
			local ox,oy = P_ClosestPointOnLine(bomb.x,bomb.y, line)
			ox = $ + P_ReturnThrustX(nil, bomb.angle, -(bomb.radius + 2*bomb.scale))
			oy = $ + P_ReturnThrustY(nil, bomb.angle, -(bomb.radius + 2*bomb.scale))
			P_MoveOrigin(bomb, ox,oy, bomb.z)
			bomb.state = S_PAINT_SUCTIONBOMB_W
		else
			bomb.angle = $ + ANGLE_90
		end
		if hitceiling
			bomb.renderflags = $|RF_VERTICALFLIP
		end
		bomb.rollangle = 0
		bomb.roll = 0
		bomb.pitch = 0
		
		bomb.forceangle = bomb.angle
		return true
	end
})
