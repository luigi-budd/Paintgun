local FADE = 2*TR + TR/2
addHook("HUD",function(v,p)
	if (gametype ~= GT_SALMONRUN) then return end
	local me = p.realmo
	
	local tics = 0
	if me.deathtimer
	and (me.deathtimer > FADE)
		tics = me.deathtimer - FADE
		if me.deathtimer - FADE < 10
			tics = 10 - $
		end
	end
	if (p.lifesaver_anim)
	and ((TR*3/2) - p.lifesaver_anim < 10)
		tics = (TR*3/2) - p.lifesaver_anim
	end
	
	if tics == 0 then return end
	local fade = 0
	if (tics < 10)
		fade = tics << V_ALPHASHIFT
	end
	
	Paint.HUD.drawSplashBG(v, 1,1,
		0,0,
		(v.width()/v.dupx())*FU, (v.height()/v.dupy())*FU,
		V_SNAPTOLEFT|V_SNAPTOTOP|fade,
		v.getColormap(TC_DEFAULT, SKINCOLOR_CARBON), false
	)
end,"game")