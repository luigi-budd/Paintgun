addHook("HUD",function(v,p)
	if (gametype ~= GT_SALMONRUN) then return end
	local rs = Salmon.roundstatus
	if not (rs.intermission) then return end
	
	local x = 160
	local y = 20
	local flags = V_SNAPTOTOP|V_ALLOWLOWERCASE|V_GREENMAP
	local introtic = (Salmon.const.INTER_TIME - rs.intermission) + 1
	
	if rs.intermission < 10
		flags = $|(10 - rs.intermission)<<V_ALPHASHIFT
	elseif introtic < 10
		flags = $|(10 - introtic)<<V_ALPHASHIFT
	end
	
	v.drawString(x,y, "Wave "..rs.wavenumber.." starts in", flags, "thin-center")
	v.drawString(x,y + 10, (rs.intermission/TR)+1, flags, "center")
	
	v.dointerp(6167)
	if rs.intermission < 10
		x = ease.outback((FU/10) * rs.intermission, 500*FU, $*FU, FU)/FU
	elseif introtic < 10
		x = ease.inback((FU/10) * (10 - introtic), $*FU, -500*FU, FU)/FU
	end
	y = 140
	flags = ($ &~(V_GREENMAP|V_SNAPTOTOP))|V_ORANGEMAP|V_SNAPTOBOTTOM
	
	v.drawString(x, y, "Hazard level:", flags, "center")
	v.drawString(x, y + 10,
		("%.0f%% \x1d %.0f%%"):format(
			FixedDiv(rs.hazard - Salmon.const.HAZARD_INCREASE, FU/2)*100,
			FixedDiv(rs.hazard, FU/2)*100
		), flags, "center"
	)
	v.dointerp(false)
end,"game")