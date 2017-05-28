/*
 *  @Name:     console
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 10-05-2017 21:11:30
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 28-05-2017 21:50:00
 *  
 *  @Description:
 *      The console is an in engine window that can be pulled up for viewing.
 *      It also takes care of outputting to a log file if enabled.
 *      The console can also execute commands if matched with input.
 */
#import "fmt.odin";
#import "os.odin";
#import win32 "sys/windows.odin";
#import "imgui.odin";
#import debug_wnd "debug_windows.odin";

OUTPUT_TO_CLI  :: false;
OUTPUT_TO_FILE :: false;

_BUF_SIZE :: 1024;

CommandProc :: #type proc(args : []string);


LogData :: struct {
    input_buf     : [256]byte,
    items         : [dynamic]string,
    history       : [dynamic]string,
    log           : [dynamic]LogItem,
    commands      : map[string]CommandProc,
    log_file_name : string,

    _scroll_to_bottom : bool,
    _history_pos      : int, 
}

LogItem :: struct {
    text : string,
    time : win32.Systemtime,
}

_internal_data := LogData{};

LogLevel :: enum {
    Normal,
    ConsoleInput,
    Error,
}

_ERROR_STR  :: "[Error]: ";
_CINPUT_STR :: "\\\\: ";

log_error :: proc(fmt_ : string, args : ..any) {
    _internal_log(fmt_, LogLevel.Error, ..args);
}

log :: proc(fmt_ : string, args : ..any) {
    _internal_log(fmt_, LogLevel.Normal, ..args);
}

_internal_log :: proc(fmt_ : string, level : LogLevel, args : ..any) {
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
    newFmt := fmt.bprintf(buf[..], "%s%s", levelStr, fmt_);
    tempStr := fmt.bprintf(buf2[..], newFmt, ..args);
    append(_internal_data.items, _string_dup(tempStr));

    when OUTPUT_TO_CLI {
        fmt.printf("%s\n", tempStr);
    }

    item := LogItem{};
    item.text = _string_dup(tempStr);

    ft : win32.Filetime;
    st : win32.Systemtime;
    win32.get_system_time_as_file_time(&ft);
    win32.file_time_to_system_time(&ft, &st);

    item.time = st;

    append(_internal_data.log,   item);
    _internal_data._scroll_to_bottom = true;
    when OUTPUT_TO_FILE {
        _update_log_file();
    }
}

_update_log_file :: proc() {
    if len(_internal_data.log_file_name) <= 0 {
        ft : win32.Filetime;
        st : win32.Systemtime;
        win32.get_system_time_as_file_time(&ft);
        win32.file_time_to_system_time(&ft, &st);

        buf := make([]byte, 255);
        _internal_data.log_file_name = fmt.bprintf(buf[..], "%d-%d-%d_%d%d%d.jlog", 
                                                st.day, st.month, st.year, 
                                                st.hour, st.minute, st.second);
    }

    h, _ := os.open(_internal_data.log_file_name, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0);
    os.seek(h, 0, 2);
    for log in _internal_data.log {
        buf : [_BUF_SIZE]byte;
        str := fmt.bprintf(buf[..], "[%2d:%2d:%2d-%3d]%s\n", log.time.hour,   log.time.minute, 
                                                              log.time.second, log.time.millisecond, 
                                                              log.text);
        os.write(h, []byte(str));
        os.seek(h, 0, 2);
    }
    os.close(h);   
} 

add_command :: proc(name : string p : CommandProc) {
    _internal_data.commands[name] = p;
}

default_help_command :: proc(args : []string) {
    log("Available Commands: ");
    for val, key in _internal_data.commands {
        log("\t%s", key);
    }
}

default_clear_command :: proc(args : []string) {
    clear_console();
}

add_default_commands :: proc() {
    add_command("Clear", default_clear_command);
    add_command("Help",  default_help_command);
}

draw_log :: proc(show : ^bool) {
    imgui.begin("Log", show, debug_wnd.STD_WINDOW);
    imgui.begin_child("Items", imgui.Vec2{0, 0}, true, 0);
    {
        for t in _internal_data.log {
            if t.text[0..<len(_ERROR_STR)] == _ERROR_STR {
                imgui.text_colored(imgui.Vec4{1, 0, 0, 1}, "[%2d:%2d:%2d-%3d]%s", t.time.hour, t.time.minute, t.time.second, t.time.millisecond, t.text);
            } else if t.text[0..<len(_CINPUT_STR)] == _CINPUT_STR {
                imgui.text_colored(imgui.Vec4{0.7, 0.7, 0.7, 1}, "[%2d:%2d:%2d-%3d]%s", t.time.hour, t.time.minute, t.time.second, t.time.millisecond, t.text);
            } else {
                imgui.text("[%2d:%2d:%2d-%3d]%s", t.time.hour, t.time.minute, t.time.second, t.time.millisecond, t.text);
            }
        }
    }
    imgui.end_child();
    imgui.end();
}

