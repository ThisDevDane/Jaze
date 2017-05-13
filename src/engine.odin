#import "math.odin";

#import "render.odin";
#import "main.odin";
#import "input.odin";
#import "jimgui.odin";
#import "time.odin";
#import "renderer.odin";
#import p32 "platform_win32.odin";

Context_t :: struct {
    Settings           : ^Setting_t,
    Input              : ^input.Input_t,
    VirtualScreen      : ^render.VirtualScreen_t,
    Win32              : ^p32.Data_t,
    ImguiState         : ^jimgui.State_t,
    Time               : ^time.Data_t,
    RenderState        : ^renderer.State_t,

    AdaptiveVSync      : bool,
    ScaleFactor        : math.Vec2,
    GameDrawRegion     : render.DrawRegion,
    WindowSize         : math.Vec2,
}

Setting_t :: struct {
    ShowCursor         : bool,
    ShowDebugMenu      : bool,
    ProgramRunning     : bool,
}

CreateContext :: proc() -> ^Context_t {
    ctx              := new(Context_t);
    ctx.Input         = new(input.Input_t);
    ctx.Settings      = new(Setting_t);
    ctx.VirtualScreen = render.CreateVirtualScreen(1920, 1080);
    ctx.Win32         = new(p32.Data_t);
    ctx.ImguiState    = new(jimgui.State_t);
    ctx.Time          = time.CreateData();

    return ctx;
}

SetContextDefaults :: proc(ctx : ^Context_t) {
    ctx.AdaptiveVSync = true;
    ctx.Settings.ProgramRunning = true;
    ctx.Settings.ShowDebugMenu = true;
    ctx.Settings.ShowCursor = true;
}