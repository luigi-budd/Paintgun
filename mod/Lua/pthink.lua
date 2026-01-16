local CV = Paint.CV
local MAX_SQUIDTIME = 3
local MAX_TRANSTIME = 6
local setalpha = false
local alphatrans = 0
local function addalpha(p)
	if p ~= displayplayer then return end
	if not setalpha
		alphatrans = min($ + 1, MAX_TRANSTIME)
	end
	setalpha = true
end

local clrstr_lut = {}

freeslot("SPR_PAINT_INKTANK")
rawset(_G,"CA2_SQUIDFORM", 132)

local ANGLE_CAP = FixedAngle(70*FU) >> 16
addHook("PlayerCmd",function(p,cmd)
	if not (p.paint and p.paint.active) then return end
	if cmd.aiming > ANGLE_CAP
		cmd.aiming = ANGLE_CAP
	elseif cmd.aiming < -ANGLE_CAP
		cmd.aiming = -ANGLE_CAP
	end
end)

Paint.basePlayer = {}
local BP = Paint.basePlayer

BP.doWeaponMobj = function(p,me,pt, cur_weapon, fireangle, dualieflip, reset_interp)
	local teleport = reset_interp and P_SetOrigin or P_MoveOrigin
	local dd = pt.dodgeroll
	
	local wepmo = pt.weaponmobj
	if dualieflip
		wepmo = pt.weaponmobjdupe
	elseif cur_weapon.guntype ~= WPT_DUALIES and (pt.weaponmobjdupe and pt.weaponmobjdupe.valid)
		P_RemoveMobj(pt.weaponmobjdupe)
		pt.weaponmobjdupe = nil
	end
	if not (wepmo and wepmo.valid)
		local mo = P_SpawnMobjFromMobj(me,0,0,0,MT_PAINT_GUN)
		mo.target = me
		mo.fireanim = 0
		if (dualieflip)
			pt.weaponmobjdupe = mo
		else
			pt.weaponmobj = mo
		end
		wepmo = mo
		teleport = P_SetOrigin
	end
	do
		local slope = InvAngle(p.aiming)
		wepmo.roll = FixedMul(slope, sin(p.drawangle))
		wepmo.pitch = FixedMul(slope, cos(p.drawangle))
	end
	wepmo.dontdrawforviewmobj = me
	wepmo.angle = fireangle
	wepmo.aiming = p.aiming
	local weapon_scale = cur_weapon:get(pt,"weaponstate_scale")
	wepmo.spritexscale = FixedMul(FU + (wepmo.fireanim * FU/12), weapon_scale)
	wepmo.spriteyscale = wepmo.spritexscale
	wepmo.destscale = me.scale
	wepmo.scalespeed = wepmo.destscale + 1
	wepmo.color = Paint:getPlayerColor(p)
	
	local finalstate = cur_weapon.weaponstate
	if dualieflip
	and cur_weapon:get(pt,"dualie_weaponstate") ~= nil
		finalstate = cur_weapon:get(pt,"dualie_weaponstate")
	elseif (cur_weapon.guntype == WPT_BRELLA)
		if (pt.deployshield or pt.shieldlag or (pt.shield and pt.shield.paint_hp <= 0) or pt.shieldlost)
		and cur_weapon:get(pt,"open_weaponstate") ~= nil
			finalstate = cur_weapon:get(pt,"open_weaponstate")
		end
	end
	wepmo.state = finalstate
	if cur_weapon:get(pt,"weaponstate_frame") ~= nil
		wepmo.frame = ($ &~FF_FRAMEMASK)|(cur_weapon:get(pt,"weaponstate_frame") & FF_FRAMEMASK)
	end
	wepmo.flags2 = ($ &~MF2_DONTDRAW)|((pt.hidden) and MF2_DONTDRAW or 0)
	wepmo.fireanim = max($-1, 0)
	
	local offx,offy = 0,0
	local firing = false
	if ((pt.deployshield or pt.shieldlag)
	or (pt.firewait or pt.fireheld or pt.endlag))
	and (pt.anglefix or pt.firewait)
		firing = true
	end
	
	if (cur_weapon.guntype == WPT_BRELLA)
	and (firing or pt.holsteranim)
	or (pt.turretmode)
		if not dualieflip
			if (firing or pt.turretmode)
				pt.holsteranim = min($ + 1, Paint.MAX_HOLSTER)
			else
				pt.holsteranim = max($-1, 0)
			end
			if (cur_weapon.guntype == WPT_DUALIES)
				pt.holsteranim = min($, Paint.MAX_HOLSTER - 2)
			end
		end
		local frac = FixedDiv(pt.holsteranim*FU, Paint.MAX_HOLSTER*FU)
		
		offx = P_ReturnThrustX(nil, fireangle, FixedMul(me.radius, frac))
		offy = P_ReturnThrustY(nil, fireangle, FixedMul(me.radius, frac))
		fireangle = $ + FixedAngle(90 * frac) * (dualieflip and -1 or 1)
	elseif not dualieflip
		pt.holsteranim = max($-1, 0)
	end
	local handoffset = {Paint:getWeaponOffset(me,pt,fireangle - ANGLE_90, cur_weapon, dualieflip, false)}
	local zoffset = (41*me.height)/48 - (12 * me.scale) + FixedMul(pt.weaponzoffset, me.scale)*P_MobjFlip(me)
	teleport(wepmo,
		me.x + handoffset[1] + offx,
		me.y + handoffset[2] + offy,
		me.z + zoffset
	)
	wepmo.angle = $ - FixedAngle(18 * FixedDiv(pt.weaponzoffset, Paint.IDLE_OFFSET) * (dualieflip and -1 or 1))
	if (P_MobjFlip(me) == -1)
		wepmo.z = $ - wepmo.height
		wepmo.eflags = $|MFE_VERTICALFLIP
	else
		wepmo.eflags = $ &~MFE_VERTICALFLIP
	end
	if (cur_weapon.guntype == WPT_CHARGER)
		if (pt.charge)
			local s = P_SpawnMobjFromMobj(wepmo,
				P_ReturnThrustX(nil, fireangle, FixedMul(cur_weapon:get(pt,"shineoffset"), me.scale)),
				P_ReturnThrustY(nil, fireangle, FixedMul(cur_weapon:get(pt,"shineoffset"), me.scale)),
				0,MT_PARTICLE
			)
			s.renderflags = $|RF_NOCOLORMAPS
			s.state = S_PAINT_FLAIR
			s.color = wepmo.color
			s.fuse = 2
			s.dispoffset = 20
			local frac = min(FixedDiv(pt.charge, cur_weapon:get(pt,"chargetime")),FU)
			s.alpha = clamp(0, frac-1, FU)
			P_SetScale(s, s.scale/2, true)
		end
		if pt.justcharged
			local fx = P_SpawnMobjFromMobj(wepmo,
				P_ReturnThrustX(nil, fireangle, FixedMul(cur_weapon:get(pt,"muzzleoffset"), me.scale)),
				P_ReturnThrustY(nil, fireangle, FixedMul(cur_weapon:get(pt,"muzzleoffset"), me.scale)),
				0,MT_PAINT_GUN
			)
			fx.state = S_PAINT_CHARGEDMAX
			fx.target = wepmo
			fx.tracer = me
			fx.weapon_id = pt.weapon_id
			fx.color = wepmo.color
			fx.renderflags = $|RF_NOCOLORMAPS|RF_ALWAYSONTOP
			fx.threshold = 1
		end
	/*
	elseif (cur_weapon.guntype == WPT_DUALIES)
		wepmo.angle = $ + FixedAngle(6 * (FU - FixedDiv(pt.weaponzoffset, Paint.IDLE_OFFSET)) * (dualieflip and -1 or 1))
	*/
	end
	if reset_interp
		wepmo.resetinterp = true
	end
end

