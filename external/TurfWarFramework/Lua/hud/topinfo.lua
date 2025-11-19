local cv_respawndelay
local SLIDEIN = TR/2
local ANIM = 5

local function drawTeam(v,p, y)
	if not G_GametypeHasTeams() then return end
	y = $ or 10
	
	-- "top" info
	v.drawString(6, 200 - y, (p.ctfteam == 1) and "RED Team" or "BLUE Team",
		V_SNAPTOBOTTOM|V_SNAPTOLEFT|V_ALLOWLOWERCASE|skincolors[Paint:getPlayerColor(p)].chatcolor,
		"thin"
	)
end
addHook("HUD",function(v,p)
	if not (TurfWar and Paint) then return end
	if not Paint:isMode() then return end
	if (p.spectator) then return end
	
	v.dointerp = function(tag)
		if v.interpolate == nil then return end
		v.interpolate(tag)
	end
	
	if not cv_respawndelay
		cv_respawndelay = CV_FindVar("respawndelay")
	end
	
	v.drawString(320 - 6, 6, (p.score).."p", V_SNAPTOTOP|V_SNAPTORIGHT|V_ALLOWLOWERCASE, "thin-right")
	
	/*
		in splatoon 3...
		...dying waits 6 seconds before teleporting you back to the respawner...
		...before waiting an additional 2 seconds before being able to launch...
		...without any respawn saver
		
		SLIDEIN should be 3 seconds according to this, but respawn
		delay is usually 3 seconds also, so making it .5 seconds
		just makes sense
	*/
	if not (gametyperules & GTR_RESPAWNDELAY) then return drawTeam(v,p); end
	if not (cv_respawndelay.value) then return drawTeam(v,p); end
	if (p.playerstate ~= PST_DEAD) then return drawTeam(v,p); end
	if (p.deadtimer < SLIDEIN) then return drawTeam(v,p); end
	
	local timer = (p.deadtimer - SLIDEIN) + 1
	local y = (200 - 12) - 4
	local x = 0
	local moveup = 16
	if timer < ANIM
		local frac = (FU/ANIM) * (timer)
		x = ease.outquad(frac, -160*FU, 0)/FU
		moveup = ease.outquad(frac, 0, $*FU)/FU
	end
	
	local delay = (cv_respawndelay.value*TR) - SLIDEIN
	local deadtimer = p.deadtimer - SLIDEIN
	local str = ("Respawn in %.2d..."):format((delay - deadtimer)/TR + 1)
	if (delay - deadtimer) < 0
		str = "Respawn ready!"
	end
	
	v.dointerp(300)
	
	for i = 0,11
		v.drawFill(x,y+i, 98 - i, 1, 29|V_SNAPTOBOTTOM|V_SNAPTOLEFT)
	end
	local repatch = v.cachePatch("PT_RESPAWN")
	local progress = min(FixedDiv(deadtimer*FU, delay*FU), FU)
	v.drawCropped(x*FU,y*FU, FU, FU,
		repatch, V_SNAPTOBOTTOM|V_SNAPTOLEFT, nil,
		0,0, FixedMul(repatch.width*FU, progress), repatch.height*FU
	)
	v.drawString(x + 6, y + 2,
		str,
		V_SNAPTOBOTTOM|V_SNAPTOLEFT|V_ALLOWLOWERCASE,
		"thin"
	)
	drawTeam(v,p, 10 + moveup)
	v.dointerp(false)
end)