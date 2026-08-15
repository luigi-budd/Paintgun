local HUD = Paint.HUD

local CLASStoICON = {
	[WPT_SHOOTER] = "SHOOTER",
	[WPT_ROLLER]  = "ROLLER",
	[WPT_CHARGER] = "CHARGER",
	[WPT_SLOSHER] = "SLOSHER",
	[WPT_GATLING] = "GATLING",
	[WPT_DUALIES] = "DUALIE",
	[WPT_BRELLA]  = "BRELLA",
	[WPT_BLASTER] = "BLASTER",
	[WPT_BRUSH]   = "BRUSH",
	[WPT_BOW]     = "BOW",
	[WPT_KATANA]  = "KATANA",
}

addHook("HUD",function(v,p,cam)
	if p.paint == nil then return end
	if not Paint:playerIsActive(p) then return end
	local pt = p.paint
	local inv = pt.inventory
	
	local subscale = FU/8
	local x = ((160 - ((6 + 2)*inv.slots)/2) + 4)*FU
	local y = (200 - 6)*FU
	local flags = V_SNAPTOBOTTOM
	
	if p.jointime <= 20*TR
		local btwpn = input.gameControlToKeyNum(GC_WEPSLOT1)
		local btstr = "unbound"
		if btwpn
			btstr = input.keyNumToName(btwpn)
		end
		v.drawScaled((160 - 65)*FU, 199*FU, FU/2, v.cachePatch("PAINT_KBUT"), flags)
		v.drawString(160 - 65, 193, btstr, flags, "small-thin-center")
		v.drawString(160 - 60, 194, " - Inventory", V_ALLOWLOWERCASE|flags, "small-thin")
	end
	
	local sub_t = Paint.subs[Paint.weapons[pt.weapon_id].subtype or ""]
	if sub_t
		x = $ - (80 * subscale)/2
		v.drawScaled(x,y,subscale, v.cachePatch("PTSUB_BG"), flags)
		v.drawScaled(x,y,FixedDiv(sub_t.icon_scale, FU*4/5), v.cachePatch(sub_t.icon), flags, v.getColormap(nil,0, "AllBlack"))
		x = $ + (80 * subscale)
	end
	
	for i = 1,inv.slots
		v.drawScaled(x,y,FU,
			v.cachePatch("PAINT_BALL"),
			flags|(inv.curslot == i and V_10TRANS or V_50TRANS|V_ADD),
			v.getColormap(TC_BLINK,inv.curslot == i and Paint:getPlayerColor(p) or SKINCOLOR_WHITE)
		)
		if inv.curslot == i
			v.drawScaled(x,y,FU,
				v.cachePatch("PAINT_SELECT"),
				flags|V_10TRANS,
				v.getColormap(TC_BLINK,Paint:getPlayerColor(p))
			)
		end
		if inv.items[i] ~= nil
			v.drawScaled(x,y, FixedDiv(Paint.weapons[inv.items[i]].icon_scale, 3*FU + FU/5),
				v.cachePatch(Paint.weapons[inv.items[i]].icon),
				flags|(inv.curslot ~= i and V_30TRANS or 0),
				inv.curslot ~= i and v.getColormap(TC_BLINK,SKINCOLOR_BLACK,"AllBlack") or nil
			)
		end
		x = $ + (6 + 2)*FU
	end
end,"game")