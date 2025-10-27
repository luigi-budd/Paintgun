dofile("lib/quaternion.lua")

rawset(_G,"SphereToCartesian",function(alpha, beta)
    local t = {}

    t.x = FixedMul(cos(alpha), cos(beta))
    t.y = FixedMul(sin(alpha), cos(beta))
    t.z = sin(beta)
    --t.z = FixedMul(sin(alpha), sin(beta)) -- for elliptical orbit

    return t
end)

local function sign(a) return (a ~= 0) and (a < 0 and -1 or 1) or 0 end
rawset(_G,"sign",sign)

rawset(_G,"clamp",function(minimum,value,maximum)
	if maximum < minimum
		local temp = minimum
		minimum = maximum
		maximum = temp
	end
	return max(minimum,min(maximum,value))
end)

rawset(_G,"P_RandomFixedSigned",do
	return P_RandomFixed() * sign(P_SignedRandom())
end)
rawset(_G,"P_RandomFixedRange",function(a,b)
	return P_RandomRange(a,b)*FU + P_RandomFixedSigned()
end)

rawset(_G,"R_PointTo3DAngles",function(x1,y1,z1, x2,y2,z2)
	return R_PointToAngle2(x1,y1,x2,y2), R_PointToAngle2(
		0,z1,
		R_PointToDist2(x1,y1,x2,y2), z2
	)
end)
rawset(_G,"R_PointTo3DDist",function(x1,y1,z1, x2,y2,z2)
	return FixedHypot(FixedHypot(x2 - x1, y2 - y1), z2 - z1)
end)

rawset(_G,"P_3DThrust",function(mo, h_ang, v_ang, speed)
	local t = SphereToCartesian(h_ang,v_ang)
	mo.momx = $ + FixedMul(speed, t.x)
	mo.momy = $ + FixedMul(speed, t.y)
	mo.momz = $ + FixedMul(speed, t.z)
end)

rawset(_G,"P_3DInstaThrust",function(mo, h_ang, v_ang, speed)
	local t = SphereToCartesian(h_ang,v_ang)
	mo.momx = FixedMul(speed, t.x)
	mo.momy = FixedMul(speed, t.y)
	mo.momz = FixedMul(speed, t.z)
end)

rawset(_G,"P_AngleLerp",function(frac, from, to)
	return from + FixedMul(to - from, frac)
end)

rawset(_G,"L_ZCollide",function(mo1,mo2)
	if mo1.z > mo2.height+mo2.z then return false end
	if mo2.z > mo1.height+mo1.z then return false end
	return true
end)

dofile("lib/w2s.lua")
dofile("lib/soap.lua")
dofile("lib/knockback.lua")