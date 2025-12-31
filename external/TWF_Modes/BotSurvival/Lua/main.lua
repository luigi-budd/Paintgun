local TR = TICRATE

local debug = false
local function dprint(...)
	if not debug then return end
	print(...)
end

freeslot("TOL_BOTSURVIVAL")
G_AddGametype({
    name = "Bot Survival",
    identifier = "SALMONRUN",
    typeoflevel = TOL_BOTSURVIVAL,
    rules = GTR_DEATHMATCHSTARTS|GTR_SPAWNINVUL|GTR_FRIENDLY,
    intermissiontype = int_coop,
    headercolor = 164,
	description = "Salmon Run"
})

sfxinfo[freeslot("sfx_p_db0")].caption = "/"
sfxinfo[freeslot("sfx_p_db1")].caption = "/"
sfxinfo[freeslot("sfx_p_db2")].caption = "/"
sfxinfo[freeslot("sfx_p_db3")] = {
	flags = SF_TOTALLYSINGLE|SF_NOMULTIPLESOUND,
	caption = "Rescued!"
}
sfxinfo[freeslot("sfx_p_db4")].caption = "Jump"
sfxinfo[freeslot("sfx_p_ge0")].caption = "Token appears"
sfxinfo[freeslot("sfx_p_ge1")].caption = "Token in!"
sfxinfo[freeslot("sfx_p_ge2")].caption = "\x82Quota met!\x80"
sfxinfo[freeslot("sfx_p_boss")].caption = "\x85".."Boss appears!\x80"

freeslot("MT_BOTSURV_SPAWNPOINT")
mobjinfo[MT_BOTSURV_SPAWNPOINT] = {
	doomednum = 14053,
	spawnstate = S_INVISIBLE,
	radius = 16*FU,
	height = 32*FU,
	flags = MF_NOCLIP|MF_NOCLIPTHING|MF_NOCLIPHEIGHT|MF_NOSECTOR|MF_SCENERY|MF_NOBLOCKMAP|MF_NOGRAVITY
}

freeslot("SPR_LFSR", "S_SR_LIFESAVER", "MT_SR_LIFESAVER")
states[S_SR_LIFESAVER] = {
	sprite = SPR_LFSR,
	frame = A|FF_SEMIBRIGHT,
	tics = -1
}
mobjinfo[MT_SR_LIFESAVER] = {
	doomednum = -1,
	spawnstate = S_SR_LIFESAVER,
	painstate = S_SR_LIFESAVER,
	deathstate = S_SR_LIFESAVER,
	radius = 16*FU,
	height = 32*FU,
	flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_SCENERY|MF_NOGRAVITY
}
addHook("MobjThinker",function(mo)
	if not (mo.target and mo.target.valid and mo.target.player and mo.target.player.lifesaver)
		P_RemoveMobj(mo)
		return
	end
	local me = mo.target
	local p = me.player
	
	mo.paint_lifesaver = true
	mo.color = me.color
	mo.shadowscale = me.shadowscale
	P_MoveOrigin(mo, me.x,me.y,me.z)
	
	if not (p.lifesaver_anim)
		mo.flags = $|MF_SHOOTABLE
		mo.takis_flingme = true
	end
end,MT_SR_LIFESAVER)

addHook("ShouldDamage",function(mo, inf,sor, damage)
	if not (mo.target and mo.target.valid and mo.target.player and mo.target.player.lifesaver)
		return
	end
	
	local me = mo.target
	local p = me.player
	
	p.lifesaver_hp = max($ - damage, 0)
	S_StartSound(nil, sfx_pnt_r0, p)
	return false
end,MT_SR_LIFESAVER)

freeslot("MT_SR_MACGUFFIN")
mobjinfo[MT_SR_MACGUFFIN] = {
	doomednum = -1,
	spawnstate = S_TOKEN,
	deathstate = S_SPRK1,
	radius = 20*FU,
	height = 40*FU,
	flags = MF_SPECIAL,
}
local dragmul = FU * 87/100
addHook("MobjThinker",function(mo)
	if not (mo and mo.valid) then return end
	if not (mo.health) then return end
	
	mo.shadowscale = FU*3/4
	mo.renderflags = $|RF_FULLBRIGHT
	local flip = P_MobjFlip(mo)
	if mo.momz*flip <= -5*mo.scale
		mo.flags = $|MF_NOGRAVITY
		mo.momz = -5*mo.scale
	else
		mo.flags = $ &~MF_NOGRAVITY
	end
	
	if (leveltime % 3 == 0)
		local spread = 20
		local sp = P_SpawnMobjFromMobj(mo,
			P_RandomRange(-spread, spread)*FU,
			P_RandomRange(-spread, spread)*FU,
			P_RandomRange(0, spread*6/5)*FU,
			MT_BOXSPARKLE
		)
		sp.renderflags = $|RF_FULLBRIGHT
		P_SetObjectMomZ(sp,P_RandomRange(1,3)*FU)
		sp.colorized = true
		sp.blendmode = AST_ADD
		sp.color = SKINCOLOR_GOLDENROD
	end
	mo.momx = FixedMul($, dragmul)
	mo.momy = FixedMul($, dragmul)
end,MT_SR_MACGUFFIN)
addHook("MobjDeath",function(mo)
	mo.momx,mo.momy,mo.momz = 0,0,0
	mo.shadowscale = 0
	mo.flags = $|MF_NOCLIPTHING|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY
	
	Salmon.roundstatus.eggsin = $ + 1
	if (Salmon.roundstatus.eggsin >= Salmon.roundstatus.quota)
		S_StartSound(nil, sfx_p_ge2)
		Paint.HUD:quotaLight()
	else
		S_StartSound(nil, sfx_p_ge1)
	end
end,MT_SR_MACGUFFIN)

