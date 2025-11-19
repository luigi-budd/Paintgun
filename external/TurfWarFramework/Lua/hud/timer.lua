local cv_timelimit
local cv_overtime

addHook("HUD",function(v)
	if not (TurfWar and Paint) then return end
	if not Paint:isMode() then return end
	
	if not cv_timelimit
		cv_timelimit = CV_FindVar("timelimit")
	end
	if not cv_overtime
		cv_overtime = CV_FindVar("overtime")
	end
	
	local y = 6
	local x = 160
	local t_width = 60
	local t_height = 6
	local flags = V_SNAPTOTOP
	
	do
		
		local time = 0
		local cmap = 0
		if (TurfWar.time ~= TurfWar.const.NOTIMER)
			time = (TurfWar.time or 0)
			if (time ~= 0) then time = $ + TR; end
			if (time < 0) then time = 0; end
			cmap = (time <= 61*TR and V_YELLOWMAP or 0)
		else
			if (gametyperules & GTR_TIMELIMIT)
			and (cv_timelimit.value)
				if leveltime < cv_timelimit.value*60*TR
					time = (cv_timelimit.value*60*TR) - leveltime
					if (time ~= 0) then time = $ + TR; end
				else
					if leveltime > (cv_timelimit.value*60*TR) + (TR/2)
					and (gametyperules & GTR_OVERTIME and cv_overtime.value)
						time = "Overtime!"
						cmap = (leveltime/(TR/2)) % 2 == 0 and V_YELLOWMAP or V_ORANGEMAP
					else
						time = 0
					end
				end
				if type(time) == "number"
					cmap = (time <= 61*TR and V_YELLOWMAP or 0)
				end
			else
				time = consoleplayer.realtime
			end
		end
		
		local minutes,seconds,str
		if type(time) == "number"
			minutes = G_TicsToMinutes(time, true)
			seconds = G_TicsToSeconds(time)
			str = ("%d:%.2d"):format(minutes,seconds)
		else
			str = time
		end
		v.drawFill(x - (t_width/2) - 1, y - 2,            t_width,t_height, 29|flags)
		v.drawFill(x - (t_width/2),     y - 2 + t_height, t_width,t_height, 29|flags)
		v.drawString(x, y, str, flags|cmap|V_ALLOWLOWERCASE, "thin-center")
	end
	
	if G_GametypeHasTeams()
		local count = Paint:countTeams()
		local width = 26
		local height = 6
		local offset = t_width - (width/2) - 4
		local ramp = 0
		local y = y - 2
		
		-- bravo team
		ramp = skincolors[skincolor_blueteam].ramp[3]
		v.drawFill(x - (width/2) - 1 - offset, y,          width,height, ramp|flags)
		v.drawFill(x - (width/2) - offset,     y + height, width,height, ramp|flags)
		v.drawString(x - offset, y + 2, count.bravo, flags, "thin-center")
		
		-- alpha team
		ramp = skincolors[skincolor_redteam].ramp[3]
		v.drawFill(x - (width/2) - 1 + offset, y,          width,height, ramp|flags)
		v.drawFill(x - (width/2) + offset,     y + height, width,height, ramp|flags)
		v.drawString(x + offset, y + 2, count.alpha, flags, "thin-center")
		
		-- bravo lead
		local ls = 0
		if (bluescore > redscore)
			ls = -1
		elseif (redscore > bluescore)
			ls = 1
		end
		
		if ls ~= 0
			local lx = x + (offset + (width/2) + 31)*ls
			if (ls == 1) then lx = $ - 29; end
			v.drawScaled(lx*FU,y*FU, FU, v.cachePatch("PT_LEAD_0"), flags|V_ADD)
			v.drawScaled(lx*FU,y*FU, FU, v.cachePatch("PT_LEAD_1"), flags|V_ADD|V_60TRANS)
			v.drawScaled(lx*FU,y*FU, FU, v.cachePatch("PT_LEAD_2"), flags)
		end
	end
	
end,"game")