WITCHER SPEED TOGGLE
Hotkey movement-speed presets for The Witcher: Enhanced Edition (1.5, Steam / GOG)
=====================================================================================

Switch Geralt's movement speed on the fly with a hotkey - no external program,
no AutoHotkey, no trainer. Everything runs inside the game's own script engine.

  V  ->  next speed preset
  B  ->  previous speed preset

Presets:  Normal -> +15% -> +30% -> +50% -> +70% -> +90%  (wraps around)

The active preset is shown in the game's feedback line ("Speed: +30%"), is stored
in your save game and persists through area transitions and save/load.


INSTALLATION
------------
1. Copy the "Data" and "System" folders into your game folder, e.g.
     ...\steamapps\common\The Witcher Enhanced Edition\
   (merge with the existing folders).
2. Start the game. That's it - the hotkeys are bound automatically on every launch.

Files installed:
  Data\Override\SpeedToggle\   compiled scripts (.ncs) + their source (.nss)
  System\Scripts\speedtoggle_hook.lua  settings (hotkeys, console)
  System\Scripts\testtools.lua         shared startup loader (see COMPATIBILITY)


CONFIGURATION
-------------
Open System\Scripts\speedtoggle_hook.lua in a text editor:

  local SPEED_UP_KEY = "V"      -- one engine key name, see below
  local SPEED_DOWN_KEY = "B"    -- set to false to leave it unbound

When you change a key, the old key is unbound automatically on the next launch.

What a hotkey can be (limits of the engine's own "bindkey" command):
- One key per action, with no modifiers. Shift+V, Ctrl+F6 and similar do not work.
- Only the engine's key names are accepted (case does not matter):
    A-Z, 0-9, F1-F12, NUMPAD0-NUMPAD9, NUMPADPLUS, NUMPADMINUS, NUMPADMULTIPLY,
    NUMPADDIVIDE, NUMPADDECIMAL, NUMPADENTER, INSERT, DELETE, HOME, END, PAGEUP,
    PAGEDOWN, PRINTSCREEN, LEFT_ARROW, RIGHT_ARROW, UP_ARROW, DOWN_ARROW, SPACE,
    TAB, BACK, RETURN, ESC, LEFTSHIFT, RIGHTSHIFT, LEFTCTRL, RIGHTCTRL, LEFTALT,
    RIGHTALT, MINUS, EQUALS, LBRACKET, RBRACKET, BACKSLASH, SEMICOLON, APOSTROPHE,
    GRAVE, COMMA, PERIOD, FORWARDSLASH, MOUSE_BUTTON0-2, JOYSTICK_BUTTON0-1
- Not available: CapsLock, extra mouse buttons (4/5), most gamepad buttons.
- Pick a key the game does not use. Free with the default controls:
    V, B, N, K, O, P, Y, F4, F6, F7, F8, F10, F11, F12, 0, 9, the numpad keys,
    Insert, Home, End, Delete.
  Binding a key the game already uses is untested; expect both actions to happen.

Tested: V, B and N on the Steam version. The other names come from the engine's
key table and should work the same, but have not been tried one by one. The
punctuation names follow the US layout, so on other layouts they may be on a
differently labelled key (untested).


IF YOU USE A "FASTER MOVEMENT" MOD OR PROJECT MERSEY
----------------------------------------------------
Mods such as "Faster Movement for Geralt" and Project Mersey make Geralt permanently
faster by editing creaturespeed.2da. That still works with this mod, but the presets
then stack on top of the faster base speed ("Normal" is no longer vanilla speed).

To get true vanilla speed as the "Normal" preset, use the file in
  Optional\VanillaSpeedWithRandomFix\creaturespeed.2da
It is vanilla speed but keeps the fix for the "random running speed" bug.
- With Project Mersey: overwrite Data\Override\ProjectMersey\2DA\creaturespeed.2da with it.
- With a faster-movement mod: remove that mod's creaturespeed.2da and put this one
  in Data\Override instead.


CHANGING THE PRESETS (ADVANCED)
-------------------------------
The preset values live in Data\Override\SpeedToggle\inc_speedtoggle.nss
(GetPresetPercent and SPEEDTOGGLE_LEVELS; the engine accepts 0-99%).
After editing, recompile in the game's developer console:

1. In speedtoggle_hook.lua set:  local ENABLE_CONSOLE = true   and start the game.
2. Open the console by typing the ` character
   (on keyboards where ` is a dead key, press it and then Space).
3. Run:
     compile ..\Data\Override\SpeedToggle\speedtoggle.nss
     compile ..\Data\Override\SpeedToggle\speedtoggle_down.nss
4. Restart the game to load the new scripts.


UNINSTALL
---------
1. In game, cycle back to "Speed: Normal" before saving (otherwise the speed bonus
   stays on the character in that save).
2. Delete Data\Override\SpeedToggle and System\Scripts\speedtoggle_hook.lua.
   Also delete System\Scripts\testtools.lua, unless Witcher Quick Loot or Witcher
   Engine Fix is installed (they use the same file).
3. Optionally delete System\keybinding.ini (the engine's saved key macros).


COMPATIBILITY / NOTES
---------------------
- System\Scripts\testtools.lua is a shared loader: the retail game runs it on startup
  but does not ship it. Witcher Quick Loot 1.0.2+ and Witcher Engine Fix
  (https://github.com/MariusTBjercke/witcher-enginefix) ship the identical file
  (loader version 2), so the mods can be installed in any order. Speed Toggle 1.2.0
  and older and Quick Loot 1.0.1 and older ship loader version 1, which does not run
  Engine Fix's hook - installing one of them after Engine Fix turns off its
  load/save-menu fix, so update them. A mod from another author that replaces
  testtools.lua would break the hotkeys - merge the two files by hand.
- The speed bonus is a "supernatural" movement-speed effect that only this mod adds
  and removes; speed changes applied by the game itself are left alone.
- Above roughly +50% the running animation visibly speeds up as well.
- Tested on the Steam version (1.5.0.1304) with DXVK.

HOW IT WORKS
------------
The game's startup Lua script calls PlayFile("testtools"), which is missing in the
retail release. This mod provides it as a small shared loader that runs
speedtoggle_hook.lua, which uses the engine's built-in "bindkey" console
command to bind the hotkeys to "runscript speedtoggle" / "runscript speedtoggle_down".
The NWScripts apply EffectMovementSpeedIncrease to the player and show the preset via
g_GuiInGame:ShowGameInfo.
