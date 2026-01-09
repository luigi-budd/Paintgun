local box_width = 30
local box_height = 19
local spacing = 25

local function func(v,game)
	if not G_GametypeHasTeams() then return end
	
	local inscores = (not game)
	local flags = V_SNAPTOTOP
	local y = (inscores) and 5 or 20
	local gotflags = 0
	if not inscores
		for play in players.iterate
			if (play.gotflag & GF_BLUEFLAG)
				gotflags = $|GF_BLUEFLAG
			end
			if (play.gotflag & GF_REDFLAG)
				gotflags = $|GF_REDFLAG
			end
			if gotflags == GF_BLUEFLAG|GF_REDFLAG
				break
			end
		end
	end
	
	local gt = TurfWar.gamemodes[gametype]
	local pointlimit = gt.pointlimit
	
	for i = -1,1,2
		local x = (160) + spacing*i
		local alpha = (i == 1)
		
		local score = bluescore
		if alpha then score = redscore; end
		
		local color = alpha and skincolor_redteam or skincolor_blueteam
		local vmap = skincolors[color].chatcolor
		local ramp = 29
		
		if (gametyperules & GTR_TEAMFLAGS)
			-- bravo can score
			if ((gotflags & GF_REDFLAG) and not alpha)
			-- alpha can score
			or ((gotflags & GF_BLUEFLAG) and alpha)
				vmap = 0
				ramp = skincolors[color].ramp[3]
			end
		end
		
		v.drawFill(
			(x - box_width/2) + 1, y,
			box_width - 2, 1,
			flags|ramp
		)
		v.drawFill(
			(x - box_width/2), y + 1,
			box_width, box_height - 2,
			flags|ramp
		)
		v.drawFill(
			(x - box_width/2) + 1, y+box_height - 1,
			box_width - 2, 1,
			flags|ramp
		)
		if (pointlimit)
			v.drawString(x, y + 3, "Remaining", flags|V_ALLOWLOWERCASE|vmap, "small-thin-center")
			v.drawString(x, y + 8, pointlimit - score, flags|vmap, "center")
		else
			v.drawString(x, y + 1, "Score", flags|V_ALLOWLOWERCASE|vmap, "thin-center")
			v.drawString(x, y + 10, score, flags|vmap, "center")
		end
		
		if not inscores
		and (gametyperules & GTR_TEAMFLAGS)
			local x = (x + (box_width/2)*i)
			if not alpha
				x = $ - 27
			else
				x = $ + 4
			end
			local y = y + 2
			
			local flagmobj = blueflag
			if (alpha) then flagmobj = redflag; end
			local flagflag = (alpha) and GF_REDFLAG or GF_BLUEFLAG
			local flag = alpha and "PT_ALPHAF" or "PT_BRAVOF"
			local cmap = v.getColormap(TC_DEFAULT, color, nil)
			v.drawScaled(x*FU,y*FU, FU/2, v.cachePatch(flag), flags, cmap)
			if (gotflags & flagflag)
				local patch = v.cachePatch("PT_NO")
				v.drawScaled(x*FU, (y - 4)*FU, FU, patch, flags, cmap)
			end
			if (flagmobj and flagmobj.valid) and (flagmobj.fuse > 1)
				v.drawString(x + 12,y + 4, ((flagmobj.fuse)/TR)+1, flags|V_YELLOWMAP, "thin-center")
			end
		end
	end
end

return func, "gameandscores"
