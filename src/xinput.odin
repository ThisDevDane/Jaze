#import win32 "sys/windows.odin";
#import "fmt.odin";
#import "strings.odin";
//#foreign_system_library xlib "xinput.lib";

LEFT_THUMB_DEADZONE  :: 7849;
RIGHT_THUMB_DEADZONE :: 8689;
TRIGGER_THRESHOLD    :: 30;
USER_MAX_COUNT       :: 4;

Error :: u32;
Success : Error : 0;
NotConnected : Error : 1167;

BatteryInformation :: struct #ordered {
    Type  : BatteryType,
    Level : BatteryLevel,
}

Capabilities :: struct #ordered {
    Type      : byte,
    SubType   : ControllerType,
    Flags     : CapabilitiesFlags,
    Gamepad   : GamepadState,
    Vibration : VibrationState,
}

State :: struct #ordered {
    PacketNumber : u32,
    Gamepad : GamepadState,
}

GamepadState :: struct #ordered {
    Buttons      : u16,
    LeftTrigger  : byte,
    RightTrigger : byte,
    LX           : i16,
    LY           : i16,
    RX           : i16,
    RY           : i16,
}

VibrationState :: struct #ordered {
    LeftMotorSpeed  : u16,
    RightMotorSpeed : u16,
}

KeyStroke :: struct #ordered {
    VirtualKey : VirtualKeys,
    Unicode    : u16,
    Flags      : KeyStrokeFlags,
    userIndex  : byte,
    HidCode    : byte
}

VirtualKeys :: enum u16 {
    A                = 0x5800,
    B                = 0x5801,
    X                = 0x5802,
    Y                = 0x5803,
    RSHOULDER        = 0x5804,
    LSHOULDER        = 0x5805,
    LTRIGGER         = 0x5806,
    RTRIGGER         = 0x5807,

    DPAD_UP          = 0x5810,
    DPAD_DOWN        = 0x5811,
    DPAD_LEFT        = 0x5812,
    DPAD_RIGHT       = 0x5813,
    START            = 0x5814,
    BACK             = 0x5815,
    LTHUMB_PRESS     = 0x5816,
    RTHUMB_PRESS     = 0x5817,

    LTHUMB_UP        = 0x5820,
    LTHUMB_DOWN      = 0x5821,
    LTHUMB_RIGHT     = 0x5822,
    LTHUMB_LEFT      = 0x5823,
    LTHUMB_UPLEFT    = 0x5824,
    LTHUMB_UPRIGHT   = 0x5825,
    LTHUMB_DOWNRIGHT = 0x5826,
    LTHUMB_DOWNLEFT  = 0x5827,

    RTHUMB_UP        = 0x5830,
    RTHUMB_DOWN      = 0x5831,
    RTHUMB_RIGHT     = 0x5832,
    RTHUMB_LEFT      = 0x5833,
    RTHUMB_UPLEFT    = 0x5834,
    RTHUMB_UPRIGHT   = 0x5835,
    RTHUMB_DOWNRIGHT = 0x5836,
    RTHUMB_DOWNLEFT  = 0x5837,
}

KeyStrokeFlags :: enum u16 {
    KeyDown          = 0x0001,
    KeyUp            = 0x0002,
    Repeat           = 0x0004,
}

Buttons :: enum u16 {
    DpadUp           = 0x0001,
    DpadDown         = 0x0002,
    DpadLeft         = 0x0004,
    DpadRight        = 0x0008,
    Start            = 0x0010,
    Back             = 0x0020,
    LeftThumb        = 0x0040,
    RightThumb       = 0x0080,
    LeftShoulder     = 0x0100,
    RightShoulder    = 0x0200,
    A                = 0x1000,
    B                = 0x2000,
    X                = 0x4000,
    Y                = 0x8000,

    Invalid          = 0x0000,
}

BatteryType :: enum byte {
    Disconnected     = 0x00,
    Wired            = 0x01,
    Alkaline         = 0x02,
    Nimh             = 0x03,
    Unknown          = 0xFF,
}

BatteryLevel :: enum byte {
    Empty            = 0x00,
    Low              = 0x01,
    Medium           = 0x02,
    Full             = 0x03,
}

DeviceType :: enum byte {
    Gamepad          = 0x00,
    Headset          = 0x01,
}

ControllerType :: enum byte {
    Unknown          = 0x00,
    Gamepad          = 0x01,
    Wheel            = 0x02,
    ArcadeStick      = 0x03,
    FlightStick      = 0x04,
    DancePad         = 0x05,
    Guitar           = 0x06,
    GuitarAlt        = 0x07,
    Bass             = 0x0B,
    DrumKit          = 0x08,
    ArcadePad        = 0x13,
}

