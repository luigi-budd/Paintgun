local function drawflashing(v, x,y, width, flags)
	local fade_sin = abs(sin(leveltime * 4 * ANG2))
	local fade = FixedMul(11*FU, fade_sin)/FU
	if (fade >= 10) then return end
	
	for i = 0,11
		v.drawFill(x,y+i, width - (i/2), 1, 54|flags|(fade<<V_ALPHASHIFT))
	end
end

local ANIM = 14

local stars = {}
local starid = 0
local function addstar(x,y, scale, tics)
	table.insert(stars, {
		x = x,
		y = y,
		scale = scale,
		maxtics = tics,
		tics = tics,
		rot = -ANGLE_22h,
		id = starid
	})
	starid = $ + 1
end

local flyingstars = {}
local flyingid = 0
local function addflyingstar(x,y, scale, tics, thrust, rot, sign)
	table.insert(flyingstars, {
		x = x,
		y = y,
		scale = scale,
		maxtics = tics,
		tics = tics,
		rot = rot,
		id = flyingid,
		thrust = thrust,
		sign = sign,
	})
	flyingid = $ + 1
end

local quotaanim = 0
function Paint.HUD:quotaLight()
	quotaanim = ANIM
	
	for i = 0, 35
		addflyingstar(
			0, 20*FU + (12 * P_RandomFixed()),
			((FU/4)/2 + FixedMul(FU/4, P_RandomFixed()))/2,
			TR + P_RandomRange(0, TR/2),
			10*FU + (40 * P_RandomFixed()),
			FixedAngle(P_RandomRange(0,360)*FU),
			P_RandomChance(FU/2) and 1 or -1
		)
	end
end

addHook("HUD",function(v,p)
	if (gametype ~= GT_SALMONRUN) then return end
	
	v.dointerp = function(tag)
		if v.interpolate == nil then return end
		v.interpolate(tag)
	end
	
	local rs = Salmon.roundstatus
	local x = 0
	local y = 20
	local flags = V_SNAPTOLEFT|V_SNAPTOTOP
	
	local timer = p.realtime
	if (rs.intermission)
	or (timer == 0 and not (rs.postround))
		timer = Salmon.const.ROUND_TIME - TR
	end
	if (rs.postgame)
		timer = 0
	end
	timer = max($, 0)
	
	local quotamet = rs.eggsin >= rs.quota
	v.drawString(x + 20, y - 10, "Wave "..rs.wavenumber, flags|V_ALLOWLOWERCASE, "thin-center")
	v.drawString(x + 64, y - 10, quotamet and "Quota met!" or "Quota", flags|V_ALLOWLOWERCASE|(quotamet and V_YELLOWMAP or 0), "thin-center")
	for i = 0,11
		v.drawFill(x,y+i, 90 - (i/2), 1, 29|flags)
	end
	if (timer <= 30*TR and not quotamet)
		drawflashing(v, x,y, 90, flags)
	end
	
	v.drawString(x + 20, y + 2, (timer) and (timer/TR)+1 or 0,
		flags|V_ALLOWLOWERCASE|((timer > 0 and timer <= 30*TR) and V_YELLOWMAP or 0),
		"thin-center"
	)
	
	v.drawScaled((x + 45)*FU, (y + 10)*FU, FU/4, v.cachePatch("TOKEA0"), flags)
	v.drawString(x + 64, y + 2, rs.eggsin.."/"..rs.quota,
		flags|V_ALLOWLOWERCASE,
		"thin-center"
	)
	
	if quotamet
		local c_x = (x + 64)*FU
		local c_y = (y + 6)*FU
		local w = 25*FU
		local h = 8*FU
		local wp = 10*FU -- pad
		local hp = 3*FU
		
		local a = FixedAngle(v.RandomRange(0,360)*FU)
		addstar(
			c_x + P_ReturnThrustX(nil, a, w) + P_ReturnThrustX(nil, a, FixedMul(wp, v.RandomFixed())),
			c_y + P_ReturnThrustY(nil, a, h) + P_ReturnThrustY(nil, a, FixedMul(hp, v.RandomFixed())),
			(FU/4)/2 + FixedMul(FU/4, v.RandomFixed()),
			10
		)
	end
	
	y = $ + 16
	local count = Salmon.countPlayers()
	for i = 0,11
		v.drawFill(x,y+i, 52 - (i/2), 1, 29|flags)
	end
	local str = count.alive
	if (count.dead)
		drawflashing(v, x,y, 52, flags)
		str = $ .. "\x85 (-"..count.dead..")"
	end
	v.drawString(x + 10, y + 2, str,
		flags|V_ALLOWLOWERCASE,
		"thin"
	)
	
	y = $ + 16
	if (rs.bossalert)
		local width = 90
		local x = 0
		if (Salmon.const.BOSS_ALERT - rs.bossalert < 6)
			local frac = (FU/6) * (Salmon.const.BOSS_ALERT - rs.bossalert)
			x = ease.outback(frac, -width*FU, 0, FU)/FU
		end
		if rs.bossalert <= 10
			local frac = (FU/10) * (10 - rs.bossalert)
			x = ease.inquad(frac, 0, -width*FU)/FU
		end
		
		v.dointerp(61)
		for i = 0,11
			v.drawFill(x - 5,y+i, (width - (i/2)) + 5, 1, 29|flags)
		end
		
		v.drawString(x + 10, y + 2,
			"Boss incoming!",
			flags|V_ALLOWLOWERCASE|V_ORANGEMAP,
			"thin"
		)
		v.dointerp(false)
	end
	
	if quotaanim
		local frac = ease.outexpo(FU - ((FU/ANIM)*quotaanim), FU, 0)
		v.dointerp(62)
		v.drawStretched(x, (20 + 6)*FU,
			FixedMul(4*FU, FU - frac), FixedMul(FU/4, frac),
			v.cachePatch("PSR_LIGHT"),
			flags|V_ADD
		)
		v.dointerp(false)
		quotaanim = $ - 1
	end
	
	for k, star in ipairs(stars)
		if (star.tics <= 0)
			table.remove(stars, k); continue
		end
	end
	for k, star in ipairs(stars)
		v.dointerp(star.id)
		local frac = FU
		local half = star.maxtics/2
		if (star.tics >= half)
			frac = ease.insine((FU/half) * (half - (star.tics - half)), 0,FU)
		else
			frac = ease.outsine((FU/half) * (half - star.tics), FU,0)
		end
		v.drawScaled(star.x,star.y, FixedMul(star.scale, frac), v.getSpritePatch(SPR_LFSR, B, 0, star.rot), flags)
		star.tics = $ - 1
	end
	v.dointerp(false)

	for k, star in ipairs(flyingstars)
		if (star.tics <= 0)
			table.remove(flyingstars, k); continue
		end
	end
	for k, star in ipairs(flyingstars)
		v.dointerp(star.id)
		
		local frac = FU
		if star.tics < 10
			frac = ease.insine(FU - ((FU/10) * star.tics), FU, 0)
			if frac < 0 then frac = 0; end
		end
		
		star.x = $ + star.thrust
		star.rot = $ + FixedAngle(star.thrust*10 * star.sign)
		star.thrust = FixedMul($, FU*89/100)
		
		v.drawScaled(star.x,star.y, FixedMul(star.scale, frac), v.getSpritePatch(SPR_LFSR, B, 0, star.rot), flags)
		
		star.tics = $ - 1
	end
	v.dointerp(false)
end)