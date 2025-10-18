Paint.CV = {}
local CV = Paint.CV

CV.splatter_lifetime = CV_RegisterVar({
	name = "paint_splatlifetime",
	defaultvalue = "20",
	flags = CV_SHOWMODIF|CV_NETVAR,
	PossibleValue = {MIN = -1, MAX = 120} 
})

CV.directhit_crosshair = CV_RegisterVar({
	name = "paint_hitcrosshair",
	defaultvalue = "On",
	flags = CV_SHOWMODIF,
	PossibleValue = CV_OnOff 
})

CV.paintguns = CV_RegisterVar({
	name = "paint_active",
	defaultvalue = "Yes",
	flags = CV_SHOWMODIF|CV_NETVAR,
	PossibleValue = CV_YesNo
})

CV.paintnerfs = CV_RegisterVar({
	name = "paint_nerfs",
	defaultvalue = "No",
	flags = CV_SHOWMODIF|CV_NETVAR,
	PossibleValue = CV_YesNo
})