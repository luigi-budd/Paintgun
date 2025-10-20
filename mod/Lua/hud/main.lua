Paint.HUD = {}
Paint.HUD.memory = {}

local function dofiles(files)
	for k, file in ipairs(files)
		dofile("hud/drawers/"..file)
	end
end
dofiles({
	"crosshair.lua",
	"hpoverlay.lua",
	"painsurge.lua",
	"killconf.lua",
	"hitmarker.lua",
	"inv.lua",
	"lowink.lua",
	"inktank.lua",
})