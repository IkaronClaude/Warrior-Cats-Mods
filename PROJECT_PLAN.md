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

## Discovery results (2026-10-24)
**Engine: UE 5.7.4**, read from the crash report's `<EngineVersion>5.7.4-0+UE5` (built from a `ue572` branch). The
version info in the exe only says "UE5-CL-0".

How to run the game on this VM, which has no GPU:
- **Steam must be running.** The operator logged in. The real exe's SteamStub refuses a non-Steam launch ("application
  load error 6:0000065432").
- **Use the Steamless-unpacked copy:** `Wrc-Win64-Shipping-NoStub.exe`, next to the original on Z:, plus
  `steam_appid.txt` = 3960600. Ownership is still checked through steam_api.
- **Run with `-nullrhi -nosound -unattended`:** D3D12 WARP dies in PipelineStateCache.cpp:602. With no renderer the game
  logic and UE4SS run fine.

**UE4SS experimental (2026-10-17 build) works on 5.7.4 as is.** Tested with dwmapi.dll + `ue4ss/` next to the exe.
- The AutoDump Lua mod dumped the usmap, the object dump, the CXX headers and the UHT headers.
- Copies are in the gitignored `dumps/`: `Wrc-5.7.4-0+UE5-83330635.usmap`, `CXXHeaderDump/`, `UHTHeaderDump/`,
  `UE4SS_ObjectDump.txt`.
- The object dump only covers what the main menu loaded.

Code modules:
- `Wrc` (the game)
- the studio framework: `SwtEngine`, `SwtAdventure`, `SwtQuest`
- 17,202 pak files; the content is under `/Game/Art`, `/Game/Gameplay/...` and `/Game/Quests`

**Customisation:** `FCatCustomData` (SwtAdventure, 0xF8 bytes) is the whole cat. It holds:
- `ClanType`, `Role`
- Body / Face / Fur / Tail / Ear / Eye / Whisker as `*Offset` + `*Value` + `*Idx`
- the colours, all indices: `FurColorIdx`, `Pattern01ColorIdx`, `Pattern02ColorIdx`, `PatternIdx`, `MarkingIdx`,
  `EyeLeftColorIdx`, `EyeRightColorIdx`
- **`bOverrideColors`**, `Design`, `Gender`, `CatSize`
- the accessories (Neck / Paw / Head / Body Id + Var) and the scars
- **`PrefixNameId` / `SuffixNameId`**

Colours are rows of `FCatColor` (`TArray<float> Values`). The data tables are under `Gameplay/DataTables/Customization`
(`DT_Patterns`, `DT_Markings`, `DT_TexturesByBody`). The UI is `UGuiCustomization*Panel` (Color / Markings / Nature /
Pattern), `UGuiColorPickerGrid` and `AGuiCatCustomActor` (the preview: `RefreshPattern`, `RefreshShape`,
`SetCustomDataFromSave`). The mesh is `UWrcCustomizableMeshComponent` (base `USwtAdventureCustomizableMeshComponent`).

**Names:** a cat stores only `PrefixNameId` + `SuffixNameId`; the text comes from the tables:
- `FPreffixName` (the string + clan weights + `Preffix_ID`)
- `FSuffixName` (the string + rank weights + `Suffix_ID`)
- the filter tables `FPrefixNameFilter` / `FSuffixNameFilter` (body / personality), `FNameBanList`, `FRogueNames`

The text is composed by code that is NOT reflected: nothing in the UHT dump builds names. So free-form names use this
plan:
- keep the generated IDs as the online-safe fallback (the operator's requirement)
- override the DISPLAYED name (TextBlock text / the name source)

**Input:** keys become `ECommands` (SwtEngine_enums, 109 values: `Player_Pause` = 89, `Player_Show_Quest` = 76,
`Player_Show_Map`, `Player_Show_Inventory`, ...).
- The hooks: `ASwtPlayerController:OnKeyPressed / OnKeyReleased (FKey)` and `USwtInputComponent:OnListenCommandInternal
  (ECommands, EInputEvent)`. Both are UFUNCTIONs that UE4SS can hook / call.
- `DefaultInput.ini` only maps Jump + the move / look axes.
- `DT_Keys` is key -> button icon only.
- The default key -> command table was not found in reflected data (probably native).
- Remap UI: `UGuiCustomConfigKey` (ActionCommand).

**Online:** a PlayFab backend (Admin/Client *CustomProperties requests in the exe) + the EOS SDK.

## Tools in this repo
- `tools/AssetDump`: a headless CUE4Parse CLI.
  - `list` writes every pak path.
  - `json <pkg> <out> <usmap>` exports a package's objects as JSON.
  - `raw <file> <out>` writes a file's bytes (ini etc.).
  - Use EGame `GAME_UE5_7`.
- `tools/bin/` (gitignored): UE4SS experimental, Steamless.

## Unreal Editor (5.7)
Parked 2026-10-24. The Epic launcher is installed on this VM (C:\Program Files\Epic Games) and logged in, but the
Unreal Engine library never offers an engine version: the + / Install Engine buttons do nothing. Still the same after
a re-login, clearing the web cache and running as admin. The log showed "SetNamedSecurityInfo failed with 5" on its
install folder.

The editor couldn't run here anyway (no GPU; even the game dies on WARP), so editor work (UMG widgets, Blueprint mod
paks) belongs on the operator's main PC. Headless cooking (UnrealEditor-Cmd -run=cook -nullrhi) is the only reason to
retry the install on this VM.

## Log
- 2026-10-24: repo created; the operator's 19 baseline ideas filed in tickets.md (P0 foundation added first).
- 2026-10-24: the operator set the goal: an open-source modding framework ASAP. The first hooks are customisation, name
  choice and PC controls, with clean extensible APIs; ease of install front and center. Z: is ours to modify. Discovery
  done (above): engine 5.7.4, UE4SS works, the dumps exist, the customisation / name / input structures are mapped.
