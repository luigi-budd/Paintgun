--hitmarker
local hitmarker_attribs = {
	caption = "/",
	priority = 100 
}
local hitmarker_prefix = {
	[1] = "h", -- Hitmarker
	[2] = "n", -- N for Nullified
	[3] = "s", -- S for Shield hit
}
for j = 1, 3
	local pre = hitmarker_prefix[j]
	for i = 0,5
		sfxinfo[freeslot("sfx_pnt_"..pre..i)] = hitmarker_attribs
	end
end

-- Nozzlenose/reeflux crit sound
sfxinfo[freeslot("sfx_pnt_h6")] = hitmarker_attribs

-- Revive shot
sfxinfo[freeslot("sfx_pnt_r0")] = hitmarker_attribs

for i = 0,2
	sfxinfo[freeslot("sfx_pt_ow"..i)].caption = "/"
end
sfxinfo[sfx_pt_ow1].flags = SF_X2AWAYSOUND|SF_TOTALLYSINGLE

sfxinfo[freeslot("sfx_pt_al")].caption = "\x85".."Armor lost!\x80"
sfxinfo[freeslot("sfx_pt_ag")].caption = "\x82".."Armor get!\x80"

--sorry that these are all wavs
for i = 0,12
	-- 0 - 8: floor splat sounds
	-- 9 - 12: wall/object collision splat sounds 
	sfxinfo[freeslot("sfx_p_sp"..i)] = {
		caption = "Splatter",
		flags = SF_NOINTERRUPT
	}
end
sfxinfo[freeslot("sfx_pt_noi")].caption = "Low ink!"
sfxinfo[freeslot("sfx_pt_sig")].caption = "Signal"
sfxinfo[freeslot("sfx_pt_srd")].caption = "Sub ready!"
sfxinfo[freeslot("sfx_pt_ctv")].caption = "/" -- center view

sfxinfo[freeslot("sfx_pt_toh")].caption = "/"
sfxinfo[freeslot("sfx_pt_tos")].caption = "/"
sfxinfo[freeslot("sfx_pt_swm")].caption = "Swimming"
sfxinfo[freeslot("sfx_pt_kth")].caption = "/" -- charge restore
sfxinfo[freeslot("sfx_pt_ijm")].caption = "/" -- charge restore

sfxinfo[freeslot("sfx_pwip_a")].caption = "\x82Wipeout!\x80"
sfxinfo[freeslot("sfx_pwip_d")].caption = "\x8FWipeout!\x80"

--srb2 edit flags
rawset(_G, "MFE_NOPITCHROLLEASING", MFE_NOPITCHROLLEASING or (1<<14))
rawset(_G, "RF_ALWAYSONTOP", RF_ALWAYSONTOP or 0x00010000)
rawset(_G, "RF_HIDEINSKYBOX", RF_HIDEINSKYBOX or 0x00020000)
rawset(_G, "RF_NOMODEL", RF_NOMODEL or 0x00040000)
rawset(_G, "TR", TICRATE)

rawset(_G,"Paint",{})

Paint.wipeouttic = -1
Paint.alphateam = {}
Paint.bravoteam = {}
addHook("ThinkFrame",do
	for k,play in ipairs(Paint.alphateam)
		if not (play and play.valid)
			table.remove(Paint.alphateam, k)
		end
	end
	for k,play in ipairs(Paint.bravoteam)
		if not (play and play.valid)
			table.remove(Paint.bravoteam, k)
		end
	end
end)

function Paint:setTeammates()
	if (gametype == GT_COOP)
		local player_list = {}
		for play in players.iterate
			if play.spectator then continue end
			if not play.paint then continue end
			if not (play.mo and play.mo.valid and play.mo.health) then continue end
			table.insert(player_list, play)
		end
		for k,play in ipairs(player_list)
			play.paint.teammates = player_list
		end
		
		return
	end
	if not G_GametypeHasTeams() then return end
	
	--We iterate everyone in this func so
	--every player doesnt iterate everyone again...
	local redteam,blueteam = {},{}
	local counted = {}
	
	for play in players.iterate
		if play.spectator then continue end
		if not play.paint then continue end
		if not (play.mo and play.mo.valid and play.mo.health) then continue end
		if play.ctfteam == 1
			table.insert(redteam, play)
		else
			table.insert(blueteam, play)
		end
		table.insert(counted,play)
	end
	
	--Then, we iterate everyone (again) and
	--set their teammates field
	--Note that the tables are not shallow copied!
	for k,play in ipairs(counted)
		if play.ctfteam == 1
			play.paint.teammates = redteam
		else
			play.paint.teammates = blueteam
		end		
	end
	Paint.alphateam = redteam
	Paint.bravoteam = blueteam
	
	--Then, the displayplayer iterates through their teammates
	--and spawns team markers
