/*
 *  @Name:     console
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 10-05-2017 21:11:30
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 15-11-2017 18:28:10
 *  
 *  @Description:
 *      The console is an in engine window that can be pulled up for viewing.
 *      It also takes care of outputting to a log file if enabled.
 *      The console can also execute commands if matched with input.
 */
import "core:fmt.odin";
import "core:os.odin";
import "core:mem.odin";
import "core:strings.odin";

import shower "window_shower.odin";

import           "mantle:libbrew/string_util.odin"
import win32     "core:sys/windows.odin";
import imgui     "mantle:libbrew/brew_imgui.odin";

OUTPUT_TO_CLI  :: true;
OUTPUT_TO_FILE :: false;

_BUF_SIZE :: 1024;

CommandProc :: #type proc(args : []string);

LogData :: struct {
    input_buf     : [256]u8,
    log           : [dynamic]LogItem,
    history       : [dynamic]string,
    current_log   : [dynamic]LogItem,
    commands      : map[string]CommandProc,
    log_file_name : string,

    _scroll_to_bottom : bool,
    _history_pos      : int, 
}

LogItem :: struct {
    text : string,
    time : win32.Systemtime,
    level : LogLevel,
}

_internal_data := LogData{};

LogLevel :: enum {
    Normal,
    ConsoleInput,
    Error,
}

_error_callback : proc();

log_error :: proc(fmt_ : string, args : ...any) {
    _internal_log(fmt_, LogLevel.Error,...args);
    if _error_callback != nil {
        _error_callback();
    }
}

log :: proc(fmt_ : string, args : ...any) {
    _internal_log(fmt_, LogLevel.Normal, ...args);
}

set_error_callback :: proc(callback : proc()) {
    _error_callback = callback;
}

_get_system_time :: proc() -> win32.Systemtime 
{
    ft : win32.Filetime;
    st : win32.Systemtime;
    win32.get_system_time_as_file_time(&ft);
    win32.file_time_to_system_time(&ft, &st);

    return st;
}

_internal_log :: proc(fmt_ : string, level : LogLevel, args : ...any) {
    buf  : [_BUF_SIZE]u8;
    buf2 : [_BUF_SIZE]u8;
    //buf3 : [_BUF_SIZE]u8;
    levelStr : string;
    h := os.stdout;
    switch level {
        case LogLevel.Normal : {
            levelStr = "";
        }

        case LogLevel.Error : {
            levelStr = "[Error]: ";
            h = os.stderr;
        }

        case LogLevel.ConsoleInput : {
            levelStr = "\\\\: ";
            h = os.stdout;
        }
    }
    newFmt := fmt.bprintf(buf[..], "%s%s", levelStr, fmt_);
    tempStr := fmt.bprintf(buf2[..], newFmt, ...args);
    
    when OUTPUT_TO_CLI {
        fmt.fprintf(h, "%s\n", tempStr);
    }
   
    st := _get_system_time();
    
    item := LogItem{};
    item.text = strings.new_string(tempStr);
    item.time = st;
    item.level = level;

    append(&_internal_data.current_log, item);
    item.text = strings.new_string(tempStr); //Note: needed cause clear console free's the item.text
    append(&_internal_data.log, item);
    _internal_data._scroll_to_bottom = true;
    when OUTPUT_TO_FILE {
        _update_log_file();
    }
}

