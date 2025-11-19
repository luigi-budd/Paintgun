local final_string = "One minute left!"
local str_len = final_string:len()
local pos = {1,1}

local animation = 0
local anim_len = 2 * TR
local anim_pulse = TR/2
local anim_frac = FU / anim_pulse

addHook("HUD",function(v)
	if not (TurfWar and Paint) then return end
	if not Paint:isMode() then return end
	
	if TurfWar.minutewarning
		animation = anim_len
		pos = {1,1}
	end
	
	if not animation then return end
	
	local goingback = false
	if animation >= (anim_len) - TR/2
		pos[2] = min($ + 1, str_len)
	elseif animation < str_len
		pos[1] = $ + 1
		goingback = true
	end
	
	local scale = FU * 3/2
	/*
	if animation >= (anim_len - str_len) - anim_pulse/2
	and animation <= (str_len*2) + anim_pulse/2
		if animation >= (str_len)
			scale = $ + ease.inoutsine(
				FU - (anim_frac * (animation - ((anim_len - str_len) + anim_pulse/2))),
				FU/2, 0
			)
		--grow
		else
			scale = $ + ease.inoutsine(
				anim_frac * (animation - ((anim_len - str_len) - anim_pulse/2)),
				0, FU/2
			)
		end
	end
	*/
	
	local x = 160*FU - FixedMul(v.stringWidth(final_string,0,"thin")*FU,scale)/2
	local y = 65*FU
	for i = 1,pos[2]
		local letter = final_string:sub(i,i)
		if ((not goingback)
		or (i > pos[1]))
		and (letter ~= " ")
			if (letter == "@")
				local pat = v.cachePatch("PT_CLOCK")
				v.drawScaled(x,y, scale,
					pat,
					V_50TRANS
				)
				x = $ + (pat.width*scale)
			else
				v.drawScaled(x,y, scale,
					v.cachePatch(string.format("TNYFN%.3d", letter:byte())),
					V_50TRANS
				)
			end
		end
		if (letter ~= "@")
			x = $ + FixedMul(v.stringWidth(letter,0,"thin")*FU, scale)
		end
	end
	animation = $ - 1
end,"game")