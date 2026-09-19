-- sprinkler phases
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

/*
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
*/

local function pain_func(mo, inf,sor, damage)
	if mo.phase == nil then return end
	if (mo.subtype ~= "shotpot") then return end
	
	mo.paint_hp = max($ - damage, 0)
	if mo.paint_hp <= 0
		mo.paint_destroyed = true
		return true
	end
	return false
end
addHook("ShouldDamage",pain_func, MT_PAINT_BOMB)

Paint:registerWeapon({
	name = "shotpot_bullet",
	hidden = true,
	damage = 10*FU,
	falloffdamage = 5*FU,
	
	str_tics = 8, -- straight state lasts this many tics
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
	name = "shotpot",
	icon = "PTSUB_SPRINKLER",
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
		if (line and line.valid)
			/*
			local line_ang = R_PointToAngle2(
				line.v1.x, line.v1.y, line.v2.x, line.v2.y
			) - ANGLE_90*(P_PointOnLineSide(bomb.x,bomb.y, line) and 1 or -1)
			bomb.angle = line_ang
			
			local ox,oy = P_ClosestPointOnLine(bomb.x,bomb.y, line)
			ox = $ + P_ReturnThrustX(nil, bomb.angle, -(bomb.radius + 2*bomb.scale))
			oy = $ + P_ReturnThrustY(nil, bomb.angle, -(bomb.radius + 2*bomb.scale))
			P_MoveOrigin(bomb, ox,oy, bomb.z)
			bomb.state = S_PAINT_SUCTIONBOMB_W
			*/
			P_SlideMove(bomb)
			return true
		else
			bomb.angle = $ + ANGLE_90
		end
		
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
		
		bomb.paint_maxhp = 120*FU
		bomb.paint_hp = bomb.paint_maxhp
		bomb.paint_team = bomb.tracer_player.ctfteam
		bomb.paint_mechanical = true
		bomb.paint_checkteams = true
		bomb.flags = $|MF_SHOOTABLE
		bomb.takis_flingme = true
		return true
	end,
	physicsthink = function(bomb, subtype, aimline)
		if aimline then return end
		if not bomb.alreadyblocked then return end
		if not (bomb.tracer_player and bomb.tracer_player.valid
			and bomb.tracer_player.mo and bomb.tracer_player.mo.valid
			and bomb.tracer_player.mo.health
		)
			P_KillMobj(bomb)
			return
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
			
			local speed = info.speed_max
			local ox,oy,oz = 0,0,0
			if not bomb.ceilingmode
				oz = 16*FU
			end
			
			local p = bomb.tracer_player
			local targ = nil
			local lastdist = INT32_MAX
			local searchdist = speed * 8
			searchBlockmap("objects", function(ref, mo)
				if not (mo and mo.valid) then return end
				if not (mo.health) then return end
				if (mo == p.mo) then return end
				
				local canhit = false
				if Paint_canHurtEnemy(p, mo) or mo.type == MT_TNTBARREL
					canhit = true
				end
				if mo.type == MT_PLAYER and Paint_canHurtPlayer(p, mo.player)
					canhit = true
				end
				if not canhit then return end
				
				local distto = R_PointTo3DDist(bomb.x,bomb.y,bomb.z + FixedMul(oz, bomb.scale),
					mo.x, mo.y, mo.z + mo.height / 2
				)
				if distto > lastdist then return end
				targ = mo
				lastdist = distto
			end, bomb, bomb.x - searchdist, bomb.x + searchdist, bomb.y - searchdist, bomb.y + searchdist)
			if not (targ and targ.valid) then return end
			
			local angle, aim = R_PointTo3DAngles(bomb.x,bomb.y,bomb.z + FixedMul(oz, bomb.scale),
				targ.x, targ.y, targ.z + targ.height / 2
			)
			local proj = Paint.spawnBulletDrop(bomb, bomb.tracer_player, bomb.color,
				0,0, speed,
				nil,nil,nil, ox,oy,oz
			)
			proj.damage = 20*FU
			proj.trail = false
			proj.weapon_id = "shotpot_bullet"
			proj.hitlist = {}
			proj.init = true
			proj.target = bomb.tracer_player.realmo
			proj.flags = $|MF_NOGRAVITY &~MF_NOCLIPTHING
			proj.splatvolume = 255 / 4
			
			proj.angle = angle
			proj.lifespan = 0
			proj.s_state = SS_STRAIGHT
			proj.shotstretch = false
			
			local cur_weapon = Paint.weapons["shotpot_bullet"]
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
			
			local h_spread = P_RandomFixedRange(-5*FU, 5*FU)
			local v_spread = 0
			
			local aimvec = P_Vec3.SphereToCartesian(angle,aim)
			local axis1 = RandomPerpendicular(aimvec)
			local axis2 = aimvec:Cross(axis1):Normalize()
			local q = P_Quat.AxisAngle(axis1, v_spread):Mul(P_Quat.AxisAngle(axis2, h_spread))
			local mom = q:Rotate(aimvec)
			proj.momx = FixedMul(speed, mom.x)
			proj.momy = FixedMul(speed, mom.y)
			proj.momz = FixedMul(speed, mom.z)
			
			S_StartSound(bomb, P_RandomRange(sfx_p_s1_0, sfx_p_s1_6))
			
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
