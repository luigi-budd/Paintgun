local HUD = Paint.HUD
local CV = Paint.CV
local hit = 0

function HUD:damageNumber(p, target, damage)
	if displayplayer ~= p then return end
	if not CV.damagenumbers.value then return end
	
	if HUD.memory.damagenumbers == nil
		HUD.memory.damagenumbers = {}
	end
	
	if HUD.memory.damagenumbers[target] == nil
		HUD.memory.damagenumbers[target] = {
			pos = {
				x = target.x,
				y = target.y,
				z = target.z + target.height,
			},
			offsetx = 0,
			offsety = 0,
			tics = TR * 6/5,
			momz = ((hit % 8) + 1)*FU,
			momx = ((hit % 4) + 1)*FU * ((leveltime % 2) and 1 or -1),
			damage = damage,
			interptag = leveltime
		}
	else
		local tb = HUD.memory.damagenumbers[target]
		tb.pos = {
			x = target.x,
			y = target.y,
			z = target.z + target.height,
		}
		tb.tics = TR * 6/5
		tb.damage = $ + damage
		tb.offsetx = 0
		tb.offsety = 0
		tb.momz = ((hit % 8) + 1)*FU
		tb.momx = ((hit % 4) + 1)*FU * ((leveltime % 2) and 1 or -1)
	end
	
	hit = $ + 1
end

local function Icon(v,p,cam, info)
	local result = K_GetScreenCoords(v,p,cam, info.pos)
	if not result.onscreen then return end
	
	local flags = 0
	local clr = Paint:getPlayerColor(p)
	local x = result.x
	local y = result.y
	local scale = result.scale
	
	if info.tics <= TR * 5/6
		info.offsetx = $ + info.momx
		info.offsety = $ - info.momz
		info.momz = $ - FU/2
	end
	
	x = $ + FixedMul(info.offsetx, scale)
	y = $ + FixedMul(info.offsety, scale)
	
	if info.tics < 10
		flags = (10 - info.tics) << V_ALPHASHIFT
	end
	
	local str = ("%.2f"):format(info.damage)
	for i = 1, str:len()
		local patch = v.cachePatch("PTDMGN_"..str:sub(i,i))
		v.drawScaled(x,y, scale,
			patch,
			flags,
			v.getColormap(nil, clr)
		)
		x = $ + (patch.width * scale) * 9/10
	end
	
end

addHook("HUD",function(v,p,cam)
	local feed = HUD.memory.damagenumbers
	if feed == nil then return end
	
	local toremove = {}
	for k, info in pairs(feed)
		if info.tics <= 0
			table.insert(toremove, k)
			continue
		end
	end
	for _, k in ipairs(toremove)
		feed[k] = nil
	end
	
	for k, info in pairs(feed)
		v.dointerp(info.interptag)
		Icon(v,p,cam, info)
		v.dointerp(false)
		if not paused
			info.tics = $ - 1
		end
	end
end,"game")