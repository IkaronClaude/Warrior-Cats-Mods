#pragma once

namespace text {
// String-table text overrides + the Lua command channel. fnameCtor = FName::FName(const TCHAR*, EFindName).
bool Install(void* fnameCtor);
}
