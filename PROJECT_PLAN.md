# PROJECT_PLAN.md: Warrior Cats: Clans of the Forest mod

The authoritative log: decisions + per-task results ("what we decided and why"). The backlog is `tickets.md`.

## The game (as found 2026-10-24)
- Install (READ-ONLY reference, the operator's copy): `Z:/Warrior Cats Clans of the Forest/`. Steam app 3960600,
  depot 3960601.
- Unreal Engine 5, project name **`Wrc`** (`Wrc/Content/Paks`, `Wrc/Binaries/Win64/Wrc-Win64-ShippingDRM.exe`).
- **IoStore** packaging:
  - `pakchunk0-Windows.utoc/.ucas` (~3 GB)
  - a small `pakchunk0-Windows.pak` (v12, index NOT encrypted)
  - `global.utoc/.ucas`

  The utoc is version 8 (ReplaceIoChunkHashWithIoHash). Pak v12 + utoc v8 suggest UE 5.4 or later. The exact version
  is still to pin (tickets P0).
- The exe has a **`.bind` section = a SteamStub DRM wrapper**: its strings are packed, so the version info only says
  "UE5-CL-0". Tools that read the exe statically need the unpacked image; UE4SS works at runtime.
- **EOS SDK** (`EOSSDK-Win64-Shipping.dll`): online content. The free-form name (ticket 3) must keep a generated
  fallback for it.
- An `Engine/Plugins/NNE` folder (neural network engine).
- Controller configs for Steam Input (ps4 / ps5 / switch / xbox).

## Ground rules
- **BYO:** never commit game data. This covers paks, extracted assets, `.locres`, mappings, audio and the exe/dlls
  (see `.gitignore`). The repo ships code, scripts, Lua, mod-project sources and docs.
- **The install on Z: is READ-ONLY.** Copy anything a test needs to mutate. Installing mods into the game folder needs
  the operator's agreement (tickets P0, "Deploy rule"). Never rm -rf on Z:.
- **Mechanics first, story later** (the operator's key philosophy; see tickets.md).

## Planned toolchain (P0, to verify)
- FModel: browse / export the IoStore paks; needs the `.usmap` mappings.
- UE4SS:
  - runtime injection, Lua mods
  - object + C++ header dumps
  - the usmap dumper
  - the Blueprint mod loader
- retoc / ZenTools: build IoStore mod paks.
- The matching UE5 editor + a skeleton project for Blueprint mods / cooking.

## Log
- 2026-10-24: repo created; the operator's 19 baseline ideas filed in tickets.md (P0 foundation added first).
