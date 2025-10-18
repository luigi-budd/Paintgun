local HUD = Paint.HUD

local CLASStoICON = {
	[WPT_SHOOTER] = "SHOOTER",
	[WPT_CHARGER] = "CHARGER",
	[WPT_BLASTER] = "BLASTER",
	[WPT_DUALIES] = "DUALIE",
}

addHook("HUD",function(v,p,cam)
	if p.paint == nil then return end
	if not Paint:playerIsActive(p) then return end
	local pt = p.paint
	local inv = pt.inventory
	
	local x = ((160 - ((6 + 2)*inv.slots)/2) + 4)*FU
	local y = (200 - 10)*FU
	local flags = V_SNAPTOBOTTOM
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
			v.drawScaled(x,y,FU/16,
				v.cachePatch("PTCLASS_"..CLASStoICON[ Paint.weapons[inv.items[i]].guntype] ),
				flags|(inv.curslot ~= i and V_30TRANS or 0),
				inv.curslot ~= i and v.getColormap(TC_BLINK,SKINCOLOR_BLACK,"AllBlack") or nil
			)
		end
		x = $ + (6 + 2)*FU
	end
end,"game")