local MYVERSION = 101
local ADDHOOK = true
if rawget(_G, "ExactoCam_Version")
	if ExactoCam_Version == MYVERSION then return end
	
	ADDHOOK = (ExactoCam_Version < MYVERSION)
end
rawset(_G,"ExactoCam_Version", MYVERSION)

local TR = TICRATE

local function P_ClosestPointOnLine3D(p, lstart, lend)
	local t,d
	local V = Vec3.Sub(lend, lstart)
	local c = Vec3.Sub(p, lstart)
	
	-- d = R_PointToDist2(0, lend.z, R_PointToDist2(lend.x, lend.y, lstart.x, lstart.y), lstart.z)
	d = R_PointTo3DDist(lstart.x,lstart.y,lstart.z, lend.x,lend.y,lend.z)
	local n = Vec3.New(V.x, V.y, V.z) / d
	t = Vec3.Dot(n, c)
	
	if t <= 0
		return lstart
	elseif t >= d
		return lend
	end
	
	n = $ * t
	return Vec3.Add(lstart, n)
end
local cammo = nil

local ANGLETURN = 0
local ANGLETURN2 = 0
local AIMING = 0
local ANGLE_CAP = FixedAngle(70*FU) >> 16
addHook("PlayerCmd",function(p,cmd)
	if p ~= consoleplayer then return end
	
	ANGLETURN = cmd.angleturn<<16
	ANGLETURN2 = ANGLETURN
	local aiming = cmd.aiming
	if aiming > ANGLE_CAP
		aiming = ANGLE_CAP
	elseif aiming < -ANGLE_CAP
		aiming = -ANGLE_CAP
	end
	AIMING = aiming<<16
	
	if (p.realmo.flags2 & MF2_TWOD or twodlevel)
		if cmd.sidemove == 0
			cmd.sidemove = cmd.forwardmove
		end
	end
end)
addHook("PlayerSpawn",function(p)
	if (p ~= consoleplayer) then return end
	if not p.realmo and p.realmo.valid then return end
	ANGLETURN = p.realmo.angle
	ANGLETURN2 = ANGLETURN
end)

