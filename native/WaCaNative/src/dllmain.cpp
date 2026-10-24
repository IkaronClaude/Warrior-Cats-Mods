// WaCaNative: the native half of WaCa ModKit, loaded by UE4SS as a C++ mod (Mods/WaCaModKit/dlls/main.dll).
// It needs no UE4SS SDK: UE4SS LoadLibrary's the DLL, calls start_mod and keeps the DLL loaded; a null mod object is
// allowed (every later UE4SS call is guarded). The work happens at load: signature scans + MinHook detours.
#include <windows.h>

#include <string>

#include "MinHook.h"
#include "input.h"
#include "text.h"
#include "log.h"

namespace {

// <...>\Mods\WaCaModKit (the DLL sits in its dlls\ folder)
std::wstring ModDir() {
    HMODULE self = nullptr;
    GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                       reinterpret_cast<LPCWSTR>(&ModDir), &self);
    wchar_t path[MAX_PATH];
    GetModuleFileNameW(self, path, MAX_PATH);
    std::wstring p(path);
    p = p.substr(0, p.find_last_of(L"\\/"));          // ...\dlls
    return p.substr(0, p.find_last_of(L"\\/"));       // ...\WaCaModKit
}

bool g_started = false;

void Start() {
    if (g_started) return;
    g_started = true;
    auto dir = ModDir();
    logx::Open(dir + L"\\WaCaNative.log");
    logx::Line(L"WaCaNative loaded from %s", dir.c_str());
    if (MH_Initialize() != MH_OK) {
        logx::Line(L"MinHook failed to initialise");
        return;
    }
    input::Install(dir);
    text::Install(input::FNameCtor());
}

}  // namespace

extern "C" __declspec(dllexport) void* start_mod() {
    Start();
    return nullptr;
}

extern "C" __declspec(dllexport) void uninstall_mod(void*) {}

BOOL APIENTRY DllMain(HMODULE, DWORD, LPVOID) { return TRUE; }
