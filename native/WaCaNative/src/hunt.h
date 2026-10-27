#pragma once
#include <string>

// A hunt's instakill succeeds only by chance (see hunt.cpp)
namespace hunt {
// hook the prey component's landing from a live USwtAdventurePreyComponent (its vtable); once
bool HookFrom(void* preyComponent);
// HuntRoll|<0/1>|<base chance %>|<critical miss %>|<CharacterType value>=<factor>,...
void Configure(const std::wstring& command);
// add EXP to a level component (USwtQuestLevelComponent, the player state's) the way the game does - its resource
// "add value" virtual (level-ups included); false when the anchors disagree
bool AddExperience(void* levelComponent, float amount);
// the EXP a fight against an enemy kind gives (the game's combat base experience table, as the tuning manager loaded
// it), or -1
int CombatExperience(void* tuningManager, const std::wstring& kind);
}