-- ink tank mobj
BP.doInkTank = function(p)
	local me = p.realmo
	local pt = p.paint
	local weapon_t = Paint.weapons[pt.weapon_id]
	local sub_t
	if weapon_t
		sub_t = Paint.subs[weapon_t.subtype]
	end
	
	local tank = pt.tankmobj
	local teleport = P_MoveOrigin
	if not (tank and tank.valid)
		local tn = P_SpawnMobjFromMobj(me,0,0,0,MT_PAINT_GUN)
		tn.sprite = SPR_PAINT_INKTANK
		tn.frame = 1|FF_SEMIBRIGHT|FF_PAPERSPRITE
		tn.fuse = -1
		tn.tics = -1
		tn.dispoffset = 10
		tn.radius = 2*me.scale
		tn.height = 4*me.scale
		tn.dontdrawforviewmobj = me
		tn.renderflags = $|RF_NOCOLORMAPS
		
		local mid = P_SpawnMobjFromMobj(me,0,0,0,MT_PAINT_GUN)
		mid.sprite = SPR_PAINT_INKTANK
		mid.frame = 1|FF_SEMIBRIGHT|FF_PAPERSPRITE|FF_TRANS50
		mid.fuse = -1
		mid.tics = -1
		mid.dispoffset = 8
		mid.radius = 2*me.scale
		mid.height = 4*me.scale
		mid.dontdrawforviewmobj = me
		mid.color = SKINCOLOR_SUPERSILVER1
		mid.colorized = true
		mid.target = me
		mid.renderflags = $|RF_NOCOLORMAPS
		tn.target = mid
		
		local back = P_SpawnMobjFromMobj(me,0,0,0,MT_PAINT_GUN)
		back.sprite = SPR_PAINT_INKTANK
		back.frame = 0|FF_SEMIBRIGHT|FF_PAPERSPRITE
		back.fuse = -1
		back.tics = -1
		back.dispoffset = 7
		back.radius = 2*me.scale
		back.height = 4*me.scale
		back.dontdrawforviewmobj = me
		back.target = me
		tn.tracer = back
		
		local line = P_SpawnMobjFromMobj(me,0,0,0,MT_PAINT_GUN)
		line.sprite = SPR_PAINT_INKTANK
		line.frame = 4|FF_SEMIBRIGHT|FF_PAPERSPRITE
		line.fuse = -1
		line.tics = -1
		line.dispoffset = 11
		line.radius = 2*me.scale
		line.height = 4*me.scale
		line.dontdrawforviewmobj = me
		line.target = me
		tn.linemobj = line
		
		teleport = P_SetOrigin
		pt.tankmobj = tn
		tank = tn
	end
	if not (tank.tracer and tank.tracer.valid)
		P_RemoveMobj(tank)
		return
	end
	local sparkmove = P_MoveOrigin
	if pt.justrestored
		local spark = P_SpawnMobjFromMobj(me, 0,0,0, MT_PARTICLE)
		spark.state = S_PAINT_CHARGEDMAX
		spark.dispoffset = 10
		spark.color = SKINCOLOR_RED
		spark.dontdrawforviewmobj = me
		spark.drawonlyforplayer = p
		spark.renderflags = $|RF_NOCOLORMAPS|RF_ALWAYSONTOP
		spark.target = me
		spark.threshold = 1
		spark.scale = $ / 2
		tank.sparkfx = spark
		sparkmove = P_SetOrigin
	end
	
	local hide = pt.hidden
	
	tank.flags2 = ($ &~MF2_DONTDRAW)|((pt.inktank <= 0 or hide) and MF2_DONTDRAW or 0)
	tank.angle = p.drawangle + ANGLE_180
	local angle = tank.angle
	tank.spriteyscale = FixedDiv(max(pt.inktank - pt.inkqueue, 0), 100*FU)
	tank.color = Paint:getPlayerColor(p)
	teleport(tank,
		me.x + P_ReturnThrustX(nil, angle, me.radius + 4*me.scale),
		me.y + P_ReturnThrustY(nil, angle, me.radius + 4*me.scale),
		me.z + me.height*2/5
	)
	tank.angle = $ - ANGLE_90
	tank.destscale = me.scale
	tank.scalespeed = tank.destscale + 1
	tank.eflags = ($ &~MFE_VERTICALFLIP)|(me.eflags & MFE_VERTICALFLIP)
	--tank.alpha = me.alpha
	if (tank.sparkfx and tank.sparkfx.valid)
		sparkmove(tank.sparkfx,
			tank.x, tank.y,
			tank.z + 29*tank.scale
		)
		tank.sparkfx.flags2 = ($ &~MF2_DONTDRAW)|(hide and MF2_DONTDRAW or 0)
	end
	
	local back = tank.tracer
	back.angle = tank.angle
	back.flags2 = ($ &~MF2_DONTDRAW)|(hide and MF2_DONTDRAW or 0)
	teleport(back,
		me.x + P_ReturnThrustX(nil, angle, me.radius + 4*me.scale - (me.scale/32)),
		me.y + P_ReturnThrustY(nil, angle, me.radius + 4*me.scale - (me.scale/32)),
		me.z + me.height*2/5
	)
	back.destscale = me.scale
	back.scalespeed = back.destscale + 1
	back.eflags = ($ &~MFE_VERTICALFLIP)|(me.eflags & MFE_VERTICALFLIP)
	back.alpha = me.alpha
	if sub_t
		back.frame = ($ &~FF_FRAMEMASK)|((pt.inktank < sub_t:get(pt,"inkcost")) and 6 or 0)
	else
		back.frame = ($ &~FF_FRAMEMASK)|6
	end
	
	local mid = tank.target
	mid.angle = tank.angle
	mid.flags2 = ($ &~MF2_DONTDRAW)|(hide and MF2_DONTDRAW or 0)
	local shouldihide = true
	if (pt.inkdelay > 0)
	or (pt.inktank - pt.inkqueue < pt.oldinktank)
		shouldihide = false
	end
	mid.flags2 = $|(shouldihide and MF2_DONTDRAW or 0)
	mid.spriteyscale = FixedDiv(pt.oldinkanim, 100*FU)
	teleport(mid,
		me.x + P_ReturnThrustX(nil, angle, me.radius + 4*me.scale - (me.scale/16)),
		me.y + P_ReturnThrustY(nil, angle, me.radius + 4*me.scale - (me.scale/16)),
		me.z + me.height*2/5
	)
	mid.destscale = me.scale
	mid.scalespeed = mid.destscale + 1
	mid.eflags = ($ &~MFE_VERTICALFLIP)|(me.eflags & MFE_VERTICALFLIP)
	--mid.alpha = me.alpha
	
	local line = tank.linemobj
	line.angle = tank.angle
	line.flags2 = ($ &~MF2_DONTDRAW)|(hide and MF2_DONTDRAW or 0)
	line.color = SKINCOLOR_RED
	if sub_t
		line.spriteyoffset = FixedMul(23*FU, FixedDiv(sub_t:get(pt,"inkcost"), 100*FU))
	else
		line.flags2 = $|MF2_DONTDRAW
	end
	teleport(line,
		me.x + P_ReturnThrustX(nil, angle, me.radius + 4*me.scale + (me.scale/32)),
		me.y + P_ReturnThrustY(nil, angle, me.radius + 4*me.scale + (me.scale/32)),
		me.z + me.height*2/5
	)
	line.destscale = me.scale
	line.scalespeed = line.destscale + 1
	line.eflags = ($ &~MFE_VERTICALFLIP)|(me.eflags & MFE_VERTICALFLIP)
	line.alpha = me.alpha
	
	tank.pitch,tank.roll = 0,0
	back.pitch,back.roll = 0,0
	mid.pitch,mid.roll = 0,0
	line.pitch,line.roll = 0,0
end

-- takes about 11 seconds to fully refill passively with no ink-related abilities...
local ink_refill_rate = FixedDiv(100*FU, 11*TR*FU)
-- ...and 3 seconds when submerged
local fast_ink_refill_rate = FixedDiv(100*FU, 3*TR*FU)

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
	blob.renderflags = $|RF_NOCOLORMAPS|RF_SEMIBRIGHT
	return blob
end

