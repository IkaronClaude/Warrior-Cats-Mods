// The event bus: game events reach the Lua mods as calls, never as something Lua has to poll for.
//
// Source of events: UE4SS's ProcessEvent pre / post callbacks (its own hook - no detour of ours). Every UFunction that
// runs through ProcessEvent can become an event, including Blueprint events that Lua's RegisterHook can't reach: a
// widget blueprint's Construct / Destruct (the moment a screen enters / leaves the viewport) is a BlueprintImplementable
// event whose implementation lives in each WBP_*_C class, so there is no one function to hook - but every call
// passes ProcessEvent with the function's NAME. A watch is (function name, class, event name, pre/post): when a
// function of that name runs on an object of that class, the event fires with the object.
// Native code adds its own events (Emit): the Steam keyboard's answer, for one.
//
// Lua side, registered as globals in EVERY Lua mod's state (WaCa.lua wraps them as WaCa.On / WaCa.Watch):
//   WaCaNative_Watch(functionName, classPath, eventName, "pre" | "post")
//   WaCaNative_Ready()            the mod's main.lua finished - events may be delivered from now on; the first thing
//                                 delivered is "Started" (on the game thread), so the mod can catch up on what is
//                                 already there (WaCa.lua replays ScreenShown for the screens already up)
//   WaCaNative_Command(text)      a native command (commands.cpp) -> true / false
// and each event calls the mod's global WaCaNative_OnEvent(eventName, object or nil, string args...).
//
// Threads: events are delivered on the GAME THREAD only, on a Lua thread of the mod's own state that UE4SS knows
// (so calls on the objects work). A mod's main.lua runs on UE4SS's loader thread while the game thread is already
// running, so nothing is delivered before the mod says it is ready. Mods using the event bus must not run Lua off
// the game thread (LoopAsync / ExecuteAsync use another OS thread on the same state: that is what corrupted the VM in
// 0.5.3).
#include "bridge.h"

#include <Mod/LuaMod.hpp>
#include <LuaMadeSimple/LuaMadeSimple.hpp>
#include <LuaType/LuaUObject.hpp>
#include <Unreal/FWeakObjectPtr.hpp>
#include <Unreal/Hooks/Hooks.hpp>
#include <Unreal/NameTypes.hpp>
#include <Unreal/UClass.hpp>
#include <Unreal/UFunction.hpp>
#include <Unreal/UObject.hpp>
#include <Unreal/UObjectGlobals.hpp>

#include <atomic>
#include <memory>
#include <thread>
#include <vector>

#include <windows.h>

#include "appearance.h"
#include "commands.h"
#include "log.h"

using namespace RC;
using namespace RC::Unreal;

namespace {

struct ModState {
    std::wstring name;
    LuaMod* mod = nullptr;                    // identifies the mod from any of its Lua threads (get_mod_ref)
    LuaMadeSimple::Lua* thread = nullptr;     // events run here; created by LuaMadeSimple, so UE4SS knows it
    bool ready = false;
    bool started = false;                     // "Started" delivered
};

struct Watch {
    FName function;
    std::wstring classPath;
    UClass* cls = nullptr;                    // resolved on first use (a class may load after the watch is made)
    bool post = true;
    std::string event;
    ModState* state = nullptr;
};

std::vector<std::unique_ptr<ModState>> g_states;
std::vector<Watch> g_watches;
std::atomic<bool> g_haveGameThread{false};
std::atomic<bool> g_startPending{false};      // a mod became ready: deliver its "Started" on the game thread
std::thread::id g_gameThread{};
int g_depth = 0;                              // nested events (a handler whose calls fire more events)
constexpr int kMaxDepth = 8;

std::wstring Wide(std::string_view s) {
    if (s.empty()) return {};
    int n = MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), nullptr, 0);
    std::wstring out(n, L'\0');
    MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), out.data(), n);
    return out;
}

std::wstring Wide(const char* s) { return Wide(std::string_view(s ? s : "")); }

bool OnGameThread() {
    return g_haveGameThread.load(std::memory_order_acquire) && std::this_thread::get_id() == g_gameThread;
}

ModState* StateOf(const LuaMadeSimple::Lua& lua) {
    LuaMod* mod = get_mod_ref(lua);
    for (auto& s : g_states)
        if (s->mod == mod) return s.get();
    return nullptr;
}

