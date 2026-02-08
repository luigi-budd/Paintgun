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
		local chargeprogress = min(FixedDiv(max(pt.charge, pt.storedcharge), weapon.chargetime), FU)
		return minrange + FixedMul(value - minrange, chargeprogress)
	elseif (key == "inkcost")
		local mincost = weapon:get(pt,"mininkcost")
		local chargeprogress = min(FixedDiv(pt.charge, weapon.chargetime), FU)
		return mincost + FixedMul(value - mincost, chargeprogress)
	end
end

function Paint.wtemplate_brella(p,pt, weapon, key,value)
	local firing = false
	if (pt.fireheld or p.cmd.buttons & BT_ATTACK)
		firing = true
	end
	if (pt.deployshield or pt.shieldlag)
	or (pt.firewait or pt.fireheld or pt.endlag)
		firing = true
	end
	if not (pt.anglefix) then firing = false; end
	
	if (key == "handoffset")
	and firing
		return 0
	end
	if (key == "tapfire")
	and (pt.shield and pt.shield.paint_hp <= 0 or pt.shieldlost)
	and not (weapon:get(pt,"nocanopy") or weapon:get(pt,"shootwhiledeployed"))
		return true
	end
end
