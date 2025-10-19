local CV = Paint.CV
freeslot("SPR_PAINT_MISC")

local function doWeaponMobj(p,me,pt, cur_weapon, fireangle, dualieflip, reset_interp)
	local teleport = reset_interp and P_SetOrigin or P_MoveOrigin
	
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
	local handoffset = {Paint:getWeaponOffset(me,fireangle - ANGLE_90, cur_weapon, dualieflip)}
	teleport(wepmo,
		me.x + handoffset[1] + me.momx,
		me.y + handoffset[2] + me.momy,
		me.z + me.height / 2 + me.momz
	)
	if (P_MobjFlip(me) == -1)
		wepmo.z = $ - wepmo.height
		wepmo.eflags = $|MFE_VERTICALFLIP
	else
		wepmo.eflags = $ &~MFE_VERTICALFLIP
	end
	do
		local slope = InvAngle(p.aiming)
		wepmo.roll = FixedMul(slope, sin(p.mo.angle))
		wepmo.pitch = FixedMul(slope, cos(p.mo.angle))
	end
	wepmo.dontdrawforviewmobj = me
	wepmo.angle = fireangle
	local weapon_scale = cur_weapon:get(pt,"weaponstate_scale")
	wepmo.spritexscale = FixedMul(FU + (wepmo.fireanim * FU/12), weapon_scale)
	wepmo.spriteyscale = wepmo.spritexscale
	if dualieflip
	and cur_weapon:get(pt,"dualie_weaponstate") ~= nil
		wepmo.state = cur_weapon:get(pt,"dualie_weaponstate")
	else
		wepmo.state = cur_weapon.weaponstate
	end
	if cur_weapon:get(pt,"weaponstate_frame") ~= nil
		wepmo.frame = ($ &~FF_FRAMEMASK)|(cur_weapon:get(pt,"weaponstate_frame") & FF_FRAMEMASK)
	end
	wepmo.flags2 = $ &~MF2_DONTDRAW
	wepmo.fireanim = max($-1, 0)
end