local cv_hidetime = CV.FindVar("hidetime")
addHook("PlayerThink",function(p)
	local me = p.mo
	if p.playerstate == PST_REBORN
	and p.paint
		p.paint.hp = 100*FU
	end
	if not (me and me.valid and me.health)
		if p.paint
			local dd = p.paint.dodgeroll
			if (dd.tics or dd.getup)
			and (me.state ~= S_PLAY_DEAD or me.state ~= S_PLAY_DRWN)
				me.state = S_PLAY_DEAD
			end
			Paint:resetPlayer(p)
			if (me and me.valid)
				me.spriteyscale = FU
			end
		end
		return
	end
	
	if not p.paint
		Paint:initPlayer(p)
		Paint:giveWeapon(p, "basic")
		Paint:giveWeapon(p, "rapid")
		Paint:giveWeapon(p, "charger")
		Paint:giveWeapon(p, "blaster")
		Paint:giveWeapon(p, "dualies")
		Paint:giveWeapon(p, "brella")
		--Paint:giveWeapon(p, "SIGMA")
	end
	local pt = p.paint
	local skin = skins[p.skin]
	
	if (not Paint:isMode()
	and not CV.paintguns.value)
	or (me.paint_inactive)
		if pt.active
			local wepmo = pt.weaponmobj
			if (wepmo and wepmo.valid)
				P_RemoveMobj(wepmo)
			end
			wepmo = pt.weaponmobjdupe
			if (wepmo and wepmo.valid)
				P_RemoveMobj(wepmo)
			end
			wepmo = pt.tankmobj
			if (wepmo and wepmo.valid)
				if (wepmo.tracer and wepmo.tracer.valid)
					P_RemoveMobj(wepmo.tracer)
				end
				P_RemoveMobj(wepmo)
			end
			
			Paint:resetPlayer(p)
			p.charflags = $|(skin.flags & SF_DASHMODE)
			p.charability = skin.ability
			p.charability2 = skin.ability2
			p.normalspeed = skin.normalspeed
			p.shieldscale = skin.shieldscale
		end
		
		pt.active = false
		return
	end
	pt.active = true
	
	if p.gotflag
		pt.disable.main = true
		pt.disable.sub = true
	end
	if (gametyperules & GTR_HIDEFROZEN)
	and not (p.pflags & PF_TAGIT)
	and (leveltime >= cv_hidetime.value*TR)
		pt.disable.main = true
		pt.disable.sub = true
	end
	if (p.exiting)
		pt.disable.swimming = true
	end

	if pt.disable.main
		local wepmo = pt.weaponmobj
		if (wepmo and wepmo.valid)
			P_RemoveMobj(wepmo)
		end
		wepmo = pt.weaponmobjdupe
		if (wepmo and wepmo.valid)
			P_RemoveMobj(wepmo)
		end
	end
	if pt.disable.inktank
		local wepmo = pt.tankmobj
		if (wepmo and wepmo.valid)
			if (wepmo.tracer and wepmo.tracer.valid)
				P_RemoveMobj(wepmo.tracer)
			end
			P_RemoveMobj(wepmo)
		end
	end
	
	--lol
	if Paint:isMode()
	or (Paint.CV.paintnerfs.value == 1)
	and (not (p.pflags & PF_TAGIT))
		p.dashmode = 0
		p.charflags = $|SF_NOSHIELDABILITY &~SF_DASHMODE
		p.charability = CA_NONE
		p.charability2 = CA2_SQUIDFORM
		p.wasmode = true
	elseif p.wasmode
		p.charflags = $|(skin.flags & SF_DASHMODE)
		p.charability = skin.ability
		p.charability2 = skin.ability2
		p.wasmode = nil
	end
	if (p.pflags & PF_TAGIT)
	or (Paint.CV.paintnerfs.value == -1)
		p.charability2 = CA2_SQUIDFORM
	end
	
	me.alpha = FU
	me.jumptime = $ or 0
	pt.spreadadd = 0
	
	local doslowdown = false
	local fireangle = p.cmd.angleturn << 16
	pt.old_weaponid = pt.weapon_id
	do
		local sel = 0
		if (p.cmd.buttons & BT_WEAPONNEXT)
		and not (p.lastbuttons & BT_WEAPONNEXT)
			sel = $ + 1
		end
		if (p.cmd.buttons & BT_WEAPONPREV)
		and not (p.lastbuttons & BT_WEAPONPREV)
			sel = $ - 1
		end
		if sel ~= 0
		and not ((pt.endlag or pt.shieldlag or pt.lastslowdown)
		or (pt.turretmode or pt.dodgeroll.tics or pt.dodgeroll.getup))
			pt.inventory.curslot = $ + sel
			if pt.inventory.curslot > pt.inventory.slots
				pt.inventory.curslot = 1
			elseif pt.inventory.curslot < 1
				pt.inventory.curslot = pt.inventory.slots
			end
			S_StartSound(nil,sfx_menu1,p)
		end
	end
	
	pt.weapon_id = pt.inventory.items[pt.inventory.curslot]
	local cur_weapon = Paint.weapons[pt.weapon_id]
	if cur_weapon == nil then
		local wepmo = pt.weaponmobj
		if (wepmo and wepmo.valid)
			P_RemoveMobj(wepmo)
			pt.weaponmobj = nil
		end
		wepmo = pt.weaponmobjdupe
		if (wepmo and wepmo.valid)
			P_RemoveMobj(wepmo)
			pt.weaponmobjdupe = nil
		end
		return
	end
	local sub_t = Paint.subs[cur_weapon.subtype]
	p.weapondelay = max($, 5)
	
	-- brella shield
	pt.shieldwait = max($-1, 0)
	if (pt.shieldlag)
		pt.shieldlag = $ - 1
		
		if pt.shieldlag == 0
			S_StartSound(me, cur_weapon:get(pt,"stowsound") or sfx_none)
		end
		doslowdown = true
	end
	
	-- handle shield / brella canopy here
	-- brella thinker / shield thinker
	local shieldout = false
	pt.deployshield = false
	if (cur_weapon.guntype == WPT_BRELLA)
		local sh = pt.shield
		if not (sh and sh.valid)
			local s = P_SpawnMobjFromMobj(me,0,0,0,MT_BRELLA_SHIELD)
			s.tracer = me
			s.target = me --im a lazy bum
			s.tracer_player = p
			s.paint_maxhp = cur_weapon:get(pt,"shieldhp")
			s.paint_hp = s.paint_maxhp
			s.paint_delay = 0
			s.paint_shield = true
			s.paint_destroyed = false
			s.paint_explodebombs = true
			s.cooldown = 0
			s.weapon_id = pt.weapon_id
			s.dontdrawforviewmobj = me
			s.dispoffset = 50
			
			s.paint_overlay = P_SpawnMobjFromMobj(s, 0,0,0, MT_OVERLAY)
			s.paint_overlay.target = s
			s.paint_overlay.tics, s.paint_overlay.fuse = -1,-1
			s.paint_overlay.dontdrawforviewmobj = me
			s.paint_overlay.colorized = true
			s.paint_overlay.renderflags = $|RF_SEMIBRIGHT|RF_NOCOLORMAPS
			
			pt.shield = s
			sh = s
		end
		local scale = cur_weapon:get(pt,"shieldscale")
		sh.spritexscale = scale
		sh.spriteyscale = scale
		sh.paint_scale = scale
		
		local newstate = cur_weapon:get(pt,"shieldstate")
		if newstate ~= nil
			sh.state = newstate
		elseif sh.state ~= sh.info.spawnstate
			sh.state = sh.info.spawnstate
		end
		
		sh.angle = fireangle
		sh.color = Paint:getPlayerColor(p)
		
		if (pt.shieldlag == Paint.CANOPY_ANIM)
		or (pt.shieldlag and ((cur_weapon:get(pt,"deployend") or cur_weapon:get(pt,"endlag")) <= Paint.CANOPY_ANIM))
		and (sh.threshold == 0)
			sh.threshold = Paint.CANOPY_ANIM
		end
		
		-- this keeps the shield out
		if not (pt.shieldwait)
		and (pt.fireheld >= cur_weapon:get(pt,"deploydelay"))
		and (pt.shotsfired)
		and (sh.paint_hp > 0)
		and not (cur_weapon:get(pt,"nocanopy") or pt.shieldlost)
			pt.deployshield = true
			if not pt.wasdeployed
				S_StartSound(me, cur_weapon:get(pt,"deploysound") or sfx_none)
				sh.threshold = Paint.CANOPY_ANIM
				
				sh.spritexscale = FixedMul($, FU*4/3)
				sh.spriteyscale = 1
				P_SetOrigin(sh, sh.x,sh.y,sh.z)
				sh.resetinterp = true
			end
			pt.inkdelay = cur_weapon:get(pt,"inkdelay_held")
			pt.maxinkdelay = pt.inkdelay
		end
		if not pt.deployshield
		and pt.wasdeployed
			local dlag = cur_weapon:get(pt,"deployend")
			if dlag == nil
				dlag = cur_weapon:get(pt,"endlag")
			end
			pt.shieldlag = dlag
			if not dlag
				S_StartSound(me, cur_weapon:get(pt,"stowsound") or sfx_none)
			end
		end
		if pt.shieldlag
			pt.fireheld = 0
			if not pt.nofiring
				p.cmd.buttons = $ &~BT_ATTACK
			end
		end
		
		if (pt.shieldlost)
		or sh.paint_destroyed
			pt.shieldlosttime = $ + 1
			
			if pt.shieldlosttime == cur_weapon:get(pt,"shieldrecover")
				S_StartSound(nil, cur_weapon:get(pt,"recoversound") or sfx_p_s5_8, p)
				pt.shieldlost = false
				sh.paint_hp = sh.paint_maxhp
				pt.shieldlosttime = 0
			end
		else
			pt.shieldlosttime = 0
		end
		
		if (pt.deployshield or pt.shieldlag)
		and (sh.paint_hp > 0)
		and not pt.shieldlost
			-- visible
			sh.flags2 = $ &~MF2_DONTDRAW
			sh.flags = $|MF_SHOOTABLE &~(MF_NOCLIP|MF_NOCLIPTHING)
			if (pt.shotsfired >= 1)
				shieldout = true
				pt.shieldtime = $ + 1
				
				local inkcost = cur_weapon:get(pt,"inkcost")
				local abovefiring = pt.inktank >= inkcost
				pt.inktank = max($ - cur_weapon:get(pt,"shieldinkuse"), 0)
				if pt.inktank <= 0
				or (abovefiring and pt.inktank < inkcost)
					pt.fireheld = 0
					pt.nofiring = true
					Paint.HUD:lowInkWarning(p, TR/2)
				end
			end
			
			-- release the shield / canopy
			-- this should also release BT_ATTACK once the canopy releases
			if pt.shieldtime >= cur_weapon:get(pt,"shieldrelease")
			and (p.cmd.buttons & BT_ATTACK)
				pt.shieldlost = true
				pt.shieldjustbroke = true
				pt.fireheld = 0
				pt.nofiring = true
				
				pt.inkdelay = max($, cur_weapon:get(pt,"inkdelay_release"))
				pt.maxinkdelay = max($, pt.inkdelay)
				S_StartSound(nil, cur_weapon:get(pt,"releasesound") or sfx_p_s5_9, p)
				
				local dupe = P_SpawnMobjFromMobj(me, 0,0,0, MT_BRELLA_SHIELD)
				dupe.tracer = me
				dupe.target = me
				dupe.tracer_player = p
				dupe.paint_maxhp = cur_weapon:get(pt,"shieldhp")
				dupe.paint_hp = sh.paint_maxhp
				dupe.paint_delay = 0
				dupe.paint_shield = true
				dupe.paint_destroyed = false
				dupe.paint_explodebombs = true
				dupe.paint_released = true
				dupe.shieldspeed = FixedMul(cur_weapon:get(pt,"shieldspeed"), me.scale)
				dupe.cooldown = 0
				dupe.weapon_id = pt.weapon_id
				dupe.angle = sh.angle
				dupe.fuse = cur_weapon:get(pt,"shieldlifetime")
				dupe.spritexscale = sh.paint_scale
				dupe.spriteyscale = sh.paint_scale
				dupe.paint_scale = sh.paint_scale
				dupe.color = sh.color
				dupe.state = sh.state
				dupe.flags = $|MF_SLIDEME &~(MF_NOGRAVITY|MF_NOCLIPHEIGHT)
				dupe.shieldsound = cur_weapon:get(pt,"shieldsound") or sfx_p_s5_a
				
				dupe.paint_overlay = P_SpawnMobjFromMobj(dupe, 0,0,0, MT_OVERLAY)
				dupe.paint_overlay.target = dupe
				dupe.paint_overlay.tics, dupe.paint_overlay.fuse = -1,-1
				dupe.paint_overlay.dontdrawforviewmobj = me
				dupe.paint_overlay.colorized = true
				dupe.paint_overlay.renderflags = $|RF_SEMIBRIGHT|RF_NOCOLORMAPS
				P_SetOrigin(dupe, sh.x, sh.y, sh.z)
			end
			
			if (P_IsObjectOnGround(me))
			and (leveltime % 3 == 0)
				local trail = P_SpawnMobjFromMobj(sh, 0,0,FU, MT_PAINT_SHOT)
				trail.target = me
				trail.tracer_p = p
				trail.color = sh.color
				trail.angle = sh.angle
				trail.trail = true
				trail.lifespan = 0
				trail.nosound = true
				trail.flags = $|MF_NOCLIPTHING &~(MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOCLIP)
				trail.frame = ($ &~FF_FRAMEMASK)|2
				trail.weapon_id = sh.weapon_id
				trail.flags2 = $|MF2_DONTDRAW
			end
		else
			-- hidden
			sh.flags2 = $|MF2_DONTDRAW
			sh.flags = $|MF_NOCLIP|MF_NOCLIPTHING &~MF_SHOOTABLE
			pt.shieldtime = 0
			if not sh.paint_destroyed
				if sh.paint_hp ~= sh.paint_maxhp
					sh.paint_hp = min($ + FixedDiv(cur_weapon:get(pt,"shieldregen"), TR*FU), sh.paint_maxhp)
				else
					sh.paint_color = nil
				end
			end
		end
		
		--print(pt.shieldtime)
		
		local move = me.radius + 16*me.scale
		P_MoveOrigin(sh,
			me.x + P_ReturnThrustX(nil,fireangle,move) + me.momx,
			me.y + P_ReturnThrustY(nil,fireangle,move) + me.momy,
			me.z + me.momz
		)
		if (P_MobjFlip(me) == -1)
			sh.z = $ - sh.height
			sh.eflags = $|MFE_VERTICALFLIP
		else
			sh.eflags = $ &~MFE_VERTICALFLIP
		end
		sh.health = sh.info.spawnhealth
		sh.lasthit = nil
		sh.cooldown = max($ - 1, 0)
	else
		local sh = pt.shield
		if (sh and sh.valid)
			sh.flags2 = $|MF2_DONTDRAW
			sh.flags = $|MF_NOCLIP|MF_NOCLIPTHING &~MF_SHOOTABLE
		end
	end
	pt.wasdeployed = pt.deployshield
	
	if not P_IsObjectOnGround(me)
	and (p.pflags & PF_JUMPED)
	and not (cur_weapon.guntype == WPT_DUALIES and (pt.dodgeroll.tics or pt.dodgeroll.getup))
		if not (me.jumptime)
			pt.spreadjump = cur_weapon:get(pt,"spread_jump")
		end
		me.jumptime = $ + 1
	else
		me.jumptime = 0
	end
	if pt.spreadjump
	and cur_weapon:get(pt,"spread_jumpspread") ~= 0
		local jumptime = cur_weapon:get(pt,"spread_jump")
		pt.spreadadd = ease.incubic(FU - ((FU/jumptime) * pt.spreadjump), cur_weapon:get(pt,"spread_jumpspread"), 0)
		pt.spreadjump = $ - 1
	end
	
	local waspressingattack = (p.cmd.buttons & BT_ATTACK)
	local justpressedfire = false
	if p.exiting
		p.cmd.buttons = $ &~BT_ATTACK
	end
	if not (p.exiting)
		if pt.store_lag
			pt.buttons = $ &~BT_SPIN
			p.cmd.buttons = $ &~BT_SPIN
		end
		
		if (pt.buttons & BT_SPIN)
			pt.spinheld = $ + 1
		else
			pt.spinheld = 0
		end
		
		if (p.cmd.buttons & BT_ATTACK)
		and not (pt.nofiring or pt.disable.main)
			if not pt.fireheld
				justpressedfire = true
				pt.firewait = cur_weapon.startlag
				if (cur_weapon.guntype == WPT_BRELLA)
					if not (pt.cooldown or pt.endlag or pt.shieldlag)
						S_StartSound(me, cur_weapon:get(pt,"readysound") or sfx_none)
					elseif (pt.cooldown < cur_weapon:get(pt,"firerate") * 3/4)
						pt.firequeued = true
					end
				end
			end
			pt.fireheld = $ + 1
			p.cmd.buttons = $|BT_ATTACK
			
			if (pt.spinheld and pt.spinheld < pt.fireheld)
				pt.fireheld = 0
				p.cmd.buttons = $ &~BT_ATTACK
				pt.nofiring = true
				
				-- store a charge
				if (cur_weapon.guntype == WPT_CHARGER)
				and (p.charability2 == CA2_SQUIDFORM)
					if (cur_weapon:get(pt,"storecharges")
					and (cur_weapon:get(pt,"partialstorage") or (pt.charge >= cur_weapon:get(pt,"chargetime"))))
						pt.storedcharge = pt.charge
					end
					pt.charge = 0
					local charge_sound = cur_weapon:get(pt,"charging_sound", p)
					local slow_charge_sound = cur_weapon:get(pt,"slow_charging_sound", p)
					S_StopSoundByID(me, charge_sound)
					S_StopSoundByID(me, slow_charge_sound)
					
					pt.maxcharged = false
					pt.justcharged = false
					pt.wasfastcharging = false
				end
			end
		else
			if (pt.fireheld or (p.cmd.buttons & BT_ATTACK)) and pt.disable.main
				Paint.HUD:cantUseWarning(p, TR/2)
			end
			
			pt.fireheld = 0
			if not (p.cmd.buttons & BT_ATTACK)
				pt.nofiring = false
			elseif pt.nofiring
				p.cmd.buttons = $ &~BT_ATTACK
			end
		end
		
		if pt.firewait == 1
			justpressedfire = true
			pt.fireheld = $ + 1
			p.cmd.buttons = $|BT_ATTACK
		end
		if pt.firequeued
			if pt.cooldown == 1
				p.cmd.buttons = $ &~BT_ATTACK
				pt.fireheld = 0
			elseif pt.cooldown == 0
				p.cmd.buttons = $|BT_ATTACK
				pt.fireheld = $ + 1
				pt.firequeued = false
				justpressedfire = true
			end
		end
		
		if (pt.buttons & BT_JUMP)
			pt.jumpheld = $ + 1
		else
			pt.jumpheld = 0
		end
	else
		pt.fireheld = 0
	end
	if not (p.cmd.buttons & BT_ATTACK or pt.fireheld)
	and not (pt.cooldown or pt.firewait or pt.endlag or pt.shieldlag)
		pt.shotsfired = 0
		pt.shieldjustbroke = false
	end
	
	-- squid form / swim form
	local clrstr = clrstr_lut[Paint:getPlayerColor(p)]
	if clrstr == nil
		clrstr_lut[Paint:getPlayerColor(p)] = ("~%.3d"):format(skincolors[Paint:getPlayerColor(p)].ramp[6])
	end
	
	local standing_pic,standing_sector = Paint.CheckFloorPic(me, true)
	if P_IsObjectOnGround(me)
	and standing_pic == clrstr
		Paint:setPlayerInInk(p, Paint.ININK_FRIENDLY)
	end
	
	p.shieldscale = skin.shieldscale
	pt.squidtoggle = false
	do
		local maxsquish = (pt.inink == Paint.ININK_FRIENDLY and FU*4/100 or FU/2)
		local easing = ease.inquad
		local oldclimbing = (pt.hidden and pt.wallink)
		pt.hidden = false
		
		if (p.cmd.buttons & BT_SPIN)
		and not ((pt.endlag or pt.shieldlag or pt.firewait /*or pt.cooldown*/ or pt.justfired or (pt.charge ~= 0))
		/*or (pt.cooldown)*/)
		and (p.charability2 == CA2_SQUIDFORM)
		and not (pt.dodgeroll.tics or pt.dodgeroll.getup)
		and not (pt.squidlag)
		and not (pt.fireheld > 1)
		and not (pt.disable.swimming)
			if not pt.wasinsquid
				S_StartSound(me,sfx_pt_tos)
			end
			
			pt.squidtoggle = true
			pt.squidtime = min($ + 1, MAX_SQUIDTIME)
			local frac = (FU/MAX_SQUIDTIME)*pt.squidtime
			--me.height = easing(frac, $, 22*me.scale)
			me.spriteyscale = easing(frac, FU, maxsquish)
			--pt.fireheld = 0
			--p.cmd.buttons = $ &~BT_ATTACK
			pt.wasinsquid = true
		else
			if pt.wasinsquid
				S_StartSound(me,sfx_pt_toh)
				if pt.fireheld ~= 0
					pt.fireheld = 1
					justpressedfire = true
				end
				if pt.storedcharge
					S_StartSound(nil, sfx_pt_kth, p)
					pt.charge = pt.storedcharge
					pt.store_lag = cur_weapon:get(pt,"storagelag")
					pt.store_firelag = cur_weapon:get(pt,"storagelaserlag")
					
					pt.storedcharge = 0
					pt.store_time = 0
				end
				pt.nofiring = false
			end
			S_StopSoundByID(me,sfx_pt_swm)
			
			local frac = FU - (FU/MAX_SQUIDTIME)*pt.squidtime
			--me.height = easing(frac, 22*me.scale, $)
			me.spriteyscale = easing(frac, maxsquish, FU)
			pt.squidtime = max($ - 1, 0)
			pt.wasinsquid = false
		end
		if pt.squidlag then pt.squidlag = $ - 1; end
		pt.justfired = false
		
		local dostoreaura = false
		p.charflags = ($ &~(SF_NOSKID|SF_NOJUMPSPIN))|(skin.flags & (SF_NOSKID|SF_NOJUMPSPIN))
		p.normalspeed = skin.normalspeed * 60 / 100
		p.thrustfactor = skin.thrustfactor
		p.accelstart = skin.accelstart
		p.acceleration = skin.acceleration
		local wallangle = me.angle - ANGLE_90
		if (pt.squidtime >= MAX_SQUIDTIME)
			local touchingwall = false
			if (p.lastlinehit ~= -1)
			and (pt.wallink and not P_IsObjectOnGround(me))
				local line = lines[p.lastlinehit]
				local ox,oy = P_ClosestPointOnLine(me.x,me.y, line)
				wallangle = R_PointToAngle2(
					line.v1.x, line.v1.y, line.v2.x, line.v2.y
				) - ANGLE_90*(P_PointOnLineSide(me.x,me.y, line) and 1 or -1)
				wallangle = $ - ANGLE_90 -- lol
				
				if R_PointToDist2(me.x + me.momx, me.y + me.momy, ox,oy) <= me.radius + 12*me.scale
					touchingwall = true
					local ang = R_PointToAngle2(me.x + me.momx, me.y + me.momy, ox,oy)
					if abs(ang) ~= ANGLE_45
						P_Thrust(me,
							ang,
							me.scale / 8
						)
					end
				end
			end
			local wallclimb = (pt.wallink and (p.powers[pw_pushing] or touchingwall))
			
			p.charflags = $|SF_NOSKID
			if (pt.inink == Paint.ININK_FRIENDLY and P_IsObjectOnGround(me))
			or wallclimb
				me.flags2 = $|MF2_DONTDRAW
				pt.hidden = true
				p.shieldscale = 0
				pt.squidanim = TR/2
				p.pflags = $ &~(PF_SPINNING)
				if (me.state == S_PLAY_ROLL)
					me.state = S_PLAY_WALK
					P_MovePlayer(p)
				end
				
				p.normalspeed = skin.normalspeed
				p.thrustfactor = $*6/4
				if pt.substrafe 
					p.accelstart = $ * 4
					p.acceleration = $ * 2
				elseif (wallclimb and not P_IsObjectOnGround(me))
					p.accelstart = 0
					p.acceleration = 0
				end
				
				me.friction = FixedMul($, FU*97/100)
				if (p.cmd.forwardmove == 0 and p.cmd.sidemove == 0)
					local fric = FU * 9/10
					me.momx = FixedMul($, fric)
					me.momy = FixedMul($, fric)
				end
			else
				p.normalspeed = $/3
			end
			
			if wallclimb
				if not (pt.wasclimbing) and me.last_speed
					P_SetObjectMomZ(me,FixedDiv(me.last_speed,me.scale)/2,true)
				end
				
				if (p.cmd.forwardmove > 0)
					P_SetObjectMomZ(me, p.normalspeed/28, true)
				elseif (me.momz * P_MobjFlip(me) < 0)
					me.momz = $ + P_GetMobjGravity(me)/2
				end
				if (p.cmd.sidemove ~= 0)
					local frac = FixedDiv(p.cmd.sidemove*FU, 50*FU)
					P_Thrust(me, wallangle, FixedMul(me.scale, frac))
				end
				
				if (pt.jumpheld == 1)
					P_SetObjectMomZ(me, 3*FU, true)
					S_StartSound(me, sfx_pt_ijm, p)
					pt.spreadjump = cur_weapon:get(pt,"spread_jump")
				end
				
				me.momz = FixedMul($, FU*98/100)
				pt.wasclimbing = true
				p.pflags = $ &~PF_STARTJUMP
			else
				if pt.wasclimbing
					me.momz = $/3
				end
				pt.wasclimbing = false
			end
			
			if pt.hidden
				local cando = true
				if (wallclimb and not (p.cmd.forwardmove > 0 or p.cmd.sidemove ~= 0))
					cando = false
				end
				if (FixedHypot(FixedHypot(me.momx,me.momy), me.momz) >= 12*me.scale)
				and cando
					if not S_SoundPlaying(me, sfx_pt_swm)
						S_StartSoundAtVolume(me,sfx_pt_swm,255/2, p)
					end
					local blob = makeBlob(p,me,pt, 0,0)
					blob.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT &~(MF_NOGRAVITY)
					P_SetOrigin(blob, me.x, me.y, blob.z)
					if (pt.wasclimbing)
						local h_ang = Paint:controlDir(p)
						local v_ang = FixedAngle(P_RandomFixedRange(-25*FU,25*FU))
						local v_speed = P_RandomRange(5,10)*me.scale
						P_Thrust(blob,h_ang, -P_RandomRange(1,3)*me.scale)
						P_Thrust(blob,h_ang+ANGLE_90, FixedMul(v_speed, sin(v_ang)) )
						
						blob.momz = $ + me.momz/2
					else
						local ang = R_PointToAngle2(0,0,me.momx,me.momy) + FixedAngle(P_RandomFixedRange(-25*FU,25*FU))
						P_SetObjectMomZ(blob, P_RandomRange(1,3)*FU)
						P_Thrust(blob,ang, -P_RandomRange(6,15)*me.scale)
						
						blob.momx = $ + me.momx
						blob.momy = $ + me.momy
						
						if (leveltime % 2 == 0)
						and (FixedHypot(FixedHypot(me.momx,me.momy), me.momz) >= 20*me.scale)
							local range = 128
							local wind = P_SpawnMobjFromMobj(me,
								P_RandomRange(-range, range)*FU,
								P_RandomRange(-range, range)*FU,
								P_RandomRange(0, range)*FU,
								MT_THOK
							)
							wind.blendmode = AST_ADD
							wind.renderflags = RF_SEMIBRIGHT|RF_PAPERSPRITE
							wind.sprite = SPR_RAIN
							wind.rollangle = ANGLE_90
							wind.angle = R_PointToAngle2(0,0,me.momx,me.momy)
							wind.drawonlyforplayer = p
						end
					end
					
					blob.destscale = 0
					blob.scalespeed = FixedDiv(blob.scale, blob.fuse*FU)
				else
					S_StopSoundByID(me,sfx_pt_swm)
				end
				
				if (pt.hp ~= 100*FU)
					local rad = FixedDiv(me.radius,me.scale)/FU
					local blob = makeBlob(p,me,pt, rad,0)
					blob.fuse = TR/2
					blob.scale = $/2
					blob.destscale = me.scale
					blob.scalespeed = FixedDiv(blob.destscale - blob.scale, blob.fuse*FU)
					blob.color = (pt.paintoverlay and pt.paintoverlay.valid) and pt.paintoverlay.color or ColorOpposite(Paint:getPlayerColor(p))
				end
				
				local angle,thrust = Paint.slopeInfluence(me,p, {
					allowstand = true, allowmult = true
				})
				if angle ~= nil
					P_Thrust(me,angle,-thrust)
				end
			else
				S_StopSoundByID(me,sfx_pt_swm)
			end
			pt.wallink = max($ - 1, 0)
			
			if pt.storedcharge
				dostoreaura = true
				
				local maxtime = cur_weapon:get(pt,"storagetime")
				pt.store_time = $ + 1
				if pt.store_time >= maxtime
				or not ((p.cmd.buttons & BT_ATTACK) or waspressingattack)
					pt.storedcharge = 0
				end
			else
				pt.store_time = 0
			end
		else
			pt.wallink = 0
			
			if pt.wasclimbing
				me.momz = $/3
			end
			pt.wasclimbing = false
		end
		if me.last_hidden ~= pt.hidden
		and me.last_hidden ~= nil
			if not ((pt.wasclimbing or pt.wallink) or oldclimbing)
				local splash = P_SpawnMobjFromMobj(me, 0,0,0, MT_PARTICLE)
				P_SetOrigin(splash, splash.x,splash.y, me.floorz)
				splash.state = S_PAINT_SPLASH
				splash.color = Paint:getPlayerColor(p)
				splash.renderflags = $|RF_SEMIBRIGHT|RF_NOCOLORMAPS
				P_SetScale(splash, splash.scale + P_RandomFixed()/2, true)
			end
			S_StartSound(me, sfx_splish)
		end
		me.last_hidden = pt.hidden
		me.last_speed = FixedHypot(me.momx,me.momy)
		if dostoreaura
			local aura = pt.store_aura
			if not (aura and aura.valid)
				local g = P_SpawnMobjFromMobj(me, 0,0,2*FU, MT_PARTICLE)
				g.sprite = SPR_PAINT_MISC
				g.frame = 32|FF_FULLBRIGHT|FF_ADD
				g.renderflags = $|RF_NOCOLORMAPS
				pt.store_aura = g
				aura = g
			end
			
			aura.angle = wallangle
			local maxtime = cur_weapon:get(pt,"storagetime")
			if (pt.hidden)
				aura.renderflags = $|RF_FLOORSPRITE
				if (pt.wallink and not P_IsObjectOnGround(me))
					aura.renderflags = $|RF_PAPERSPRITE &~RF_FLOORSPRITE
				end
			else
				aura.renderflags = $ &~(RF_FLOORSPRITE|RF_PAPERSPRITE)
			end
			aura.color = Paint:getPlayerColor(p)
			if pt.store_time > maxtime - TR/2
				aura.alpha = FU - FixedDiv((pt.store_time - (maxtime - TR/2))*FU, (TR/2)*FU)
			end
			P_MoveOrigin(aura, me.x + me.momx, me.y + me.momy, me.z + me.momz + (6*me.scale))
		elseif (pt.store_aura and pt.store_aura.valid)
			P_RemoveMobj(pt.store_aura)
			pt.store_aura = nil
		end
		
		if pt.inink == Paint.ININK_ENEMY
			p.normalspeed = $ * 3/5
		end
		if (pt.squidanim)
			me.colorized = true
			pt.squidanim = $ - 1
			if pt.squidanim == 0
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
				me.colorized = false
			end
		end
	end
	
	if pt.store_lag
		pt.fireheld = max($, 1)
		p.cmd.buttons = $|BT_ATTACK
		pt.store_lag = $ - 1
		
		if pt.store_lag == 0
			if P_IsObjectOnGround(me)
				me.state = S_PLAY_WALK
				P_MovePlayer(p)
			else
				if (me.momz * P_MobjFlip(me) > 0)
					me.state = S_PLAY_SPRING
				else
					me.state = S_PLAY_FALL
				end
			end
			
			local charge_sound = cur_weapon:get(pt,"charging_sound", p)
			--local slow_charge_sound = cur_weapon:get(pt,"slow_charging_sound", p)
			if pt.charge < cur_weapon:get(pt,"chargetime")
				S_StartSound(me,charge_sound, p)
			end
		elseif me.state ~= S_PLAY_ROLL
			me.state = S_PLAY_ROLL
		end
	end
	if pt.store_firelag
		pt.store_firelag = $ - 1
	end
	
	pt.fastrefill = false
	if pt.inkdelay
		if not pt.fireheld
			pt.inkdelay = $ - 1
		end
		pt.oldinkanim = ease.linear(FU - FixedDiv(pt.inkdelay*FU, (pt.maxinkdelay or 1)*FU), pt.oldinktank, pt.inktank)
	elseif pt.inktank ~= 100*FU
	and not pt.fireheld
	and not pt.inkqueue
		pt.maxinkdelay = 0
		local oldtank = pt.inktank
		if pt.hidden
			pt.inktank = $ + fast_ink_refill_rate
			pt.fastrefill = true
		else
			pt.inktank = $ + ink_refill_rate
		end
		if oldtank < sub_t:get(pt,"inkcost")
		and pt.inktank >= sub_t:get(pt,"inkcost")
			S_StartSound(nil, sfx_pt_srd, p)
			pt.justrestored = true
		end
		pt.inktank = min($, 100*FU)
	end
	
	pt.justcharged = false
	pt.inkqueue = 0
	if not pt.squidtoggle
		if (cur_weapon.guntype == WPT_SHOOTER
		or cur_weapon.guntype == WPT_BLASTER
		or cur_weapon.guntype == WPT_DUALIES
		or cur_weapon.guntype == WPT_BRELLA)
			if ( ( (justpressedfire or (pt.fireheld and not cur_weapon:get(pt,"tapfire"))) and pt.cooldown <= 0) )
			and (p.cmd.buttons & BT_ATTACK)
			and (pt.firewait <= 1)
			and not (cur_weapon.guntype == WPT_DUALIES and (pt.dodgeroll.tics or pt.firewait))
			and not pt.shieldjustbroke
				local chance = cur_weapon:get(pt,"spread_base") + pt.spread
				if pt.spreadadd ~= 0
					chance = max($, cur_weapon:get(pt,"spread_jumpchance"))
				end
				local spread = P_RandomChance(FixedDiv(chance, 100*FU))
				
				if (cur_weapon:get(pt, "neverspreadonground")
				and not me.jumptime)
				or (cur_weapon:get(pt, "neverspreadatall"))
					spread = false
				end
				
				local donotfire = shieldout
				if shieldout
				and cur_weapon:get(pt,"shootwhiledeployed")
					donotfire = false
				end
				
				if not donotfire
					Paint:fireWeapon(p, cur_weapon, fireangle, p.aiming, spread, true)
					local bps = cur_weapon:get(pt,"bulletspershot")
					if bps ~= 1
					and bps > 1
						for i = 1, bps - 1
							Paint:fireWeapon(p, cur_weapon, fireangle, p.aiming, spread, true)
						end
					end
				end
				
				if shieldout
					pt.cooldown = (cur_weapon:get(pt,"firerate")) + 1
					pt.endlag = max($, cur_weapon.endlag)
					pt.squidlag = max($, cur_weapon:get(pt,"squidlag"))
					pt.justfired = true
					pt.anglefix = pt.cooldown
					
					if cur_weapon:get(pt,"shootwhiledeployed")
						pt.shieldwait = 0
					end
					doslowdown = true
				end
			end
			if (cur_weapon.guntype ~= WPT_DUALIES)
				pt.dodgeroll.count = 0
			end
			pt.charge = 0
			pt.maxcharged = false
		elseif (cur_weapon.guntype == WPT_CHARGER)
		and not pt.store_firelag
			local charge_sound = cur_weapon:get(pt,"charging_sound", p)
			local slow_charge_sound = cur_weapon:get(pt,"slow_charging_sound", p)
			local charge_time = cur_weapon:get(pt,"chargetime")
			local lowink = (pt.inktank - pt.inkqueue <= 0) or (pt.inktank < cur_weapon:get(pt, "inkcost")+1)
			
			if not pt.fireheld
			and (pt.chargetics > 0 and pt.chargetics < cur_weapon:get(pt,"mincharge"))
				if not lowink
					pt.fireheld = 1
					p.cmd.buttons = $|BT_ATTACK
				else
					pt.charge = 0
					pt.maxcharged = false
					pt.justcharged = false
					pt.wasfastcharging = false
					S_StopSoundByID(me, charge_sound)
					S_StopSoundByID(me, slow_charge_sound)
				end
			end
			
			if pt.fireheld and (pt.cooldown == 0)
				doslowdown = true
				if not pt.charge
					-- this is the little click sound
					S_StartSound(nil, cur_weapon.charge_sound, p)
					S_StartSound(me, charge_sound, p)
					pt.oldinktank = pt.inktank
					pt.oldinkanim = pt.oldinktank
				end
				
				local slowcharge = lowink
				if (me.jumptime and cur_weapon:get(pt,"slowwhenjumping"))
				or lowink
					S_StopSoundByID(me, charge_sound)
					if (pt.wasfastcharging or pt.charge == 0)
					and pt.charge < charge_time
						S_StartSound(me, slow_charge_sound, p)
					end
					slowcharge = true
				elseif S_SoundPlaying(me, slow_charge_sound)
				and (slow_charge_sound ~= charge_sound)
					S_StopSoundByID(me, slow_charge_sound)
					if pt.charge <= charge_time
						S_StartSound(me, charge_sound, p)
					end
				end
				
				if lowink
					Paint.HUD:lowInkWarning(p, TR/2)
				end
				local step = FU
				if (slowcharge)
					step = $ / 3
				end
				pt.charge = min($ + step, charge_time)
				pt.chargetics = $ + 1
				if pt.charge >= charge_time
					if not pt.maxcharged
						S_StartSound(nil, cur_weapon.charged_sound, p)
						pt.justcharged = true
						pt.maxcharged = true
					end
					S_StopSoundByID(me, charge_sound)
					S_StopSoundByID(me, slow_charge_sound)
				end
				local mincost = cur_weapon:get(pt,"mininkcost")
				local chargeprogress = min(FixedDiv(pt.charge, charge_time), FU)
				pt.inkqueue = mincost + FixedMul(cur_weapon.inkcost - mincost, chargeprogress)
				pt.wasfastcharging = not slowcharge
				
				pt.anglefix = max($, 1)
			end
			if not pt.fireheld
			and (p.lastbuttons & BT_ATTACK)
			and (pt.charge)
				pt.charge = min($, charge_time)
				Paint:fireWeapon(p, cur_weapon, fireangle, p.aiming, spread, true)
				pt.charge = 0
				pt.justcharged = false
				pt.maxcharged = false
				pt.wasfastcharging = false
				S_StopSoundByID(me, charge_sound)
				S_StopSoundByID(me, slow_charge_sound)
			end
			Paint:chargerSightline(p)
		end
	end
	if (pt.store_lag or pt.storedcharge)
		local mincost = cur_weapon:get(pt,"mininkcost")
		local chargeprogress = min(FixedDiv(max(pt.storedcharge, pt.charge), cur_weapon.chargetime), FU)
		pt.inkqueue = mincost + FixedMul(cur_weapon.inkcost - mincost, chargeprogress)
	end
	if not pt.charge
		pt.chargetics = 0
	end
	--print("lag", pt.firewait, pt.endlag, pt.cooldown, "firerate = "..cur_weapon:get(pt,"firerate"))
	
	-- handle dodge rolls
	local dd = pt.dodgeroll
	if cur_weapon.guntype == WPT_DUALIES
		local inpain = (P_PlayerInPain(p) or me.state == S_PLAY_PAIN or (not me.health))
		if dd.tics and not inpain
			local frac = FU - FixedDiv(dd.tics*FU, cur_weapon:get(pt,"dodgelength")*FU)
			--frac = ease.outsine($ * 3/4, 0, FU)
			P_TryMove(me,
				ease.outquad(frac, dd.startx, dd.destx),
				ease.outquad(frac, dd.starty, dd.desty),
				true
			)
			
			dd.momx = ($ + (me.x - dd.oldx))/2
			dd.momy = ($ + (me.y - dd.oldy))/2
			
			p.rmomx = dd.momx - p.cmomx
			p.rmomy = dd.momy - p.cmomy
			me.state = S_PLAY_ROLL
			dd.tics = $ - 1
			
			local rad = FixedDiv(me.radius,me.scale)/FU
			local hei = FixedDiv(me.height,me.scale)/FU
			for i = 0,2
				local b = makeBlob(p,me,pt, rad,hei)
				b.destscale = 0
				b.fuse = 10
				b.scalespeed = FixedDiv(b.scale, b.fuse*FU)
			end
			
			p.skidtime = 0
			if dd.tics == 0
				me.state = S_PLAY_GLIDE_LANDING
				me.momx = dd.momx
				me.momy = dd.momy
				dd.getup = cur_weapon:get(pt,"dodgegetup")
				pt.turretmode = true
				dd.momx = 0;dd.momx = 0
				P_MovePlayer(p)
			end
			p.pflags = $|PF_FULLSTASIS
			p.jumpfactor = 0
			dd.oldx = me.x
			dd.oldy = me.y
		elseif pt.firewait or dd.getup or inpain or pt.turretmode
			p.pflags = $|PF_FULLSTASIS
			p.jumpfactor = 0
			
			local redid = false
			if not (pt.firewait > cur_weapon:get(pt,"dodgelength"))
			and (pt.jumpheld == 1)
			and (pt.forwardmove ~= 0 or pt.sidemove ~= 0)
			and (pt.fireheld)
				if Paint:doDodgeRoll(p)
					p.pflags = $|PF_JUMPSTASIS
					p.cmd.buttons = $ &~BT_JUMP
					redid = true
				end
			end
			
			dd.getup = max($-1, 1)
			if ((pt.forwardmove ~= 0 or pt.sidemove ~= 0)
			or not (p.cmd.buttons & BT_ATTACK))
			or (pt.inktank < cur_weapon:get(pt,"inkcost"))
				dd.leave = $ + 1
			else
				dd.leave = 0
			end
			
			if (dd.leave >= 5
			and dd.getup == 1)
			and (not redid)
			or inpain
				if not inpain
					me.state = S_PLAY_WALK
					P_MovePlayer(p)
				end
				
				if cur_weapon:get(pt,"turret_endsound") ~= nil
				and (dd.count ~= 0)
					S_StartSound(me, cur_weapon:get(pt,"turret_endsound"))
				end
				dd.getup = 0
				pt.turretmode = false
				dd.count = 0
				dd.tics = 0
				dd.leave = 0
			else
				me.state = (FixedHypot(me.momx,me.momy) < 8*me.scale) and S_PLAY_GLIDE_LANDING or S_PLAY_ROLL
			end
		else
			dd.count = 0
			dd.leave = 0
			pt.turretmode = false
			p.jumpfactor = skin.jumpfactor
		end
		/*
		print(leveltime .. " dd = {")
		for k,v in pairs(dd)
			print("    "..tostring(k) .. " = " .. tostring(v))
		end
		print("}")
		print(pt.turretmode)
		*/
	end
	
	-- sub stuff
	-- AIMING A SUB / AIMING SUB
	local wasaiming = pt.aimingsub
	if not (pt.fireheld or pt.squidtoggle or p.exiting)
	and (p.cmd.buttons & BT_FIRENORMAL)
		pt.aimingsub = true
	else
		pt.aimingsub = false
	end
	if (pt.disable.sub)
		if pt.aimingsub
			Paint.HUD:cantUseWarning(p, TR/2)
		end
		pt.aimingsub = false
	end

	if pt.aimingsub
		pt.aimingtime = $ + 1
		local easefrac = 0
		if (pt.aimingtime >= TR/2)
			easefrac = min((FU/(TR*3/2)) * (pt.aimingtime - TR/2), FU)
			pt.fovadd = ease.inoutquad(
				easefrac,
				0, -30*FU
			)
		end
		if (p == displayplayer)
			me.alpha = ease.inoutquad(
				easefrac,
				$, FU/2
			)
			local test = Paint:throwSub(p, cur_weapon, fireangle, p.aiming + (ANG2*2 + ANG1), true)
			if test and test.valid
				local pos = {
					x = test.x,
					y = test.y,
					z = test.z,
					ceiling = false,
				}
				while (true)
					if Paint:bombPhysics(test, cur_weapon.subtype, true)
						pos.x = test.x; pos.y = test.y; pos.z = test.z
						break
					end
					if not P_TryMove(test, test.x + test.momx, test.y + test.momy, true)
						pos.x = test.x; pos.y = test.y; pos.z = test.z
						break
					end
					pos.x = test.x; pos.y = test.y; pos.z = test.z
					if not P_ZMovement(test) then break end
					pos.x = test.x; pos.y = test.y; pos.z = test.z
					
					if test.z <= test.floorz then break end
					if test.z + test.momz + test.height >= test.ceilingz
						pos.ceiling = true
						break
					end
					
					local dot = P_SpawnMobj(
						test.x,test.y,test.z,
						MT_PARTICLE
					)
					dot.state = S_THOK
					dot.tics = -1
					dot.fuse = 2
					dot.frame = $ &~FF_TRANSMASK
					dot.renderflags = $|RF_FULLBRIGHT|RF_NOCOLORMAPS
					dot.scale = FU/5
					dot.color = me.color
					dot.blendmode = AST_ADD
					P_SetOrigin(dot, dot.x,dot.y,dot.z)
				end
				local lock = P_SpawnMobj(pos.x,pos.y,pos.z, MT_PARTICLE)
				lock.state = S_LOCKON1
				lock.tics = 2
				lock.fuse = 2
				lock.scale = $ * 2
				lock.shadowscale = 4*FU
				if pos.ceiling
					lock.renderflags = $|RF_VERTICALFLIP
				end
				if (test and test.valid)
					P_RemoveMobj(test)
				end
			end
		end
		
		p.normalspeed = $ / 2
		p.drawangle = fireangle
		pt.substrafe = 10
	else
		if wasaiming
		and not (pt.fireheld or pt.squidtoggle)
			Paint:throwSub(p, cur_weapon, fireangle, p.aiming + (ANG2*2 + ANG1), false)
		end
		if pt.substrafe
			pt.substrafe = $ - 1
		end
		pt.fovadd = $ * 4/5
		pt.aimingtime = 0
	end
	p.fovadd = $ + pt.fovadd
	
	if ((p.cmd.buttons & BT_ATTACK)
	or pt.firewait)
	and pt.cooldown
		doslowdown = true
	end
	if pt.cooldown
		--doslowdown = true
		pt.cooldown = $ - 1
	end
	if pt.firewait --startlag
		doslowdown = true
		pt.firewait = $ - 1
	end
	if pt.endlag
		doslowdown = true
		pt.endlag = $ - 1
	end
	if pt.anglefix
	or (pt.firewait or pt.shieldlag)
	or (pt.store_lag)
		p.drawangle = fireangle
		if pt.anglefix
			pt.anglefix = $ - 1
		end
		if pt.anglefix == 0
			pt.anglestand = p.drawangle
		end
	elseif p.panim == PA_IDLE
	and not pt.aimingsub
		p.drawangle = pt.anglestand
	else
		pt.anglestand = p.drawangle
	end
	if (pt.spreadcooldown)
		pt.spreadcooldown = $ - 1
	else
		pt.spread = max($ - cur_weapon:get(pt,"spread_decay"), 0)
	end
	if (pt.hidden)
		doslowdown = false
	end
	
	if (pt.firewait or pt.fireheld or pt.endlag or pt.cooldown)
	or (dd.tics or dd.getup or pt.turretmode)
		pt.weaponzoffset = P_Lerp(FU * 3/4, $, 0)
	else
		pt.weaponzoffset = P_Lerp(FU / 3, $, Paint.IDLE_OFFSET)
	end
	
	if doslowdown
		local slowdown = cur_weapon:get(pt,"shootspeed")
		if (pt.deployshield or pt.shieldlag)
			slowdown = cur_weapon:get(pt,"shieldingspeed")
		end
		p.normalspeed = FixedMul(skin.normalspeed * 60 / 100, slowdown)
		p.charflags = $|SF_NOJUMPSPIN
	end
	if (p.gotflag)
		p.normalspeed = $ * 8/10
		p.acceleration = $ * 3/4
	end
	
	pt.lastslowdown = doslowdown
	
	if not P_IsObjectOnGround(me)
	and FixedHypot(me.momx,me.momy) > FixedMul(p.normalspeed, me.scale)
		local speed = FixedHypot(me.momx,me.momy)
		local div = 18*FU
		
		local newspeed = speed - FixedDiv(speed - FixedMul(p.normalspeed, me.scale),div)
		me.momx = FixedMul(FixedDiv(me.momx,speed), newspeed)
		me.momy = FixedMul(FixedDiv(me.momy,speed), newspeed)
	end
	
	do
		if pt.hp ~= 100*FU
		and (pt.timetoheal <= 0)
			if pt.inink == Paint.ININK_FRIENDLY
			and (FixedHypot(me.momx,me.momy) < 5*me.scale)
			and pt.hidden
				pt.hp = $ + 8*FU
			elseif pt.inink ~= Paint.ININK_ENEMY
				pt.hp = $ + FixedDiv(12*FU + FU/2, TR*FU)
			end
			pt.hp = min($, 100*FU)
		end
		pt.timetoheal = max($-1,0)
		
		if pt.inink ~= 0
			me.spriteyoffset = ease.linear(FU/6, $, -(pt.inink == Paint.ININK_ENEMY and 9 or 4)*FU)
		else
			me.spriteyoffset = ease.linear(FU/6, $, 0)
		end
		
		if pt.inink == Paint.ININK_ENEMY
			if not S_SoundPlaying(me, sfx_pt_ow2)
				S_StartSound(me, sfx_pt_ow2, p)
			end
			if (p == displayplayer or p == secondarydisplayplayer)
				P_StartQuake(FU*3/2, 2)
			end
		else
			S_StopSoundByID(me,sfx_pt_ow2)
		end
		
		if pt.inktime
			pt.inktime = $ - 1
		else
			pt.inink = 0
		end
	end
	
	if (pt.hittime)
		pt.hittime = $ - 1
		if pt.hittime == 0
			pt.hitlist = {}
		end
	end
end)

