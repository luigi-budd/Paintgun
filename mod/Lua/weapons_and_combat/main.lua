dofile("weapons/bullet.lua")
dofile("weapons/bomb.lua")

for i = 0,6
	sfxinfo[freeslot("sfx_p_s0_"..i)].caption = "Paint fired"
end
--im so sorry most of these sounds are wav but im lazy so pls forgive me
for i = 0,6 -- this is for the charger
	sfxinfo[freeslot("sfx_p_s2_"..i)].caption = "Paint fired"
end
for i = 0,3
	sfxinfo[freeslot("sfx_pt_dr"..i)].caption = "Dry fire"
end

sfxinfo[sfx_p_s2_0].caption = "/"
sfxinfo[sfx_p_s2_3].caption = "/"
sfxinfo[sfx_p_s2_1].flags = SF_X2AWAYSOUND
sfxinfo[sfx_p_s2_2].flags = SF_X2AWAYSOUND|SF_X4AWAYSOUND

sfxinfo[freeslot("sfx_pt_dge")].caption = "Dodge roll"
sfxinfo[freeslot("sfx_pt_lug")].caption = "Lunge"

rawset(_G, "SUBMOVE_LATERAL", 50*FU)
rawset(_G, "SUBMOVE_VERTICAL", SUBMOVE_LATERAL)
rawset(_G, "SUBMOVE_OFFSET", 0)

Paint.subs = {}
local sub_meta = {
	realname = "Sub Weapon",
	icon = "MISSING",
	icon_scale = FU/10,
	spawnstate = nil,
	spawnscale = FU/2,

	airdrag = FU * 97/100,
	gravmul = FU,
	
	inkcost = 70*FU,
	inkdelay = TR,
	offset = 6*FU,
	fuse = 40,
	explodeoncontact = false,
	explodesound = sfx_pb_exp,
	allowhitmarkers = false,
	guidedrot = false,
	inertia = true,
	
	inner_radius = FixedMul(tofixed("3.6"), Paint.DU2FU),
	inner_damage = 180*FU,
	outer_radius = FixedMul(tofixed("7"), Paint.DU2FU),
	outer_damage = 30*FU,
	quakeforce = 10*FU,
	
	-- function(mobj_t "sub", boolean "hitceiling", [line_t "line"])
	blockedfunc = nil,
	-- function(mobj_t "sub", string "subtype", boolean "aimline")
	physicsthink = nil,
	-- function(mobj_t "sub")
	deathstate = nil,
}
registerMetatable(sub_meta)

function Paint:registerSubWeapon(props)
	assert(props.name, "Properties table must have a name field")
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
		__index = sub_meta,
	})
	Paint.subs[props.name] = props
end

-- weapon classes
rawset(_G, "WPT_SHOOTER", 1 ) -- x
rawset(_G, "WPT_ROLLER",  2 )
rawset(_G, "WPT_CHARGER", 3 ) -- x
rawset(_G, "WPT_SLOSHER", 4 )
rawset(_G, "WPT_GATLING", 5 )
rawset(_G, "WPT_DUALIES", 6 ) -- x
rawset(_G, "WPT_BRELLA",  7 ) -- x
rawset(_G, "WPT_BLASTER", 8 ) -- x
rawset(_G, "WPT_BRUSH",   9 )
rawset(_G, "WPT_BOW",     10)
rawset(_G, "WPT_KATANA",  11) -- x

rawset(_G, "WPT_SPECIAL",  12)

-- weapon weight classes
rawset(_G, "WEI_LIGHT", 1)
rawset(_G, "WEI_MID",   2)
rawset(_G, "WEI_HEAVY", 3)
Paint.WEI_MULS = {
	[WEI_LIGHT] = tofixed("1.08333"),
	[WEI_MID]   = FU,
	[WEI_HEAVY] = tofixed("0.91666"),
}

-- shot states
rawset(_G, "SS_STRAIGHT", 1)
rawset(_G, "SS_BRAKE", 2)
rawset(_G, "SS_FREE", 3)

