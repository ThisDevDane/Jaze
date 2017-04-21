#import win32 "sys/windows.odin" when ODIN_OS == "windows";
#import win32wgl "sys/wgl.odin" when ODIN_OS == "windows";
#import "fmt.odin";
#import "strings.odin";
#import "math.odin";

#import "odimgui/src/imgui.odin";
#import "jwin32.odin";
#import "gl.odin";
#import wgl "jwgl.odin";
#import debugWnd"debug_windows.odin";
#import "jimgui.odin";
#import "xinput.odin";
#import "render.odin";
#import "time.odin";
#import "catalog.odin";
#import "asset.odin";
#import "console.odin";
#import "entity.odin";

ProgramRunning : bool;
ShowDebugMenu : bool = true;
GlobalWin32VarsPtr : ^Win32Vars_t;
GlobalWindowPosition : win32.Window_Placement;

Win32Vars_t :: struct {
    AppHandle    : win32.Hinstance,
    WindowHandle : win32.Hwnd,
    WindowSize   : math.Vec2,
    DeviceCtx    : win32.Hdc,
    Ogl          : gl.OpenGLVars_t,
}

CreateWindow :: proc (instance : win32.Hinstance, ) -> win32.Hwnd {
    using win32;
    wndClass : WndClassExA;
    wndClass.size = size_of(WndClassExA);
    wndClass.style = CS_OWNDC|CS_HREDRAW|CS_VREDRAW;
    wndClass.wnd_proc = WindowProc;
    wndClass.instance = instance;
    wndClass.class_name = strings.new_c_string("jaze_class");

    if RegisterClassExA(^wndClass) == 0 {
        panic("Could Not Register Class");
    }

    windowStyle : u32 = WS_OVERLAPPEDWINDOW|WS_VISIBLE;
    clientRect := Rect{0,0,1280,720};
    AdjustWindowRect(^clientRect, windowStyle, 0);
    windowHandle := CreateWindowExA(0,
                                    wndClass.class_name,
                                    strings.new_c_string("Jaze"),
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
        panic("Could Not Create Window");
    }

    return windowHandle;
}


