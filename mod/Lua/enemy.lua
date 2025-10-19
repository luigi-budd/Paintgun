Paint.enemyList = {}
addHook("NetVars",function(n)
	Paint.enemyList = n($)
end)

local baseinfo = mobjinfo[MT_BLUECRAWLA]
addHook("MobjDamage",function(mo, inf,sor, damage)
	if not (sor and sor.valid and sor.player and sor.player.valid and sor.player.paint and sor.player.paint.active) then return end
	if not (mo.flags & (MF_ENEMY|MF_BOSS)) then return end
	
	mo.paint_maxhp = FixedDiv(mo.info.radius + mo.info.height, baseinfo.height + baseinfo.radius) * 120 
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

addHook("MobjDamage",function(me, inf,sor, damage)
	local p = me.player
	local pt = p.paint
	if not (pt and pt.active) then return end
	if not (sor and sor.valid) then return end
	if not (inf and inf.valid) then return end
	if not (sor.flags & (MF_ENEMY|MF_BOSS|MF_MISSILE|MF_FIRE|MF_PAIN)) then return end
	
	if (inf.flags & MF_MISSILE)
		damage = $ * 3
	end
	if me.paint_hurttic ~= leveltime
		Paint:damagePlayer(p,inf,nil,damage*FU*15, sor)
		Paint:playHurtSound(p)
		
		Knockback.addKnockback(me, TR, R_PointToAngle2(me.x,me.y,inf.x,inf.y), -32*inf.scale)
	end
	me.paint_hurttic = leveltime
	return true
end,MT_PLAYER)

addHook("ThinkFrame",do
	for k,mo in ipairs(Paint.enemyList)
		if not (mo and mo.valid)
			table.remove(Paint.enemyList,k)
		end
	end
	
	for k,mo in ipairs(Paint.enemyList)
		if not (mo and mo.valid) then continue end
		
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
				ov.blendmode = AST_ADD
				ov.color = mo.paint_color
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
			overlay.dispoffset = mo.dispoffset + 1
			overlay.color = mo.paint_color
		end
	end
end)