-- takes about 11 seconds to fully refill passively with no ink-related abilities...
local ink_refill_rate = FixedDiv(100*FU, 11*TR*FU)
-- ...and 3 seconds when submerged
local fast_ink_refill_rate = FixedDiv(100*FU, 3*TR*FU)

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
		--Paint:giveWeapon(p, "SIGMA")
	end
	local pt = p.paint
	
	if not Paint:isMode()
	and not CV.paintguns.value
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
			local skin = skins[p.skin]
			p.charflags = $|(skin.flags & SF_DASHMODE)
			p.charability = skin.ability
			p.charability2 = skin.ability2
			p.normalspeed = skin.normalspeed
		end
		
		pt.active = false
		return
	end
	pt.active = true
	
	--lol
	if Paint:isMode()
		p.dashmode = 0
		p.charflags = $ &~SF_DASHMODE
		p.charability = CA_NONE
		p.charability2 = CA2_NONE
		p.wasmode = true
	elseif p.wasmode
		local skin = skins[p.skin]
		p.charflags = $|(skin.flags & SF_DASHMODE)
		p.charability = skin.ability
		p.charability2 = skin.ability2
		p.wasmode = nil
	end
	
	me.jumptime = $ or 0
	pt.spreadadd = 0
	
	local fireangle = p.cmd.angleturn << 16
	local old_weaponid = pt.weapon_id
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
		and not (pt.endlag or pt.lastslowdown)
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
	if G_RingSlingerGametype()
		p.weapondelay = max($, 5)
	end
	
	if not P_IsObjectOnGround(me)
	and (p.pflags & PF_JUMPED)
		if not (me.jumptime)
			pt.spreadjump = cur_weapon:get(pt,"spread_jump")
		end
		me.jumptime = $ + 1
	else
		me.jumptime = 0
	end
	if pt.spreadjump
		local jumptime = cur_weapon:get(pt,"spread_jump")
		pt.spreadadd = ease.incubic(FU - ((FU/jumptime) * pt.spreadjump), cur_weapon:get(pt,"spread_jumpspread"), 0)
		pt.spreadjump = $ - 1
	end
	
	local justpressedfire = false
	if p.exiting
		p.cmd.buttons = $ &~BT_ATTACK
	end
	if not p.exiting
		if (p.cmd.buttons & BT_ATTACK)
			if not pt.fireheld
				justpressedfire = true
				pt.firewait = cur_weapon.startlag
			end
			pt.fireheld = $ + 1
			p.cmd.buttons = $|BT_ATTACK
		else
			pt.fireheld = 0
		end
		if pt.firewait == 1
			justpressedfire = true
			pt.fireheld = $ + 1
			p.cmd.buttons = $|BT_ATTACK
		end
		
		if (pt.buttons & BT_JUMP)
			pt.jumpheld = $ + 1
		else
			pt.jumpheld = 0
		end
	else
		pt.fireheld = 0
		pt.shotsfired = 0
	end
	
	if pt.inkdelay
		pt.inkdelay = $ - 1
	elseif pt.inktank ~= 100*FU
	and not pt.fireheld
		if (pt.inink == Paint.ININK_FRIENDLY)
		and (FixedHypot(me.momx,me.momy) < 5*me.scale)
			pt.inktank = $ + fast_ink_refill_rate
		else
			pt.inktank = $ + ink_refill_rate
		end
		pt.inktank = min($, 100*FU)
	end
	
	local doslowdown = false
	
	if (cur_weapon.guntype == WPT_SHOOTER
	or cur_weapon.guntype == WPT_BLASTER
	or cur_weapon.guntype == WPT_DUALIES)
		if ( ( (justpressedfire or pt.fireheld) and pt.cooldown <= 0)
		/*or (pt.fireheld % cur_weapon:get(pt,"firerate") == 0)*/)
		and (p.cmd.buttons & BT_ATTACK)
		and (pt.firewait <= 1)
		and not (cur_weapon.guntype == WPT_DUALIES and (pt.dodgeroll.tics or pt.firewait))
			local chance = cur_weapon:get(pt,"spread_base") + pt.spread
			if pt.spreadadd ~= 0
				chance = max($, cur_weapon:get(pt,"spread_jumpchance"))
			end
			local spread = P_RandomChance(FixedDiv(chance, 100*FU))
			
			if cur_weapon:get(pt, "neverspreadonground")
			and not me.jumptime
				spread = false
			end
			
			Paint:fireWeapon(p, cur_weapon, fireangle, spread)
			local bps = cur_weapon:get(pt,"bulletspershot")
			if bps ~= 1
			and bps > 1
				for i = 1, bps - 1
					Paint:fireWeapon(p, cur_weapon, fireangle, spread)
				end
			end
			doslowdown = true
		end
		if (cur_weapon.guntype ~= WPT_DUALIES)
			pt.dodgeroll.count = 0
		end
		pt.charge = 0
	elseif (cur_weapon.guntype == WPT_CHARGER)
		local charge_sound = cur_weapon:get(pt,"charging_sound", p)
		local slow_charge_sound = cur_weapon:get(pt,"slow_charging_sound", p)
		if pt.fireheld and (pt.cooldown == 0)
			doslowdown = true
			if not pt.charge
				S_StartSound(nil, cur_weapon.charge_sound, p)
				S_StartSound(me, charge_sound)
			end
			local docharge = true
			if me.jumptime
				S_StopSoundByID(me, charge_sound)
				if (me.jumptime == 1 or not pt.charge)
				and pt.charge < cur_weapon.chargetime
					S_StartSound(me, slow_charge_sound)
				end
				if not (me.jumptime & 1)
					docharge = false
				end
			elseif S_SoundPlaying(me, slow_charge_sound)
			and (slow_charge_sound ~= charge_sound)
				S_StopSoundByID(me, slow_charge_sound)
				if pt.charge <= cur_weapon.chargetime
					S_StartSound(me, charge_sound)
				end
			end
			if docharge
				pt.charge = min($ + 1, cur_weapon.chargetime + 1)
				if pt.charge == cur_weapon.chargetime
					S_StartSound(nil, cur_weapon.charged_sound, p)
					S_StopSoundByID(me, charge_sound)
					S_StopSoundByID(me, slow_charge_sound)
				end
			end
			pt.anglefix = max($, 1)
		end
		if not pt.fireheld
		and (p.lastbuttons & BT_ATTACK)
		and (pt.charge)
			pt.charge = min($, cur_weapon.chargetime)
			Paint:fireWeapon(p, cur_weapon, fireangle,  spread)
			pt.charge = 0
			S_StopSoundByID(me, charge_sound)
			S_StopSoundByID(me, slow_charge_sound)
		end
		Paint:chargerSightline(p)
	end
	--print("lag", pt.firewait, pt.endlag, pt.cooldown, "firerate = "..cur_weapon:get(pt,"firerate"))
	-- handle dodge rolls
	if cur_weapon.guntype == WPT_DUALIES
		local inpain = (P_PlayerInPain(p) or me.state == S_PLAY_PAIN or (not me.health))
		local dd = pt.dodgeroll
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
			
			p.skidtime = 0
			if dd.tics == 0
				me.state = S_PLAY_GLIDE_LANDING
				me.momx = dd.momx
				me.momy = dd.momy
				P_MovePlayer(p)
				dd.getup = cur_weapon:get(pt,"dodgegetup")
				pt.turretmode = true
				dd.momx = 0;dd.momx = 0
			end
			p.pflags = $|PF_FULLSTASIS
			dd.oldx = me.x
			dd.oldy = me.y
		elseif pt.firewait or dd.getup or inpain
			p.pflags = $|PF_FULLSTASIS
			
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
		end
	end
	
	if pt.cooldown
		doslowdown = true
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
		p.drawangle = fireangle
		pt.anglefix = $ - 1
		if pt.anglefix == 0
			pt.anglestand = p.drawangle
		end
	elseif p.panim == PA_IDLE
		p.drawangle = pt.anglestand
	else
		pt.anglestand = p.drawangle
	end
	if (pt.spreadcooldown)
		pt.spreadcooldown = $ - 1
	else
		pt.spread = max($ - cur_weapon:get(pt,"spread_decay"), 0)
	end
	
	if doslowdown
		p.normalspeed = FixedMul(skins[p.skin].normalspeed, cur_weapon.shootspeed)
	elseif pt.lastslowdown
		p.normalspeed = skins[p.skin].normalspeed
	end
	pt.lastslowdown = doslowdown
	
	do
		local reset_interp = pt.weapon_id ~= old_weaponid
		doWeaponMobj(p,me,pt, cur_weapon, p.drawangle, false, reset_interp)
		if (cur_weapon.guntype == WPT_DUALIES)
			doWeaponMobj(p,me,pt, cur_weapon, p.drawangle, true, reset_interp)
		end
	end
	
	do
		if pt.hp ~= 100*FU
		and (pt.timetoheal <= 0)
			if pt.inink == 0
				pt.hp = $ + FixedDiv(12*FU + FU/2, TR*FU)
			elseif pt.inink == Paint.ININK_FRIENDLY
			and (FixedHypot(me.momx,me.momy) < 5*me.scale)
				pt.hp = $ + 8*FU
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
	
	-- tank mobj
	do
		local tank = pt.tankmobj
		local teleport = P_MoveOrigin
		if not (tank and tank.valid)
			local tn = P_SpawnMobjFromMobj(me,0,0,0,MT_PAINT_GUN)
			tn.sprite = SPR_PAINT_MISC
			tn.frame = 3|FF_SEMIBRIGHT|FF_PAPERSPRITE
			tn.fuse = -1
			tn.tics = -1
			tn.dispoffset = 10
			tn.radius = 2*me.scale
			tn.height = 4*me.scale
			tn.colorized = true
			tn.dontdrawforviewmobj = me
			tn.target = me
			
			local back = P_SpawnMobjFromMobj(me,0,0,0,MT_PAINT_GUN)
			back.sprite = SPR_PAINT_MISC
			back.frame = 2|FF_SEMIBRIGHT|FF_PAPERSPRITE
			back.fuse = -1
			back.tics = -1
			back.dispoffset = 7
			back.radius = 2*me.scale
			back.height = 4*me.scale
			back.dontdrawforviewmobj = me
			back.target = me
			tn.tracer = back
			
			teleport = P_SetOrigin
			pt.tankmobj = tn
			tank = tn
		end
		if not (tank.tracer and tank.tracer.valid)
			P_RemoveMobj(tank)
		end
		if tank and tank.valid
			tank.flags2 = ($ &~MF2_DONTDRAW)|(pt.inktank <= 0 and MF2_DONTDRAW or 0)
			tank.angle = p.drawangle + ANGLE_180
			tank.spriteyscale = FixedDiv(pt.inktank, 100*FU)
			tank.color = Paint:getPlayerColor(p)
			teleport(tank,
				me.x+me.momx + P_ReturnThrustX(nil, tank.angle, me.radius + 4*me.scale),
				me.y+me.momy + P_ReturnThrustY(nil, tank.angle, me.radius + 4*me.scale),
				me.z+me.momz + me.height*2/5
			)
			
			local back = tank.tracer
			back.angle = tank.angle
			teleport(back,
				me.x+me.momx + P_ReturnThrustX(nil, tank.angle, me.radius + 4*me.scale - (me.scale/32)),
				me.y+me.momy + P_ReturnThrustY(nil, tank.angle, me.radius + 4*me.scale - (me.scale/32)),
				me.z+me.momz + me.height*2/5
			)
			tank.angle = $ - ANGLE_90
			back.angle = $ - ANGLE_90
			
			tank.pitch,tank.roll = 0,0
			back.pitch,back.roll = 0,0
		end
	end
