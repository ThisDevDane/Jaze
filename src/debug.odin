#import debugWnd "debug_windows.odin";
#import "imgui.odin";
#import "main.odin";
#import "console.odin";
#import wgl "jwgl.odin";

RenderDebugUI :: proc(Ctx : ^main.EngineContext_t) {
   MakeMenuBar();
   TryToRenderWindows(Ctx);
}

MakeMenuBar :: proc() {
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

    if imgui.BeginMenu("Visual", true) {
        if imgui.Checkbox("Toggle Adaptive VSync", &main.EngineContext.AdaptiveVSync) {
            if main.EngineContext.AdaptiveVSync {
                wgl.SwapIntervalEXT(-1);
            } else {
                wgl.SwapIntervalEXT(0);
            }
        }
        {
            b := debugWnd.GetWindowState("ShowStatOverlay");
            if imgui.Checkbox("Toggle Stat Overlay", &b) {
                debugWnd.SetWindowState("ShowStatOverlay", b);
            }
        }
        
        imgui.EndMenu();
    }

    if imgui.BeginMenu("Misc", true) {
        MakeMenuItem("Camera Settings", "ShowCameraSettings");
        MakeMenuItem("Console", "Alt+C", "ShowConsoleWindow");
        MakeMenuItem("Debug Window States", "ShowDebugWindowStates");
        MakeMenuItem("Show Test Window", "ShowTestWindow");

        imgui.Separator();
        imgui.MenuItem("Toggle Fullscreen", "Alt+Enter", false, false);

        
        if imgui.MenuItem("Exit", "Escape", false, true) {
            main.EngineContext.ProgramRunning = false;
        }
        imgui.EndMenu();
    }
    imgui.EndMainMenuBar();
    imgui.PopStyleColor(1);
}

TryToRenderWindows :: proc(Ctx : ^main.EngineContext_t) {
    if debugWnd.GetWindowState("ShowOpenGLInfo") {
        b := debugWnd.GetWindowState("ShowOpenGLInfo");
        debugWnd.OpenGLInfo(&Ctx.win32.Ogl, &b);
        debugWnd.SetWindowState("ShowOpenGLInfo", b);
    }

    if debugWnd.GetWindowState("ShowWin32VarInfo") {
        b := debugWnd.GetWindowState("ShowWin32VarInfo");
        debugWnd.Win32VarsInfo(&Ctx.win32, &b);
        debugWnd.SetWindowState("ShowWin32VarInfo", b);
    }

    debugWnd.TryShowWindow("ShowXinputInfo",        debugWnd.ShowXinputInfoWindow);
    debugWnd.TryShowWindow("ShowXinputState",       debugWnd.ShowXinputStateWindow);
    debugWnd.TryShowWindow("ShowTimeData",          debugWnd.ShowTimeDataWindow);
    debugWnd.TryShowWindow("ShowCatalogWindow",     debugWnd.ShowCatalogWindow);
    debugWnd.TryShowWindow("ShowDebugWindowStates", debugWnd.ShowDebugWindowStates);
    debugWnd.TryShowWindow("ShowStatOverlay",       debugWnd.StatOverlay);
    debugWnd.TryShowWindow("ShowConsoleWindow",     console.DrawConsole);
    debugWnd.TryShowWindow("ShowLogWindow",         console.DrawLog);

    if debugWnd.GetWindowState("ShowTestWindow") {
        b := debugWnd.GetWindowState("ShowTestWindow");
        imgui.ShowTestWindow(&b);
        debugWnd.SetWindowState("ShowTestWindow", b);
    }
}