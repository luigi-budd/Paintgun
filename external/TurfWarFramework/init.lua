/* Basic framework for Splatoon modes, to be used with Paintgun (load Paintgun first)*/

local folder = ""
local function dofolder(files)
	for k, file in ipairs(files)
		dofile(folder..file)
	end
end

folder = ""
dofolder{
	"main.lua"
}
folder = "hud/"
dofolder{
	"oneminute.lua",
	"topinfo.lua",
	"scores.lua",
	"gameset.lua",
	"timer.lua",
	"gamestate_text.lua",
	--"countdown.lua",
}