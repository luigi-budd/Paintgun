--hitmarker
for i = 0,5
	sfxinfo[freeslot("sfx_pnt_h"..i)].caption = "/"
end
for i = 0,5
	sfxinfo[freeslot("sfx_pnt_n"..i)].caption = "/" -- N for Nullified
end
for i = 0,3
	sfxinfo[freeslot("sfx_pt_ow"..i)].caption = "/"
end
sfxinfo[sfx_pt_ow1].flags = SF_X2AWAYSOUND|SF_TOTALLYSINGLE
sfxinfo[sfx_pt_ow3].caption = "Shield lost!"

--sorry that these are all wavs
for i = 0,8
	sfxinfo[freeslot("sfx_pn_sp"..i)].caption = "Splatter"
end
sfxinfo[freeslot("sfx_pt_noi")].caption = "Low ink!"

sfxinfo[freeslot("sfx_pt_toh")].caption = "/"
sfxinfo[freeslot("sfx_pt_tos")].caption = "/"
sfxinfo[freeslot("sfx_pt_swm")].caption = "Swimming"

--srb2 edit flags
rawset(_G, "MFE_NOPITCHROLLEASING", MFE_NOPITCHROLLEASING or (1<<14))
rawset(_G, "RF_ALWAYSONTOP", RF_ALWAYSONTOP or 0x00010000)
rawset(_G, "RF_HIDEINSKYBOX", RF_HIDEINSKYBOX or 0x00020000)
rawset(_G, "RF_NOMODEL", RF_NOMODEL or 0x00040000)
rawset(_G, "TR", TICRATE)

rawset(_G,"Paint",{})

function Paint:setTeammates()
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
	
	--Then, the displayplayer iterates through their teammates
	--and spawns team markers
end

function Paint:initPlayer(p)
	p.paint = {
		player = p,
		
		weapon_id = "",
		weaponmobj = nil,
		weaponmobjdupe = nil, -- for dualies
		
		forwardmove = 0, sidemove = 0,buttons = 0,
		
		jumpheld = 0,
		fireheld = 0,
		firewait = 0,
		justfired = false,
		cooldown = 0,
		
		-- percentage
		-- this is added to `wep.spread_base`, and is capped to `wep.spread_max - wep.spread_base`
		spread = 0,
		spreadcooldown = 0, -- wait this many tics before decreasing spreadchance
		spreadadd = 0, -- used for jump inaccuracy
		spreadjump = 0,
		
		charge = 0,
		shotsfired = 0, -- for dualies
		turretmode = false, -- for dualies
		dodgeroll = {
			startx = 0, starty = 0,
			destx = 0, desty = 0,
			oldx = 0, oldy = 0,
			momx = 0,momy = 0, -- for ending the dodge
			
			tics = 0,
			getup = 0,
			count = 0, -- how many have we performed?
			leave = 0, -- count UP when we want to exit turret
		},
		
		endlag = 0,
		anglefix = 0,
		anglestand = (p.realmo and p.realmo.valid) and (p.realmo.angle) or p.cmd.angleturn << 16,
		lastslowdown = false,
		holsteranim = 0,
		
		inktank = 100*FU,
		inkdelay = 0, -- delay before restoring ink
		tankmobj = nil,
		
		inventory = {
			items = {},
			curslot = 1,
			slots = 6,
		},
		
		hp = 100*FU,
		timetoheal = 0,
		inink = 0, -- 0 = not in ink, -1 = friendly ink, 1 = enemy ink
		inktime = 0,
		inkleveltime = 0, -- dont set inink multiple times a tic
		wallink = 0, -- touching wall ink
		wasclimbing = false,
		
		squidtime = 0,
		squidanim = 0,
		squidlag = 0,
		hidden = false,
		wasinsquid = 0,
		
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
	pt.inktank = 100*FU
	pt.inink = 0
	
	pt.charge = 0
	pt.fireheld = 0
	pt.firewait = 0
	pt.endlag = 0
	p.cmd.buttons = $ &~BT_ATTACK
	pt.endlag = 0
	pt.anglestand = (p.realmo and p.realmo.valid) and p.realmo.angle or p.cmd.angleturn << 16
	pt.holsteranim = 0
	
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

dofile("cvars/main.lua")
dofile("lib/lib.lua")
dofile("weapons/main.lua")
dofile("weapons/player.lua")
dofile("hud/main.lua")
dofile("auxiliary.lua")
dofile("enemy.lua")

addHook("NetVars",function(n)
	Paint.modes = n($)
end)
