local htranstable = {
	[0] = 10,
	[1] = 9,
	[2] = 9,
	[3] = 8,
	[4] = 8,
	[5] = 7,
	[6] = 7,
	[7] = 6,
	[8] = 6,
	[9] = 5,
	[10] = 5,
}

return function(v)
	local msg = TurfWar.messagestate
	if not msg.tics then return end
	
	local x = 160
	local y = 45
	local fade = 0
	if (msg.tics < 10)
		fade = (10 - msg.tics)
	end
	/*
	if (TurfWar.const.MSG_TIME - msg.tics) < 5
		local tic = ((TurfWar.const.MSG_TIME - msg.tics) + 1)*2
		fade = (10 - tic) << V_ALPHASHIFT
	end
	*/
	local countup = (TurfWar.const.MSG_TIME - msg.tics)
	if (countup == 0)
		fade = 9
	elseif (countup == 1)
		fade = 7
	elseif (countup == 2)
		fade = 5
	elseif (countup == 3)
		fade = 3
	end
	
	local bgcolor = 29
	if msg.team ~= 0
		local color = skincolor_redteam
		if (msg.team == TurfWar.const.TEAM_BRAVO)
			color = skincolor_blueteam
		end
		bgcolor = skincolors[color].ramp[3]
	end
	
	local progress = (countup > 4) and FU or FixedDiv(countup*FU, 4*FU)
	local strlen = FixedMul((v.stringWidth(msg.text, V_ALLOWLOWERCASE,"normal") + 6)*FU, progress) / FU
	local strlen_h = strlen / 2
	local htrans = htranstable[10 - fade]
	if htrans ~= 10
		for i = 0,11
			v.dointerp(1300 + i + bgcolor)
			v.drawFill((x - 3) - strlen_h + (i/2), (y - 1) + i, strlen, 1, bgcolor|V_SNAPTOTOP|(htrans << V_ALPHASHIFT))
			v.dointerp(false)
		end
	end
	
	v.drawString(x,y, msg.text, V_SNAPTOTOP|V_ALLOWLOWERCASE|(fade << V_ALPHASHIFT), "center")
end