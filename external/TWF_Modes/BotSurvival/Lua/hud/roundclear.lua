local fmt_string = "Wave %d Cleared!"
local final_string = fmt_string
local lose_string = "Wave %d Failed!"

local str_len = final_string:len()
local usefail = false

local pos = {1,1}

local animation = 0
local anim_len = 4 * TR
local anim_pulse = TR/2
local anim_frac = FU / anim_pulse

addHook("HUD",function(v,p)
	if (gametype ~= GT_SALMONRUN) then return end
	
	local rs = Salmon.roundstatus
	if rs.waveclear
		animation = anim_len
		
		usefail = rs.failed
		final_string = (usefail and lose_string or fmt_string):format(rs.wavenumber)
		str_len = final_string:len()
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
	local y = 40*FU
	for i = 1,pos[2]
		local letter = final_string:sub(i,i)
		if ((not goingback)
		or (i > pos[1]))
		and (letter ~= " ")
			if (letter == "@")
				local pat = v.cachePatch("PT_CLOCK")
				v.drawScaled(x,y, scale,
					pat,
					V_50TRANS|V_SNAPTOTOP
				)
				x = $ + (pat.width*scale)
			else
				v.drawScaled(x,y, scale,
					v.cachePatch(string.format("TNYFN%.3d", letter:byte())),
					V_50TRANS|V_SNAPTOTOP
				)
			end
		end
		if (letter ~= "@")
			x = $ + FixedMul(v.stringWidth(letter,0,"thin")*FU, scale)
		end
	end
	animation = $ - 1
end,"game")