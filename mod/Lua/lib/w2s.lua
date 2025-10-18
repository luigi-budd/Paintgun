local cv_fov
local cv_glshearing

/*
	Code updated in Lua by GenericHeroGuy for libSG
	Ported to C by NepDisk and acutally made to work and fixed by Indev!(Thanks so much!)
	Badly uncapped in C by GenericHeroGuy
	original code by Lat'
	Code from SRB2Kart Saturn, retranslated to Lua with some edits by luigi budd
*/
rawset(_G, "K_GetScreenCoords",function(vid,p,cam, point, props)
	props = $ or {}
	local hofs = props.hofs or 0
	local dontclip = props.dontclip or false -- Dont make `result.offscreen = false` when the result goes off screen dimensions
	local interpmobj = props.interpmobj or false -- (SRB2-edit only) (WIP) Interpolates mobj state for "uncapped game" HUDs
	local noscalestart = props.noscalestart or false -- Returns positions for patches with V_NOSCALESTART
	local anglecliponly = props.anglecliponly or false -- Only clips the result if angle checks fail. Does not clip to screen dimensions.
	local viewoverride = props.viewoverride
	
	if not cv_glshearing
		cv_glshearing = CV_FindVar("gr_shearing")
	end
	if not cv_fov
		cv_fov = CV_FindVar("fov")
	end
	local x,y,scale
	local targx,targy,targz
	
	local dist
	local distfact
	local offset
	
	local xres,yres
	local fov, viewroll
	
	local onscreen = true
	if not (p and p.valid and point)
		onscreen = false
		return {x=0,y=0,onscreen=onscreen}
	end
	
	if (takis_custombuild and interpmobj)
		targx,targy,targz = vid.interpolateMobj(point)
	else
		targx = point.x
		targy = point.y
		targz = point.z
	end
	
	local isMobj = type(point) == "userdata" and userdataType(point) == "mobj_t"
	local camAngle = cam.angle
	local camAiming = cam.aiming
	local camPos = {x = cam.x, y = cam.y, z = cam.z}
	if (not cam.chase) -- in first-person
		if (P_GetLocalAngle ~= nil) --localaiming functions exist?
		and (p == consoleplayer or p == secondarydisplayplayer)
			camAngle = P_GetLocalAngle(p)
			camAiming = P_GetLocalAiming(p)
		elseif (SUBVERSION < 16) --assuming camera fix was merged into 2.2.16, and we're on 2.2.15
			local m = p.realmo
			camPos = {x = m.x, y = m.y, z = p.viewz}
			--sglib uses p.realmo.angle, so...
			camAngle = m.angle
			camAiming = p.aiming
		--if we ARE on 2.2.16 then do nothing, everythings already correct
		end
	end
	if (p.awayviewmobj and p.awayviewmobj.valid and p.awayviewtics > 0)
		local away = p.awayviewmobj
		--not on our camera?
		if not (away.x == camPos.x and away.y == camPos.y and away.z + 20*FU == camPos.z)
			camPos = {x = away.x, y = away.y, z = away.z + 20*FU}
			camAngle = away.angle
			camAiming = p.awayviewaiming
		end
	end
	if viewoverride ~= nil
		if viewoverride.angle ~= nil
			camAngle = viewoverride.angle
		end
		if viewoverride.aiming ~= nil
			camAiming = viewoverride.aiming
		end
		if viewoverride.x ~= nil
			camPos.x = viewoverride.x
		end
		if viewoverride.y ~= nil
			camPos.y = viewoverride.y
		end
		if viewoverride.z ~= nil
			camPos.z = viewoverride.z
		end
	end
	
	x = camAngle - R_PointToAngle2(camPos.x,camPos.y, targx,targy)
	
	distfact = cos(x)
	if distfact == 0 then distfact = 1; end
	if not (abs(x) < ANGLE_90)
		onscreen = false
	end
	
	if noscalestart
		xres = (vid.width()) << (FRACBITS-1)
		yres = (vid.height()) << (FRACBITS-1)
	else
		xres = (vid.width()/vid.dupx()) << (FRACBITS-1)
		yres = (vid.height()/vid.dupy()) << (FRACBITS-1)
	end
	fov = FixedDiv(xres, tan(FixedAngle(cv_fov.value/2)))
	viewroll = (p and p.valid) and p.viewrollangle or 0
	
	-- flipping
	local targflip = (isMobj and point.eflags & MFE_VERTICALFLIP)
	local srcflip = (p.pflags & PF_FLIPCAM) and (p.realmo.eflags & MFE_VERTICALFLIP)
	
	-- Y coordinate
	-- getting the angle difference here is a bit more involved...
	-- start by getting the height difference between the camera and target
	y = camPos.z - targz
	if (targflip)
		y = $ - ((point.height * 2) / 3)-- for some reason needs to be divided by "1.5" idk
	end
	if (hofs)
		y = $ - (targflip and -hofs or hofs)
	end
	
	dist = R_PointToDist2(camPos.x,camPos.y, targx,targy)
	
	local opengl = vid.renderer() == "opengl"
	if opengl and (cv_glshearing.value == 1
	or (cv_glshearing.value == 2 and cam.chase))
		opengl = false
	end
	
	if (opengl)
		local yang = R_PointToAngle2(0,0, dist,y) -- not perspective
		x = FixedMul(x, cos(yang)) -- perspective
		y = -camAiming - FixedDiv(yang, distfact)
		
		if not (abs(y) < ANGLE_90)
			onscreen = false
		end
		if splitscreen
			y = $ + ($/4)
		end
		if scrflip
			y = -$
		end
		y = FixedMul(tan(-y), fov) + yres -- project the angle to get our final Y coordinate
		dist = R_PointToDist2(0, 0, R_PointToDist2(targx,targy,camPos.x,camPos.y), targz - camPos.z)
	else
		local fovratio = FixedDiv(90*FU, 180*FU - FixedMul(cv_fov.value, 4*FU/3)-FU*-30)
		y = FixedDiv(y, FixedMul(dist,distfact))
		if scrflip
			y = -y
		end
		if y ~= INT32_MIN
			y = FixedMul(FixedDiv(y, fovratio), xres) + yres
		end
		offset = FixedMul(tan(camAiming), xres)
		
		if splitscreen
			offset = 17*$/120
		end
		offset = FixedDiv($, fovratio)
		if (scrflip)
			offset = -$
		end
		y = $ + offset
	end
	
	dist = FixedMul($, FixedDiv(cv_fov.value, 90*FU))
	scale = FixedDiv(yres, dist + 1)
	
	-- project the angle to get our final X coordinate
	x = FixedMul(tan(x), fov)
	if splitscreen
		x = ($/2) + (x/8)
	end
	x = $ + xres
	
	/*
	if viewroll
		local tempx = x
		x = FixedMul(cos(viewroll), tempx) - FixedMul(sin(viewroll), y)
		y = FixedMul(sin(viewroll), tempx) + FixedMul(cos(viewroll), y)
	end
	*/
	
	-- adjust coords for splitscreen
	if splitscreen
		y = y >> 1
		if (p == secondarydisplayplayer)
			y = $ + yres
		end
	end
	if not noscalestart
		x = $ - ((vid.width()/vid.dupx()) - BASEVIDWIDTH) << (FRACBITS - 1)
		y = $ - ((vid.height()/vid.dupy()) - BASEVIDHEIGHT) << (FRACBITS - (splitscreen and 2 or 1))
	end
	-- now clip in screenspace
	if not dontclip
		if abs(camAngle - R_PointToAngle2(camPos.x,camPos.y, targx,targy)) > FixedAngle(cv_fov.value)
			onscreen = false
		end
		if x < 0 or x > (2*xres) then
			onscreen = false
		end
		if y < 0 or y > (2*yres) then
			onscreen = false
		end
	elseif anglecliponly
		if abs(camAngle - R_PointToAngle2(camPos.x,camPos.y, targx,targy)) > FixedAngle(cv_fov.value)
			onscreen = false
		end
	end
	
	return {x = x, y = y, scale = scale, onscreen = onscreen}
end)