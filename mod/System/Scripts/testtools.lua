-- Witcher Speed Toggle: startup hook.
-- startup.luc always loads "testtools", but the retail game ships without it,
-- so this file runs on every launch and binds the hotkeys below.

-- Hotkeys (engine key names, e.g. "V", "B", "F6", "NUMPAD5"). Set to nil to leave a key unbound.
local SPEED_UP_KEY = "V"
local SPEED_DOWN_KEY = "B"

-- Developer console: lets the ` character open the console (needed only to recompile the scripts).
local ENABLE_CONSOLE = false

if ENABLE_CONSOLE then
    g_cAuroraSettings.m_nDebugMode = 1
end

-- The engine saves every bindkey to System\keybinding.ini and reloads it on startup, so after
-- a key is changed above, the old key would stay bound too. Unbind this mod's stale keys.
local function UnbindStaleKeys()
    local wanted = { speedtoggle = SPEED_UP_KEY or "", speedtoggle_down = SPEED_DOWN_KEY or "" }

    local file = io.open("keybinding.ini", "r")
    if not file then return end

    local stale = {}
    for line in file:lines() do
        local _, _, key, script = string.find(line, "^(%S+)%s+runscript%s+(%S+)")
        if key and wanted[script] and string.upper(key) ~= string.upper(wanted[script]) then
            table.insert(stale, key)
        end
    end
    file:close()

    for _, key in ipairs(stale) do
        console("bindkey " .. key)
    end
end

UnbindStaleKeys()

if SPEED_UP_KEY then
    console("bindkey " .. SPEED_UP_KEY .. " runscript speedtoggle")
end

if SPEED_DOWN_KEY then
    console("bindkey " .. SPEED_DOWN_KEY .. " runscript speedtoggle_down")
end
