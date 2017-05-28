/*
 *  @Name:     main
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 10-05-2017 21:11:30
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 28-05-2017 17:31:15
 *  
 *  @Description:
 *      The main file for Jaze.
 */

#import "fmt.odin";
#import "strings.odin";
#import "math.odin";

#import "imgui.odin";
#import "gl.odin";
#import "debug.odin";
#import "jimgui.odin";
#import "xinput.odin";
#import "time.odin";
#import "catalog.odin";
#import "console.odin";
#import "path.odin";
#import "entity.odin";
#import "input.odin";
#import "engine.odin";
#import "game.odin";
#import "jmap.odin";
#import "render_queue.odin";
#import "renderer.odin";
#import store "key_value_store.odin";
#import ja "asset.odin";
#import wgl "jwgl.odin";
#import debugWnd "debug_windows.odin";
#import p32 "platform_win32.odin";

calculate_viewport :: proc(newSize : math.Vec2, targetAspectRatio : f32) -> renderer.DrawRegion {
    res : renderer.DrawRegion;
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

opengl_debug_callback :: proc(source : gl.DebugSource, type : gl.DebugType, id : i32, severity : gl.DebugSeverity, length : i32, message : ^byte, userParam : rawptr) #cc_c {
    console.log("[%v | %v | %v] %s \n", source, type, severity, strings.to_odin_string(message));
}

clear_screen :: proc(ctx : ^engine.Context) {
    gl.Scissor(0, 0, i32(ctx.window_size.x), i32(ctx.window_size.y));
    gl.ClearColor(0, 0, 0, 1);
    gl.Clear(gl.ClearFlags.COLOR_BUFFER);
}

clear_game_screen :: proc(ctx : ^engine.Context) {
        gl.Scissor(ctx.game_draw_region.X, 
                   ctx.game_draw_region.Y, 
                   ctx.game_draw_region.Width, 
                   ctx.game_draw_region.Height);

        gl.ClearColor(1, 0, 1, 1);
        gl.Clear(gl.ClearFlags.COLOR_BUFFER);
}

