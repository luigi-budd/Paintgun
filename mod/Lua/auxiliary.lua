-- auxiliary functions

function Paint:controlDir(p)
	local pt = p.paint
	return (p.cmd.angleturn << 16) + R_PointToAngle2(0, 0, pt.forwardmove << 16, -pt.sidemove << 16)
end