-- https://www.youtube.com/watch?v=lVE7RFD1tmo
-- lifespan, mindropoffgrav, dropoffmul, dropoff, and other related variables
-- should be removed and replaced with bulletsimple phases
-- a distanceunit-to-fracunit scaling factor should also be added lol
Paint.weapons = {}
local weapon_meta = {
	realname = "Main Weapon",
	icon = "MISSING",
	icon_scale = FU/10,
	hidden = false,
	
	range = 405 * FU, --about 2.3 splat3 distance units
	damage = 24*FU,
	startlag = 0,
	endlag = 0,
	squidlag = 0, -- wait this many frames before being able to swim
	shootspeed = FixedDiv(tofixed("0.072"), Paint.SPLAT2WALKSPEED), -- how much to slow down while shooting
	inertia = false,
	tapfire = false,
	
	subtype = "splatbomb",
	
	shottype = MT_PAINT_SHOT,
	shotscale = FU, -- visual scale
	shotstate = nil, -- leave nil for mobjinfo[shottype].spawnstate
	shotstretch = true, -- stretch shots when theyre in straight state
	
	weightclass = WEI_MID,
	
	guntype = WPT_SHOOTER,
	handoffset = 16 * FU,
	inkcost = FU,
	inkdelay = 12,
	firewithnoink = false, -- allow firing even if you have low ink
	nodryfirelag = false, -- disables the added firerate when you dryfire
	dofireanim = true,
	
	critsound = false, -- nozzlenose stuff
	shotsforcrit = 0,
	
	-- generic "groups" field for weapons that fire volleys of projectiles
	-- the individual fields in a group depends on the weapon using it
	groupnum = 0,
	groups = {
		/*
		-- [1, groupnum]
		[1] = {
			info
		},
		[2] = {},
		...
		*/
	},
	-- dupes for abilitywraps to use
	groupnum2 = {},
	groups2 = {},
	
	--shooter-specific
	h_spread = {6*FU, 6*FU},
	v_spread = {3*FU, 3*FU}, -- visual only for the crosshair if `verticalspread` is false
	naturalaiming = 6*FU,
	verticalspread = false,
	-- spread values (PERCETANGES [0, 100*FRACUNIT], DIVIDED BY 100*FU WHEN NEEDED)
	spread_base = (FU * 1), -- chance to spread, similar to accelstart
	spread_pershot = (FU * 1), -- add this much chance to spread per shot
	spread_max = (FU * 25), -- max chance to spread
	spread_recovery = 4, -- how many tics to wait before recovering spread
	spread_decay = (FU*3/2),
	spread_jumpspread = 6*FU, -- how many degrees does jump inaccuracy add?
	spread_jump = 41, -- how many tics until jump spread decays?
	spread_jumpchance = (FU * 40), -- set spread chance to this when jumping
	/*[DEPRECATED]*/ lifespan = 5,
	spawnspeed = FixedMul(tofixed("2.0"), Paint.DU2FU), -- 2.0 splat3 distance units
	
	str_tics = 10, -- straight state lasts this many tics
	str2brk_maxspeed = FixedMul(tofixed("10"), Paint.DU2FU), -- when ending straight state, cap xyspeed to this
	brk_airresist = FU * 64/100, -- xy AND z moms are affected by air resistance
	brk_gravity = FixedMul(tofixed("0.07"), Paint.DU2FU),
	/*
		brake state ends when:
			1. brk2fre_minz condition is satisfied
			AND
			2. (brk2fre_minxy is satisfied) or (brk2fre_tics is satisfied)
	*/
	brk2fre_minz = FixedMul(tofixed("-0.15"), Paint.DU2FU), -- go to free when momz is below this
	brk2fre_minxy = FixedMul(tofixed("0.2355"), Paint.DU2FU), -- or go to free when xyspeed is below this
	brk2fre_tics = 4, -- or when brake state lasts this many tics
	fre_airresist = FU * 98/100,
	fre_gravity = FixedMul(tofixed("0.016"), Paint.DU2FU),
	crs_guideframe = 8, -- crosshair is placed at this frame in the shot's lifetime
	crs_scale = FU, -- crosshair scale
	-- start falling off when past crs_guideframe 
	falloffdamage = 18*FU, --damage to fall off to when the bullet drops off
	fallofftime = 23, --how many tics to reach falloffdamage?
	
	firerate = 3, -- how many tics to wait AFTER the tic when firing
	/*[DEPRECATED]*/ dropoff = 540 * FU, --absolute edge of range, drop off in between
	/*[DEPRECATED]*/ dropoffmul = FU / 20,
	/*[DEPRECATED]*/ mindropoffgrav = FU*3/4, --WTF.
	/*[DEPRECATED]*/ dragmul = FU * 78/100,
	quartersteps = true,
	neverspreadonground = false, -- never apply shotspread if the player is grounded
	neverspreadatall = false,
	bulletspershot = 1,-- these probably add to dualie order and spread calcs but idk
	
	--charger specific
	chargetime = TR*FU,
	mincharge = 5, -- 5 tics
	minrange = FixedMul(tofixed("10.75"), Paint.DU2FU),
	mininkcost = 2*FU + (FU/4),
	charge_sound = sfx_p_s2_0,
	weak_sounds = {
		sfx_p_s2_1
	},
	strong_sounds = {
		sfx_p_s2_2
	},
	charging_sound = sfx_p_s2_5,
	slow_charging_sound = sfx_p_s2_6,
	charged_sound = sfx_p_s2_3,
	maxdamage = 160*FU, -- fully charged
	partialdamage = 80*FU, -- max partial charge damage (regular damage is minimum uncharged damage)
	pierces = -1,
	maxfirerate = 4, -- (firerate -> maxfirerate) * chargeprogress
	shineoffset = -12*FU, --offset the shine vfx this much from fireangle
	muzzleoffset = 40*FU, --for the max-charge effect
	slowwhenjumping = true, -- slow charging when jumping
	storecharges = true,
	partialstorage = false, -- allow charge storage even when not fully charged
	storagetime = TR*5/4,
	storagelag = TR/2,
	storagelaserlag = 15,
	
	--blaster specific
	/*
		[GROUP INFO]
		radius = fixed_t,
		damage = fixed_t,
		
		-- each group "adds" a damage radius on explosion
		-- blasters always explode 2 tics after they reach brake state
	*/
	/*[DEPRECATED]*/ splashradius = 112*FU,
	/*[DEPRECATED]*/ splashdamage = {50*FU,70*FU}, -- min, max splash damage (damage field is direct hit)
	blocksearch = FixedMul(tofixed("4"), Paint.DU2FU), -- separate from splash damage, how much of the blockmap should we search
	blast_sounds = {}, -- end of range
	explode_sounds = {}, -- hit geometry
	geo_damagemul = FU/2, -- hitting geometry multiplies both by this scale
	geo_rangemul = FU/2,
	lerp_damage = true,
	
	--dualie specific
	shotoffset = 2*FU, -- how far from the center are we offset?
	dodgerolls = 2, -- use endlag variable
	dodgeslide = false, -- dualie squelchers
	dodgelength = 10,
	dodgedist = 190*FU,
	dodgeendlag = 3, -- wait this many tics AFTER rolling to start firing
	dodgecamlag = 4,
	dodgegetup = TR/2, -- you can get up after this many tics
	dodgeinkcost = 8*FU, -- use this much ink for dodge rolls
	dodgeshotcost = nil,
	dodgesound = nil,
	turret_range = nil,
	turret_firerate = nil,
	turret_startsound = nil,
	turret_endsound = nil,
	
	--brella specific
	/*
		[GROUP INFO]
		h_degree = fixed_t,
		h_noise = fixed_t,
		v_degree = fixed_t,
		v_noise = fixed_t,
		numprojs = int,
		
		-- Horizontal/VerticalDegree and Horizontal/VerticalOffset
		-- seem to be h/v_degree and h/v_noise respectively...
		-- its hard to tell because there isnt much documentation i can find
		-- about how this class works...
		--
		-- H/VDegree also seem to be spread evenly between the TotalNum in a group,
		-- so if HDegree is 45, and TotalNum is 2, there should be 2 projectiles
		-- fired at -45d and 45d
		-- It also seems that half the projectiles are fired at +VDegree,
		-- then -VDegree?
		-- So therefore, if HDegree is 60, VDegree is 20, and TotalNum is 6,
		-- the spread pattern for this group should look like:
		--		-60 d         60 d
		--		x      x      x		+20 d
		--		       -			 0  d
		--		x      x      x		-20 d
	*/
	/*[DEPRECATED]*/ pelletspread = 8*FU,
	/*[DEPRECATED]*/ pelletnoise = FU*3/2,
	-- these 2 do not apply to the center most pellet
	pelletradius = 6*FU,
	pelletheight = 12*FU,
	-- charger "maxdamage" is also used for brella pellets,
	-- damage is chosen from [wep.damage, wep.maxdamage],
	-- then is capped to wep.totaldamage if necessary
	totaldamage = 81*FU,
	capdamage = false, -- brellas DO cap damage, but this needs to be false so other weapons dont get capped
	slowturnmul = FU/12,
	deploywait = (TR/2)*4/5,
	deployend = Paint.CANOPY_ANIM, -- use endlag if nil
	deploydelay = 11, -- hold fire for this long before deploying
	releasetime = 64, -- wait this long AFTER deploying the canopy to release it
	shieldingspeed = FixedDiv(tofixed("0.055"), Paint.SPLAT2WALKSPEED), -- `shootspeed` but for when you shield
	readysound = nil,
	deploysound = nil,
	stowsound = nil,
	breaksound = nil,
	recoversound = nil,
	releasesound = nil,
	contactdamage = 30*FU,
	contactcooldown = TR/2,
	releasedmultiplier = FU/2, -- damage mulitiplier when released
	open_weaponstate = nil, -- for when the canopy is open/released
	shieldstate = nil, -- state for the canopy
	shieldscale = FU/2, -- sprite scale for canopy
	shieldhp = 500*FU,
	shieldregen = 150*FU, -- heal this much hp per second
	shieldrecover = 5*TR + (TR/2), -- wait this much before "respawning" the shield (either launched or destroyed)
	shieldlifetime = 5*TR, -- released canopies last for this long
	shieldspeed = FixedMul(tofixed("0.132"), Paint.DU2FU), -- released canopies travel this fast
	shieldsound = nil, -- released canopies repeat this sound
	shieldrelease = 64, -- release canopies this many tics after opening
	shieldinkuse = FixedDiv(20*FU, TR*FU),
	shieldspan = 60*FU, -- how wide half the canopy is, for protecting against bombs
	inkdelay_held = 12, -- set inkdelay to this when HOLDING a canopy, but not releasing it
	inkdelay_release = 2*TR, -- set inkdelay to this when RELEASING a canopy
	shootwhiledeployed = false, -- undercover brella
	regenonkill = false, -- also undercover brella
	nocanopy = false, -- brella has no canopy (grizzco brella)
	localalpha = FU, -- also undercover brella
	
	--splatana specific
	/*
		[GROUP INFO]
		offset = fixed_t,
		radius = fixed_t,
		height = fixed_t,
		state = statenum_t,
		
		a group is spawned on both sides of the center projectile
		offset `offset` fracs + `radius`
		the projectile will also be centered depending on its `height` and the center's height
		
	*/
	melee_damage = 15*FU,
	melee_radius = 64*FU,
	melee_height = 12*FU,
	melee_offset = 0,
	--vertical dupes
	vmelee_damage = 120*FU,
	vmelee_radius = 64*FU,
	vmelee_height = 40*FU,
	vmelee_offset = 12*FU,
	--
	h_fuse = 4, -- horizontal slashes disappear after this many tics
	v_fuse = 13, -- vertical slashes
	v_speed = FixedMul(tofixed("1.2"), Paint.DU2FU), -- spawnspeed for vertical slashes
	v_inkcost = 6*FU, -- inkcost for vertical slashes
	v_endlag = 12,
	c_radius = 14*FU, -- radius and height for the center projectile
	c_height = 20*FU,
	vc_radius = 16*FU, -- radius and height for the center projectile
	vc_height = 32*FU,
	weaponstate_swipe = nil,
	swipeangleoffset = 0,
	-- charger chargetime and mincharge are used for charge slashes,
	-- however, if attack is held for less than mincharge, a horizontal slash
	-- will be fired instead of no projectile
	-- charger strong_sounds is also used for charged slashes
	-- charger charging_sound and slow_charging_sound are also used
	-- charger maxdamage is also used for charge slashes
	crs_sections = 3, -- how many bars to draw on the crosshair
	crs_chargingsections = 4,
	crs_chargedguideframe = 14,
	charging_shootspeed = FixedDiv(tofixed("0.0945"), Paint.SPLAT2WALKSPEED),
	vshotstate = nil, -- only the center hitbox gets a visual for vslashes
	
	--roller-brush-specific
	/*
		[GROUP INFO]
		numprojs = int,
		state = statenum_t,
		spawndegree = fixed_t,
		spawnwidth = fixed_t,
		spawnspeed = fixed_t,
		speedoffset = fixed_t,
		angleoffset = fixed_t,
		spawnoffset = fixed_t,
		-- brush attributes
		leftangoff = fixed_t,
		rightangoff = fixed_t,
		upwardsmul = fixed_t,
		
		a group is spawned from the player
		
		spawndegree determines how wide a group spread on 1 side,
		so 30 degrees would spread a group left 30d and right 30d evenly spread by numprojs,
		totaling to a 60d spread
		
		spawnwidth adjusts how far a projectile spawns on both sides,
		so 1 du of spawnwidth would spread all projectiles on the left a total of 1 du,
		and all projectiles on the right a total of 1 du, equalling a total width of 2 du
		
		all projectiles spawn with spawnspeed speed, and have their speed
		offset [-speedoffset, speedoffset]
		so if spawnspeed is 5 du, and speedoffset is 1 du, all projectiles can spawn
		with speeds from [4, 6]
		
		angleoffset is a multiplier, and multiplies the final speed and adds it perpendicularly
		so if angleoffset is 0.2, the multiplier will be random from [-0.2, 0.2]
		
		^ 4 (base speed)
		|
		|
		|
		|--> + 0.8 (4 * 0.2) (angle offset)
		
		spawnoffset moves the projectile randomly in all 3 axes
		from [-spawnoffset, spawnoffset]
		
		upwardsmul for brushes is like angleoffset, but for the z axis
		
	*/
	
	weaponstate = S_PAINT_GUN,
	dualie_weaponstate = nil, -- state for the weaponmobjdupe for dualies
	dualie_weaponmirror = false,
	weaponstate_frame = nil, -- frame constants, leave nil for state-defined frame
	weaponstate_scale = FU,
	allowdrycolor = false, -- just recolors the weapon to white if theres no ink lol
	
	sounds = {
		sfx_p_s0_0, sfx_p_s0_1, sfx_p_s0_2, sfx_p_s0_3, sfx_p_s0_4, sfx_p_s0_5, sfx_p_s0_6
	},
	-- drysounds = {}, -- if defined, these are used for dryfire sounds
	soundvolume = 255 * 3/4,
	splatvolume = 255, -- for ink splats
	
	-- function to override stats on the fly
	-- (player_t player, table paint, weapon_t weapon, string key, any cur_value)
	abilitywrap = nil,
	
	-- always get passed (player_t, paint_t, weapon_t) plus any misc values
	callbacks = {
		onfire = nil,
		ondryfire = nil,
		onhit = nil,
		
		crosshaironfire = nil,
		
		bulletthinker = nil,
		crosshairthinker = nil,
		
		canswap = nil,
		prethinker = nil, -- before paintgun logic, in playerthink
		postthinker = nil, -- after paintgun logic, in playerthink
	}
}
registerMetatable(weapon_meta)

