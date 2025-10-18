rawset(_G,"Knockback",{})
local KB = Knockback

KB.list = {}
addHook("NetVars",function(n)
	KB.list = n($)
end)
addHook("MapLoad",do
	KB.list = {}
end)

KB.initKnockback = function(mo)
	mo.knockback = {
		list = {},
		thrust = {x=0,y=0},
		wait = 0,
	}
end

KB.addKnockback = function(mo, tics, angle, thrust)
	if not mo.knockback
		KB.initKnockback(mo)
	end
	if mo.knockback.wait then return end
	table.insert(mo.knockback.list, {
		tics = tics,
		angle = angle,
		thrust = thrust,
		frac = (FU / tics),
	})
	mo.knockback.wait = 3
	local wasinlist = false
	for id,othermo in ipairs(KB.list)
		if othermo == mo
			wasinlist = true
			break
		end
	end
	if not wasinlist
		table.insert(KB.list, mo)
	end
end

addHook("ThinkFrame",do
	if gamestate ~= GS_LEVEL then return end
	--clean up
	for k,mo in ipairs(KB.list)
		if not (
			(mo and mo.valid)
			and (mo.health)
			and (mo.knockback ~= nil)
			and (#mo.knockback.list)
		) then
			if (mo and mo.valid and mo.knockback)
				mo.knockback = nil
			end
			table.remove(KB.list,k)
		end
	end
	--iterate
	for k,mo in ipairs(KB.list)
		local thrust = {x = 0,y = 0}
		local knocked = false
		
		local grounded = P_IsObjectOnGround(mo)
		local k = mo.knockback
		for id,t in ipairs(k.list)
			if not t.tics then table.remove(k.list, id); end
		end
		for id,t in ipairs(k.list)
			local force = ease.outcubic(FU - (t.frac * t.tics), t.thrust, 0)
			if grounded
				force = FixedDiv($, mo.friction)
			end
			thrust.x = $ + P_ReturnThrustX(nil,t.angle, force)
			thrust.y = $ + P_ReturnThrustY(nil,t.angle, force)
			t.tics = $ - 1
			if not t.didit
				local frac = FU * 5/6
				mo.momx,mo.momy = FixedMul($1,frac),FixedMul($2,frac)
				t.didit = true
			end
			knocked = true
		end
		local accspeed = FixedDiv(abs(FixedHypot(mo.momx,mo.momy)), mo.scale)
		if knocked
			P_TryMove(mo,
				mo.x + thrust.x,
				mo.y + thrust.y,
				true
			)
			local cap = 25*FU
			if accspeed > cap
				local newspeed = accspeed - FixedDiv(accspeed - cap, 8*FU)
				newspeed = FixedMul($,mo.scale)
				local ang = R_PointToAngle2(0,0,mo.momx,mo.momy)
				mo.momx = P_ReturnThrustX(nil,ang,newspeed)
				mo.momy = P_ReturnThrustY(nil,ang,newspeed)
			end
		end
		
		k.wait = max($-1, 0)
	end
end)	