void Deliver(ModState& s, const std::string& event, UObject* object, std::initializer_list<std::string> args) {
    if (!s.ready || !s.thread) return;
    const LuaMadeSimple::Lua& lua = *s.thread;
    if (!lua.is_global_function("WaCaNative_OnEvent")) return;
    if (g_depth >= kMaxDepth) {
        logx::Line(L"[bridge] %s: event %s dropped (nested %d deep)", s.name.c_str(), Wide(event).c_str(), g_depth);
        return;
    }
    ++g_depth;
    try {
        lua.prepare_function_call("WaCaNative_OnEvent");
        lua.set_string(event);
        if (object) LuaType::auto_construct_object(lua, object);
        else lua.set_nil();
        for (const auto& a : args) lua.set_string(a);
        lua.call_function(2 + static_cast<int32_t>(args.size()), 0);
    } catch (const std::exception& e) {
        // the traceback is already in UE4SS.log (LuaMadeSimple's error handler)
        logx::Line(L"[bridge] %s: event %s failed: %s", s.name.c_str(), Wide(event).c_str(), Wide(e.what()).c_str());
    }
    --g_depth;
}

void DeliverStarted() {
    g_startPending.store(false, std::memory_order_relaxed);
    for (size_t i = 0; i < g_states.size(); ++i) {
        ModState& s = *g_states[i];
        if (!s.ready || s.started) continue;
        s.started = true;
        Deliver(s, "Started", nullptr, {});
    }
}

void OnProcessEvent(bool post, UObject* context, UFunction* function) {
    if (!OnGameThread()) return;
    if (g_startPending.load(std::memory_order_relaxed)) DeliverStarted();
    if (g_watches.empty() || !context || !function) return;
    const FName name = function->GetNamePrivate();
    // by index: a handler may add watches (the vector grows)
    for (size_t i = 0; i < g_watches.size(); ++i) {
        if (g_watches[i].post != post || !(g_watches[i].function == name)) continue;
        if (!g_watches[i].cls) {
            g_watches[i].cls = UObjectGlobals::StaticFindObject<UClass*>(nullptr, nullptr, g_watches[i].classPath.c_str());
            if (!g_watches[i].cls) continue;
        }
        if (!context->IsA(g_watches[i].cls)) continue;
        ModState* state = g_watches[i].state;
        std::string event = g_watches[i].event;
        Deliver(*state, event, context, {});
    }
}

// --- Lua functions (the calling Lua state is the argument; arguments are consumed from index 1) ---

int LuaWatch(const LuaMadeSimple::Lua& lua) {
    ModState* state = StateOf(lua);
    if (!state) return 0;
    if (!lua.is_string()) lua.throw_error("WaCaNative_Watch(functionName, classPath, eventName, \"pre\" | \"post\")");
    std::wstring function = Wide(std::string(lua.get_string()));
    std::wstring classPath = Wide(std::string(lua.get_string()));
    std::string event(lua.get_string());
    bool post = true;
    if (lua.is_string()) post = lua.get_string() != "pre";
    Watch w;
    w.function = FName(function.c_str(), FNAME_Add);
    w.classPath = classPath;
    w.post = post;
    w.event = event;
    w.state = state;
    g_watches.push_back(std::move(w));
    logx::Line(L"[bridge] %s: %s on %s (%s) -> %s", state->name.c_str(), function.c_str(), classPath.c_str(),
               post ? L"post" : L"pre", Wide(event).c_str());
    return 0;
}

int LuaReady(const LuaMadeSimple::Lua& lua) {
    if (ModState* state = StateOf(lua)) {
        state->ready = true;
        g_startPending.store(true, std::memory_order_release);
        logx::Line(L"[bridge] %s: ready for events", state->name.c_str());
    }
    return 0;
}

// dev: the bindings of a multicast delegate - WaCaNative_DevDelegate(object address, property offset) -> text
// "Object.Function; ..." (a TArray of FScriptDelegate = FWeakObjectPtr + FName, 16 bytes each on this build)
int LuaDevDelegate(const LuaMadeSimple::Lua& lua) {
    auto object = static_cast<uintptr_t>(lua.get_integer());
    auto offset = static_cast<uintptr_t>(lua.get_integer());
    struct Binding {
        FWeakObjectPtr Object;
        uint32_t NameIndex;
        uint32_t NameNumber;
    };
    struct Array {
        Binding* Data;
        int32_t Num;
        int32_t Max;
    };
    std::wstring out;
    auto* arr = reinterpret_cast<Array*>(object + offset);
    if (arr->Num < 0 || arr->Num > 64) {
        out = L"(not a delegate array)";
    } else if (arr->Num == 0) {
        out = L"(nothing bound)";
    }
    for (int32_t i = 0; arr->Num > 0 && arr->Num <= 64 && i < arr->Num; ++i) {
        UObject* bound = arr->Data[i].Object.Get();
        FName fn(arr->Data[i].NameIndex, arr->Data[i].NameNumber);
        if (!out.empty()) out += L"; ";
        out += bound ? bound->GetFullName() : std::wstring(L"(gone)");
        out += L" :: ";
        out += fn.ToString();
    }
    int n = WideCharToMultiByte(CP_UTF8, 0, out.c_str(), -1, nullptr, 0, nullptr, nullptr);
    std::string utf8(n > 0 ? n - 1 : 0, '\0');
    if (n > 1) WideCharToMultiByte(CP_UTF8, 0, out.c_str(), -1, utf8.data(), n, nullptr, nullptr);
    lua.set_string(utf8);
    return 1;
}

