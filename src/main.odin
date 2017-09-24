/*
 *  @Name:     main
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 31-05-2017 21:57:56
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 24-09-2017 22:26:50
 *  
 *  @Description:
 *      Entry point of Jaze
 */
import "core:fmt.odin";
import "core:os.odin";
import "core:strings.odin";

import misc "libbrew/win/misc.odin";
import "libbrew/win/window.odin";
import "libbrew/gl.odin";
import imgui "libbrew/brew_imgui.odin";
import wgl "libbrew/win/opengl.odin";
import "libbrew/win/msg.odin";
import input "libbrew/win/keys.odin";

import "engine.odin";

main :: proc() {
    fmt.println("Program Start...");
    app_handle := misc.get_app_handle();
    width, height := 1280, 720;
    fmt.println("Creating Window...");
    wnd_handle := window.create_window(app_handle, "LibBrew Example", true, 100, 100, width, height);
    fmt.println("Creating GL Context...");
    glCtx      := wgl.create_gl_context(wnd_handle, 3, 3);
    fmt.println("Load GL Functions...");
    gl.load_functions();

    dear_state := new(imgui.State);
    fmt.println("Initialize Dear ImGui...");
    imgui.init(dear_state, wnd_handle);

    wgl.swap_interval(-1);
    gl.clear_color(41/255.0, 57/255.0, 84/255.0, 1);

    message         : msg.Msg;
    mpos_x          : int;
    mpos_y          : int;
    prev_lm_down    : bool;
    lm_down         : bool;
    rm_down         : bool;
    scale_by_max    : bool = false;
    time_data       := misc.create_time_data();
    i               := 0;
    dragging        := false;
    sizing_x        := false;
    sizing_y        := false;
    maximized       := false;
    shift_down      := false;
    new_frame_state := imgui.FrameState{};
    show_test       := false;

    fmt.println("Creating engine context");
    EngineContext := engine.create_context();
    engine.set_context_defaults(EngineContext);


    fmt.println("Entering Main Loop...");
main_loop: 
    for {
        prev_lm_down = lm_down ? true : false;
        for msg.poll_message(&message) {
            match msg in message {
                case msg.MsgQuitMessage : {
                    break main_loop;
                }

                case msg.MsgKey : {
                    match msg.key {
                        case input.VirtualKey.Escape : {
                            if msg.down == true && shift_down {
                                break main_loop;
                            }
                        }

                        case input.VirtualKey.Lshift : {
                            shift_down = msg.down;
                        }
                    }
                }

                case msg.MsgMouseButton : {
                    match msg.key {
                        case input.VirtualKey.LMouse : {
                            lm_down = msg.down;
                        }

                        case input.VirtualKey.RMouse : {
                            rm_down = msg.down;
                        }
                    }
                }

                case msg.MsgWindowFocus : {
                    new_frame_state.window_focus = msg.enter_focus;
                }

                /*case msg.Msg.MouseMove : {
                    mpos_x = msg.x;
                    mpos_y = msg.y;
                }*/

                case msg.MsgSizeChange : {
                    width = msg.width;
                    height = msg.height;
                    gl.viewport(0, 0, i32(width), i32(height));
                    gl.scissor( 0, 0, i32(width), i32(height));
                }
            }
        }
        dt := misc.time(&time_data);
        mpos_x, mpos_y = window.get_mouse_pos(wnd_handle);
        new_frame_state.deltatime = f32(dt);
        new_frame_state.mouse_x = mpos_x;
        new_frame_state.mouse_y = mpos_y;
        new_frame_state.window_width = width;
        new_frame_state.window_height = height;
        new_frame_state.left_mouse = lm_down;
        new_frame_state.right_mouse = rm_down;

        gl.clear(gl.ClearFlags.COLOR_BUFFER);

        imgui.begin_new_frame(&new_frame_state);

        imgui.begin_main_menu_bar();
        {
            imgui.begin_menu("Jaze  |###WindowTitle", false);
            if imgui.is_item_clicked(0) {
                dragging = true;
                if imgui.is_mouse_double_clicked(0) {
                    dragging = false;
                    if !maximized {
                        window.maximize_window(wnd_handle);
                        maximized = true;
                    } else {
                        window.restore_window(wnd_handle);
                        maximized = false;
                    }
                }
            }
            if imgui.begin_menu("Misc###LibbrewMain") {
                if imgui.menu_item(label = "Show Test Window") {
                    show_test = !show_test;
                }
                imgui.menu_item(label = "LibBrew Info", enabled = false);
                imgui.menu_item(label = "OpenGL Info", enabled = false);
                imgui.separator();
                imgui.menu_item("Toggle Fullscreen", "Alt+Enter", false);
                if imgui.menu_item("Exit", "LShift + Esc") {
                    break main_loop;
                }
                imgui.end_menu();
            }
        }
        imgui.end_main_menu_bar();

        if imgui.is_mouse_down(0) && dragging {
            d := imgui.get_mouse_drag_delta();
            x, y := window.get_window_pos(wnd_handle);
            window.set_window_pos(wnd_handle, x + int(d.x), y + int(d.y));
            if maximized && d.x != 0 && d.y != 0 {
                maximized = false;
                window.restore_window(wnd_handle);
            }
        } else {
            dragging = false;
        }

        if imgui.begin_panel("TEST##1", imgui.Vec2{0, 19}, imgui.Vec2{f32(width/2), f32(height-19)}) {
            defer imgui.end();
        }

        if imgui.begin_panel("TEST##2", imgui.Vec2{f32(width/2), 19}, imgui.Vec2{f32(width/2), f32(height-19)}) {
            defer imgui.end();
        }

        is_between :: proc(v, min, max : int) -> bool #inline {
            return v >= min && v <= max;
        }

        if lm_down && !prev_lm_down { 
            if is_between(mpos_x, width-4, width+4) {
                sizing_x = true;
            }

            if is_between(mpos_y, height-4, height+4) {
                sizing_y = true;
            }
        }

        new_w : int;
        new_h : int;
       
        if (sizing_x || sizing_y) && lm_down {
            new_w = sizing_x ? mpos_x+2 : width;
            new_h = sizing_y ? mpos_y+2 : height;
            window.set_window_size(wnd_handle, new_w+2, new_h+2);
        } else {
            sizing_x = false;
            sizing_y = false;
        }

        imgui.show_test_window(&show_test);

        imgui.render_proc(dear_state, width, height);
        window.swap_buffers(wnd_handle);
        //brew.sleep(1);
    }

    imgui.shutdown();
    fmt.println("Ending Application...");
}