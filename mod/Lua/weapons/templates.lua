-- weapon.abilitywrap templates for weapon classes

function Paint.wtemplate_dualies(p,pt, weapon, key,value)
	if not pt.turretmode then return end
	if (key == "range")
		return weapon.turret_range ~= nil and weapon.turret_range or value
	elseif (key == "firerate")
		return weapon.turret_firerate ~= nil and weapon.turret_firerate or value
	elseif (key == "shotoffset")
		return 0
	elseif (key == "neverspreadonground")
		return P_RandomChance(FU/10)
	elseif (key == "inkcost")
		return weapon.dodgeshotcost ~= nil and weapon.dodgeshotcost or value
	end
end

function Paint.wtemplate_charger(p,pt, weapon, key,value)
	if (key == "range")
		local minrange = weapon:get(pt,"minrange")
		local chargeprogress = min(FixedDiv(pt.charge*FU, weapon.chargetime*FU), FU)
		return max(FixedMul(value, chargeprogress), minrange)
	end
end