_update_log_file :: proc() {
    if len(_internal_data.log_file_name) <= 0 {
        st := _get_system_time();
        buf := make([]u8, 255);
        _internal_data.log_file_name = fmt.bprintf(buf[..], "%d-%d-%d_%d%d%d.jlog", 
                                                st.day, st.month, st.year, 
                                                st.hour, st.minute, st.second);
    }

    h, _ := os.open(_internal_data.log_file_name, os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0);
    os.seek(h, 0, 2);
    for log in _internal_data.log {
        buf : [_BUF_SIZE]u8;
        str := fmt.bprintf(buf[..], "[%2d:%2d:%2d-%3d]%s\n", log.time.hour,   log.time.minute, 
                                                              log.time.second, log.time.millisecond, 
                                                              log.text);
        os.write(h, cast([]u8)str);
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

//TODO(Hoej): Display is horrible since work is incomplete, need to figure out how I want to do it
draw_log :: proc(show : ^bool) {
    imgui.begin("Log", show, imgui.WindowFlags.ShowBorders |  imgui.WindowFlags.NoCollapse);
    {
        imgui.begin_child("Items");
        {
            for t in _internal_data.log {
                imgui.text("%2d:%2d:%2d-%3d", t.time.hour, t.time.minute, t.time.second, t.time.millisecond);
                imgui.same_line();

                imgui.same_line();
                switch t.level {
                    case LogLevel.Error : {
                        imgui.text("[Error]:");
                        imgui.same_line();
                        imgui.text_colored(imgui.Vec4{1, 0, 0, 1}, t.text);
                    }

                    case LogLevel.ConsoleInput : {
                        imgui.text("\\\\:     ");
                        imgui.same_line();
                        imgui.text_colored(imgui.Vec4{0.7, 0.7, 0.7, 1}, t.text);
                    }

                    case : {
                        imgui.text("        ");
                        imgui.same_line();
                        imgui.text(t.text);
                    }
                }
            }
        }
        imgui.end_child();
    }
    imgui.end();
}

draw_console :: proc(show : ^bool) {
    imgui.begin("Console", show, imgui.WindowFlags.ShowBorders |  imgui.WindowFlags.NoCollapse | imgui.WindowFlags.MenuBar);
    {
        if imgui.begin_menu_bar() {
            if imgui.begin_menu("Misc", true) {
                if imgui.menu_item("Show Log", "", false, len(_internal_data.log) > 0) {
                    
                    shower.toggle_window_state("console_log");
                }              
                if imgui.menu_item("Clear", "", false, len(_internal_data.current_log) > 0) {
                    clear_console();
                }

                imgui.end_menu();
            }
            imgui.end_menu_bar();
        }

        imgui.begin_child("Buffer", imgui.Vec2{-1, -40}, true);
        {
            for t in _internal_data.current_log {
                pop := false;
                switch t.level {
                    case LogLevel.Error : {
                        imgui.push_style_color(imgui.Color.Text, imgui.Vec4{1, 0, 0, 1});
                        pop = true;
                    }

                    case LogLevel.ConsoleInput : {
                        imgui.push_style_color(imgui.Color.Text, imgui.Vec4{0.7, 0.7, 0.7, 1});
                        pop = true;
                    }
                }
                imgui.text_wrapped(t.text);
                if pop do imgui.pop_style_color();
            }

            if _internal_data._scroll_to_bottom {
                imgui.set_scroll_here(0.5);
            }
            _internal_data._scroll_to_bottom = false;
        }
        imgui.end_child();

        TEXT_FLAGS :: imgui.InputTextFlags.EnterReturnsTrue | imgui.InputTextFlags.CallbackCompletion | imgui.InputTextFlags.CallbackHistory;
        if imgui.input_text("##Input", _internal_data.input_buf[..], TEXT_FLAGS, _text_edit_callback) {
            imgui.set_keyboard_focus_here(-1);
            enter_input(_internal_data.input_buf[..]);
        }
        imgui.same_line(0, -1);
        if imgui.button("Enter", imgui.Vec2{-1, 0}) {
            enter_input(_internal_data.input_buf[..]);
        }
        imgui.separator();
        imgui.text_colored(imgui.Vec4{1, 1, 1, 0.2}, "Current: %d | Log : %d | History: %d", len(_internal_data.current_log), 
                                                                                             len(_internal_data.log), 
                                                                                             len(_internal_data.history));
    }
    imgui.end();
}

enter_input :: proc(input : []u8) {
    if input[0] != 0 &&
       input[0] != ' ' {
        i := _find_string_null(input[..]);
        str := string(input[0..i]);
        _internal_log(str, LogLevel.ConsoleInput);
        append(&_internal_data.history, strings.new_string(str));
        if !execute_command(str) {
            cmd_name, _ := string_util.split_first(str, ' ');
            log_error("%s is not a command", cmd_name);
        }
        input[0] = 0;
        _internal_data._scroll_to_bottom = true;
        _internal_data._history_pos = 0;
    }
}

clear_console :: proc() {
    for t in _internal_data.current_log {
        free(t.text);
    }
    clear(&_internal_data.current_log);
}

execute_command :: proc(cmdString : string) -> bool {
    name, _ := string_util.split_first(cmdString, ' ');
    if cmd, ok := _internal_data.commands[name]; ok {
        args : [dynamic]string;
        //TODO(Hoej): Revisist all of this
        if len(cmdString) != len(name) {
            p := 0;
            newStr := cmdString[len(name)+1..];
            for r, i in newStr {
                if r == ' ' {
                    append(&args, newStr[p..i]);
                    p = i+1;
                }

                if i == len(newStr)-1 {
                    append(&args, newStr[p..i+1]);
                }
            }
        }
        cmd(args[..]);
        return true;
    }
    return false;
}

_text_edit_callback :: proc "cdecl"(data : ^imgui.TextEditCallbackData) -> i32{
    switch data.event_flag {
        case imgui.InputTextFlags.CallbackHistory : {
            using _internal_data;
            prev := _history_pos;

            if data.event_key == imgui.Key.UpArrow {
                if _history_pos == 0 {
                    _history_pos = len(history);
                } else {
                    _history_pos -= 1;
                }
            } else if data.event_key == imgui.Key.DownArrow {
                if _history_pos != 0 {
                    _history_pos += 1;
                    if _history_pos > len(history) {
                        _history_pos = 0;
                    }
                }
            }

            if prev != _history_pos {
                pos := _history_pos > 0 ? _history_pos-1 : -1;  
                slice := cast([]u8)mem.slice_ptr(&data.buf^, int(data.buf_size));
                str := fmt.bprintf(slice, "%s", pos < 0 ? "" : history[pos]);
                strlen := i32(len(str)-1);
                data.buf_text_len = strlen;
                data.cursor_pos = strlen;
                data.selection_start = strlen;
                data.selection_end = strlen;
                data.buf_dirty = true;
            }
        }

        case imgui.InputTextFlags.CallbackCompletion : {
            //TODO(Hoej): Tab to complete partial command/cycle
            //            or maybe just print a list of commands that could match 
        }
    }

    return 0;
}

_find_string_null :: proc(s : []u8) -> int {
    for r, i in s {
        if r == 0 {
            return i;
        }
    }

    return -1;
}