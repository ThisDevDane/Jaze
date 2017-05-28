/*
 *  @Name:     platform_win32
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 05-05-2017 22:12:56
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 28-05-2017 19:10:51
 *  
 *  @Description:
 *      Contains data and functions related to interacting with windows.
 */
#import win32 "sys/windows.odin" when ODIN_OS == "windows";
#import win32wgl "sys/wgl.odin" when ODIN_OS == "windows";
#import "math.odin";
#import "strings.odin";
#import "fmt.odin";

#import "gl.odin";
#import "engine.odin";
#import "input.odin";
#import "imgui.odin";
#import wgl "jwgl.odin";
#import debugWnd "debug_windows.odin";

AppHandle :: win32.Hinstance;
WndHandle :: win32.Hinstance;

Data_t :: struct {
    AppHandle          : AppHandle,
    WindowHandle       : WndHandle,
    DeviceCtx          : win32.Hdc,
    Ogl                : gl.OpenGLVars_t,
    WindowPlacement    : win32.Window_Placement,
}

WindowProc :: proc(hwnd: win32.Hwnd, 
                   msg: u32, 
                   wparam: win32.Wparam, 
                   lparam: win32.Lparam) -> win32.Lresult #cc_c {
    match(msg) {       
        case win32.WM_DESTROY : {
            win32.PostQuitMessage(0);
            return 0;
        }

        case : {
            return win32.DefWindowProcA(hwnd, msg, wparam, lparam);
        }
    }
}

GetProgramHandle :: proc() -> AppHandle {
    return AppHandle(win32.GetModuleHandleA(nil));
}

GetWindowSize :: proc(handle : WndHandle) -> math.Vec2 {
    res : math.Vec2;
    rect : win32.Rect;
    win32.GetClientRect(win32.Hwnd(handle), &rect);
    res.x = f32(rect.right);
    res.y = f32(rect.bottom);

    return res;
}

SwapBuffers :: proc(dc : win32.Hdc) {
    win32.SwapBuffers(dc);
}

Event :: union {
    Quit{
        ExitCode : int    
    },
    KeyDown{},
    MouseWheel{},
    Char{},
}

MessageLoop :: proc(ctx : ^engine.Context){
    msg : win32.Msg;
    for win32.PeekMessageA(&msg, nil, 0, 0, win32.PM_REMOVE) == win32.TRUE {
        match msg.message {
            case win32.WM_QUIT : {
                ctx.settings.program_running = false;
            }

            case win32.WM_SYSKEYDOWN : {
                if win32.Key_Code(msg.wparam) == win32.Key_Code.RETURN {
                    ToggleBorderlessFullscreen(ctx.win32.WindowHandle, &ctx.win32.WindowPlacement);
                }

                if win32.Key_Code(msg.wparam) == win32.Key_Code.C {
                    debugWnd.toggle_window_state("ShowConsoleWindow");
                }

                if msg.wparam == 0xC0 {
                    ctx.settings.show_debug_menu = !ctx.settings.show_debug_menu;
                }
                continue;
            }

            case win32.WM_KEYDOWN : {
                if win32.Key_Code(msg.wparam) == win32.Key_Code.ESCAPE {
                    win32.PostQuitMessage(0);
                }
            } 

            case win32.WM_CHAR : {
                imgui.gui_io_add_input_character(u16(msg.wparam)); 
                input.add_char_to_queue(ctx.input, rune(msg.wparam));
            }
            break;

            case win32.WM_MOUSEWHEEL : {
                delta := i16(win32.HIWORD(msg.wparam));
                if(delta > 1) {
                    ctx.imgui_state.mouse_wheel_delta += 1;
                }
                if(delta < 1) {
                    ctx.imgui_state.mouse_wheel_delta -= 1;
                }
            } 


        }

        win32.TranslateMessage(&msg);
        win32.DispatchMessageA(&msg);
    }
}

GetDC :: proc(handle : WndHandle) -> win32.Hdc {
    return win32.GetDC(win32.Hwnd(handle));
}

IsWindowActive :: proc(handle : WndHandle) -> bool {
    return win32.GetActiveWindow() == win32.Hwnd(handle);
}

/*GetGlobalCursorPos :: proc() -> math.Vec2 {
    mousePos : win32.Point;
    win32.GetCursorPos(&mousePos);
    win32.ScreenToClient(handle, &mousePos);
    input.MousePos = math.Vec2{f32(mousePos.x), f32(mousePos.y)};
}*/

GetCursorPos :: proc(handle : WndHandle) -> math.Vec2 {
    mousePos : win32.Point;
    win32.GetCursorPos(&mousePos);
    win32.ScreenToClient(win32.Hwnd(handle), &mousePos);
    return math.Vec2{f32(mousePos.x), f32(mousePos.y)};
}

