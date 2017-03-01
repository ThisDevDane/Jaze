#foreign_system_library user32 "User32.lib";
#import win32 "sys/windows.odin";

HMONITOR      :: win32.HANDLE;

WM_MOUSEWHEEL        :: 0x020A;
WM_SYSKEYDOWN        :: 0x0104;
WM_WINDOWPOSCHANGED  :: 0x0047;

GWL_STYLE     :: -16;

HWND_TOP :: cast(win32.HWND)cast(uint)0;

MONITOR_DEFAULTTONULL    :: 0x00000000;
MONITOR_DEFAULTTOPRIMARY :: 0x00000001;
MONITOR_DEFAULTTONEAREST :: 0x00000002;

SWP_FRAMECHANGED  :: 0x0020;
SWP_NOOWNERZORDER :: 0x0200;
SWP_NOZORDER      :: 0x0004;
SWP_NOSIZE        :: 0x0001;
SWP_NOMOVE        :: 0x0002;


MONITORINFO :: struct #ordered {
    Size : u32,
    Monitor : win32.RECT,
    Work : win32.RECT,
    flags : u32,
}

WINDOWPLACEMENT :: struct #ordered {
    Length : u32,
    Flags : u32,
    ShowCmd : u32,
    MinPos : win32.POINT,
    MaxPos : win32.POINT,
    NormalPos : win32.RECT,
}

GetMonitorInfo     :: proc(monitor : HMONITOR, mi : ^MONITORINFO) -> win32.BOOL                                                     #foreign user32 "GetMonitorInfoA";
MonitorFromWindow  :: proc(wnd : win32.HWND, flags : u32) -> HMONITOR                                                               #foreign user32 "MonitorFromWindow";

SetWindowPos       :: proc(wnd : win32.HWND, wndInsertAfter : win32.HWND, x : i32, y : i32, width : i32, height : i32, flags : u32) #foreign user32 "SetWindowPos";

GetWindowPlacement :: proc(wnd : win32.HWND, wndpl : ^WINDOWPLACEMENT) -> win32.BOOL                                                #foreign user32 "GetWindowPlacement";
SetWindowPlacement :: proc(wnd : win32.HWND, wndpl : ^WINDOWPLACEMENT) -> win32.BOOL                                                #foreign user32 "SetWindowPlacement";

GetWindowLongPtr   :: proc(wnd : win32.HWND, index : i32) -> i64                                                                    #foreign user32 "GetWindowLongPtrA";
SetWindowLongPtr   :: proc(wnd : win32.HWND, index : i32, new : i64) -> i64                                                         #foreign user32 "SetWindowLongPtrA";

GetWindowText      :: proc(wnd : win32.HWND, str : ^byte, maxCount : i32) -> i32                                                    #foreign user32 "GetWindowTextA";

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