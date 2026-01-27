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

rawset(_G, "SUBMOVE_LATERAL", 50*FU)
rawset(_G, "SUBMOVE_VERTICAL", SUBMOVE_LATERAL)
rawset(_G, "SUBMOVE_OFFSET", 0)

Paint.subs = {}
local sub_meta = {
	realname = "Sub Weapon",
	icon = "MISSING",
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
	
	inner_radius = 175*FU,
	inner_damage = 180*FU,
	outer_radius = 290*FU,
	outer_damage = 30*FU,
	quakeforce = 10*FU,
	
	-- function(mobj_t "sub", boolean "hitceiling", [line_t "line"])
	blockedfunc = nil,
	-- function(mobj_t "sub", string "subtype", boolean "aimline")
	physicsthink = nil,
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
rawset(_G, "WPT_SHOOTER", 1)
rawset(_G, "WPT_CHARGER", 2)
rawset(_G, "WPT_KATANA", 3)
rawset(_G, "WPT_BRUSH", 4)
rawset(_G, "WPT_BLASTER", 5)
rawset(_G, "WPT_DUALIES", 6)
rawset(_G, "WPT_BRELLA", 7)
rawset(_G, "WPT_SLOSHER", 8)

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
	
	range = 405 * FU, --about 2.3 splat3 distance units
	damage = 24*FU,
	startlag = 0,
	endlag = 0,
	squidlag = 0, -- wait this many frames before being able to swim
	shootspeed = FU*78/100, --how much to slow down when shooting
	inertia = false,
	tapfire = false,
	
	subtype = "splatbomb",
	
	shottype = MT_PAINT_SHOT,
	shotscale = FU, -- visual scale
	shotstate = nil, -- leave nil for mobjinfo[shottype].spawnstate
	
	guntype = WPT_SHOOTER,
	handoffset = 16 * FU,
	inkcost = FU,
	inkdelay = 12,
	firewithnoink = false, -- allow firing even if you have low ink
	
	critsound = false, -- nozzlenose stuff
	shotsforcrit = 0,
	
	--shooter-specific
	h_spread = {6*FU, 6*FU},
	v_spread = {3*FU, 3*FU}, -- visual only for the crosshair if `verticalspread` is false
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
	splashradius = 112*FU,
	splashdamage = {50*FU,70*FU}, -- min, max splash damage (damage field is direct hit)
	blast_sounds = {}, -- end of range
	explode_sounds = {}, -- hit geometry
	
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
	turret_range = nil,
	turret_firerate = nil,
	turret_startsound = nil,
	turret_endsound = nil,
	
	--brella specific
	pelletspread = 8*FU,
	pelletnoise = FU*3/2,
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
	shieldingspeed = (FU*78/100)*7/10, -- `shootspeed` but for when you shield
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
	shieldspeed = FixedMul(tofixed("0.226"), Paint.DU2FU), -- released canopies travel this fast
	shieldsound = nil, -- released canopies repeat this sound
	shieldrelease = 64, -- release canopies this many tics after opening
	shieldinkuse = FixedDiv(20*FU, 64*FU),
	inkdelay_held = 12, -- set inkdelay to this when HOLDING a canopy, but not releasing it
	inkdelay_release = 2*TR, -- set inkdelay to this when RELEASING a canopy
	shootwhiledeployed = false, -- undercover brella
	nocanopy = false, -- brella has no canopy (grizzco brella)
	
	weaponstate = S_PAINT_GUN,
	dualie_weaponstate = nil, -- state for the weaponmobjdupe for dualies
	weaponstate_frame = nil, -- frame constants, leave nil for state-defined frame
	weaponstate_scale = FU,
	
	sounds = {
		sfx_p_s0_0, sfx_p_s0_1, sfx_p_s0_2, sfx_p_s0_3, sfx_p_s0_4, sfx_p_s0_5, sfx_p_s0_6
	},
	soundvolume = 255 * 3/4,
	splatvolume = 255, -- for ink splats
	
	-- function to override stats on the fly
	-- (player_t player, table paint, weapon_t weapon, string key, any cur_value)
	abilitywrap = nil,
	
	-- always get passed (player_t, paint_t, weapon_t) plus any misc values
	callbacks = {
		onfire = nil,
	}
}
registerMetatable(weapon_meta)

function Paint:registerWeapon(props)
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
		__index = weapon_meta,
	})
	Paint.weapons[props.name] = props
