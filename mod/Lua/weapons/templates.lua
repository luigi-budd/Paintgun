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

function Paint.wtemplate_splatana(p,pt, weapon, key,value, crosshair)
	local crosshaircheck = false
	if crosshair
		crosshaircheck = pt.charge > 0
	else
		crosshaircheck = pt.maxchargeshot
	end
	
	if key == "crs_guideframe"
	and (pt.charge)
		return weapon:get(pt,"crs_chargedguideframe")
	elseif key == "h_fuse"
	and crosshaircheck
		return weapon:get(pt,"v_fuse")
	elseif key == "totaldamage"
	and (pt.maxchargeshot)
		return weapon:get(pt,"maxdamage")
	elseif key == "spawnspeed"
	and crosshaircheck
		return weapon:get(pt,"v_speed")
	
	elseif key == "melee_damage"
	and (pt.maxchargeshot)
		return weapon:get(pt,"vmelee_damage")
	elseif key == "melee_radius"
	and (pt.maxchargeshot)
		return weapon:get(pt,"vmelee_radius")
	elseif key == "melee_height"
	and (pt.maxchargeshot)
		return weapon:get(pt,"vmelee_height")
	end
end