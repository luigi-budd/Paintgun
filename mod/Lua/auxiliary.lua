-- auxiliary functions

function Paint:controlDir(p)
	local pt = p.paint
	return (p.cmd.angleturn << 16) + R_PointToAngle2(0, 0, pt.forwardmove << 16, -pt.sidemove << 16)
end

-- okay...
for i = 0, 8
	states[S_SPLISH1 + i].frame = $ &~FF_TRANSMASK
end