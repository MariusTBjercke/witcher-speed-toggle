# Witcher Speed Toggle

Hotkey movement-speed presets for **The Witcher: Enhanced Edition**. Switch Geralt's running speed on the fly, with no external program, no AutoHotkey and no trainer. Everything runs inside the game's own script engine.

| Key | Action |
|---|---|
| `V` | Next speed preset |
| `B` | Previous speed preset |

Presets: **Normal → +15% → +30% → +50% → +70% → +90%**. They wrap around in both directions.

- The active preset is shown in the game's feedback line (`Speed: +30%`).
- The preset is stored in your save game and persists through area transitions and save/load.
- Speed changes made by the game itself are left alone. The mod only adds and removes its own effect.

## Requirements

- The Witcher: Enhanced Edition, patch **1.5** (Steam or GOG, Director's Cut). Tested on Steam 1.5.0.1304.

## Installation

1. Download `WitcherSpeedToggle-<version>.zip` from [Releases](https://github.com/MariusTBjercke/witcher-speed-toggle/releases).
2. Extract the `Data` and `System` folders into your game folder and merge them with the existing ones, for example:
   `...\steamapps\common\The Witcher Enhanced Edition\`
3. Start the game. The hotkeys are bound automatically on every launch.

Files installed:

| Path | Purpose |
|---|---|
| `Data\Override\SpeedToggle\` | Compiled scripts (`.ncs`) and their source (`.nss`) |
| `System\Scripts\speedtoggle_hook.lua` | Settings: hotkeys and console |
| `System\Scripts\testtools.lua` | Shared startup loader (see [Compatibility](#compatibility)) |

## Configuration

Edit `System\Scripts\speedtoggle_hook.lua`:

```lua
local SPEED_UP_KEY = "V"      -- one engine key name, see below
local SPEED_DOWN_KEY = "B"    -- set to false to leave it unbound
local ENABLE_CONSOLE = false  -- true enables the developer console (` character)
```

When you change a key, the old key is unbound automatically on the next launch.

### What a hotkey can be

The hotkeys use the engine's own `bindkey` command, which has these limits:

- **One key per action, with no modifiers.** Combinations such as Shift+V or Ctrl+F6 are not supported.
- **Only the engine's key names are accepted.** Case does not matter:
  - `A`–`Z`, `0`–`9`, `F1`–`F12`
  - `NUMPAD0`–`NUMPAD9`, `NUMPADPLUS`, `NUMPADMINUS`, `NUMPADMULTIPLY`, `NUMPADDIVIDE`, `NUMPADDECIMAL`, `NUMPADENTER`
  - `INSERT`, `DELETE`, `HOME`, `END`, `PAGEUP`, `PAGEDOWN`, `PRINTSCREEN`
  - `LEFT_ARROW`, `RIGHT_ARROW`, `UP_ARROW`, `DOWN_ARROW`
  - `SPACE`, `TAB`, `BACK`, `RETURN`, `ESC`
  - `LEFTSHIFT`, `RIGHTSHIFT`, `LEFTCTRL`, `RIGHTCTRL`, `LEFTALT`, `RIGHTALT`
  - `MINUS`, `EQUALS`, `LBRACKET`, `RBRACKET`, `BACKSLASH`, `SEMICOLON`, `APOSTROPHE`, `GRAVE`, `COMMA`, `PERIOD`, `FORWARDSLASH`
  - `MOUSE_BUTTON0`–`MOUSE_BUTTON2`, `JOYSTICK_BUTTON0`, `JOYSTICK_BUTTON1`
- **Not available:** CapsLock, extra mouse buttons (4/5) and most gamepad buttons. The engine has no names for them.
- **Pick a key the game does not use.** With the default controls these are free: `V B N K O P Y`, `F4 F6 F7 F8 F10 F11 F12`, `0 9`, the numpad keys, and `INSERT HOME END DELETE`. Binding a key the game already uses has not been tested. Expect both the game's action and the speed change.

What has been tested: `V`, `B` and `N` on the Steam version. The other names come from the engine's key table and should work the same, but they have not been tried one by one. The punctuation names follow the US keyboard layout, so on other layouts they may sit on a differently labelled key (untested).

## Using a "faster movement" mod or Project Mersey

Project Mersey and *Faster Movement for Geralt* make Geralt permanently faster by editing `creaturespeed.2da`. This mod still works with them, but the presets stack on top of the faster base speed, so "Normal" is no longer vanilla speed.

To make "Normal" true vanilla speed, use `Optional\VanillaSpeedWithRandomFix\creaturespeed.2da`. It is vanilla speed, but it keeps the fix for the "random running speed" bug.

- **With Project Mersey:** overwrite `Data\Override\ProjectMersey\2DA\creaturespeed.2da` with it.
- **With a faster-movement mod:** remove that mod's `creaturespeed.2da` and put this one in `Data\Override`.

## Changing the presets

The presets live in `inc_speedtoggle.nss` (`GetPresetPercent` and `SPEEDTOGGLE_LEVELS`). The engine accepts 0–99%. To recompile, use the game's built-in compiler:

1. Set `ENABLE_CONSOLE = true` in `speedtoggle_hook.lua` and start the game.
2. Open the console by typing the `` ` `` character. On keyboards where `` ` `` is a dead key, press it and then Space.
3. Run:
   ```
   compile ..\Data\Override\SpeedToggle\speedtoggle.nss
   compile ..\Data\Override\SpeedToggle\speedtoggle_down.nss
   ```
4. Restart the game to load the new scripts.

From a clone of this repository you can skip the game: after editing the presets in `mod\Data\Override\SpeedToggle\inc_speedtoggle.nss`, run `python -I tools\build_speedtoggle_ncs.py` to rebuild both `.ncs` files, then copy the folder into the game.

## Uninstall

1. In game, cycle back to `Speed: Normal` before saving. Otherwise the speed bonus stays on the character in that save.
2. Delete `Data\Override\SpeedToggle` and `System\Scripts\speedtoggle_hook.lua`. Also delete `System\Scripts\testtools.lua`, unless [Witcher Quick Loot](https://github.com/MariusTBjercke/witcher-quick-loot) or [Witcher Engine Fix](https://github.com/MariusTBjercke/witcher-enginefix) is installed, because they use the same file.
3. Optionally delete `System\keybinding.ini`, which holds the engine's saved key macros.

## Known issue: hotkeys stop after Alt+Tab in full screen

Without DXVK, in exclusive full screen ("Full screen" ticked in Options > Graphics), the game rebuilds its input handling when it loses focus (Alt+Tab, the Windows key, clicking another window) and forgets every key bound with `bindkey`. V and B then do nothing until the next launch. Workarounds:

- Untick "Full screen" (windowed or borderless window).
- Use [DXVK](https://github.com/doitsujin/dxvk) (its 32-bit `d3d9.dll` next to `witcher.exe`), which avoids the rebuild.
- After coming back, untick and tick "Full screen" again in the options: changing it rebinds the hotkeys.
- With the console enabled, type `bindkey V runscript speedtoggle` (and `bindkey B runscript speedtoggle_down`) after coming back.

Changing "Full screen" or the resolution in the options is handled automatically (loader version 3).

## Compatibility

- `System\Scripts\testtools.lua` is a shared loader. It is the only Lua file the game runs on startup that the retail release does not ship. [Witcher Quick Loot](https://github.com/MariusTBjercke/witcher-quick-loot) (1.0.2 or newer) and [Witcher Engine Fix](https://github.com/MariusTBjercke/witcher-enginefix) ship the identical file, so the mods can be installed in any order. Keep the newest one (loader version 3, Speed Toggle 1.2.2): version 2 does not rebind the hotkeys after a video mode change, and version 1 (Speed Toggle 1.2.0 and older, Quick Loot 1.0.1 and older) also does not run Engine Fix's hook, which turns off its load/save-menu fix. A mod from another author that replaces `testtools.lua` would break the hotkeys; merge the two files by hand.
- Above roughly +50%, the running animation visibly speeds up as well.

## How it works

The game's startup Lua script (`startup.luc`) calls `g_Lua:PlayFile("testtools")`, but the retail release has no such file. This mod provides it as a small shared loader, which runs `speedtoggle_hook.lua`. The hook calls the engine's built-in `bindkey` console command to bind the hotkeys to `runscript speedtoggle` and `runscript speedtoggle_down`. The NWScripts apply `EffectMovementSpeedIncrease` (wrapped in `SupernaturalEffect`) to the player and show the preset through `g_GuiInGame:ShowGameInfo`.

## Building a release

```powershell
powershell -File tools\package-release.ps1
```

This writes `dist\WitcherSpeedToggle-<version>.zip`. The version is taken from `CHANGELOG.md`.

## License

[MIT](LICENSE). The Witcher is a trademark of CD PROJEKT S.A. This is an unofficial fan mod.
