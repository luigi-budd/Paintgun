local ML = MenuLib

local luasig = "iAmLua"..P_RandomFixed()
addHook("NetVars",function(n) luasig = n($); end)
COM_AddCommand("_paint_setinv", function(p, sig, item1, item2, item3)
	if sig ~= luasig then return end
	local pt = p.paint
	if not pt then return end
	local inv = pt.inventory
	
	inv.items[1] = item1
	inv.items[2] = item2
	inv.items[3] = item3
end)

local CLASS2BIT = {
	[WPT_SHOOTER] = 1<<0,
	[WPT_ROLLER]  = 1<<1,
	[WPT_CHARGER] = 1<<2,
	[WPT_SLOSHER] = 1<<3,
	[WPT_GATLING] = 1<<4,
	[WPT_DUALIES] = 1<<5,
	[WPT_BRELLA]  = 1<<6,
	[WPT_BLASTER] = 1<<7,
	[WPT_BRUSH]   = 1<<8,
	[WPT_BOW]     = 1<<9,
	[WPT_KATANA]  = 1<<10,
}
local CLASS2ICON = {
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

ML.addMenu({
	stringId = "Paint_WeaponPicker",
	title = "Inventory",
	
	color = 27,
	outline = 30,
	width = 170,
	height = 160,
	x = 5,
	y = 10,
	ps_flags = PS_DRAWTITLE|PS_NOSLIDEIN,
	filter = 0,
	
	curslot = 1,
	workinv = {},
	
	drawer = function(v, ML, menu, props)
		local x = props.corner_x + 6
		local y = props.corner_y + 16
		v.drawString(x,y + 2,"Filter:", V_ALLOWLOWERCASE, "thin")
		
		local ix = (x + 46)*FU
		local iy = (y +  4)*FU
		for wpt = WPT_SHOOTER, WPT_KATANA
			local wy = iy + ((wpt % 2 == 0) and 2*FU or 0)
			
			local trans = V_80TRANS
			local clr = SKINCOLOR_BONE
			local hovered = false
			if ML.mouseInZone(ix - 3*FU,wy - 3*FU, 6*FU,6*FU, true)
				hovered = true
				ML.client.canPressSomething = true
				if (ML.client.mouseHeld == 1)
					menu.filter = $^^CLASS2BIT[wpt]
				end
			end
			if hovered
			or (menu.filter & CLASS2BIT[wpt])
				trans = V_40TRANS
				if (menu.filter & CLASS2BIT[wpt])
					trans = 0
					clr = SKINCOLOR_YELLOW
				end
			end
			
			v.drawScaled(ix,wy,FU,
				v.cachePatch("PAINT_BALL"),
				trans,
				v.getColormap(TC_DEFAULT,clr)
			)
			v.drawScaled(ix, wy,
				FU/16,
				v.cachePatch("PTCLASS_"..CLASS2ICON[wpt]),
				0
			)
			
			ix = $ + 8*FU
		end
		v.drawString(ix + 4*FU,(y + 2)*FU,"x", V_ALLOWLOWERCASE, "thin-fixed-center")
		if ML.mouseInZone(ix, (y + 2)*FU, 6*FU,6*FU, true)
			ML.client.canPressSomething = true
			if (ML.client.mouseHeld == 1)
				menu.filter = 0
			end
		end
		
		y = ($ + 14)
		local startx = x
		
		local count = 0
		local dimen = 30
		local pad = 2
		ML.interpolate(v, false)
		
		local hoveringname = ""
		
		local inv = menu.workinv
		local curitems = {}
		for i = 1, inv.slots
			curitems[inv.items[i]] = true
		end
		
		for name, info in pairs(Paint.weapons)
			if (menu.filter ~= 0)
			and (menu.filter & CLASS2BIT[info.guntype] == 0)
				continue
			end
			
			if count == 5
				count = 0
				x = startx
				y = $ + (dimen + pad)
			end
			count = $ + 1
			
			local itrans = 0
			local clr = 24
			if curitems[info.name]
				clr = 26
				itrans = V_30TRANS
			end
			if inv.items[menu.curslot] == info.name
				clr = 18
				itrans = 0
			end
			
			v.drawFill(x, y, dimen,dimen, clr)
			
			v.drawScaled((x + dimen/2)*FU, (y + dimen/2)*FU,
				FU/10,
				v.cachePatch(info.icon),
				itrans
			)
			v.drawScaled((x + 4)*FU, (y + 4)*FU,
				FU/16,
				v.cachePatch("PTCLASS_"..CLASS2ICON[info.guntype]),
				itrans
			)
			local sub_t = Paint.subs[info.subtype or ""]
			if sub_t
				v.drawScaled((x + (dimen - 4))*FU, (y + 4)*FU,
					FU/10,
					v.cachePatch(sub_t.icon),
					itrans, v.getColormap(TC_DEFAULT, SKINCOLOR_PURPLE)
				)
			end
			
			if ML.mouseInZone(x*FU,y*FU, dimen*FU,dimen*FU, true)
				hoveringname = info.realname
				
				ML.client.canPressSomething = true
				if (ML.client.mouseHeld == 1)
					inv.items[menu.curslot] = info.name
				end
			end
			
			x = $ + (dimen + pad)
		end
		
		x = (props.corner_x + menu.width/2) - ((dimen * inv.slots) + (pad * inv.slots - 1))/2
		y = (props.corner_y + menu.height) - (dimen + pad*2)
		for i = 1, inv.slots
			local item = inv.items[i]
			local wep = Paint.weapons[item or ""]
			
			if i == menu.curslot
				v.drawFill(x -1, y - 1, dimen+2,dimen+2, 73)
			end
			v.drawFill(x, y, dimen,dimen, 24)
			
			if wep
				v.drawScaled((x + dimen/2)*FU, (y + dimen/2)*FU,
					FU/10,
					v.cachePatch(wep.icon),
					0
				)
				v.drawScaled((x + 4)*FU, (y + 4)*FU,
					FU/16,
					v.cachePatch("PTCLASS_"..CLASS2ICON[wep.guntype]),
					0
				)
				local sub_t = Paint.subs[wep.subtype or ""]
				if sub_t
					v.drawScaled((x + (dimen - 4))*FU, (y + 4)*FU,
						FU/10,
						v.cachePatch(sub_t.icon),
						0, v.getColormap(TC_DEFAULT, SKINCOLOR_PURPLE)
					)
				end
				
				if ML.mouseInZone(x*FU,y*FU, dimen*FU,dimen*FU, true)
					hoveringname = wep.realname
					
					ML.client.canPressSomething = true
					if (ML.client.mouseHeld == 1)
						menu.curslot = i
					end
				end
			end
			
			x = $ + (dimen + pad)
		end
		
		if hoveringname ~= ""
			local x = (ML.client.mouse_x / FU) + 4
			local y = (ML.client.mouse_y / FU) + 4
			local wid = (v.stringWidth(hoveringname, 0, "thin")/2) + 4
			ML.interpolate(v, 100000)
			v.drawFill(x,y, wid, 8, 29)
			v.drawFill(x+1,y+1, wid-2, 6, 27)
			v.drawString(x+2,y+2, hoveringname, V_ALLOWLOWERCASE, "small-thin")
		end
	end,
	init = function()
		ML.client.mouse_x = 85*FU
		ML.client.mouse_y = 130*FU
		
		local p = consoleplayer
		local pt = p.paint
		local inv = pt.inventory
		local menu = ML.menus[ML.findMenu("Paint_WeaponPicker")]
		menu.workinv = {items = {}, slots = inv.slots}
		for i = 1, inv.slots
			menu.workinv.items[i] = inv.items[i]
		end
	end,
	exit = function()
		local p = consoleplayer
		local menu = ML.menus[ML.findMenu("Paint_WeaponPicker")]
		local minv = menu.workinv
		
		COM_BufInsertText(p, ("_paint_setinv %s %s %s %s"):format(
			luasig,
			minv.items[1], minv.items[2], minv.items[3]
		))
	end
})

addHook("KeyDown", function(key)
	if isdedicatedserver then return end
	if key.repeated then return end
	if gamestate ~= GS_LEVEL then return end
	-- this is what ChatGPT told me to do
	if chatactive then return end
	--if ML.client.currentMenu.id ~= -1 then return end
	if (#ML.client.popups) then return end
	
	local wp5_f, wp5_s = input.gameControlToKeyNum(GC_WEPSLOT1)
	
	if (key.num == wp5_f)
	or (key.num == wp5_s)
		ML.initPopup(ML.findMenu("Paint_WeaponPicker"))
	end
end)
