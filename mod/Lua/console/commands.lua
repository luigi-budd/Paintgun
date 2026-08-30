local CV = Paint.CV

local function AddCommand(name, func)
	COM_AddCommand("paint_"..name, function(p, ...)
		local pt = p.paint
		if not pt then return end
		
		func(p,pt, ...)
	end, COM_ADMIN)
end

AddCommand("setteam", function(p,pt, teamname)
	Paint:setPlayerTeam(p, teamname)
end)