rawset(_G,"Salmon", {})

local playercolors = {
	SKINCOLOR_GALAXY,
	SKINCOLOR_MIDNIGHT,
	SKINCOLOR_PURPLE,
	SKINCOLOR_ROSY,
	SKINCOLOR_FUCHSIA,
	
	SKINCOLOR_ORANGE,
	SKINCOLOR_COPPER,
	SKINCOLOR_TANGERINE,
	
	SKINCOLOR_CERULEAN,
	SKINCOLOR_SAPPHIRE,
	SKINCOLOR_CORNFLOWER,
}

Salmon.playercolor = SKINCOLOR_GALAXY

Salmon.spawnpoints = {}
Salmon.waypoints = {}
Salmon.playerspawns = {}

local STAGE_START	= 1
local STAGE_END		= 2

local ROUND_PREGAME		= 1
local ROUND_GAME		= 2
local ROUND_POSTGAME	= 3
local ROUND_GAMEOVER	= 4
local ROUND_WINGAME		= 5

local INTER_TIME	= 10*TR
local POST_TIME		= 10*TR
local ROUND_TIME	= 100*TR

local HAZARD_START = FU/10
local HAZARD_INCREASE = FU/84
local HAZARD_FRANTIC = HAZARD_START + (HAZARD_INCREASE*4)

local BOSS_ALERT = 4*TR

local MAPSEC_TAG = 5050
local MAPSEC_CLR_TAG = 5051
local DAYTRANS_TIME = 10*TR
local DAYTRANS_STEP = (DAYTRANS_TIME)/255

Salmon.const = {
	STAGE_START	= STAGE_START,
	STAGE_END	= STAGE_END,
	INTER_TIME	= INTER_TIME,
	POST_TIME	= POST_TIME,
	ROUND_TIME	= ROUND_TIME,
	
	HAZARD_START	= HAZARD_START,
	HAZARD_INCREASE	= HAZARD_INCREASE,
	HAZARD_FRANTIC	= HAZARD_FRANTIC,
	
	BOSS_ALERT = BOSS_ALERT,
}

Salmon.roundstatus = {
	intermission = 0,
	roundtime = 0,
	postround = 0,
	
	oldhazard = HAZARD_START,
	hazard = HAZARD_START - HAZARD_INCREASE,
	wavenumber = 0,
	waveclear = false,
	failed = false,
	quota = 0,
	eggsin = 0,
	
	tospawn = 0,
	spawncooldown = 0,
	enemiesspawned = 0,
	carriersspawned = 0,
	bossalert = 0,
	
	to_day = 0,
	to_night = 0,	
}

local function waveSong(hazard, down)
	if hazard >= HAZARD_FRANTIC
		return (down) and "FRAND" or "FRAN"
	else
		return (down) and "WAVED" or "WAVE"
	end
end

-- hardcoded but i dont give a damn
Salmon.day_color = {
	r = 238,
	g = 80,
	b = 0,
	a = 102, -- 10 = 102 somehow
	
	-- fade
	f_r = 10,
	f_g = 11,
	f_b = 25,
	f_a = 255,
	
	l = 200, --sector light
}
Salmon.night_color = {
	r = 33,
	g = 34,
	b = 78,
	a = 255/10,
	
	-- fade
	f_r = 22,
	f_g = 4,
	f_b = 76,
	f_a = 255/13,
	
	l = 150, --sector light
}
Salmon.map_colormap = nil -- extracolormap_t
Salmon.map_sectors = {}

Salmon.setupRound = function(stage)
	local rs = Salmon.roundstatus
	if stage == STAGE_START
		rs.intermission = INTER_TIME
		rs.roundtime = ROUND_TIME
		
		if ((rs.wavenumber % 4)+1) == 2
			rs.to_night = DAYTRANS_TIME
		elseif ((rs.wavenumber % 4)+1) == 4
			rs.to_day = DAYTRANS_TIME
		end
		rs.wavenumber = $ + 1
		
		if not rs.failed
			local overachieve = FU
			if (rs.eggsin >= rs.quota*5/2)
				overachieve = $ + FU * 3/4
			elseif (rs.eggsin >= rs.quota*2)
				overachieve = $ + FU/2
			elseif (rs.eggsin >= rs.quota*3/2)
				overachieve = $ + FU/4
			end
			rs.hazard = min($ + FixedMul(HAZARD_INCREASE, overachieve), FU)
		else
			if rs.hazard > HAZARD_START
				rs.hazard = max($ - HAZARD_INCREASE, HAZARD_START)
			else
				rs.hazard = HAZARD_START - HAZARD_INCREASE
			end
		end
		
		for p in players.iterate
			p.sr_teleported = false
		end
		
		local haz = ease.linear(rs.hazard, HAZARD_START, FU)
		
		dprint(("frac: %f -> %f"):format(rs.hazard, haz))
		local work = FixedMul(70*FU, haz)
		local curve = Salmon.playerCurve()
		if curve ~= FU
			work = FixedMul($, curve)
		end
		rs.quota = max(work/FU, 3)
		rs.eggsin = 0
		
		rs.enemiesspawned = 0
		rs.carriersspawned = 0
		rs.failed = false
	elseif stage == STAGE_END
		for k, mo in ipairs(Paint.enemyList)
			if mo.type == MT_PAINT_ENEMY
				P_RemoveMobj(mo)
			end
		end
		-- lol
		for mobj in mobjs.iterate()
			if mobj.type == MT_SR_MACGUFFIN
				P_RemoveMobj(mobj)
			elseif (mobj.type == MT_PAINT_WALLSPLAT or mobj.type == MT_PAINT_SPLATTER)
			and (mobj.color ~= Salmon.playercolor)
				P_RemoveMobj(mobj)
			end
		end
		
		rs.tospawn = 0
		rs.spawncooldown = 0
		
		rs.postround = POST_TIME
		rs.oldhazard = rs.hazard
		
		dprint("WAVE "..rs.wavenumber.." CLEARED: enemies spawned: "..rs.enemiesspawned.." player count: "..(Salmon.countPlayers().playing))
	end
