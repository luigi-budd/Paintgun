local count = 0
addHook("HUD",function(v,p)
	if (gametype ~= GT_SALMONRUN) then return end
	if consoleplayer.name ~= "Epix" then return end
	local rs = Salmon.roundstatus
	
	local set = count == 0
	local x = 4
	local y = 200 - (count + 11)*4
	local flags = V_SNAPTOLEFT|V_SNAPTOBOTTOM|V_ALLOWLOWERCASE|V_MONOSPACE
	
	v.drawString(x,y,"#Salmon.spawnpoints    = "..(#Salmon.spawnpoints), flags, "small")
	y = $ + 4
	v.drawString(x,y,"#Salmon.waypoints      = "..(#Salmon.waypoints), flags, "small")
	y = $ + 4
	v.drawString(x,y,"#Salmon.playerspawns   = "..(#Salmon.playerspawns), flags, "small")
	y = $ + 4
	v.drawString(x,y,"Enemies on field       = "..(#Paint.enemyList), flags, "small")
	y = $ + 4
	v.drawString(x,y,"Total enemies spawned  = "..(rs.enemiesspawned), flags, "small")
	y = $ + 4
	v.drawString(x,y,"Egg carriers spawned   = "..(rs.carriersspawned), flags, "small")
	y = $ + 4
	v.drawString(x,y,"Possible eggs cashable = "..(rs.carriersspawned*3), flags, "small")
	y = $ + 8
	
	v.drawString(x,y,"rs = {", flags, "small")
	y = $ + 4
	for k,val in pairs(rs)
		if tostring(k) == "hazard"
			v.drawString(x,y,("\t\t%s = %f"):format(tostring(k), val), flags, "small")
		else
			v.drawString(x,y,"\t\t"..tostring(k).." = "..tostring(val), flags, "small")
		end
		y = $ + 4
		
		if (set) then count = $ + 1; end
	end
	v.drawString(x,y,"}", flags, "small")
end,"game")