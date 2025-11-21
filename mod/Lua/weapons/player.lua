-- Player interactions and handlers
local CV = Paint.CV

local function isFriendlyFire(p1,p2)
	if not (p1 and p1.valid and p2 and p2.valid) then return false; end
	if G_GametypeHasTeams()
		return p1.ctfteam == p2.ctfteam
	elseif G_TagGametype()
		return (p1.pflags & PF_TAGIT) == (p2.pflags & PF_TAGIT)
	end
	return false
end
Paint.isFriendlyFire = isFriendlyFire

-- shot and sorp can be nil, but inf should NEVER be nil
function Paint:killPlayer(p, shot, sorp, inf)
	local pt = p.paint
	local me = p.mo
	if (p.gotflag)
		P_PlayerFlagBurst(p,false)
	end
	P_PlayerWeaponAmmoBurst(p)
	P_PlayerWeaponPanelBurst(p)
	P_PlayerEmeraldBurst(p)
	
	if (p == displayplayer or p == secondarydisplayplayer)
		P_StartQuake(15*FU, 14)
	end
	
	if (p.powers[pw_shield] ~= 0)
		pt.hp = 100*FU
		S_StartSound(me, sfx_pt_ow3)
		p.powers[pw_shield] = 0
		
		if (p == displayplayer or p == secondarydisplayplayer)
			P_StartQuake(15*FU, TR)
		end
		
		return
	end
	
	Paint.HUD:killNotice(p)
	P_KillMobj(me, shot, (sorp and sorp.valid) and sorp.mo or inf)
	if not Paint.isFriendlyFire(p,sorp)
		--CONS_Printf(sorp, "\x82Killed "..p.name.."!")
		if sorp and sorp.valid
			P_AddPlayerScore(sorp, 100)
			Paint.HUD:killConfirm(sorp, p)
		end
		if pt.hittime
			local candidates = {}
			for i = 0, #players-1
				local play = players[i]
				if not (play and play.valid) then continue end
				local info = pt.hitlist[i]
				if (info == nil) then continue end
				if (play == sorp) then continue end
				
				table.insert(candidates, {player = play, damage = info.damage})
			end
			table.sort(candidates, function(a,b)
				return a.damage > b.damage
			end)
			if #candidates
			and (candidates[1] ~= nil)
			and candidates[1].player ~= sorp
				Paint.HUD:killConfirm(candidates[1].player, p, true)
				P_AddPlayerScore(candidates[1].player, 50)
			end
		end
	end
	if (gametyperules & GTR_TAG)
	and (sorp and sorp.valid and sorp.pflags & PF_TAGIT)
		p.pflags = $|PF_TAGIT
	end
	
	local deathcolor
	if (pt.paintoverlay and pt.paintoverlay.valid and pt.paintoverlay.color ~= self:getPlayerColor(p))
		deathcolor = pt.paintoverlay.color
	else
		deathcolor = (sorp and sorp.valid) and self:getPlayerColor(sorp) or ColorOpposite(self:getPlayerColor(p))
	end
	for i = 0,30
		local angle = FixedAngle(P_RandomFixedRange(0,360))
		local drop = P_SpawnMobjFromMobj(me,0,0,FU, MT_PAINT_SHOT)
		if drop and drop.valid
			drop.target = (sorp and sorp.valid) and sorp.mo or inf
			drop.angle = angle
			drop.color = deathcolor
			drop.trail = true
			drop.lifespan = 0
			drop.flags = $|MF_NOCLIPTHING &~MF_NOGRAVITY
			drop.tracer_player = sorp
			P_SetObjectMomZ(drop, P_RandomFixedRange(1,17))
			P_Thrust(drop, angle, P_RandomFixedRange(1,17))
		end
		S_StartSound(me, sfx_pt_ow1)
		S_StartSound(me, sfx_pt_ow1)
	end

	local spr_scale = FU * 2
	local tntstate = S_TNTBARREL_EXPL3
	local rflags = RF_FULLBRIGHT|RF_NOCOLORMAPS
	local bam = P_SpawnMobjFromMobj(me, 0,0,0, MT_THOK)
	P_SetMobjStateNF(bam, tntstate)
	bam.spritexscale = FixedMul($, spr_scale)
	bam.spriteyscale = bam.spritexscale
	bam.renderflags = $|rflags
	bam.blendmode = AST_ADD
	bam.colorized = true
	bam.color = deathcolor
	local t = P_SpawnMobjFromMobj(me,0,0,0,MT_THOK)
	t.color = deathcolor
	t.spritexscale = FU * 3
	t.spriteyscale = t.spritexscale
	
	for i = 0,2
		local outline = P_SpawnMobjFromMobj(me, 0,0,0, MT_PAINT_SHOT)
		outline.visualfadestupidshit = true
		outline.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOCLIPTHING
		outline.fuse = 9
		outline.radius = 40*me.scale
		outline.sprite = SPR_PAINT_MISC
		outline.frame = ($ &~FF_FRAMEMASK)|18
		outline.spritexscale = FU * 3
		outline.spriteyscale = outline.spritexscale
		outline.renderflags = $|rflags|RF_PAPERSPRITE|RF_NOSPLATBILLBOARD
		outline.blendmode = AST_ADD
		outline.colorized = true
		outline.color = deathcolor
		outline.angle = me.angle + (ANGLE_90 * i)
		if i == 2
			outline.renderflags = $|RF_FLOORSPRITE &~RF_PAPERSPRITE
		end
	end
	
