local HUD = Paint.HUD
local offset = 0
local tag_len = 7*TR
local token_len = 3*TR
local popup = 4
local slidein = 4

function HUD:killConfirm(p, targ, wasassist)
	if displayplayer ~= p then return end
	
	if HUD.memory.killfeed == nil
		HUD.memory.killfeed = {}
	end
	
	local mo = targ.realmo
	if not (mo and mo.valid) then return end
	
	if (#HUD.memory.killfeed > 6)
		table.remove(HUD.memory.killfeed, 1)
	end
	
	table.insert(HUD.memory.killfeed, {
		pos = {x=mo.x,y=mo.y,z=mo.z + mo.height/2},
		name = targ.name,
		token_tics = token_len,
		tag_tics = tag_len,
		assist = wasassist,
		id = (#targ) + leveltime --always a player
	})
end

local function Icon(v,p,cam, info)
	if not info.token_tics then return end
	local result = K_GetScreenCoords(v,p,cam, {x=info.pos.x, y=info.pos.y, z=info.pos.z})
	if not result.onscreen then return end
	
	local scale = 0
	if info.token_tics > token_len - popup
		scale = ((FU/2)/popup) * (info.token_tics - (token_len - popup))
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
		if not (info and info.tag_tics > 0)
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
			if info.tag_tics > (tag_len - slidein)
				x = $ - ((scnwid/slidein) * (info.tag_tics - (tag_len - slidein)))
			end
			local fade = 0
			if info.tag_tics < 10
				fade = (10 - info.tag_tics) << V_ALPHASHIFT
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
			info.token_tics = max($ - 1, 0)
			info.tag_tics = $ - 1
		end
	end
end,"game")