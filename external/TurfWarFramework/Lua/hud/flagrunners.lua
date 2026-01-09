return function(v,p, cam)
	if not (TurfWar and Paint) then return end
	if not Paint:isMode() then return end
	if not (gametyperules & GTR_TEAMFLAGS) then return end
	
	local runners = {}
	for play in players.iterate
		if play.spectator then continue end
		if not (play.mo and play.mo.valid) then continue end
		if not play.gotflag then continue end
		local mo = play.mo
		local pos = {
			x = mo.x,
			y = mo.y,
			z = mo.z + mo.height*6/5
		}
		
		table.insert(runners, {
			pos = pos,
			flag = play.gotflag,
			id = #play
		})
	end
	if redflag and redflag.valid and redflag.fuse > 1
		table.insert(runners, {
			pos = {
				x = redflag.x,
				y = redflag.y,
				z = redflag.z + redflag.height*6/5
			},
			flag = GF_REDFLAG,
			dropped = true,
			fuse = redflag.fuse,
			id = 35
		})
	elseif blueflag and blueflag.valid and blueflag.fuse > 1
		table.insert(runners, {
			pos = {
				x = blueflag.x,
				y = blueflag.y,
				z = blueflag.z + blueflag.height*6/5
			},
			flag = GF_BLUEFLAG,
			dropped = true,
			fuse = blueflag.fuse,
			id = 36
		})
	end
	
	local sci_w = (v.width() / v.dupx())
	local sci_h = (v.height() / v.dupy())
	local sc_w = sci_w*FU
	local sc_h = sci_h*FU
	local sch_w = (sci_w - BASEVIDWIDTH)*FU/2
	local sch_h = (sci_h - BASEVIDHEIGHT)*FU/2
	
	for k, info in ipairs(runners)
		local result = K_GetScreenCoords(v,p,cam, info.pos, {anglecliponly = true})
		local clr = v.getColormap(TC_DEFAULT, info.flag == GF_REDFLAG and skincolor_redteam or skincolor_blueteam)
		local flags = 0
		if not info.dropped
			flags = (info.flag ~= p.ctfteam) and V_50TRANS or 0
		end
		
		local x = result.x
		local y = result.y
		if not result.onscreen
			local da = result.camAngle - R_PointToAngle2(result.camPos.x,result.camPos.y, info.pos.x,info.pos.y)
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
			
			v.dointerp(50 + info.id)
			v.drawScaled(x, y,
				FU/2,
				v.getSpritePatch(SPR_PAINT_MISC, 20, 0,
					InvAngle(da) + ANGLE_90
				),
				0
			)
		else
			v.dointerp(info.id)
		end
		
		v.drawScaled(x,y, FU/2, v.cachePatch("PT_FLAGICON"),
			-- teammates catching the enemy flag have a transparent icon
			flags,
			clr
		)
		if info.dropped
			v.drawString(x, y + 2*FU,
				(info.fuse/TR)+1, V_YELLOWMAP, "small-thin-fixed-center"
			)
		end
		v.dointerp(false)
	end
end