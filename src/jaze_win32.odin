#foreign_system_library "user32.lib";
#import win32 "sys/windows.odin";

DestroyWindow :: proc(wnd : win32.HWND) -> win32.BOOL #foreign user32 "DestroyWindow";