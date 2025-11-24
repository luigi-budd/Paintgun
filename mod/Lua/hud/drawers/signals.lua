local HUD = Paint.HUD
local CV = Paint.CV

HUD.memory.signals = {}

local byteLUT = {}
for i = 26, 126
	byteLUT[i] = ("%.3d"):format(i)
end

function HUD:addSignal(p, from, type)
	if displayplayer ~= p then return end
	if not (CV.nametags.value) then return end
	local mo = from.realmo
	if not (mo and mo.valid) then return end
	
	table.insert(HUD.memory.signals, {
		from = from,
		tics = Paint.SIGNAL_TIME,
		type = type
	})
end

local texts = {
	[Paint.SIGNAL_BOOYAH]	= "Booyah!",
	[Paint.SIGNAL_THISWAY]	= "This way!",
	[Paint.SIGNAL_OUCH]		= "Ouch...",
	[Paint.SIGNAL_HELP]		= "Help!",
}

addHook("HUD",function(v,p,cam)
	local me = p.realmo
	if not (me and me.valid) then return end
	--if not Paint:playerIsActive(p) then return end
	local pt = p.paint
	
	if not (CV.nametags.value) then return end
	
	for k,v in ipairs(HUD.memory.signals)
		if v.tics <= 0
		or not (v.from and v.from.valid)
			table.remove(HUD.memory.signals, k)
			continue
		end
		v.tics = $ - 1
	end
	
	local tmp = {}
	for k,v in ipairs(HUD.memory.signals)
		if not v.from.realmo and v.from.realmo.valid then continue end
		table.insert(tmp, {
			from = v.from,
			tics = v.tics,
			type = v.type,
			dist = R_PointToDist(v.from.realmo.x, v.from.realmo.y)
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
	for k, va in ipairs(tmp)
		local pos = va.from.realmo
		local pro = K_GetScreenCoords(v,p,cam, pos, {anglecliponly = true})
		local x = pro.x
		local y = pro.y
		local str = texts[va.type]
		pro.scale = FU + abs(sin(FixedAngle(va.tics * FU * 8)))/4
		local fade = 0
		if (va.tics < 10)
			fade = (10 - va.tics) << V_ALPHASHIFT
		end
		
		if not pro.onscreen
			local da = pro.camAngle - R_PointToAngle2(pro.camPos.x,pro.camPos.y, pos.x,pos.y)
			local borderx = 30
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
		end
		
		x = $ - (v.stringWidth(str,0,"thin")*pro.scale)/2
		
		v.dointerp(#va.from)
		for i = 1, str:len()
			local char = str:sub(i,i)
			local byte = char:byte()
			if (byte < 26 or byte > 126) then continue; end
			if (char == " ")
				x = $ + 4*pro.scale
				continue
			end
			local letter = v.cachePatch("TNYFN" .. byteLUT[byte])
			v.drawScaled(x,y, pro.scale, letter, fade)
			x = $ + (letter.width*pro.scale)
		end
		v.dointerp(false)
	end
end,"game")