end
function Paint:countTeams()
	local count = {alpha = 0, bravo = 0}
	if not G_GametypeHasTeams() then return count; end

	for play in players.iterate
		if play.spectator then continue end
		if not play.paint then continue end
		if play.ctfteam == 1
			count.alpha = $ + 1
		else
			count.bravo = $ + 1
		end
	end
	return count
end

-- TODO:
function Paint:teamSound(p, mysfx, teamsfx, othersfx)
	
end

function Paint:initPlayer(p)
	p.paint = {
		player = p,
		
		weapon_id = "",
		weaponmobj = nil,
		weaponmobjdupe = nil, -- for dualies
		
		forwardmove = 0, sidemove = 0,buttons = 0,
		-- fixed varients of forward/sidemoves for sub stuff
		fixed_fmove = 0, fixed_smove = 0,
		
		-- cant perform any of these actions if true
		-- all reset the next tic
		disable = {
			main = false,
			sub = false,
			inktank = false,
			swimming = false,
		},
		wasdisabled = {
			main = false,
			sub = false,
			inktank = false,
			swimming = false,
		},
		
		jumpheld = 0,
		spinheld = 0,
		fireheld = 0,
		firewait = 0,
		justfired = false,
		nofiring = false,
		cooldown = 0,
		
		-- percentage
		-- this is added to `wep.spread_base`, and is capped to `wep.spread_max - wep.spread_base`
		spread = 0,
		spreadcooldown = 0, -- wait this many tics before decreasing spreadchance
		spreadadd = 0, -- used for jump inaccuracy
		spreadjump = 0,
		
		charge = 0, -- in fixed_t
		chargetics = 0, -- how many tics we've been charging, slowdowns do NOT apply
		storedcharge = 0,
		store_time = 0,
		store_lag = 0,
		store_firelag = 0,
		store_aura = nil,
		maxcharged = false,
		justcharged = true,
		wasfastcharging = false,
		
		shotsfired = 0, -- for dualies
		turretmode = false, -- for dualies
		dodgeroll = {
			startx = 0,	starty = 0,
			destx = 0,	desty = 0,
			oldx = 0,	oldy = 0,
			momx = 0,	momy = 0, -- for ending the dodge
			
			tics = 0,
			getup = 0,
			count = 0, -- how many have we performed?
			leave = 0, -- count UP when we want to exit turret
		}, -- also for dualies
		
		-- substuff
		aimingsub = false,
		aimingtime = 0,
		substrafe = 0,
		fovadd = 0,
		justrestored = false,
		
		endlag = 0,
		anglefix = 0,
		anglestand = (p.realmo and p.realmo.valid) and (p.realmo.angle) or p.cmd.angleturn << 16,
		angdiff = 0,
		lastslowdown = false,
		holsteranim = 0,
		weaponzoffset = 0,
		prevangle = (p.realmo and p.realmo.valid) and (p.realmo.angle) or p.cmd.angleturn << 16, -- last angle for slow turning
		doslowturn = false,
		slowturning = false,
		
		-- brella stuff
		shield = nil, -- shield mobj for brellas
		shieldwait = 0, -- dont deploy for this long
		shieldlag = Paint.CANOPY_ANIM, -- keep deployed for this long
		shieldregen = 0, -- timer until regen
		shieldtime = 0, -- timer until canopy release
		shieldlost = false, -- lost is only used when you shoot off the canopy, not when it is destroyed
		shieldlosttime = 0,
		deployshield = false,
		wasdeployed = false,
		shieldjustbroke = false, -- ugh
		shieldjustregened = false,
		firequeued = false, -- pressing fire again shortly after a tapfire will queue another shot up
		
		oldinktank = 100*FU,
		oldinkanim = 100*FU,
		inktank = 100*FU,
		inkqueue = 0, -- for charger animation
		maxinkdelay = 0,
		inkdelay = 0, -- delay before restoring ink
		tankmobj = nil,
		fastrefill = false,
		
		inventory = {
			items = {},
			curslot = 1,
			slots = 6,
		},
		
		hp = 100*FU,
		hurtat = {}, -- leveltime indices for capping damage for certain guntypes
		hurttic = 0,
		timetoheal = 0,
		-- SP armor, set brokenarmor to false when armorregen == 0
		brokenarmor = false,
		armorregen = 0, 
		--
		inink = 0, -- 0 = not in ink, -1 = friendly ink, 1 = enemy ink
		inktime = 0,
		inkleveltime = 0, -- dont set inink multiple times a tic
		wallink = 0, -- touching wall ink
		wasclimbing = false,
		
		squidtime = 0,
		squidanim = 0,
		squidlag = 0,
		squidtoggle = false,
		hidden = false,
		wasinsquid = 0,
		
		signaltime = 0,
		signaltype = 0,
		
		paintoverlay = nil,
		teammates = nil,
		
		hitlist = {},
		hittime = 0,
		
		active = true,
		
		-- Make sure these match weapon.callbacks
		calledbacks = {
			onfire = false,
		},
	}
	Paint:setTeammates()
