local HUD = Paint.HUD
local MAXANIM = 5
local anim = 0

addHook("HUD",function(v,p,cam)
	local me = p.mo
	if not (me and me.valid) then return end
	if not Paint:playerIsActive(p) then return end
	local pt = p.paint
	
	if not (pt.squidtime and pt.hidden)
		anim = max($ - 1, 0)
		if not anim then return end
	else
		anim = min($ + 1, MAXANIM)
	end
	
	local result = K_GetScreenCoords(v,p,cam, me, {anglecliponly = true})
	if not result.onscreen then return end
	result.scale = $ * 3/2
	result.x = $ + 27*result.scale
	
	local animprogress = FixedDiv(anim*FU, MAXANIM*FU)
	
	v.dointerp(true)
	v.drawStretched(result.x,result.y, result.scale, FixedMul(result.scale, animprogress), v.getSpritePatch(SPR_PAINT_MISC,5,0), 0)
	/*
	v.drawStretched(result.x,result.y, result.scale, FixedMul(result.scale, FixedDiv(pt.inktank,100*FU)),
		v.getSpritePatch(SPR_PAINT_MISC,3,0), 0, v.getColormap(TC_DEFAULT, Paint:getPlayerColor(p))
	)
	*/
	local fast = (pt.inktank ~= 100*FU and pt.inkdelay == 0)
	local inkprogress = FixedDiv(pt.inktank,100*FU)
	local patch = v.getSpritePatch(SPR_PAINT_MISC,fast and 3 or 4,0)
	local cropheight = FixedMul(patch.height*FU, FU - inkprogress)
	local ypos = result.y + FixedMul(cropheight, FixedMul(result.scale, animprogress))
	if pt.inkdelay ~= 0
		local inkprogress = FixedDiv(pt.oldinkanim,100*FU)
		local cropheight = FixedMul(patch.height*FU, FU - inkprogress)
		local ypos = result.y + FixedMul(cropheight, FixedMul(result.scale, animprogress))
		v.drawCropped(result.x,ypos, result.scale, FixedMul(result.scale, animprogress),
			patch, V_50TRANS, v.getColormap(TC_RAINBOW, SKINCOLOR_SUPERSILVER1),
			0,cropheight, patch.width*FU, patch.height*FU
		)
	end
	v.drawCropped(result.x,ypos, result.scale, FixedMul(result.scale, animprogress),
		patch, 0, v.getColormap(TC_DEFAULT, Paint:getPlayerColor(p)),
		0,cropheight, patch.width*FU, patch.height*FU
	)
	/*
	HUD.drawSplashBG(v,
		result.x - patch.leftoffset*result.scale,
		result.y - patch.topoffset*result.scale + FixedMul(cropheight, FixedMul(result.scale, animprogress)),
		abs(leveltime)*FU/4,abs(leveltime)*FU/4,
		patch.width*result.scale, FixedMul(patch.height*FixedMul(result.scale,animprogress), inkprogress),
		0, v.getColormap(TC_DEFAULT, Paint:getPlayerColor(p)), 
		fast
	)*/
	v.dointerp(false)
end,"game")