addHook("JumpSpecial",function(p)
	local me = p.mo
	if not (me and me.valid and me.health) return end
	
	local pt = p.paint
	if not (pt) then return end
	if not pt.active then return end
	if (pt.squidtime) then return end
	if pt.firewait then return end
	if (pt.disable.main or pt.wasdisabled.main) then return end
	
	local dd = pt.dodgeroll
	if (dd.tics or dd.getup) then return true; end
	
	if not (p.cmd.buttons & BT_ATTACK) then return end
	if not (p.cmd.forwardmove ~= 0 or p.cmd.sidemove ~= 0) then return end
	
	local wep = Paint.weapons[pt.weapon_id]
	if (wep == nil) then return end
	if (wep.guntype ~= WPT_DUALIES) then return end
	
	if not (p.pflags & PF_JUMPDOWN)
	and dd.count < wep:get(pt,"dodgerolls")
		Paint:doDodgeRoll(p)
		return true
	end
	return true
end)

addHook("PlayerSpawn",function(p)
	if not p.paint then return end
	Paint:resetPlayer(p)
end)

local move_lerp = FU / 3
addHook("PreThinkFrame",do setalpha = false; for p in players.iterate
	local me = p.mo
	local pt = p.paint
	if not pt then continue end
	
	pt.forwardmove = p.cmd.forwardmove
	pt.sidemove = p.cmd.sidemove
	pt.buttons = p.cmd.buttons
	pt.fixed_fmove = $ + FixedMul((pt.forwardmove*FU) - $, move_lerp)
	pt.fixed_smove = $ + FixedMul((pt.sidemove*FU) - $, move_lerp)
	
	pt.wasdisabled.main = pt.disable.main
	pt.wasdisabled.sub = pt.disable.sub
	pt.wasdisabled.inktank = pt.disable.inktank
	pt.wasdisabled.swimming = pt.disable.swimming
	pt.disable.main = false
	pt.disable.sub = false
	pt.disable.inktank = false
	pt.disable.swimming = false
	
	if (me and me.valid)
		me.alpha = FU
		if me.health
			me.paint_alivepos = {
				x = me.x, y = me.y, z = me.z
			}
		end
	end

	if not pt.active then continue end
	
	if pt.inink == Paint.ININK_ENEMY
		me.movefactor = FU/2
		me.friction = FU/2
	end
end; end)

