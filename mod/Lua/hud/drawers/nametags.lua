local HUD = Paint.HUD
local CV = Paint.CV
local ANIM = 14

HUD.memory.killtags = {}

local byteLUT = {}
for i = 26, 126
	byteLUT[i] = ("%.3d"):format(i)
end

function HUD:killNotice(target)
	local mo = target.realmo
	if not (mo and mo.valid) then return end
	
	table.insert(HUD.memory.killtags, {
		pos = {x=mo.x,y=mo.y,z=mo.z + mo.height/2, play = target},
		name = target.name,
		tics = 5 * TR,
		color = Paint:getPlayerColor(target),
		id = (#target) + leveltime,
		play = target,
	})
end

addHook("HUD",function(v,p,cam)
	local me = p.realmo
	if not (me and me.valid) then return end
	if not Paint:playerIsActive(p) then return end
	local pt = p.paint
	
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
			table.insert(tmp, {play = v, dist = dist, id = #v})
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
		})
	end
	table.sort(tmp, function(a,b)
		return a.dist > b.dist
	end)
	
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
		local pro = K_GetScreenCoords(v,p,cam, pos, {anglecliponly = true})
		if not pro.onscreen then continue end
		
		if (va.tag)
		and (va.tics >= (5*TR - ANIM))
			local work = 5*TR - va.tics
			pro.y = $ - abs(ease.outback((FU/ANIM)*work, -300*FU, 0, FU/2))
		end
		pro.y = $ - (60 * pro.scale)
		pro.scale = FU / 2
		local tx = pro.x
		
		local wcmap = cmap
		local wacmap = acmap
		if (va.tag)
			wcmap = v.getStringColormap(skincolors[va.clr].chatcolor)
			wacmap = v.getColormap(TC_DEFAULT, va.clr)
		end
		
		v.dointerp(va.id)
		v.drawScaled(pro.x,pro.y + 12*pro.scale, pro.scale/2, v.getSpritePatch(SPR_PAINT_MISC,1,0), 0, wacmap)
		
		local str = (va.tag) and (va.name) or play.name
		pro.x = $ - (v.stringWidth(str,0,"thin")*pro.scale)/2
		for i = 1, str:len()
			local char = str:sub(i,i)
			local byte = char:byte()
			if (byte < 26 or byte > 126) then continue; end
			if (char == " ")
				pro.x = $ + 4*pro.scale
				continue
			end
			local letter = v.cachePatch("TNYFN" .. byteLUT[byte])
			v.drawScaled(pro.x,pro.y, pro.scale, letter, 0, wcmap)
			pro.x = $ + (letter.width*pro.scale)
		end
		if (va.tag)
			v.drawScaled(tx,pro.y, pro.scale, v.cachePatch("PAINT_TNYCROSS"), 0, wcmap)
		end
		v.dointerp(false)
	end
end,"game")