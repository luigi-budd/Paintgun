-- doesnt actually draw anything, but
-- we need it to be local
local HUD = Paint.HUD

local lagtics = 0
local oldangle = 0
local oldaiming = 0

local factor = FU/2
local function camlag()
	camera.momx = FixedMul($, factor)
	camera.momy = FixedMul($, factor)
	camera.momz = FixedMul($, factor)	
end

function HUD:cameraLag(p, tics)
	if p ~= displayplayer then return end
	
	lagtics = tics
	oldangle = camera.angle
	oldaiming = camera.aiming
	
	camlag()
	camera.angle = oldangle
	camera.aiming = oldaiming
end

addHook("ThinkFrame",do
	if not lagtics then return end
	
	camlag()
	camera.angle = oldangle
	camera.aiming = oldaiming
	lagtics = $ - 1
end)