CreateWindow :: proc (instance : AppHandle, windowSize : math.Vec2) -> WndHandle {
    using win32;
    wndClass : WndClassExA;
    wndClass.size = size_of(WndClassExA);
    wndClass.style = CS_OWNDC|CS_HREDRAW|CS_VREDRAW;
    wndClass.wnd_proc = WindowProc;
    wndClass.instance = win32.Hinstance(instance);
    wndClass.class_name = strings.new_c_string("jaze_class");

    if RegisterClassExA(&wndClass) == 0 {
        panic("Could not register main window class");
    }

    windowStyle : u32 = WS_OVERLAPPEDWINDOW|WS_VISIBLE;
    clientRect := Rect{0, 0, i32(windowSize.x), i32(windowSize.y)};
    AdjustWindowRect(&clientRect, windowStyle, 0);
    windowHandle := CreateWindowExA(0,
                                    wndClass.class_name,
                                    strings.new_c_string("Jaze - DEV VERSION"),
                                    windowStyle,
                                    CW_USEDEFAULT,
                                    CW_USEDEFAULT,
                                    clientRect.right - clientRect.left,
                                    clientRect.bottom - clientRect.top,
                                    nil,
                                    nil,
                                    win32.Hinstance(instance),
                                    nil);
    if windowHandle == nil {
        panic("Could not create main window");
    }

    return WndHandle(windowHandle);
}

GetMaxGLVersion :: proc() -> (i32, i32) {
    wndHandle := win32.CreateWindowExA(0, 
                                       strings.new_c_string("STATIC"), 
                                       strings.new_c_string("OpenGL Version Checker"), 
                                       win32.WS_OVERLAPPED, 
                                       win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT,
                                       nil, nil, nil, nil);
    if wndHandle == nil {
        panic("Could not create opengl version checker window");
    }
    deviceCtx := win32.GetDC(wndHandle);
    if deviceCtx == nil {
        panic("Could not get DC for opengl version checker window");
    }

    pfd := win32.PIXELFORMATDESCRIPTOR {};
    pfd.size = size_of(win32.PIXELFORMATDESCRIPTOR);
    pfd.version = 1;
    pfd.flags = win32.PFD_DRAW_TO_WINDOW | win32.PFD_SUPPORT_OPENGL | win32.PFD_DOUBLEBUFFER;
    pfd.color_bits = 32;
    pfd.alpha_bits = 8;
    pfd.depth_bits = 24;
    format := win32.ChoosePixelFormat(deviceCtx, &pfd);

    win32.DescribePixelFormat(deviceCtx, format, size_of(win32.PIXELFORMATDESCRIPTOR), &pfd);

    win32.SetPixelFormat(deviceCtx, format, &pfd);

    ctx := win32wgl.CreateContext(deviceCtx);
    if deviceCtx == nil {
        panic("Could not get OpenGL Context for opengl version checker window");
    }
    win32wgl.MakeCurrent(deviceCtx, ctx);

    major : i32;
    minor : i32;
    gl._GetIntegervStatic(i32(gl.GetIntegerNames.MajorVersion), &major);
    gl._GetIntegervStatic(i32(gl.GetIntegerNames.MinorVersion), &minor);

    return major, minor;
}


