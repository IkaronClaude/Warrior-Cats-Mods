"""Send input to the running game on the VM (offscreen test runs: -dx12 -warp -wacaoffscreen).

  vm_input.py key <vk hex> [count]       a key press + release posted to the game window (e.g. 0D = Enter)
  vm_input.py click <x> <y>              a left click at client coordinates
  vm_input.py move <x> <y>               a mouse move to client coordinates

Posts window messages to the game's top-level window (found by the game's process name), so it needs no focus and no
interactive desktop."""
import ctypes
import ctypes.wintypes as wt
import sys
import time

user32 = ctypes.WinDLL("user32", use_last_error=True)
kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)

GAME_EXE = "wrc-win64-shipping-nostub.exe"
WM_KEYDOWN, WM_KEYUP = 0x0100, 0x0101
WM_MOUSEMOVE, WM_LBUTTONDOWN, WM_LBUTTONUP = 0x0200, 0x0201, 0x0202
MK_LBUTTON = 0x0001


def process_name(pid):
    h = kernel32.OpenProcess(0x1000, False, pid)        # PROCESS_QUERY_LIMITED_INFORMATION
    if not h:
        return ""
    buf = ctypes.create_unicode_buffer(1024)
    size = wt.DWORD(len(buf))
    ok = kernel32.QueryFullProcessImageNameW(h, 0, buf, ctypes.byref(size))
    kernel32.CloseHandle(h)
    return buf.value.rsplit("\\", 1)[-1].lower() if ok else ""


def game_window():
    found = []

    @ctypes.WINFUNCTYPE(wt.BOOL, wt.HWND, wt.LPARAM)
    def each(hwnd, _):
        if user32.IsWindowVisible(hwnd) and not user32.GetWindow(hwnd, 4):      # visible, no owner
            pid = wt.DWORD()
            user32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
            if process_name(pid.value) == GAME_EXE:
                found.append(hwnd)
        return True

    user32.EnumWindows(each, 0)
    if not found:
        sys.exit("no game window (is the game running?)")
    return found[0]


def key(hwnd, vk, count=1):
    scan = user32.MapVirtualKeyW(vk, 0)
    down = 1 | (scan << 16)
    up = down | (1 << 30) | (1 << 31)
    for _ in range(count):
        user32.PostMessageW(hwnd, WM_KEYDOWN, vk, down)
        time.sleep(0.05)
        user32.PostMessageW(hwnd, WM_KEYUP, vk, up)
        time.sleep(0.2)


def lparam(x, y):
    return (y << 16) | (x & 0xFFFF)


def main():
    hwnd = game_window()
    cmd = sys.argv[1]
    if cmd == "key":
        key(hwnd, int(sys.argv[2], 16), int(sys.argv[3]) if len(sys.argv) > 3 else 1)
    elif cmd == "move":
        user32.PostMessageW(hwnd, WM_MOUSEMOVE, 0, lparam(int(sys.argv[2]), int(sys.argv[3])))
    elif cmd == "click":
        lp = lparam(int(sys.argv[2]), int(sys.argv[3]))
        user32.PostMessageW(hwnd, WM_MOUSEMOVE, 0, lp)
        time.sleep(0.05)
        user32.PostMessageW(hwnd, WM_LBUTTONDOWN, MK_LBUTTON, lp)
        time.sleep(0.08)
        user32.PostMessageW(hwnd, WM_LBUTTONUP, 0, lp)
    else:
        sys.exit(__doc__)
    print("sent", cmd, "to window", hex(hwnd))


if __name__ == "__main__":
    main()
