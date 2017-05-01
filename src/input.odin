#import win32 "sys/windows.odin";

ButtonStates :: enum {
    Up,
    Held,
    Down,
    Neutral,
}

Input_t :: struct {
    AnyKeyPressed : bool,

    Bindings : map[string]win32.Key_Code,
    _MouseStates : [3]ButtonStates,
    _KeyStates : [256]ButtonStates,
    _OldKeyStates : [256]ButtonStates,
}

Update :: proc(input : ^Input_t) {
    input.AnyKeyPressed = false;
    ClearCharQueue(input);

    for k in win32.Key_Code {
        if win32.GetKeyState(i32(k)) < 0 {
            if input._OldKeyStates[k] == ButtonStates.Down {
                input._KeyStates[k] = ButtonStates.Held;
            } else {
                input._KeyStates[k] = ButtonStates.Down;
            }

            input.AnyKeyPressed = true;
        } else {
            if input._OldKeyStates[k] == ButtonStates.Down || 
               input._OldKeyStates[k] == ButtonStates.Held {

                input._KeyStates[k] = ButtonStates.Up;
            } else {
                input._KeyStates[k] = ButtonStates.Neutral;
            }
        }
    }

    input._OldKeyStates = input._KeyStates;
}

AddBinding :: proc(input : ^Input_t, name : string, key : win32.Key_Code) {
    input.Bindings[name] = key;
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
        return input._KeyStates[i32(key)];
    }

    return ButtonStates.Neutral;
}

AddCharToQueue :: proc(input : ^Input_t, char : rune) {
    //TODO(Hoej)
}

ClearCharQueue :: proc(input : ^Input_t) {
    //TODO(Hoej)
}