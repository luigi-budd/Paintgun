assert(Paint,"Load paintgun first IDIOT!!!! Fuckin. Asshole")
assert(TurfWar,"TWO dependencies THAT'S RIGHT! you need PAINTING WAR TOO LOL!!!!")
--from chrispy chars!!! by Lach!!!!
rawset(_G,"SafeFreeslot",function(...)
	local to_freeslot = {...}
	local returning = nil
	local single = (#to_freeslot == 1)
	for _, item in ipairs(to_freeslot) do
		if rawget(_G, item) == nil then
			if single then
				returning = freeslot(item)
			else
				freeslot(item)
			end
		end
	end
	return returning
end)

SafeFreeslot("TOL_PAINTCP")
G_AddGametype({
	name = "Splat Zones",
	identifier = "paintcp",
	typeoflevel = TOL_MATCH|TOL_PAINTCP,
	rules = GTR_OVERTIME|GTR_TEAMS|GTR_SPECTATORS|GTR_POWERSTONES|GTR_POINTLIMIT|GTR_HURTMESSAGES|GTR_PITYSHIELD|GTR_DEATHMATCHSTARTS|GTR_SPAWNINVUL|GTR_NOTITLECARD,
	rankingtype = GT_TEAMMATCH,
	intermissiontype = int_teammatch,
	defaultpointlimit = 3000,
	headercolor = 121,
	description = "Crazy Dog Shit Happenin' In This Gametype"
})

SafeFreeslot(
	"MT_CONTROLPOINT",
	"MT_CPBONUS",
	"S_CPBONUS",
	"SPR_CPBS"
)

// Control point object
mobjinfo[MT_CONTROLPOINT] = {
	//$Name "Control Point"
	//$Sprite EMBMA0
	//$Category "BattleMod Control Point"
	doomednum = 3640,
	spawnstate = S_EMBLEM1,
	height = 32*FU,
	radius = 24*FU,
	flags = MF_NOGRAVITY|MF_SCENERY
}

// Control point object's bonus sphere graphic
mobjinfo[MT_CPBONUS] = {
	spawnstate = S_CPBONUS,
	flags = MF_NOGRAVITY|MF_NOBLOCKMAP|MF_NOCLIPHEIGHT
}

states[S_CPBONUS] = {
	sprite = SPR_CPBS,
	frame = A|FF_FULLBRIGHT|FF_TRANS10,
	tics = 0,
	nextstate = S_CPBONUS
}

rawset(_G,"SplatZones",{})
SplatZones.RoundLength = 180*TR -- TR is rawsetted in both of the other mods loaded, we chillin
Paint.modes[GT_PAINTCP] = true
TurfWar.starttimes[GT_PAINTCP] = SplatZones.RoundLength -- I'd really like turfwar / epix code to handle this timelimit shit considering srb2 is so unreliable about it. Main reason why turfwar is required lol
dofile("console.lua")
dofile("main.lua")
dofile("exec.lua")
