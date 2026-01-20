states[freeslot("S_PAINT_BURSTBOMB")] = {
	frame = 1|FF_SEMIBRIGHT,
	sprite = SPR_PAINT_BOMB,
	tics = -1,
}
sfxinfo[freeslot("sfx_pb_ep2")].caption = "Explosion"

Paint:registerSubWeapon({
	realname = "Burst Bomb",
	name = "burstbomb",
	icon = "PTSUB_BURST",
	spawnstate = S_PAINT_BURSTBOMB,
	
	explodeoncontact = true,
	fuse = 100*TR,
	allowhitmarkers = true,
	explodesound = sfx_pb_ep2,
	
	inkcost = 45*FU,
	
	inner_radius = 60*FU,
	inner_damage = 35*FU,
	outer_radius = 143*FU,
	outer_damage = 25*FU,
	quakeforce = 3*FU,
})
