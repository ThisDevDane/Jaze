/*
 *  @Name:     game
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 04-05-2017 15:53:25
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 22-05-2017 01:01:37
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

Context_t :: struct {
    EntityList : ^entity.List,
    Map        : ^jmap.Data_t,
    GameCamera : ^renderer.Camera_t,

    MapRenderQueue   : ^render_queue.Queue,
    TowerRenderQueue : ^render_queue.Queue,
    EnemyRenderQueue : ^render_queue.Queue,
    DebugRenderQueue : ^render_queue.Queue,
    
    BuildMode  : bool,
    BuildHoverTexture : ^ja.Asset.Texture,

    TowerBasicBottomTexture : ^ja.Asset.Texture, 
    TowerBasicTopTexture : ^ja.Asset.Texture, 
}

_CAMERA_SPEED :: 5;
_CAMERA_SPEED_FAST :: 10;
_CAMERA_ZOOM_SPEED :: 0.5;
_MAX_CAMERA_ZOOM :: 100;
_MIN_CAMERA_ZOOM :: 30;

CreateContext :: proc() -> ^Context_t {
    ctx := new(Context_t);
    
    ctx.MapRenderQueue   = render_queue.Make();
    ctx.TowerRenderQueue = render_queue.Make();
    ctx.EnemyRenderQueue = render_queue.Make();
    ctx.DebugRenderQueue = render_queue.Make();
    ctx.EntityList       = entity.MakeList();

    ctx.GameCamera      = new(renderer.Camera_t);
    ctx.GameCamera.Pos  = math.Vec3{0, 0, 15};
    ctx.GameCamera.Zoom = 50;
    ctx.GameCamera.Near = 0.1;
    ctx.GameCamera.Far  = 50;
    ctx.GameCamera.Rot  = 45;

    return ctx;
}

UploadTowerTextures :: proc(ctx : ^Context_t, textureCat : ^catalog.Catalog) {
    t, _ := catalog.Find(textureCat, "towerDefense_tile249");
    ctx.TowerBasicTopTexture = t.(^ja.Asset.Texture); 
    t, _ = catalog.Find(textureCat, "towerDefense_tile180");
    ctx.TowerBasicBottomTexture = t.(^ja.Asset.Texture); 
}

SetupBindings :: proc(input_ : ^input.Input_t) {
    input.AddBinding(input_, "CameraUp",       win32.Key_Code.W);
    input.AddBinding(input_, "CameraLeft",     win32.Key_Code.A);
    input.AddBinding(input_, "CameraRight",    win32.Key_Code.D);
    input.AddBinding(input_, "CameraDown",     win32.Key_Code.S);
    input.AddBinding(input_, "CameraZoomIn",   win32.Key_Code.E);
    input.AddBinding(input_, "CameraZoomOut",  win32.Key_Code.Q);
    input.AddBinding(input_, "CameraFastMov",  win32.Key_Code.SHIFT);

    input.AddBinding(input_, "ToggleBuild",  win32.Key_Code.B);
    input.AddBinding(input_, "Build",  win32.Key_Code.LBUTTON);
}

CameraLogic :: proc(ctx : ^engine.Context_t, camera : ^renderer.Camera_t) {
    dir := math.Vec3{0, 0, 0};
    if input.IsButtonHeld(ctx.Input, "CameraUp") {
        dir += math.Vec3{0, 1, 0};
    }
    if input.IsButtonHeld(ctx.Input, "CameraLeft") {
        dir += math.Vec3{-1, 0, 0};
    }
    if input.IsButtonHeld(ctx.Input, "CameraRight") {
        dir += math.Vec3{1, 0, 0};
    }
    if input.IsButtonHeld(ctx.Input, "CameraDown") {
        dir += math.Vec3{0, -1, 0};
    }

    zoom := 0;
    if input.IsButtonHeld(ctx.Input, "CameraZoomIn") {
        zoom++;
    }
    if input.IsButtonHeld(ctx.Input, "CameraZoomOut") {
        zoom--;
    }

    camera.Zoom += (f32(zoom) * _CAMERA_ZOOM_SPEED) * f32(ctx.Time.DeltaTime);
    if camera.Zoom > _MAX_CAMERA_ZOOM {
        camera.Zoom = _MAX_CAMERA_ZOOM;
    } else if camera.Zoom < _MIN_CAMERA_ZOOM {
        camera.Zoom = _MIN_CAMERA_ZOOM;
    }

    speed : f32 = input.IsButtonHeld(ctx.Input, "CameraFastMov") ? _CAMERA_SPEED_FAST : _CAMERA_SPEED;
    camera.Pos += (dir * speed) * f32(ctx.Time.DeltaTime);
}

InputLogic :: proc(ctx : ^engine.Context_t, gCtx : ^Context_t) {
    CameraLogic(ctx, gCtx.GameCamera);

    if input.IsButtonDown(ctx.Input, "ToggleBuild") {
        gCtx.BuildMode = !gCtx.BuildMode;
    }
}

BuildModeLogic :: proc(ctx : ^engine.Context_t, gCtx : ^Context_t) {
    view := renderer.CreateViewMatrixFromCamera(gCtx.GameCamera);
    proj := renderer.CalculateOrtho(ctx.WindowSize, 
                                    ctx.ScaleFactor, 
                                    gCtx.GameCamera.Far, 
                                    gCtx.GameCamera.Near);
    wp := renderer.ScreenToWorld(ctx.Input.MousePos, 
                                 proj, view, 
                                 ctx.GameDrawRegion, 
                                 gCtx.GameCamera) + 0.5;

    withinMap := wp.x >= 0 && 
                 wp.y >= 0 && 
                 wp.x < f32(gCtx.Map.Width) && 
                 wp.y < f32(gCtx.Map.Height);

    if withinMap {
        wp.x = f32(int(wp.x));
        wp.y = f32(int(wp.y));
        wp.z = -4;

        if jmap.TileIsBuildable(gCtx.Map, math.Vec2{wp.x, wp.y}) && 
           !gCtx.Map.Occupied[int(wp.y)][int(wp.x)] {
                cmd := renderer.Command.Bitmap{};
                cmd.RenderPos = wp;
                cmd.Scale = math.Vec3{1, 1, 1};
                cmd.Rotation = 0;
                cmd.Texture = gCtx.BuildHoverTexture;
                render_queue.Enqueue(gCtx.MapRenderQueue, cmd);
        }
    }

    if input.IsButtonDown(ctx.Input, "Build") && withinMap {
        if jmap.TileIsBuildable(gCtx.Map, math.Vec2{wp.x, wp.y}) && 
           !gCtx.Map.Occupied[int(wp.y)][int(wp.x)] {
            console.Log("Build at %v", wp);
            e := entity.CreateTower();
            e.(^entity.Entity.Tower).T.Position = math.Vec3{wp.x, wp.y, -1};
            gCtx.Map.Occupied[int(wp.y)][int(wp.x)] = true;
            entity.AddEntity(gCtx.EntityList, e);
        }
    }
}