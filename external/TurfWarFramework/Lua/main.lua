rawset(_G, "TR",TICRATE)

rawset(_G, "TurfWar",{})
TurfWar.const = {}
TurfWar.const.ROUNDTIME = 3 * 60 * TR
TurfWar.const.ENDTIME = -5*TR
TurfWar.const.NOTIMER = -255

TurfWar.const.TEAM_ALPHA = 1
TurfWar.const.TEAM_BRAVO = 2

TurfWar.const.MSG_TIME = 2*TR + (TR/2)

TurfWar.time = TurfWar.const.NOTIMER
TurfWar.minutewarning = false
TurfWar.overtime = false

TurfWar.old = {
	alphascore = 0,
	bravoscore = 0,
	
	alphaobj_picked = false,
	bravoobj_picked = false,
	alphaobj_special = -2,
	bravoobj_special = -2,
}
TurfWar.messagestate = {
	team = 0,
	tics = 0,
	text = ""
}
TurfWar.gotflags = {}

sfxinfo[freeslot("sfx_1min")].caption = "/"
sfxinfo[freeslot("sfx_p_rest")].caption = "/"
sfxinfo[freeslot("sfx_p_pos")].caption = "/"
sfxinfo[freeslot("sfx_p_neg")].caption = "/"
sfxinfo[freeslot("sfx_p_led")].caption = "/"
sfxinfo[freeslot("sfx_p_over")].caption = "/"
for i = 0,3
	sfxinfo[freeslot("sfx_p_c"..i)].caption = "/"
end

freeslot("TOL_PAINTGUN")
G_AddGametype({
    name = "Team Paintball",
    identifier = "TURFWAR",
    typeoflevel = TOL_PAINTGUN|TOL_MATCH,
    rules = GTR_SPECTATORS|GTR_TEAMS|GTR_DEATHMATCHSTARTS|GTR_SPAWNINVUL|GTR_RESPAWNDELAY,
    intermissiontype = int_teammatch,
    headercolor = 164,
	description = "Team Deathmatch"
})
G_AddGametype({
    name = "FFA Paintball",
    identifier = "FFATURFWAR",
    typeoflevel = TOL_PAINTGUN|TOL_MATCH,
    rules = GTR_SPECTATORS|GTR_DEATHMATCHSTARTS|GTR_SPAWNINVUL|GTR_RESPAWNDELAY,
    intermissiontype = int_match,
    headercolor = 164,
	description = "Free-for-all"
})
freeslot("TOL_CTFPAINTGUN")
G_AddGametype({
    name = "CTF Paintball",
    identifier = "CTFTURFWAR",
    typeoflevel = TOL_CTFPAINTGUN|TOL_CTF,
    rules = GTR_SPECTATORS|GTR_TEAMS|GTR_TEAMFLAGS|GTR_DEATHMATCHSTARTS|GTR_SPAWNINVUL|GTR_RESPAWNDELAY,
    intermissiontype = int_ctf,
    headercolor = 164,
	description = "Capture the Flag"
})


local gamemode_t = {
	starttime = TurfWar.const.NOTIMER,
	pointlimit = 0,
	allowovertime = false,
	allowpinchmusic = true,
	nohud = false,
}
registerMetatable(gamemode_t)
TurfWar.gamemodes = {}
TurfWar.registerGamemode = function(gt, props)
	Paint.modes[gt] = true
	setmetatable(props, {
		__index = gamemode_t
	})
	TurfWar.gamemodes[gt] = props
end

TurfWar.registerGamemode(GT_TURFWAR, {
	starttime = TurfWar.const.ROUNDTIME
})
TurfWar.registerGamemode(GT_FFATURFWAR, {
	starttime = TurfWar.const.ROUNDTIME
})
TurfWar.registerGamemode(GT_CTFTURFWAR, {
	starttime = 5*60*TR,
	pointlimit = 3,
	allowovertime = true,
	allowpinchmusic = false,
})

TurfWar.HUDS = {
	game = {},
	scores = {}
}

