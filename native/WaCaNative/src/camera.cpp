// Mouse look on the game's own camera. The game turns its camera only from the right stick, through a stick
// pipeline: a dead zone, a response curve (|v|^e), a clamp to [-2, 2], then * turn speed * frame time. A mouse fed
// into that axis (the old [Axes] MouseX mapping) turns at most at stick speed and feels sticky. Here the mouse is
// read the standard UE way (APlayerController::GetInputMouseDelta - the MouseX / MouseY keys, rebindable) and goes
// into the game's own turn value already divided by turn speed * frame time - so the game turns the camera by exactly
// delta * sensitivity degrees: no dead zone, curve or clamp, and the stick still works the game's way on top.
//
// Traced 2026-10-25 (tickets.md, mouse look): the camera update (component, input source, dt) asks the turn function
// (component -> the sum of the camera / movement axes, shaped and clamped) and adds turn * component+0x1CC (turn
// speed) * dt to the camera actor's input rotator (+0x3A0). That rotator is only honoured while the camera sees input:
// written from outside (before or after the update) the view didn't move (VM: the arrow keys turned it 16.8 deg, a
// direct write turned nothing) - hence going through the turn value. The player's invert settings live on the input
// source (+0x8B3 set = yaw inverted); the idle check after the update recentres the camera unless component+0x220
// (the idle time) stays 0.
// Anchors (relocation framework): the update by the string "LookAtYaw" + prologue, confirmed by its body asking for
// the camera axes (mov byte ptr [rbp+67h], 3Eh twice); the turn function = the one function the update calls that asks
// for the camera-right axis (mov byte ptr [rsp+70h], 3Fh). Anything missing = mouse look off (logged); the stick
// still works.
#include "camera.h"

#include <windows.h>

#include <atomic>
#include <cmath>
#include <cstdint>
#include <vector>

#include <Unreal/FWeakObjectPtr.hpp>
#include <Unreal/UFunction.hpp>
#include <Unreal/UObject.hpp>
#include <Unreal/UObjectGlobals.hpp>

#include "MinHook.h"
#include "log.h"
#include "scan.h"

using namespace RC;
using namespace RC::Unreal;

namespace {

using UpdateFn = void(__fastcall*)(void* component, void* input, float dt);
using TurnFn = float(__fastcall*)(void* component, float deadZone);
UpdateFn g_update = nullptr;
TurnFn g_turn = nullptr;

std::atomic<bool> g_on{false};
std::atomic<float> g_yawScale{0.f};
std::atomic<float> g_pitchScale{0.f};

// layout of the 2026-10-25 build (see the file comment)
constexpr int kTurnSpeed = 0x1CC, kIdleTime = 0x220;
constexpr int kInvertYaw = 0x8B3;

// this frame's update, for the turn function it calls (both on the game thread)
void* g_frameInput = nullptr;
float g_frameDt = 0.f;

// weak: a level change destroys it; looked up again (once) when gone
FWeakObjectPtr g_pc;
UFunction* g_mouseDelta = nullptr;

// the first live instance of a class (FindFirstOf can return the class default object - VM 2026-10-25)
UObject* FirstLive(const CharType* className) {
    std::vector<UObject*> all;
    UObjectGlobals::FindAllOf(className, all);
    for (UObject* o : all)
        if (o && !o->HasAnyFlags(static_cast<EObjectFlags>(RF_ClassDefaultObject | RF_ArchetypeObject))) return o;
    return nullptr;
}

bool MouseDelta(float& dx, float& dy) {
    UObject* pc = g_pc.Get();
    if (!pc || !g_mouseDelta) {
        pc = FirstLive(STR("PlayerController"));
        g_pc = FWeakObjectPtr(pc);
        g_mouseDelta = pc ? pc->GetFunctionByNameInChain(STR("GetInputMouseDelta")) : nullptr;
        if (!g_mouseDelta) return false;
    }
    struct { float x, y; } params{};
    pc->ProcessEvent(g_mouseDelta, &params);
    dx = params.x;
    dy = params.y;
    return true;
}

void __fastcall UpdateDetour(void* component, void* input, float dt) {
    g_frameInput = input;
    g_frameDt = dt;
    g_update(component, input, dt);
    g_frameInput = nullptr;
}

// the game's turn (stick) + the mouse's yaw in turn units: the caller multiplies by turn speed * dt
float __fastcall TurnDetour(void* component, float deadZone) {
    float turn = g_turn(component, deadZone);
    if (!g_on || !component || !g_frameInput || g_frameDt <= 0.f) return turn;
    float dx = 0.f, dy = 0.f;
    if (!MouseDelta(dx, dy) || dx == 0.f) return turn;
    auto* comp = static_cast<uint8_t*>(component);
    float speed = *reinterpret_cast<float*>(comp + kTurnSpeed);
    if (!(std::fabs(speed) > 1e-4f)) return turn;
    auto* in = static_cast<uint8_t*>(g_frameInput);
    float degrees = dx * g_yawScale * (in[kInvertYaw] ? -1.f : 1.f);
    float mouse = degrees / (speed * g_frameDt);
    static bool reported = false;
    if (!reported) {
        reported = true;
        logx::Line(L"[camera] first mouse turn: delta %.3f -> %.2f deg (turn speed %.1f, dt %.4f): turn %.3f %+.3f", dx,
                   degrees, speed, g_frameDt, turn, mouse);
    }
    *reinterpret_cast<float*>(comp + kIdleTime) = 0.f;      // the player is looking around: no recentring
    return turn + mouse;
}

}  // namespace

namespace camera {

void Install() {
    auto* update = scan::FunctionUsing("LookAtYaw", "40 55 53 41 55 41 56");
    if (!update) {
        logx::Line(L"[camera] update: not found (anchor \"LookAtYaw\") - mouse look OFF");
        return;
    }
    if (!scan::BodyContains(update, "C6 45 67 3E", 2)) {
        logx::Line(L"[camera] update at %p: its body doesn't ask for the camera axes - anchors disagree, mouse look OFF", update);
        return;
    }
    auto* turn = scan::CalleeWhere(update, "C6 44 24 70 3F");
    if (!turn) {
        logx::Line(L"[camera] turn function: no single callee of the update asks for the camera-right axis - mouse look OFF");
        return;
    }
    bool ok = MH_CreateHook(update, reinterpret_cast<void*>(&UpdateDetour), reinterpret_cast<void**>(&g_update)) == MH_OK &&
              MH_CreateHook(turn, reinterpret_cast<void*>(&TurnDetour), reinterpret_cast<void**>(&g_turn)) == MH_OK &&
              MH_EnableHook(update) == MH_OK && MH_EnableHook(turn) == MH_OK;
    logx::Line(L"[camera] update at %p, turn at %p (confirmed: update asks for the camera axes, turn is its camera-right "
               L"callee)%s", update, turn, ok ? L"" : L" - could not hook");
}

void SetMouseLook(bool on, float yawScale, float pitchScale) {
    g_yawScale = yawScale;
    g_pitchScale = pitchScale;
    if (g_on.exchange(on) != on) logx::Line(L"[camera] mouse look %s (yaw %.3f, pitch %.3f per unit)", on ? L"on" : L"off", yawScale, pitchScale);
}

}  // namespace camera
