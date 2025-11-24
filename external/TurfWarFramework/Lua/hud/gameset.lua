local y
return function(v)
	if (TurfWar.time == TurfWar.const.NOTIMER) then return end
	
	if TurfWar.time > 0
		y = v.height() / v.dupy()
		return
	end
	y = max($ - ($/10), 0)
	
	local str = "GAME!"
	v.drawLevelTitle(160 - v.levelTitleWidth(str)/2,
		100 - (v.levelTitleHeight(str)/2) - y,
		str, 0
	)
end