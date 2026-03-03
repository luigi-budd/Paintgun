/*
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
*/

-- sprinkler phases
Paint.SPN_DEPLOY = 0
Paint.SPN_HIGH   = 1
Paint.SPN_MID    = 2
Paint.SPN_LOW    = 3
local phase2time = {
	[Paint.SPN_DEPLOY] = TR/2,
	[Paint.SPN_HIGH]   = 5*TR,
	[Paint.SPN_MID]    = 15*TR,
	[Paint.SPN_LOW]    = -1, -- infinite
}
local nextphase = {
	[Paint.SPN_DEPLOY]	= Paint.SPN_HIGH,
	[Paint.SPN_HIGH]	= Paint.SPN_MID,
	[Paint.SPN_MID]		= Paint.SPN_LOW,
	[Paint.SPN_LOW]	= Paint.SPN_LOW -- just so things dont error
}

local phasedata = {
	[Paint.SPN_HIGH] = {
		spraytic = 2,
		rotate = 33*FU,
		rottic = 1,
		
		speed_min = 20*FU,
		speed_max = 40*FU
	},
	[Paint.SPN_MID] = {
		spraytic = 4,
		rotate = 11*FU,
		rottic = 1,
		
		speed_min = 20*FU,
		speed_max = 40*FU
	},
	[Paint.SPN_LOW] = {
		spraytic = 6,
		rotate = 1*FU,
		rottic = 1,
		
		speed_min = 20*FU,
		speed_max = 40*FU
	},
}

local function RandomPerpendicular(v)
    local up = P_Vec3.New(0, 0, FU)

    if abs(v:Dot(up)) > (99 * FU / 100) then
        up = P_Vec3.New(FU, 0, 0)
    end

    return v:Cross(up):Normalize()
end

Paint:registerWeapon({
	name = "sprinkler_bullet",
	hidden = true,
	damage = 20*FU,
	falloffdamage = 10*FU,
	
	str_tics = 4, -- straight state lasts this many tics
	str2brk_maxspeed = FixedMul(tofixed("1.493"), Paint.DU2FU), -- when ending straight state, cap xyspeed to this
	brk_airresist = FU * 64/100, -- xy AND z moms are affected by air resistance
	brk_gravity = FixedMul(tofixed("0.07"), Paint.DU2FU),
	brk2fre_minz = FixedMul(tofixed("-0.15"), Paint.DU2FU), -- go to free when momz is below this
	brk2fre_minxy = FixedMul(tofixed("0.2355"), Paint.DU2FU), -- or go to free when xyspeed is below this
	brk2fre_tics = 4, -- or when brake state lasts this many tics
	fre_airresist = FU * 98/100,
	fre_gravity = FixedMul(tofixed("0.06"), Paint.DU2FU),
	crs_guideframe = 8, -- crosshair is placed at this frame in the shot's lifetime
})

