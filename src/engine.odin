/*
 *  @Name:     engine
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 04-05-2017 15:13:05
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 25-10-2017 22:51:03
 *  
 *  @Description:
 *      Contains the engine context.
 */
import "core:math.odin";
import "input.odin";
import "time.odin";
import "renderer.odin";
import imgui "mantle:libbrew/brew_imgui.odin";

Context :: struct {
    settings             : ^Setting,
    input                : ^input.Input,
    virtual_screen       : ^renderer.VirtualScreen,
    //win32                : ^p32.Data_t,
    imgui_state          : ^imgui.State,
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
    ctx.virtual_screen = renderer.create_virtual_screen(1920, 1080);
    //ctx.win32          = new(p32.Data_t);
    ctx.imgui_state    = new(imgui.State);
    ctx.time           = time.create_data();

    return ctx;
}

create_default_context :: proc() -> ^Context {
    ctx := create_context();

    ctx.adaptive_vsync = true;
    ctx.settings.program_running = true;
    ctx.settings.show_debug_menu = true;
    ctx.settings.show_cursor = true;

    return ctx;
}