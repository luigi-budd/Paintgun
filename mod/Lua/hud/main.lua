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

local numdrawers = 0
local drawers = {}
dofiles = function(root,files)
	for k, file in ipairs(files)
		--print("\x83PAINTGUN\x80: adding HUD file "..("hud/"..root..file))
		local info = dofile("hud/"..root..file)
		info = $ or {}
		info.path = "hud/"..root..file
		
		numdrawers = $ + 1
		drawers[numdrawers] = info
	end
end

dofiles("drawers/",{
	"signals.lua",
	"nametags.lua",
	"inktank.lua",
	"hpoverlay.lua",
	"painsurge.lua",
	"healthbar.lua",
	"crosshair.lua",
	"hitmarker.lua",
	"lowink.lua",
	"killconf.lua",
	"inv.lua",
	"damagenumbers.lua",
	"wipeout.lua",
	
	"cameralag.lua",
	"musicvolume.lua",
})

addHook("HUD", function(v,p,c)
	if not numdrawers then return end
	if p.paint == nil then return end
	local pt = p.paint
	
	local active = Paint:playerIsActive(p)
	
	for i = 1, numdrawers
		local info = drawers[i]
		
		if (active == false and not info.allowinactive)
			continue
		end
		
		if info.func ~= nil and (info.type == "game" or info.type == nil)
			info.func(v,p,c)
		end
	end
end,"game")