local team_markers = {}
addHook("PostThinkFrame", do
	for p in players.iterate
		local me = p.mo
		local pt = p.paint
		if not pt then continue end
		
		if (p.playerstate == PST_REBORN)
			local overlay = pt.paintoverlay
			if (overlay and overlay.valid)
				P_RemoveMobj(overlay)
			end
		end
		
		do
			local cb = pt.calledbacks
			cb.onfire = false
		end
		
		-- signals
		if (pt.signaltime) then pt.signaltime = $ - 1; end
		if (p.cmd.buttons & (BT_CUSTOM1|BT_CUSTOM2)
		and not (p.lastbuttons & (BT_CUSTOM1|BT_CUSTOM2)))
		and not pt.signaltime
			pt.signaltime = Paint.SIGNAL_TIME
			local type
			local sfx
			
			if p.cmd.buttons & BT_CUSTOM1
				-- This way!
				if (me and me.valid and me.health and not p.lifesaver)
					type = Paint.SIGNAL_THISWAY
					sfx = sfx_s3kc1s
				else
					-- Help!
					if (p.lifesaver or me.deathtimer)
						type = Paint.SIGNAL_HELP
						sfx = sfx_s3kd6s
					-- Ouch...
					--TODO: maybe find a better sound for this?
					else
						type = Paint.SIGNAL_OUCH
						sfx = sfx_kc3e
					end
				end
			-- Booyah!
			elseif p.cmd.buttons & BT_CUSTOM2
				type = Paint.SIGNAL_BOOYAH
				sfx = sfx_ncspec
			end
			
			pt.signaltype = type
			for play in players.iterate
				if play.spectator then continue end
				if not (play.realmo and play.realmo.valid) then continue end
				if not Paint:mobjsOnTeam(p.realmo, play.realmo) then continue end
				
				S_StartSound(nil, sfx, play)
				Paint.HUD:addSignal(play, p, type)
			end
			S_StartSoundAtVolume(nil, sfx_pt_sig, 255*3/5, p)
		end
		
		if not (me and me.valid and me.health)
			local overlay = pt.paintoverlay
			if (overlay and overlay.valid)
				overlay.flags2 = $|MF2_DONTDRAW
			end
			pt.deployshield = false
			pt.wasdeployed = false
			continue
		end
		
		if R_PointToDist(me.x, me.y) <= 100*me.scale
			addalpha(p)
		end
		if local_raycasts
		and not (p.exiting or pt.disable.main)
			local ray = local_raycasts.hitcast
			if (ray and ray.valid)
			and R_PointTo3DDist(me.x,me.y,me.z + me.height/2, ray.x,ray.y,ray.z) <= 128*me.scale 
				addalpha(p)
			end
			ray = local_raycasts.dhitcast
			if (ray and ray.valid)
			and R_PointTo3DDist(me.x,me.y,me.z + me.height/2, ray.x,ray.y,ray.z) <= 128*me.scale 
				addalpha(p)
			end
		end
		
		if p == displayplayer
		and alphatrans
			me.alpha = P_Lerp(FixedDiv(alphatrans*FU, MAX_TRANSTIME*FU), $, FU * 2/10)
		end
		if (pt.shield and pt.shield.valid)
			pt.shield.alpha = me.alpha
			if (pt.shield.paint_overlay and pt.shield.paint_overlay.valid)
				pt.shield.paint_overlay.alpha = FixedMul($, me.alpha)
			end
		end
		
		do
			local overlay = pt.paintoverlay
			if not (overlay and overlay.valid)
				local ov = P_SpawnMobjFromMobj(me,0,0,0,MT_OVERLAY)
				ov.state = S_PLAY_STND
				ov.target = me
				ov.tics,ov.fuse = -1,-1
				ov.dontdrawforviewmobj = me
				ov.colorized = true
				ov.blendmode = AST_TRANSLUCENT
				ov.renderflags = $|RF_SEMIBRIGHT|RF_NOCOLORMAPS
				if Paint:getPlayerColor(p) ~= SKINCOLOR_NONE
					ov.color = ColorOpposite(Paint:getPlayerColor(p))
				else
					ov.color = SKINCOLOR_GREEN
				end
				overlay = ov
				pt.paintoverlay = ov
			end
			overlay.skin = me.skin
			overlay.alpha = FixedMul(me.alpha, FU - FixedDiv(pt.hp, 100*FU))
			overlay.sprite = me.sprite
			overlay.frame = A
			overlay.sprite2 = me.sprite2
			overlay.frame = me.frame
			overlay.angle = p.drawangle
			overlay.spritexscale = me.spritexscale
			overlay.spriteyscale = me.spriteyscale
			overlay.spritexoffset = me.spritexoffset
			overlay.spriteyoffset = me.spriteyoffset
			overlay.pitch = me.pitch
			overlay.roll = me.roll
			overlay.dispoffset = me.dispoffset + 1
			if overlay.color == SKINCOLOR_NONE
				overlay.color = ColorOpposite(Paint:getPlayerColor(p))
			end
			if (pt.hidden)
				overlay.flags2 = $|MF2_DONTDRAW
			else
				overlay.flags2 = $ &~MF2_DONTDRAW
			end
		end
		
		if not me.paint_inactive
			if not pt.disable.inktank
				BP.doInkTank(p)
			end

			local cur_weapon = Paint.weapons[pt.weapon_id]
			if pt.weapon_id ~= nil
				local reset_interp = pt.weapon_id ~= pt.old_weaponid
				if not (pt.disable.main)
					BP.doWeaponMobj(p,me,pt, cur_weapon, p.drawangle, false, reset_interp)
					if (cur_weapon.guntype == WPT_DUALIES)
						BP.doWeaponMobj(p,me,pt, cur_weapon, p.drawangle, true, reset_interp)
					end
				end
				
				local dd = pt.dodgeroll
				if (dd.tics or dd.getup or pt.turretmode)
				and me.state ~= S_PLAY_GLIDE_LANDING
					me.state = S_PLAY_GLIDE_LANDING
				end
			end
		end
		pt.justrestored = false
		pt.angdiff = P_Lerp(FU / 4, $, p.drawangle)
		
		/*
		local changed = false
		me.superready = $ or false
		if (p.cmd.buttons & BT_CUSTOM3)
		and not (p.lastbuttons & BT_CUSTOM3)
			me.superready = not $
			changed = true
		end
		if me.superready
			me.renderflags = $|RF_FULLBRIGHT
			me.eflags = $|MFE_FORCESUPER
			
			me.color = (Paint:getPlayerColor(p)) - abs( ((leveltime>>1) % 9) - 4 )
		else
			me.renderflags = $ &~RF_FULLBRIGHT
			me.eflags = $ &~MFE_FORCESUPER
			me.color = Paint:getPlayerColor(p)
		end
		if changed
			P_MovePlayer(p)
			me.state = $
		end
		*/
	end
	if not setalpha
		alphatrans = max($ - 1, 0)
	end
end)

