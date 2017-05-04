#import win32 "sys/windows.odin" when ODIN_OS == "windows";
#import win32wgl "sys/wgl.odin" when ODIN_OS == "windows";
#import "fmt.odin";
#import "strings.odin";
#import "math.odin";

#import "imgui.odin";
#import "jwin32.odin";
#import "gl.odin";
#import "debug.odin";
#import "jimgui.odin";
#import "xinput.odin";
#import "render.odin";
#import "time.odin";
#import "catalog.odin";
#import "console.odin";
#import "entity.odin";
#import "input.odin";
#import "engine.odin";
#import "game.odin";
#import wgl "jwgl.odin";
#import debugWnd "debug_windows.odin";
#import p32 "platform_win32.odin";


CalculateViewport :: proc(newSize : math.Vec2, targetAspectRatio : f32) -> render.DrawRegion {
    res : render.DrawRegion;
    res.Width = i32(newSize.x);
    res.Height = i32(f32(res.Width) / targetAspectRatio + 0.5);

    if i32(newSize.y) < res.Height {
        res.Height = i32(newSize.y);
        res.Width = i32(f32(res.Height) * targetAspectRatio + 0.5);
    }

    res.X = (i32(newSize.x) / 2) - (res.Width / 2);
    res.Y = (i32(newSize.y) / 2) - (res.Height / 2);
    return res;
}

OpenGLDebugCallback :: proc(source : gl.DebugSource, type : gl.DebugType, id : i32, severity : gl.DebugSeverity, length : i32, message : ^byte, userParam : rawptr) #cc_c {
    console.Log("[%v | %v | %v] %s \n", source, type, severity, strings.to_odin_string(message));
}

MessageLoop :: proc(ctx : ^engine.Context_t){
    msg : win32.Msg;
    for win32.PeekMessageA(&msg, nil, 0, 0, win32.PM_REMOVE) == win32.TRUE {
        match msg.message {
            case win32.WM_QUIT : {
                ctx.Settings.ProgramRunning = false;
            }

            case win32.WM_SYSKEYDOWN : {
                if win32.Key_Code(msg.wparam) == win32.Key_Code.RETURN {
                    p32.ToggleBorderlessFullscreen(ctx.Win32.WindowHandle, &ctx.Win32.WindowPlacement);
                }

                if win32.Key_Code(msg.wparam) == win32.Key_Code.C {
                    debugWnd.ToggleWindow("ShowConsoleWindow");
                }

                if msg.wparam == 0xC0 {
                    ctx.Settings.ShowDebugMenu = !ctx.Settings.ShowDebugMenu;
                }
                continue;
            }

            case win32.WM_KEYDOWN : {
                if win32.Key_Code(msg.wparam) == win32.Key_Code.ESCAPE {
                    win32.PostQuitMessage(0);
                }
            } 

            case win32.WM_CHAR : {
                imgui.GuiIO_AddInputCharacter(u16(msg.wparam)); 
                input.AddCharToQueue(ctx.Input, rune(msg.wparam));
            }
            break;

            case win32.WM_MOUSEWHEEL : {
                delta := i16(win32.HIWORD(msg.wparam));
                if(delta > 1) {
                    ctx.ImguiState.MouseWheelDelta += 1;
                }
                if(delta < 1) {
                    ctx.ImguiState.MouseWheelDelta -= 1;
                }
            } 


        }

        win32.TranslateMessage(&msg);
        win32.DispatchMessageA(&msg);
    }
}

UpdateWindowSize :: proc(ctx : ^engine.Context_t) {
    rect : win32.Rect;
    win32.GetClientRect(ctx.Win32.WindowHandle, &rect);
    ctx.WindowSize.x = f32(rect.right);
    ctx.WindowSize.y = f32(rect.bottom);
}

ClearScreen :: proc(ctx : ^engine.Context_t) {
    gl.Scissor(0, 0, i32(ctx.WindowSize.x), i32(ctx.WindowSize.y));
    gl.ClearColor(0, 0, 0, 1);
    gl.Clear(gl.ClearFlags.COLOR_BUFFER);
}

ClearGameScreen :: proc(ctx : ^engine.Context_t) {
        gl.Scissor(ctx.GameDrawRegion.X, 
                   ctx.GameDrawRegion.Y, 
                   ctx.GameDrawRegion.Width, 
                   ctx.GameDrawRegion.Height);

        gl.ClearColor(1, 0, 1, 1);
        gl.Clear(gl.ClearFlags.COLOR_BUFFER);
}

