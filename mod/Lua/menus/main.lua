rawset(_G, "MENULIB_ROOT", "lib/MenuLib/")
dofile("lib/MenuLib/exec.lua")

local items = {
	"weaponpicker",
}
for k, file in ipairs(items)
	dofile("menus/items/" .. file ..".lua")
end
