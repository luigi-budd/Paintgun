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
	local cropheight = FixedMul(patch.height*FU, FU - inkprogress)
	local ypos = result.y + FixedMul(cropheight, result.scale)
	v.drawCropped(result.x,ypos, result.scale, result.scale,
		patch, 0, v.getColormap(TC_DEFAULT, Paint:getPlayerColor(p)),
		0,cropheight, patch.width*FU, patch.height*FU
	)
	if (pt.inktank ~= 100*FU and FixedHypot(me.momx,me.momy) < 5*me.scale)
		v.drawCropped(result.x,ypos, result.scale, result.scale,
			patch, V_ADD|V_20TRANS, v.getColormap(TC_DEFAULT, Paint:getPlayerColor(p)),
			0,cropheight, patch.width*FU, patch.height*FU
		)
	end
	v.dointerp(false)
end,"game")