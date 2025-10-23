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
		
		local fadeprogress = ease.insine(FixedDiv(hp, 100*FU), FU, 0)
		local fade = fadeprogress
		local scale = FU --+ (FixedMul(FU/10, FU - fade))
		local patch_progress = (FixedMul(8*FU, fadeprogress)/FU) + 1
		patch_progress = clamp(1,$,8)
		local patch = v.cachePatch("PAINT_OVERLAY" .. patch_progress )
		local wid = (v.width() / v.dupx()) + 1
		local hei = (v.height() / v.dupy()) + 1
		local p_w = patch.width
		local p_h = patch.height
		local nudge = FU/2
		
		--local pulse = 0
		local X_STR = FixedMul(FixedDiv(wid * FU, p_w * FU), scale) + FU/7
		local Y_STR = FixedMul(FixedDiv(hei * FU, p_h * FU), scale) + FU/7
		
		local color = ColorOpposite(Paint:getPlayerColor(p))
		if pt.paintoverlay and pt.paintoverlay.valid
			color = pt.paintoverlay.color
		end
		local clrmp = v.getColormap(TC_RAINBOW,color)
		
		fade = (10*$)/FU
		fade = max($, 2)
		fade = 10 - min($,9)
		
		local strength = 5*FixedMul(fadeprogress, scale)
		local speed = 7*FU
		local YPOS = 100*FU + FixedMul( strength/3, sin(FixedAngle(speed *leveltime)) )
		v.dointerp(100)
		for i = 0,p_h
			local ifrac = i*FU
			local shift = FixedMul(strength, cos(FixedAngle( speed * (leveltime+i) )) )
			
			v.drawCropped(160*FU + shift, YPOS + FixedMul(ifrac,Y_STR),
				X_STR,Y_STR, patch, (fade << V_ALPHASHIFT)|V_ADD, clrmp,
				0, ifrac, p_w*FU, FU
			)
			if fade < 5
				v.drawCropped(160*FU + shift, YPOS + FixedMul(ifrac,Y_STR),
					X_STR,Y_STR, patch, ((fade*2) << V_ALPHASHIFT)|V_ADD, clrmp,
					0, ifrac, p_w*FU, FU
				)
			end
		end
		v.dointerp(false)
		
		--v.drawString(160,150, ("%.2f hp"):format(pt.hp), V_ALLOWLOWERCASE,"thin")
	end
end,"game")