// A plain log file next to the DLL's mod folder (WaCaNative.log), flushed per line.
#pragma once
#include <cstdarg>
#include <cstdio>
#include <mutex>
#include <string>

namespace logx {

inline std::mutex& Lock() { static std::mutex m; return m; }
inline FILE*& File() { static FILE* f = nullptr; return f; }

inline void Open(const std::wstring& path) {
    std::lock_guard g(Lock());
    _wfopen_s(&File(), path.c_str(), L"w, ccs=UTF-8");
}

inline void Line(const wchar_t* fmt, ...) {
    std::lock_guard g(Lock());
    if (!File()) return;
    va_list ap;
    va_start(ap, fmt);
    vfwprintf(File(), fmt, ap);
    va_end(ap);
    fputwc(L'\n', File());
    fflush(File());
}

}  // namespace logx
