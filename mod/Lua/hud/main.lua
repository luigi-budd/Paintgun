Paint.HUD = {}
Paint.HUD.memory = {}

local function dofiles(root,files)
	for k, file in ipairs(files)
		dofile("hud/"..root..file)
	end
end
dofiles("drawers/libs/",{
	"srb2edit.lua",
	"splashbg.lua",
})
dofiles("drawers/",{
	"crosshair.lua",
	"hpoverlay.lua",
	"painsurge.lua",
	"killconf.lua",
	"hitmarker.lua",
	"inv.lua",
	"lowink.lua",
	"inktank.lua",
})