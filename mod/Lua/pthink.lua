local CV = Paint.CV
local MAX_SQUIDTIME = 3

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
	do
		local slope = InvAngle(p.aiming)
		wepmo.roll = FixedMul(slope, sin(p.drawangle))
		wepmo.pitch = FixedMul(slope, cos(p.drawangle))
	end
	wepmo.dontdrawforviewmobj = me
	wepmo.angle = fireangle
	local weapon_scale = cur_weapon:get(pt,"weaponstate_scale")
	wepmo.spritexscale = FixedMul(FU + (wepmo.fireanim * FU/12), weapon_scale)
	wepmo.spriteyscale = wepmo.spritexscale
	wepmo.destscale = me.scale
	wepmo.scalespeed = wepmo.destscale + 1
	wepmo.color = Paint:getPlayerColor(p)
	if dualieflip
	and cur_weapon:get(pt,"dualie_weaponstate") ~= nil
		wepmo.state = cur_weapon:get(pt,"dualie_weaponstate")
	else
		wepmo.state = cur_weapon.weaponstate
	end
	if cur_weapon:get(pt,"weaponstate_frame") ~= nil
		wepmo.frame = ($ &~FF_FRAMEMASK)|(cur_weapon:get(pt,"weaponstate_frame") & FF_FRAMEMASK)
	end
	wepmo.flags2 = ($ &~MF2_DONTDRAW)|((pt.hidden) and MF2_DONTDRAW or 0)
	wepmo.fireanim = max($-1, 0)
	
	local offx,offy = 0,0
	if (cur_weapon.guntype == WPT_BRELLA)
	and ((pt.endlag or pt.firewait) or (pt.fireheld or p.cmd.buttons & BT_ATTACK))
	or pt.holsteranim
		if ((pt.endlag or pt.firewait) or (pt.fireheld or p.cmd.buttons & BT_ATTACK))
			pt.holsteranim = min($ + 1, Paint.MAX_HOLSTER)
		else
			pt.holsteranim = max($-1, 0)
		end
		local frac = FixedDiv(pt.holsteranim*FU, Paint.MAX_HOLSTER*FU)
		
		offx = P_ReturnThrustX(nil, fireangle, FixedMul(me.radius, frac))
		offy = P_ReturnThrustY(nil, fireangle, FixedMul(me.radius, frac))
		fireangle = $ + FixedAngle(90 * frac)
	else
		pt.holsteranim = max($-1, 0)
	end
	local handoffset = {Paint:getWeaponOffset(me,fireangle - ANGLE_90, cur_weapon, dualieflip, false)}
	local zoffset = (41*me.height)/48 - (12 * me.scale)
	teleport(wepmo,
		me.x + handoffset[1] + me.momx + offx,
		me.y + handoffset[2] + me.momy + offy,
		me.z + zoffset       + me.momz
	)
	if (P_MobjFlip(me) == -1)
		wepmo.z = $ - wepmo.height
		wepmo.eflags = $|MFE_VERTICALFLIP
	else
		wepmo.eflags = $ &~MFE_VERTICALFLIP
	end
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
	return blob
