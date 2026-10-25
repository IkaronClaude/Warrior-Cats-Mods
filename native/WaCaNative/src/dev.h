#pragma once
#include <string>

// Reverse-engineering helpers (see dev.cpp): a hardware watchpoint that logs the code touching an address, and key
// presses posted to the game window.
namespace dev {
void Watch(const std::wstring& addrHex, const std::wstring& lenText);
void Unwatch();
void PressKey(const std::wstring& vkHex);
void Stack(const std::wstring& label);
}
