#import win32 "sys/windows.odin";
#import "math.odin";

#import "entity.odin";
#import "jmap.odin";
#import "renderer.odin";
#import "engine.odin";
#import "input.odin";
#import "console.odin";

Context_t :: struct {
    EntityList : ^entity.List,
    Map        : ^jmap.Data_t,
    GameCamera : ^renderer.Camera_t,
}

_CAMERA_SPEED :: 10;
_CAMERA_ZOOM_SPEED :: 0.5;
_MAX_CAMERA_ZOOM :: 100;
_MIN_CAMERA_ZOOM :: 30;

SetupCameraBindings :: proc(input_ : ^input.Input_t) {
    input.AddBinding(input_, "CameraUp",       win32.Key_Code.W);
    input.AddBinding(input_, "CameraLeft",     win32.Key_Code.A);
    input.AddBinding(input_, "CameraRight",    win32.Key_Code.D);
    input.AddBinding(input_, "CameraDown",     win32.Key_Code.S);
    input.AddBinding(input_, "CameraZoomIn",   win32.Key_Code.E);
    input.AddBinding(input_, "CameraZoomOut",  win32.Key_Code.Q);
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