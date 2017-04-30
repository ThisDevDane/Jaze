#import "fmt.odin";
#import "os.odin";
#import win32 "sys/windows.odin";
#import "imgui.odin";
#import debugWnd "debug_windows.odin";

OUTPUT_TO_CLI  :: true;
OUTPUT_TO_FILE :: false;

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
    ConsoleInput,
    Error,
}

_ERROR_STR  :: "[Error]: ";
_CINPUT_STR :: "\\\\: ";

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

        case LogLevel.ConsoleInput : {
            levelStr = _CINPUT_STR;
        }
    }
    c := fmt.bprintf(buf[..], "%s%s", levelStr, fmt_);
    newFmt  := string(buf[0..c]);
    c = fmt.bprintf(buf2[..], newFmt, ..args);
    tempStr := string(buf2[0..c]);
    append(_InternalData.Items, _StringDup(tempStr));

    when OUTPUT_TO_CLI {
        fmt.printf("%s\n", tempStr);
    }

    item := LogItem{};
    item.Text = _StringDup(tempStr);

    ft : win32.Filetime;
    st : win32.Systemtime;
    win32.GetSystemTimeAsFileTime(&ft);
    win32.FileTimeToSystemTime(&ft, &st);

    item.Time = st;

    append(_InternalData.Log,   item);
    _InternalData.ScrollToBottom = true;
    when OUTPUT_TO_FILE {
        _UpdateLogFile();
    }
}

_UpdateLogFile :: proc() {
    if len(_InternalData.LogFileName) <= 0 {
        ft : win32.Filetime;
        st : win32.Systemtime;
        win32.GetSystemTimeAsFileTime(&ft);
        win32.FileTimeToSystemTime(&ft, &st);

        buf := make([]byte, 255);
        c := fmt.bprintf(buf[..], "%d-%d-%d_%d%d%d.jlog", 
                                                st.day, st.month, st.year, 
                                                st.hour, st.minute, st.second);
        _InternalData.LogFileName = string(buf[0..c]);
    }

    h, _ := os.open(_InternalData.LogFileName, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0);
    os.seek(h, 0, 2);
    for log in _InternalData.Log {
        buf : [_BUF_SIZE]byte;
        c := fmt.bprintf(buf[..], "[%2d:%2d:%2d-%3d]%s\n", log.Time.hour,   log.Time.minute, 
                                                              log.Time.second, log.Time.millisecond, 
                                                              log.Text);
        str := string(buf[0..c]);
        os.write(h, []byte(str));
        os.seek(h, 0, 2);
    }
    os.close(h);   
} 

AddCommand :: proc(name : string p : CommandProc) {
    _InternalData.Commands[name] = p;
}

DefaultHelpCommand :: proc(args : []string) {
    Log("Available Commands: ");
    for val, key in _InternalData.Commands {
        Log("\t%s", key);
    }
}

DefaultClearCommand :: proc(args : []string) {
    ClearConsole();
}

DrawLog :: proc(show : ^bool) {
    imgui.Begin("Log", show, debugWnd.STD_WINDOW);
    imgui.BeginChild("Items", imgui.Vec2{0, 0}, true, 0);
    {
        for t in _InternalData.Log {
            if t.Text[0..<len(_ERROR_STR)] == _ERROR_STR {
                imgui.TextColored(imgui.Vec4{1, 0, 0, 1}, "[%2d:%2d:%2d-%3d]%s", t.Time.hour, t.Time.minute, t.Time.second, t.Time.millisecond, t.Text);
            } else if t.Text[0..<len(_CINPUT_STR)] == _CINPUT_STR {
                imgui.TextColored(imgui.Vec4{0.7, 0.7, 0.7, 1}, "[%2d:%2d:%2d-%3d]%s", t.Time.hour, t.Time.minute, t.Time.second, t.Time.millisecond, t.Text);
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
                if t[0..<len(_ERROR_STR)] == _ERROR_STR {
                    imgui.TextColored(imgui.Vec4{1, 0, 0, 1}, t);
                } else if t[0..<len(_CINPUT_STR)] == _CINPUT_STR {
                    imgui.TextColored(imgui.Vec4{0.7, 0.7, 0.7, 1}, t);
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
        str := string(input[0..<i]);
        _InternalLog(str, LogLevel.ConsoleInput);
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
                c := fmt.bprintf(slice_ptr(data.Buf, data.BufSize)[..], "%s", pos < 0 ? "" : _InternalData.History[pos]);
                str := string(slice_ptr(data.Buf, data.BufSize)[0..c]);
                strlen := i32(len(str)-1);
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
            return s[0..<i];
        }
    }

    return s;
}

_StringDup :: proc(s : string) -> string {
    data := make([]byte, len(s)+1);
    copy(data, []byte(s[..]));
    return string(data);    
}

_FindStringNull :: proc(s : []byte) -> int {
    for r, i in s {
        if r == 0 {
            return i;
        }
    }

    return -1;
}