CreateOpenGLContext :: proc (vars : ^Win32Vars_t, modern : bool) -> win32wgl.Hglrc
{
    if !modern {
        pfd := win32.PIXELFORMATDESCRIPTOR {};
        pfd.size = size_of(win32.PIXELFORMATDESCRIPTOR);
        pfd.version = 1;
        pfd.flags = win32.PFD_DRAW_TO_WINDOW | win32.PFD_SUPPORT_OPENGL | win32.PFD_DOUBLEBUFFER;
        pfd.color_bits = 32;
        pfd.alpha_bits = 8;
        pfd.depth_bits = 24;
        format := win32.ChoosePixelFormat(vars.DeviceCtx, ^pfd);

        win32.DescribePixelFormat(vars.DeviceCtx, format, size_of(win32.PIXELFORMATDESCRIPTOR), ^pfd);

        win32.SetPixelFormat(vars.DeviceCtx, format, ^pfd);

        ctx := win32wgl.CreateContext(vars.DeviceCtx);

        assert(ctx != nil);
        win32wgl.MakeCurrent(vars.DeviceCtx, ctx);

        gl._GetIntegervStatic(cast(i32)gl.GetIntegerNames.MajorVersion, ^vars.Ogl.VersionMajorMax);
        gl._GetIntegervStatic(cast(i32)gl.GetIntegerNames.MinorVersion, ^vars.Ogl.VersionMinorMax);

        return ctx;
    } else {
        {
    
            wndHandle := win32.CreateWindowExA(0, 
                           strings.new_c_string("STATIC"), 
                           strings.new_c_string("OpenGL Loader"), 
                           win32.WS_OVERLAPPED, 
                           win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT,
                           nil, nil, nil, nil);
            assert(wndHandle != nil);
            wndDc := win32.GetDC(wndHandle);
            assert(wndDc != nil);
            temp := vars.DeviceCtx;
            vars.DeviceCtx = wndDc;
    
            oldCtx := CreateOpenGLContext(vars, false);
    
            vars.DeviceCtx = temp;
            assert(oldCtx != nil);
            extensions := wgl.TryGetExtensionList{};
            wgl.TryGetExtension(^extensions, ^wgl.ChoosePixelFormatARB,    "wglChoosePixelFormatARB");
            wgl.TryGetExtension(^extensions, ^wgl.CreateContextAttribsARB, "wglCreateContextAttribsARB");
            wgl.TryGetExtension(^extensions, ^wgl.GetExtensionsStringARB,  "wglGetExtensionsStringARB");
            wgl.TryGetExtension(^extensions, ^wgl.SwapIntervalEXT,         "wglSwapIntervalEXT");
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

        success := wgl.ChoosePixelFormatARB(vars.DeviceCtx, ^attribArray[0], nil, 1, ^format, ^formats);
        if (success == win32.TRUE) && (formats == 0) {
            panic("Couldn't find suitable pixel format");
        }
        pfd : win32.PIXELFORMATDESCRIPTOR;
        pfd.version = 1;
        pfd.size = size_of(win32.PIXELFORMATDESCRIPTOR);

        win32.DescribePixelFormat(vars.DeviceCtx, format, size_of(win32.PIXELFORMATDESCRIPTOR), ^pfd);
        win32.SetPixelFormat(vars.DeviceCtx, format, ^pfd);
        createAttr : [dynamic]wgl.Attrib;
        append(createAttr, wgl.CONTEXT_MAJOR_VERSION_ARB(3),
                           wgl.CONTEXT_MINOR_VERSION_ARB(3),
                           wgl.CONTEXT_FLAGS_ARB(wgl.CONTEXT_FLAGS_ARB_VALUES.DEBUG_BIT_ARB),
                           wgl.CONTEXT_PROFILE_MASK_ARB(wgl.CONTEXT_PROFILE_MASK_ARB_VALUES.CORE_PROFILE_BIT_ARB));
        attribArray = wgl.PrepareAttribArray(createAttr);
        
        ctx := wgl.CreateContextAttribsARB(vars.DeviceCtx, nil, ^attribArray[0]);
        assert(ctx != nil);
        win32wgl.MakeCurrent(vars.DeviceCtx, ctx);
        return ctx;
    }
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

        case win32.WM_MOUSEWHEEL : {
            delta := cast(i16)win32.HIWORD(wparam);
            if(delta > 1) {
                jimgui.State.MouseWheelDelta += 1;
            }
            if(delta < 1) {
                jimgui.State.MouseWheelDelta -= 1;
            }

            result = 1;
        } 

        case WM_SIZE : {
            gl.Viewport(0, 0, cast(i32)win32.LOWORD(lparam), cast(i32)win32.HIWORD(lparam));
            if GlobalWin32VarsPtr != nil {
                GlobalWin32VarsPtr.WindowSize.x = cast(f32)win32.LOWORD(lparam);
                GlobalWin32VarsPtr.WindowSize.y = cast(f32)win32.HIWORD(lparam);
            }

            io := imgui.GetIO();
            if io.RenderDrawListsFn != nil {
                jimgui.BeginNewFrame(0);
                imgui.SetNextWindowPosCenter(0);
                imgui.PushStyleVar(imgui.GuiStyleVar.Alpha, 0.8);
                imgui.Begin("Sizing", nil, imgui.GuiWindowFlags.AlwaysAutoResize | imgui.GuiWindowFlags.NoTitleBar);
                imgui.Text("%d, %d", cast(i32)GlobalWin32VarsPtr.WindowSize.x, cast(i32)GlobalWin32VarsPtr.WindowSize.y);
                imgui.End();
                imgui.PopStyleVar(1);
                RenderDebugUI(GlobalWin32VarsPtr);
                gl.Clear(gl.ClearFlags.COLOR_BUFFER | gl.ClearFlags.DEPTH_BUFFER);
                imgui.Render();
                win32.SwapBuffers(GlobalWin32VarsPtr.DeviceCtx);
            }
            result = 1;
        }

        case WM_CHAR : {
            imgui.GuiIO_AddInputCharacter(cast(u16)wparam); 
            result = 1;
        }
        break;

        default : {
            result = DefWindowProcA(hwnd, msg, wparam, lparam);
        }
    }
    
    return result;
}

OpenGLDebugCallback :: proc(source : gl.DebugSource, type : gl.DebugType, id : i32, severity : gl.DebugSeverity, length : i32, message : ^byte, userParam : rawptr) #cc_c {
    fmt.printf("[%v | %v | %v] %s \n", source, type, severity, strings.to_odin_string(message));
}

