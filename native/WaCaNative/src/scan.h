// Byte-signature scanning over the game module's .text ("48 8B ?? E8 ?? ?? ?? ??").
#pragma once
#include <windows.h>
#include <algorithm>
#include <cstdint>
#include <cstring>
#include <optional>
#include <string>
#include <vector>

namespace scan {

struct Pattern {
    std::vector<uint8_t> Bytes;
    std::vector<bool> Mask;   // true = must match
};

inline Pattern Parse(const char* text) {
    Pattern p;
    for (const char* c = text; *c;) {
        if (*c == ' ') { ++c; continue; }
        if (c[0] == '?') {
            p.Bytes.push_back(0);
            p.Mask.push_back(false);
            c += (c[1] == '?') ? 2 : 1;
        } else {
            p.Bytes.push_back(static_cast<uint8_t>(strtoul(std::string(c, 2).c_str(), nullptr, 16)));
            p.Mask.push_back(true);
            c += 2;
        }
    }
    return p;
}

// the first match inside the main module's executable section, or nullopt
inline std::optional<uint8_t*> Find(const char* text) {
    auto p = Parse(text);
    auto* base = reinterpret_cast<uint8_t*>(GetModuleHandleW(nullptr));
    auto* dos = reinterpret_cast<IMAGE_DOS_HEADER*>(base);
    auto* nt = reinterpret_cast<IMAGE_NT_HEADERS*>(base + dos->e_lfanew);
    auto* sec = IMAGE_FIRST_SECTION(nt);
    for (unsigned i = 0; i < nt->FileHeader.NumberOfSections; ++i, ++sec) {
        if (!(sec->Characteristics & IMAGE_SCN_MEM_EXECUTE)) continue;
        uint8_t* start = base + sec->VirtualAddress;
        size_t size = sec->Misc.VirtualSize;
        for (size_t off = 0; off + p.Bytes.size() <= size; ++off) {
            bool ok = true;
            for (size_t k = 0; k < p.Bytes.size(); ++k) {
                if (p.Mask[k] && start[off + k] != p.Bytes[k]) { ok = false; break; }
            }
            if (ok) return start + off;
        }
    }
    return std::nullopt;
}

// the target of an E8 / E9 rel32 at `at`
inline uint8_t* RelTarget(uint8_t* at) {
    return at + 5 + *reinterpret_cast<int32_t*>(at + 1);
}

// --- Anchoring a function on a string it uses (survives game updates better than raw bytes): the string, the code
// that references it, the function around that code (from the exe's own unwind table), checked by its prologue. ---

struct Section { uint8_t* start; size_t size; };

inline std::vector<Section> Sections(bool executable) {
    std::vector<Section> out;
    auto* base = reinterpret_cast<uint8_t*>(GetModuleHandleW(nullptr));
    auto* nt = reinterpret_cast<IMAGE_NT_HEADERS*>(base + reinterpret_cast<IMAGE_DOS_HEADER*>(base)->e_lfanew);
    auto* sec = IMAGE_FIRST_SECTION(nt);
    for (unsigned i = 0; i < nt->FileHeader.NumberOfSections; ++i, ++sec) {
        bool exec = (sec->Characteristics & IMAGE_SCN_MEM_EXECUTE) != 0;
        if (exec == executable) out.push_back({base + sec->VirtualAddress, sec->Misc.VirtualSize});
    }
    return out;
}

// every address of an exact ASCII string (its terminating NUL included) in the module's data
inline std::vector<uint8_t*> FindAscii(const char* text) {
    std::vector<uint8_t*> out;
    size_t n = strlen(text) + 1;
    for (const auto& s : Sections(false)) {
        for (size_t off = 0; off + n <= s.size; ++off) {
            if (s.start[off] == static_cast<uint8_t>(text[0]) && memcmp(s.start + off, text, n) == 0 &&
                (off == 0 || s.start[off - 1] == 0)) {
                out.push_back(s.start + off);
            }
        }
    }
    return out;
}

// the start of the function containing `code` (its primary unwind entry, chained entries followed), or null
inline uint8_t* FunctionStart(uint8_t* code) {
    DWORD64 imageBase = 0;
    auto* fn = RtlLookupFunctionEntry(reinterpret_cast<DWORD64>(code), &imageBase, nullptr);
    for (int guard = 0; fn && guard < 16; ++guard) {
        auto* info = reinterpret_cast<uint8_t*>(imageBase + fn->UnwindInfoAddress);
        if (!(info[0] >> 3 & 0x4)) return reinterpret_cast<uint8_t*>(imageBase + fn->BeginAddress);   // not chained
        uint8_t codes = info[2];
        auto* chained = reinterpret_cast<RUNTIME_FUNCTION*>(info + 4 + ((codes + 1) & ~1) * 2);
        fn = chained;
    }
    return nullptr;
}

// the functions that reference `target` RIP-relatively (lea / mov ..., [rip + disp32])
inline std::vector<uint8_t*> FunctionsReferencing(uint8_t* target) {
    std::vector<uint8_t*> out;
    for (const auto& s : Sections(true)) {
        for (size_t off = 0; off + 4 <= s.size; ++off) {
            uint8_t* p = s.start + off;
            if (p + 4 + *reinterpret_cast<int32_t*>(p) != target) continue;
            uint8_t* fn = FunctionStart(p);
            if (fn && std::find(out.begin(), out.end(), fn) == out.end()) out.push_back(fn);
        }
    }
    return out;
}

// the one function that uses the ASCII string `text` and starts with `prologue` (pattern syntax), or null
inline uint8_t* FunctionUsing(const char* text, const char* prologue) {
    auto p = Parse(prologue);
    uint8_t* found = nullptr;
    for (uint8_t* str : FindAscii(text)) {
        for (uint8_t* fn : FunctionsReferencing(str)) {
            bool ok = true;
            for (size_t k = 0; k < p.Bytes.size() && ok; ++k) ok = !p.Mask[k] || fn[k] == p.Bytes[k];
            if (!ok) continue;
            if (found && found != fn) return nullptr;      // ambiguous: refuse rather than hook the wrong one
            found = fn;
        }
    }
    return found;
}

}  // namespace scan