Paint:registerSubWeapon({
	realname = "Sprinkler",
	name = "sprinkler",
	icon = "PTSUB_SUCTION",
	spawnstate = S_PAINT_SUCTIONBOMB_W,

	fuse = -1,
	
	inner_radius = 210*FU,
	inner_damage = 180*FU,
	outer_radius = 340*FU,
	outer_damage = 30*FU,
	quakeforce = 12*FU,
	guidedrot = false,
	
	blockedfunc = function(bomb, hitceiling, line)
		if bomb.alreadyblocked then return true; end
		if (bomb.tracer_player.submobj and bomb.tracer_player.submobj.valid)
			P_KillMobj(bomb.tracer_player.submobj)
		end
		
		bomb.alreadyblocked = true
		bomb.nophysics = true
		bomb.forcefuse = true
		bomb.momx,bomb.momy,bomb.momz = 0,0,0
		
		bomb.phase = Paint.SPN_DEPLOY
		bomb.phasetime = phase2time[bomb.phase]
		bomb.rotwait = 0
		bomb.spraywait = 0
		
		Paint:teamSound(bomb.tracer_player, bomb, sfx_pb_ht5, nil, sfx_pb_ht5)
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
		bomb.wallmode = (line and line.valid)
		bomb.ceilingmode = hitceiling
		
		bomb.aiming = bomb.rollangle
		bomb.rollangle = 0
		bomb.roll = 0
		bomb.pitch = 0
		
		bomb.forceangle = bomb.angle
		bomb.baseangle = bomb.angle
		bomb.tracer_player.submobj = bomb
		return true
	end,
	physicsthink = function(bomb, subtype, aimline)
		if aimline then return end
		if not bomb.alreadyblocked then return end
		if not (bomb.tracer_player and bomb.tracer_player.valid and bomb.tracer_player.mo and bomb.tracer_player.valid)
			P_KillMobj(bomb)
		end
		
		bomb.phasetime = $ - 1
		if bomb.phasetime == 0
			bomb.phase = nextphase[$]
			bomb.phasetime = phase2time[bomb.phase]
		end
		
		if bomb.phase == Paint.SPN_DEPLOY
			return
		end
		local info = phasedata[bomb.phase]
		
		if not bomb.spraywait
			bomb.spraywait = info.spraytic
			
			local angle = bomb.angle + FixedAngle(180*FU * bomb.extravalue2)
			local aim = 0
			
			if not bomb.wallmode
				local sec = bomb.subsector.sector
				local slope = sec.f_slope
				if (bomb.ceilingmode)
					slope = sec.c_slope
				end
				if slope
					aim = FixedMul(slope.zangle, cos(angle))
					if bomb.ceilingmode
						aim = -$
					end
				end
			end
			
			local speed = P_RandomFixedRange(info.speed_min, info.speed_max)
			local ox,oy,oz = 0,0,0
			if (bomb.wallmode)
				local dist = 22*FU
				ox = P_ReturnThrustX(nil, bomb.baseangle + ANGLE_180, dist)
				oy = P_ReturnThrustY(nil, bomb.baseangle + ANGLE_180, dist)
			else
				oz = 16*FU
			end
			
			local proj = Paint.spawnBulletDrop(bomb, bomb.tracer_player, bomb.color,
				0,0, speed,
				nil,nil,nil, ox,oy,oz
			)
			proj.damage = 20*FU
			proj.trail = false
			proj.weapon_id = "sprinkler_bullet"
			proj.hitlist = {}
			proj.init = true
			proj.target = bomb.tracer_player.realmo
			proj.flags = $|MF_NOGRAVITY &~MF_NOCLIPTHING
			proj.splatvolume = 255 / 4
			
			proj.angle = angle
			proj.lifespan = 0
			proj.s_state = SS_STRAIGHT
			proj.shotstretch = false
			
			local cur_weapon = Paint.weapons["sprinkler_bullet"]
			proj.str_tics			= cur_weapon["str_tics"]
			proj.str2brk_maxspeed	= FixedMul(cur_weapon["str2brk_maxspeed"], proj.scale)
			proj.brk_airresist		= cur_weapon["brk_airresist"]
			proj.brk_gravity		= cur_weapon["brk_gravity"]
			proj.brk2fre_minz		= FixedMul(cur_weapon["brk2fre_minz"], proj.scale)
			proj.brk2fre_minxy		= FixedMul(cur_weapon["brk2fre_minxy"], proj.scale)
			proj.brk2fre_tics		= cur_weapon["brk2fre_tics"]
			proj.fre_airresist		= cur_weapon["fre_airresist"]
			proj.fre_gravity		= cur_weapon["fre_gravity"]
			proj.crs_guideframe		= cur_weapon["crs_guideframe"]
			
			proj.p_angle = angle
			proj.p_aiming = FixedAngle(aim)
			proj.baseangle = angle
			proj.angoffset = 0
			proj.origin = {x = proj.x, y = proj.y, z = proj.z}
			proj.basedamage = proj.damage
			proj.falloffdamage = cur_weapon["falloffdamage"]
			
			local h_spread = 0
			local v_spread = P_RandomFixedRange(10*FU, 45*FU) * (bomb.ceilingmode and -1 or 1)
			v_spread = FixedAngle($)
			
			if bomb.wallmode
				angle = bomb.baseangle + ANGLE_90
				aim = bomb.aiming + FixedAngle(180*FU * bomb.extravalue2)
				h_spread,v_spread = -$2, $1
			end
			
			local aimvec = P_Vec3.SphereToCartesian(angle,aim)
			local axis1 = RandomPerpendicular(aimvec)
			local axis2 = aimvec:Cross(axis1):Normalize()
			local q = P_Quat.AxisAngle(axis1, v_spread):Mul(P_Quat.AxisAngle(axis2, h_spread))
			local mom = q:Rotate(aimvec)
			proj.momx = FixedMul(speed, mom.x)
			proj.momy = FixedMul(speed, mom.y)
			proj.momz = FixedMul(speed, mom.z)
			
			bomb.extravalue2 = 1 - $
		else
			bomb.spraywait = $ - 1
		end
		
		if not bomb.rotwait
			bomb.rotwait = info.rottic
			if bomb.wallmode
				bomb.aiming = $ + FixedAngle(info.rotate)
			else
				bomb.angle = $ + FixedAngle(info.rotate)
			end
		else
			bomb.rotwait = $ - 1
		end
		bomb.forceangle = bomb.angle
	end
})
