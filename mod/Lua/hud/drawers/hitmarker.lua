local HUD = Paint.HUD
local offset = 0

freeslot("SPR_PAINT_HITMARKER")
local POWERFUL_LEN = TR/3
local POWERFUL_FIRST = 4
function HUD:hitMarker(p, pos, rotangle, sizemul, powerful, blocked)
	if displayplayer ~= p then return end
	
	if HUD.memory.hitmarkers == nil
		HUD.memory.hitmarkers = {}
	end
	
	local tics = 4
	if (blocked)
		tics = 8
	elseif powerful
		tics = POWERFUL_LEN
	end
	table.insert(HUD.memory.hitmarkers, {
		pos = pos, --{x=mo.x,y=mo.y,z=mo.z + mo.height/2},
		tics = tics,
		elapsed = 0,
		frame = A,
		angle = rotangle or 0,
		sizemul = sizemul or FU,
		powerful = powerful,
		blocked = blocked,
		interptag = leveltime + offset
	})
	offset = $ + 1
end

local function Icon(v,p,cam, info)
	local result = K_GetScreenCoords(v,p,cam, info.pos)
	if not result.onscreen then return end
	local scale = FixedMul(FU/2, info.sizemul)
	
	if info.powerful
		local circ = v.getSpritePatch(SPR_PAINT_HITMARKER, 4, 0,0)
		local el = info.elapsed
		if el < POWERFUL_FIRST
			local adjust = FU * (POWERFUL_FIRST - el)
			v.drawScaled(result.x,result.y, FixedMul(scale, adjust),
				circ, V_20TRANS|V_ADD)
		elseif el > POWERFUL_FIRST
			local ANIM = POWERFUL_LEN - POWERFUL_FIRST
			local frac = ease.outexpo(((FU/ANIM)*(el - POWERFUL_FIRST)), FU, 0)
			v.drawStretched(result.x, result.y,
				FixedMul(10*scale, FU - frac), FixedMul(scale*3, frac or FU),
				circ, V_20TRANS|V_ADD)
		end
		if el <= POWERFUL_FIRST
			local adjust = FU
			if el == 1
				adjust = FU * 3/2
			elseif el == 2
				adjust = FU*6/3
			elseif el == 3
				adjust = FU + (FU/6)
			end
			
			local patch = v.getSpritePatch(SPR_PAINT_HITMARKER, 5 + el, 0, info.angle)
			v.drawScaled(result.x,result.y, FixedMul(scale*3/2, adjust),
				patch,
				0, v.getColormap(nil, Paint:getPlayerColor(p))
			)
		end
		return
	end
	
	local flags = 0
	local patch
	if info.blocked
		patch = v.getSpritePatch(SPR_PAINT_MISC, 23 + (info.frame), 0, info.angle)
		flags = $|(info.frame<<V_ALPHASHIFT)
	else
		patch = v.getSpritePatch(SPR_PAINT_HITMARKER, clamp(0,info.frame,3), 0, info.angle)
	end
	if patch == nil then return end
	
	v.drawScaled(result.x,result.y, scale, --scale,
		patch,
		flags,
		v.getColormap(nil, Paint:getPlayerColor(p))
	)
end

addHook("HUD",function(v,p,cam)
	local feed = HUD.memory.hitmarkers
	if feed == nil then return end
	
	for i = #feed, 1, -1
		local info = feed[i]
		if info.tics <= 0
			table.remove(feed, i); continue
		end
		
		v.dointerp(info.interptag)
		Icon(v,p,cam, info)
		v.dointerp(false)
		if not paused
			info.tics = $ - 1
			info.frame = $ + 1
			info.elapsed = $ + 1
		end
	end
	offset = 0
end,"game")