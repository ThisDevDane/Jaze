#import win32 "sys/windows.odin";
#import "fmt.odin";

LEFT_THUMB_DEADZONE  :: 7849;
RIGHT_THUMB_DEADZONE :: 8689;
TRIGGER_THRESHOLD    :: 30;


BatteryInformation :: struct #ordered {
    Type  : BatteryType,
    Level : BatteryLevel,
}

Capabilities :: struct #ordered {
    Type      : byte,
    SubType   : ControllerType,
    Flags     : CapabilitieFlags,
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
    GuitarAlt        = 0x7,
    Bass             = 0x0B,
    DrumKit          = 0x08,
    ArcadePad        = 0x13,
}

CapabilitieFlags :: enum u16 {
    Voice            = 0x0004,
    FFB              = 0x0001,
    Wireless         = 0x0002,
    PMD              = 0x0008,
    NoNavigations    = 0x0010,
}

_Enable                : proc(enable : win32.Bool) #cc_c;
_GetBatteryInformation : proc(userIndex : u32, devType : DeviceType, out : ^BatteryInformation) -> u32#cc_c;
_GetCapabilities       : proc(userIndex : u32, type : u32, out : ^Capabilities) -> u32 #cc_c;
_GetKeystroke          : proc(userIndex : u32, reserved : u32, out : ^KeyStroke) -> u32 #cc_c;
_GetState              : proc(userIndex : u32, state : ^State) #cc_c;
_SetState              : proc(userIndex : u32, state : VibrationState) #cc_c;

//TODO: Make Odin friendly functions that need it

Init :: proc() {
    fmt.println("TEST"); 
    //TODO: Load Functions
}