#import win32 "sys/windows.odin" when ODIN_OS == "windows";
#import win32wgl "sys/wgl.odin" when ODIN_OS == "windows";
#import "math.odin";
#import "strings.odin";
#import "fmt.odin";

#import "gl.odin";
#import wgl "jwgl.odin";

Data_t :: struct {
    AppHandle          : win32.Hinstance,
    WindowHandle       : win32.Hwnd,
    DeviceCtx          : win32.Hdc,
    Ogl                : gl.OpenGLVars_t,
    WindowPlacement    : win32.Window_Placement,
}

WindowProc :: proc(hwnd: win32.Hwnd, 
                   msg: u32, 
                   wparam: win32.Wparam, 
                   lparam: win32.Lparam) -> win32.Lresult #cc_c {
    using win32;
    result : Lresult = 0;
    match(msg) {       
        case WM_DESTROY : {
            PostQuitMessage(0);
        }

        default : {
            result = DefWindowProcA(hwnd, msg, wparam, lparam);
        }
    }
    
    return result;
}

CreateWindow :: proc (instance : win32.Hinstance, windowSize : math.Vec2) -> win32.Hwnd {
    using win32;
    wndClass : WndClassExA;
    wndClass.size = size_of(WndClassExA);
    wndClass.style = CS_OWNDC|CS_HREDRAW|CS_VREDRAW;
    wndClass.wnd_proc = WindowProc;
    wndClass.instance = instance;
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
                                    instance,
                                    nil);
    if windowHandle == nil {
        panic("Could not create main window");
    }

    return windowHandle;
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


CreateOpenGLContext :: proc (DeviceCtx : win32.Hdc, modern : bool) -> win32wgl.Hglrc
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
    
            oldCtx := CreateOpenGLContext(DeviceCtx, false);
    
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
        append(createAttr, wgl.CONTEXT_MAJOR_VERSION_ARB(3),
                           wgl.CONTEXT_MINOR_VERSION_ARB(3),
                           wgl.CONTEXT_FLAGS_ARB(wgl.CONTEXT_FLAGS_ARB_VALUES.DEBUG_BIT_ARB),
                           wgl.CONTEXT_PROFILE_MASK_ARB(wgl.CONTEXT_PROFILE_MASK_ARB_VALUES.CORE_PROFILE_BIT_ARB));
        attribArray = wgl.PrepareAttribArray(createAttr);
        
        ctx := wgl.CreateContextAttribsARB(DeviceCtx, nil, &attribArray[0]);
        assert(ctx != nil);
        win32wgl.MakeCurrent(DeviceCtx, ctx);
        return ctx;
    }
}

ToggleBorderlessFullscreen :: proc(wnd : win32.Hwnd, WindowPlacement : ^win32.Window_Placement) {
    Style : u32 = u32(win32.GetWindowLongPtrA(wnd, win32.GWL_STYLE));
    if(Style & win32.WS_OVERLAPPEDWINDOW == win32.WS_OVERLAPPEDWINDOW) {
        monitorInfo : win32.Monitor_Info;
        monitorInfo.size = size_of(win32.Monitor_Info);

        win32.GetWindowPlacement(wnd, WindowPlacement);
        win32.GetMonitorInfoA(win32.MonitorFromWindow(wnd, win32.MONITOR_DEFAULTTOPRIMARY), &monitorInfo);
        win32.SetWindowLongPtrA(wnd, win32.GWL_STYLE, i64(Style) & ~win32.WS_OVERLAPPEDWINDOW);
        win32.SetWindowPos(wnd, win32.Hwnd_TOP,
                                monitorInfo.monitor.left, monitorInfo.monitor.top,
                                monitorInfo.monitor.right - monitorInfo.monitor.left,
                                monitorInfo.monitor.bottom - monitorInfo.monitor.top,
                                win32.SWP_FRAMECHANGED | win32.SWP_NOOWNERZORDER);
    } else {
        win32.SetWindowLongPtrA(wnd, win32.GWL_STYLE, i64(Style | win32.WS_OVERLAPPEDWINDOW));
        win32.SetWindowPlacement(wnd, WindowPlacement);
        win32.SetWindowPos(wnd, nil, 0, 0, 0, 0,
                                win32.SWP_NOMOVE | win32.SWP_NOSIZE | win32.SWP_NOZORDER |
                                win32.SWP_NOOWNERZORDER | win32.SWP_FRAMECHANGED);
    }       
}

ChangeWindowTitle :: proc(window : win32.Hwnd, fmt_ : string, args : ..any) {
    buf : [1024]byte;
    fmt.bprintf(buf[..], fmt_, ..args);
    win32.SetWindowTextA(window, &buf[0]);
}