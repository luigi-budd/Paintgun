local HUD = Paint.HUD
local wipeteam = 0
local wipetics = 0
local WIPEANIM = 2*TR + (TR/2)

local LETTER_DOWN = -10*FU
local LETTER_UP = 5*FU
local LETTER_TICS = 12
local LETTER_FRAC = (FU / LETTER_TICS)

local letters = {}
-- i cant be bothered to properly crop the letters
local spacing = {
	[1] = 43,
	[2] = 13,
	[3] = 27,
	[4] = 21,
	[5] = 29,
	[6] = 29,
	[7] = 29,
	[8] = 17,
}
local function resetletters()
	for i = 1,8
		letters[i] = {
			tics = LETTER_TICS,
			wait = (i - 1),
		}
	end
end

function HUD:wipeoutAnim(team)
	wipeteam = team
	wipetics = WIPEANIM
	resetletters()
end

addHook("HUD",function(v,p,cam)
	if not wipetics then return end

	local myteam = 1
	if (not p.spectator)
		myteam = p.ctfteam
	end
	
	local x = 160*FU
	local y = 70*FU
	local scale = FU / 2

	local cmap = v.getColormap(TC_DEFAULT, (wipeteam == 1) and skincolor_redteam or skincolor_blueteam)

	local tics = (WIPEANIM - wipetics)
	local grow = (tics*FU/500)
	local master_fade = 0
	if (wipetics < 10)
		master_fade = (10 - wipetics) << V_ALPHASHIFT
	end
	v.drawStretched(x,y,
		FixedMul(scale * 6/5, min((FU/6)*tics,FU)) + grow, scale - grow/2,
		v.cachePatch("PTWIPE_U"), V_ADD|master_fade, cmap
	)

	-- Letter Logic
	-- this is the width of the text
	x = $ - (208 * scale)/2
	-- this is the height of the text i think
	y = $ - (48 * scale)/2
	local lpatch = (wipeteam == myteam) and "PTWIPED_" or "PTWIPEA_"
	for i = 1,8
		local lt = letters[i]
		if lt.wait
			lt.wait = $ - 1
			continue
		end
		
		local fade = 0
		local oy = 0
		if lt.tics
			local start = (LETTER_TICS - lt.tics) + 1
			if start < 10 and start > 0
				fade = (10 - start) << V_ALPHASHIFT
			end
			
			oy = ease.outback(FU - (LETTER_FRAC * lt.tics), LETTER_UP, 0, -FU*12)
			lt.tics = $ - 1
		end
		
		v.drawScaled(x,y + oy, scale, v.cachePatch(lpatch..i), fade|master_fade, cmap)
		x = $ + (spacing[i] * scale)
	end

	wipetics = $ - 1
end)