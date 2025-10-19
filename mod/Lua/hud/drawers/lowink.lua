local HUD = Paint.HUD
local MAXTICS = TR
local HALFTICS = MAXTICS/2
local tics = 0
local starttic = 0

function HUD:lowInkWarning(p, cooldown)
	if displayplayer ~= p then return end
	if not tics
		S_StartSound(nil, sfx_pt_noi, p)
		starttic = leveltime
	end
	tics = max(MAXTICS, (cooldown or 0) + 1)
end

addHook("HUD",function(v,p,cam)
	local me = p.mo
	if not (me and me.valid) then return end
	if not Paint:playerIsActive(p) then return end
	local pt = p.paint
	
	local x = (160 - (68/2))*FU
	local y = 150*FU
	local flags = V_SNAPTOBOTTOM
	local clrmp = v.getColormap(TC_DEFAULT, Paint:getPlayerColor(p))
	if tics
		local anim = (leveltime - starttic) % MAXTICS
		local fade = sin(FixedAngle(FixedMul(360*FU, FixedDiv((anim > HALFTICS) and (HALFTICS - anim) or anim, HALFTICS))))
		
		v.drawScaled(x,y, FU, v.cachePatch("PT_LOW_BG"), flags|V_50TRANS, clrmp)

		v.drawScaled(x,y, FU, v.cachePatch("PT_LOW_TXT"), flags)
		v.drawScaled(x,y + fade/2, FU, v.cachePatch("PT_LOW_TNK"), flags)
		v.drawScaled(x,y, FU, v.cachePatch("PT_LOW_X"), flags|V_ADD|(
			(FixedInt(10 * abs(fade)) & 10)<<V_ALPHASHIFT
		))

		-- marquee
		do
			local clip_w = 72*FU
			local crop_w = 64*FU
			local crop_h = 6*FU
			local x = x + 2*FU
			local y = y + 2*FU
			v.drawCropped(x,y,FU,FU, v.cachePatch("PT_LOW_MARQ"), flags, clrmp,
				(leveltime*FU) % clip_w, 0, crop_w,crop_h
			)
		end
		v.drawScaled(x,y, FU, v.cachePatch("PT_LOW_OUT"), flags, clrmp)

		if not paused
			tics = $ - 1
		end
	end
end,"game")