function Paint:registerWeapon(props)
	assert(props.name, "Properties table must have a name field")
	props.get = function(self, paint, key, crosshair)
		local value = self[key]
		if self.abilitywrap ~= nil
			local temp = self.abilitywrap(paint.player, paint, self, key, value, crosshair)
			if temp ~= nil
				value = temp
			end
		end
		return value
	end
	setmetatable(props, {
		__index = weapon_meta,
	})
	Paint.weapons[props.name] = props
end
-- blank dummy weapon
Paint:registerWeapon({name = "null", hidden = true})

function Paint:giveWeapon(p, wep_name, slot)
	if self.weapons[wep_name] == nil
		CONS_Printf(p,'\x85Weapon "'..wep_name..'" doesnt exist')
		return
	end
	
	if slot == nil
		local inv = p.paint.inventory
		local foundfree = false
		for i = 1, inv.slots
			if inv.items[i] == nil
				slot = i
				foundfree = true
				break
			end
		end
		if not foundfree
			CONS_Printf(p, "\x85Out of inventory slots")
			return
		end
	end
	p.paint.inventory.items[slot] = wep_name
end
function Paint:removeWeapon(p, slot)
	if slot == nil
		return
	end
	p.paint.inventory.items[slot] = nil
end

--returns x,y
-- DONT FORGET to wrap the results, `{Paint:getWeaponOffset(me, me.angle - ANGLE_90, wep)}` for example
-- aimit: use shotoffset for aimProjectile, handoffset otherwise
-- submode: use suboffset
function Paint:getWeaponOffset(me,pt, angle, cur_weapon, doflip, aimit, submode)
	local flipped = false
	local offset = (cur_weapon.guntype == WPT_DUALIES or aimit) and cur_weapon:get(pt,"shotoffset") or cur_weapon:get(pt,"handoffset")
	if submode
		offset = Paint.subs[cur_weapon.subtype]:get(pt,"offset")
	end
	
	if ((cur_weapon.guntype == WPT_DUALIES) and (pt.shotsfired % 2) and (doflip == nil))
	or doflip
		angle = $ - ANGLE_180
		flipped = true
	end
	return P_ReturnThrustX(nil, angle, (me.radius + FixedMul(offset,me.scale))),
		   P_ReturnThrustY(nil, angle, (me.radius + FixedMul(offset,me.scale))),
		   flipped
