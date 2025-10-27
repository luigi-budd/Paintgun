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
	
	/*
	-- proof-of-concept wavy "ink meter"
	do
		local patch = v.cachePatch("PT_LOW_BG")
		local strength = FU
		local speed = 14*FU
		local clrmp = v.getColormap(TC_DEFAULT, Paint:getPlayerColor(p))
		
		local clip_w = 128*2
		local clip_h = 48*2
		local crop_w = 64*FU
		local crop_h = 23*FU
		local force = FU/2
		local sx = leveltime
		local sy = leveltime
		for i = 0, (crop_w + abs(16 * sin(FixedAngle(leveltime*FU*4))))/FU
			local ifrac = i*FU
			local shift = FixedMul(strength, cos(FixedAngle( speed * (leveltime+i) )) )
			
			v.drawCropped(160*FU + ifrac, 100*FU + shift,
				FU,FU, patch, 0, clrmp,
				abs((sx % clip_w)*force + ifrac), abs((sy % clip_h)*force), FU, crop_h - shift
			)
		end
	end
	*/
	
	local x = (160 - (68/2))*FU
	local y = 150*FU
	local flags = V_SNAPTOBOTTOM
	local clrmp = v.getColormap(TC_DEFAULT, Paint:getPlayerColor(p))
	if tics
		local anim = (leveltime - starttic) % MAXTICS+1
		local fade = sin(FixedAngle(FixedMul(180*FU, FixedDiv((anim > HALFTICS) and (HALFTICS - anim) or anim, HALFTICS))))
		
		-- bg
		do
			local clip_w = 128*2
			local clip_h = 48*2
			local crop_w = 64*FU
			local crop_h = 23*FU
			local x = x + 2*FU
			local y = y + 2*FU
			v.drawCropped(x,y,FU,FU, v.cachePatch("PT_LOW_BG"), flags|V_20TRANS, clrmp,
				abs((leveltime) % clip_w)*FU/2, abs((leveltime) % clip_h)*FU/2, crop_w,crop_h
			)
		end
		
		v.drawScaled(x,y, FU, v.cachePatch("PT_LOW_TXT"), flags)
		v.drawScaled(x,y + fade/2, FU, v.cachePatch("PT_LOW_TNK"), flags)
		v.drawScaled(x,y, FU, v.cachePatch("PT_LOW_X"), flags|V_ADD|(
			(FixedInt(10 * abs(fade)) & 10)<<V_ALPHASHIFT
		))
		
		-- marquee
		do
			local clip_w = 72
			local crop_w = 64*FU
			local crop_h = 6*FU
			local x = x + 2*FU
			local y = y + 2*FU
			v.drawCropped(x,y,FU,FU, v.cachePatch("PT_LOW_MARQ"), flags, clrmp,
				abs((leveltime) % clip_w)*FU, 0, crop_w,crop_h
			)
		end
		v.drawScaled(x,y, FU, v.cachePatch("PT_LOW_OUT"), flags, clrmp)
		
		if not paused
			tics = $ - 1
		end
	end
end,"game")