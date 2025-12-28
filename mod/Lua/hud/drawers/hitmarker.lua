local HUD = Paint.HUD

freeslot("SPR_PAINT_HITMARKER")
function HUD:hitMarker(p, pos, rotangle, sizemul, powerful, blocked)
	if displayplayer ~= p then return end
	
	if HUD.memory.hitmarkers == nil
		HUD.memory.hitmarkers = {}
	end
	
	table.insert(HUD.memory.hitmarkers, {
		pos = pos, --{x=mo.x,y=mo.y,z=mo.z + mo.height/2},
		tics = blocked and 8 or 4,
		frame = A,
		angle = rotangle or 0,
		sizemul = sizemul or FU,
		powerful = powerful,
		blocked = blocked,
		interptag = leveltime
	})
end

local function Icon(v,p,cam, info)
	local result = K_GetScreenCoords(v,p,cam, info.pos)
	if not result.onscreen then return end
	
	local flags = 0
	local patch
	if info.blocked
		patch = v.getSpritePatch(SPR_PAINT_MISC, 23 + (info.frame), 0, info.angle)
		flags = $|(info.frame<<V_ALPHASHIFT)
	else
		patch = v.getSpritePatch(SPR_PAINT_HITMARKER, clamp(0,info.frame,3), 0, info.angle)
	end
	if patch == nil then return end
	local scale = FixedMul(FU/2, info.sizemul)
	
	v.drawScaled(result.x,result.y, scale, --scale,
		patch,
		flags,
		v.getColormap(nil, Paint:getPlayerColor(p))
	)
end

addHook("HUD",function(v,p,cam)
	local feed = HUD.memory.hitmarkers
	if feed == nil then return end
	
	local toremove = {}
	for k, info in ipairs(feed)
		if info.tics <= 0
			table.insert(toremove, k)
			continue
		end
	end
	for _, k in ipairs(toremove)
		table.remove(feed, k)
	end
	
	for k, info in ipairs(feed)
		v.dointerp(info.interptag)
		Icon(v,p,cam, info)
		v.dointerp(false)
		if not paused
			info.tics = $ - 1
			info.frame = $ + 1
		end
	end
end,"game")