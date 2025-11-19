addHook("HUD",function(v)
	if not (TurfWar and Paint) then return end
	if not Paint:isMode() then return end
	
	if not (TurfWar.time > 0
	and TurfWar.time <= 10*TR)
		return
	end
	
	local number = (TurfWar.time + 1)/TR
	local scale = FU * 3
	print(number)
	
	local x = 160*FU
	local y = 100*FU
	
	v.drawScaled(x,y, scale,
		v.cachePatch(string.format("TNYFN%.3d", letter:byte())),
		V_ADD|V_80TRANS
	)
	
	animation = $ - 1
end,"game")