addHook("SeenPlayer",function(p, p2)
	if not (p.paint) then return end
	if not (p2.paint) then return end
	
	if (gametyperules & GTR_TEAMS)
		if p.ctfteam ~= p2.ctfteam
		and p2.paint.hidden
			return false
		end
	elseif p2.paint.hidden
		return false
	end
end)

addHook("PlayerCanEnterSpinGaps",function(p)
	if not (p.paint) then return end
	local pt = p.paint
	if not Paint:playerIsActive(p) then return end
	
	if pt.squidtime >= MAX_SQUIDTIME
		return true
	end
end)

local easing = ease.inquad
addHook("PlayerHeight",function(p)
	local pt = p.paint
	if not pt then return end
	if not pt.active then return end
	
	local me = p.realmo
	if not (me and me.valid) then return end
	
	if (pt.turretmode or pt.dodgeroll.getup) or pt.dodgeroll.tics
		return P_GetPlayerSpinHeight(p)
	end
	if not pt.squidtime then return end
	
	local frac_step = (FU/MAX_SQUIDTIME)
	local small_height = FixedMul(Paint.SQUID_HEIGHT, me.scale)
	
	if (pt.squidtoggle)
		return easing(frac_step*pt.squidtime, P_GetPlayerHeight(p), small_height)
	else
		local frac = FU - (FU/MAX_SQUIDTIME)*pt.squidtime
		return easing(FU - (frac_step*pt.squidtime), small_height, P_GetPlayerHeight(p))
	end
end)