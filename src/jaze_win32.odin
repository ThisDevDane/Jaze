#foreign_system_library "user32.lib";
#import win32 "sys/windows.odin";

WM_MOUSEWHEEL :: 0x020A;

DestroyWindow :: proc(wnd : win32.HWND) -> win32.BOOL #foreign user32 "DestroyWindow";

HIWORD        :: proc(wParam : win32.WPARAM) -> u16 {
    return (cast(u16)(((cast(u32)(wParam)) >> 16) & 0xffff));
}
HIWORD        :: proc(lParam : win32.LPARAM) -> u16 {
    return (cast(u16)(((cast(u32)(lParam)) >> 16) & 0xffff));
}

LOWORD        :: proc(wParam : win32.WPARAM) -> u16 {
    return  cast(u16)wParam;
}
LOWORD        :: proc(lParam : win32.LPARAM) -> u16 {
    return cast(u16)lParam;
}