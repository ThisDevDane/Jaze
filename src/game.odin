/*
 *  @Name:     game
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 04-05-2017 15:53:25
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 28-05-2017 20:10:14
 *  
 *  @Description:
 *      Contains the Game Context.
 *      Also contains functions for "game" logic and drawing.
 */
#import win32 "sys/windows.odin";
#import "math.odin";

#import "entity.odin";
#import "jmap.odin";
#import "renderer.odin";
#import "render_queue.odin";
#import "engine.odin";
#import "catalog.odin";
#import "input.odin";
#import "console.odin";
#import ja "asset.odin";

Context :: struct {
    entity_list : ^entity.List,
    map_        : ^jmap.Data_t,
    game_camera : ^renderer.Camera_t,

    map_render_queue   : ^render_queue.Queue,
    tower_render_queue : ^render_queue.Queue,
    enemy_render_queue : ^render_queue.Queue,
    debug_render_queue : ^render_queue.Queue,
    
    build_mode  : bool,
    build_hover_texture : ^ja.Asset.Texture,

    tower_basic_bottom_texture : ^ja.Asset.Texture, 
    tower_basic_top_texture : ^ja.Asset.Texture, 
}

_CAMERA_SPEED :: 5;
_CAMERA_SPEED_FAST :: 10;
_CAMERA_ZOOM_SPEED :: 30;
_MAX_CAMERA_ZOOM :: 100;
_MIN_CAMERA_ZOOM :: 30;

create_context :: proc() -> ^Context {
    ctx := new(Context);
    
    ctx.map_render_queue   = render_queue.Make();
    ctx.tower_render_queue = render_queue.Make();
    ctx.enemy_render_queue = render_queue.Make();
    ctx.debug_render_queue = render_queue.Make();
    ctx.entity_list       = entity.MakeList();

    ctx.game_camera      = new(renderer.Camera_t);
    ctx.game_camera.Pos  = math.Vec3{0, 0, 15};
    ctx.game_camera.Zoom = 50;
    ctx.game_camera.Near = 0.1;
    ctx.game_camera.Far  = 50;
    ctx.game_camera.Rot  = 45;

    return ctx;
}

upload_tower_textures :: proc(ctx : ^Context, textureCat : ^catalog.Catalog) {
    t, _ := catalog.find(textureCat, "towerDefense_tile249");
    ctx.tower_basic_top_texture = t.(^ja.Asset.Texture); 
    t, _ = catalog.find(textureCat, "towerDefense_tile180");
    ctx.tower_basic_bottom_texture = t.(^ja.Asset.Texture); 
}

setup_bindings :: proc(input_ : ^input.Input) {
    input.add_binding(input_, "CameraUp",       win32.KeyCode.W);
    input.add_binding(input_, "CameraLeft",     win32.KeyCode.A);
    input.add_binding(input_, "CameraRight",    win32.KeyCode.D);
    input.add_binding(input_, "CameraDown",     win32.KeyCode.S);
    input.add_binding(input_, "CameraZoomIn",   win32.KeyCode.E);
    input.add_binding(input_, "CameraZoomOut",  win32.KeyCode.Q);
    input.add_binding(input_, "CameraFastMov",  win32.KeyCode.Shift);

    input.add_binding(input_, "ToggleBuild",  win32.KeyCode.B);
    input.add_binding(input_, "Build",  win32.KeyCode.Lbutton);
}

camera_logic :: proc(ctx : ^engine.Context, camera : ^renderer.Camera_t) {
    dir := math.Vec3{0, 0, 0};
    if input.is_button_held(ctx.input, "CameraUp") {
        dir += math.Vec3{0, 1, 0};
    }
    if input.is_button_held(ctx.input, "CameraLeft") {
        dir += math.Vec3{-1, 0, 0};
    }
    if input.is_button_held(ctx.input, "CameraRight") {
        dir += math.Vec3{1, 0, 0};
    }
    if input.is_button_held(ctx.input, "CameraDown") {
        dir += math.Vec3{0, -1, 0};
    }

    zoom := 0;
    if input.is_button_held(ctx.input, "CameraZoomIn") {
        zoom++;
    }
    if input.is_button_held(ctx.input, "CameraZoomOut") {
        zoom--;
    }

    camera.Zoom += (f32(zoom) * _CAMERA_ZOOM_SPEED) * f32(ctx.time.delta_time);
    if camera.Zoom > _MAX_CAMERA_ZOOM {
        camera.Zoom = _MAX_CAMERA_ZOOM;
    } else if camera.Zoom < _MIN_CAMERA_ZOOM {
        camera.Zoom = _MIN_CAMERA_ZOOM;
    }

    speed : f32 = input.is_button_held(ctx.input, "CameraFastMov") ? _CAMERA_SPEED_FAST : _CAMERA_SPEED;
    camera.Pos += (dir * speed) * f32(ctx.time.delta_time);
}

input_logic :: proc(ctx : ^engine.Context, gCtx : ^Context) {
    camera_logic(ctx, gCtx.game_camera);

    if input.is_button_down(ctx.input, "ToggleBuild") {
        gCtx.build_mode = !gCtx.build_mode;
    }
}

build_mode_logic :: proc(ctx : ^engine.Context, gCtx : ^Context) {
    view := renderer.CreateViewMatrixFromCamera(gCtx.game_camera);
    proj := renderer.CalculateOrtho(ctx.window_size, 
                                    ctx.scale_factor, 
                                    gCtx.game_camera.Far, 
                                    gCtx.game_camera.Near);
    wp := renderer.ScreenToWorld(ctx.input.mouse_pos, 
                                 proj, view, 
                                 ctx.game_draw_region, 
                                 gCtx.game_camera) + 0.5;

    withinMap := wp.x >= 0 && 
                 wp.y >= 0 && 
                 wp.x < f32(gCtx.map_.Width) && 
                 wp.y < f32(gCtx.map_.Height);

    if withinMap {
        wp.x = f32(int(wp.x));
        wp.y = f32(int(wp.y));
        wp.z = -4;

        if jmap.TileIsBuildable(gCtx.map_, math.Vec2{wp.x, wp.y}) && 
           !gCtx.map_.Occupied[int(wp.y)][int(wp.x)] {
                cmd := renderer.Command.Bitmap{};
                cmd.RenderPos = wp;
                cmd.Scale = math.Vec3{1, 1, 1};
                cmd.Rotation = 0;
                cmd.Texture = gCtx.build_hover_texture;
                render_queue.Enqueue(gCtx.map_render_queue, cmd);
        }
    }

    if input.is_button_down(ctx.input, "Build") && withinMap {
        if jmap.TileIsBuildable(gCtx.map_, math.Vec2{wp.x, wp.y}) && 
           !gCtx.map_.Occupied[int(wp.y)][int(wp.x)] {
            console.log("Build at %v", wp);
            e := entity.CreateTower();
            e.(^entity.Entity.Tower).T.Position = math.Vec3{wp.x, wp.y, -1};
            gCtx.map_.Occupied[int(wp.y)][int(wp.x)] = true;
            entity.AddEntity(gCtx.entity_list, e);
        }
    }
}