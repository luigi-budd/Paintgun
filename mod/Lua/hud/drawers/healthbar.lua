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
local SLIDEIN = TR/2
local ANIM = 5
local cv_respawndelay
addHook("HUD",function(v,p,cam)
	if not CV.healthbar.value
		if wasactive then hud.enable("lives") end
		return
	end
	wasactive = true
	if not cv_respawndelay
		cv_respawndelay = CV_FindVar("respawndelay")
	end
	
	local me = p.mo
	if not (me and me.valid) then return end
	if not Paint:playerIsActive(p) then return end
	if p.spectator then return end
	local pt = p.paint
	
	hud.disable("lives")
	
	local danger = pt.brokenarmor
	
	local flags = V_SNAPTOBOTTOM|V_SNAPTOLEFT
	local x = 6*FU
	local y = (200 - 22)*FU
	if TurfWar ~= nil
		local canmoveit = true
		if not (gametyperules & GTR_RESPAWNDELAY) then canmoveit = false; end
		if not (cv_respawndelay.value) then canmoveit = false; end
		if (p.playerstate ~= PST_DEAD) then canmoveit = false; end
		if (p.deadtimer < SLIDEIN) then canmoveit = false; end
		
		if canmoveit
			local timer = (p.deadtimer - SLIDEIN) + 1
			if timer < ANIM
				local frac = (FU/ANIM) * (timer)
				x = ease.inquad(frac, $, -160*FU)
				y = ease.inquad(frac, $, $ - 16*FU)
			else
				x = -160*FU
				y = $ - 16*FU
			end
			v.dointerp(true)
		end
	end
	
	local clrmp
	if danger
		clrmp = v.getColormap(TC_DEFAULT, SKINCOLOR_CARBON)
	else
		local clr = SKINCOLOR_SEAFOAM
		if (gametyperules & GTR_TEAMS)
			if p.ctfteam == 1
				clr = skincolor_redteam
			else
				clr = skincolor_blueteam
			end
		end
		if (p.pflags & PF_TAGIT)
			clr = SKINCOLOR_TOPAZ
		end
		
		clrmp = v.getColormap(TC_DEFAULT, clr)
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
	
	v.drawScaled(x,y, FU, v.cachePatch("PAINT_HEALTHBG"), V_REVERSESUBTRACT|flags)
	
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
	
	if (p.pflags & PF_TAGIT)
		v.drawString(x, y + 12*FU, "IT!",
			flags|V_ALLOWLOWERCASE,
			"thin-fixed"
		)
	end
	
	v.dointerp(false)
end,"game")