main :: proc() {
    EngineContext := engine.CreateContext();
    engine.SetContextDefaults(EngineContext);

    input.AddBinding(EngineContext.Input, "Fire", win32.Key_Code.LBUTTON);
    input.AddBinding(EngineContext.Input, "Zoom", win32.Key_Code.RBUTTON);
    input.AddBinding(EngineContext.Input, "Build", win32.Key_Code.B);

    {
        EngineContext.Win32.WindowPlacement.length = size_of(win32.Window_Placement);
        EngineContext.Win32.AppHandle = win32.GetModuleHandleA(nil);
        EngineContext.Win32.WindowHandle = p32.CreateWindow(EngineContext.Win32.AppHandle, math.Vec2{1280, 720}); 
        EngineContext.Win32.DeviceCtx = win32.GetDC(EngineContext.Win32.WindowHandle);
        EngineContext.Win32.Ogl.VersionMajorMax, EngineContext.Win32.Ogl.VersionMinorMax = p32.GetMaxGLVersion();
        EngineContext.Win32.Ogl.Ctx = p32.CreateOpenGLContext(EngineContext.Win32.DeviceCtx, true);
    }
    {
        gl.Init();
        gl.DebugMessageCallback(OpenGLDebugCallback, nil);
        gl.Enable(gl.Capabilities.DebugOutputSynchronous);
        gl.DebugMessageControl(gl.DebugSource.DontCare, gl.DebugType.DontCare, gl.DebugSeverity.Notification, 0, nil, false);
        gl.GetInfo(&EngineContext.Win32.Ogl);
        wgl.GetInfo(&EngineContext.Win32.Ogl, EngineContext.Win32.DeviceCtx);
    }

    jimgui.Init(EngineContext);

    wgl.SwapIntervalEXT(-1);
    xinput.Init();
    xinput.Enable(true);
    //soundCat, _   := catalog.CreateNew(catalog.Kind.Sound,   "data/sounds/",   ".ogg");
    shaderCat, _  := catalog.CreateNew(catalog.Kind.Shader,  "data/shaders/",  ".frag,.vert");
    textureCat, _ := catalog.CreateNew(catalog.Kind.Texture, "data/textures/", ".png,.jpg,.jpeg");

    render.Init(shaderCat, textureCat);

    console.AddCommand("Help", console.DefaultHelpCommand);
    console.AddCommand("Clear", console.DefaultClearCommand);

    GameContext := new(game.Context_t);
    GameContext.EntityList = entity.MakeList();

    e := entity.CreateTower();
    entity.AddEntity(GameContext.EntityList, entity.CreateEntity());
    entity.AddEntity(GameContext.EntityList, entity.CreateTower());
    entity.AddEntity(GameContext.EntityList, entity.CreateTower());
    entity.AddEntity(GameContext.EntityList, entity.CreateSlowTower());
    entity.AddEntity(GameContext.EntityList, entity.CreateTower());
    entity.AddEntity(GameContext.EntityList, e);
    entity.AddEntity(GameContext.EntityList, entity.CreateEntity());
    entity.RemoveEntity(GameContext.EntityList, e);

    for EngineContext.Settings.ProgramRunning {
        MessageLoop(EngineContext);
        
        time.Update(EngineContext.Time);
        if win32.GetActiveWindow() == EngineContext.Win32.WindowHandle {
            input.Update(EngineContext.Input);
            input.UpdateMousePosition(EngineContext.Input, EngineContext.Win32.WindowHandle);
        } else {
            input.SetAllInputNeutral(EngineContext.Input);
        }
        UpdateWindowSize(EngineContext);
        

        p32.ChangeWindowTitle(EngineContext.Win32.WindowHandle, 
                          "Jaze - DEV VERSION | <%.1f, %.1f> | <%d, %d, %d, %d>", // <%.0f, %.0f> misses a number, tell bill
                          EngineContext.WindowSize.x, EngineContext.WindowSize.y,
                          EngineContext.GameDrawRegion.X, EngineContext.GameDrawRegion.Y,
                          EngineContext.GameDrawRegion.Width, EngineContext.GameDrawRegion.Height);



        EngineContext.GameDrawRegion = CalculateViewport(EngineContext.WindowSize, EngineContext.VirtualScreen.AspectRatio);
        EngineContext.ScaleFactor.x = EngineContext.WindowSize.x / f32(EngineContext.VirtualScreen.Dimension.x);
        EngineContext.ScaleFactor.y = EngineContext.WindowSize.y / f32(EngineContext.VirtualScreen.Dimension.y);
        ClearScreen(EngineContext);
        gl.Viewport(EngineContext.GameDrawRegion.X, 
                    EngineContext.GameDrawRegion.Y, 
                    EngineContext.GameDrawRegion.Width,
                    EngineContext.GameDrawRegion.Height);
        ClearGameScreen(EngineContext);
        gl.Clear(gl.ClearFlags.DEPTH_BUFFER);


        render.Draw(EngineContext);
        
        if EngineContext.Settings.ShowDebugMenu {
            jimgui.BeginNewFrame(EngineContext.Time.UnscaledDeltaTime, EngineContext);
            debug.RenderDebugUI(EngineContext, GameContext);
            jimgui.RenderProc(EngineContext);
        }

        win32.SwapBuffers(EngineContext.Win32.DeviceCtx);
    }
}