end

local function RandomPerpendicular(v)
    local up = P_Vec3.New(0, 0, FU)

    if abs(v:Dot(up)) > (99 * FU / 100) then
        up = P_Vec3.New(FU, 0, 0)
    end

    return v:Cross(up):Normalize()
end

-- hsprd and vsprd arguments are offsets for spread values
-- hsprd and vsprd are fixed_t
-- FUCK!!! I HATE THIS FUNCTION!! THIS FUCKTION!!
function Paint:aimProjectile(p, proj, angle, aiming, dospread, mom_vec, dualieflip, crosshair, hsprd, vsprd, chargerdupe)
	local me = p.mo
	local pt = p.paint
	local weap = self.weapons[pt.weapon_id]
	local gravflip = P_MobjFlip(me)
	
	aiming = $ + FixedAngle(weap:get(pt,"naturalaiming",crosshair))*gravflip
	hsprd = $ or 0
	vsprd = $ or 0
	local speed = FixedMul(weap:get(pt,"spawnspeed",crosshair), proj.scale)
	if (weap.guntype == WPT_CHARGER)
		speed = proj.radius * 2
	end
	
	mom_vec = $ or {x = 0,y = 0}
	
	local handoffset2 = {Paint:getWeaponOffset(me,pt,angle - ANGLE_90, weap, dualieflip, false)}
	local handoffset  = {Paint:getWeaponOffset(me,pt,angle - ANGLE_90, weap, dualieflip, true)}
	handoffset[4], handoffset[5] = handoffset[1], handoffset[2]
	
	local range = FixedMul(chargerdupe and (weap.range) or (weap:get(pt,"range",crosshair)), me.scale)
	local aimvec = P_Vec3.SphereToCartesian(angle,aiming)
	-- for shooters, adjust the range to be at the end of straight state
	if (weap.guntype ~= WPT_CHARGER and weap.guntype ~= WPT_BLASTER)
		range = speed * weap:get(pt,"str_tics",crosshair)
	end
	
	-- Aim in the center (but offset)
	if (weap.guntype == WPT_DUALIES)
		local f_angle = angle - ANGLE_90
		if handoffset[3] -- dualie flipped
			f_angle = $ - ANGLE_180
		end
		local soff = FixedMul(weap:get(pt,"shotoffset",crosshair),me.scale) + me.radius
		handoffset[1] = P_ReturnThrustX(nil, f_angle, soff)
		handoffset[2] = P_ReturnThrustY(nil, f_angle, soff)
		handoffset[4], handoffset[5] = handoffset[1], handoffset[2]
		if pt.turretmode
			handoffset[1],handoffset[2] = 0,0
		end
	-- Aim in the center 
	elseif (weap.guntype == WPT_BRELLA)
		handoffset[1],handoffset[2] = 0,0
	end
	
	local h_spread,v_spread = 0,0
	if not crosshair
		h_spread = P_RandomFixedRange(-weap.h_spread[1], weap.h_spread[2])
		v_spread = P_RandomFixedRange(-weap.v_spread[1], weap.v_spread[2])
		if (weap.guntype == WPT_DUALIES and pt.turretmode)
		or not dospread
			h_spread = FixedDiv($, FU*5/2)
			v_spread = FixedDiv($, FU*5/2)
		end
		if not dospread
			h_spread = $ / 4
			v_spread = $ / 4
		end
		
		local random = P_RandomFixedSigned()
		h_spread = $ + FixedMul(pt.spreadadd, random)
		h_spread = FixedAngle($)
		v_spread = FixedAngle($)
		
		--angle = $ - h_spread
		--aiming = $ + FixedAngle(v_spread)
	end
	if (weap:get(pt,"neverspreadatall",crosshair))
	-- 100% accurate for these (usually blasters)
	or ((weap:get(pt,"neverspreadonground",crosshair) and not me.jumptime))
		h_spread = 0
		v_spread = 0
	end
	-- apparently shooters dont have any vertical spread in splatoon
	-- weapon.v_spread will stay for visuals and other weapon classes
	if not (weap:get(pt,"verticalspread",crosshair))
		v_spread = 0
	end
	
	h_spread = $ - FixedAngle(hsprd)
	v_spread = $ + FixedAngle(vsprd)

	local point = {
		x = me.x + FixedMul(range, aimvec.x) + mom_vec.x + handoffset[1],
		y = me.y + FixedMul(range, aimvec.y) + mom_vec.y + handoffset[2],
		z = proj.z + FixedMul(range, aimvec.z)
	}
	if (weap.guntype == WPT_DUALIES)
		if pt.turretmode
			angle = R_PointToAngle2(
				me.x + mom_vec.x + handoffset[4],
				me.y + mom_vec.y + handoffset[5],
				point.x, point.y
			)
		else
			angle = R_PointToAngle2(
				me.x + mom_vec.x + handoffset2[1],
				me.y + mom_vec.y + handoffset2[2],
				point.x, point.y
			)
		end
		aimvec = P_Vec3.SphereToCartesian(angle,aiming)
	end
	
	local axis1 = RandomPerpendicular(aimvec)
	local axis2 = aimvec:Cross(axis1):Normalize()
	local q = P_Quat.AxisAngle(axis1, v_spread):Mul(P_Quat.AxisAngle(axis2, h_spread))
	local mom = q:Rotate(aimvec)
	proj.momx = FixedMul(speed, mom.x)
	proj.momy = FixedMul(speed, mom.y)
	proj.momz = FixedMul(speed, mom.z)
	
	proj.angle = R_PointToAngle2(proj.x,proj.y, point.x,point.y) - h_spread
	
	/*
	if not crosshair
		P_SpawnMobj(point.x,point.y,point.z, MT_THOK).color = SKINCOLOR_RED
	end
	P_SpawnMobj(point.x,point.y,point.z, MT_THOK).color = (dualieflip and SKINCOLOR_RED or SKINCOLOR_GREEN)
	P_SpawnMobj(point.x,point.y, me.z, MT_THOK)
	P_SpawnMobj(
		me.x + P_ReturnThrustX(nil,angle,FixedMul(weap.dropoff, me.scale)),
		me.y + P_ReturnThrustY(nil,angle,FixedMul(weap.dropoff, me.scale)),
		me.z, MT_THOK
	).color = SKINCOLOR_RED
	*/
	return point
