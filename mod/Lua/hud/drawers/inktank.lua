local HUD = Paint.HUD
local MAXANIM = 5
local anim = 0

addHook("HUD",function(v,p,cam)
	local me = p.mo
	if not (me and me.valid) then return end
	if not Paint:playerIsActive(p) then return end
	local pt = p.paint
	
	if not cam.chase
		local strength = FU
		local speed = 14*FU
		local clrmp = v.getColormap(TC_DEFAULT, Paint:getPlayerColor(p))
		local wclrmp = v.getColormap(TC_RAINBOW, SKINCOLOR_SUPERSILVER1)
		
		local fast = (pt.inktank ~= 100*FU and pt.inkdelay == 0)
		
		local wid = 80*FU
		local x = 160*FU - wid/2
		local y = 150*FU
		
		local whiteink = pt.inkdelay ~= 0 or pt.inkqueue ~= 0
		
		local prog = FixedDiv(max(pt.inktank - pt.inkqueue, 0), 100*FU)
		local whiteprog = FixedDiv(pt.oldinkanim,100*FU)
		local f_wid = FixedMul(wid,prog)
		local w_wid = FixedMul(wid,whiteprog)
		
		local pad = 2
		v.drawFill((x/FU) - pad  , (y/FU) - pad  , (wid/FU) + pad*2, 10 + pad*2, 23)
		v.drawFill((x/FU) - pad/2, (y/FU) - pad/2, (wid/FU) + pad  , 6         , 25)
		v.drawFill((x/FU)        , (y/FU)        , (wid/FU)        , 10        , 27)
		
		local ox = (leveltime*FU)/8
		local oy = (leveltime*FU)/8
		for i = 0,9
			local sinoff = abs(sin(FixedAngle((leveltime+i*4)*FU*4)))/2
			if whiteink
				HUD.drawSplashBG(v, x,y + i*FU, 
					0,i*FU,
					clamp(0, w_wid + sinoff, wid),
					FU, V_50TRANS, wclrmp, true
				)
			end
			
			HUD.drawSplashBG(v, x,y + i*FU, 
				ox,oy + i*FU,
				clamp(0, f_wid + sinoff, wid),
				FU, 0, clrmp, pt.fastrefill
			)
		end
		local weapon_t = Paint.weapons[pt.weapon_id]
		local sub_t
		if weapon_t
			sub_t = Paint.subs[weapon_t.subtype]
		end
		if sub_t
			local color = Paint:getPlayerColor(p) + 1
			local blend = 0
			color = clamp(SKINCOLOR_WHITE, $, SKINCOLOR_VOLCANIC - 1)
			if color <= SKINCOLOR_BLACK
				color = SKINCOLOR_WHITE
				blend = V_SUBTRACT
			end
			
			v.drawScaled(x + FixedMul(wid, FixedDiv(sub_t:get(pt,"inkcost"), 100*FU)),
				y,
				FU,
				v.cachePatch("PAINT_FPSUBLINE"),
				blend,v.getColormap(TC_DEFAULT, color, nil)
			)
		end
		return
	end
	
	if not (pt.squidtime and pt.hidden)
		anim = max($ - 1, 0)
		if not anim then return end
	else
		anim = min($ + 1, MAXANIM)
	end
	
	local result = K_GetScreenCoords(v,p,cam, me, {anglecliponly = true})
	if not result.onscreen then return end
	--result.scale = $ * 3/2
	result.x = $ + 27*result.scale
	
	local animprogress = FixedDiv(anim*FU, MAXANIM*FU)
	local weapon_t = Paint.weapons[pt.weapon_id]
	local sub_t
	if weapon_t
		sub_t = Paint.subs[weapon_t.subtype]
	end

	v.dointerp(true)
	v.drawStretched(result.x,result.y, result.scale, FixedMul(result.scale, animprogress), v.getSpritePatch(SPR_PAINT_INKTANK,3,0), 0)
	local fast = (pt.inktank ~= 100*FU and pt.inkdelay == 0)
	local inkprogress = FixedDiv(pt.inktank - pt.inkqueue,100*FU)
	local patch = v.getSpritePatch(SPR_PAINT_INKTANK,fast and 1 or 2,0)
	local cropheight = FixedMul(patch.height*FU, FU - inkprogress)
	local ypos = result.y + FixedMul(cropheight, FixedMul(result.scale, animprogress))
	if pt.inkdelay ~= 0
	or pt.inkqueue ~= 0
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
	if sub_t
		local color = Paint:getPlayerColor(p) + 1
		local blend = 0
		color = clamp(SKINCOLOR_WHITE, $, SKINCOLOR_VOLCANIC - 1)
		if color <= SKINCOLOR_BLACK
			color = SKINCOLOR_WHITE
			blend = V_SUBTRACT
		end
		
		v.drawStretched(result.x,
			result.y - FixedMul(23 * FixedMul(result.scale, animprogress), FixedDiv(sub_t:get(pt,"inkcost"), 100*FU)),
			result.scale, FixedMul(result.scale, animprogress),
			v.getSpritePatch(SPR_PAINT_INKTANK, (fast and pt.inktank >= sub_t:get(pt,"inkcost")) and 4 or 5,0),
			blend,v.getColormap(TC_DEFAULT, color, nil)
		)
	end
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