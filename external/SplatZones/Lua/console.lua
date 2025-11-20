-- CV replacement vars
local CP = SplatZones
CP.Console = {}
local CV = CP.Console
CV.CPMeter = CV_RegisterVar{
	name = "paintcp_meter",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 0, MAX = 15}
}
CV.CPWait = CV_RegisterVar{
	name = "paintcp_wait",
	defaultvalue = 30,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 10, MAX = 255}
}
CV.CPBonus = CV_RegisterVar{
	name = "paintcp_bonus",
	defaultvalue = 500,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 0, MAX = 100000}
}
CV.CPRadius = CV_RegisterVar{
	name = "paintcp_radius",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 0, MAX = 359}
}
CV.CPHeight = CV_RegisterVar{
	name = "paintcp_height",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = {MIN = -1, MAX = 4}
}
CV.CPSpawnBounce = CV_RegisterVar{
	name = "paintcp_spawnbounce",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}
CV.CPSpawnAuto = CV_RegisterVar{
	name = "paintcp_spawnauto",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}
CV.CPSpawnScatter = CV_RegisterVar{
	name = "paintcp_spawnscatter",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}
CV.CPSpawnBomb = CV_RegisterVar{
	name = "paintcp_spawnbomb",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}
CV.CPSpawnGrenade = CV_RegisterVar{
	name = "paintcp_spawngrenade",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}
CV.CPSpawnRail = CV_RegisterVar{
	name = "paintcp_spawnrail",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}
CV.CPSpawnInfinity = CV_RegisterVar{
	name = "paintcp_spawninfinity",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}
CV.Debug = CV_RegisterVar{
	name = "paintcp_debug",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}