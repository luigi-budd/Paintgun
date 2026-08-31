Paint.teams = {}
local team_meta = {
	id = "baseteam",
	
	-- when not nil, any player on this team will
	-- be forced to use this color
	color = nil,
	
	abilitywrap = nil, -- function, see weapon_t
	thinker = nil, -- function(player)
	onassigned = nil, -- function(player)
}
registerMetatable(team_meta)

function Paint:registerTeam(props)
	assert(props.id, "Properties table must have an id field")
	props.get = function(self, paint, key)
		local value = self[key]
		if self.abilitywrap ~= nil
			local temp = self.abilitywrap(paint.player, paint, self, key, value)
			if temp ~= nil
				value = temp
			end
		end
		return value
	end
	setmetatable(props, {
		__index = team_meta,
	})
	Paint.teams[props.id] = props
end

/*
Paint:registerTeam({
	id = "testteam",
	color = SKINCOLOR_ORANGE,
	
	onassigned = function(p)
		local pt = p.paint
		
		Paint:removeWeapon(p, 1)
		Paint:removeWeapon(p, 2)
		Paint:removeWeapon(p, 3)
	end
})
*/

-- set to false to remove a team
function Paint:setPlayerTeam(p, teamname)
	local pt = p.paint
	
	if teamname == false -- remove assignment
		pt.team = false
		return
	end
	
	if self.teams[teamname] == nil
		error(("Paintgun team '%s' does not exist"):format(tostring(teamname)), 3)
		return
	end
	
	local team = Paint.teams[teamname]
	pt.team = teamname
	
	if team.onassigned ~= nil
		team.onassigned(p)
	end
end

-- returns a players team (int), nil if there are no teams
function Paint:getPlayerTeam(p)
	local pt = p.paint
	if G_GametypeHasTeams()
		return p.ctfteam
	end
	-- player does not have any team alignment
	if pt.team == false then return nil; end
	
	return pt.team
end

-- checks mo2 against mo1 if they are on the same team
function Paint:mobjsOnTeam(mo1, mo2)
	if not mo1 and mo1.valid then return false; end
	if not (mo1.player and mo1.player.valid)
		if (mo2.player and mo2.player.valid)
			return mo1.color == self:getPlayerColor(mo2.player)
		else
			return mo1.color == mo2.color
		end
	elseif not (mo2.player and mo2.player.valid)
		if (mo1.player and mo1.player.valid)
			return mo2.color == self:getPlayerColor(mo1.player)
		else
			return mo2.color == mo1.color
		end
	end
	if (mo1.player == mo2.player) then return true; end
	if (gametyperules & GTR_FRIENDLY)
		if CV.FindVar("friendlyfire").value
			return false
		end
		return true
	end
	if (gametyperules & GTR_TAG)
		return (mo1.player.pflags & PF_TAGIT) == (mo2.player.pflags & PF_TAGIT)
	end
	
	if G_GametypeHasTeams()
		return mo1.player.ctfteam == mo2.player.ctfteam
	end
	-- players can never share a team if they have no alignment,
	-- even if both are unassigned
	if (mo1.player.paint.team == false or mo2.player.paint.team == false)
		return false
	end
	return mo1.player.paint.team == mo2.player.paint.team
end

-- TODO: a weird and inconsistant mix of several of these types of functions
--		 are used all throughout the codebase... a more unified way to check for
--		 player-player, player-mobj, mobj-mobj "teamness" needs to be made
function Paint:isFriendlyFire(p1,p2)
	if not (p1 and p1.valid and p2 and p2.valid) then return false; end
	if G_GametypeHasTeams()
		return p1.ctfteam == p2.ctfteam
	elseif G_TagGametype()
		return (p1.pflags & PF_TAGIT) == (p2.pflags & PF_TAGIT)
	end
	if (Paint:getPlayerTeam(p1) ~= nil and Paint:getPlayerTeam(p2) ~= nil)
		return Paint:getPlayerTeam(p1) == Paint:getPlayerTeam(p2)
	end
	
	if (gametyperules & GTR_FRIENDLY)
		return CV.FindVar("friendlyfire").value == 0
	end
	return false -- eh we're probably good here
end