local cv_camdist = CV_FindVar("cam_dist")
local cv_camheight = CV_FindVar("cam_height")
local cv_camrotate = CV_FindVar("cam_rotate")
local sidefrac = 0
local idletime = 0
local twodanim = 0
local blockingmobjs = {}
local movewasblocked = false
rawset(_G, "ExactoCam_Thinker", function(p, camera)
	--if leveltime == 0 then return end
	if not (p and p.valid) then return end
	local me = p.realmo
	if not (me and me.valid) then return end
	
	if (p.awayviewtics > 0)
	and (p.awayviewmobj ~= cammo)
		return
	end
	
	if (p.powers[pw_carry] == CR_NIGHTSFALL or p.powers[pw_carry] == CR_NIGHTSMODE) then return end
	
	if not (cammo and cammo.valid)
		cammo = P_SpawnMobjFromMobj(me, 0,0,0, MT_RAY)
		cammo.fuse = -1
		cammo.tics = -1
		cammo.height = camera.height
		cammo.radius = camera.radius
		cammo.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOSECTOR|MF_NOBLOCKMAP|MF_NOGRAVITY|MF_NOTHINK
	end
	cammo.height = camera.height
	cammo.radius = camera.radius
	
	if p ~= consoleplayer
		ANGLETURN = p.cmd.angleturn << 16
		ANGLETURN2 = ANGLETURN
		AIMING = p.cmd.aiming << 16
	end
	
	/*
	local aim = AngleFixed(AIMING)
	if aim > 180*FU then aim = -(360*FU - $); end
	if aim > 80*FU and aim < 180*FU
		aim = 80*FU
	elseif aim < -80*FU
		aim = -80*FU
	end
	AIMING = FixedAngle(aim)
	*/
	
	local camflip = P_MobjFlip(me)
	
	local camdist = FixedMul(cv_camdist.value, me.scale)
	camdist = FixedMul($, p.camerascale)
	camdist = $ + (20*FU - 20*me.scale)
	local camheight = FixedMul(cv_camheight.value, me.scale)
	camheight = $ - (16*FU - 16*me.scale)
	
	local focusPos = Vec3.MobjPosToVec(me)
	focusPos.z = $ + ((41*P_GetPlayerHeight(p)/48) + camheight)*camflip
	
	local shiftVec = Vec3.New(0,0,0)
	
	local twod = (me.flags2 & MF2_TWOD or twodlevel)
	if twod
		twodanim = P_Lerp(FU/3, $, FU)
		
		camdist = $ * 2
		local runspeed = FixedMul(skins[p.skin].normalspeed * 6/10, me.scale)
		local speedfrac = min(abs(FixedDiv(me.momx, runspeed)), FU)
		local movefrac = abs(FixedDiv(p.cmd.sidemove*FU, 50*FU))
		movefrac = FixedMul($, speedfrac)
		
		local pushfactor = p.cmd.sidemove
		local dopush = abs(pushfactor) > 10
		if p.cmd.sidemove == 0 and abs(me.momx) > runspeed
			pushfactor = me.momx
			dopush = true
			movefrac = speedfrac
		end
		
		if dopush
		-- and P_CheckSight(cammo, me)
		and not movewasblocked
			sidefrac = P_Lerp(FixedMul(FU/10, movefrac), $, FU * sign(pushfactor))
			idletime = 0
		else
			if not P_CheckSight(cammo, me)
				sidefrac = P_Lerp(FU/15, $, 0)
			end
			idletime = $ + 1
			
			if idletime >= 3*TR
			or p.exiting
				sidefrac = P_Lerp(FU/15, $, 0)
			end
		end
		
		shiftVec = Vec3.New(camdist * 2/5, 0,0) * sidefrac
		if me.momz * P_MobjFlip(me) < 0
			shiftVec.z = $ + me.momz
		end
	else
		twodanim = P_Lerp(FU/3, $, 0)
		sidefrac = P_Lerp(FU/2, $, 0)
	end
	if twodanim
		ANGLETURN = P_Lerp(twodanim, $, ANGLE_90)
		ANGLETURN2 = ANGLETURN
	end
	
	movewasblocked = false
	
	local adjustVec = Vec3.SphereToCartesian(ANGLETURN, AIMING) * (-camdist)
	adjustVec = focusPos + adjustVec
	-- clipping / poppercam
	if not (me.flags & (MF_NOCLIP|MF_NOCLIPHEIGHT) or p.powers[pw_carry] == CR_NIGHTSMODE or twod)
		local camSec = R_PointInSubsector(adjustVec.x,adjustVec.y).sector
		if camSec.camsec
			camSec = camSec.camsec -- lol
		elseif camSec.heightsec
			camSec = camSec.heightsec
		end
		
		local topZ = camSec.ceilingheight
		local botZ = camSec.floorheight
		if (camSec.c_slope)
			topZ = P_GetZAt(camSec.c_slope, adjustVec.x,adjustVec.y)
		end
		if (camSec.f_slope)
			botZ = P_GetZAt(camSec.f_slope, adjustVec.x,adjustVec.y)
		end
		
		local midZ = adjustVec.z + (adjustVec.z - focusPos.z)/2
		local camTop = midZ + cammo.height
		for rover in camSec.ffloors()
			if not (rover.fofflags & FOF_BLOCKOTHERS) then continue end
			if not (rover.fofflags & FOF_EXISTS) then continue end
			if not (rover.fofflags & FOF_RENDERALL) then continue end
			if (rover.master.frontsector.flags & MSF_NOCLIPCAMERA) then continue end
			
			local fTopZ = rover.topheight
			local fBotZ = rover.bottomheight
			if (rover.t_slope)
				fTopZ = P_GetZAt(rover.t_slope, adjustVec.x,adjustVec.y)
			end
			if (rover.b_slope)
				fBotZ = P_GetZAt(rover.b_slope, adjustVec.x,adjustVec.y)
			end
			
			local delta1 = midZ - (fBotZ + ((fTopZ - fBotZ)/2))
			local delta2 = camTop - (fBotZ + ((fTopZ - fBotZ)/2))
			if (fTopZ > botZ and (abs(delta1) < abs(delta2)))
				botZ = fTopZ
			end
			if (fBotZ < topZ and (abs(delta1) >= abs(delta2)))
				topZ = fBotZ
			end
		end
		
		-- wtopZ = $ - cammo.height*6
		--botZ = $ - 10*FU
		local bound = clamp(botZ, adjustVec.z, topZ)
		/*
		P_SpawnMobj(me.x,me.y,topZ, MT_THOK)
		P_SpawnMobj(me.x,me.y,botZ, MT_THOK).color = SKINCOLOR_RED
		print(adjustVec.z > topZ)
		print(("%f"):format(adjustVec.z))
		print(("%f"):format(topZ))
		*/
		
		--if abs(bound - adjustVec.z) >= camdist/2
		if (adjustVec.z < botZ)
		or (adjustVec.z > topZ)
		or (R_PointInSubsectorOrNil(adjustVec.x,adjustVec.y) == nil)
			local ray = P_SpawnMobjFromMobj(me,
				0,0,0, MT_RAY)
			ray.height = 4*FU
			ray.radius = 2*FU
			ray.flags = MF_SLIDEME|MF_NOCLIPTHING
			Vec3.ToMobjMom(Vec3.SphereToCartesian(ANGLETURN,0) * (-camdist), ray, false)
			P_RailThinker(ray)
			local olddist = camdist
			camdist = R_PointToDist2(me.x,me.y, ray.x,ray.y)
			
			adjustVec = Vec3.SphereToCartesian(ANGLETURN, AIMING) * (-camdist)
			adjustVec = focusPos + adjustVec
			-- not in a wall?
			if abs(olddist - camdist) < FU
				local newdist = R_PointTo3DDist(
					adjustVec.x,adjustVec.y,bound,
					focusPos.x,focusPos.y,focusPos.z
				)
				
				adjustVec = Vec3.SphereToCartesian(ANGLETURN, AIMING) * (-newdist)
				adjustVec = focusPos + adjustVec
				adjustVec.z = bound
				movewasblocked = true
				--print("not wall")
				--print(("%f"):format(adjustVec.z))
			elseif adjustVec.z < me.z
				adjustVec.z = me.z
				movewasblocked = true
			end
		end
	end
	/*
	if sidefrac
		local sideVec = Vec3.SphereToCartesian(ANGLETURN+ANGLE_90, 0) * (-FixedMul(camdist, FixedSqrt(2*FU)/2))
		sideVec = $ * sidefrac
		adjustVec = $ + sideVec
	end
	*/
	-- invisicam
	if (p.playerstate == PST_LIVE)
		Vec3.ToMobjPos(adjustVec + shiftVec, cammo, true, false)
		
		local checkplayers = (gametyperules & GTR_FRIENDLY) == 0
		local ray = P_SpawnMobjFromMobj(cammo,
			0,0,0, MT_RAY)
		ray.height = 8*FU
		ray.radius = 4*FU
		ray.flags = $|MF_NOCLIPTHING|MF_NOCLIPHEIGHT|MF_NOCLIP
		Vec3.ToMobjMom(Vec3.SphereToCartesian(ANGLETURN,AIMING) * (8*FU), ray, true)
		
		local blockrad = ray.radius + me.radius
		for i = 0,255
			if not (ray and ray.valid) then break; end
			
			if abs(ray.x - me.x) <= blockrad
			and abs(ray.y - me.y) <= blockrad
			--and ((ray.z+ray.height >= me.z) and (ray.z <= me.z+me.height))
				P_RemoveMobj(ray)
				break
			end
			
			P_RailThinker(ray)
			searchBlockmap("objects", function(m, found)
				if not (found and found.valid and found.health) then return end
				if (found == me) then return end
				if (blockingmobjs[found]) then return end
				if (found.type == MT_PLAYER and not checkplayers) then return end
				if (found.flags & (MF_SOLID|MF_SCENERY|MF_NOTHINK) == 0) then return end
				/*
				print(found.info.typename,
					found.flags & MF_SOLID == MF_SOLID,
					found.flags & MF_SCENERY == MF_SCENERY,
					found.flags & MF_NOTHINK == MF_NOTHINK
				)
				*/
				
				if abs(ray.x - found.x) <= ray.radius + found.radius
				and abs(ray.y - found.y) <= ray.radius + found.radius
				and ((ray.z+ray.height >= found.z) and (ray.z <= found.z+found.height))
					return
				end
				
				blockingmobjs[found] = found
			end, ray)
		end
		if ray and ray.valid then P_RemoveMobj(ray); end
		
		local radius = me.radius * 3/2
		local height = me.height * 3/2
		for _,found in pairs(blockingmobjs)
			if not (found and found.valid) then continue end
			
			local obscuring = false
			local intersect = P_ClosestPointOnLine3D(Vec3.MobjPosToVec(found), adjustVec, focusPos)
			
			local angletome = R_PointToAngle2(found.x,found.y, me.x,me.y)
			local angdiff = AngleFixed(angletome - ANGLETURN)
			
			if abs(intersect.x - found.x) <= found.radius + radius
			and abs(intersect.y - found.y) <= found.radius + radius
			and (
				found.z <= intersect.z + height -- check overhead
				and found.z+found.height*3/2 >= intersect.z -- check underhead
			)
			and (
				(angdiff <= 28*FU or angdiff >= (360 - 28)*FU)
				or R_PointToDist2(adjustVec.x,adjustVec.y, found.x,found.y) <= 64*me.scale
			)
				obscuring = true
			end
			
			if obscuring
				found.alpha = P_Lerp(FU/3, $, FU/3)
			else
				found.alpha = FixedCeil(P_Lerp(FU/2, $, FU)*100)/100
				if found.alpha >= FU
					blockingmobjs[_] = nil
				end
			end
		end
	else
		local ha,va = R_PointTo3DAngles(cammo.x,cammo.y,cammo.z, focusPos.x,focusPos.y,focusPos.z)
		ANGLETURN2 = ha
		AIMING = va
		
		if (focusPos.z > me.floorz)
			local dist = R_PointTo3DDist(cammo.x,cammo.y,cammo.z, focusPos.x,focusPos.y,focusPos.z)
			if dist > camdist
				local adjust = dist - camdist
				local moveVec = Vec3.SphereToCartesian(ha,va) * adjust
				moveVec:ToMobjPos(cammo, false, false)
			else
				local adjust = (dist - camdist) / 5
				local moveVec = Vec3.SphereToCartesian(ha,va) * adjust
				moveVec:ToMobjPos(cammo, false, false)
			end
		end
	end
	
	-- P_TeleportCameraMove(camera, cammo.x, cammo.y, cammo.z)
	cammo.angle = ANGLETURN2
	if camera.chase and not freecam_active
		p.awayviewaiming = AIMING
		p.awayviewmobj = cammo
		p.awayviewtics = 2
	elseif p.awayviewmobj == cammo
		p.awayviewmobj = nil
	end
end)

if ADDHOOK
	addHook("PostThinkFrame",do
		if (gamestate ~= GS_LEVEL) then return end
		ExactoCam_Thinker(displayplayer, camera)
	end)
end