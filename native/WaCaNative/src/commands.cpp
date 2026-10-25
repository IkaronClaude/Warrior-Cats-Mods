// The commands Lua sends with WaCaNative.Command (registered by bridge.cpp in every Lua mod's state):
//   SetText|<key>|<text>
//   SetUIKey|<DataTable address hex>|<row>|<key>[|<icon texture object path>]   (ui.cpp)
//   SteamKeyboard|<description>|<existing text>      the answer arrives as the SteamTextInput event (steam.cpp)
//   DevWatch|<address hex>|<length>  DevWatchRow|<table hex>|<row>|<offset hex>|<length>  DevUnwatch
//   PressKey|<Unreal key name>                      a real key press + release posted to the game window (KeyAliases)
//   DevPressKey|<vk hex>  DevStack|<label>                                        (dev.cpp)
#include "commands.h"

#include "dev.h"
#include "log.h"
#include "steam.h"
#include "text.h"
#include "ui.h"

namespace {

std::wstring Arg(const std::wstring& s, size_t i) {
    size_t start = 0;
    for (size_t k = 0; k < i; ++k) {
        start = s.find(L'|', start);
        if (start == std::wstring::npos) return L"";
        ++start;
    }
    size_t end = s.find(L'|', start);
    return s.substr(start, end == std::wstring::npos ? std::wstring::npos : end - start);
}

}  // namespace

namespace commands {

bool Run(const std::wstring& cmd) {
    auto verb = Arg(cmd, 0);
    if (verb == L"SetText") text::SetText(Arg(cmd, 1), Arg(cmd, 2));
    else if (verb == L"SetUIKey") ui::SetUIKey(Arg(cmd, 1), Arg(cmd, 2), Arg(cmd, 3), Arg(cmd, 4));
    else if (verb == L"DevWatch") dev::Watch(Arg(cmd, 1), Arg(cmd, 2));
    else if (verb == L"DevWatchRow") dev::Watch(ui::RowAddressHex(Arg(cmd, 1), Arg(cmd, 2), Arg(cmd, 3)), Arg(cmd, 4));
    else if (verb == L"DevUnwatch") dev::Unwatch();
    else if (verb == L"DevPressKey") dev::PressKey(Arg(cmd, 1));
    else if (verb == L"PressKey") dev::PressKeyNamed(Arg(cmd, 1));
    else if (verb == L"DevStack") dev::Stack(Arg(cmd, 1));
    else if (verb == L"SteamKeyboard") steam::ShowKeyboard(Arg(cmd, 1), Arg(cmd, 2));
    else {
        logx::Line(L"[commands] unknown command %s", cmd.c_str());
        return false;
    }
    return true;
}

}  // namespace commands
