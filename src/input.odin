#import win32 "sys/windows.odin";
#import "math.odin";

#import "xinput.odin";

ButtonStates :: enum {
    Up,
    Held,
    Down,
    Neutral,
}

Binding :: struct {
    ID   : string,
    Key  : win32.Key_Code,
    XKey : xinput.Buttons, 
}

Input_t :: struct {
    AnyKeyPressed : bool,
    MousePos      : math.Vec2,

    Bindings      : map[string]Binding,
    KeyStates     : [256]ButtonStates,
    _OldKeyStates : [256]ButtonStates,
    XState        : [4]xinput.GamepadState,
    _OldXState    : [4]xinput.GamepadState,
}

Update :: proc(input : ^Input_t) {
    input.AnyKeyPressed = false;
    ClearCharQueue(input);
    UpdateKeyboard(input);
    UpdateXinput(input);
}

UpdateMousePosition :: proc(input : ^Input_t, handle : win32.Hwnd) {
    mousePos : win32.Point;
    win32.GetCursorPos(&mousePos);
    win32.ScreenToClient(handle, &mousePos);
    input.MousePos = math.Vec2{f32(mousePos.x), f32(mousePos.y)};
}

UpdateKeyboard :: proc(input : ^Input_t) {
    for k in win32.Key_Code {
        if win32.GetKeyState(i32(k)) < 0 {
            if input._OldKeyStates[k] == ButtonStates.Down || 
               input._OldKeyStates[k] == ButtonStates.Held {
                input.KeyStates[k] = ButtonStates.Held;
            } else {
                input.KeyStates[k] = ButtonStates.Down;
            }

            input.AnyKeyPressed = true;
        } else {
            if input._OldKeyStates[k] == ButtonStates.Down || 
               input._OldKeyStates[k] == ButtonStates.Held {

                input.KeyStates[k] = ButtonStates.Up;
            } else {
                input.KeyStates[k] = ButtonStates.Neutral;
            }
        }
    }

    input._OldKeyStates = input.KeyStates;
}

UpdateXinput :: proc(input : ^Input_t) {
    IsButtonPressed :: proc(state : xinput.State, b : xinput.Buttons) -> bool {
        return state.Gamepad.Buttons & u16(b) == u16(b);
    }
}

SetAllInputNeutral :: proc(input : ^Input_t) {
    for k in win32.Key_Code {
       input.KeyStates[k] = ButtonStates.Neutral;
       input._OldKeyStates[k] = ButtonStates.Neutral;
    }
}

AddBinding :: proc(input : ^Input_t, name : string, key : win32.Key_Code) {
    _, ok := input.Bindings[name];
    if ok {
        input.Bindings[name].Key = key;
    } else {
        new : Binding;
        new.ID = name;
        new.Key = key;
        new.XKey = xinput.Buttons.Invalid;
        input.Bindings[name] = new;
    }
}

AddBinding :: proc(input : ^Input_t, name : string, xKey : xinput.Buttons) {
        _, ok := input.Bindings[name];
    if ok {
        input.Bindings[name].XKey = xKey;
    } else {
        new : Binding;
        new.ID = name;
        new.Key = win32.Key_Code.NONAME;
        new.XKey = xKey;
        input.Bindings[name] = new;
    }
}

IsButtonDown :: proc(input : ^Input_t, name : string) -> bool {
    return GetButtonState(input, name) == ButtonStates.Down;
}

IsButtonUp :: proc(input : ^Input_t, name : string) -> bool {
    return GetButtonState(input, name) == ButtonStates.Up;
}

IsButtonHeld :: proc(input : ^Input_t, name : string) -> bool {
    return GetButtonState(input, name) == ButtonStates.Held;
}

GetButtonState :: proc(input : ^Input_t, name : string) -> ButtonStates {
    if key, ok := input.Bindings[name]; ok {
        return input.KeyStates[i32(key.Key)];
    }

    return ButtonStates.Neutral;
}

AddCharToQueue :: proc(input : ^Input_t, char : rune) {
    //TODO(Hoej)
}

ClearCharQueue :: proc(input : ^Input_t) {
    //TODO(Hoej)
}