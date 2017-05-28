/*
 *  @Name:     debug
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 10-05-2017 21:11:30
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 28-05-2017 16:52:26
 *  
 *  @Description:
 *      Contains all the debug menu stuff related to the Menu bar.
 *      Also contains the function to try and render debug windows.
 */
#import win32 "sys/windows.odin";
#import "jwin32.odin";
#import debug_wnd "debug_windows.odin";
#import "imgui.odin";
#import "main.odin";
#import "console.odin";
#import "engine.odin";
#import "game.odin";
#import wgl "jwgl.odin";

render_debug_ui :: proc(ctx : ^engine.Context, gameCtx : ^game.Context) {
   make_menu_bar(ctx);
   try_to_render_windows(ctx, gameCtx);
}

make_menu_bar :: proc(ctx : ^engine.Context) {
     make_menu_item :: proc(title : string, id : string) {
        make_menu_item(title, "", id);
    }

    make_menu_item :: proc(title : string, shortcut : string, id : string) {
        if imgui.MenuItem(title, shortcut, false, true) {
            debug_wnd.toggle_window_state(id);
        }
    }

    imgui.PushStyleColor(imgui.GuiCol.MenuBarBg, imgui.Vec4{0.35, 0.35, 0.35, 0.78});
    imgui.BeginMainMenuBar();

    if imgui.BeginMenu("Game", true) {
        make_menu_item("Entity List", "ShowEntityList");
        make_menu_item("Game Info", "ShowGameInfo");
        imgui.EndMenu();
    }
   
    if imgui.BeginMenu("Data", true) {
        make_menu_item("OpenGL Info", "ShowOpenGLInfo");
        make_menu_item("Win32Var Info", "ShowWin32VarInfo");
        make_menu_item("Time Data", "ShowTimeData");
        make_menu_item("Engine Info", "ShowEngineInfo");
        imgui.EndMenu();
    }

    if imgui.BeginMenu("Input", true) {
        make_menu_item("Keyboard & Mouse", "ShowInputWindow");
        if imgui.BeginMenu("XInput", true) {
            make_menu_item("Info", "ShowXinputInfo");
            make_menu_item("State", "ShowXinputState");
            imgui.EndMenu();
        }
        imgui.EndMenu();
    }

    if imgui.BeginMenu("Asset", true) {
        make_menu_item("Catalogs", "ShowCatalogWindow");
        imgui.EndMenu();
    }

    if imgui.BeginMenu("Visual", true) {
        if imgui.Checkbox("Adaptive VSync", &ctx.adaptive_vsync) {
            if ctx.adaptive_vsync {
                wgl.SwapIntervalEXT(-1);
            } else {
                wgl.SwapIntervalEXT(0);
            }
        }
        {
            b := debug_wnd.get_window_state("ShowStatOverlay");
            if imgui.Checkbox("Stat Overlay", &b) {
                debug_wnd.set_window_state("ShowStatOverlay", b);
            }
        }

        if imgui.Checkbox("Hardware Cursor", &ctx.settings.show_cursor) {
            win32.ShowCursor(win32.Bool(ctx.settings.show_cursor));
        }
        
        imgui.EndMenu();
    }

    if imgui.BeginMenu("Misc", true) {
        make_menu_item("Console", "Alt+C", "ShowConsoleWindow");
        make_menu_item("Debug Window States", "ShowDebugWindowStates");
        make_menu_item("Show Test Window", "ShowTestWindow");

        imgui.Separator();
        imgui.MenuItem("Toggle Fullscreen", "Alt+Enter", false, false);

        
        if imgui.MenuItem("Exit", "Escape", false, true) {
            ctx.settings.program_running = false;
        }
        imgui.EndMenu();
    }
    imgui.EndMainMenuBar();
    imgui.PopStyleColor(1);
}

try_to_render_windows :: proc(ctx : ^engine.Context, gameCtx : ^game.Context) {
    if debug_wnd.get_window_state("ShowOpenGLInfo") {
        b := debug_wnd.get_window_state("ShowOpenGLInfo");
        debug_wnd.opengl_info(&ctx.win32.Ogl, &b);
        debug_wnd.set_window_state("ShowOpenGLInfo", b);
    }

    if debug_wnd.get_window_state("ShowInputWindow") {
        b := debug_wnd.get_window_state("ShowInputWindow");
        debug_wnd.show_input_window(ctx.input, &b);
        debug_wnd.set_window_state("ShowInputWindow", b);
    }

    if debug_wnd.get_window_state("ShowWin32VarInfo") {
        b := debug_wnd.get_window_state("ShowWin32VarInfo");
        debug_wnd.show_struct_info("Win32 Info", &b, ctx.win32^);;
        debug_wnd.set_window_state("ShowWin32VarInfo", b);
    }

    if debug_wnd.get_window_state("ShowEntityList") {
        b := debug_wnd.get_window_state("ShowEntityList");
        debug_wnd.show_entity_list(gameCtx, &b);
        debug_wnd.set_window_state("ShowEntityList", b);
    }

        if debug_wnd.get_window_state("ShowGameInfo") {
        b := debug_wnd.get_window_state("ShowGameInfo");
        debug_wnd.show_struct_info("Game Info", &b, gameCtx^);
        debug_wnd.set_window_state("ShowGameInfo", b);
    }

    if debug_wnd.get_window_state("ShowTimeData") {
        b := debug_wnd.get_window_state("ShowTimeData");
        debug_wnd.show_struct_info("Time", &b, ctx.time^);
        debug_wnd.set_window_state("ShowTimeData", b);
    }

    if debug_wnd.get_window_state("ShowEngineInfo") {
        b := debug_wnd.get_window_state("ShowEngineInfo");
        debug_wnd.show_struct_info("Engine Info", &b, ctx^);
        debug_wnd.set_window_state("ShowEngineInfo", b);
    }


    debug_wnd.try_show_window("ShowXinputInfo",        debug_wnd.show_xinput_info_window);
    debug_wnd.try_show_window("ShowXinputState",       debug_wnd.show_xinput_state_window);
    debug_wnd.try_show_window("ShowCatalogWindow",     debug_wnd.show_catalog_window);
    debug_wnd.try_show_window("ShowDebugWindowStates", debug_wnd.show_debug_windows_states);
    debug_wnd.try_show_window("ShowStatOverlay",       debug_wnd.stat_overlay);
    debug_wnd.try_show_window("ShowConsoleWindow",     console.draw_console);
    debug_wnd.try_show_window("ShowLogWindow",         console.draw_log);

    if debug_wnd.get_window_state("ShowTestWindow") {
        b := debug_wnd.get_window_state("ShowTestWindow");
        imgui.ShowTestWindow(&b);
        debug_wnd.set_window_state("ShowTestWindow", b);
    }
}