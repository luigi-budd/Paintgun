local HUD = Paint.HUD
local CV = Paint.CV
local ANIM = 14

HUD.memory.killtags = {}

local byteLUT = {}
for i = 26, 126
	byteLUT[i] = ("%.3d"):format(i)
end

function HUD:killNotice(target)
	if not (CV.nametags.value) then return end
	local mo = target.realmo
	if not (mo and mo.valid) then return end
	if not (displayplayer and displayplayer.valid) then return end
	if displayplayer.spectator then return end
	
	table.insert(HUD.memory.killtags, {
		pos = {x=mo.x,y=mo.y,z=mo.z + mo.height/2, play = target},
		name = target.name,
		tics = 5 * TR,
		color = Paint:getPlayerColor(target),
		id = (#target) + leveltime,
		play = target,
		friendly = Paint:mobjsOnTeam(displayplayer.realmo, mo)
	})
end

addHook("HUD",function(v,p,cam)
	local me = p.realmo
	if not (me and me.valid) then return end
	--if not Paint:playerIsActive(p) then return end
	local pt = p.paint
	if not pt then return end
	if not (CV.nametags.value) then return end
	
	for k,v in ipairs(HUD.memory.killtags)
		if v.tics <= 0
		or not (v.play and v.play.valid)
			table.remove(HUD.memory.killtags, k)
			continue
		end
		v.tics = $ - 1
	end
	
	local tmp = {}
	if (pt.teammates ~= nil
	and #pt.teammates)
		for k,v in pairs(pt.teammates)
			local dist = 0
			if (v and v.valid and v.mo and v.mo.valid and v.mo.health and v ~= p)
				dist = R_PointToDist(v.mo.x, v.mo.y)
			else
				continue
			end
			table.insert(tmp, {play = v, dist = dist, id = #v, friendly = Paint:mobjsOnTeam(p.realmo, v.realmo)})
		end
	end
	for k,v in ipairs(HUD.memory.killtags)
		if v.play == p then continue end
		table.insert(tmp, {play = v.play, dist = R_PointToDist(v.pos.x, v.pos.y), tag = true,
			tics = v.tics,
			pos = v.pos,
			name = v.name,
			clr = v.color,
			id = v.id,
			
			friendly = v.friendly
		})
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
		local pos
		if va.tag
			pos = {x = va.pos.x, y = va.pos.y, z = va.pos.z}
		else
			pos = play.realmo
		end
		
		local wvmap = vmap
		local wcmap = cmap
		local wacmap = acmap
		if (va.tag)
			wvmap = skincolors[va.clr].chatcolor
			wcmap = v.getStringColormap(wvmap)
			wacmap = v.getColormap(TC_DEFAULT, va.clr)
		end
		
		local pro = K_GetScreenCoords(v,p,cam, pos, {anglecliponly = true})
		if not pro.onscreen
			if not va.tag then continue end
			--if not va.friendly then continue end
			
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
			local x = center.x + FixedMul(scr.x, sin(da))
			local y = center.y - FixedMul(scr.y, cos(da))
			
			v.dointerp(va.id)
			v.drawScaled(x,y, FU/2, v.cachePatch("PAINT_KNOTICE_X"), 0, wacmap)
			v.drawScaled(x, y,
				FU/2,
				v.getSpritePatch(SPR_PAINT_MISC, 20, 0, 
					InvAngle(da) + ANGLE_90
				),
				0
			)
			v.dointerp(false)
			continue
		end
		
		if (va.tag)
		and (va.tics >= (5*TR - ANIM))
			local work = 5*TR - va.tics
			pro.y = $ - abs(ease.outback((FU/ANIM)*work, -300*FU, 0, FU/2))
		end
		pro.y = $ - (60 * pro.scale)
		pro.scale = FU / 2
		local tx = pro.x
		
		v.dointerp(va.id)
		local str = (va.tag) and (va.name) or play.name
		
		-- this games string drawing is impeccable
		v.drawScaled(pro.x - (7*pro.scale)/2, pro.y + 8*pro.scale, pro.scale, v.cachePatch("TNYFN027"), 0, wcmap)
		v.drawString(pro.x, pro.y, str, V_ALLOWLOWERCASE|wvmap, "small-thin-fixed-center")
		if (va.tag)
			v.drawScaled(tx,pro.y, pro.scale, v.cachePatch("PAINT_TNYCROSS"), 0, wcmap)
		end
		v.dointerp(false)
	end
end,"game")