end

Salmon.resetStatus = function()
	Salmon.roundstatus = {
		intermission = 0,
		roundtime = 0,
		postround = 0,
		
		oldhazard = HAZARD_START,
		hazard = HAZARD_START,
		wavenumber = 0,
		waveclear = false,
		failed = false,
		quota = 0,
		eggsin = 0,
		
		tospawn = 0,
		spawncooldown = 0,
		enemiesspawned = 0,
		carriersspawned = 0,
		bossalert = 0
	}
	Salmon.spawnpoints = {}
	Salmon.waypoints = {}
	Salmon.playerspawns = {}
end

Salmon.countPlayers = function()
	local count = {
		playing = 0,
		alive = 0,
		dead = 0,
		
		total = 0,
		inactive = 0,
	}
	for p in players.iterate
		count.total = $ + 1
		if (p.spectator or p.quittime)
			count.inactive = $ + 1
			continue
		end
		count.playing = $ + 1
		if (p.playerstate == PST_DEAD)
		or (p.lifesaver)
			count.dead = $ + 1
			continue
		end
		count.alive = $ + 1
	end
	return count
end

Salmon.revivePlayer = function(p)
	local me = p.mo
	
	p.lifesaver = false
	p.lifesaver_anim = 0
	p.lifesaver_hp = 0
	
	me.height = P_GetPlayerHeight(p)
	p.jumpfactor = skins[p.skin].jumpfactor
	p.pflags = $ &~(PF_INVIS|PF_GODMODE)
	p.fake_flashing = flashingtics
	
	me.paint_lifesaver = nil
	me.paint_inactive = nil
	
	S_StartSound(me, sfx_p_db3)
end

