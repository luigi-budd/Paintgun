freeslot("S_PAINT_SUCTIONBOMB")
states[S_PAINT_SUCTIONBOMB] = {
	frame = 0|FF_SEMIBRIGHT,
	sprite = SPR_BARR,
	tics = -1,
}

sfxinfo[freeslot("sfx_pb_ht5")].caption = "Suction"
Paint:registerSubWeapon({
	realname = "Suction Bomb",
	name = "suctionbomb",
	icon = "PTSUB_SUCTION",
	spawnstate = S_PAINT_SUCTIONBOMB,

	fuse = 2*TR,
	
	inner_radius = 210*FU,
	inner_damage = 180*FU,
	outer_radius = 340*FU,
	outer_damage = 30*FU,
	quakeforce = 12*FU,
	guidedrot = true,
	
	blockedfunc = function(bomb, hitceiling, line)
		bomb.nophysics = true
		bomb.forcefuse = true
		bomb.momx,bomb.momy,bomb.momz = 0,0,0
		S_StartSound(bomb, sfx_pb_ht5)
		S_StopSoundByID(bomb, sfx_pb_fly)
		
		if (line and line.valid)
			bomb.angle = R_PointToAngle2(
				line.v1.x, line.v1.y, line.v2.x, line.v2.y
			) - ANGLE_90*(P_PointOnLineSide(bomb.x,bomb.y, line) and 1 or -1)
		end
		if hitceiling
			bomb.renderflags = $|RF_VERTICALFLIP
		end
		bomb.rollangle = 0
		bomb.roll = 0
		bomb.pitch = 0
		
		return true
	end,
	physicsthink = function(bomb, _, aim)
		if aim then return end
		bomb.colorized = true
	end
})
