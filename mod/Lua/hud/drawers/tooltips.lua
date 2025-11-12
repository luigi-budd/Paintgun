local HUD = Paint.HUD
local anim = 10*TR

addHook("HUD",function(v,p,cam)
	if p.paint == nil then return end
	if not Paint:playerIsActive(p) then return end
	if (p.jointime > anim) then return end
	
	local flags = V_ALLOWLOWERCASE|V_SNAPTOLEFT|V_SNAPTOBOTTOM
	local x = 6
	local y = 200 - 100
	if (anim - p.jointime) < TR/2
		local pro = TR/2
		local tics = pro - (anim - p.jointime)
		x = $ - ease.inquad((FU/pro)*tics, 0, 400*FU)/FU
	end
	
	v.drawString(x,y, "[FIRE] - Fire weapon", flags, "thin")
	y = $ - 8
	v.drawString(x,y, "[WEAPON NEXT/PREV] - Scroll Inventory", flags, "thin")
	y = $ - 8
	v.drawString(x,y, "[SPIN] - Swim form", flags, "thin")
	y = $ - 8
end,"game")