addHook("MapLoad",do
	if gametype ~= GT_SALMONRUN
		Salmon.resetStatus()
		return
	end
	
	Salmon.map_colormap = nil
	Salmon.map_sectors = {}
	for sector in sectors.tagged(MAPSEC_CLR_TAG)
		local line = sector.lines[0]
		Salmon.map_colormap = P_GetSectorColormapAt(sector,
			line.v1.x,
			line.v1.y,
			sector.floorheight
		)
		break
	end
	for sector in sectors.iterate --tagged(MAPSEC_TAG)
		--if sector.colormap ~= Salmon.map_colormap then continue end
		if not sector.taglist:has(MAPSEC_TAG) then continue end
		table.insert(Salmon.map_sectors, #sector)
	end
	
	Salmon.setupRound(STAGE_START)
	
	Salmon.spawnpoints = {}
	Salmon.waypoints = {}
	Salmon.playerspawns = {}
	
	for mt in mapthings.iterate
		if mt.type == mobjinfo[MT_BOTSURV_SPAWNPOINT].doomednum
			local zpos = R_PointInSubsector(mt.x*FU,mt.y*FU).sector.floorheight
			table.insert(Salmon.spawnpoints,{
				x = mt.x*FU,
				y = mt.y*FU,
				z = zpos + mt.z*FU,
				a = FixedAngle(mt.angle*FU),
				
				tag = mt.tag
			})
		elseif mt.type == mobjinfo[MT_BOSS3WAYPOINT].doomednum
			local zpos = R_PointInSubsector(mt.x*FU,mt.y*FU).sector.floorheight
			table.insert(Salmon.waypoints,{
				x = mt.x*FU,
				y = mt.y*FU,
				z = zpos + mt.z*FU,
				
				tag = mt.tag
			})
		-- these are supposed to be match starts but apparently their types dont match up in uzb
		elseif mt.type == 0
			local zpos = R_PointInSubsector(mt.x*FU,mt.y*FU).sector.floorheight
			table.insert(Salmon.playerspawns,{
				x = mt.x*FU,
				y = mt.y*FU,
				z = zpos + mt.z*FU,
				a = FixedAngle(mt.angle*FU),
			})
		end
	end
	
	Salmon.playercolor = playercolors[P_RandomRange(1, #playercolors)]
end)

Salmon.bossAlert = function()
	S_StartSound(nil, sfx_p_boss)
	Salmon.roundstatus.bossalert = BOSS_ALERT
end

Salmon.playerCurve = function()
	local count = Salmon.countPlayers()
	local frac = FU
	if count.playing < 8
		frac = ease.outquint(FixedDiv(count.playing*FU, 8*FU), 0, FU)
	end
	return frac
end

local old = 0
Salmon.startEnemyWave = function()
	local rs = Salmon.roundstatus
	local spawn = FixedMul(40*FU, rs.hazard)/FU
	
	rs.tospawn = $ + P_RandomRange(max(spawn * 2/3, 1), spawn)
	
	dprint(
		("spawned enemy wave of %d at %d for wave %d (time diff. of %d) (%d on field)"):format(
			rs.tospawn, (ROUND_TIME - rs.roundtime)/TR, rs.wavenumber, (rs.roundtime - old)/TR, #Paint.enemyList
		)
	)
	
	old = rs.roundtime
end

Salmon.spawnEnemy = function()
	if (#Paint.enemyList > 50) then return end
	
	local rs = Salmon.roundstatus
	local spawn = Salmon.spawnpoints[P_RandomRange(1, #Salmon.spawnpoints)]
	local dest
	for k, way_t in ipairs(Salmon.waypoints)
		if way_t.tag == spawn.tag
			dest = way_t
			break
		end
	end
	if dest == nil
		print(("\x82WARNING\x80: Spawnpoint at (%.1f, %.1f) of tag %d has no waypoint tag!"):format(spawn.x,spawn.y, spawn.tag))
		return
	end
	
	local mobj = P_SpawnMobj(spawn.x,spawn.y,spawn.z, MT_PAINT_ENEMY)
	mobj.color = SKINCOLOR_FOREST
	mobj.paint_color = mobj.color
	mobj.angle = spawn.a
	mobj.nerfed = true
	mobj.destination = {x = dest.x, y = dest.y, tag = dest.tag}
	mobj.renderflags = $|RF_SEMIBRIGHT
	
	mobj.paint_maxhp = 75*FU
	mobj.paint_hp = mobj.paint_maxhp
	
	local chance = FU/5
	-- under quota?
	if (rs.carriersspawned*3 <= rs.quota * 7/5)
		chance = FU*12/10 - FixedDiv((rs.carriersspawned*3*FU) or FU, ((rs.quota or 1) * 7/5)*FU)
		if (rs.roundtime <= 40*TR)
			chance = FU
		end
	end
	
	if P_RandomChance(chance)
		mobj.sr_eggcarrier = true
		mobj.color = SKINCOLOR_MASTER
		mobj.paint_color = mobj.color
		
		mobj.scale = $ * 7/5
		
		mobj.paint_maxhp = 430*FU
		mobj.paint_hp = mobj.paint_maxhp
		rs.carriersspawned = $ + 1
		
		Salmon.bossAlert()
	end
	
	rs.enemiesspawned = $ + 1
end

-- just a lerp function now
local function approach(from, to, step)
	if step <= 1
		return to
	end
	return from + (FixedMul((to - from)*FU, FU - FixedDiv(step*FU, DAYTRANS_TIME*FU))/FU)
end

addHook("ThinkFrame",do
	if gamestate ~= GS_LEVEL then return end
	if gametype ~= GT_SALMONRUN then return end
	if (leveltime == 0) then return end
	
	local rs = Salmon.roundstatus
	local player_time = 0
	
	rs.waveclear = false
	local wasfailed = rs.failed
	local state = 0
	local hazard = rs.hazard
	if (rs.intermission ~= 0)
		state = ROUND_PREGAME
		rs.intermission = $ - 1
		
		if (rs.intermission <= 3*TR)
			if rs.intermission % TR == 0
				S_StartSound(nil, (rs.intermission < TR) and sfx_s3kad or sfx_s3ka7)
			end
		end
		
		if mapmusname ~= waveSong(hazard, true)
			if rs.intermission == 5*TR
				S_ChangeMusic(waveSong(hazard), true, nil, 0,0, 5*MUSICRATE, 0)
			elseif rs.intermission == 0
				mapmusname = waveSong(hazard)
			end
		elseif rs.intermission == 0
			S_ChangeMusic(waveSong(hazard), true, nil, 0,S_GetMusicPosition(), 0,0)
			mapmusname = waveSong(hazard)
		end
		
		player_time = rs.intermission
	elseif (rs.roundtime ~= 0)
		state = ROUND_GAME
		rs.roundtime = $ - 1
		
		if (rs.roundtime <= 3*TR)
			if rs.roundtime % TR == 0
			and rs.roundtime > 0
				S_StartSound(nil, sfx_s3ka7)
			end
		end
		
		local interval = FixedDiv((TR*3/2)*FU, rs.hazard)
		dprint("intervals:",
			("base:   %f"):format(FixedDiv(interval, TR*FU))
		)
		
		local curve = Salmon.playerCurve()
		if curve ~= FU
			interval = FixedDiv($, curve)
		end
		dprint("final:   "..(interval / FU)..", "..(interval/FU)/TR)
		
		interval = $ / FU
		if (interval < 1) then interval = 1; end
		if (interval > 30*TR) then interval = 30*TR; end
		if (rs.roundtime % interval == 0)
		or (rs.roundtime == ROUND_TIME - 1)
			Salmon.startEnemyWave()
		end
		
		if rs.tospawn
			if rs.spawncooldown
				rs.spawncooldown = $ - 1
			else
				Salmon.spawnEnemy()
				rs.tospawn = $ - 1
				rs.spawncooldown = 10
			end
		end
		
		if rs.roundtime == 0
			rs.waveclear = true
			if (rs.eggsin >= rs.quota)
				Salmon.setupRound(STAGE_END)
				S_ChangeMusic(waveSong(hazard,true), true, nil, 0,S_GetMusicPosition(), 0,0)
				mapmusname = waveSong(hazard,true)
				S_StartSound(nil, sfx_p_pos)
			else
				rs.failed = true
			end
		end
		
		local count = Salmon.countPlayers()
		if count.dead == count.playing
			rs.failed = true
		end
		
		if rs.failed
			rs.roundtime = 0
			rs.waveclear = true
			
			S_ChangeMusic(waveSong(rs.hazard,true), true, nil, 0,S_GetMusicPosition(), 0,0)
			mapmusname = waveSong(rs.hazard,true)
			S_StartSound(nil, sfx_p_neg)
			
			Salmon.setupRound(STAGE_END)
		end
		if rs.waveclear
			rs.tospawn = 0
			rs.spawncooldown = 0
		end
		player_time = rs.roundtime
	elseif (rs.postround ~= 0)
		state = ROUND_POSTGAME
		rs.postround = $ - 1
		
		Paint.HUD.memory.killtags = {}
		
		local count = Salmon.countPlayers()
		local teleported = 0
		if rs.postround <= POST_TIME - 6*TR
		and (#Salmon.playerspawns > 0)
			local tlen = #Salmon.playerspawns
			for p in players.iterate
				if (p.playerstate ~= PST_LIVE) then continue end
				if (p.lifesaver and p.lifesaver_anim) then continue end
				if p.sr_teleported then teleported = $ + 1; continue end
				
				local index = ((#p + rs.wavenumber) % tlen) + 1
				local spawn = Salmon.playerspawns[index]
				
				local me = p.realmo
				me.momx,me.momy,me.momz = 0,0,0
				P_SetOrigin(me, spawn.x,spawn.y,spawn.z)
				me.angle = spawn.a
				p.drawangle = spawn.a
				p.paint.anglestand = spawn.a
				p.cmd.angleturn = spawn.a >> 16
				if P_IsLocalPlayer(p)
					P_ResetCamera(p,camera)
				end
				if (p.lifesaver)
					Salmon.revivePlayer(p)
				end
				P_ResetPlayer(p)
				
				me.reactiontime = TR/2
				me.state = S_PLAY_STND
				P_FlashPal(p, PAL_MIXUP, 10)
				S_StartSound(me,sfx_mixup,p)
				p.sr_teleported = true
				p.paint.inktank = 100*FU
			end
			if teleported ~= count.playing
				rs.postround = max($, TR)
			end
			if rs.postround == 0
				Salmon.setupRound(STAGE_START)
			end
		end
	end
	
	if state ~= ROUND_GAME
		for k, mo in ipairs(Paint.enemyList)
			if not (mo and mo.valid) then continue end
			if mo.type == MT_PAINT_ENEMY
				P_RemoveMobj(mo)
			end
		end
	end
	
	for p in players.iterate
		p.realtime = player_time
	end
	
	if rs.bossalert
		rs.bossalert = $ - 1
	end
	
	if rs.to_day
	and (Salmon.map_colormap)
	and (#Salmon.map_sectors)
		local t = Salmon.day_color
		local n = Salmon.night_color
		local clr = Salmon.map_colormap
		
		for _, secnum in ipairs(Salmon.map_sectors)
			sectors[secnum].lightlevel = approach(n.l, t.l, rs.to_day)
		end
		
		clr.red			= approach(n.r, t.r,   rs.to_day)
		clr.green		= approach(n.g, t.g,   rs.to_day)
		clr.blue		= approach(n.b, t.b,   rs.to_day)
		clr.alpha		= approach(n.a, t.a,   rs.to_day)
		
		clr.fade_red	= approach(n.f_r, t.f_r, rs.to_day)
		clr.fade_green	= approach(n.f_g, t.f_g, rs.to_day)
		clr.fade_blue	= approach(n.f_b, t.f_b, rs.to_day)
		clr.fade_alpha	= approach(n.f_a, t.f_a, rs.to_day)
		
		rs.to_day = $ - 1
	end
	if rs.to_night
	and (Salmon.map_colormap)
	and (#Salmon.map_sectors)
		local n = Salmon.day_color
		local t = Salmon.night_color
		local clr = Salmon.map_colormap
		
		for _, secnum in ipairs(Salmon.map_sectors)
			sectors[secnum].lightlevel = approach(n.l, t.l, rs.to_night)
		end
		
		clr.red			= approach(n.r, t.r,   rs.to_night)
		clr.green		= approach(n.g, t.g,   rs.to_night)
		clr.blue		= approach(n.b, t.b,   rs.to_night)
		clr.alpha		= approach(n.a, t.a,   rs.to_night)
		
		clr.fade_red	= approach(n.f_r, t.f_r, rs.to_night)
		clr.fade_green	= approach(n.f_g, t.f_g, rs.to_night)
		clr.fade_blue	= approach(n.f_b, t.f_b, rs.to_night)
		clr.fade_alpha	= approach(n.f_a, t.f_a, rs.to_night)
		
		rs.to_night = $ - 1
	end
end)

local WATER_TIME = 3*TR
local WATER_ANIM = TR/2

local DEAD_TIME = 5*TR + (TR/2)
local DEAD_ANIM = TR*3/2

local function makeBlob(p,me,pt, rad,hei)
	local blob = P_SpawnMobjFromMobj(me,
		P_RandomRange(-rad,rad)*FU,
		P_RandomRange(-rad,rad)*FU,
		P_RandomRange(0,hei)*FU,
		MT_PARTICLE
	)
	P_SetMobjStateNF(blob, S_GOOP1)
	blob.sprite = SPR_PAINT_MISC
	blob.frame = 15
	
	blob.tics = -1
	blob.fuse = TR*3/4
	
	blob.color = Paint:getPlayerColor(p)
	return blob
end

-- you stay dead for 5.5 seconds total, 1.5 seconds are spent for the lifesaver animation
addHook("PlayerThink",function(p)
	local me = p.mo
	if not (me and me.valid) then return end
	if gametype ~= GT_SALMONRUN then return end
	
	local pt = p.paint
	
	p.skincolor = Salmon.playercolor
	me.color = Salmon.playercolor
	me.renderflags = $|RF_SEMIBRIGHT
	
	if me.deathtimer == nil
		me.deathtimer = 0
		
		-- we probably just spawned
		local teammates = {}
		for play in players.iterate
			table.insert(teammates, play)
		end
		for play in players.iterate
			play.paint.teammates = teammates
		end
	end
	
	if (p.playerstate == PST_DEAD)
		if me.deathtimer == 0
			p.deathpos = {x = me.x, y = me.y, z = me.z}
		end
		me.deathtimer = $ + 1
		p.sr_teleported = false
		p.jumpfactor = 0
		
		if me.deathtimer >= 2*TR + TR/2
			me.paint_overlayhp = FixedCeil(ease.linear(FU/2, $, 100*FU))
		end
		
		if me.deathtimer == DEAD_TIME - DEAD_ANIM
			local pos = me.groundpos
			if pos == nil
				if (#Salmon.playerspawns > 0)
					local index = (#p % #Salmon.playerspawns) + 1
					local spawn = Salmon.playerspawns[index]
					pos = {x = spawn.x, y = spawn.y, z = spawn.z}
				else -- ur fucked
					pos = {x = 0, y = 0, z = 0}
				end
			end
			
			G_DoReborn(#p)
			me = p.mo
			P_SetOrigin(me,
				pos.x,
				pos.y,
				pos.z
			)
			p.cmd.angleturn = me.angle >> 16
			p.cmd.aiming = 0
			p.aiming = 0
			if P_IsLocalPlayer(p)
				P_ResetCamera(p, camera)
			end
			me.paint_inactive = true
			
			p.powers[pw_flashing] = 0
			me.state = S_PLAY_STND
			P_MovePlayer(p)
			P_ResetPlayer(p)
			p.pflags = $|(PF_INVIS|PF_GODMODE|PF_FULLSTASIS)
			S_StartSound(me, sfx_p_db2)
			
			me.angle = pos.a
			p.drawangle = me.angle
			pt.anglestand = me.angle
			me.paint_lifesaver = true
			p.lifesaver = true
			p.lifesaver_hp = 40*FU
			p.lifesaver_anim = DEAD_ANIM
			p.paint.hp = 100*FU
			
			me.lifesaver_mo = P_SpawnMobjFromMobj(me,0,0,0,MT_SR_LIFESAVER)
			me.lifesaver_mo.target = me
			me.lifesaver_mo.rollangle = ANGLE_180
			me.lifesaver_mo.colorized = true
			me.lifesaver_mo.paint_explodebombs = true
		else
			p.deadtimer = 0
		end
	else
		me.paint_overlayhp = p.paint.hp
	end
	
	if p.lifesaver_anim
		p.lifesaver_anim = $ - 1
		
		local ls = me.lifesaver_mo
		if (ls and ls.valid)
			local frac = (FU/DEAD_ANIM)
			local tic = DEAD_ANIM - p.lifesaver_anim
			local anim = ease.inexpo(frac*tic, 0, FU)
			ls.rollangle = FixedAngle( ease.outback(anim, 180*FU, 0, FU*6/5) )
		end
		
		p.pflags = $|PF_FULLSTASIS
		if p.lifesaver_anim == 0
			p.lifesaver_anim = nil
			
			local rad = FixedDiv(me.radius,me.scale)/FU
			local hei = FixedDiv(me.height,me.scale)/FU
			for i = 0,15
				local blob = makeBlob(p,me,pt, rad,hei)
				local ang = R_PointToAngle2(blob.x,blob.y, me.x,me.y)
				P_SetObjectMomZ(blob, P_RandomRange(2,6)*FU)
				P_Thrust(blob,ang, -P_RandomRange(1,3)*me.scale)
				blob.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT &~(MF_NOGRAVITY)
				blob.destscale = 0
				blob.scalespeed = FixedDiv(blob.scale, blob.fuse*FU)
			end
			if (ls and ls.valid)
				ls.colorized = false
			end
		end
	end
	
	if p.lifesaver
		p.normalspeed = 5*FU
		p.jumpfactor = FU/2
		p.charability = CA_NONE
		p.charability2 = CA2_NONE
		
		me.height = FixedMul(Paint.SQUID_HEIGHT, me.scale)
		me.flags2 = $|MF2_DONTDRAW
		
		if S_SoundPlaying(me, skins[p.skin].soundsid[SKSJUMP])
			S_StopSoundByID(me, skins[p.skin].soundsid[SKSJUMP])
			S_StartSound(me, sfx_p_db4)
		end
		
		local ls = me.lifesaver_mo
		if (ls and ls.valid and not p.lifesaver_anim)
			ls.threshold = $ + 1
			ls.rollangle = FixedAngle(5 * sin(FixedAngle(ls.threshold * FU * 4)))
		end
		if not me.deathtimer
			p.deathpos = {x = me.x, y = me.y, z = me.z}
		end
		
		if p.lifesaver_hp <= 0
			Salmon.revivePlayer(p)
		end
	end
	
	if p.fake_flashing
		p.powers[pw_flashing] = p.fake_flashing
		p.fake_flashing = $ - 1
		
		if (p.fake_flashing % 3 == 0)
			local spread = 10
			local sp = P_SpawnMobjFromMobj(me,
				P_RandomRange(-spread, spread)*FU,
				P_RandomRange(-spread, spread)*FU,
				P_RandomRange(0, spread*2)*FU,
				MT_IVSP
			)
			sp.color = P_RandomRange(SKINCOLOR_AETHER,SKINCOLOR_VOLCANIC)
			sp.colorized = true
			sp.blendmode = AST_ADD
			
			sp.frame = $ + (flashingtics - p.fake_flashing)/3
			sp.destscale = 0
			sp.scalespeed = FixedDiv(sp.scale, sp.tics*FU)
			P_SetObjectMomZ(sp, 3*FU)
		end
	elseif p.powers[pw_flashing] == 1
		p.powers[pw_flashing] = 0
	end
	
	if (me.health)
	and P_IsObjectOnGround(me)
	and not (me.eflags & MFE_TOUCHWATER)
		me.groundpos = {
			x = me.x,
			y = me.y,
			z = me.floorz,
			a = p.cmd.angleturn << 16
		}
	end
	
	if me.health
	and (me.eflags & MFE_UNDERWATER)
		S_StartSound(me, sfx_p_db0)
		me.waterdeath = 3*TR
		me.waterheight = me.z
		me.oldwatertop = me.watertop
		me.watermomz = 0
		me.wateradjust = -16*me.scale + (me.momz * 2)
		me.paint_nopainoverlay = true
		
		Paint.HUD:killNotice(p)
		
		local bubbles = FixedDiv(abs(me.wateradjust)/4, me.scale)>>(FRACBITS-1)
		if bubbles > 128
			bubbles = 128
		end
		local dist = FixedDiv(me.radius, me.scale) + 3*FU
		for i = 0, bubbles
			local ang = FixedAngle(P_RandomRange(0, 360)*FU)
			local bub = P_SpawnMobjFromMobj(me,
				P_ReturnThrustX(nil, ang, dist),
				P_ReturnThrustY(nil, ang, dist),
				0, MT_PARTICLE
			)
			bub.z = me.oldwatertop
			bub.scale = $ * 2
			P_SetMobjStateNF(bub, mobjinfo[MT_MEDIUMBUBBLE].spawnstate)
			bub.tics = -1
			bub.fuse = 3*TR
			bub.flags = $ &~MF_NOGRAVITY
			bub.momz = 2*bub.scale + FixedMul(abs(me.wateradjust)/6, P_RandomFixed())
			P_Thrust(bub, ang, me.scale + FixedMul(3*me.scale, P_RandomFixed()))
		end
		
		me.momx,me.momy,me.momz = 0,0,0
		me.health = 0
		p.playerstate = PST_DEAD
	end
	
	if (me.waterdeath ~= nil)
		if me.state ~= S_PLAY_DRWN
			me.state = S_PLAY_DRWN
		end
		me.fuse = 3*TR
		me.flags = $|MF_NOCLIPHEIGHT
		me.flags2 = $ &~MF2_DONTDRAW
		me.waterdeath = $ - 1
		
		me.momx,me.momy,me.momz = 0,0,0
		me.z = (me.oldwatertop - (me.height/2))
		
		if p.lifesaver
			me.watermomz = $ - me.scale/3
			me.oldwatertop = $ + me.watermomz
			me.z = $ + me.wateradjust
			me.flags2 = $|MF2_DONTDRAW
			return
		end
		
		if me.waterdeath > WATER_TIME - WATER_ANIM
			local tics = WATER_ANIM - (me.waterdeath - (WATER_TIME - WATER_ANIM))
			
			local frac = FixedDiv(tics*FU, WATER_ANIM*FU)
			me.z = $ + ease.inquad(frac, me.wateradjust, 0)
		end
		
		me.spriteyoffset = 2 * sin(FixedAngle(leveltime*FU*50))
		if me.waterdeath <= 2*TR
			if me.waterdeath == 2*TR
				S_StartSound(me, sfx_p_db1)
				if (P_IsLocalPlayer(p))
					P_StartQuake(10*FU, 10)
				end
				
				local deathcolor = Paint:getPlayerColor(p)
				for i = 0,30
					local angle = FixedAngle(P_RandomFixedRange(0,360))
					local drop = P_SpawnMobjFromMobj(me,0,0,FU, MT_PAINT_SHOT)
					if drop and drop.valid
						drop.target = me
						drop.angle = angle
						drop.color = deathcolor
						drop.trail = true
						drop.lifespan = 0
						drop.flags = $|MF_NOCLIPTHING &~MF_NOGRAVITY
						drop.tracer_player = sorp
						drop.fuse = 2 * TR
						P_SetObjectMomZ(drop, P_RandomFixedRange(1,17))
						P_Thrust(drop, angle, P_RandomFixedRange(1,17))
					end
				end
				local spr_scale = FU * 2
				local tntstate = S_TNTBARREL_EXPL3
				local rflags = RF_FULLBRIGHT|RF_NOCOLORMAPS
				local bam = P_SpawnMobjFromMobj(me, 0,0,0, MT_THOK)
				P_SetMobjStateNF(bam, tntstate)
				bam.spritexscale = FixedMul($, spr_scale)
				bam.spriteyscale = bam.spritexscale
				bam.renderflags = $|rflags
				bam.blendmode = AST_ADD
				bam.colorized = true
				bam.color = deathcolor
				local t = P_SpawnMobjFromMobj(me,0,0,0,MT_THOK)
				t.color = deathcolor
				t.spritexscale = FU * 3
				t.spriteyscale = t.spritexscale
				
				for i = 0,2
					local outline = P_SpawnMobjFromMobj(me, 0,0,0, MT_PAINT_SHOT)
					outline.visualfadestupidshit = true
					outline.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOCLIPTHING
					outline.fuse = 9
					outline.radius = 40*me.scale
					outline.sprite = SPR_PAINT_MISC
					outline.frame = ($ &~FF_FRAMEMASK)|18
					outline.spritexscale = FU * 3
					outline.spriteyscale = outline.spritexscale
					outline.renderflags = $|rflags|RF_PAPERSPRITE|RF_NOSPLATBILLBOARD
					outline.blendmode = AST_ADD
					outline.colorized = true
					outline.color = deathcolor
					outline.angle = me.angle + (ANGLE_90 * i)
					if i == 2
						outline.renderflags = $|RF_FLOORSPRITE &~RF_PAPERSPRITE
					end
				end
			end
			me.flags2 = $|MF2_DONTDRAW
		else
			local ang = FixedAngle(P_RandomRange(0, 360)*FU)
			local dist = FixedDiv(me.radius, me.scale) + 3*FU
			if (leveltime % 3 == 0)
				local splash = P_SpawnMobjFromMobj(me,
					P_ReturnThrustX(nil, ang, dist),
					P_ReturnThrustY(nil, ang, dist),
					0, MT_SPLISH
				)
				splash.z = me.oldwatertop
			end
			local bub = P_SpawnMobjFromMobj(me,
				P_ReturnThrustX(nil, ang, dist),
				P_ReturnThrustY(nil, ang, dist),
				0, MT_PARTICLE
			)
			bub.z = me.oldwatertop
			bub.scale = $ * 2
			P_SetMobjStateNF(bub, mobjinfo[MT_SMALLBUBBLE].spawnstate)
			bub.tics = -1
			bub.fuse = TR
			bub.flags = $ &~MF_NOGRAVITY
			bub.momz = 2*bub.scale + FixedMul(P_RandomRange(0, 3)*bub.scale, P_RandomFixed())
			P_Thrust(bub, ang, me.scale + FixedMul(P_RandomRange(0, 2)*me.scale, P_RandomFixed()))
		end
	end
end)

addHook("MobjDeath",function(mo)
	if not mo.sr_eggcarrier then return end
	
	local sfx = P_SpawnGhostMobj(mo)
	sfx.flags2 = $|MF2_DONTDRAW
	sfx.fuse = 3 * TR
	
	for i = 0,2
		local ang = FixedAngle(120*FU * i)
		local egg = P_SpawnMobjFromMobj(mo, 0,0,0, MT_SR_MACGUFFIN)
		egg.scale = FU
		P_SetObjectMomZ(egg, 12*FU)
		P_Thrust(egg, ang, 5 * egg.scale)
	end
	S_StartSound(sfx, sfx_p_ge0)
end,MT_PAINT_ENEMY)

addHook("NetVars",function(n)
	Salmon.spawnpoints = n($)
	Salmon.waypoints = n($)
	Salmon.playerspawns = n($)
	Salmon.playercolor = n($)
	Salmon.roundstatus = n($)
	Salmon.map_colormap = n($)
	Salmon.map_sectors = n($)
end)

TurfWar.registerGamemode(GT_SALMONRUN, {
	starttime = TurfWar.const.NOTIMER,
	nohud = true,
})

/*
local items = {
	score = true,
	time = true,
	rings = true,
	lives = true,
	teamscores = true,
	textspectator = true,
}
addHook("MapChange",function(nextmap)
	if (gametype == GT_SALMONRUN)
		for item,_ in pairs(items)
			hud.disable(item)
		end
	else
		for item,_ in pairs(items)
			hud.enable(item)
		end
	end
end)
addHook("PlayerJoin",function(pnode)
	if not Paint then return end
	if not (consoleplayer and consoleplayer.valid) then return end
	if #consoleplayer ~= pnode then return end
	
	if (gametype == GT_SALMONRUN)
		for item,_ in pairs(items)
			hud.disable(item)
		end
	else
		for item,_ in pairs(items)
			hud.enable(item)
		end
	end
end)
*/

local hudfiles = {
	"revives",
	"wipe",
	"timer",
	"roundclear",
	"wavestart",
	"debug"
}
for k, name in ipairs(hudfiles)
	dofile("hud/"..name..".lua")
end