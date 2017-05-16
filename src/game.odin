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

Context_t :: struct {
    EntityList : ^entity.List,
    Map        : ^jmap.Data_t,
    GameCamera : ^renderer.Camera_t,

    MapRenderQueue   : ^render_queue.Queue,
    TowerRenderQueue : ^render_queue.Queue,
    EnemyRenderQueue : ^render_queue.Queue,
    
    BuildMode  : bool,
}

_CAMERA_SPEED :: 10;
_CAMERA_ZOOM_SPEED :: 0.5;
_MAX_CAMERA_ZOOM :: 100;
_MIN_CAMERA_ZOOM :: 30;

CreateContext :: proc() -> ^Context_t {
    ctx := new(Context_t);
    
    ctx.MapRenderQueue   = render_queue.Make();
    ctx.TowerRenderQueue = render_queue.Make();
    ctx.EnemyRenderQueue = render_queue.Make();
    ctx.EntityList       = entity.MakeList();

    ctx.GameCamera      = new(renderer.Camera_t);
    ctx.GameCamera.Pos  = math.Vec3{0, 0, 15};
    ctx.GameCamera.Zoom = 50;
    ctx.GameCamera.Near = 0.1;
    ctx.GameCamera.Far  = 50;
    ctx.GameCamera.Rot  = 45;

    return ctx;
}

SetupBindings :: proc(input_ : ^input.Input_t) {
    input.AddBinding(input_, "CameraUp",       win32.Key_Code.W);
    input.AddBinding(input_, "CameraLeft",     win32.Key_Code.A);
    input.AddBinding(input_, "CameraRight",    win32.Key_Code.D);
    input.AddBinding(input_, "CameraDown",     win32.Key_Code.S);
    input.AddBinding(input_, "CameraZoomIn",   win32.Key_Code.E);
    input.AddBinding(input_, "CameraZoomOut",  win32.Key_Code.Q);

    input.AddBinding(input_, "ToggleBuild",  win32.Key_Code.B);
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

    camera.Zoom += f32(zoom) * _CAMERA_ZOOM_SPEED;
    if camera.Zoom > _MAX_CAMERA_ZOOM {
        camera.Zoom = _MAX_CAMERA_ZOOM;
    } else if camera.Zoom < _MIN_CAMERA_ZOOM {
        camera.Zoom = _MIN_CAMERA_ZOOM;
    }

    camera.Pos += (dir * _CAMERA_SPEED * f32(ctx.Time.DeltaTime));
}

InputLogic :: proc(ctx : ^engine.Context_t, gCtx : ^Context_t) {
    CameraLogic(ctx, gCtx.GameCamera);

    if input.IsButtonDown(ctx.Input, "ToggleBuild") {
        gCtx.BuildMode = !gCtx.BuildMode;
    }
}