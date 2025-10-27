dofile("weapons/bullet.lua")

for i = 0,6
	sfxinfo[freeslot("sfx_p_s0_"..i)].caption = "Paint fired"
end
--im so sorry most of these sounds are wav but im lazy so pls forgive me
for i = 0,6
	sfxinfo[freeslot("sfx_p_s2_"..i)].caption = "Paint fired"
end
for i = 0,3
	sfxinfo[freeslot("sfx_pt_dr"..i)].caption = "Dry fire"
end

sfxinfo[sfx_p_s2_0].caption = "/"
sfxinfo[sfx_p_s2_3].caption = "/"
sfxinfo[sfx_p_s2_1].flags = SF_X2AWAYSOUND
sfxinfo[sfx_p_s2_2].flags = SF_X2AWAYSOUND

sfxinfo[freeslot("sfx_pt_dge")].caption = "Dodge roll"

rawset(_G, "WPT_SHOOTER", 1)
rawset(_G, "WPT_CHARGER", 2)
rawset(_G, "WPT_KATANA", 3)
rawset(_G, "WPT_BRUSH", 4)
rawset(_G, "WPT_BLASTER", 5)
rawset(_G, "WPT_DUALIES", 6)

rawset(_G, "SUB_BOMB", 1)
rawset(_G, "SUB_BURST", 2)