// WaCaNative_RebuildLook(cat look component's address) -> true / false: the game builds that cat's whole look again
// from its own data (appearance.cpp) - with the look hook, any WaCa look goes in with it
int LuaRebuildLook(const LuaMadeSimple::Lua& lua) {
    auto* comp = reinterpret_cast<UObject*>(static_cast<uintptr_t>(lua.get_integer()));
    void* data = comp ? comp->GetValuePtrByPropertyName(STR("CustomData")) : nullptr;
    lua.set_bool(data && appearance::Rebuild(comp, data));
    return 1;
}

int LuaCommand(const LuaMadeSimple::Lua& lua) {
    if (!lua.is_string()) lua.throw_error("WaCaNative_Command(text)");
    bool ok = commands::Run(Wide(std::string(lua.get_string())));
    lua.set_bool(ok);
    return 1;
}

}  // namespace

namespace bridge {

void Install() {
    Hook::FCallbackOptions once{true, true, STR("WaCaModKit"), STR("GameThread")};
    auto id = Hook::RegisterEngineTickPreCallback(
        [](auto&, UEngine*, float, bool) {
            g_gameThread = std::this_thread::get_id();
            g_haveGameThread.store(true, std::memory_order_release);
            logx::Line(L"[bridge] game thread found (engine tick)");
        },
        once);
    if (id == Hook::ERROR_ID) logx::Line(L"[bridge] no engine tick hook - events are OFF");
    Hook::RegisterProcessEventPreCallback([](auto&, UObject* c, UFunction* f, void*) { OnProcessEvent(false, c, f); },
                                          {false, true, STR("WaCaModKit"), STR("EventsPre")});
    Hook::RegisterProcessEventPostCallback([](auto&, UObject* c, UFunction* f, void*) { OnProcessEvent(true, c, f); },
                                           {false, true, STR("WaCaModKit"), STR("EventsPost")});
    logx::Line(L"[bridge] ProcessEvent callbacks installed");
}

void LuaStarted(const std::wstring& modName, LuaMadeSimple::Lua& lua) {
    auto state = std::make_unique<ModState>();
    state->name = modName;
    state->mod = get_mod_ref(lua);
    state->thread = &lua.new_thread();
    lua.registry().make_ref();                // anchors the thread (new_thread left it on the stack)
    lua.register_function("WaCaNative_Watch", &LuaWatch);
    lua.register_function("WaCaNative_Ready", &LuaReady);
    lua.register_function("WaCaNative_Command", &LuaCommand);
    lua.register_function("WaCaNative_DevDelegate", &LuaDevDelegate);
    lua.register_function("WaCaNative_RebuildLook", &LuaRebuildLook);
    g_states.push_back(std::move(state));
}

void LuaStopping(LuaMadeSimple::Lua& lua) {
    LuaMod* mod = get_mod_ref(lua);
    for (auto it = g_states.begin(); it != g_states.end(); ++it) {
        if ((*it)->mod != mod) continue;
        ModState* s = it->get();
        std::erase_if(g_watches, [s](const Watch& w) { return w.state == s; });
        logx::Line(L"[bridge] %s stopped", s->name.c_str());
        g_states.erase(it);
        return;
    }
}

void EmitLook(void* component, void* part, const char* what) {
    if (!OnGameThread() || g_states.empty()) return;
    auto* comp = static_cast<UObject*>(component);
    std::wstring partName = static_cast<UObject*>(part)->GetFullName();
    int n = WideCharToMultiByte(CP_UTF8, 0, partName.c_str(), -1, nullptr, 0, nullptr, nullptr);
    std::string utf8(n > 0 ? n - 1 : 0, '\0');
    if (n > 1) WideCharToMultiByte(CP_UTF8, 0, partName.c_str(), -1, utf8.data(), n, nullptr, nullptr);
    for (size_t i = 0; i < g_states.size(); ++i) Deliver(*g_states[i], "CatLookPart", comp, {what, utf8});
}

void Emit(const char* event, std::initializer_list<std::string> args) {
    if (!OnGameThread()) {
        logx::Line(L"[bridge] event %s raised off the game thread - dropped", Wide(event).c_str());
        return;
    }
    for (size_t i = 0; i < g_states.size(); ++i) Deliver(*g_states[i], event, nullptr, args);
}

}  // namespace bridge
