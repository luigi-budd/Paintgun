-- the rainmaker is sort of an amalgamation of a blaster and a charger
local hsprd = tofixed("4.86")

Paint:registerWeapon({
	realname = "Rainmaker",
	icon = "PTMAIN_SSHOT",
	hidden = true,
	
	name = "rainmaker",
	guntype = WPT_SPECIAL,
	subtype = "",
	
	handoffset = 8*FU,
	h_spread = {hsprd,hsprd},
	v_spread = {3*FU, 3*FU},

	weaponstate = S_PAINT_GUN,
	weaponstate_scale = FU/2,
	
	range = FixedMul(tofixed("25.75"), Paint.DU2FU),
	dropoff = 0,
	damage = 40*FU, -- damage here is the minimum damage
	callbacks = {
		canswap = function()
			return false
		end,
		postthinker = function(p,pt, wep)
			local me = p.mo
			local charge_sound = wep:get(pt,"charging_sound", p)
			local slow_charge_sound = wep:get(pt,"slow_charging_sound", p)
			local charge_time = wep:get(pt,"chargetime")
			local lowink = (pt.inktank - pt.inkqueue <= 0) or (pt.inktank < wep:get(pt, "inkcost")+1)
			
			if not pt.realfireheld
			and (pt.chargetics > 0 and pt.chargetics < wep:get(pt,"mincharge"))
				if not lowink
					pt.realfireheld = 1
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
			
			print(pt.charge)
			if pt.realfireheld and (pt.cooldown == 0)
				--doslowdown = true
				if not pt.charge
					-- this is the little click sound
					S_StartSound(nil, wep.charge_sound, p)
					S_StartSound(me, charge_sound, p)
					pt.oldinktank = pt.inktank
					pt.oldinkanim = pt.oldinktank
				end
				
				local slowcharge = lowink
				if (me.jumptime and wep:get(pt,"slowwhenjumping"))
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
						S_StartSound(nil, wep.charged_sound, p)
						pt.justcharged = true
						pt.maxcharged = true
					end
					S_StopSoundByID(me, charge_sound)
					S_StopSoundByID(me, slow_charge_sound)
				end
				local mincost = wep:get(pt,"mininkcost")
				local chargeprogress = min(FixedDiv(pt.charge, charge_time), FU)
				pt.inkqueue = mincost + FixedMul(wep.inkcost - mincost, chargeprogress)
				pt.wasfastcharging = not slowcharge
				
				pt.anglefix = max($, 1)
			end
			if not (pt.realfireheld)
			and (p.lastbuttons & BT_ATTACK)
			and (pt.charge)
				print("!!!")
				pt.charge = min($, charge_time)
				Paint:fireWeapon(p, wep, p.cmd.angleturn << 16, p.aiming, spread, true)
				pt.charge = 0
				pt.justcharged = false
				pt.maxcharged = false
				pt.wasfastcharging = false
				S_StopSoundByID(me, charge_sound)
				S_StopSoundByID(me, slow_charge_sound)
			end
			Paint:chargerSightline(p)
		end,
	}
})
