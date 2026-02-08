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
	"signals.lua",
	"nametags.lua",
	"inktank.lua",
	"hpoverlay.lua",
	"painsurge.lua",
	"crosshair.lua",
	"hitmarker.lua",
	"lowink.lua",
	"killconf.lua",
	"inv.lua",
	"damagenumbers.lua",
	"wipeout.lua",
	
	"cameralag.lua",
})