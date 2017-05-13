//#import win32 "sys/windows.odin" when ODIN_OS == "windows";
//#import win32wgl "sys/wgl.odin" when ODIN_OS == "windows";
#import "fmt.odin";
#import "strings.odin";
#import "math.odin";

#import "imgui.odin";
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
#import "jmap.odin";
#import "render_queue.odin";
#import "renderer.odin";
#import ja "asset.odin";
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

//    input.AddBinding(EngineContext.Input, "Fire", win32.Key_Code.LBUTTON);
//    input.AddBinding(EngineContext.Input, "Zoom", win32.Key_Code.RBUTTON);
//    input.AddBinding(EngineContext.Input, "Build", win32.Key_Code.B);

    {
       // EngineContext.Win32.WindowPlacement.length = size_of(win32.Window_Placement);
        EngineContext.Win32.AppHandle = p32.GetProgramHandle();
        EngineContext.Win32.WindowHandle = p32.CreateWindow(EngineContext.Win32.AppHandle, math.Vec2{1280, 720}); 
        EngineContext.Win32.DeviceCtx = p32.GetDC(EngineContext.Win32.WindowHandle);
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
    mapCat, _ := catalog.CreateNew(catalog.Kind.Texture, "data/maps/", ".png");

    render.Init(shaderCat, textureCat);
    EngineContext.RenderState = renderer.Init(shaderCat);

    console.AddCommand("Help", console.DefaultHelpCommand);
    console.AddCommand("Clear", console.DefaultClearCommand);

    GameContext := new(game.Context_t);
    GameContext.EntityList = entity.MakeList();
    GameContext.Map = jmap.CreateMap(20, 10, textureCat);
    camera := new(renderer.Camera_t);
    camera.Pos = math.Vec3{0, 0, 15};
    camera.Zoom = 50;
    camera.Near = 0.1;
    camera.Far = 50;
    camera.Rot = 45;
    GameContext.GameCamera = camera;

    game.SetupCameraBindings(EngineContext.Input);

    entity.AddEntity(GameContext.EntityList, entity.CreateSlowTower());

    for EngineContext.Settings.ProgramRunning {
        p32.MessageLoop(EngineContext);
        
        time.Update(EngineContext.Time);
        if p32.IsWindowActive(EngineContext.Win32.WindowHandle) {
            input.Update(EngineContext.Input);
            input.UpdateMousePosition(EngineContext.Input, EngineContext.Win32.WindowHandle);
        } else {
            input.SetAllInputNeutral(EngineContext.Input);
        }
        EngineContext.WindowSize = p32.GetWindowSize(EngineContext.Win32.WindowHandle);
        
        p32.ChangeWindowTitle(EngineContext.Win32.WindowHandle, 
                          "Jaze - DEV VERSION | <%.0f, %.0f> | <%d, %d, %d, %d>",
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

        game.CameraLogic(EngineContext, GameContext.GameCamera);


        queue := jmap.DrawMap(GameContext.Map);
        renderer.RenderQueue(EngineContext, GameContext.GameCamera, queue);
        render.Draw(EngineContext);
        
        if EngineContext.Settings.ShowDebugMenu {
            jimgui.BeginNewFrame(EngineContext.Time.UnscaledDeltaTime, EngineContext);
            debug.RenderDebugUI(EngineContext, GameContext);
            jimgui.RenderProc(EngineContext);
        }

        p32.SwapBuffers(EngineContext.Win32.DeviceCtx);
    }
}