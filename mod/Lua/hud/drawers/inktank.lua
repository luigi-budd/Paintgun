local HUD = Paint.HUD

addHook("HUD",function(v,p,cam)
	local me = p.mo
	if not (me and me.valid) then return end
	if not Paint:playerIsActive(p) then return end
	local pt = p.paint
	
	if not (pt.squidtime and pt.hidden) then return end
	
	local result = K_GetScreenCoords(v,p,cam, me, {anglecliponly = true})
	if not result.onscreen then return end
	result.scale = $ * 3/2
	
	result.x = $ + 25*result.scale
	
	v.dointerp(true)
	v.drawScaled(result.x,result.y, result.scale, v.getSpritePatch(SPR_PAINT_MISC,4,0), 0)
	/*
	v.drawStretched(result.x,result.y, result.scale, FixedMul(result.scale, FixedDiv(pt.inktank,100*FU)),
		v.getSpritePatch(SPR_PAINT_MISC,3,0), 0, v.getColormap(TC_DEFAULT, Paint:getPlayerColor(p))
	)
	*/
	local inkprogress = FixedDiv(pt.inktank,100*FU)
	local patch = v.getSpritePatch(SPR_PAINT_MISC,3,0)
	v.drawCropped(result.x,result.y + FixedMul(FixedMul(patch.height*FU, FU - inkprogress), result.scale), result.scale, result.scale,
		patch, 0, v.getColormap(TC_DEFAULT, Paint:getPlayerColor(p)),
		0,FixedMul(patch.height*FU, FU - inkprogress), patch.width*FU, patch.height*FU
	)
	
	v.dointerp(false)
end,"game")