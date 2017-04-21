#import "fmt.odin";
#import "os.odin";
#import win32 "sys/windows.odin";
#import "imgui.odin";
#import debugWnd "debug_windows.odin";

_BUF_SIZE :: 1024;

CommandProc :: #type proc(args : []string);


LogData :: struct {
    InputBuf : [256]byte,
    Items    : [dynamic]string,
    History  : [dynamic]string,
    Log      : [dynamic]LogItem,
    Commands : map[string]CommandProc,

    ScrollToBottom : bool,
    HistoryPos : int, 
    LogFileName : string,
}

LogItem :: struct {
    Text : string,
    Time : win32.Systemtime,
}

_InternalData := LogData{};

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
    buf  : [_BUF_SIZE]byte;
    buf2 : [_BUF_SIZE]byte;
    buf3 : [_BUF_SIZE]byte;
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
    item := LogItem{};
    item.Text = _StringDup(tempStr);

    ft : win32.Filetime;
    st : win32.Systemtime;
    win32.GetSystemTimeAsFileTime(^ft);
    win32.FileTimeToSystemTime(^ft, ^st);

    item.Time = st;

    append(_InternalData.Log,   item);
    _InternalData.ScrollToBottom = true;
    _UpdateLogFile();
}

_UpdateLogFile :: proc() {
    if len(_InternalData.LogFileName) <= 0 {
        ft : win32.Filetime;
        st : win32.Systemtime;
        win32.GetSystemTimeAsFileTime(^ft);
        win32.FileTimeToSystemTime(^ft, ^st);

        buf := make([]byte, 255);
        _InternalData.LogFileName = fmt.sprintf(buf[..0], "%d-%d-%d_%d%d%d.jlog", 
                                                st.day, st.month, st.year, 
                                                st.hour, st.minute, st.second);
    }

    h, _ := os.open(_InternalData.LogFileName, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0);
    os.seek(h, 0, 2);
    for log in _InternalData.Log {
        buf : [_BUF_SIZE]byte;
        str := fmt.sprintf(buf[..0], "[%2d:%2d:%2d-%3d]%s\n", log.Time.hour,   log.Time.minute, 
                                                          log.Time.second, log.Time.millisecond, 
                                                          log.Text);
        os.write(h, cast([]byte)str);
        os.seek(h, 0, 2);
    }
    os.close(h);   
} 

AddCommand :: proc(name : string p : CommandProc) {
    _InternalData.Commands[name] = p;
}

LogConsoleData :: proc(args : []string) {
    Log("InputBuf: [%d]%s:", len(_InternalData.InputBuf), cast(string)_InternalData.InputBuf[..]);
    Log("Commands: %v", _InternalData.Commands);
    Log("ScrollToBottom: %t", _InternalData.ScrollToBottom);
    Log("HistoryPos: %d", _InternalData.HistoryPos);
}

HelpCommand :: proc(args : []string) {
    Log("Available Commands: ");
    for val, key in _InternalData.Commands {
        Log("\t%s", key);
    }
}

DrawLog :: proc(show : ^bool) {
    imgui.Begin("Log", show, debugWnd.STD_WINDOW);
    imgui.BeginChild("Items", imgui.Vec2{0, 0}, true, 0);
    {
        for t in _InternalData.Log {
            if t.Text[..len(_ERROR_STR)] == _ERROR_STR {
                imgui.TextColored(imgui.Vec4{1, 0, 0, 1}, "[%2d:%2d:%2d-%3d]%s", t.Time.hour, t.Time.minute, t.Time.second, t.Time.millisecond, t.Text);
            } else {
                imgui.Text("[%2d:%2d:%2d-%3d]%s", t.Time.hour, t.Time.minute, t.Time.second, t.Time.millisecond, t.Text);
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
                if imgui.MenuItem("Log Console Data", "", false, true) {
                    LogConsoleData(nil);
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
        
        if imgui.InputText("Input", _InternalData.InputBuf[..], TEXT_FLAGS, _TextEditCallback, nil) {
            imgui.SetKeyboardFocusHere(-1);
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
        Log(str);
        append(_InternalData.History, _StringDup(str));
        if !ExecuteCommand(str) {
            LogError("%s is not a command", _PullCommandName(str));
        }
        input[0] = 0;
        _InternalData.ScrollToBottom = true;
        _InternalData.HistoryPos = 0;
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
        args : [dynamic]string;
        if len(cmdString) != len(name) {
            p := 0;
            newStr := cmdString[len(name)+1..];
            for r, i in newStr {
                if r == ' ' {
                    append(args, newStr[p..i]);
                    p = i+1;
                }

                if i == len(newStr)-1 {
                    append(args, newStr[p..i+1]);
                }
            }
        }
        cmd(args[..]);
        return true;
    }
    return false;
}

_TextEditCallback :: proc(data : ^imgui.GuiTextEditCallbackData) -> i32 #cc_c {
    match data.EventFlag {
        case imgui.GuiInputTextFlags.CallbackHistory : {
            prev := _InternalData.HistoryPos;

            if data.EventKey == imgui.GuiKey.UpArrow {
                if _InternalData.HistoryPos == 0 {
                    _InternalData.HistoryPos = len(_InternalData.History);
                } else {
                    _InternalData.HistoryPos--;
                }
            } else if data.EventKey == imgui.GuiKey.DownArrow {
                if _InternalData.HistoryPos != 0 {
                    _InternalData.HistoryPos++;
                    if _InternalData.HistoryPos > len(_InternalData.History) {
                        _InternalData.HistoryPos = 0;
                    }
                }
            }

            if prev != _InternalData.HistoryPos {
                pos := _InternalData.HistoryPos > 0 ? _InternalData.HistoryPos-1 : -1;  
                str := fmt.sprintf(slice_ptr(data.Buf, data.BufSize)[..0], "%s", pos < 0 ? "" : _InternalData.History[pos]);
                strlen := cast(i32)len(str)-1;
                data.BufTextLen = strlen;
                data.CursorPos = strlen;
                data.SelectionStart = strlen;
                data.SelectionEnd = strlen;
                data.BufDirty = true;
            }
        }

        case imgui.GuiInputTextFlags.CallbackCompletion : {

        }
    }

    return 0;
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