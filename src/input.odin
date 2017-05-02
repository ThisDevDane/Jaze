#import win32 "sys/windows.odin";
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

    Bindings : map[string]Binding,
    KeyStates : [256]ButtonStates,
    _OldKeyStates : [256]ButtonStates,
}

Update :: proc(input : ^Input_t) {
    input.AnyKeyPressed = false;
    ClearCharQueue(input);

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