// Hunting by chance (tickets.md 9, operator 2026-10-27): the game's prey instakill always works; with HuntRoll on, the
// moment the cat LANDS on the prey is rolled - chance = the cat's base chance (by rank, set from Lua) x the prey's
// factor (by its CharacterType, e.g. rabbit 0.5), never above 100% - critical miss. Only the CharacterTypes Lua lists
// are rolled: NPC cats carry the same component for the game's sneak attack, which stays as it is. A miss skips the landing (no
// hunted sequence - the prey carries on as the game makes it); a hit runs it. Both are Lua events: HuntCaught /
// HuntMissed (prey full name, cat full name, CharacterType value, chance %).
// The landing: USwtAdventurePreyComponent's UFunction OnHunterLanded(Hit, Character) is native; its exec thunk calls
// the component's VIRTUAL vtable +0xAA0 (rcx = component, rdx = &Hit, r8 = the cat) - hooked from a live component's
// vtable. Anchor: the thunk (from the UFunction by name) calls exactly that slot (call qword ptr [rax+0AA0h]);
// tools/check_hooks.py checks the same offline.
// EXP for a catch (operator 2026-10-27, what the fight would have given): the level component's resource "add value"
// is its VIRTUAL vtable +0x508 (rcx = component, xmm1 = amount): it scales the amount by the EXP multiplier
// (+0x114) and checks the current value (+0x10C) against the next level. Anchors: that function's body reads both
// fields exactly once (movss xmm1, [rbx+10Ch] / mulss xmm6, [rbx+114h]).
#include "hunt.h"

#include <windows.h>

#include <atomic>
#include <cstdint>
#include <map>
#include <mutex>
#include <random>
#include <string>

#include <Unreal/UFunction.hpp>
#include <Unreal/UObject.hpp>
#include <Unreal/UObjectGlobals.hpp>

#include "MinHook.h"
#include "bridge.h"
#include "log.h"
#include "scan.h"

using namespace RC;
using namespace RC::Unreal;

namespace {

using LandedFn = void(__fastcall*)(void* component, void* hit, void* character);
LandedFn g_landed = nullptr;
bool g_tried = false;
constexpr int kLandedSlot = 0xAA0;

std::atomic<bool> g_on{false};
std::mutex g_mutex;
double g_base = 1.0;                       // the cat's chance before the prey's factor (1.0 = 100%)
double g_critMiss = 0.05;
std::map<int, double> g_factors;           // CharacterType value -> factor (only these kinds are rolled)

std::string Narrow(const std::wstring& w) {
    int n = WideCharToMultiByte(CP_UTF8, 0, w.c_str(), -1, nullptr, 0, nullptr, nullptr);
    std::string s(n > 0 ? n - 1 : 0, '\0');
    if (n > 1) WideCharToMultiByte(CP_UTF8, 0, w.c_str(), -1, s.data(), n, nullptr, nullptr);
    return s;
}

std::wstring Field(const std::wstring& s, int index, wchar_t sep) {
    size_t start = 0;
    for (int i = 0; i < index; ++i) {
        start = s.find(sep, start);
        if (start == std::wstring::npos) return L"";
        ++start;
    }
    size_t end = s.find(sep, start);
    return s.substr(start, end == std::wstring::npos ? std::wstring::npos : end - start);
}

double Roll() {
    static std::mt19937 rng{std::random_device{}()};
    return std::uniform_real_distribution<double>(0.0, 1.0)(rng);
}

void __fastcall LandedDetour(void* componentPtr, void* hit, void* characterPtr) {
    auto* component = static_cast<UObject*>(componentPtr);
    auto* cat = static_cast<UObject*>(characterPtr);
    // a component's outer is its actor (the prey)
    UObject* prey = component ? component->GetOuterPrivate() : nullptr;
    if (!g_on || !prey || !cat) {
        g_landed(componentPtr, hit, characterPtr);
        return;
    }
    auto* type = prey->GetValuePtrByPropertyNameInChain<uint8_t>(STR("CharacterType"));
    int typeValue = type ? *type : -1;
    double chance;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        auto it = g_factors.find(typeValue);
        if (it == g_factors.end()) {
            g_landed(componentPtr, hit, characterPtr);
            return;
        }
        chance = g_base * it->second;
        if (chance > 1.0 - g_critMiss) chance = 1.0 - g_critMiss;
    }
    double r = Roll();
    bool caught = r < chance;
    logx::Line(L"[hunt] landed on %s (type %d): chance %.0f%%, rolled %.0f -> %s", prey->GetName().c_str(), typeValue,
               chance * 100.0, r * 100.0, caught ? L"CAUGHT" : L"missed");
    char pct[16];
    snprintf(pct, sizeof(pct), "%.0f", chance * 100.0);
    bridge::Emit(caught ? "HuntCaught" : "HuntMissed",
                 {Narrow(prey->GetFullName()), Narrow(cat->GetFullName()), std::to_string(typeValue), pct});
    if (caught) g_landed(componentPtr, hit, characterPtr);
}

