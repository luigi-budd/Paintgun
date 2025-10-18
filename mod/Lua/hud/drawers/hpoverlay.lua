local HUD = Paint.HUD
local fudge = FU/5
addHook("HUD",function(v,p,cam)
	local me = p.mo
	if not (me and me.valid) then return end
	if not Paint:playerIsActive(p) then return end
	local pt = p.paint
	
	if pt.hp ~= 100*FU
	or (p.playerstate == PST_DEAD)
		local hp = (p.playerstate ~= PST_DEAD) and pt.hp or 0
		
		local patch = v.cachePatch("PAINT_OVERLAY")
		local wid = (v.width() / v.dupx()) + 1
		local hei = (v.height() / v.dupy()) + 1
		local p_w = patch.width
		local p_h = patch.height
		local nudge = FU/2
		
		--local pulse = 0
		local fade = FU - FixedDiv(hp, 100*FU)
		local scale = FU + (FixedMul(FU/5, FU - fade))
		
		local color = ColorOpposite(Paint:getPlayerColor(p))
		if pt.paintoverlay and pt.paintoverlay.valid
			color = pt.paintoverlay.color
		end
		
		--pulse = FixedMul(fade, max(abs(sin(FixedAngle(leveltime*FU*3))) - fudge, fudge))
		--pulse = (10*$)/FU
		--pulse = 10 - min($, 9)
		
		fade = (10*$)/FU
		fade = 10 - min($,9)
		fade = min($, 9)
		--print(fade, pulse)
		
		v.drawStretched(160*FU,100*FU,
			FixedMul(FixedDiv(wid * FU, p_w * FU), scale),
			FixedMul(FixedDiv(hei * FU, p_h * FU), scale),
			patch,
			(fade << V_ALPHASHIFT)|V_ADD,
			v.getColormap(TC_RAINBOW,color)
		)
		if fade < 5
			v.drawStretched(160*FU,100*FU,
				FixedMul(FixedDiv(wid * FU, p_w * FU), scale),
				FixedMul(FixedDiv(hei * FU, p_h * FU), scale),
				patch,
				((fade*2) << V_ALPHASHIFT)|V_ADD,
				v.getColormap(TC_RAINBOW,color)
			)
		end
	end
end,"game")