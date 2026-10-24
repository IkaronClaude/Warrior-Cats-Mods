// Byte-signature scanning over the game module's .text ("48 8B ?? E8 ?? ?? ?? ??").
#pragma once
#include <windows.h>
#include <cstdint>
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

}  // namespace scan