local function dofolder(files)
	for k, file in ipairs(files)
		local func,order = dofile("hud/"..file)
		order = $ or "game"
		if order == "game"
			table.insert(TurfWar.HUDS.game, func)
		elseif order == "scores"
			table.insert(TurfWar.HUDS.scores, func)
		elseif order == "gameandscores"
			table.insert(TurfWar.HUDS.game, func)
			table.insert(TurfWar.HUDS.scores, func)
		end
	end
end
dofolder{
	"flagrunners.lua",
	"oneminute.lua",
	"topinfo.lua",
	"scores.lua",
	"gameset.lua",
	"timer.lua",
	"gamestate_text.lua",
	"countdown.lua",
}

addHook("HUD",function(v,p,c)
	if not (TurfWar and Paint) then return end
	if not Paint:isMode() then return end
	if TurfWar.gamemodes[gametype].nohud then return end
	
	for k, func in ipairs(TurfWar.HUDS.game)
		func(v,p,c)
	end
end,"game")
addHook("HUD",function(v)
	if not (TurfWar and Paint) then return end
	if not Paint:isMode() then return end
	if TurfWar.gamemodes[gametype].nohud then return end
	
	for k, func in ipairs(TurfWar.HUDS.scores)
		func(v)
	end
end,"scores")

local cv_allowmusic = CV_RegisterVar({
	name = "paint_1minutemusic",
	defaultvalue = "Off",
	flags = CV_SHOWMODIF|CV_NETVAR,
	PossibleValue = CV_OnOff
})

local items = {
	score = true,
	time = true,
	rings = true,
	lives = true,
	teamscores = true,
	textspectator = true,
}
addHook("MapChange",function(nextmap)
	if not Paint then return end
	
	if Paint:isMode()
		local color = P_RandomRange(SKINCOLOR_LAVENDER,SKINCOLOR_VOLCANIC)
		skincolor_redteam = color
		skincolor_blueteam = ColorOpposite(color)
		
		local gm = TurfWar.gamemodes[gametype]
		TurfWar.time = gm.starttime
		TurfWar.minutewarning = false
		TurfWar.overtime = false
		
		for item,_ in pairs(items)
			hud.disable(item)
		end
	else
		skincolor_redteam = SKINCOLOR_RED
		skincolor_blueteam = SKINCOLOR_BLUE
		for item,_ in pairs(items)
			hud.enable(item)
		end
	end
end)
addHook("PlayerJoin",function(pnode)
	if not Paint then return end
	if not (consoleplayer and consoleplayer.valid) then return end
	if #consoleplayer ~= pnode then return end
	
	if Paint:isMode()
		for item,_ in pairs(items)
			hud.disable(item)
		end
	else
		for item,_ in pairs(items)
			hud.enable(item)
		end
	end
end)

local typetosfx = {
	["positive"] = sfx_p_pos,
	["negative"] = sfx_p_neg,
	["reset"] = sfx_p_rest,
	["lead"] = sfx_p_led,
}
local function SetMessage(team, pos_text, neg_text)
	TurfWar.messagestate.tics = TurfWar.const.MSG_TIME
	TurfWar.messagestate.team = team
	
	local p = consoleplayer
	if not (p and p.valid) then return end
	local myteam = p.ctfteam
	
	if (myteam == 0 or team == 0)
		TurfWar.messagestate.text = pos_text
		return
	end
	TurfWar.messagestate.text = (myteam == team) and pos_text or neg_text
end
local function StateSound(type, team)
	local p = consoleplayer
	if not (p and p.valid) then return end
	local myteam = p.ctfteam
	
	if team ~= 0
		if myteam ~= 0
			if type == "positive"
			and team ~= myteam
				type = "negative"
			elseif type == "negative"
			and team ~= myteam
				type = "positive"
			end
		elseif type == "negative"
			type = "positive"
		end
	end
	
	local sfx = typetosfx[type]
	S_StartSoundAtVolume(nil, sfx, 255 * 9/10, p)
end

addHook("MobjSpawn",function(f)
	f.color = skincolor_redteam
end,MT_REDFLAG)
addHook("MobjSpawn",function(f)
	f.color = skincolor_blueteam
end,MT_BLUEFLAG)