end
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
		Paint:giveWeapon(p, "brella")
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
	or (Paint.CV.paintnerfs.value)
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
	end
	if not (p.cmd.buttons & BT_ATTACK or pt.fireheld)
	and not (pt.cooldown or pt.firewait or pt.endlag)
		pt.shotsfired = 0
	end
	
	-- squid form
	do
		local maxsquish = (pt.inink == Paint.ININK_FRIENDLY and FU*4/100 or FU/2)
		local easing = ease.inquad
		pt.hidden = false
		
		if (p.cmd.buttons & BT_SPIN)
		and not ((pt.endlag or pt.firewait or pt.cooldown or pt.justfired or (pt.charge ~= 0))
		or (pt.fireheld and pt.cooldown <= 0))
		and (p.charability2 == CA2_NONE)
		and not (pt.dodgeroll.tics or pt.dodgeroll.getup)
		and not (pt.squidlag)
			if not pt.wasinsquid
				S_StartSound(me,sfx_pt_tos)
			end
			
			pt.squidtime = min($ + 1, MAX_SQUIDTIME)
			local frac = (FU/MAX_SQUIDTIME)*pt.squidtime
			me.height = easing(frac, $, 22*me.scale)
			me.spriteyscale = easing(frac, FU, maxsquish)
			pt.fireheld = 0
			p.cmd.buttons = $ &~BT_ATTACK
			pt.wasinsquid = true
		else
			if pt.wasinsquid
				S_StartSound(me,sfx_pt_toh)
			end
			S_StopSoundByID(me,sfx_pt_swm)
			
			local frac = FU - (FU/MAX_SQUIDTIME)*pt.squidtime
			me.height = easing(frac, 22*me.scale, $)
			me.spriteyscale = easing(frac, maxsquish, FU)
			pt.squidtime = max($ - 1, 0)
			pt.wasinsquid = false
		end
		if pt.squidlag then pt.squidlag = $ - 1; end
		pt.justfired = false
		
		p.charflags = ($ &~SF_NOSKID)|(skins[p.skin].flags & SF_NOSKID)
		p.normalspeed = skins[p.skin].normalspeed * 4/5
		p.thrustfactor = skins[p.skin].thrustfactor
		if (pt.squidtime >= MAX_SQUIDTIME)
			p.charflags = $|SF_NOSKID
			if (pt.inink == Paint.ININK_FRIENDLY)
			or (pt.wallink and p.powers[pw_pushing])
				me.flags2 = $|MF2_DONTDRAW
				pt.hidden = true
				pt.squidanim = TR/2
				p.pflags = $ &~PF_SPINNING
				if (me.state == S_PLAY_ROLL)
					me.state = S_PLAY_WALK
					P_MovePlayer(p)
				end
				
				p.normalspeed = skins[p.skin].normalspeed * 9/10
				p.thrustfactor = $*6/4
				me.friction = FixedMul($, FU*97/100)
				if (p.cmd.forwardmove == 0 and p.cmd.sidemove == 0)
					local fric = FU * 9/10
					me.momx = FixedMul($, fric)
					me.momy = FixedMul($, fric)
				end
			else
				p.normalspeed = $/3
			end
			
			/*
			local old_x,old_y = me.x,me.y
			local trymove = P_TryMove(me,
				me.x + (38 * cos(p.drawangle)),
				me.y + (38 * sin(p.drawangle)),
				true
			)
			if trymove
				P_MoveOrigin(me, old_x,old_y,me.z)
			end
			print(trymove)
			*/
			if (pt.wallink and p.powers[pw_pushing])
				if not (pt.wasclimbing) and me.last_speed
					P_SetObjectMomZ(me,FixedDiv(me.last_speed,me.scale)/2,true)
				end
				
				P_SetObjectMomZ(me, p.normalspeed/28, true)
				if (pt.jumpheld == 1)
					P_SetObjectMomZ(me, 3*FU, true)
				end
				
				me.momz = FixedMul($, FU*98/100)
				pt.wasclimbing = true
			else
				if pt.wasclimbing
					me.momz = $/3
				end
				pt.wasclimbing = false
			end
			
			if pt.hidden
				if (FixedHypot(FixedHypot(me.momx,me.momy), me.momz) >= 8*me.scale)
					if not S_SoundPlaying(me, sfx_pt_swm)
						S_StartSoundAtVolume(me,sfx_pt_swm,255/2, p)
					end
					local blob = makeBlob(p,me,pt, 0,0)
					blob.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT &~(MF_NOGRAVITY)
					P_SetOrigin(blob, me.x+me.momx, me.y+me.momy, blob.z)
					if (pt.wasclimbing)
						local h_ang = Paint:controlDir(p)
						local v_ang = FixedAngle(P_RandomFixedRange(-25,25))
						local v_speed = P_RandomRange(5,10)*me.scale
						P_Thrust(blob,h_ang, -P_RandomRange(1,3)*me.scale)
						P_Thrust(blob,h_ang+ANGLE_90, FixedMul(v_speed, sin(v_ang)) )
						
						blob.momz = $ + me.momz/2
					else
						local ang = R_PointToAngle2(0,0,me.momx,me.momy) + FixedAngle(P_RandomFixedRange(-25,25))
						P_SetObjectMomZ(blob, P_RandomRange(1,3)*FU)
						P_Thrust(blob,ang, -P_RandomRange(6,15)*me.scale)
						
						blob.momx = $ + me.momx
						blob.momy = $ + me.momy
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
		else
			pt.wallink = 0
			
			if pt.wasclimbing
				me.momz = $/3
			end
			pt.wasclimbing = false
		end
		if me.last_hidden ~= pt.hidden
		and me.last_hidden ~= nil
			if not (pt.wasclimbing or pt.wallink)
				local splash = P_SpawnMobjFromMobj(me, 0,0,0, MT_PARTICLE)
				P_SetOrigin(splash, splash.x,splash.y, me.floorz)
				splash.state = S_PAINT_SPLASH
				splash.color = Paint:getPlayerColor(p)
				P_SetScale(splash, splash.scale + P_RandomFixed()/2, true)
			end
			S_StartSound(me, sfx_splish)
		end
		me.last_hidden = pt.hidden
		me.last_speed = FixedHypot(me.momx,me.momy)
		
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
	
	if pt.inkdelay
		pt.inkdelay = $ - 1
	elseif pt.inktank ~= 100*FU
	and not pt.fireheld
		if (pt.inink == Paint.ININK_FRIENDLY)
		and pt.hidden
			pt.inktank = $ + fast_ink_refill_rate
		else
			pt.inktank = $ + ink_refill_rate
		end
		pt.inktank = min($, 100*FU)
	end
	
	local doslowdown = false
	
	if (cur_weapon.guntype == WPT_SHOOTER
	or cur_weapon.guntype == WPT_BLASTER
	or cur_weapon.guntype == WPT_DUALIES
	or cur_weapon.guntype == WPT_BRELLA)
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
			
			if (cur_weapon:get(pt, "neverspreadonground")
			and not me.jumptime)
			or (cur_weapon:get(pt, "neverspreadatall"))
				spread = false
			end
			
			Paint:fireWeapon(p, cur_weapon, fireangle, p.aiming, spread, true)
			local bps = cur_weapon:get(pt,"bulletspershot")
			if bps ~= 1
			and bps > 1
				for i = 1, bps - 1
					Paint:fireWeapon(p, cur_weapon, fireangle, p.aiming, spread, true)
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
			or (pt.inktank <= 0)
				S_StopSoundByID(me, charge_sound)
				if (me.jumptime == 1 or not pt.charge)
				and pt.charge < cur_weapon.chargetime
					S_StartSound(me, slow_charge_sound)
				end
				if not (leveltime & 1)
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
			Paint:fireWeapon(p, cur_weapon, fireangle, p.aiming, spread, true)
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
		/*
		print("dd = {")
		for k,v in pairs(dd)
			print("\t"..tostring(k) .. " = " .. tostring(v))
		end
		print("}")
		*/
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
	end
	pt.lastslowdown = doslowdown
	
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
	
	-- ink tank mobj
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
			local hide = pt.hidden
			tank.flags2 = ($ &~MF2_DONTDRAW)|((pt.inktank <= 0 or hide) and MF2_DONTDRAW or 0)
			tank.angle = p.drawangle + ANGLE_180
			tank.spriteyscale = FixedDiv(pt.inktank, 100*FU)
			tank.color = Paint:getPlayerColor(p)
			teleport(tank,
				me.x+me.momx + P_ReturnThrustX(nil, tank.angle, me.radius + 4*me.scale),
				me.y+me.momy + P_ReturnThrustY(nil, tank.angle, me.radius + 4*me.scale),
				me.z+me.momz + me.height*2/5
			)
			tank.destscale = me.scale
			tank.scalespeed = tank.destscale + 1
			
			local back = tank.tracer
			back.angle = tank.angle
			back.flags2 = ($ &~MF2_DONTDRAW)|(hide and MF2_DONTDRAW or 0)
			teleport(back,
				me.x+me.momx + P_ReturnThrustX(nil, tank.angle, me.radius + 4*me.scale - (me.scale/32)),
				me.y+me.momy + P_ReturnThrustY(nil, tank.angle, me.radius + 4*me.scale - (me.scale/32)),
				me.z+me.momz + me.height*2/5
			)
			tank.angle = $ - ANGLE_90
			back.angle = $ - ANGLE_90
			back.destscale = me.scale
			back.scalespeed = back.destscale + 1
			
			tank.pitch,tank.roll = 0,0
			back.pitch,back.roll = 0,0
		end
	end
	
	-- weapon mobjs
	do
		local reset_interp = pt.weapon_id ~= old_weaponid
		doWeaponMobj(p,me,pt, cur_weapon, p.drawangle, false, reset_interp)
		if (cur_weapon.guntype == WPT_DUALIES)
			doWeaponMobj(p,me,pt, cur_weapon, p.drawangle, true, reset_interp)
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
	
	do
		local cb = pt.calledbacks
		cb.onfire = false
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
			ov.blendmode = AST_TRANSLUCENT
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