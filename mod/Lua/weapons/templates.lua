-- weapon.abilitywrap templates for weapon classes

function Paint.wtemplate_dualies(p,pt, weapon, key,value)
	if not pt.turretmode then return end
	if (key == "range")
		return weapon.turret_range ~= nil and weapon.turret_range or value
	elseif (key == "firerate")
		if weapon.turret_firerate == nil
			return value
		end
		return weapon.turret_firerate
	elseif (key == "shotoffset")
		return 0
	elseif (key == "neverspreadonground")
		return false --P_RandomChance(FU/10) -- seems like it causes resynchs?
	elseif (key == "inkcost")
		if weapon.dodgeshotcost == nil
			return value
		end
		return weapon.dodgeshotcost
	elseif (key == "endlag")
		return weapon.realendlag or 0
	elseif (key == "handoffset")
		return 0
	end
end

function Paint.wtemplate_charger(p,pt, weapon, key,value)
	if (key == "range")
		local minrange = weapon:get(pt,"minrange")
		local chargeprogress = min(FixedDiv(pt.charge, weapon.chargetime), FU)
		return minrange + FixedMul(value - minrange, chargeprogress)
	elseif (key == "inkcost")
		local mincost = weapon:get(pt,"mininkcost")
		local chargeprogress = min(FixedDiv(pt.charge, weapon.chargetime), FU)
		return mincost + FixedMul(value - mincost, chargeprogress)
	end
end