end)

addHook("JumpSpecial",function(p)
	local me = p.mo
	if not (me and me.valid and me.health) return end
	
	local pt = p.paint
	if not pt.active then return end
	
	if pt.firewait then return true; end
	
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

addHook("PreThinkFrame",do for p in players.iterate
	local me = p.mo
	local pt = p.paint
	if not pt then continue end
	
	pt.forwardmove = p.cmd.forwardmove
	pt.sidemove = p.cmd.sidemove
	pt.buttons = p.cmd.buttons
	
	if not pt.active then continue end
	
	if pt.inink == Paint.ININK_ENEMY
		me.movefactor = FU/2
		me.friction = FU/2
	end
end; end)

local team_markers = {}
addHook("PostThinkFrame",do for p in players.iterate
	local me = p.mo
	local pt = p.paint
	if not pt then continue end
	
	if (p.playerstate == PST_REBORN)
		local overlay = pt.paintoverlay
		if (overlay and overlay.valid)
			P_RemoveMobj(overlay)
		end
	end
	
	if not (me and me.valid and me.health)
		local overlay = pt.paintoverlay
		if (overlay and overlay.valid)
			overlay.flags2 = $|MF2_DONTDRAW
		end
		continue
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
			ov.blendmode = AST_ADD
			if Paint:getPlayerColor(p) ~= SKINCOLOR_NONE
				ov.color = ColorOpposite(Paint:getPlayerColor(p))
			else
				ov.color = SKINCOLOR_GREEN
			end
			overlay = ov
			pt.paintoverlay = ov
		end
		overlay.skin = me.skin
		overlay.alpha = FU - FixedDiv(pt.hp, 100*FU)
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
	end
	
	if p == displayplayer
	and (pt.teammates ~= nil)
		for k, play in ipairs(pt.teammates)
			if not (play and play.valid and play.mo and play.mo.valid and play.mo.health)
			or (play == p)
				--dont remove, since this table is a reference
				continue
			end
			local mo = play.mo
			local mark = team_markers[#play]
			if not (mark and mark.valid)
				local new = P_SpawnMobjFromMobj(mo, 0,0, FixedDiv(mo.height,mo.scale), MT_THOK)
				new.fuse = -1
				new.frame = (leveltime >= 30*TICRATE) and B or A
				new.sprite = SPR_PAINT_MISC
				new.renderflags = $|RF_FULLBRIGHT
				new.drawonlyforplayer = p
				team_markers[#play] = new
				mark = new
			end
			if (leveltime == 30*TICRATE)
				mark.frame = B
			end
			mark.tics = 2
			mark.color = Paint:getPlayerColor(p)
			P_MoveOrigin(mark, mo.x, mo.y, mo.z + mo.height)
		end
	end
end; end)