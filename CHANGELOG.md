# Changelog

## 1.2.2

- Shared loader version 3: the hotkeys keep working after "Full screen" or the resolution is changed in the options. The engine replaced its input handling on every video mode change and dropped all keys bound with `bindkey`; the loader now binds them again right after. Identical in Witcher Quick Loot and Witcher Engine Fix.
- Known issue: in exclusive full screen without DXVK, losing focus (Alt+Tab, the Windows key) still drops the hotkeys until the next launch. Play in borderless/windowed mode or with DXVK (see the README).

## 1.2.1

- Shared loader version 2: also runs Witcher Engine Fix's hook (`enginefix_hook`). `testtools.lua` is now identical in Witcher Quick Loot 1.0.2 and Witcher Engine Fix, so installing this mod after Engine Fix no longer turns off Engine Fix's load/save-menu fix.

## 1.2.0

- New top preset: +90%. V / B now step through Normal, +15%, +30%, +50%, +70% and +90%.
- `tools/build_speedtoggle_ncs.py` rebuilds the compiled scripts from the preset table in `inc_speedtoggle.nss`, so changing the presets no longer needs the game's console.

## 1.1.0

- Settings moved to `System\Scripts\speedtoggle_hook.lua`. `testtools.lua` is now a shared loader, identical in Witcher Quick Loot, so the two mods can be installed in any order.
- A hotkey set to `false` is now unbound as well (`nil` from 1.0.0 still works but leaves an old binding behind).

## 1.0.0

- First release: V / B step Geralt's movement speed through Normal, +15%, +30%, +50% and +70%.
- Hotkeys are bound automatically at startup through `System\Scripts\testtools.lua` (configurable). A key that is changed there is unbound on the next launch.
- Optional vanilla-speed `creaturespeed.2da` with the random-running-speed fix.
