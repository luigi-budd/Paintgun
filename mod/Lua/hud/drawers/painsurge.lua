local HUD = Paint.HUD
local paintics = 0

function HUD:painSurge(p)
	if displayplayer ~= p then return end
	
	paintics = 6
end

local hudinfo = {}
hudinfo.func = function(v,p,cam)
	if not paintics then return end
	
	local frame = (7 - paintics)
	local patch = v.cachePatch("PAINT_PS_"..(frame))
	local wid = (v.width() / v.dupx()) + 1
	local hei = (v.height() / v.dupy()) + 1
	local p_w = patch.width
	local p_h = patch.height
	v.drawStretched(0,0,
		FixedDiv(wid * FU, p_w * FU),
		FixedDiv(hei * FU, p_h * FU),
		patch,
		V_SNAPTOTOP|V_SNAPTOLEFT,
		v.getColormap(TC_DEFAULT,Paint:getPlayerColor(p))
	)
	if not paused
		paintics = $ - 1
	end
end
hudinfo.type = "game"
return hudinfo