Paint.enemyList = {}
addHook("NetVars",function(n)
	Paint.enemyList = n($)
end)

local basetype = MT_BLUECRAWLA
mobjinfo[basetype].height = $ + 8*FU

addHook("MobjDamage",function(mo, inf,sor, damage)
	if not (sor and sor.valid and sor.player and sor.player.valid and sor.player.paint and sor.player.paint.active) then return end
	if not (mo.flags & (MF_ENEMY|MF_BOSS)) then return end
	
	local baseinfo = mobjinfo[basetype]
	if mo.paint_maxhp == nil
		mo.paint_maxhp = FixedDiv(mo.info.radius + mo.info.height, baseinfo.height + baseinfo.radius) * 120
	end
	if mo.paint_hp == nil
	and not mo.paint_resist
		mo.paint_hp = mo.paint_maxhp
	elseif mo.paint_resist
		mo.paint_resist = nil
		return
	end
	--print((mo.info.typename .. " %f * %f = %f"):format(mo.info.radius, mo.info.height, mo.paint_maxhp))
	
	if mo.paint_stackid == nil
		table.insert(Paint.enemyList, mo)
		mo.paint_stackid = #Paint.enemyList
	end
	if mo.fake_paint == nil
		mo.fake_paint = {
			hurtat = {}
		}
	end
	
	damage = Paint:checkBulletParams(mo, mo.fake_paint, inf, damage)
	local weptype = Paint.weapons[inf.weapon_id]
	if (weptype and weptype.callbacks and weptype.callbacks.onhit ~= nil)
		weptype.callbacks.onhit(inf.target.player,inf.target.player.paint, Paint.weapons[inf.target.player.paint.weapon_id], inf, inf, mo, damage)
	end
	damage = FixedDiv($, mo.scale)
	
	mo.paint_healdelay = TR*3/2
	mo.paint_color = inf.color
	mo.paint_hp = $ - damage
	if mo.paint_hp > 0
		return true
	end
	mo.paint_hp = nil
	mo.paint_resist = true
	P_DamageMobj(mo,inf,sor, 1)
	return true
end)

addHook("MobjDamage",function(me, inf,sor, damage, dmgt)
	local p = me.player
	local pt = p.paint
	if not (pt and pt.active) then return end
	
	-- probably sector damage
	if not (inf and inf.valid and sor and sor.valid)
		if dmgt == DMG_WATER or dmgt == DMG_FIRE
			if me.paint_hurttic ~= leveltime
				Paint:damagePlayer(p,nil,nil,FU * 3/4, nil)
				Paint:setPlayerInInk(p, Paint.ININK_ENEMY)
			end
			me.paint_hurttic = leveltime
		else
			if (me.paint_hurttic == nil)
			or me.paint_hurttic < leveltime
				Paint:damagePlayer(p,inf,nil,8*FU, sor)
				Paint:playHurtSound(p)
				Knockback.addKnockback(me,
					TR / 2,
					R_PointToAngle2(0,0, me.momx,me.momy),
					-40*me.scale
				)
				me.paint_hurttic = leveltime + 4
			end
		end
		
		return true
	end
	
	--if not (sor.flags & (MF_ENEMY|MF_BOSS|MF_MISSILE|MF_FIRE|MF_PAIN)) then return end
	
	if (inf.flags & (MF_ENEMY|MF_BOSS|MF_MISSILE|MF_FIRE|MF_PAIN))
	and (inf.paint_touchpain ~= nil)
		if inf.paint_touchpain == false
			return true
		end
	end
	
	print(inf.info.typename)
	print(sor.info.typename)
	
	local baseinfo = mobjinfo[basetype]
	local speed = FixedHypot(FixedHypot(inf.momx,inf.momy), inf.momz) / 3
	damage = ($ * FU * 8) + speed
	if (inf.flags & MF_MISSILE)
		damage = $ + 8*FU
	else
		damage = $ + max((FixedDiv(inf.info.radius + inf.info.height, baseinfo.height + baseinfo.radius) - FU) * 20, 0)
	end
	if inf.scale > FU
		damage = FixedMul($, inf.scale * 3/4)
	end
	
	if (inf.type == MT_TNTBARREL or inf.type == MT_DRAGONMINE or inf.type == MT_PROXIMITYTNT)
		speed = 70*inf.scale
		damage = $ * 7
	end
	
	if (me.paint_hurttic == nil)
	or me.paint_hurttic < leveltime
		Paint:damagePlayer(p,inf,nil,damage, sor)
		Paint:playHurtSound(p)
		
		Knockback.addKnockback(me, TR*3/4 + (speed / FU / 2), R_PointToAngle2(me.x,me.y,inf.x,inf.y), -(16*inf.scale + speed))
		me.paint_hurttic = leveltime + 5
	end
	return true
end,MT_PLAYER)

addHook("ThinkFrame",do
	local removedelayed = {}
	for k,mo in ipairs(Paint.enemyList)
		if not (mo and mo.valid and mo.health)
			if (mo and mo.valid and not mo.health)
				if (mo.paint_overlay and mo.paint_overlay.valid)
					P_RemoveMobj(mo.paint_overlay)
				end
			end
			table.insert(removedelayed, {key = k})
			continue
		end
		
		if not (mo.health and mo.paint_hp ~= nil)
			local overlay = mo.paint_overlay
			if (overlay and overlay.valid)
				P_RemoveMobj(overlay)
				mo.paint_overlay = nil
			end
			continue
		end
		
		if mo.paint_healdelay
			mo.paint_healdelay = $ - 1
		elseif mo.paint_hp ~= mo.paint_maxhp
			mo.paint_hp = min($ + FixedDiv(12*FU + FU/2, TR*FU), mo.paint_maxhp)
		end
		
		do
			local overlay = mo.paint_overlay
			if not (overlay and overlay.valid)
				local ov = P_SpawnMobjFromMobj(mo,0,0,0,MT_OVERLAY)
				ov.state = S_INVISIBLE
				ov.target = mo
				ov.tics,ov.fuse = -1,-1
				ov.dontdrawforviewmobj = mo
				ov.colorized = true
				ov.blendmode = AST_TRANSLUCENT
				ov.color = mo.paint_color
				ov.renderflags = $|RF_SEMIBRIGHT|RF_NOCOLORMAPS
				overlay = ov
				mo.paint_overlay = ov
			end
			if mo.skin
				overlay.skin = mo.skin
			end
			overlay.alpha = FU - FixedDiv(mo.paint_hp, mo.paint_maxhp)
			overlay.sprite = mo.sprite
			overlay.frame = A
			overlay.sprite2 = mo.sprite2
			overlay.frame = mo.frame
			overlay.angle = mo.angle
			overlay.spritexscale = mo.spritexscale
			overlay.spriteyscale = mo.spriteyscale
			overlay.spritexoffset = mo.spritexoffset
			overlay.spriteyoffset = mo.spriteyoffset
			overlay.pitch = mo.pitch
			overlay.roll = mo.roll
			overlay.rollangle = mo.rollangle
			overlay.dispoffset = mo.dispoffset + 1
			overlay.color = mo.paint_color
		end
	end
	for k,v in ipairs(removedelayed)
		table.remove(Paint.enemyList, v.key)
	end
end)