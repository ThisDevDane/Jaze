/*
 *  @Name:     debug
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 10-05-2017 21:11:30
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 20-05-2017 00:45:35
 *  
 *  @Description:
 *  
 */
#import win32 "sys/windows.odin";
#import "jwin32.odin";
#import debugWnd "debug_windows.odin";
#import "imgui.odin";
#import "main.odin";
#import "console.odin";
#import "engine.odin";
#import "game.odin";
#import wgl "jwgl.odin";

RenderDebugUI :: proc(ctx : ^engine.Context_t, gameCtx : ^game.Context_t) {
   MakeMenuBar(ctx);
   TryToRenderWindows(ctx, gameCtx);
}

MakeMenuBar :: proc(ctx : ^engine.Context_t) {
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

    if imgui.BeginMenu("Game", true) {
        MakeMenuItem("Entity List", "ShowEntityList");
        MakeMenuItem("Game Info", "ShowGameInfo");
        imgui.EndMenu();
    }
   
    if imgui.BeginMenu("Data", true) {
        MakeMenuItem("OpenGL Info", "ShowOpenGLInfo");
        MakeMenuItem("Win32Var Info", "ShowWin32VarInfo");
        MakeMenuItem("Time Data", "ShowTimeData");
        MakeMenuItem("Engine Info", "ShowEngineInfo");
        imgui.EndMenu();
    }

    if imgui.BeginMenu("Input", true) {
        MakeMenuItem("Keyboard & Mouse", "ShowInputWindow");
        if imgui.BeginMenu("XInput", true) {
            MakeMenuItem("Info", "ShowXinputInfo");
            MakeMenuItem("State", "ShowXinputState");
            imgui.EndMenu();
        }
        imgui.EndMenu();
    }

    if imgui.BeginMenu("Asset", true) {
        MakeMenuItem("Catalogs", "ShowCatalogWindow");
        imgui.EndMenu();
    }

    if imgui.BeginMenu("Visual", true) {
        if imgui.Checkbox("Adaptive VSync", &ctx.AdaptiveVSync) {
            if ctx.AdaptiveVSync {
                wgl.SwapIntervalEXT(-1);
            } else {
                wgl.SwapIntervalEXT(0);
            }
        }
        {
            b := debugWnd.GetWindowState("ShowStatOverlay");
            if imgui.Checkbox("Stat Overlay", &b) {
                debugWnd.SetWindowState("ShowStatOverlay", b);
            }
        }

        if imgui.Checkbox("Hardware Cursor", &ctx.Settings.ShowCursor) {
            jwin32.ShowCursor(win32.Bool(ctx.Settings.ShowCursor));
        }
        
        imgui.EndMenu();
    }

    if imgui.BeginMenu("Misc", true) {
        MakeMenuItem("Console", "Alt+C", "ShowConsoleWindow");
        MakeMenuItem("Debug Window States", "ShowDebugWindowStates");
        MakeMenuItem("Show Test Window", "ShowTestWindow");

        imgui.Separator();
        imgui.MenuItem("Toggle Fullscreen", "Alt+Enter", false, false);

        
        if imgui.MenuItem("Exit", "Escape", false, true) {
            ctx.Settings.ProgramRunning = false;
        }
        imgui.EndMenu();
    }
    imgui.EndMainMenuBar();
    imgui.PopStyleColor(1);
}

TryToRenderWindows :: proc(ctx : ^engine.Context_t, gameCtx : ^game.Context_t) {
    if debugWnd.GetWindowState("ShowOpenGLInfo") {
        b := debugWnd.GetWindowState("ShowOpenGLInfo");
        debugWnd.OpenGLInfo(&ctx.Win32.Ogl, &b);
        debugWnd.SetWindowState("ShowOpenGLInfo", b);
    }

    if debugWnd.GetWindowState("ShowInputWindow") {
        b := debugWnd.GetWindowState("ShowInputWindow");
        debugWnd.ShowInputWindow(ctx.Input, &b);
        debugWnd.SetWindowState("ShowInputWindow", b);
    }

    if debugWnd.GetWindowState("ShowWin32VarInfo") {
        b := debugWnd.GetWindowState("ShowWin32VarInfo");
        debugWnd.ShowStructInfo("Win32 Info", &b, ctx.Win32^);;
        debugWnd.SetWindowState("ShowWin32VarInfo", b);
    }

    if debugWnd.GetWindowState("ShowEntityList") {
        b := debugWnd.GetWindowState("ShowEntityList");
        debugWnd.ShowEntityList(gameCtx, &b);
        debugWnd.SetWindowState("ShowEntityList", b);
    }

        if debugWnd.GetWindowState("ShowGameInfo") {
        b := debugWnd.GetWindowState("ShowGameInfo");
        debugWnd.ShowStructInfo("Game Info", &b, gameCtx^);
        debugWnd.SetWindowState("ShowGameInfo", b);
    }

    if debugWnd.GetWindowState("ShowTimeData") {
        b := debugWnd.GetWindowState("ShowTimeData");
        debugWnd.ShowStructInfo("Time", &b, ctx.Time^);
        debugWnd.SetWindowState("ShowTimeData", b);
    }

    if debugWnd.GetWindowState("ShowEngineInfo") {
        b := debugWnd.GetWindowState("ShowEngineInfo");
        debugWnd.ShowStructInfo("Engine Info", &b, ctx^);
        debugWnd.SetWindowState("ShowEngineInfo", b);
    }


    debugWnd.TryShowWindow("ShowXinputInfo",        debugWnd.ShowXinputInfoWindow);
    debugWnd.TryShowWindow("ShowXinputState",       debugWnd.ShowXinputStateWindow);
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