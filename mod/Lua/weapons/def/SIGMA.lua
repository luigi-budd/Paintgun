Paint:registerWeapon({
	name = "SIGMA",
	handoffset = 6*FU,
	h_spread = {25, 25},
	v_spread = {0, 30},
	damage = 2*FU,
	firerate = 0,
	range = 1000*FU,
	bulletspershot = 5,
	
	spread_base = (0), -- chance to spread, similar to accelstart
	spread_pershot = (FU/2), -- add this much chance to spread per shot
	spread_max = (FU * 100), -- max chance to spread
	spread_recovery = 105, -- how many tics to wait before recovering spread
	spread_decay = (FU/2),
	spread_jumpspread = 10*FU, -- how many degrees does jump inaccuracy add?
	spread_jump = 105, -- how many tics until jump spread decays?
	spread_jumpchance = (FU * 100), -- set spread chance to this when jumping
})