end

function Paint:fireWeapon(p, cur_weapon, angle, aiming, dospread, doaiming, hsprd, vsprd)
	local me = p.mo
	local pt = p.paint
	local dofireanim = cur_weapon:get(pt,"dofireanim")
	
	pt.inkdelay = max($, cur_weapon:get(pt,"inkdelay"))
	if (pt.inktank < cur_weapon:get(pt,"inkcost") - 1)
	and not pt.calledbacks.onfire
		local canfire = cur_weapon:get(pt,"firewithnoink")
		local firerate = cur_weapon:get(pt,"firerate")
		if not (canfire or cur_weapon:get(pt,"nodryfirelag")) then firerate = $*2; end
		
		pt.cooldown = firerate + 1
		pt.endlag = max($, cur_weapon.endlag)
		pt.shotsfired = $ + 1
		pt.squidlag = max($, cur_weapon:get(pt,"squidlag"))
		
		Paint.HUD:lowInkWarning(p, pt.cooldown)
		
		if not canfire
			local handoffset = {Paint:getWeaponOffset(me,pt, angle - ANGLE_90, cur_weapon, nil, false)}
			pt.anglefix = pt.cooldown
			if dofireanim
				if (pt.weaponmobj and pt.weaponmobj.valid)
				and not handoffset[3] -- flipped
					pt.weaponmobj.fireanim = 4
				end
				if (pt.weaponmobjdupe and pt.weaponmobjdupe.valid)
				and handoffset[3] -- flipped
					pt.weaponmobjdupe.fireanim = 4
				end
			end
			
			local drysound = P_RandomRange(sfx_pt_dr0, sfx_pt_dr3)
			local ds_table = cur_weapon:get(pt,"drysounds")
			if ds_table
				drysound = ds_table[P_RandomRange(1, #ds_table)]
			end
			S_StartSound(me, drysound, p)
			pt.oldinktank = min(max(pt.oldinkanim, pt.inktank), 100*FU)
			
			if cur_weapon.guntype == WPT_BRELLA
				pt.nofiring = true
			end
			if not pt.calledbacks.onfire
			and (cur_weapon.callbacks and cur_weapon.callbacks.ondryfire ~= nil)
				pt.calledbacks.onfire = true
				cur_weapon.callbacks.ondryfire(p,pt,cur_weapon, angle, aiming, dospread, doaiming)
			end
			return
		end
	end
	
	if not pt.calledbacks.onfire
		pt.oldinktank = min(max(pt.oldinkanim, pt.inktank), 100*FU)
		if pt.maxinkdelay == 0
		and not pt.fireheld
			pt.oldinkanim = pt.oldinktank
		end
		pt.maxinkdelay = max($, pt.inkdelay)
		
		pt.inktank = max($ - cur_weapon:get(pt,"inkcost"), 0)
		pt.squidlag = max($, cur_weapon:get(pt,"squidlag"))
		pt.justfired = true
	end
	local doinertia = cur_weapon.inertia
	local proj = P_SpawnMobjFromMobj(me,
		0,0,
		41*FixedDiv(P_GetPlayerHeight(p),p.mo.scale)/48 - 8*FU,
		cur_weapon.shottype
	)
	proj.target = me
	proj.weapon_id = pt.weapon_id
	proj.lifespan = 0
	proj.s_state = SS_STRAIGHT

	-- who knows if this is optimized
	proj.str_tics			= cur_weapon:get(pt,"str_tics")
	proj.str2brk_maxspeed	= FixedMul(cur_weapon:get(pt,"str2brk_maxspeed"), proj.scale)
	proj.brk_airresist		= cur_weapon:get(pt,"brk_airresist")
	proj.brk_gravity		= cur_weapon:get(pt,"brk_gravity")
	proj.brk2fre_minz		= FixedMul(cur_weapon:get(pt,"brk2fre_minz"), proj.scale)
	proj.brk2fre_minxy		= FixedMul(cur_weapon:get(pt,"brk2fre_minxy"), proj.scale)
	proj.brk2fre_tics		= cur_weapon:get(pt,"brk2fre_tics")
	proj.fre_airresist		= cur_weapon:get(pt,"fre_airresist")
	proj.fre_gravity		= cur_weapon:get(pt,"fre_gravity")
	proj.crs_guideframe		= cur_weapon:get(pt,"crs_guideframe")
	
	if cur_weapon:get(pt,"critsound")
		proj.fired_at = leveltime
		proj.critsound = true
		proj.shotsforcrit = cur_weapon:get(pt, "shotsforcrit")
	end
	if cur_weapon:get(pt,"totaldamage")
	and cur_weapon:get(pt,"capdamage")
		proj.fired_at = leveltime
		proj.totaldamage = cur_weapon:get(pt,"totaldamage")
	end
	
	local mom_vec = {x = me.momx,y = me.momy}
	local handoffset = {Paint:getWeaponOffset(me,pt, angle - ANGLE_90, cur_weapon, nil, false)}
	-- fire from the center
	if (cur_weapon.guntype == WPT_BRELLA)
	or (cur_weapon.guntype == WPT_KATANA)
		handoffset[1] = 0
		handoffset[2] = 0
	end
	local aimoffset_vec = SphereToCartesian(angle,aiming)
	local aimoffset_dist = 5 * me.scale
	
	if not doinertia
		mom_vec.x, mom_vec.y = 0, 0
	end
	
	proj.p_angle = angle
	proj.p_aiming = aiming
	if doaiming
		Paint:aimProjectile(p,proj, angle, aiming, dospread, mom_vec, nil,nil, hsprd, vsprd)
	end
	proj.baseangle = proj.angle
	proj.angoffset = (pt.angdiff - angle)
	proj.origin = {x = me.x+mom_vec.x, y = me.y+mom_vec.y, z = proj.z}
	if doinertia
		proj.momx = $ + mom_vec.x
		proj.momy = $ + mom_vec.y
	end
	proj.momz = $ + me.pmomz
	local wep_damage = cur_weapon:get(pt,"damage")
	proj.damage = wep_damage
	proj.charge = pt.charge
	proj.pierces = cur_weapon.pierces
	proj.powerful = false
	proj.init = true
	-- charger progress
	proj.progress = 0
	proj.hitlist = {}
	
	proj.spritexscale = FixedMul($, cur_weapon:get(pt,"shotscale"))
	proj.spriteyscale = FixedMul($, cur_weapon:get(pt,"shotscale"))
	proj.shotstretch = cur_weapon:get(pt,"shotstretch")
	proj.basescale = proj.spritexscale
	proj.color = Paint:getPlayerColor(p)
	proj.renderflags = $|RF_SEMIBRIGHT|RF_NOCOLORMAPS
	local new_state = cur_weapon:get(pt,"shotstate")
	if (new_state ~= nil)
		proj.state = new_state
	end
	
	if (proj.type == MT_PAINT_SHOT) -- moves in quarter steps
	and cur_weapon:get(pt,"quartersteps")
	and cur_weapon.guntype ~= WPT_CHARGER
		proj.momx = $ / 4
		proj.momy = $ / 4
		proj.momz = $ / 4
		proj.quartersteps = true
	end
	
	local firerate = cur_weapon:get(pt,"firerate")
	if not pt.calledbacks.onfire
		pt.shotsfired = $ + 1
		pt.cooldown = firerate + 1
		pt.endlag = max($, cur_weapon.endlag)
		pt.spread = min($ + cur_weapon:get(pt,"spread_pershot"), cur_weapon:get(pt,"spread_max") - cur_weapon:get(pt,"spread_base"))
		pt.spreadcooldown = cur_weapon:get(pt,"spread_recovery")
		
		if cur_weapon.guntype == WPT_BRELLA
			pt.shieldwait = max($, cur_weapon:get(pt,"deploywait"))
		end
	end
	
	local weaponsound = cur_weapon.sounds[P_RandomRange(1, #cur_weapon.sounds)]
	local weaponvolume = cur_weapon:get(pt,"soundvolume")
	proj.splatvolume = cur_weapon:get(pt,"splatvolume")
	if (cur_weapon.guntype == WPT_CHARGER)
		local chargetime = cur_weapon:get(pt,"chargetime")
		local chargeprogress = min(FixedDiv(pt.charge, chargetime), FU)
		if pt.charge >= chargetime/2
			weaponsound = cur_weapon.strong_sounds[P_RandomRange(1, #cur_weapon.strong_sounds)]
		else
			weaponsound = cur_weapon.weak_sounds[P_RandomRange(1, #cur_weapon.weak_sounds)]
		end
		
		pt.cooldown = (firerate + (FixedMul((cur_weapon:get(pt,"maxfirerate") - firerate)*FU, chargeprogress)/FU)) + 1
		pt.endlag = pt.cooldown
		
		proj.powerful = chargeprogress >= FU
		proj.progress = chargeprogress
		if (p == displayplayer or p == secondarydisplayplayer)
		and proj.powerful
			P_StartQuake(5 * max(chargeprogress, FU/5), 12)
		end
		
		if (chargeprogress >= FU)
			proj.damage = cur_weapon:get(pt,"maxdamage")
		else
			proj.damage = wep_damage + FixedMul(cur_weapon:get(pt,"partialdamage") - wep_damage, ease.linear(chargeprogress,0,FU))
			proj.pierces = 0
		end
	end
	if (cur_weapon.guntype == WPT_BRELLA)
		proj.damage = wep_damage + FixedMul(cur_weapon:get(pt,"maxdamage") - wep_damage, P_RandomFixed())
		proj.pellet = true
	end
	if (cur_weapon.guntype == WPT_BLASTER)
		proj.powerful = true
	end
	if (cur_weapon.guntype == WPT_KATANA)
		proj.fuse = cur_weapon:get(pt,"h_fuse")
		
		if (pt.charge >= cur_weapon:get(pt,"chargetime"))
			weaponsound = cur_weapon.strong_sounds[P_RandomRange(1, #cur_weapon.strong_sounds)]
		end
	end
	
	if not pt.calledbacks.onfire
		S_StartSoundAtVolume(me, weaponsound, weaponvolume)
	end
	
	proj.basedamage = proj.damage
	proj.falloffdamage = cur_weapon:get(pt, "falloffdamage")
	
	pt.anglefix = pt.cooldown
	if dofireanim
		if (pt.weaponmobj and pt.weaponmobj.valid)
		and not handoffset[3] -- flipped
			pt.weaponmobj.fireanim = 4
		end
		if (pt.weaponmobjdupe and pt.weaponmobjdupe.valid)
		and handoffset[3] -- flipped
			pt.weaponmobjdupe.fireanim = 4
		end
	end
	
	-- No recursion
	local newpos = {
		x = me.x + handoffset[1] + mom_vec.x + FixedMul(aimoffset_dist, aimoffset_vec.x),
		y = me.y + handoffset[2] + mom_vec.y + FixedMul(aimoffset_dist, aimoffset_vec.y),
		z = proj.z + me.momz + FixedMul(aimoffset_dist, aimoffset_vec.z) + me.pmomz
	}
	if not pt.calledbacks.onfire
	and (cur_weapon.callbacks and cur_weapon.callbacks.onfire ~= nil)
		pt.calledbacks.onfire = true
		cur_weapon.callbacks.onfire(p,pt,cur_weapon, proj, mom_vec, angle, aiming, dospread, doaiming, newpos)
	end
	if proj and proj.valid
		P_SetOrigin(proj, newpos.x, newpos.y, newpos.z)
	end
	return proj -- may be invalid
end

-- also does the aiming for the sub
function Paint:throwSub(p, wep, angle, aiming, aimline)
	local me = p.realmo
	local pt = p.paint
	local sub_t = Paint.subs[wep.subtype]
	aiming = $ + FixedAngle(5*FU)
	
	if (pt.inktank < sub_t:get(pt,"inkcost") - 1)
		--pt.cooldown = firerate + 1
		--pt.endlag = max($, cur_weapon.endlag)
		--pt.shotsfired = $ + 1
		--pt.squidlag = max($, cur_weapon:get(pt,"squidlag"))
		
		Paint.HUD:lowInkWarning(p, TR / 2)
		return
	end
	if not aimline
		pt.inkdelay = max($, sub_t:get(pt,"inkdelay"))
		
		pt.oldinktank = min(max(pt.oldinkanim, pt.inktank), 100*FU)
		if pt.maxinkdelay == 0
			pt.oldinkanim = pt.oldinktank
		end
		pt.maxinkdelay = max($, pt.inkdelay)
		
		pt.inktank = max($ - sub_t:get(pt,"inkcost"), 0)
	end
	
	local flip = P_MobjFlip(me)
	local handoffset = {Paint:getWeaponOffset(me,pt, angle - ANGLE_90, wep, nil, false, true)}
	local bomb = P_SpawnMobjFromMobj(me,
		0,0,
		41*FixedDiv(p.mo.height,p.mo.scale)/48 - 8*FU,
		(aimline) and MT_RAY or MT_PAINT_BOMB
	)
	local vec = SphereToCartesian(angle, aiming)
	bomb.momx = FixedMul(FixedMul(SUBMOVE_LATERAL, me.scale), vec.x)
	bomb.momy = FixedMul(FixedMul(SUBMOVE_LATERAL, me.scale), vec.y)
	bomb.momz = FixedMul(FixedMul(SUBMOVE_VERTICAL, me.scale), vec.z) + FixedMul(SUBMOVE_OFFSET, me.scale)
	bomb.momz = $ * flip
	
	local sprscale = sub_t:get(pt,"spawnscale")
	bomb.spritexscale = sprscale
	bomb.spriteyscale = sprscale
	bomb.paint_scale = sprscale
	
	bomb.shadowscale = FixedMul(2*FU, sprscale)
	--bomb.fuse = 5 * TR
	bomb.target = me
	bomb.tracer_player = p
	
	bomb.color = Paint:getPlayerColor(p)
	bomb.basecolor = bomb.color
	bomb.renderflags = $|RF_NOCOLORMAPS|RF_SEMIBRIGHT
	
	bomb.subweapon = true
	bomb.subtype = wep.subtype
	bomb.airdrag = sub_t:get(pt,"airdrag")
	bomb.gravmul = sub_t:get(pt,"gravmul")
	bomb.fusetimer = sub_t:get(pt,"fuse")
	bomb.explodeoncontact = sub_t:get(pt,"explodeoncontact")
	bomb.allowhitmarkers = sub_t:get(pt,"allowhitmarkers")
	bomb.guidedrot = sub_t:get(pt,"guidedrot")
	bomb.inertia = sub_t:get(pt,"inertia")
	
	if aimline
		bomb.flags = MF_NOCLIPTHING|MF_NOSECTOR|MF_NOGRAVITY
		bomb.flags2 = $|MF2_DONTDRAW
		bomb.tics = -1
		bomb.fuse = -1
		bomb.radius = FixedMul(mobjinfo[MT_PAINT_BOMB].radius, me.scale)
		bomb.height = FixedMul(mobjinfo[MT_PAINT_BOMB].height, me.scale)
	else
		Paint:teamSound(p, bomb, sfx_pb_fly, nil, sfx_pb_fly, 255 * 3/4)
		--S_StartSoundAtVolume(bomb, sfx_pb_fly, 255 * 3/4)
		if sub_t.spawnstate ~= nil
			bomb.state = sub_t.spawnstate
		end
	end
	
	if bomb.inertia
		local momzadd = 3 * ((me.momz * flip) / me.scale) * 3/4
		momzadd = $ * me.scale
		if momzadd < 0 then momzadd = 0; end
		bomb.momz = $ + momzadd
		
		/*
		-- this doesnt feel too nice with kb+m play
		local sidefact = FixedDiv(pt.fixed_smove, 50*FU)
		local sideangle = FixedAngle(15 * sidefact)
		P_InstaThrust(bomb, angle - sideangle, R_PointToDist2(0,0, bomb.momx,bomb.momy))
		*/
		
		local backfact = FixedDiv(pt.fixed_fmove, 50*FU)
		if backfact > 0 then backfact = 0; end
		P_Thrust(bomb, angle, 10 * backfact)
	end

	P_SetOrigin(bomb,
		bomb.x + handoffset[1] + me.momx,
		bomb.y + handoffset[2] + me.momy,
		bomb.z + me.momz
	)
	return bomb
end

dofile("weapons/helpers.lua")
dofile("weapons/templates.lua")
dofile("weapons/callback_templates.lua")
dofile("weapons/def/_FREESLOT.lua")
dofile("weapons/bombdef/_FREESLOT.lua")