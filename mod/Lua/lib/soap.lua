rawset(_G,"Paint_canHurtEnemy",function(p, mobj,flags,exclude, nobs)
	if (CanFlingThing ~= nil)
		return CanFlingThing(p, mobj,flags,false,exclude)
	end
	
	local flingable = false
	flags = $ or MF_ENEMY|MF_BOSS|MF_MONITOR|MF_SHOOTABLE
	exclude = $ or 0
	
	if not (mobj and mobj.valid) then return false end
	
	if (mobj.flags2 & MF2_FRET and not nobs)
		return false
	end
	
	if mobj.flags & (flags)
		flingable = true
	end
	
	if mobj.takis_flingme ~= nil
		if mobj.takis_flingme == true
			flingable = true
		elseif mobj.takis_flingme == false
			flingable = false
		end
	end
	
	if (mobj.flags & MF_SHOOTABLE and flags & MF_SHOOTABLE)
		if mobj.flags2 & MF2_INVERTAIMABLE
			flingable = not $
		end
	end
	
	if mobj.flags & (exclude)
		flingable = false
	end
	
	--use CanPlayerHurtPlayer instead
	if (mobj.player and mobj.player.valid) then flingable = false end
	
	if (mobj.type == MT_EGGMAN_BOX or mobj.type == MT_EGGMAN_GOLDBOX) then flingable = false end

	/*
		if true, force a hit
		if false, force no hits
		if nil, use the above checks
	*/
	if Takis_Hook
		local hook_event = Takis_Hook.events["CanFlingThing"]
		for i,v in ipairs(hook_event)
			if hook_event.typefor ~= nil
				if hook_event.typefor(mobj, v.typedef) == false then continue end
			end
			
			local result = Takis_Hook.tryRunHook("CanFlingThing", v, mobj, p,flags,false,exclude)
			if result ~= nil
				flingable = result
			end
		end
	end
	return flingable
end)

rawset(_G, "Paint_canHurtPlayer", function(p1,p2,nobs)
	if not (p1 and p1.valid)
	or not (p2 and p2.valid)
		return false
	end
	
	local allowhurt = true
	local ff = CV_FindVar("friendlyfire").value
	
	if not (nobs)
		--no griefing!
		if (TAKIS_NET
		and TAKIS_NET.inspecialstage)
		or G_IsSpecialStage(gamemap)
			return false
		end
		
		if not (p1.mo and p1.mo.valid)
			return false
		end
		if not (p2.mo and p2.mo.valid)
			return false
		end
		
		/*
		if not p1.mo.health
			return false
		end
		*/
		if not p2.mo.health
			return false
		end
		
		--non-supers can hit each other, supers can hit other supers,
		--but non-supers cant hit supers
		local superallowed = true
		if (p1.powers[pw_super])
			superallowed = true
		elseif (p2.powers[pw_super])
			superallowed = false
		end
		
		if ((p2.powers[pw_flashing])
		or (p2.powers[pw_invulnerability])
		or not superallowed)
			return false
		end
		
		if (leveltime <= CV_FindVar("hidetime").value*TR)
		and (gametyperules & GTR_STARTCOUNTDOWN)
			return false
		end
		
		if (p1.botleader == p2)
			return false
		end
		
		--battlemod parrying
		/*
		if (p2.guard and p2.guard == 1)
			return false
		end
		
		if p1.takistable
		and p1.takistable.inBattle
		and CBW_Battle.MyTeam(p1,p2)
			return false
		end
		
		if p1.takistable
		and p1.takistable.inSaxaMM
		and (p1.mm and p1.mm.role ~= MMROLE_MURDERER)
			return false
		end
		*/
	end
	
	-- In COOP/RACE, you can't hurt other players unless cv_friendlyfire is on
	if (not (ff or (gametyperules & GTR_FRIENDLYFIRE))
	and (gametyperules & (GTR_FRIENDLY|GTR_RACE)))
		allowhurt = false
	end
	
	if G_TagGametype()
		if ((p2.pflags & PF_TAGIT and not ((ff or (gametyperules & GTR_FRIENDLYFIRE))
		and p1.pflags & PF_TAGIT)))
			allowhurt = false
		end
		
		if (not (ff or (gametyperules & GTR_FRIENDLYFIRE))
		and (p2.pflags & PF_TAGIT == p1.pflags & PF_TAGIT))
			allowhurt = false
		end
	end
	
	if G_GametypeHasTeams()
		if (not (ff or gametyperules & GTR_FRIENDLYFIRE))
		and (p2.ctfteam == p1.ctfteam)
			allowhurt = false
		end
	end
	
	if P_PlayerInPain(p1)
		allowhurt = false
	end
	
	/*
	if Takis_Hook
			if true, force a hit
			if false, force no hits
			if nil, use the above checks
		local hook_event = Takis_Hook.events["CanPlayerHurtPlayer"]
		for i,v in ipairs(hook_event)
			local result = Takis_Hook.tryRunHook("CanPlayerHurtPlayer", v, p1,p2,nobs)
			if result ~= nil
				allowhurt = result
			end
		end
	end
	*/
	return allowhurt
end)