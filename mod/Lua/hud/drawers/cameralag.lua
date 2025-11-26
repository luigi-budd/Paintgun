-- doesnt actually draw anything, but
-- we need it to be local
local HUD = Paint.HUD

local lagtics = 0
local oldangle = 0

function HUD:cameraLag(p, tics)
	if p ~= displayplayer then return end
	
	lagtics = tics
	oldangle = camera.angle
	
	camera.momx, camera.momy, camera.momz = 0,0,0
	camera.angle = oldangle
end

addHook("ThinkFrame",do
	if not lagtics then return end
	
	camera.momx, camera.momy, camera.momz = 0,0,0
	camera.angle = oldangle
	lagtics = $ - 1
end)