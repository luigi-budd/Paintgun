-- credits: @kirberburgy2 for making thsi for me Lol!!

local Vec3 = {}
Vec3.__index = Vec3

registerMetatable(Vec3)

function Vec3.Add(v1, v2) 
    return Vec3.New(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z)
end

function Vec3.Sub(v1, v2) 
    return Vec3.New(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z)
end

function Vec3.Mul(v1, x2) 
    if type(x2) == "number" then
        return Vec3.New(FixedMul(v1.x, x2), FixedMul(v1.y, x2), FixedMul(v1.z, x2))
    end
    
    return Vec3.New(FixedMul(v1.x, x2.x), FixedMul(v1.y, x2.y), FixedMul(v1.z, x2.z))
end

function Vec3.Div(v1, x2) 
    if type(x2) == "number" then
        return Vec3.New(FixedDiv(v1.x, x2), FixedDiv(v1.y, x2), FixedDiv(v1.z, x2))
    end
    
    return Vec3.New(FixedDiv(v1.x, x2.x), FixedDiv(v1.y, x2.y), FixedDiv(v1.z, x2.z))
end

function Vec3.Dot(v1, v2) 
    return FixedMul(v1.x, v2.x) + FixedMul(v1.y, v2.y) + FixedMul(v1.z, v2.z)
end

function Vec3.Cross(v1, v2)
    return Vec3.New(
        FixedMul(v1.y, v2.z) - FixedMul(v1.z, v2.y),
        FixedMul(v1.z, v2.x) - FixedMul(v1.x, v2.z),
        FixedMul(v1.x, v2.y) - FixedMul(v1.y, v2.x)
    )
end

function Vec3.Neg(v) 
    return Vec3.New(-v.x, -v.y, -v.z)
end

function Vec3.Len(v) 
    return FixedSqrt(v:Dot(v))
end

function Vec3.Normalize(v) 
    local l = v:Len()
    
    if l == 0 then
        return v
    end
    
    return v:Div(l)
end

function Vec3.New(x, y, z) 
    return setmetatable({
        ["x"] = x,
        ["y"] = y,
        ["z"] = z,
    }, Vec3)
end

-- in here because yknow
function Vec3.SphereToCartesian(a,b)
    return Vec3.New(
        FixedMul(cos(a), cos(b)),
        FixedMul(sin(a), cos(b)),
        sin(b)
    )	
end

local Quaternion = {}
Quaternion.__index = Quaternion

registerMetatable(Quaternion)

function Quaternion.Conjugate(q)
    return Quaternion.New2(
        q.w,
        q.xyz:Neg()
    )
end

function Quaternion.Add(q1, q2)
    return Quaternion.New2(q1.w + q2.w, q1.xyz:Add(q2.xyz))
end

function Quaternion.Sub(q1, q2)
    return Quaternion.New2(q1.w - q2.w, q1.xyz:Sub(q2.xyz))
end

function Quaternion.Mul(q1, q2)
    return Quaternion.New2(
        FixedMul(q1.w, q2.w) - q1.xyz:Dot(q2.xyz),
        q2.xyz:Mul(q1.w):Add(q1.xyz:Mul(q2.w):Add(q1.xyz:Cross(q2.xyz)))
    )
end

function Quaternion.Inv(q)
    local denom = FixedMul(q.w, q.w) + q.xyz:Dot(q.xyz)
    
    return Quaternion.New(FixedDiv(q.w, denom), q.xyz:Neg():Div(denom))
end

function Quaternion.Div(q1, q2)
    return q1:Inv():Mul(q2)
end

function Quaternion.Rotate(q, v)
    local qv = Quaternion.New2(0, v)
    local rotated = q:Mul(qv):Mul(q:Conjugate())
    return rotated.xyz
end

function Quaternion.New(w, x, y, z)
    return setmetatable({
        ["w"] = w,
        xyz = Vec3.New(x, y, z)
    }, Quaternion)
end

function Quaternion.New2(w, v)
    return setmetatable({
        ["w"] = w,
        xyz = v
    }, Quaternion)
end

function Quaternion.AxisAngle(v, t)
    local t2 = t/2
    
    return Quaternion.New2(cos(t2), v:Normalize():Mul(sin(t2)))
end

-- P = paint
rawset(_G, "P_Vec3", Vec3)
rawset(_G, "P_Quat", Quaternion)