ToggleFullscreen :: proc(wnd : win32.Hwnd) {
    Style : u32 = cast(u32)win32.GetWindowLongPtrA(wnd, win32.GWL_STYLE);
    if(Style & win32.WS_OVERLAPPEDWINDOW == win32.WS_OVERLAPPEDWINDOW) {
        monitorInfo : win32.Monitor_Info;
        monitorInfo.size = size_of(win32.Monitor_Info);

        win32.GetWindowPlacement(wnd, ^GlobalWindowPosition);
        win32.GetMonitorInfoA(win32.MonitorFromWindow(wnd, win32.MONITOR_DEFAULTTOPRIMARY), ^monitorInfo);
        win32.SetWindowLongPtrA(wnd, win32.GWL_STYLE, cast(i64)Style & ~win32.WS_OVERLAPPEDWINDOW);
        win32.SetWindowPos(wnd, win32.Hwnd_TOP,
                              monitorInfo.monitor.left, monitorInfo.monitor.top,
                              monitorInfo.monitor.right - monitorInfo.monitor.left,
                              monitorInfo.monitor.bottom - monitorInfo.monitor.top,
                              win32.SWP_FRAMECHANGED | win32.SWP_NOOWNERZORDER);
    } else {
        win32.SetWindowLongPtrA(wnd, win32.GWL_STYLE, cast(i64)(Style | win32.WS_OVERLAPPEDWINDOW));
        win32.SetWindowPlacement(wnd, ^GlobalWindowPosition);
        win32.SetWindowPos(wnd, nil, 0, 0, 0, 0,
                              win32.SWP_NOMOVE | win32.SWP_NOSIZE | win32.SWP_NOZORDER |
                              win32.SWP_NOOWNERZORDER | win32.SWP_FRAMECHANGED);
    }       
}

RenderDebugUI :: proc(vars : ^Win32Vars_t) {

    MakeMenuItem :: proc(title : string, id : string) {
        MakeMenuItem(title, "", id);
    }

    MakeMenuItem :: proc(title : string, shortcut : string, id : string) {
        if imgui.MenuItem(title, shortcut, false, true) {
            debugWnd.ToggleWindow(id);
        }
    }

    imgui.PushStyleColor(imgui.GuiCol.MenuBarBg, imgui.Vec4{0.35, 0.35, 0.35, 0.78});
    imgui.BeginMainMenuBar();
   
    if imgui.BeginMenu("Data", true) {
        MakeMenuItem("OpenGL Info", "ShowOpenGLInfo");
        MakeMenuItem("Win32Var Info", "ShowWin32VarInfo");
        
        if imgui.BeginMenu("XInput", true) {
            MakeMenuItem("Info", "ShowXinputInfo");
            MakeMenuItem("State", "ShowXinputState");
            imgui.EndMenu();
        }

        MakeMenuItem("Time Data", "ShowTimeData");
        imgui.EndMenu();
    }

    if imgui.BeginMenu("Asset", true) {
        MakeMenuItem("Catalogs", "ShowCatalogWindow");
        imgui.EndMenu();
    }

    if imgui.BeginMenu("Misc", true) {
        MakeMenuItem("Camera Settings", "ShowCameraSettings");
        MakeMenuItem("Console", "Alt+C", "ShowConsoleWindow");
        MakeMenuItem("Debug Window States", "ShowDebugWindowStates");
        MakeMenuItem("Show Test Window", "ShowTestWindow");

        imgui.Separator();
        if imgui.MenuItem("Toggle Fullscreen", "Alt+Enter", false, true) {
            ToggleFullscreen(vars.WindowHandle);
        }
        
        if imgui.MenuItem("Exit", "Escape", false, true) {
            ProgramRunning = false;
        }
        imgui.EndMenu();
    }
    imgui.EndMainMenuBar();
    imgui.PopStyleColor(1);

    if debugWnd.GetWindowState("ShowOpenGLInfo") {
        b := debugWnd.GetWindowState("ShowOpenGLInfo");
        debugWnd.OpenGLInfo(^vars.Ogl, ^b);
        debugWnd.SetWindowState("ShowOpenGLInfo", b);
    }

    if debugWnd.GetWindowState("ShowWin32VarInfo") {
        b := debugWnd.GetWindowState("ShowWin32VarInfo");
        debugWnd.Win32VarsInfo(vars, ^b);
        debugWnd.SetWindowState("ShowWin32VarInfo", b);
    }

    debugWnd.TryShowWindow("ShowXinputInfo",        debugWnd.ShowXinputInfoWindow);
    debugWnd.TryShowWindow("ShowXinputState",       debugWnd.ShowXinputStateWindow);
    debugWnd.TryShowWindow("ShowTimeData",          debugWnd.ShowTimeDataWindow);
    debugWnd.TryShowWindow("ShowCatalogWindow",     debugWnd.ShowCatalogWindow);
    debugWnd.TryShowWindow("ShowDebugWindowStates", debugWnd.ShowDebugWindowStates);
    debugWnd.TryShowWindow("ShowConsoleWindow",     console.DrawConsole);
    debugWnd.TryShowWindow("ShowLogWindow",         console.DrawLog);

    if debugWnd.GetWindowState("ShowTestWindow") {
        b := debugWnd.GetWindowState("ShowTestWindow");
        imgui.ShowTestWindow(^b);
        debugWnd.SetWindowState("ShowTestWindow", b);
    }
}