draw_console :: proc(show : ^bool) {
    imgui.begin("Console", show, debug_wnd.STD_WINDOW | imgui.GuiWindowFlags.MenuBar);
    {
        if imgui.begin_menu_bar() {
            if imgui.begin_menu("Misc", true) {
                if imgui.menu_item("Show Log", "", false, len(_internal_data.log) > 0) {
                    debug_wnd.toggle_window_state("ShowLogWindow");
                }              
                if imgui.menu_item("Clear", "", false, len(_internal_data.items) > 0) {
                    clear_console();
                }

                imgui.end_menu();
            }
            imgui.end_menu_bar();
        }

        imgui.begin_child("Buffer", imgui.Vec2{-1, -40}, true, 0);
        {
            for t in _internal_data.items {
                if t[0..<len(_ERROR_STR)] == _ERROR_STR {
                    imgui.text_colored(imgui.Vec4{1, 0, 0, 1}, t);
                } else if t[0..<len(_CINPUT_STR)] == _CINPUT_STR {
                    imgui.text_colored(imgui.Vec4{0.7, 0.7, 0.7, 1}, t);
                } else {
                    imgui.text(t);
                }
            }

            if _internal_data._scroll_to_bottom {
                imgui.set_scroll_here(0.5);
            }
            _internal_data._scroll_to_bottom = false;
        }
        imgui.end_child();

        text_FLAGS :: imgui.GuiInputTextFlags.EnterReturnsTrue | imgui.GuiInputTextFlags.CallbackCompletion | imgui.GuiInputTextFlags.CallbackHistory;
        
        if imgui.input_text("Input", _internal_data.input_buf[..], text_FLAGS, _text_edit_callback, nil) {
            imgui.set_keyboard_focus_here(-1);
            enter_input(_internal_data.input_buf[..]);
        }
        imgui.same_line(0, -1);
        if imgui.button("Enter", imgui.Vec2{-1, 0}) {
            enter_input(_internal_data.input_buf[..]);
        }
        imgui.separator();
        imgui.text_colored(imgui.Vec4{1, 1, 1, 0.2}, "Items: %d | History: %d | Log : %d", len(_internal_data.items), 
                                                                                          len(_internal_data.history), 
                                                                                          len(_internal_data.log));
    }
    imgui.end();
}

enter_input :: proc(input : []byte) {
    if input[0] != 0 &&
       input[0] != ' ' {
        i := _find_string_null(input[..]);
        str := string(input[0..<i]);
        _internal_log(str, LogLevel.ConsoleInput);
        append(_internal_data.history, _string_dup(str));
        if !execute_command(str) {
            log_error("%s is not a command", _pull_command_name(str));
        }
        input[0] = 0;
        _internal_data._scroll_to_bottom = true;
        _internal_data._history_pos = 0;
    }
}

clear_console :: proc() {
    for str in _internal_data.items {
        free(str);
    }
    clear(_internal_data.items);
}

execute_command :: proc(cmdString : string) -> bool {
    name := _pull_command_name(cmdString);
    if cmd, ok := _internal_data.commands[name]; ok {
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

_text_edit_callback :: proc(data : ^imgui.GuiTextEditCallbackData) -> i32 #cc_c {
    match data.event_flag {
        case imgui.GuiInputTextFlags.CallbackHistory : {
            prev := _internal_data._history_pos;

            if data.event_key == imgui.GuiKey.UpArrow {
                if _internal_data._history_pos == 0 {
                    _internal_data._history_pos = len(_internal_data.history);
                } else {
                    _internal_data._history_pos--;
                }
            } else if data.event_key == imgui.GuiKey.DownArrow {
                if _internal_data._history_pos != 0 {
                    _internal_data._history_pos++;
                    if _internal_data._history_pos > len(_internal_data.history) {
                        _internal_data._history_pos = 0;
                    }
                }
            }

            if prev != _internal_data._history_pos {
                pos := _internal_data._history_pos > 0 ? _internal_data._history_pos-1 : -1;  
                str := fmt.bprintf(slice_ptr(data.buf, data.buf_size)[..], "%s", pos < 0 ? "" : _internal_data.history[pos]);
                strlen := i32(len(str)-1);
                data.buf_text_len = strlen;
                data.cursor_pos = strlen;
                data.selection_start = strlen;
                data.selection_end = strlen;
                data.buf_dirty = true;
            }
        }

        case imgui.GuiInputTextFlags.CallbackCompletion : {

        }
    }

    return 0;
}

_pull_command_name :: proc(s : string) -> string {
    for r, i in s {
        if r == ' ' {
            return s[0..<i];
        }
    }

    return s;
}

_string_dup :: proc(s : string) -> string {
    data := make([]byte, len(s)+1);
    copy(data, []byte(s[..]));
    return string(data);    
}

_find_string_null :: proc(s : []byte) -> int {
    for r, i in s {
        if r == 0 {
            return i;
        }
    }

    return -1;
}