addHook("MobjSpawn",function(f)
	table.insert(TurfWar.gotflags, f)
end,MT_GOTFLAG)

local function valid(b)
	return (b and b.valid)
end
addHook("ThinkFrame",do
	if not Paint then return end
	if (TurfWar == nil) then return end
	if not Paint:isMode() then return end
	
	local old = TurfWar.old
	
	TurfWar.messagestate.tics = max($-1, 0)
	if (gametyperules & GTR_TEAMFLAGS)
		local a_picked = (redflag == nil)
		local b_picked = (blueflag == nil)
		local gotflags = 0
		for p in players.iterate
			if (p.gotflag & GF_REDFLAG)
				gotflags = $|GF_REDFLAG
			end
			if (p.gotflag & GF_BLUEFLAG)
				gotflags = $|GF_BLUEFLAG
			end
			if gotflags == (GF_REDFLAG|GF_BLUEFLAG)
				break
			end
		end
		
		local setlead = false
		
		if redscore > old.bravoscore
		and (old.alphascore < old.bravoscore)
			StateSound("lead", TurfWar.const.TEAM_ALPHA)
			SetMessage(TurfWar.const.TEAM_ALPHA, "We took the lead!", "We lost the lead!")
			COM_BufInsertText(consoleplayer, 'cecho ""')
			
			setlead = true
		end
		if bluescore > old.alphascore
		and (old.bravoscore < old.alphascore)
			StateSound("lead", TurfWar.const.TEAM_BRAVO)
			SetMessage(TurfWar.const.TEAM_BRAVO, "We took the lead!", "We lost the lead!")
			COM_BufInsertText(consoleplayer, 'cecho ""')
			
			setlead = true
		end
		
		if a_picked and not old.alphaobj_picked
			StateSound("negative", TurfWar.const.TEAM_ALPHA)
			SetMessage(TurfWar.const.TEAM_BRAVO, "We got their flag!", "They got our flag!")
		elseif (not a_picked) and (valid(redflag) and redflag.fuse)
		and old.alphaobj_picked
			StateSound("negative", TurfWar.const.TEAM_BRAVO)
			SetMessage(TurfWar.const.TEAM_ALPHA, "They dropped our flag!", "We dropped their flag!")
		end
		if (not (gotflags & GF_REDFLAG))
		and (valid(redflag) and (redflag.fuse == 1 or redflag.flags2 & MF2_JUSTATTACKED))
			StateSound("reset", 0)
			SetMessage(0, "Flag reset!")
		end
		
		if b_picked and not old.bravoobj_picked
			StateSound("negative", TurfWar.const.TEAM_BRAVO)
			SetMessage(TurfWar.const.TEAM_ALPHA, "We got their flag!", "They got our flag!")
		elseif (not b_picked) and (valid(blueflag) and blueflag.fuse)
		and old.bravoobj_picked
			StateSound("negative", TurfWar.const.TEAM_ALPHA)
			SetMessage(TurfWar.const.TEAM_BRAVO, "They dropped our flag!", "We dropped their flag!")
		end
		if (not (gotflags & GF_BLUEFLAG))
		and (valid(blueflag) and (blueflag.fuse == 1 or blueflag.flags2 & MF2_JUSTATTACKED))
			StateSound("reset", 0)
			SetMessage(0, "Flag reset!")
		end
		
		-- a team scores and DIDNT set the lead
		if not setlead
			-- bravo scores
			if (bluescore > old.bravoscore)
				StateSound("negative", TurfWar.const.TEAM_ALPHA)
				SetMessage(TurfWar.const.TEAM_BRAVO, "We captured their flag!", "They captured our flag!")
				COM_BufInsertText(consoleplayer, 'cecho ""')
			end
			
			-- alpha scores
			if (redscore > old.alphascore)
				StateSound("negative", TurfWar.const.TEAM_BRAVO)
				SetMessage(TurfWar.const.TEAM_ALPHA, "We captured their flag!", "They captured our flag!")
				COM_BufInsertText(consoleplayer, 'cecho ""')
			end
		end
		
		for k,mo in ipairs(TurfWar.gotflags)
			if not (mo and mo.valid)
				table.remove(TurfWar.gotflags, k)
			end
		end
		for k,f in ipairs(TurfWar.gotflags)
			-- ...
			if not (f and f.valid) then
				table.remove(TurfWar.gotflags, k)
				continue
			end
			local frame = (f.frame & FF_FRAMEMASK)
			if (frame == 1)
				f.color = skincolor_redteam
			elseif (frame == 2)
				f.color = skincolor_blueteam
			end
		end
	end
	
	old.alphascore = redscore
	old.bravoscore = bluescore
	
	if (gametyperules & GTR_TEAMFLAGS)
		old.alphaobj_picked = (redflag == nil)
		old.bravoobj_picked = (blueflag == nil)
		if valid(redflag)
			old.alphaobj_special = redflag.flags & MF_SPECIAL
		else
			old.alphaobj_special = -2
		end
		if valid(blueflag)
			old.bravoobj_special = blueflag.flags & MF_SPECIAL
		else
			old.bravoobj_special = -2
		end
	else
		old.alphaobj_picked = false
		old.bravoobj_picked = false
		old.alphaobj_special = -2
		old.bravoobj_special = -2
	end
	
	TurfWar.minutewarning = false
	if TurfWar.gamemodes[gametype].pointlimit
		local limit = TurfWar.gamemodes[gametype].pointlimit
		
		-- in timed gamemodes, force the time to 1 tic so the game over
		-- sequence will start
		if TurfWar.time ~= TurfWar.const.NOTIMER
			if (redscore >= limit or bluescore >= limit)
			and TurfWar.time > 1
				TurfWar.time = 1
			end
		elseif (redscore >= limit or bluescore >= limit)
			G_ExitLevel()
		end
	end
	
	if TurfWar.time ~= TurfWar.const.NOTIMER
		if TurfWar.gamemodes[gametype].allowovertime and G_GametypeHasTeams()
		and (redscore == bluescore)
		and TurfWar.time == 1
			local picked = (redscore ~= 0) and (bluescore ~= 0)
			if old.alphaobj_picked or old.bravoobj_picked
			and not picked
				picked = true
			end
			
			if picked
				TurfWar.overtime = true
				S_StartSound(nil, sfx_p_over)
			end
		end
		if TurfWar.overtime
		and (redscore ~= bluescore)
			TurfWar.overtime = false
			TurfWar.time = 1
		end
		
		for p in players.iterate
			p.realtime = max(TurfWar.time,0)
			
			if TurfWar.time <= 0
			and not TurfWar.overtime
				p.pflags = $|PF_FULLSTASIS
				p.powers[pw_nocontrol] = 4
				p.exiting = 400
			end
		end
		TurfWar.time = $ - 1
		if TurfWar.overtime
			TurfWar.time = max($, 0)
		end
		
		if TurfWar.time == 60*TR
			S_StartSound(nil,sfx_1min)
			TurfWar.minutewarning = true
		elseif TurfWar.time == 30*TR
		and (cv_allowmusic.value == 1 and TurfWar.gamemodes[gametype].allowpinchmusic)
			local mus = "_PINCH"
			S_ChangeMusic(mus,false)
			mapmusname = mus
		elseif TurfWar.time == 0
		and not TurfWar.overtime
			S_StartSound(nil,sfx_lvpass)
			S_StartSound(nil,sfx_nxbump)
			S_StopMusic(consoleplayer)
			mapmusname = ""
		elseif TurfWar.time == TurfWar.const.ENDTIME
			G_ExitLevel()
		end
	elseif (gametyperules & GTR_TIMELIMIT)
	and (timelimit)
		if (timelimit*60*TR) - leveltime == 60*TR
			S_StartSound(nil,sfx_1min)
			TurfWar.minutewarning = true
		end
	end
end)

addHook("NetVars",function(n)
	--TurfWar = n($)
	TurfWar.const = n($)
	TurfWar.time = n($)
	TurfWar.minutewarning = n($)

	TurfWar.old = n($)
	TurfWar.messagestate = n($)
	TurfWar.gotflags = n($)

	TurfWar.gamemodes = n($)
end)

