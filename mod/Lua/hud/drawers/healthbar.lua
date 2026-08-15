local HUD = Paint.HUD
local CV = Paint.CV

local wasactive = false

local widths = {
	["SPT2FONT_0"] = 38*FU,
	["SPT2FONT_1"] = 28*FU,
	["SPT2FONT_2"] = 39*FU,
	["SPT2FONT_3"] = 40*FU,
	["SPT2FONT_4"] = 40*FU,
	["SPT2FONT_5"] = 35*FU,
	["SPT2FONT_6"] = 38*FU,
	["SPT2FONT_7"] = 36*FU,
	["SPT2FONT_8"] = 38*FU,
	["SPT2FONT_9"] = 38*FU,
	["SPT2FONT_PERC"] = 57*FU,
	["SPT2FONT_BAR"] = 14*FU,
}
local FONT_SCALE = FixedDiv(6*FU, 74*FU)
local function drawFontString(v, x,y, str, flags, scalemul)
	local font = "SPT2FONT_"
	local scale = FixedMul(FONT_SCALE, scalemul or FU)
	
	local wid = 0
	for i = 1,str:len()
		local char = str:sub(i,i)
		if char == " " then wid = $ + 2*FU; continue; end
		
		if char == "%" then char = "PERC"; wid = $ + FU;
		elseif char == "|" then char = "BAR"; end
		
		local img = font .. char
		wid = $ + FixedMul(widths[img], scale) + FU
	end
	x = $ - wid
	
	for j = 1,0, -1
		local myx = x
		for i = 1,str:len()
			local char = str:sub(i,i)
			if char == " " then myx = $ + 2*FU; continue; end
			
			if char == "%" then char = "PERC"; myx = $ + FU;
			elseif char == "|" then char = "BAR"; end
			
			local img = font .. char
			local real_img = img .. (j and "O" or "")
			local pat = v.cachePatch(real_img)
			
			v.drawScaled(myx,y, scale, pat, flags)
			
			myx = $ + FixedMul(widths[img], scale) + FU
		end
	end
end

-- not the health bars from v11 unfortunately...
-- just the healthbar from raiders
addHook("HUD",function(v,p,cam)
	if not CV.healthbar.value
		if wasactive then hud.enable("lives") end
		return
	end
	wasactive = true
	
	local me = p.mo
	if not (me and me.valid) then return end
	if not Paint:playerIsActive(p) then return end
	local pt = p.paint
	
	hud.disable("lives")
	
	local danger = pt.brokenarmor
	
	local flags = V_SNAPTOBOTTOM|V_SNAPTOLEFT
	local x = 10*FU
	local y = (200 - 20)*FU
	local clrmp
	if danger
		clrmp = v.getColormap(TC_DEFAULT, SKINCOLOR_CARBON)
	else
		clrmp = v.getColormap(TC_DEFAULT, SKINCOLOR_SEAFOAM)
	end
	
	local maxwidth = 90*FU
	local hp = pt.hp
	if (p.playerstate == PST_DEAD) then hp = 0; end
	
	local hpprogress = FixedDiv(hp, 100*FU)
	if danger
		hpprogress = FU - FixedDiv(pt.armorregen, 100*FU)
	end
	
	local width = FixedMul(maxwidth, hpprogress)
	local height = 10*FU
	
	v.drawFill(x/FU,(y/FU)+1, maxwidth/FU, (height/FU)-2, 17|V_REVERSESUBTRACT|flags)
	v.drawFill((x/FU)+1,(y/FU), (maxwidth/FU) - 2, 1, 17|V_REVERSESUBTRACT|flags)
	v.drawFill((x/FU)+1,(y/FU)+(height/FU)-1, (maxwidth/FU) - 2, 1, 17|V_REVERSESUBTRACT|flags)
	
	local ox = (leveltime*FU)/8
	local oy = (leveltime*FU)/8
	for i = 0,9
		local xoff = (i == 0 or i == 9) and FU or 0
		local woff = xoff and 2*FU or 0
		
		local sinoff = abs(sin(FixedAngle((leveltime+i*4)*FU*4)))/2
		HUD.drawSplashBG(v, x+xoff, y + i*FU, 
			ox+xoff,oy + i*FU,
			clamp(0, width + sinoff - xoff, maxwidth - woff),
			FU, flags, clrmp, true
		)
	end
	
	if danger
		v.drawString(x + maxwidth - 4*FU, y + FU,
			"Danger!", V_ALLOWLOWERCASE|V_ORANGEMAP|flags,
			"thin-fixed-right"
		)
	else
		drawFontString(v,
			x + maxwidth - 4*FU, y + FU,
			string.format("%d | %d", hp/FU, 100), flags, FU
		)
	end
end,"game")