end

function Paint:resetPlayer(p)
	local pt = p.paint
	pt.timetoheal = 0
	pt.hp = 100*FU
	pt.hurtat = {}
	pt.brokenarmor = false
	pt.armorregen = 0
	pt.oldinktank = 100*FU
	pt.oldtankanim = 100*FU
	pt.inktank = 100*FU
	pt.inkdelay = 0
	pt.maxinkdelay = 0
	pt.inink = 0
	
	pt.charge = 0
	pt.maxcharged = false
	pt.justcharged = false
	pt.nofiring = false
	pt.fireheld = 0
	pt.firewait = 0
	pt.endlag = 0
	p.cmd.buttons = $ &~BT_ATTACK
	pt.shotsfired = 0
	pt.anglestand = (p.realmo and p.realmo.valid) and p.realmo.angle or p.cmd.angleturn << 16
	pt.prevangle = (p.realmo and p.realmo.valid) and (p.realmo.angle) or p.cmd.angleturn << 16
	pt.holsteranim = 0
	pt.shieldlag = 0
	pt.shieldwait = 0
	pt.deployshield = false
	pt.shieldjustbroke = false
	pt.firequeued = false
	
	pt.spread = 0
	pt.spreadcooldown = 0
	pt.spreadadd = 0
	pt.spreadjump = 0
	
	pt.turretmode = false
	pt.dodgeroll.tics = 0
	pt.dodgeroll.getup = 0
	pt.dodgeroll.count = 0
	pt.dodgeroll.leave = 0
	
	pt.squidtime = 0
	pt.squidanim = 0
	pt.squidlag = 0
	
	pt.teammates = nil
	Paint:setTeammates()
end

Paint.modes = {
	--[GT_GAMETYPE] = true
}
function Paint:isMode()
	return Paint.modes[gametype] == true
end

-- constants
Paint.ININK_FRIENDLY = -1
Paint.ININK_ENEMY = 1
Paint.MAX_HOLSTER = 5
Paint.SQUID_HEIGHT = 25*FU
Paint.CANOPY_ANIM = 6
Paint.IDLE_OFFSET = -13*FU

Paint.SIGNAL_TIME = 3*TR
Paint.SIGNAL_BOOYAH		= 1
Paint.SIGNAL_THISWAY	= 2
Paint.SIGNAL_OUCH		= 3
Paint.SIGNAL_HELP		= 4

-- distance-unit 2 fracunit scale factor
-- .35 du = 16 fu (player radii)
-- 45.714 is the scale factor cause, of math reasons :think:
-- multiply 1.71428 to get 1/60 -> 1/35
Paint.DU2FU = 46*FU

dofile("cvars/main.lua")
dofile("lib/lib.lua")
dofile("weapons/main.lua")
dofile("weapons/player.lua")
dofile("hud/main.lua")
dofile("auxiliary.lua")
dofile("enemy.lua")

addHook("NetVars",function(n)
	Paint.modes = n($)
	Paint.alphateam = n($)
	Paint.bravoteam = n($)
	Paint.wipeouttic = n($)
end)
