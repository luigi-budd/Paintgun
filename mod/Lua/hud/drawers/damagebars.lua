local HUD = Paint.HUD
local CV = Paint.CV
local barinterp = 0
local camray = nil

function HUD:damageBar(p, target)
	if displayplayer ~= p then return end
	if not CV.damagebars.value then return end
	
	if HUD.memory.damagebars == nil
		HUD.memory.damagebars = {}
	end
	
	local info = {
		mo = target,
		tics = TR,
		shake = 12,
	}
	local didntexist = HUD.memory.damagebars[target] == nil
	local oldtag = -1
	if not didntexist
		oldtag = HUD.memory.damagebars[target].interptag
	end
	HUD.memory.damagebars[target] = info
	
	if didntexist
		HUD.memory.damagebars[target].interptag = barinterp
		barinterp = $ + 1
	else
		HUD.memory.damagebars[target].interptag = oldtag
	end
end

local v_width,v_height = 0,0
local linefactor = 4
local function drawLine(v, x, y, t, angle, length, color)
	length = ($*linefactor)/FU
    for i=0, length-1 do
		local destx = x + FixedMul(i*FU/linefactor, cos(angle))
		local desty = y - FixedMul(i*FU/linefactor, sin(angle))
		if destx < 0 or destx > v_width then continue end
		if desty < 0 or desty > v_height then continue end
        v.drawFixedFill(destx, desty, t, t, color)
    end
end

local function DamageBar(v,p,cam, info)
	local mo = info.mo
	if not (mo and mo.valid)
		HUD.memory.damagebars[mo] = nil
		return
	end
	if info.tics <= 0
		HUD.memory.damagebars[mo] = nil
		return
	end
	
	local result = K_GetScreenCoords(v,p,cam, {x = mo.x, y = mo.y, z = mo.z + mo.height*13/10})
	if result.onscreen and P_CheckSight(camray, mo)
		local fade = 0
		if info.tics < 10
			fade = (10 - info.tics) << V_ALPHASHIFT
		end
		
		local blink = info.shake >= 6
		local angle = FixedAngle(info.shake * (leveltime % 2 and 1 or -1) * FU / 2)
		local scale = min(result.scale * 6/5, FU * 3/4)
		local width = 70*scale
		local outlinethickness = scale/2
		local progress = FixedDiv(mo.health*FU, (mo.maxhealth or 1)*FU)
		
		local skincolor
		local health, maxhealth
		if (mo.player)
			skincolor = Paint:getPlayerColor(mo.player)
			health = mo.player.paint.hp
			maxhealth = 100*FU
			if not mo.health then health = 0; end
		elseif mo.paint_maxhp ~= nil
			skincolor = mo.color or ColorOpposite(Paint:getPlayerColor(p))
			health = (mo.paint_hp or mo.health)
			maxhealth = (mo.paint_maxhp or FU)
		else -- uh oh!
			HUD.memory.damagebars[mo] = nil
			return
		end
		local progress = FixedDiv(health, maxhealth)
		local color = skincolors[skincolor].ramp[2]
		local colormap = skincolors[skincolor].chatcolor
		local x,y
		
		v.dointerp(info.interptag)
		x = result.x - FixedMul((width + outlinethickness)/ 2, cos(angle))
		y = result.y + FixedMul((width + outlinethickness) / 2, sin(angle))
		drawLine(v, x, y - outlinethickness - scale, (scale + outlinethickness)*2, angle, width, ((not blink) and 31 or 0)|fade)
		
		v.dointerp(info.interptag + 1)
		x = result.x - FixedMul(width / 2, cos(angle))
		y = result.y + FixedMul(width / 2, sin(angle))
		drawLine(v, x, y - scale, 2*scale, angle, width, 31|fade)
		v.dointerp(info.interptag + 2)
		drawLine(v, x, y - scale, 2*scale, angle, FixedMul(width,progress), ((not blink) and color or 0)|fade)
		
		v.dointerp(info.interptag + 3)
		v.drawScaled(result.x - (7*scale)/2, result.y + scale, scale, v.cachePatch("TNYFN027"), 0, v.getStringColormap(colormap))
		v.dointerp(false)
	end
	
	info.shake = max($ - 1, 0)
	info.tics = $ - 1
end

addHook("PostThinkFrame",do
	if gamestate ~= GS_LEVEL then return end
	camray = P_SpawnMobj(camera.x, camera.y, camera.z, MT_RAY)
	camray.fuse = 2
	camray.tics = 2
end)

local hudinfo = {}
hudinfo.func = function(v,p,cam)
	if v.drawFixedFill == nil then return end
	
	v_width = (v.width() / v.dupx())*FU
	v_height = (v.height() / v.dupy())*FU
	
	local feed = HUD.memory.damagebars
	if feed == nil then return end
	
	local tmp = {}
	for mo,info in pairs(HUD.memory.damagebars)
		if not (mo and mo.valid) then continue end
		table.insert(tmp, {mo = mo, dist = R_PointToDist(mo.x,mo.y)})
	end
	table.sort(tmp, function(a,b)
		return a.dist > b.dist
	end)
	for k, this in ipairs(tmp)
		DamageBar(v,p,cam, HUD.memory.damagebars[this.mo])
	end
end
hudinfo.type = "game"
return hudinfo