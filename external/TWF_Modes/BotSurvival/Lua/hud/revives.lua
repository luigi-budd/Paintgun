local byteLUT = {}
for i = 26, 126
	byteLUT[i] = ("%.3d"):format(i)
end

addHook("HUD",function(v,p, cam)
	if (gametype ~= GT_SALMONRUN) then return end
	local me = p.realmo
	local pt = p.paint
	
	local tmp = {}
	if (pt.teammates ~= nil
	and #pt.teammates)
		for k,v in pairs(pt.teammates)
			local dist = 0
			if (v and v.valid and v.mo and v.mo.valid and (not v.mo.health or v.lifesaver) and v ~= p)
				dist = R_PointToDist(v.mo.x, v.mo.y)
			else
				continue
			end
			table.insert(tmp, {play = v, dist = dist, id = #v})
		end
	end

	table.sort(tmp, function(a,b)
		return a.dist > b.dist
	end)

	local sci_w = (v.width() / v.dupx())
	local sci_h = (v.height() / v.dupy())
	local sc_w = sci_w*FU
	local sc_h = sci_h*FU
	local sch_w = (sci_w - BASEVIDWIDTH)*FU/2
	local sch_h = (sci_h - BASEVIDHEIGHT)*FU/2

	local clr = Paint:getPlayerColor(p)
	if clr == SKINCOLOR_NONE then return end
	local vmap = skincolors[clr].chatcolor
	local cmap = v.getStringColormap(vmap)
	local acmap = v.getColormap(TC_DEFAULT, clr)
	for k, va in ipairs(tmp)
		local play = va.play
		local pos = play.deathpos
		if (pos == nil) then continue end
		
		local wcmap = cmap
		local wacmap = acmap
		
		local pro = K_GetScreenCoords(v,p,cam, pos, {anglecliponly = true})
		local x = pro.x
		local y = pro.y - 90*pro.scale
		local scale = FU/2
		v.dointerp(va.id)
		if not pro.onscreen
			if pro.camPos == nil then continue end
			local da = pro.camAngle - R_PointToAngle2(pro.camPos.x,pro.camPos.y, pos.x,pos.y)
			local borderx = 15
			local bordery = 15
			local center = {
				x = 160*FU,
				y = 100*FU,
			}
			local scr = {
				x = (160 - borderx)*FU + sch_w,
				y = (100 - bordery)*FU + sch_h,
			}
			x = center.x + FixedMul(scr.x, sin(da))
			y = center.y - FixedMul(scr.y, cos(da))
			
			v.drawScaled(x, y,
				FU/2,
				v.getSpritePatch(SPR_PAINT_MISC, 20, 0, 
					InvAngle(da) + ANGLE_90
				),
				0
			)
		end
		
		v.drawScaled(x,y, scale,
			v.getSprite2Patch(play.skin, SPR2_LIFE, false, A,0,0), 
			0, v.getColormap(nil,nil,"AllBlack")
		)
		v.drawScaled(x,y, FU/4, v.cachePatch("PAINT_KNOTICE_X"), 0, wacmap)
		
		v.dointerp(false)
	end
	
end,"game")