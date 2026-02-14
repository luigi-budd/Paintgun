-- doesnt actually draw anything, but
-- we need it to be local
local HUD = Paint.HUD

local BASE_TOVOL = 100
local BASE_TOFRAC = FU*2

local i_tovol = BASE_TOVOL
local i_tofrac = BASE_TOFRAC
local i_vol = BASE_TOVOL*FU

function HUD:musicLerp(p, tovol, tofrac)
	if p ~= displayplayer then return end
	tofrac = $ or BASE_TOFRAC
	
	i_tovol = min($, tovol)
	i_tofrac = min($, tofrac)
end

addHook("ThinkFrame",do
	local tovol = i_tovol*FU
	if i_vol > tovol
		i_vol = max($ - i_tofrac, tovol)
	elseif i_vol < tovol
		i_vol = min($ + i_tofrac, tovol)
	else
		i_vol = tovol
	end
	
	if (consoleplayer and consoleplayer.valid)
		S_SetInternalMusicVolume(i_vol/FU, consoleplayer)
	end
	i_tovol = BASE_TOVOL
	i_tofrac = BASE_TOFRAC
end)