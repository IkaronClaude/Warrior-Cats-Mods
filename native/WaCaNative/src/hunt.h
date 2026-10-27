#pragma once
#include <string>

// A hunt's instakill succeeds only by chance (see hunt.cpp)
namespace hunt {
// hook the prey component's landing from a live USwtAdventurePreyComponent (its vtable); once
bool HookFrom(void* preyComponent);
// HuntRoll|<0/1>|<base chance %>|<critical miss %>|<CharacterType value>=<factor>,...
void Configure(const std::wstring& command);
}
