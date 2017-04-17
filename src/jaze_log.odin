#import "fmt.odin";
#import "odimgui/src/imgui.odin";
#import debugWnd "jaze_debug_windows.odin";

_BUF_SIZE :: 1024;

CommandProc :: #type proc(args : string);

TestCommand :: proc(args : string) {
    Log("TESTING");
    Log("TESTING2");
    Log("TESTING3");
}

LogData :: struct {
    InputBuf : [256]byte,
    Items    : [dynamic]string,
    History  : [dynamic]string,
    Log      : [dynamic]string,
    Commands : map[string]CommandProc,

    ScrollToBottom : bool,
}

_InternalData : LogData;

LogLevel :: enum {
    Normal,
    Error,
}

_ERROR_STR :: "[Error]: ";

LogError :: proc(fmt_ : string, args : ..any) {
    _InternalLog(fmt_, LogLevel.Error, ..args);
}

Log :: proc(fmt_ : string, args : ..any) {
    _InternalLog(fmt_, LogLevel.Normal, ..args);
}

_InternalLog :: proc(fmt_ : string, level : LogLevel, args : ..any) {
    buf : [_BUF_SIZE]byte;
    buf2 : [_BUF_SIZE]byte;
    levelStr : string;
    match level {
        case LogLevel.Normal : {
            levelStr = "";
        }

        case LogLevel.Error : {
            levelStr = _ERROR_STR;
        }
    }
    newFmt  := fmt.sprintf(buf[..0], "%s%s", levelStr, fmt_);
    tempStr := fmt.sprintf(buf2[..0], newFmt, ..args);
    append(_InternalData.Items, _StringDup(tempStr));
    append(_InternalData.Log,   _StringDup(tempStr));
}

AddCommand :: proc(name : string p : CommandProc) {
    _InternalData.Commands[name] = p;
}

DrawLog :: proc(show : ^bool) {
    imgui.Begin("Log", show, debugWnd.STD_WINDOW);
    imgui.BeginChild("Items", imgui.Vec2{0, 0}, true, 0);
    {
        for t in _InternalData.Log {
            if t[..len(_ERROR_STR)] == _ERROR_STR {
                imgui.TextColored(imgui.Vec4{1, 0, 0, 1}, t);
            } else {
                imgui.Text(t);
            }
        }
    }
    imgui.EndChild();
    imgui.End();
}

DrawConsole :: proc(show : ^bool) {
    imgui.Begin("Console", show, debugWnd.STD_WINDOW | imgui.GuiWindowFlags.MenuBar);
    {
        if imgui.BeginMenuBar() {
            if imgui.BeginMenu("Misc", true) {
                if imgui.MenuItem("Show Log", "", false, len(_InternalData.Log) > 0) {
                    debugWnd.ToggleWindow("ShowLogWindow");
                }                
                if imgui.MenuItem("Clear", "", false, len(_InternalData.Items) > 0) {
                    ClearConsole();
                }

                imgui.EndMenu();
            }
            imgui.EndMenuBar();
        }

        imgui.BeginChild("Buffer", imgui.Vec2{-1, -40}, true, 0);
        {
            for t in _InternalData.Items {
                if t[..len(_ERROR_STR)] == _ERROR_STR {
                    imgui.TextColored(imgui.Vec4{1, 0, 0, 1}, t);
                } else {
                    imgui.Text(t);
                }
            }

            if _InternalData.ScrollToBottom {
                imgui.SetScrollHere(0.5);
            }
            _InternalData.ScrollToBottom = false;
        }
        imgui.EndChild();

        TEXT_FLAGS :: imgui.GuiInputTextFlags.EnterReturnsTrue | imgui.GuiInputTextFlags.CallbackCompletion | imgui.GuiInputTextFlags.CallbackHistory;
        
        if imgui.InputText("Input", _InternalData.InputBuf[..], TEXT_FLAGS, nil, nil) {
            InputEnter(_InternalData.InputBuf[..]);
        }
        imgui.SameLine(0, -1);
        if imgui.Button("Enter", imgui.Vec2{-1, 0}) {
            InputEnter(_InternalData.InputBuf[..]);
        }
        imgui.Separator();
        imgui.TextColored(imgui.Vec4{1, 1, 1, 0.2}, "Items: %d | History: %d | Log : %d", len(_InternalData.Items), 
                                                                                          len(_InternalData.History), 
                                                                                          len(_InternalData.Log));
    }
    imgui.End();
}

InputEnter :: proc(input : []byte) {
    if input[0] != 0 &&
       input[0] != ' ' {
        i := _FindStringNull(input[..]);
        str := cast(string)input[..i];
        append(_InternalData.Items, _StringDup(str));
        append(_InternalData.History, _StringDup(str));
        append(_InternalData.Log, _StringDup(str));
        if !ExecuteCommand(str) {
            LogError("%s is not a command", _PullCommandName(str));
        }
        input[0] = 0;
        _InternalData.ScrollToBottom = true;
    }
}

ClearConsole :: proc() {
    for str in _InternalData.Items {
        free(str);
    }
    clear(_InternalData.Items);
}

ExecuteCommand :: proc(cmdString : string) -> bool {
    name := _PullCommandName(cmdString);
    if cmd, ok := _InternalData.Commands[name]; ok {
        cmd(cmdString);
        return true;
    }
    return false;
}

_PullCommandName :: proc(s : string) -> string {
    for r, i in s {
        if r == ' ' {
            return s[..i];
        }
    }

    return s;
}

_StringDup :: proc(s : string) -> string {
    data := make([]byte, len(s)+1);
    copy(data, cast([]byte)s[..]);
    return cast(string)data;    
}

_FindStringNull :: proc(s : []byte) -> int {
    for r, i in s {
        if r == 0 {
            return i;
        }
    }

    return -1;
}