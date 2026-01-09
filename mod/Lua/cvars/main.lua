Paint.CV = {}
local CV = Paint.CV

local CV_Lookup = {}
setmetatable(CV_Lookup, {
	__mode = "kv"
})

CV.FindVar = function(cv_name)
	if CV_Lookup[cv_name]
		return CV_Lookup[cv_name]
	end
	local cvar = CV_FindVar(cv_name)
	CV_Lookup[cv_name] = cvar
	return cvar
end

CV.splatter_lifetime = CV_RegisterVar({
	name = "paint_splatlifetime",
	defaultvalue = "20",
	flags = CV_SHOWMODIF|CV_NETVAR,
	PossibleValue = {MIN = -1, MAX = 120} 
})
CV.paintguns = CV_RegisterVar({
	name = "paint_active",
	defaultvalue = "Yes",
	flags = CV_SHOWMODIF|CV_NETVAR,
	PossibleValue = CV_YesNo
})
CV.paintnerfs = CV_RegisterVar({
	name = "paint_nerfs",
	defaultvalue = "Yes",
	flags = CV_SHOWMODIF|CV_NETVAR,
	PossibleValue = CV_YesNo
})

-- local cvars
CV.directhit_crosshair = CV_RegisterVar({
	name = "paint_hitcrosshair",
	defaultvalue = "Accurate",
	flags = CV_SHOWMODIF,
	PossibleValue = {Accurate = 1, Performance = 2, Off = 0} 
})
CV.nametags = CV_RegisterVar({
	name = "paint_nametags",
	defaultvalue = "On",
	flags = CV_SHOWMODIF,
	PossibleValue = CV_OnOff 
})
CV.damagenumbers = CV_RegisterVar({
	name = "paint_damagenumbers",
	defaultvalue = "Off",
	flags = CV_SHOWMODIF,
	PossibleValue = CV_OnOff 
})