main :: proc() {
    EngineContext := engine.create_context();
    engine.set_context_defaults(EngineContext);

    {
        EngineContext.win32.AppHandle = p32.GetProgramHandle();
        EngineContext.win32.WindowHandle = p32.CreateWindow(EngineContext.win32.AppHandle, 
                                                            math.Vec2{1280, 720}); 
        EngineContext.win32.DeviceCtx = p32.GetDC(EngineContext.win32.WindowHandle);
        EngineContext.win32.Ogl.VersionMajorMax, EngineContext.win32.Ogl.VersionMinorMax = p32.GetMaxGLVersion();
        EngineContext.win32.Ogl.Ctx = p32.CreateOpenGLContext(EngineContext.win32.DeviceCtx, true, 3, 3);
    }
    {
        gl.Init();
        gl.DebugMessageCallback(opengl_debug_callback, nil);
        gl.Enable(gl.Capabilities.DebugOutputSynchronous);
        gl.DebugMessageControl(gl.DebugSource.DontCare, gl.DebugType.DontCare, gl.DebugSeverity.Notification, 0, nil, false);
        gl.GetInfo(&EngineContext.win32.Ogl);
        wgl.GetInfo(&EngineContext.win32.Ogl, EngineContext.win32.DeviceCtx);
    }

    jimgui.init(EngineContext);

    wgl.SwapIntervalEXT(-1);
    xinput.Init(true);

    shaderCat, _  := catalog.create_new(catalog.Kind.Shader,  "data/shaders/",  ".frag,.vert");
    textureCat, _ := catalog.create_new(catalog.Kind.Texture, "data/textures/", ".png,.jpg,.jpeg");
    mapCat, _ := catalog.create_new(catalog.Kind.Texture, "data/maps/", ".png");

    EngineContext.render_state = renderer.Init(shaderCat);

    console.add_default_commands();

    GameContext    := game.create_context();
    mapTex, _      := catalog.find(mapCat, "map2");
    GameContext.map_ = jmap.CreateMap(mapTex.(^ja.Asset.Texture), textureCat);

    hover, _ := catalog.find(textureCat, "towerDefense_tile016");
    GameContext.build_hover_texture = hover.(^ja.Asset.Texture);

    game.setup_bindings(EngineContext.input);
    game.upload_tower_textures(GameContext, textureCat);

    for EngineContext.settings.program_running {
        p32.MessageLoop(EngineContext);
        gl.DebugInfo.DrawCalls = 0;
        
        time.update(EngineContext.time);
        if p32.IsWindowActive(EngineContext.win32.WindowHandle) {
            input.update(EngineContext.input);
            input.update_mouse_position(EngineContext.input, EngineContext.win32.WindowHandle);
        } else {
            input.set_input_neutral(EngineContext.input);
        }
        EngineContext.window_size = p32.GetWindowSize(EngineContext.win32.WindowHandle);
        
        p32.ChangeWindowTitle(EngineContext.win32.WindowHandle, 
                          "Jaze - DEV VERSION | <%.0f, %.0f> | <%d, %d, %d, %d>",
                          EngineContext.window_size.x, EngineContext.window_size.y,
                          EngineContext.game_draw_region.X, EngineContext.game_draw_region.Y,
                          EngineContext.game_draw_region.Width, EngineContext.game_draw_region.Height);



        EngineContext.game_draw_region = calculate_viewport(EngineContext.window_size,
                                                            EngineContext.virtual_screen.AspectRatio);
        EngineContext.scale_factor.x = EngineContext.window_size.x / f32(EngineContext.virtual_screen.Dimension.x);
        EngineContext.scale_factor.y = EngineContext.window_size.y / f32(EngineContext.virtual_screen.Dimension.y);
        clear_screen(EngineContext);
        gl.Viewport(EngineContext.game_draw_region.X, 
                    EngineContext.game_draw_region.Y, 
                    EngineContext.game_draw_region.Width,
                    EngineContext.game_draw_region.Height);
        clear_game_screen(EngineContext);
        gl.Clear(gl.ClearFlags.DEPTH_BUFFER);
        jimgui.begin_new_frame(EngineContext.time.unscaled_delta_time, EngineContext);

        game.input_logic(EngineContext, GameContext);
        jmap.DrawMap(GameContext.map_, GameContext.map_render_queue, GameContext.build_mode);
        if GameContext.build_mode {
            game.build_mode_logic(EngineContext, GameContext);
        }
        
        entity.DrawTowers(EngineContext, GameContext, GameContext.tower_render_queue);

        {
            SendSquare :: proc(pos : math.Vec3, col : math.Vec4, queue : ^render_queue.Queue) {
                cmd := renderer.Command.Rect{};
                cmd.RenderPos = pos;
                cmd.Scale = math.Vec3{1, 1, 1};
                cmd.Rotation = 0;        
                cmd.Color = col;
                render_queue.Enqueue(queue, cmd);
            }
            s := GameContext.map_.StartTile;
            e := GameContext.map_.EndTile;
            SendSquare(math.Vec3{s.Pos.x, s.Pos.y,-14}, math.Vec4{0, 0, 1, 0.5}, GameContext.debug_render_queue);
            SendSquare(math.Vec3{e.Pos.x, e.Pos.y,-14}, math.Vec4{0, 0, 1, 0.5}, GameContext.debug_render_queue);
    
            p := path.Find(GameContext.map_, s, e);
        }

        renderer.RenderQueue(EngineContext, GameContext.game_camera, GameContext.map_render_queue);
        renderer.RenderQueue(EngineContext, GameContext.game_camera, GameContext.tower_render_queue);
        renderer.RenderQueue(EngineContext, GameContext.game_camera, GameContext.enemy_render_queue);
        renderer.RenderQueue(EngineContext, GameContext.game_camera, GameContext.debug_render_queue);
        
        if EngineContext.settings.show_debug_menu {
            debug.render_debug_ui(EngineContext, GameContext);
            jimgui.render_proc(EngineContext);
        }

        p32.SwapBuffers(EngineContext.win32.DeviceCtx);
    }
}