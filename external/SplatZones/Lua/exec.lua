local CP = SplatZones
-- Net
local function sync(net)
	//Control Point
	CP.Num			= net($)
	CP.Mode	  	 	= net($)
	CP.LeadCapAmt 	= net($)
	CP.Active	 	= net($)
	CP.Capturing  	= net($)
	CP.Blocked   	= net($)
	CP.Timer	  	= net($)
	CP.ID		 	= net($)
	CP.TeamCapAmt 	= net($)
end
addHook("NetVars",sync)

-- PaintCP
local function onBonusRmve(mo)
	if mo.target then
		P_SpawnMobj(mo.x,mo.y,mo.z,MT_SPARK)
	end
end
addHook("MapChange",CP.Reset)
addHook("MobjSpawn",CP.Spawn,MT_CONTROLPOINT)
addHook("MapThingSpawn",CP.MapThingSpawn,MT_CONTROLPOINT)
addHook("MapLoad",CP.Generate)
addHook("MobjThinker",CP.PointThinker,MT_CONTROLPOINT)
addHook("MobjThinker",CP.SphereThinker,MT_CPBONUS)
addHook("MobjRemoved",onBonusRmve,MT_CPBONUS)
addHook("ThinkFrame",CP.ThinkFrame)

