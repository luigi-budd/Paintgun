-- auxiliary functions and SHIT!

function Paint:controlDir(p)
	local pt = p.paint
	return (p.cmd.angleturn << 16) + R_PointToAngle2(0, 0, pt.forwardmove << 16, -pt.sidemove << 16)
end

local ORIG_FRICTION = (232 << (FRACBITS-8)) --this should really be exposed...
function Paint.slopeInfluence(mobj,player, options, p_slope)
	if (mobj.flags & (MF_NOCLIPHEIGHT|MF_NOGRAVITY)) then return end
	
	if options == nil then options = {} end
	
	local thrust
	local slope = (p_slope and p_slope.valid) and p_slope or mobj.standingslope
	local p = (player and player.valid) and player or mobj.player
	
	if not (slope and slope.valid) then return end
	if (slope.flags & SL_NOPHYSICS) then return end
	
	if (p and p.valid)
	or (options.allowstand)
		if abs(slope.zdelta) < FU/4
			if not(p and p.valid)
			or not (p.pflags & PF_SPINNING)
				return
			end
		end
		
		if abs(slope.zdelta) < FU/2
			if not (p and p.valid)
				if not (mobj.momx or mobj.momy)
					return
				end
			else
				if not (p.rmomz or p.rmomy)
					return
				end
			end
		end
	end
	thrust = sin(slope.zangle)*3/2 * (-P_MobjFlip(mobj))
	
	if (p and p.pflags & PF_SPINNING)
	or (options.allowmult)
		local mul = 0
		if (mobj.momx or mobj.momy)
			local angle = R_PointToAngle2(0,0,mobj.momx,mobj.momy) - slope.xydirection
			
			if P_MobjFlip(mobj) * slope.zdelta < 0
				angle = $^ANGLE_180
			end
			mul = cos(angle)
		end
		thrust = FixedMul($, FU*2/3 + mul/8)
	end
	
	if (mobj.momx or mobj.momy)
		thrust = FixedMul($, FU + R_PointToDist2(0,0,mobj.momx,mobj.momy)/16)
	end
	thrust = FixedMul($, abs(P_GetMobjGravity(mobj)))
	
	thrust = FixedMul($, FixedDiv(mobj.friction,ORIG_FRICTION))
	return slope.xydirection,thrust
end

function Paint.CheckFloorPic(me, checkgrounded)
	if checkgrounded and not P_IsObjectOnGround(me) then return ""; end
	
	local sector = me.subsector.sector
	local flip = (me.eflags & MFE_VERTICALFLIP == MFE_VERTICALFLIP)
	local floorpic = sector.floorpic
	if flip
		floorpic = sector.ceilingpic
	end
	
	for rover in sector.ffloors()
		if (rover.flags & FOF_BLOCKPLAYER) == 0 then continue end
		if (rover.flags & FF_EXISTS) == 0 then continue end
		
		local topheight = rover.topheight
		local bottomheight = rover.bottomheight
		if (rover.t_slope and rover.t_slope.valid)
			topheight = P_GetZAt(rover.t_slope, me.x,me.y)
		end
		if (rover.b_slope and rover.b_slope.valid)
			bottomheight = P_GetZAt(rover.b_slope, me.x,me.y)
		end
		
		-- over/under
		if (me.z > topheight and checkgrounded)
		or me.z + me.height < bottomheight -- FU
			continue
		end
		
		floorpic = flip and rover.bottompic or rover.toppic
		sector = rover.sector
	end
	return floorpic, sector
end

freeslot("S_PAINT_SPLASH")
states[S_PAINT_SPLASH] = {
	sprite = SPR_PAINT_MISC,
	frame = 6|FF_ANIMATE|FF_SEMIBRIGHT,
	var1 = 14 - 6,
	var2 = 2,
	tics = (14 - 6)*2,
}
freeslot("S_PAINT_SPLASH2")
states[S_PAINT_SPLASH2] = {
	sprite = SPR_PAINT_MISC,
	frame = 10|FF_ANIMATE|FF_SEMIBRIGHT,
	var1 = 14 - 10,
	var2 = 2,
	tics = (14 - 10)*2,
}

freeslot("S_PAINT_FLAIR")
states[S_PAINT_FLAIR] = {
	sprite = SPR_PAINT_MISC,
	frame = 19|FF_FULLBRIGHT|FF_ADD,
	tics = -1,
	nextstate = S_PAINT_FLAIR
}

freeslot("S_PAINT_CHARGEDMAX")
states[S_PAINT_CHARGEDMAX] = {
	sprite = SPR_PAINT_MISC,
	frame = 21|FF_FULLBRIGHT|FF_ADD|FF_ANIMATE,
	tics = (10 * 2),
	var1 = 10,
	var2 = 2,
}

freeslot("S_PAINT_BROKEARMOR")
states[S_PAINT_BROKEARMOR] = {
	sprite = SPR_PAINT_MISC,
	frame = 34|FF_FULLBRIGHT|FF_ADD|FF_PAPERSPRITE,
	tics = 1,
	action = function(s)
		s.angle = $ + s.rang
		s.rollangle = $ + s.rroll
		
		if P_IsObjectOnGround(s)
			s.momz = -s.prevmomz / 2
		end
		s.prevmomz = s.momz
	end,
	nextstate = S_PAINT_BROKEARMOR
}
