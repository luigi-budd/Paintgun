local HUD = Paint.HUD
local MAXTICS = TR
local tics = 0

function HUD:lowInkWarning(p, cooldown)
	if displayplayer ~= p then return end
	if not tics
		S_StartSound(nil, sfx_pt_noi, p)
	end
	tics = max(MAXTICS, (cooldown or 0) + 1)
end

addHook("HUD",function(v,p,cam)
	local me = p.mo
	if not (me and me.valid) then return end
	if not Paint:playerIsActive(p) then return end
	local pt = p.paint
	
	if tics
		v.drawString(160, 160, "Low ink!", V_ALLOWLOWERCASE|V_SNAPTOBOTTOM, "thin-center")
		
		if not paused
			tics = $ - 1
		end
	end
end,"game")