end

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
	
	hsprd = $ or 0
	vsprd = $ or 0
	local speed = FixedMul(weap:get(pt,"spawnspeed"), proj.scale)
	if (weap.guntype == WPT_CHARGER)
		speed = proj.radius * 2
	end
	mom_vec = $ or {x = 0,y = 0}
	
	local handoffset2 = {Paint:getWeaponOffset(me,pt,angle - ANGLE_90, weap, dualieflip, false)}
	local handoffset  = {Paint:getWeaponOffset(me,pt,angle - ANGLE_90, weap, dualieflip, true)}
	handoffset[4], handoffset[5] = handoffset[1], handoffset[2]
	
	local range = FixedMul(chargerdupe and (weap.range) or (weap:get(pt,"range")), me.scale)
	local aimvec = P_Vec3.SphereToCartesian(angle,aiming)
	-- for shooters, adjust the range to be at the end of straight state
	if (weap.guntype ~= WPT_CHARGER and weap.guntype ~= WPT_BLASTER)
		range = speed * weap:get(pt,"str_tics")
	end
	
	-- Aim in the center (but offset)
	if (weap.guntype == WPT_DUALIES)
		local f_angle = angle - ANGLE_90
		if handoffset[3] -- dualie flipped
			f_angle = $ - ANGLE_180
		end
		local soff = FixedMul(weap:get(pt,"shotoffset"),me.scale) + me.radius
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
	if (weap:get(pt,"neverspreadatall"))
	-- 100% accurate for these (usually blasters)
	or ((weap:get(pt,"neverspreadonground") and not me.jumptime))
		h_spread = 0
		v_spread = 0
	end
	-- apparently shooters dont have any vertical spread in splatoon
	-- weapon.v_spread will stay for visuals and other weapon classes
	if not (weap:get(pt,"verticalspread"))
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
	pt.inkdelay = max($, cur_weapon:get(pt,"inkdelay"))
	if (pt.inktank < cur_weapon:get(pt,"inkcost") - 1)
	and not pt.calledbacks.onfire
		local canfire = cur_weapon:get(pt,"firewithnoink")
		local firerate = cur_weapon:get(pt,"firerate")
		if not canfire then firerate = $*2; end
		pt.cooldown = firerate + 1
		pt.endlag = max($, cur_weapon.endlag)
		pt.shotsfired = $ + 1
		pt.squidlag = max($, cur_weapon:get(pt,"squidlag"))
		
		Paint.HUD:lowInkWarning(p, pt.cooldown)
		
		if not canfire
			local handoffset = {Paint:getWeaponOffset(me,pt, angle - ANGLE_90, cur_weapon, nil, false)}
			pt.anglefix = pt.cooldown
			if (pt.weaponmobj and pt.weaponmobj.valid)
			and not handoffset[3] -- flipped
				pt.weaponmobj.fireanim = 4
			end
			if (pt.weaponmobjdupe and pt.weaponmobjdupe.valid)
			and handoffset[3] -- flipped
				pt.weaponmobjdupe.fireanim = 4
			end
			
			S_StartSound(me, P_RandomRange(sfx_pt_dr0, sfx_pt_dr3), p)
			pt.oldinktank = min(max(pt.oldinkanim, pt.inktank), 100*FU)
			
			if cur_weapon.guntype == WPT_BRELLA
				pt.nofiring = true
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
		2*cos(angle), 2*sin(angle),
		41*FixedDiv(p.mo.height,p.mo.scale)/48 - 8*FU,
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
	
	proj.spritexscale = FixedMul($, cur_weapon:get(pt,"shotscale"))
	proj.spriteyscale = FixedMul($, cur_weapon:get(pt,"shotscale"))
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

	if cur_weapon.guntype == WPT_CHARGER
		local sound
		local chargetime = cur_weapon:get(pt,"chargetime")
		local chargeprogress = min(FixedDiv(pt.charge, chargetime), FU)
		if pt.charge >= chargetime/2
			sound = cur_weapon.strong_sounds[P_RandomRange(1, #cur_weapon.strong_sounds)]
		else
			sound = cur_weapon.weak_sounds[P_RandomRange(1, #cur_weapon.weak_sounds)]
		end
		S_StartSoundAtVolume(me, sound, cur_weapon.soundvolume)
		
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
		end
	elseif not pt.calledbacks.onfire
		S_StartSoundAtVolume(me, cur_weapon.sounds[P_RandomRange(1, #cur_weapon.sounds)], cur_weapon.soundvolume)
	end
	if cur_weapon.guntype == WPT_BRELLA
		proj.damage = wep_damage + FixedMul(cur_weapon:get(pt,"maxdamage") - wep_damage, P_RandomFixed())
		proj.pellet = true
	end
	proj.basedamage = proj.damage
	proj.falloffdamage = cur_weapon:get(pt, "falloffdamage")
	
	pt.anglefix = pt.cooldown
	if (pt.weaponmobj and pt.weaponmobj.valid)
	and not handoffset[3] -- flipped
		pt.weaponmobj.fireanim = 4
	end
	if (pt.weaponmobjdupe and pt.weaponmobjdupe.valid)
	and handoffset[3] -- flipped
		pt.weaponmobjdupe.fireanim = 4
	end
	
	-- No recursion
	if not pt.calledbacks.onfire
	and (cur_weapon.callbacks and cur_weapon.callbacks.onfire ~= nil)
		pt.calledbacks.onfire = true
		cur_weapon.callbacks.onfire(p,pt,cur_weapon, proj, mom_vec, angle, aiming, dospread, doaiming)
	end
	
	P_SetOrigin(proj,
		me.x + handoffset[1] + mom_vec.x + FixedMul(aimoffset_dist, aimoffset_vec.x),
		me.y + handoffset[2] + mom_vec.y + FixedMul(aimoffset_dist, aimoffset_vec.y),
		proj.z + me.momz + FixedMul(aimoffset_dist, aimoffset_vec.z) + me.pmomz
	)
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
		S_StartSoundAtVolume(bomb, sfx_pb_fly, 255 * 3/4)
		if sub_t.spawnstate ~= nil
			bomb.state = sub_t.spawnstate
		end
	end
	
	if bomb.inertia
		local momzadd = 3 * ((me.momz * flip) / me.scale) * 3/4
		momzadd = $ * me.scale
		if momzadd < 0 then momzadd = 0; end
		bomb.momz = $ + momzadd
		
		local sidefact = FixedDiv(pt.fixed_smove, 50*FU)
		local sideangle = FixedAngle(15 * sidefact)
		P_InstaThrust(bomb, angle - sideangle, R_PointToDist2(0,0, bomb.momx,bomb.momy))
		
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