CapabilitiesFlags :: enum u16 {
    Voice            = 0x0004,
    FFB              = 0x0001,
    Wireless         = 0x0002,
    PMD              = 0x0008,
    NoNavigations    = 0x0010,
}

User :: enum u32 {
    Player1 = 0,
    Player2,
    Player3,
    Player4,
}

_Enable                : proc(enable : win32.Bool) #cc_c;
_GetBatteryInformation : proc(userIndex : u32, devType : DeviceType, out : ^BatteryInformation) -> u32#cc_c;
_GetCapabilities       : proc(userIndex : u32, type : u32, out : ^Capabilities) -> u32 #cc_c;
_GetKeystroke          : proc(userIndex : u32, reserved : u32, out : ^KeyStroke) -> u32 #cc_c;
_GetState              : proc(userIndex : u32, state : ^State) -> u32 #cc_c;
_SetState              : proc(userIndex : u32, state : VibrationState) -> u32 #cc_c;

//TODO: Make Odin friendly functions that need it

/*xEnable :: proc(enable : win32.Bool) #foreign xlib "XInputEnable";
xGetCapabilities :: proc(userIndex : u32, type : u32, out : ^Capabilities) -> u32 #foreign xlib "XInputGetCapabilities";
*/
Enable :: proc(enable : bool) {
    if _Enable != nil {
        _Enable(win32.Bool(enable));
    } else {
        //TODO: Logging        
    }
}

GetCapabilities :: proc(user : User) -> (Capabilities, Error) {
    return GetCapabilities(user, false);
}

GetCapabilities :: proc(user : User, onlyGamepads : bool)  -> (Capabilities, Error) {
    if _GetCapabilities != nil {
        res := Capabilities{};
        _u := u32(user);
        err := _GetCapabilities(u32(user), u32(onlyGamepads), &res);
        return res, Error(err);
    } else {
        //TODO: Logging        
    }
    return Capabilities{}, NotConnected;
}

GetState :: proc(user : User) -> (State, Error) {
     if _GetState != nil {
        res := State{};
        err := _GetState(u32(user), &res);
        return res, Error(err);
    } else {
        //TODO: Logging        
    }

    return State{}, NotConnected;
}

XInputVersion :: enum {
    NotLoaded,
    Version1_4,
    Version1_3,
    Version9_1_0,
    Error
}

DebugFunctionLoadStatus :: struct {
    Name    : string,
    Address : int,
    Success : bool,
    TypeInfo : ^Type_Info,
}

DebugInfo_t :: struct {
    LibAddress : int,
    NumberOfFunctionsLoaded : i32,
    NumberOfFunctionsLoadedSuccessed : i32,
    Statuses : [dynamic]DebugFunctionLoadStatus,
}

DebugInfo : DebugInfo_t;

Version := XInputVersion.NotLoaded;

Init :: proc() -> bool {
    lib1_4   := "xinput1_4.dll\x00";
    lib1_3   := "xinput1_3.dll\x00";
    lib9_1_0 := "xinput9_1_0.dll\x00";

    lib := win32.LoadLibraryA(&lib1_4[0]);
    using XInputVersion;
    Version = Version1_4;
    if lib == nil {
        lib = win32.LoadLibraryA(&lib1_3[0]);
        Version = Version1_3;
    }

    if lib == nil {
        lib := win32.LoadLibraryA(&lib9_1_0[0]);
        Version = Version9_1_0;
    }



    if lib == nil {
        Version = Error;
        //TODO: Logging
        return false;
    }

    DebugInfo.LibAddress = int(lib);

    set_proc_address :: proc(h : win32.Hmodule, p: rawptr, name: string) #inline {
        txt := strings.new_c_string(name); defer free(txt);
        res: = win32.GetProcAddress(h, txt);
        ^(proc() #cc_c)(p)^ = res;


        status := DebugFunctionLoadStatus{};
        status.Name = name;
        status.Address = int(rawptr(res));
        status.Success = false;
        //status.TypeInfo = info;
        DebugInfo.NumberOfFunctionsLoaded++;

        if status.Address != 0 {
            status.Success = true;
            DebugInfo.NumberOfFunctionsLoadedSuccessed++;
        }
        append(DebugInfo.Statuses, status);
    }

    set_proc_address(lib, &_Enable,                "XInputEnable"               );
    set_proc_address(lib, &_GetBatteryInformation, "XInputGetBatteryInformation");
    set_proc_address(lib, &_GetCapabilities,       "XInputGetCapabilities"      );
    set_proc_address(lib, &_GetKeystroke,          "XInputGetKeystroke"         );
    set_proc_address(lib, &_GetState,              "XInputGetState"             );
    set_proc_address(lib, &_SetState,              "XInputSetState"             );

    return true;
}