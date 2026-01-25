local animation = 0
local lastnumber = 11
local ANIM_START = TR - 2

return function(v)
	if TurfWar.time == TurfWar.const.NOTIMER then return end
	if not (TurfWar.time > 0
	and TurfWar.time < 10*TR)
		return
	end
	
	local number = (TurfWar.time/TR) + 1
	if lastnumber ~= number
		animation = ANIM_START
		
		local sfx = sfx_p_c0
		if number <= 3
			sfx = $ + number
		end
		S_StartSound(nil, sfx)
		if sfx == sfx_p_c0
			S_StartSound(nil, sfx)
		end
	end
	lastnumber = number
	
	if not animation then return end
	
	local animfrac = (FU/ANIM_START) * (ANIM_START - animation)
	local scale = ease.outexpo(min((FU/6) * (ANIM_START - animation), FU),
		FU/10, FU/2
	) + ((ANIM_START - animation)*FU/500)
	local fade = 0
	if animation < 9
		/*
		fade = clamp(0, ease.outexpo(animfrac,
			0, 9*FU
		)/FU, 9) << V_ALPHASHIFT
		*/
		fade = (10 - animation) << V_ALPHASHIFT
	end
	
	local x = 160*FU
	local y = 80*FU
	
	v.drawScaled(x,y, scale,
		v.cachePatch("PTCOUNT_"..(number)),
		V_ADD|fade
	)
	
	animation = $ - 1
end