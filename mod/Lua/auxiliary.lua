-- auxiliary functions and SHIT!

function Paint:controlDir(p)
	local pt = p.paint
	return (p.cmd.angleturn << 16) + R_PointToAngle2(0, 0, pt.forwardmove << 16, -pt.sidemove << 16)
end

freeslot("S_PAINT_SPLASH")
states[S_PAINT_SPLASH] = {
	sprite = SPR_PAINT_MISC,
	frame = 6|FF_ANIMATE,
	var1 = 14 - 6,
	var2 = 2,
	tics = (14 - 6)*2,
}
