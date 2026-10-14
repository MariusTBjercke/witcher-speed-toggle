-- Witcher Speed Toggle: settings. Run on every launch by the shared loader in testtools.lua.

-- Hotkeys: one engine key name each (see README), or false to leave the action unbound.
local SPEED_UP_KEY = "V"
local SPEED_DOWN_KEY = "B"

-- Developer console: lets the ` character open the console (needed only to recompile the scripts).
local ENABLE_CONSOLE = false

if ENABLE_CONSOLE then
    ModHooks_EnableConsole()
end

ModHooks_BindScripts({ speedtoggle = SPEED_UP_KEY, speedtoggle_down = SPEED_DOWN_KEY })
