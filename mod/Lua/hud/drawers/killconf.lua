local HUD = Paint.HUD
local offset = 0
local len = 5*TR
local popup = 4
local slidein = 4

function HUD:killConfirm(p, targ, wasassist)
	if displayplayer ~= p then return end
	
	if HUD.memory.killfeed == nil
		HUD.memory.killfeed = {}
	end
	
	local mo = targ.mo
	table.insert(HUD.memory.killfeed, {
		pos = {x=mo.x,y=mo.y,z=mo.z + mo.height/2},
		name = targ.name,
		tics = 5 * TR,
		assist = wasassist,
		id = (#targ) --always a player
	})
end

local function Icon(v,p,cam, info)
	local result = K_GetScreenCoords(v,p,cam, {x=info.pos.x, y=info.pos.y, z=info.pos.z})
	if not result.onscreen then return end
	
	local scale = 0
	if info.tics > len - popup
		scale = ((FU/2)/popup) * (info.tics - (len - popup))
	end
	local iconname = (info.assist) and "PAINT_ASSIST" or "PAINT_KILL"
	local finalscale = FU/4 + scale
	if (info.assist) then finalscale = $/2; end
	v.drawScaled(result.x,result.y, finalscale, v.cachePatch(iconname), 0, v.getColormap(nil, Paint:getPlayerColor(p)))
end

addHook("HUD",function(v,p,cam)
	local feed = HUD.memory.killfeed
	if feed == nil then return end
	
	local y = (200 - 12)
	local scnwid = (v.width()/v.dupx())/2
	offset = 0
	
	--for k, info in ipairs(feed)
	for k = 1, #feed
		local info = feed[k]
		if not (info and info.tics > 0)
			table.remove(feed, k)
		end
	end
	
	for k = 1, #feed
		local info = feed[k]
		
		v.dointerp(info.id)
		Icon(v,p,cam, info)
		v.dointerp(false)
		
		if not info.assist
			local x = 160
			if info.tics > (len - slidein)
				x = $ - ((scnwid/slidein) * (info.tics - (len - slidein)))
			end
			local fade = 0
			if info.tics < 10
				fade = (10 - info.tics) << V_ALPHASHIFT
			end
			
			local str = "Killed "..info.name.."!"
			local str_wid = v.stringWidth(str,0,"thin")/2
			offset = $ + 7
			v.dointerp(info.id + 1)
			v.drawFill(x - str_wid/2 - 2,
				y - offset - 1,
				str_wid + 3, 6, 29|V_SNAPTOBOTTOM|fade
			)
			v.drawString(x,y - offset, str, V_SNAPTOBOTTOM|V_ALLOWLOWERCASE|fade,"small-thin-center")
		end
		v.dointerp(false)
		if not paused
			info.tics = $ - 1
		end
	end
end,"game")