ChangeWindowTitle :: proc(window : win32.Hwnd, fmt_ : string, args : ..any) {
    buf : [1024]byte;
    fmt.sprintf(buf[..0], fmt_, ..args);
    win32.SetWindowTextA(window, ^buf[0]);
}

main :: proc() {
    GlobalWindowPosition.length = size_of(win32.Window_Placement);
    win32vars := Win32Vars_t{};
    GlobalWin32VarsPtr = ^win32vars;
    win32vars.AppHandle = win32.GetModuleHandleA(nil);
    win32vars.WindowHandle = CreateWindow(win32vars.AppHandle); 
    win32vars.DeviceCtx = win32.GetDC(win32vars.WindowHandle);
    win32vars.Ogl.Ctx = CreateOpenGLContext(^win32vars, true);
    gl.Init();
    gl.DebugMessageCallback(OpenGLDebugCallback, nil);
    gl.Enable(gl.Capabilities.DebugOutputSynchronous);
    gl.DebugMessageControl(gl.DebugSource.DontCare, gl.DebugType.DontCare, gl.DebugSeverity.Notification, 0, nil, false);
    gl.GetInfo(^win32vars.Ogl);
    wgl.GetInfo(^win32vars.Ogl, win32vars.DeviceCtx);

    ChangeWindowTitle(win32vars.WindowHandle, "Jaze %s", win32vars.Ogl.VersionString);

    gl.ClearColor(1, 0, 1, 1);
    jimgui.Init(win32vars.WindowHandle);
    ProgramRunning = true;

    time.Init();

    wgl.SwapIntervalEXT(-1);
    xinput.Init();
    xinput.Enable(true);
    //soundCat, _   := catalog.CreateNew(catalog.Kind.Sound,   "data/sounds/",   ".ogg");
    shaderCat, _  := catalog.CreateNew(catalog.Kind.Shader,  "data/shaders/",  ".frag,.vert");
    textureCat, _ := catalog.CreateNew(catalog.Kind.Texture, "data/textures/", ".png,.jpg,.jpeg");

    render.Init(shaderCat, textureCat);

    console.AddCommand("LogCData", console.LogConsoleData);
    console.AddCommand("Help", console.HelpCommand);

    for ProgramRunning {
        msg : win32.Msg;
        for win32.PeekMessageA(^msg, nil, 0, 0, win32.PM_REMOVE) == win32.TRUE {
            match msg.message {
                case win32.WM_QUIT : {
                    ProgramRunning = false;
                }

                case win32.WM_SYSKEYDOWN : {
                    if cast(win32.Key_Code)msg.wparam == win32.Key_Code.RETURN {
                        ToggleFullscreen(win32vars.WindowHandle);
                    }

                    if cast(win32.Key_Code)msg.wparam == win32.Key_Code.C {
                        debugWnd.ToggleWindow("ShowConsoleWindow");
                    }

                    if msg.wparam == 0xC0 {
                        ShowDebugMenu = !ShowDebugMenu;
                    }
                    continue;
                }

                case win32.WM_KEYDOWN : {
                    if cast(win32.Key_Code)msg.wparam == win32.Key_Code.ESCAPE {
                        win32.PostQuitMessage(0);
                    }
                } 
            }

            win32.TranslateMessage(^msg);
            win32.DispatchMessageA(^msg);
        }

        time.Update();

        ChangeWindowTitle(win32vars.WindowHandle, "Jaze %s | dt: %.5f sdt: %.5f ss: %.1f", win32vars.Ogl.VersionString, time.GetUnscaledDeltaTime(), 
                                                                                           time.GetDeltaTime(), time.GetTimeSinceStart());


        if ShowDebugMenu {
            jimgui.BeginNewFrame(time.GetUnscaledDeltaTime());
            RenderDebugUI(^win32vars);
        }


        gl.Clear(gl.ClearFlags.COLOR_BUFFER | gl.ClearFlags.DEPTH_BUFFER);

        render.Draw(win32vars.WindowSize);        
        if ShowDebugMenu {
            imgui.Render();
        }

        win32.SwapBuffers(win32vars.DeviceCtx);
    }
}