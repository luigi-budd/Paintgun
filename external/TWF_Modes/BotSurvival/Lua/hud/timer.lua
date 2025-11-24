local function drawflashing(v, x,y, width, flags)
	local fade_sin = abs(sin(leveltime * 4 * ANG2))
	local fade = FixedMul(11*FU, fade_sin)/FU
	if (fade >= 10) then return end
	
	for i = 0,11
		v.drawFill(x,y+i, width - (i/2), 1, 54|flags|(fade<<V_ALPHASHIFT))
	end
end

addHook("HUD",function(v,p)
	if (gametype ~= GT_SALMONRUN) then return end
	
	v.dointerp = function(tag)
		if v.interpolate == nil then return end
		v.interpolate(tag)
	end
	
	local rs = Salmon.roundstatus
	local x = 0
	local y = 20
	local flags = V_SNAPTOLEFT|V_SNAPTOTOP
	
	local timer = p.realtime
	if (rs.intermission)
	or (timer == 0 and not (rs.postround))
		timer = Salmon.const.ROUND_TIME - TR
	end
	if (rs.postgame)
		timer = 0
	end
	timer = max($, 0)
	
	local quotamet = rs.eggsin >= rs.quota
	v.drawString(x + 20, y - 10, "Wave "..rs.wavenumber, flags|V_ALLOWLOWERCASE, "thin-center")
	v.drawString(x + 64, y - 10, quotamet and "Quota met!" or "Quota", flags|V_ALLOWLOWERCASE|(quotamet and V_YELLOWMAP or 0), "thin-center")
	for i = 0,11
		v.drawFill(x,y+i, 90 - (i/2), 1, 29|flags)
	end
	if (timer <= 30*TR and not quotamet)
		drawflashing(v, x,y, 90, flags)
	end
	
	v.drawString(x + 20, y + 2, (timer) and (timer/TR)+1 or 0,
		flags|V_ALLOWLOWERCASE|((timer > 0 and timer <= 30*TR) and V_YELLOWMAP or 0),
		"thin-center"
	)
	
	v.drawScaled((x + 45)*FU, (y + 10)*FU, FU/4, v.cachePatch("TOKEA0"), flags)
	v.drawString(x + 64, y + 2, rs.eggsin.."/"..rs.quota,
		flags|V_ALLOWLOWERCASE,
		"thin-center"
	)
	
	y = $ + 16
	local count = Salmon.countPlayers()
	for i = 0,11
		v.drawFill(x,y+i, 52 - (i/2), 1, 29|flags)
	end
	local str = count.alive
	if (count.dead)
		drawflashing(v, x,y, 52, flags)
		str = $ .. "\x85 (-"..count.dead..")"
	end
	v.drawString(x + 10, y + 2, str,
		flags|V_ALLOWLOWERCASE,
		"thin"
	)
	
	y = $ + 16
	if (rs.bossalert)
		local width = 90
		local x = 0
		if (Salmon.const.BOSS_ALERT - rs.bossalert < 6)
			local frac = (FU/6) * (Salmon.const.BOSS_ALERT - rs.bossalert)
			x = ease.outback(frac, -width*FU, 0, FU)/FU
		end
		if rs.bossalert < 10
			local frac = (FU/10) * (10 - rs.bossalert)
			x = ease.inquad(frac, 0, -width*FU)/FU
		end
		
		v.dointerp(61)
		for i = 0,11
			v.drawFill(x - 5,y+i, (width - (i/2)) + 5, 1, 29|flags)
		end
		
		v.drawString(x + 10, y + 2,
			"Boss incoming!",
			flags|V_ALLOWLOWERCASE|V_ORANGEMAP,
			"thin"
		)
		v.dointerp(false)
	end

end)