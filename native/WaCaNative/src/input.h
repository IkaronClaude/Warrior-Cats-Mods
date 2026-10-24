#pragma once
#include <string>

namespace input {
// Hooks the game's default-binding apply step; keybinds.ini lives in <modDir>\config. False when the game changed.
bool Install(const std::wstring& modDir);
}