end

function Paint:damagePlayer(p, shot, sorp, damage, inf) -- mobj if no player
	if damage == nil
		damage = self.weapons[shot.weapon_id].damage
	end
	local pt = p.paint
	
	if (pt.paintoverlay and pt.paintoverlay.valid)
	and (shot and shot.valid)
		pt.paintoverlay.color = (shot.color ~= SKINCOLOR_NONE) and shot.color or ColorOpposite(self:getPlayerColor(p))
		if (shot.color == SKINCOLOR_NONE)
		and (inf and inf.valid and inf.color ~= SKINCOLOR_NONE)
			pt.paintoverlay.color = inf.color
		end
	end
	
	if (sorp and sorp.valid)
		if pt.hitlist[#sorp] == nil
			pt.hitlist[#sorp] = {damage = 0}
		end
		pt.hitlist[#sorp].damage = $ + damage
		pt.hittime = 3*TR
	end
	
	local oldhp = pt.hp
	pt.hp = $ - damage
	if oldhp > 85*FU
	and pt.hp <= 85*FU
		Paint.HUD:painSurge(p)
	end
	if pt.hp <= 0
		pt.hp = 0
		Paint:killPlayer(p, shot, sorp, inf)
		return
	end
	pt.timetoheal = TR*5/4
end

function Paint:playHurtSound(p)
	if (p.paint.hurttic == leveltime) then return end
	p.paint.hurttic = leveltime
	
	local sfx = sfx_pt_ow0 --P_RandomRange(sfx_pt_ow0,sfx_pt_ow2)
	S_StartSound(nil, sfx, p)
	--S_StartSound(nil, sfx, p)
end

function Paint:getPlayerColor(p)
	if G_GametypeHasTeams()
		return (p.ctfteam == 1 and skincolor_redteam or skincolor_blueteam)
	end
	return p.skincolor
end

function Paint:chargerSightline(p)
	local me = p.mo
	local pt = p.paint
	local wep = self.weapons[pt.weapon_id]
	
	if not pt.charge then return end
	--if leveltime & 1 then return end
	
	local range = wep:get(pt,"range") + (wep:get(pt,"falloff"))[2]*FU
	range = FixedMul($, me.scale)
	local dots = 50
	local step = FixedDiv(range, dots*FU)
	local angle = (p.cmd.angleturn<<16)
	local vec = {
		x = FixedMul(cos(angle), cos(p.aiming)),
		y = FixedMul(sin(angle), cos(p.aiming)),
		z = sin(p.aiming)
	}
	local offsets = {Paint:getWeaponOffset(me,pt, angle - ANGLE_90, wep, false)}
	local x,y,z =	me.x + offsets[1] + me.momx,
					me.y + offsets[2] + me.momy,
					me.z + (41*(me.height)/48 - 8*me.scale) + me.momz
	local ticker = (leveltime/4)
	for i = 1,dots
		local dist = step * i
		local dx = x + FixedMul(dist, vec.x)
		local dy = y + FixedMul(dist, vec.y)
		local dz = z + FixedMul(dist, vec.z)
		local fz = P_FloorzAtPos(dx,dy,dz, 4*FU)
		local cz = P_CeilingzAtPos(dx,dy,dz, 4*FU)
		if (dz <= fz
		or dz >= cz)
			break
		end
		if ((i-ticker) % 4 == 0) then continue end

		local dot = P_SpawnMobj(
			dx,dy,dz,
			MT_PARTICLE
		)
		dot.color = me.color
		dot.state = S_THOK
		dot.tics = -1
		dot.fuse = 2
		dot.blendmode = AST_ADD
		dot.frame = $ &~FF_TRANSMASK
		dot.renderflags = $|RF_FULLBRIGHT|RF_NOCOLORMAPS
		dot.scale = FU/5
		--dot.dontdrawforviewmobj = me
		P_SetOrigin(dot, dot.x,dot.y,dot.z)
		
	end
end

--Returns whether or not we should apply
--damaging code to the player
function Paint:playerIsActive(p)
	return (p.paint ~= nil and p.paint.active)
end

-- wrapper for setting this
function Paint:setPlayerInInk(p, type)
	p.paint.inink = type
	p.paint.inktime = 2
end
function Paint:setPlayerWallInk(p, type)
	p.paint.wallink = 3
end

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
function Paint:doDodgeRoll(p)
	local me = p.mo
	local pt = p.paint
	
	local wep = Paint.weapons[pt.weapon_id]
	if (wep == nil) then return end
	if (wep.guntype ~= WPT_DUALIES) then return end

	local dd = pt.dodgeroll
	if dd.count >= wep:get(pt,"dodgerolls") then return end
	if (pt.inktank < wep:get(pt,"dodgeinkcost")) then Paint.HUD:lowInkWarning(p); return end
	pt.inktank = max($ - wep:get(pt,"dodgeinkcost"), 0)
	
	me.jumptime = 0
	pt.spreadjump = 0
	pt.spreadadd = 0
	pt.anglefix = 0
	
	if not dd.count
	and wep:get(pt,"turret_startsound") ~= nil
		S_StartSound(me, wep:get(pt,"turret_startsound"))
	end
	
	local ang = Paint:controlDir(p)
	local dist = FixedMul(wep:get(pt,"dodgedist"), me.scale)
	
	local rad = FixedDiv(me.radius,me.scale)/FU
	local hei = FixedDiv(me.height,me.scale)/FU
	for i = 0,15
		local blob = makeBlob(p,me,pt, rad,hei)
		local ang = R_PointToAngle2(blob.x,blob.y, me.x,me.y)
		P_SetObjectMomZ(blob, P_RandomRange(2,6)*FU)
		P_Thrust(blob,ang, -P_RandomRange(1,3)*me.scale)
		blob.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT &~(MF_NOGRAVITY)
		blob.destscale = 0
		--blob.fuse = 12
		blob.scalespeed = FixedDiv(blob.scale, blob.fuse*FU)
	end
	
	dd.startx = me.x + me.momx
	dd.starty = me.y + me.momy
	dd.oldx = dd.startx; dd.oldy = dd.starty
	
	dd.destx = me.x + P_ReturnThrustX(nil,ang, dist) + me.momx
	dd.desty = me.y + P_ReturnThrustY(nil,ang, dist) + me.momy
	
	if not (P_IsObjectOnGround(me))
		P_SetObjectMomZ(me, -25*FU)
	else
		me.momz = 0
	end
	
	dd.leave = 0
	dd.tics = wep:get(pt,"dodgelength")
	dd.count = $ + 1
	pt.firewait = dd.tics + wep:get(pt,"dodgeendlag")
	S_StartSound(me, sfx_pt_dge)
	return true
end

-- checks mo2 against mo1 if they are on the same team
function Paint:mobjsOnTeam(mo1, mo2)
	if not (mo1.player and mo1.player.valid)
		if (mo2.player and mo2.player.valid)
			return mo1.color == self:getPlayerColor(mo2.player)
		else
			return mo1.color == mo2.color
		end
	elseif not (mo2.player and mo2.player.valid)
		if (mo1.player and mo1.player.valid)
			return mo2.color == self:getPlayerColor(mo1.player)
		else
			return mo2.color == mo1.color
		end
	end
	if (mo1.player == mo2.player) then return true; end
	if (gametyperules & GTR_FRIENDLY)
		if CV.FindVar("friendlyfire").value
			return false
		end
		return true
	end
	if not G_GametypeHasTeams() then return false; end
	return mo1.player.ctfteam == mo2.player.ctfteam
end