Paint.weapons = {}
local weapon_meta = {
	range = 425 * FU, --about 2.3 distance units
	damage = 24*FU,
	startlag = 0,
	endlag = 0,
	shootspeed = FU/2, --how much to slow down when shooting
	inertia = false,
	
	subtype = SUB_BOMB,
	
	shottype = MT_PAINT_SHOT,
	shotscale = FU, -- visual scale
	shotstate = nil, -- leave nil for mobjinfo[shottype].spawnstate
	
	guntype = WPT_SHOOTER,
	handoffset = 16 * FU,
	inkcost = FU,
	inkdelay = 12,
	
	--shooter-specific
	h_spread = {6, 6}, --TODO: make 1 value only
	v_spread = {3, 3}, --TODO: make 1 value only
	-- spread values (PERCETANGES [0, 100*FRACUNIT], DIVIDED BY 100*FU WHEN NEEDED)
	spread_base = (FU * 1), -- chance to spread, similar to accelstart
	spread_pershot = (FU * 1), -- add this much chance to spread per shot
	spread_max = (FU * 25), -- max chance to spread
	spread_recovery = 4, -- how many tics to wait before recovering spread
	spread_decay = (FU*3/2),
	spread_jumpspread = 6*FU, -- how many degrees does jump inaccuracy add?
	spread_jump = 41, -- how many tics until jump spread decays?
	spread_jumpchance = (FU * 40), -- set spread chance to this when jumping
	lifespan = 5,
	firerate = 3, -- how many tics to wait AFTER the tic when firing
	dropoff = 540 * FU, --absolute edge of range, drop off in between
	dropoffmul = FU / 20,
	mindropoffgrav = FU/2, --WTF.
	falloff = {16,16}, --random distance
	falloffdamage = 10*FU, --damage falloff when the bullet does
	fallofftime = 12, --how many tics to reach falloffdamage?
	dragmul = FU * 78/100,
	quartersteps = true,
	neverspreadonground = false, -- never apply shotspread if the player is grounded
	bulletspershot = 1, -- yes these DO factor into spread! yes, these DO change dualie order!
	
	--charger specific
	chargetime = TR * 3/4,
	minrange = 140*FU,
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
	pierces = 3,
	maxfirerate = TR, -- (firerate -> maxfirerate) * chargeprogress
	
	--blaster specific
	splashradius = 132*FU,
	splashdamage = {50*FU,70*FU}, -- min, max splash damage (damage field is direct hit)
	blast_sounds = {}, -- end of range
	explode_sounds = {}, -- hit geometry
	
	--dualie specific
	shotoffset = 6*FU, -- how far from the center are we offset?
	dodgerolls = 2, -- use endlag variable
	dodgeslide = false, -- dualie squelchers
	dodgelength = 10,
	dodgedist = 190*FU,
	dodgeendlag = 3, -- wait this many tics AFTER rolling to start firing
	dodgegetup = 32, -- you can get up after this many tics
	dodgeinkcost = 8*FU, -- use this much ink for dodge rolls
	dodgeshotcost = nil,
	turret_range = nil,
	turret_firerate = nil,
	turret_startsound = nil,
	turret_endsound = nil,
	
	weaponstate = S_PAINT_GUN,
	dualie_weaponstate = nil, -- state for the weaponmobjdupe for dualies
	weaponstate_frame = nil, -- frame constants, leave nil for state-defined frame
	weaponstate_scale = FU,
	
	sounds = {
		sfx_p_s0_0, sfx_p_s0_1, sfx_p_s0_2, sfx_p_s0_3, sfx_p_s0_4, sfx_p_s0_5, sfx_p_s0_6
	},
	soundvolume = 255 * 3/4,
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
	setmetatable(props, {
		__index = weapon_meta,
	})
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
function Paint:getWeaponOffset(me, angle, cur_weapon, doflip)
	local flipped = false
	if ((cur_weapon.guntype == WPT_DUALIES) and (me.player.paint.shotsfired % 2) and (doflip == nil))
	or doflip
		angle = $ - ANGLE_180
		flipped = true
	end
	return P_ReturnThrustX(nil, angle, (me.radius + FixedMul(cur_weapon.handoffset,me.scale))),
		   P_ReturnThrustY(nil, angle, (me.radius + FixedMul(cur_weapon.handoffset,me.scale))),
		   flipped
end

local function RandomPerpendicular(v)
    local up = P_Vec3.New(0, 0, FU)

    if abs(v:Dot(up)) > (99 * FU / 100) then
        up = P_Vec3.New(FU, 0, 0)
    end

    return v:Cross(up):Normalize()
end

function Paint:aimProjectile(p, proj, angle, aiming, dospread, mom_vec, dualieflip, crosshair)
	local speed = R_PointToDist2(0,0, proj.momx,proj.momy)
	if not speed then return end
	mom_vec = $ or {x = 0,y = 0}
	
	local me = p.mo
	local pt = p.paint
	local weap = self.weapons[pt.weapon_id]
	
	local handoffset = {Paint:getWeaponOffset(me,angle - ANGLE_90, weap, dualieflip)}
	handoffset[4], handoffset[5] = handoffset[1], handoffset[2]
	
	local range = FixedMul(weap:get(pt,"range"), me.scale)
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
		-- 100% accurate for these (usually blasters)
		if not dospread
		and (weap:get(pt, "neverspreadonground")
		and not me.jumptime)
			h_spread = 0
			v_spread = 0
		end
		
		h_spread = $ + (pt.spreadadd * sign(h_spread))
		h_spread = FixedAngle($)
		v_spread = FixedAngle($)
		
		--angle = $ - h_spread
		--aiming = $ + FixedAngle(v_spread)
	end
	local aimvec = P_Vec3.SphereToCartesian(angle,aiming)
	
	local point = {
		x = me.x + FixedMul(range, aimvec.x) + mom_vec.x + handoffset[1],
		y = me.y + FixedMul(range, aimvec.y) + mom_vec.y + handoffset[2],
		z = proj.z + FixedMul(range, aimvec.z)
	}
	if (weap.guntype == WPT_DUALIES and pt.turretmode)
		angle = R_PointToAngle2(
			me.x + mom_vec.x + handoffset[4],
			me.y + mom_vec.y + handoffset[5],
			point.x, point.y
		)
		if dospread
			angle = $ - h_spread
		end
		aimvec = P_Vec3.SphereToCartesian(angle,aiming)
	end
	
	local axis1 = RandomPerpendicular(aimvec)
	local axis2 = aimvec:Cross(axis1):Normalize()
	local q = P_Quat.AxisAngle(axis1, h_spread):Mul(P_Quat.AxisAngle(axis2, v_spread))
	local mom = q:Rotate(aimvec)
	proj.momx = FixedMul(speed, mom.x)
	proj.momy = FixedMul(speed, mom.y)
	proj.momz = FixedMul(speed, mom.z)
	
	proj.angle = R_PointToAngle2(proj.x,proj.y, point.x,point.y)
	--P_3DInstaThrust(proj, angle,aiming, speed)
	
	/*
	P_SpawnMobj(point.x,point.y,point.z, MT_THOK).color = (dospread and SKINCOLOR_RED or SKINCOLOR_GREEN)
	P_SpawnMobj(point.x,point.y, me.z, MT_THOK)
	P_SpawnMobj(
		me.x + P_ReturnThrustX(nil,angle,FixedMul(weap.dropoff, me.scale)),
		me.y + P_ReturnThrustY(nil,angle,FixedMul(weap.dropoff, me.scale)),
		me.z, MT_THOK
	).color = SKINCOLOR_RED
	*/
	return point
end

function Paint:fireWeapon(p, cur_weapon, angle, dospread)
	local me = p.mo
	local pt = p.paint
	pt.inkdelay = max($, cur_weapon:get(pt,"inkdelay"))
	if (pt.inktank < cur_weapon:get(pt,"inkcost") - 1)
		local firerate = cur_weapon:get(pt,"firerate")
		pt.cooldown = (firerate * 2) + 1
		pt.endlag = max($, cur_weapon.endlag)
		pt.shotsfired = $ + 1
		
		Paint.HUD:lowInkWarning(p, pt.cooldown)
		
		local handoffset = {Paint:getWeaponOffset(me, angle - ANGLE_90, cur_weapon)}
		pt.anglefix = pt.cooldown
		if (pt.weaponmobj and pt.weaponmobj.valid)
		and not handoffset[3] -- flipped
			pt.weaponmobj.fireanim = 4
		end
		if (pt.weaponmobjdupe and pt.weaponmobjdupe.valid)
		and handoffset[3] -- flipped
			pt.weaponmobjdupe.fireanim = 4
		end
		
		S_StartSound(me, sfx_pt_dr0, sfx_pt_dr3)
		return
	end
	
	pt.inktank = max($ - cur_weapon:get(pt,"inkcost"), 0)
	local doinertia = cur_weapon.inertia
	local proj = P_SpawnMobjFromMobj(me,
		2*cos(angle), 2*sin(angle),
		41*FixedDiv(p.mo.height,p.mo.scale)/48 - 8*FU,
		cur_weapon.shottype
	)
	proj.target = me
	proj.weapon_id = pt.weapon_id
	proj.color = Paint:getPlayerColor(p)
	proj.lifespan = 0
	proj.falloff = FixedMul(P_RandomFixedRange(-cur_weapon.falloff[1], cur_weapon.falloff[2]), proj.scale)
	local mom_vec = {x = doinertia and me.momx or 0,y = doinertia and me.momy or 0}
	local handoffset = {Paint:getWeaponOffset(me, angle - ANGLE_90, cur_weapon)}
	P_SetOrigin(proj,
		me.x + handoffset[1] + mom_vec.x,
		me.y + handoffset[2] + mom_vec.y,
		proj.z + me.momz
	)
	if not (proj and proj.valid) then return end
	if not doinertia
		mom_vec = {x = 0, y = 0}
	end
	
	P_InstaThrust(proj, angle, FixedMul(FixedDiv(cur_weapon:get(pt,"range"), cur_weapon:get(pt,"lifespan") * FU), proj.scale))
	proj.p_angle = angle
	proj.p_aiming = p.aiming
	Paint:aimProjectile(p,proj, angle, p.aiming, dospread, mom_vec)
	proj.origin = {x = me.x+mom_vec.x, y = me.y+mom_vec.y, z = proj.z}
	if doinertia
		proj.momx = $ + mom_vec.x
		proj.momy = $ + mom_vec.y
	end
	proj.damage = cur_weapon:get(pt,"damage")
	proj.charge = pt.charge
	proj.pierces = cur_weapon.pierces
	proj.powerful = false
	proj.init = true
	proj.progress = 0
	proj.spritexscale = FixedMul($, cur_weapon:get(pt,"shotscale"))
	proj.spriteyscale = FixedMul($, cur_weapon:get(pt,"shotscale"))
	local new_state = cur_weapon:get(pt,"shotstate")
	if (new_state ~= nil)
		proj.state = new_state
	end
	
	if (proj.type == MT_PAINT_SHOT) -- moves in quarter steps
	and cur_weapon:get(pt,"quartersteps")
		proj.momx = $ / 4
		proj.momy = $ / 4
		proj.momz = $ / 4
		proj.quartersteps = true
	end
	
	local firerate = cur_weapon:get(pt,"firerate")
	pt.shotsfired = $ + 1
	pt.cooldown = firerate + 1
	pt.endlag = max($, cur_weapon.endlag)
	pt.spread = min($ + cur_weapon:get(pt,"spread_pershot"), cur_weapon:get(pt,"spread_max") - cur_weapon:get(pt,"spread_base"))
	pt.spreadcooldown = cur_weapon:get(pt,"spread_recovery")
	if cur_weapon.guntype == WPT_CHARGER
		local sound
		local chargeprogress = min(FixedDiv(pt.charge*FU, cur_weapon.chargetime*FU), FU)
		if pt.charge >= cur_weapon.chargetime/2
			sound = cur_weapon.strong_sounds[P_RandomRange(1, #cur_weapon.strong_sounds)]
		else
			sound = cur_weapon.weak_sounds[P_RandomRange(1, #cur_weapon.weak_sounds)]
		end
		S_StartSoundAtVolume(me, sound, cur_weapon.soundvolume)
		
		if (p == displayplayer or p == secondarydisplayplayer)
			P_StartQuake(15 * max(chargeprogress, FU/5), 12)
		end
		pt.cooldown = (firerate + (FixedMul((cur_weapon.maxfirerate - firerate)*FU, chargeprogress)/FU)) + 1
		pt.endlag = pt.cooldown
		
		proj.progress = chargeprogress
		if (chargeprogress >= FU)
			proj.damage = cur_weapon.maxdamage
		else
			proj.damage = cur_weapon.damage + FixedMul(cur_weapon.partialdamage - cur_weapon.damage, ease.inexpo(chargeprogress,0,FU))
		end
	else
		S_StartSoundAtVolume(me, cur_weapon.sounds[P_RandomRange(1, #cur_weapon.sounds)], cur_weapon.soundvolume)
	end
	
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
		cur_weapon.callbacks.onfire(p,pt,cur_weapon, proj, mom_vec, angle, dospread)
	end
	return proj
end

dofile("weapons/templates.lua")
dofile("weapons/def/FREESLOT.lua")