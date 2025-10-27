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

freeslot("S_PAINT_SPLASH")
states[S_PAINT_SPLASH] = {
	sprite = SPR_PAINT_MISC,
	frame = 6|FF_ANIMATE,
	var1 = 14 - 6,
	var2 = 2,
	tics = (14 - 6)*2,
}
