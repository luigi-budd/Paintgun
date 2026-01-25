local HUD = Paint.HUD
local FRAMETIME = 0

addHook("HUD",function(v,p,cam)
	local me = p.mo
	FRAMETIME = $ + 1

	if not (me and me.valid) then return end
	if not Paint:playerIsActive(p) then return end
	local pt = p.paint
	
	if (me.paint_nopainoverlay) then return end
	
	local hp = pt.hp
	if (p.playerstate ~= PST_LIVE)
		hp = 0
	end
	if (me.paint_overlayhp ~= nil)
		hp = me.paint_overlayhp
	end
	if hp >= 100*FU then return end

	-- draw the stuff
	local fadeprogress = ease.linear(FixedDiv(hp, 100*FU), FU, 0)
	local scale = FU
	if fadeprogress <= FU/2
		scale = $ + ease.outquad(fadeprogress*2, FU/3, 0)
	end
	local patch_progress = (FixedMul(11*FU, fadeprogress)/FU)
	patch_progress = clamp(0,$,11)
	local patch = v.cachePatch("PAINT_OVERLAY" .. patch_progress)
	local wid = (v.width() / v.dupx()) + 1
	local hei = (v.height() / v.dupy()) + 1
	local p_w = patch.width
	local p_h = patch.height
	local nudge = FU/2
	
	local X_STR = FixedMul(FixedDiv(wid * FU, p_w * FU), scale) + FU/7
	local Y_STR = FixedMul(FixedDiv(hei * FU, p_h * FU), scale) + FU/7
	
	local color = ColorOpposite(Paint:getPlayerColor(p))
	if pt.paintoverlay and pt.paintoverlay.valid
		color = pt.paintoverlay.color
	end
	local clrmp = v.getColormap(TC_DEFAULT,color)
	
	local strength = 6*FixedMul(fadeprogress, scale)
	local speed = 6*FU
	local YPOS = 100*FU + FixedMul( strength/3, sin(FixedAngle(speed * FRAMETIME)) )
	local blending = V_SUBTRACT
	
	v.dointerp(100)
	if (v.renderer() == "opengl")
		for i = 0,p_h
			local ifrac = i*FU
			local shift = FixedMul(strength, cos(FixedAngle( speed * (FRAMETIME+i) )) )
			
			v.drawCropped(160*FU + shift, YPOS + FixedMul(ifrac,Y_STR),
				X_STR,Y_STR, patch, blending, clrmp,
				0, ifrac, p_w*FU, FU
			)
		end
	else
		v.drawStretched(160*FU, YPOS, X_STR,Y_STR, patch, blending, clrmp)
	end
	v.dointerp(false)
	
	--v.drawString(160,150, ("%.2f hp"):format(pt.hp), V_ALLOWLOWERCASE,"thin")
end,"game")