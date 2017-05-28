/*
 *  @Name:     engine
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 04-05-2017 15:13:05
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 28-05-2017 17:32:55
 *  
 *  @Description:
 *      Contains the engine context.
 */
#import "math.odin";

#import "main.odin";
#import "input.odin";
#import "jimgui.odin";
#import "time.odin";
#import "renderer.odin";
#import p32 "platform_win32.odin";

Context :: struct {
    settings             : ^Setting,
    input                : ^input.Input,
    virtual_screen       : ^renderer.VirtualScreen_t,
    win32                : ^p32.Data_t,
    imgui_state          : ^jimgui.State,
    time                 : ^time.Data,
    render_state         : ^renderer.State_t,

    adaptive_vsync       : bool,
    scale_factor         : math.Vec2,
    game_draw_region     : renderer.DrawRegion,
    window_size          : math.Vec2,
}

Setting :: struct {
    show_cursor         : bool,
    show_debug_menu      : bool,
    program_running     : bool,
}

create_context :: proc() -> ^Context {
    ctx               := new(Context);
    ctx.input          = new(input.Input);
    ctx.settings       = new(Setting);
    ctx.virtual_screen = renderer.CreateVirtualScreen(1920, 1080);
    ctx.win32          = new(p32.Data_t);
    ctx.imgui_state    = new(jimgui.State);
    ctx.time           = time.create_data();

    return ctx;
}

set_context_defaults :: proc(ctx : ^Context) {
    ctx.adaptive_vsync = true;
    ctx.settings.program_running = true;
    ctx.settings.show_debug_menu = true;
    ctx.settings.show_cursor = true;
}