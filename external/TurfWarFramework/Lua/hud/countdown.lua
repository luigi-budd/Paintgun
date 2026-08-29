local animation = 0
local lastnumber = 11
local ANIM_START = TR - 2
local hidingalpha = 20

local cv_hidetime = CV_FindVar("hidetime")
return function(v)
	if TurfWar.time == TurfWar.const.NOTIMER then return end
	
	local hidetime = false
	local roundtimer = TurfWar.time
	local docountdown = true
	if not (TurfWar.time > 0 and TurfWar.time < 10*TR)
		docountdown = false
	end
	if ((gametyperules & GTR_TAG) and cv_hidetime.value)
		local remaining = (cv_hidetime.value*TR - leveltime)
		docountdown = remaining < 10*TR and remaining > 0
		if docountdown
			roundtimer = (cv_hidetime.value*TR - leveltime)
			hidetime = true
		end
	end
	
	if hidetime
		hidingalpha = max($ - 1, 0)
	else
		hidingalpha = min($ + 7, 20)
	end
	if hidingalpha ~= 20 and (hidingalpha / 2 ~= 10)
		local trans = (hidingalpha / 2) << V_ALPHASHIFT
		v.drawString(160, 40, "Hiding ends in:", V_ALLOWLOWERCASE|V_ADD|trans|V_GRAYMAP, "thin-center")
	end
	
	if not docountdown then return end
	
	local number = (roundtimer/TR) + 1
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
	
	v.dointerp(150 + number)
	v.drawScaled(x,y, scale,
		v.cachePatch("PTCOUNT_"..(number)),
		V_ADD|fade
	)
	v.dointerp(false)
	
	animation = $ - 1
end