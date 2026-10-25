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

## Running the game WITH a renderer on the GPU-less VM: not possible (2026-10-25)
Every route was tried; a real-creator check needs the operator's PC.
- `-dx11 -warp`: "A D3D11-compatible GPU (Feature Level 11.0, Shader Model 5.0) is required".
- `-vulkan` with Mesa lavapipe (VK_ICD_FILENAMES): "Unable to launch with RHI 'Vulkan' since the project is not
  configured to support it" (the game ships D3D12 only).
- `-dx12 -warp` with the system WARP: LowLevelFatalError in PipelineStateCache.cpp:602 (PSO creation).
- `-dx12 -warp` with the current WARP (Microsoft.Direct3D.WARP 1.0.21 d3d10warp.dll next to the exe): the device comes
  up, but swap-chain creation fails (D3D12Viewport.cpp:572 E_INVALIDARG), also with an 8-bit back buffer and tearing
  off - the VM's remote display adapter rejects the swap chain.

Headless (`-nullrhi`) the game reaches the "press any key" splash and stops there: the splash reads real input, and
with no window there is none. Key / command UFUNCTIONs, the flow manager and fake login completions don't advance it.
Headless tests therefore show creator screens directly (WidgetBlueprintLibrary.Create + AddToViewport): the name
screen works that way; the customisation screen crashes outside the real creator flow.

## C++ mods against the UE4SS SDK: proven (2026-10-25)
UE4SS builds from source on this VM and a C++ mod built against it loads in the game.
- Source: `tools/bin/src/RE-UE4SS` (gitignored) at **8333063**, the same commit as the UE4SS v3.0.1 Beta DLL we ship
  (its log says "Git SHA #83330635"). A C++ mod must match the shipped UE4SS.dll, so keep the two on one commit.
- Needs the private UEPseudo submodule (the IkaronClaude account's Epic link + EpicGames org membership), VS 18 C++
  tools, Ninja and Rust (cargo, for patternsleuth).
- Build: `tools/bin/src/build.bat` = vcvars64 + `cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Game__Shipping__Win64` over
  a root CMakeLists that adds `RE-UE4SS` and the mod (`HelloMod`: a CppUserModBase with `start_mod` /
  `uninstall_mod` exports, `target_link_libraries(... UE4SS)`).
- A full build takes 2.2 GB in `build/` (measured). A disk-full stop mid-link leaves a corrupt
  UE4SS.pdb (LNK1318): delete it and re-run, and ninja resumes.
- Install: `ue4ss/Mods/<Name>/dlls/main.dll` + `enabled.txt`. Headless test: the log showed
  "[HelloMod] unreal init" 4 s after the mod started.
- This unblocks the native half of the creator redesign: UDataTable rows (AddRow failed from Lua with
  "ICppStructOps::Copy unavailable") and ProcessEvent / object-notification hooks without our own MinHook detours.

## Event-driven foundation (0.6.0, 2026-10-25)
The mod no longer polls. Both Lua loops (300 ms creator/menu, 2 s everything else) are gone; every reaction is to an
event.
- **Native event bus** (`native/WaCaNative/src/bridge.cpp`): WaCaNative is now a real UE4SS C++ mod (CppUserModBase,
  built against the SDK at the shipped commit). UE4SS's own ProcessEvent pre/post callbacks feed "watches"
  (function name + class + event name + pre/post). Matching on the function NAME is what reaches Blueprint events:
  a widget's Construct / Destruct is implemented per WBP class, so there is no single UFunction for RegisterHook.
- **Lua bridge only through UE4SS's exported API.** The raw Lua C API is static inside UE4SS.dll and NOT exported;
  LuaMadeSimple and `LuaType::auto_construct_object` are. Events run on a thread made with `Lua::new_thread()`
  (UE4SS's `process_lua_function` looks the calling lua_State up in its own map; a bare lua_newthread would break
  method calls on objects). Globals per mod: `WaCaNative_Watch / _Ready / _Command`; events call the mod's
  `WaCaNative_OnEvent`.
- **Threads:** `on_lua_start` fires BEFORE main.lua, which runs on UE4SS's loader thread while the game thread is
  live. So a mod's events are held until it calls `WaCa.Ready()` (last line of main.lua); then `Started` is delivered
  on the game thread and WaCa.lua replays ScreenShown for the screens already up. The game thread is found with a
  one-shot engine-tick callback; events from any other thread are dropped.
- **Built-in events** (WaCa.On): ScreenShown / ScreenHidden (SwtScreen Construct post / Destruct pre),
  ScreenFocusIn / ScreenFocusOut (OnAddedToFocusPath / OnRemovedFromFocusPath: the name box taking / losing the
  keyboard), CatSpawned (ReceiveBeginPlay on SwtAdventureCharacter / SwtAdventureQuestActor /
  WrcCatSkeletalMeshWithCustomization), SteamTextInput (native, from the Steam callback), Started.
- The fake string-table command channel ("WACA:" keys through an FTextKey detour) is gone: `WaCaNative_Command`.
- Headless proof (2026-10-25): the intro logos screen arrived via the Started replay; the name screen flow
  (Enter on the list -> FocusIn -> focus away -> "name done" -> Destruct -> "creator closed") ran entirely on events,
  in both Lua mods. NOT yet seen on a GPU: CatSpawned in real gameplay, the cursor staying right without the old
  per-tick re-assert, Steam keyboards.
- Gotchas: `project(UE4SS)` caches `UE4SS_SOURCE_DIR` (pointing at its UE4SS/ subfolder) - our own variable is
  `WACA_UE4SS_DIR`, or the second configure adds the wrong folder ("Unknown CMake command organize_targets"). The DLL
  now uses the dynamic CRT (/MD) like UE4SS.
- CI: the release workflow clones RE-UE4SS at 8333063 with submodules; needs the repository secret
  `UE4SS_SOURCE_TOKEN` (an Epic-linked account's token). Not set yet: a v0.6.0 tag would fail until it is.