CreateOpenGLContext :: proc (DeviceCtx : win32.Hdc, modern : bool, major, minor : int) -> win32wgl.Hglrc
{
    if !modern {
        pfd := win32.PIXELFORMATDESCRIPTOR {};
        pfd.size = size_of(win32.PIXELFORMATDESCRIPTOR);
        pfd.version = 1;
        pfd.flags = win32.PFD_DRAW_TO_WINDOW | win32.PFD_SUPPORT_OPENGL | win32.PFD_DOUBLEBUFFER;
        pfd.color_bits = 32;
        pfd.alpha_bits = 8;
        pfd.depth_bits = 24;
        format := win32.ChoosePixelFormat(DeviceCtx, &pfd);

        win32.DescribePixelFormat(DeviceCtx, format, size_of(win32.PIXELFORMATDESCRIPTOR), &pfd);

        win32.SetPixelFormat(DeviceCtx, format, &pfd);

        ctx := win32wgl.CreateContext(DeviceCtx);

        assert(ctx != nil);
        win32wgl.MakeCurrent(DeviceCtx, ctx);

        return ctx;
    } else {
        {
    
            wndHandle := win32.CreateWindowExA(0, 
                           strings.new_c_string("STATIC"), 
                           strings.new_c_string("OpenGL Loader"), 
                           win32.WS_OVERLAPPED, 
                           win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT,
                           nil, nil, nil, nil);
            if wndHandle == nil {
                panic("Could not create opengl loader window");
            }
            wndDc := win32.GetDC(wndHandle);
            assert(wndDc != nil);
            temp := DeviceCtx;
            DeviceCtx = wndDc;
    
            oldCtx := CreateOpenGLContext(DeviceCtx, false, 0, 0);
    
            DeviceCtx = temp;
            assert(oldCtx != nil);
            extensions := wgl.TryGetExtensionList{};
            wgl.TryGetExtension(&extensions, &wgl.ChoosePixelFormatARB,    "wglChoosePixelFormatARB");
            wgl.TryGetExtension(&extensions, &wgl.CreateContextAttribsARB, "wglCreateContextAttribsARB");
            wgl.TryGetExtension(&extensions, &wgl.GetExtensionsStringARB,  "wglGetExtensionsStringARB");
            wgl.TryGetExtension(&extensions, &wgl.SwapIntervalEXT,         "wglSwapIntervalEXT");
            wgl.LoadExtensions(oldCtx, wndDc, extensions);
            win32wgl.MakeCurrent(nil, nil);
            win32wgl.DeleteContext(oldCtx);
            win32.ReleaseDC(wndHandle, wndDc);
            win32.DestroyWindow(wndHandle);
    
        }
        
        attribs : [dynamic]wgl.Attrib;
        append(attribs, wgl.DRAW_TO_WINDOW_ARB(true),
                        wgl.ACCELERATION_ARB(wgl.ACCELERATION_ARB_VALUES.FULL_ACCELERATION_ARB),
                        wgl.SUPPORT_OPENGL_ARB(true),
                        wgl.DOUBLE_BUFFER_ARB(true),
                        wgl.PIXEL_TYPE_ARB(wgl.PIXEL_TYPE_ARB_VALUES.RGBA_ARB),
                        wgl.COLOR_BITS_ARB(32),
                        wgl.ALPHA_BITS_ARB(8),
                        wgl.DEPTH_BITS_ARB(24),
                        wgl.FRAMEBUFFER_SRGB_CAPABLE_ARB(true));
        attribArray := wgl.PrepareAttribArray(attribs);
        format : i32;
        formats : u32;

        success := wgl.ChoosePixelFormatARB(DeviceCtx, &attribArray[0], nil, 1, &format, &formats);
        if (success == win32.TRUE) && (formats == 0) {
            panic("Couldn't find suitable pixel format");
        }
        pfd : win32.PIXELFORMATDESCRIPTOR;
        pfd.version = 1;
        pfd.size = size_of(win32.PIXELFORMATDESCRIPTOR);

        win32.DescribePixelFormat(DeviceCtx, format, size_of(win32.PIXELFORMATDESCRIPTOR), &pfd);
        win32.SetPixelFormat(DeviceCtx, format, &pfd);
        createAttr : [dynamic]wgl.Attrib;
        append(createAttr, wgl.CONTEXT_MAJOR_VERSION_ARB(i32(major)),
                           wgl.CONTEXT_MINOR_VERSION_ARB(i32(minor)),
                           wgl.CONTEXT_FLAGS_ARB(wgl.CONTEXT_FLAGS_ARB_VALUES.DEBUG_BIT_ARB),
                           wgl.CONTEXT_PROFILE_MASK_ARB(wgl.CONTEXT_PROFILE_MASK_ARB_VALUES.CORE_PROFILE_BIT_ARB));
        attribArray = wgl.PrepareAttribArray(createAttr);
        
        ctx := wgl.CreateContextAttribsARB(DeviceCtx, nil, &attribArray[0]);
        assert(ctx != nil);
        win32wgl.MakeCurrent(DeviceCtx, ctx);
        return ctx;
    }
}

ToggleBorderlessFullscreen :: proc(wnd : WndHandle, WindowPlacement : ^win32.Window_Placement) {
    Style : u32 = u32(win32.GetWindowLongPtrA(win32.Hwnd(wnd), win32.GWL_STYLE));
    if(Style & win32.WS_OVERLAPPEDWINDOW == win32.WS_OVERLAPPEDWINDOW) {
        monitorInfo : win32.Monitor_Info;
        monitorInfo.size = size_of(win32.Monitor_Info);

        win32.GetWindowPlacement(win32.Hwnd(wnd), WindowPlacement);
        win32.GetMonitorInfoA(win32.MonitorFromWindow(win32.Hwnd(wnd), win32.MONITOR_DEFAULTTOPRIMARY), &monitorInfo);
        win32.SetWindowLongPtrA(win32.Hwnd(wnd), win32.GWL_STYLE, i64(Style) & ~win32.WS_OVERLAPPEDWINDOW);
        win32.SetWindowPos(win32.Hwnd(wnd), win32.Hwnd_TOP,
                                monitorInfo.monitor.left, monitorInfo.monitor.top,
                                monitorInfo.monitor.right - monitorInfo.monitor.left,
                                monitorInfo.monitor.bottom - monitorInfo.monitor.top,
                                win32.SWP_FRAMECHANGED | win32.SWP_NOOWNERZORDER);
    } else {
        win32.SetWindowLongPtrA(win32.Hwnd(wnd), win32.GWL_STYLE, i64(Style | win32.WS_OVERLAPPEDWINDOW));
        win32.SetWindowPlacement(win32.Hwnd(wnd), WindowPlacement);
        win32.SetWindowPos(win32.Hwnd(wnd), nil, 0, 0, 0, 0,
                                win32.SWP_NOMOVE | win32.SWP_NOSIZE | win32.SWP_NOZORDER |
                                win32.SWP_NOOWNERZORDER | win32.SWP_FRAMECHANGED);
    }       
}

ChangeWindowTitle :: proc(window : WndHandle, fmt_ : string, args : ..any) {
    buf : [1024]byte;
    fmt.bprintf(buf[..], fmt_, ..args);
    win32.SetWindowTextA(win32.Hwnd(window), &buf[0]);
}