using AddValueFn = void(__fastcall*)(void* component, float amount);
constexpr int kAddValueSlot = 0x508;

}  // namespace

namespace hunt {

bool AddExperience(void* levelComponent, float amount) {
    if (!levelComponent) return false;
    auto* fn = (*reinterpret_cast<uint8_t***>(levelComponent))[kAddValueSlot / 8];
    static uint8_t* checked = nullptr;
    if (fn != checked) {
        if (!scan::BodyContains(fn, "F3 0F 10 8B 0C 01 00 00", 1) || !scan::BodyContains(fn, "F3 0F 59 B3 14 01 00 00", 1)) {
            logx::Line(L"[hunt] the level component's slot +0x%X (%p) isn't its add-value - anchors disagree, no EXP", kAddValueSlot, fn);
            return false;
        }
        checked = fn;
    }
    reinterpret_cast<AddValueFn>(fn)(levelComponent, amount);
    logx::Line(L"[hunt] +%.0f EXP", amount);
    return true;
}

bool HookFrom(void* preyComponent) {
    if (g_tried || !preyComponent) return g_landed != nullptr;
    g_tried = true;
    auto* fn = UObjectGlobals::StaticFindObject<UFunction*>(nullptr, nullptr,
                                                            STR("/Script/SwtAdventure.SwtAdventurePreyComponent:OnHunterLanded"));
    auto* thunk = fn ? reinterpret_cast<uint8_t*>(fn->GetFunc()) : nullptr;
    if (!thunk || !scan::BodyContains(thunk, "FF 90 A0 0A 00 00", 1)) {
        logx::Line(L"[hunt] OnHunterLanded's thunk %p doesn't call the landing slot - anchors disagree, hunting by chance OFF", thunk);
        return false;
    }
    auto* target = (*reinterpret_cast<uint8_t***>(preyComponent))[kLandedSlot / 8];
    bool ok = MH_CreateHook(target, reinterpret_cast<void*>(&LandedDetour), reinterpret_cast<void**>(&g_landed)) == MH_OK &&
              MH_EnableHook(target) == MH_OK;
    logx::Line(L"[hunt] prey landing at %p (confirmed: OnHunterLanded's thunk calls its slot)%s", target,
               ok ? L"" : L" - could not hook");
    if (!ok) g_landed = nullptr;
    return ok;
}

void Configure(const std::wstring& command) {
    bool on = Field(command, 1, L'|') == L"1";
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        g_base = _wtof(Field(command, 2, L'|').c_str()) / 100.0;
        g_critMiss = _wtof(Field(command, 3, L'|').c_str()) / 100.0;
        g_factors.clear();
        std::wstring list = Field(command, 4, L'|');
        for (int i = 0;; ++i) {
            std::wstring pair = Field(list, i, L',');
            if (pair.empty()) break;
            size_t eq = pair.find(L'=');
            if (eq != std::wstring::npos) g_factors[_wtoi(pair.substr(0, eq).c_str())] = _wtof(pair.substr(eq + 1).c_str());
        }
    }
    g_on = on;
    logx::Line(L"[hunt] hunting by chance %s: base %.0f%%, critical miss %.0f%%, %zu prey factors", on ? L"on" : L"off",
               g_base * 100.0, g_critMiss * 100.0, g_factors.size());
}

}  // namespace hunt
