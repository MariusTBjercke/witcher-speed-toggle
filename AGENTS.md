# AGENTS.md

Notes for agents and maintainers. User-facing docs are in `README.md` and `docs/README.txt` (the README shipped inside the zip).

## Project at a glance

A mod for The Witcher: Enhanced Edition 1.5 (Aurora engine, 32-bit, Lua 5.0 UI and NWScript game logic). It adds hotkeys that cycle Geralt's movement speed between presets. No external process is involved.

| Path | What |
|---|---|
| `mod/` | Mirrors the game folder. Copy its contents into the game folder to install. |
| `mod/Data/Override/SpeedToggle/inc_speedtoggle.nss` | All logic and the preset table (`GetPresetPercent`, `SPEEDTOGGLE_LEVELS`) |
| `mod/Data/Override/SpeedToggle/speedtoggle.nss`, `speedtoggle_down.nss` | Entry points: `StepSpeedPreset(+1/-1)` |
| `mod/Data/Override/SpeedToggle/*.ncs` | **Compiled** scripts. They are committed, so keep them in sync with the `.nss`. Preset changes are rebuilt by `tools/build_speedtoggle_ncs.py`, anything else needs the game's compiler. |
| `mod/System/Scripts/testtools.lua` | **Shared loader** (loader version 2), byte-identical in witcher-quick-loot and witcher-enginefix. It defines `ModHooks_BindScripts` / `ModHooks_EnableConsole` and runs each known hook file that exists |
| `mod/System/Scripts/speedtoggle_hook.lua` | This mod's settings (keys, console); calls the loader's helpers |
| `optional/VanillaSpeedWithRandomFix/creaturespeed.2da` | Vanilla speed with `RANDOMDEV 0` on the `Normal` row, for Mersey and faster-movement users |
| `docs/README.txt` | The README shipped in the zip, renamed README_WitcherSpeedToggle.txt so it cannot clash with sibling mods |
| `docs/local/` | Git-ignored local notes, for example `nexus.md` (Nexus page and file drafts that follow the conventions of the owner's Liberty Loadout page) |
| `tools/package-release.ps1` | Builds `dist/WitcherSpeedToggle-<version>.zip` (version from `CHANGELOG.md`) |
| `tools/build_speedtoggle_ncs.py` | Rewrites the preset table in both `.ncs` from `inc_speedtoggle.nss`, without the game. It regenerates `GetPresetPercent` (the last function, one 60-byte block per `if`) and the two `CONST int` in `% SPEEDTOGGLE_LEVELS`, in the compiler's own layout. `--check` only verifies |
| `tools/luac50dis.py` | Minimal Lua 5.0 bytecode disassembler for the game's `.luc` files |
| `tools/WitcherDebugMode.ps1` | Reads and sets `m_nDebugMode` in the running game (debugging aid) |

The version lives in `CHANGELOG.md` (`## x.y.z`). Tag releases `vX.Y.Z`.

## Build, test, release

- **Preset changes** (`SPEEDTOGGLE_LEVELS` and the `if (nLevel == N) return P;` lines; keep them in order and keep `return 0;` last): `python -I tools\build_speedtoggle_ncs.py`. No game needed. Fed the 1.1.0 `.nss`, it reproduces the 1.1.0 `.ncs` byte for byte.
- **Compile** (any other change, needs the game). Set `ENABLE_CONSOLE = true` in the installed `speedtoggle_hook.lua`, start the game, type `` ` ``, then run
  `compile ..\Data\Override\SpeedToggle\speedtoggle.nss` (and the same for `speedtoggle_down.nss`).
  The path is relative to the game's `System\` folder. It must include `.nss`, because the compiler strips the last 4 characters. The `.ncs` file is written next to the source, together with a `.ndb` debug file that you should not commit. **Restart the game** to pick up a recompiled `.ncs`.
- **Test** in game: V and B cycle presets, and the feedback line shows `Speed: …`. The speed must survive save/load and area transitions. Test with `ENABLE_CONSOLE = false` and with no `System\keybinding.ini`, so the bindings are proven to come from Lua.
- **Package:** `powershell -File tools\package-release.ps1`, then
  `gh release create vX.Y.Z dist\WitcherSpeedToggle-X.Y.Z.zip --draft --title ... --notes ...`.
  Publish after the owner has tested it.
- Steam's `witcher.exe` is wrapped by SteamStub. Launch the game through Steam, because starting `System\witcher.exe` directly gives "Application load error 5:0000065434".

## Findings (reverse engineering, Steam 1.5.0.1304)

Analysis used a Steamless-unpacked copy of `witcher.exe` in Ghidra. The addresses below are VAs in that unpacked exe, with image base `0x400000`.

**Startup hook.** `System\Scripts\startup.luc` calls `g_Lua:PlayFile(name)` for about 100 scripts. `testtools` (unconditional) and `startup_local` (only when debug mode is on) are missing in retail. The engine accepts plain-text `.lua` as well as compiled `.luc`, from the `SCRIPTS2:`/`SCRIPTS:` aliases, which point to `System\Scripts`. Do not confuse this with `Data\Scripts\testtools.lua`, a CDPR D'jinni tool that is not loaded by `PlayFile`.

**Console.** `FUN_0074eb70` is the character input handler. It opens the console when the typed *character* is `` ` `` (0x60), `g_cAuroraSettings.m_nDebugMode` (`0x00C5068C`, `witcher.exe+0x85068C`) is non-zero, and the GUI exists. It works on characters, not keys, so on Nordic layouts you type the dead key and then Space. Only Lua writes `m_nDebugMode`. No C++ code writes it (all xrefs are reads).

**Dead end: the registry route.** `hwdepsettings.luc` defines `CDebugModeSetting`. Its registry name is obfuscated as `LockPlayerWalk` under `HKCU\Software\CD Projekt RED\Witcher\Settings`. Its `ApplyChanges` maps 108→`m_nDebugMode=1` and 230→`2`, otherwise 0. Setting it as REG_SZ did **not** enable the console in practice. The base class only applies "changed" values, so this was abandoned in favour of the `testtools` hook. `witcher.ini` `[Game Options] Debug Mode=1` also does nothing.

**Script compiler.** The console command `compile <path>` is registered to `FUN_00aba340`. It loads `nwscriptdefn`, strips 4 characters (`.nss`), sets the temporary aliases `CLSOURCE:`/`CLTARGET:` to the file's directory, and writes the `.ncs` there. `compile speedtoggle` without a path silently produces nothing. The console command `nss <code>` (`FUN_009a1a40`) wraps the code in `#include "inc_console"` + `void main(){…}`, compiles it to `TEMP:temp_script` and runs it, which is handy for one-off tests. Engine function signatures are in `System\Scripts\nwscriptdefn.nss`, and CDPR's include sources are in `Data\Scripts\Inc\`.

**Key macros.** The console command `bindkey <KEY> <command>` (`FUN_0041eeb0`) looks up the key name case-insensitively in the table at `0x00b434a8` (`MOUSE_BUTTON0` = index 0, …). It then saves all macros to `System\keybinding.ini` as `KEY command` lines (`FUN_0041ddd0`). On startup, `FUN_0041f030` clears every macro and replays each line of that file through `bindkey`. It sets `DAT_00c512ea` while doing so, which suppresses the save. Because of this, a key the mod no longer uses would stay bound after a config change. `testtools.lua` therefore reads `keybinding.ini` with Lua's `io` library, which retail scripts such as `gui_mainmenu.luc` also use, and runs `bindkey <KEY>` with no command to unbind every line that runs `speedtoggle`/`speedtoggle_down` on a key that is no longer configured. Other macros are left alone. This works whichever of the two runs first. Only single key names exist: there is no modifier syntax, and CapsLock and mouse buttons 4/5 have no name. Macros run console commands **without** debug mode. The registry `Bindings` values use the same index: letters A–Z are 79–104, F1–F12 start at 12, and the digits 1–9 are 31–39.

**Speed effect.** CDPR's `inc_witcher_01.nss` has `SetMovementRateEffect`, which uses `EffectMovementSpeedIncrease` (0–99%). Shipped scripts appear not to use it. This mod tags its effect by wrapping it in `SupernaturalEffect`. It identifies its own effects by type 28 + permanent duration + the subtype obtained from `GetEffectSubType(SupernaturalEffect(EffectMovementSpeedIncrease(1)))`, so no hard-coded subtype constant is needed. The preset index is stored in the local int `MOD_SPEEDTOGGLE_LEVEL` on the PC, which persists in saves.

**UI feedback.** `FloatingTextStringOnCreature` vanishes almost immediately. The script instead uses `RunClientLua("g_GuiInGame:ShowGameInfo('feedback', '<text>')")`, the same line the game uses for "Received: …".

**Base speed.** `creaturespeed.2da`, row 4 `Normal`: vanilla `MOVERATE 1.0`, `RANDOMDEV 0.2`. The random deviation is the "random running speed" bug. Project Mersey and *Faster Movement for Geralt (30%)* both ship `MOVERATE 1.3`, `RANDOMDEV 0`.

## Pitfalls

- `mod/System/Scripts/testtools.lua` must stay **byte-identical** with the copies in `witcher-quick-loot` and `witcher-enginefix` ([Witcher Engine Fix](https://github.com/MariusTBjercke/witcher-enginefix), hook `enginefix_hook`). The game's Lua cannot list a folder, so the loader names every hook in `HOOKS`. A new mod that uses the loader adds its hook name there; then bump the "loader version" comment and release every mod that ships the loader.
- In a hook's settings, `false` unbinds a key. `nil` drops the entry from the table, so a previous binding is never cleaned up.
- A resref can be at most 16 characters. `speedtoggle_down` is exactly 16.
- `OVERRIDE=..\Data` in `System\witcher.ini` makes the whole `Data` tree an override, so loose files anywhere under `Data` are loaded. Don't leave stale copies of the `.ncs` elsewhere under `Data`.
- Edits to the `.nss` do nothing until the file is recompiled **and** the game is restarted.

## Redoing the investigation

- Unpack: run [Steamless](https://github.com/atom0s/Steamless) on `System\witcher.exe`, which writes `witcher.exe.unpacked.exe`, then import that into Ghidra.
- Lua: `python -I tools/luac50dis.py "<game>\System\Scripts\startup.luc" testtools` prints the functions whose disassembly contains the given strings.
- Live debug state: `powershell -File tools\WitcherDebugMode.ps1 [-Set 1]` while the game runs.
