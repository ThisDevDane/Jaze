/*
 *  @Name:     main
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hoej@northworldprod.com
 *  @Creation: 31-05-2017 21:57:56
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 27-11-2017 00:13:43
 *  
 *  @Description:
 *      Entry point of Jaze
 */
import "core:fmt.odin";
import "core:os.odin";
import "core:strings.odin";
import "core:mem.odin";

import       "mantle:libbrew/win/window.odin";
import       "mantle:libbrew/win/msg.odin";
import       "mantle:libbrew/win/file.odin";
import misc  "mantle:libbrew/win/misc.odin";
import input "mantle:libbrew/win/keys.odin";
import wgl   "mantle:libbrew/win/opengl.odin";

import       "mantle:libbrew/gl.odin";
import imgui "mantle:libbrew/brew_imgui.odin";
import       "mantle:libbrew/string_util.odin";

import       "mantle:odin-xinput/xinput.odin"; 
import curl  "mantle:ocurl/ocurl_easy.odin";

import         "debug_info.odin";
import         "gl_util.odin";
import         "engine.odin";
import         "console.odin";
import         "catalog.odin";
import leak    "leakcheck_allocator.odin";
import obj     "obj_parser.odin";
import shower  "window_shower.odin";
import dbg_win "debug_windows.odin";
import jinput  "input.odin";
import ja      "asset.odin";
import kvs     "key_value_store.odin";

opengl_debug_callback :: proc "cdecl" (source : gl.DebugSource, type_ : gl.DebugType, id : i32, severity : gl.DebugSeverity, length : i32, message : ^u8, userParam : rawptr) {
    console.log_error("[%v | %v | %v] %s \n", source, type_, severity, strings.to_odin_string(message));
}

console_error_callback :: proc() {
    b := shower.get_window_state("console");
    if !b {
        shower.toggle_window_state("console");
    }
}

set_proc_gl :: proc(lib_ : rawptr, p: rawptr, name: string) {
    set_proc(lib_, p, name, &debug_info.ogl);
}

set_proc_xinput :: proc(lib_ : rawptr, p: rawptr, name: string) {
    set_proc(lib_, p, name, &debug_info.xinput);
}

set_proc :: inline proc(lib_ : rawptr, p: rawptr, name: string, info : ^debug_info.Info) {
    lib := misc.LibHandle(lib_);
    res := wgl.get_proc_address(name);
    if res == nil {
        res = misc.get_proc_address(lib, name);
    }   
    if res == nil {
        fmt.println("Couldn't load:", name);
    }

    (^rawptr)(p)^ = rawptr(res);

    status := debug_info.Function_Load_Status{};
    status.name = name;
    status.address = int(uintptr(rawptr(res)));
    status.success = false;
    info.number_of_functions_loaded += 1;

    if status.address != 0 {
        status.success = true;
        info.number_of_functions_loaded_successed += 1;
    }
    append(&info.statuses, status);

}

load_lib :: proc(str : string) -> rawptr {
    return rawptr(misc.load_library(str));
}

free_lib :: proc(lib : rawptr) {
    misc.free_library(misc.LibHandle(lib));
}

main :: proc() {
context <- mem.context_from_allocator(leak.leakcheck()) {
    console.set_error_callback(console_error_callback);
    console.add_default_commands();
    console.log("Program Start...");
    app_handle := misc.get_app_handle();
    width, height := 1280, 720;
    console.log("Creating Window...");
    wnd_handle := window.create_window(app_handle, "LibBrew Example", true, 100, 100, width, height);
    console.log("Creating GL Context...");
    glCtx      := wgl.create_gl_context(wnd_handle, 4, 5);
    console.log("Load GL Functions...");
    gl.load_functions(set_proc_gl, load_lib, free_lib);

    dear_state := new(imgui.State);
    console.log("Initialize Dear ImGui...");
    imgui.init(dear_state, wnd_handle);

    wgl.swap_interval(-1);
    gl.clear_color(41/255.0, 57/255.0, 84/255.0, 1);

    message               : msg.Msg;
    show_imgui            : bool = true;
    mpos_x                : int;
    mpos_y                : int;
    prev_lm_down          : bool;
    lm_down               : bool;
    rm_down               : bool;
    scale_by_max          : bool = false;
    adaptive_vsync        : bool = true;

    time_data             := misc.create_time_data();
    acc_time              := 0.0;
    i                     := 0;
    dragging              := false;
    sizing_x              := false;
    sizing_y              := false;
    maximized             := false;
    shift_down            := false;
    new_frame_state       := imgui.FrameState{};
    show_test             := false;
    show_gl_info          := false;
    show_shower_state    := false;
    gl_vars               := gl.OpenGLVars{};
    
    console.log("Setting up catalogs...");
    catalog.add_extensions(catalog.Asset_Kind.Texture, ".png", ".bmp", ".PNG", ".jpg", ".jpeg");
    catalog.add_extensions(catalog.Asset_Kind.Sound, ".ogg");
    catalog.add_extensions(catalog.Asset_Kind.ShaderSource, ".vs", ".vert", ".glslv");
    catalog.add_extensions(catalog.Asset_Kind.ShaderSource, ".fs", ".frag", ".glslf");
    catalog.add_extensions(catalog.Asset_Kind.Font, ".ttf");
    catalog.add_extensions(catalog.Asset_Kind.Model3D, ".obj");
    test_catalog    := catalog.create("test", "data\\test");
    texture_catalog := catalog.create("texture", "data\\textures");
    shader_catalog  := catalog.create("shader", "data\\shaders");
    sound_catalog   := catalog.create("sound", "data\\sounds");
    map_catalog     := catalog.create("map", "data\\maps");
    font_catalog    := catalog.create("font", "data\\fonts");
    model_catalog   := catalog.create("model", "data\\models");
    
    shower.set_window_state("console", true);
    
    console.log("Creating engine context");
    EngineContext := engine.create_default_context();

    console.log("Setting up OpenGL");
    gl.debug_message_callback(opengl_debug_callback, nil);
    gl.enable(gl.Capabilities.DebugOutputSynchronous);
    gl.debug_message_control(gl.DebugSource.DontCare, gl.DebugType.DontCare, gl.DebugSeverity.Notification, 0, nil, false);
    gl.get_info(&gl_vars);

    xinput.init(set_proc_xinput, load_lib, true);

    console.log("Model test setup");
    vertexAsset  := catalog.find(shader_catalog, "basic_vert");
    fragAsset    := catalog.find(shader_catalog, "basic_frag");
    vertex       := vertexAsset.derived.(^ja.Shader);
    frag         := fragAsset.derived.(^ja.Shader);
    test_program := gl_util.create_program(vertex, frag);
    test_program.Attributes["model_pos"] = gl.get_attrib_location(test_program, "model_pos");
    test_program.Attributes["model_norm"] = gl.get_attrib_location(test_program, "model_norm");

    test_program.Uniforms["angle"] = gl.get_uniform_location(test_program, "angle");
    test_program.Uniforms["res"] = gl.get_uniform_location(test_program, "res");

    test_vao := gl.gen_vertex_array();
    gl.bind_vertex_array(test_vao);
    test_vbo := gl.gen_vbo();
    test_normals := gl.gen_vbo();
    test_ebo := gl.gen_ebo();
    model_asset := catalog.find(model_catalog, "monkey");
    model := model_asset.derived.(^ja.Model_3d);
    {
        if model != nil {
            gl.bind_buffer(test_vbo);
            gl.buffer_data(gl.BufferTargets.Array, model.vertices[..], gl.BufferDataUsage.StaticDraw);
            gl.enable_vertex_attrib_array(u32(test_program.Attributes["model_pos"]));
            gl.vertex_attrib_pointer(u32(test_program.Attributes["model_pos"]), 3, gl.VertexAttribDataType.Float, false, 3 * size_of(f32), nil);
            
            gl.bind_buffer(test_ebo);
            gl.buffer_data(gl.BufferTargets.ElementArray, model.vert_indices[..], gl.BufferDataUsage.StaticDraw);
            
            gl.bind_buffer(test_normals);
            gl.buffer_data(gl.BufferTargets.Array, model.normals[..], gl.BufferDataUsage.StaticDraw);
            gl.enable_vertex_attrib_array(u32(test_program.Attributes["model_norm"]));
            gl.vertex_attrib_pointer(u32(test_program.Attributes["model_norm"]), 3, gl.VertexAttribDataType.Float, false, 3 * size_of(f32), nil);
        } else {
            console.log_error("Could not load monkey");       
        }
    }

    console.log("Entering Main Loop...");
main_loop: 
    for {
        prev_lm_down = lm_down ? true : false;
        for msg.poll_message(&message) {
            switch msg in message {
                case msg.MsgQuitMessage : {
                    break main_loop;
                }

                case msg.MsgChar : {
                    imgui.gui_io_add_input_character(u16(msg.char));
                    jinput.add_char_to_queue(EngineContext.input, msg.char);
                }

                case msg.MsgKey : {
                    switch msg.key {
                        case input.VirtualKey.Escape : {
                            if msg.down == true && shift_down {
                                break main_loop;
                            }
                        }

                        case input.VirtualKey.Tab : {
                            if msg.down {
                                show_imgui = !show_imgui;
                            }
                        }

                        case input.VirtualKey.Lshift : {
                            shift_down = msg.down;
                        }
                    }
                }

                case msg.MsgMouseButton : {
                    switch msg.key {
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
                    jinput.set_input_neutral(EngineContext.input);
                }

                /*case msg.Msg.MouseMove : {
                    mpos_x = msg.x;
                    mpos_y = msg.y;
                }*/

                case msg.MsgSizeChange : {
                    width = msg.width;
                    height = msg.height;
                    gl.viewport(0, 0, i32(width), i32(height));
                    gl.scissor (0, 0, i32(width), i32(height));
                }
            }
        }
        dt := misc.time(&time_data);
        acc_time += dt;
        mpos_x, mpos_y = window.get_mouse_pos(wnd_handle);
        new_frame_state.deltatime = f32(dt);
        new_frame_state.mouse_x = mpos_x;
        new_frame_state.mouse_y = mpos_y;
        new_frame_state.window_width = width;
        new_frame_state.window_height = height;
        new_frame_state.left_mouse = lm_down;
        new_frame_state.right_mouse = rm_down;

        gl.clear(gl.ClearFlags.COLOR_BUFFER | gl.ClearFlags.DEPTH_BUFFER);

        {
            gl.bind_vertex_array(test_vao);
            gl.use_program(test_program);
            gl.uniform(test_program.Uniforms["angle"], f32(acc_time ));
            gl.uniform(test_program.Uniforms["res"], f32(width), f32(height));
            gl.enable(gl.Capabilities.DepthTest);
            gl.draw_elements(gl.DrawModes.Triangles, model.vert_ind_num, gl.DrawElementsType.UInt, nil);
        }

        if new_frame_state.window_focus {
            jinput.update(EngineContext.input);
        }
        imgui.begin_new_frame(&new_frame_state);
        imgui.begin_main_menu_bar();
        {
            h := imgui.is_window_hovered();
            f := imgui.is_window_focused();
            if f && h { //NOTE: kinda works, needs more work
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
            } else {
                dragging = false;
            }

            imgui.begin_menu("Jaze    |###WindowTitle", false);
            if imgui.begin_menu("Misc###LibbrewMain") {
                if imgui.checkbox("Adpative Vsync", &adaptive_vsync) {
                    wgl.swap_interval(adaptive_vsync ? -1 : 0);
                }
                if imgui.menu_item(label = "Show Test Window") {
                    shower.toggle_window_state("test_window");
                }
                imgui.menu_item(label = "LibBrew Info", enabled = false);
                if imgui.menu_item(label = "OpenGL Info") {
                    shower.toggle_window_state("opengl_info");
                }
                if imgui.begin_menu("xInput") {
                    if imgui.menu_item(label = "Info") {
                        shower.toggle_window_state("xinput_info");
                    }
                    if imgui.menu_item(label = "State") {
                        shower.toggle_window_state("xinput_state");
                    }
                    imgui.end_menu();
                }
                if imgui.menu_item(label = "Debug Windows Info") {
                    shower.toggle_window_state("debug_state");
                }
                if imgui.menu_item(label = "Console") {
                    shower.toggle_window_state("console");
                }
                if imgui.menu_item(label = "Catalog") {
                    shower.toggle_window_state("catalog_window");
                }
                if imgui.menu_item(label = "Input") {
                    shower.toggle_window_state("input_window");
                }
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
            d : imgui.Vec2;
            imgui.get_mouse_drag_delta(&d);
            x, y := window.get_window_pos(wnd_handle);
            window.set_window_pos(wnd_handle, x + int(d.x), y + int(d.y));
            if maximized && d.x != 0 && d.y != 0 {
                maximized = false;
                window.restore_window(wnd_handle);
            }
        } else {
            dragging = false;
        }

        is_between :: inline proc(v, min, max : int) -> bool {
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
       /* if imgui.begin("Source Test") {
            output_line_number :: proc(i : int) {
                imgui.push_style_color(imgui.GuiCol.Text, imgui.Vec4{1, 1, 1, 0.4});
                imgui.text("%v", i); imgui.same_line(0, 5);
                imgui.pop_style_color();
            }

            imgui.begin_child(str_id = "source", border = false);
            {
                i := 0;
                output_line_number(i);
                line, r := string_util.get_line_and_remainder(shader.source);
                imgui.text(line);
                for r != "" {
                    line, r = string_util.get_line_and_remainder(r);
                    i += 1;
                    output_line_number(i);
                    imgui.text(line);
                }
            }
            imgui.end_child();
        }
        imgui.end();*/

        if shower.get_window_state("test_window") {
            b := shower.get_window_state("test_window");
            imgui.show_test_window(&b);
            shower.set_window_state("test_window", b);
        }

        if shower.get_window_state("opengl_info") {
            b := shower.get_window_state("opengl_info");
            dbg_win.opengl_info(&gl_vars, &b);
            shower.set_window_state("opengl_info", b);
        }

        if shower.get_window_state("input_window") {
            b := shower.get_window_state("input_window");
            dbg_win.show_input_window(EngineContext.input, &b);
            shower.set_window_state("input_window", b);
        }
        if shower.get_window_state("catalog_window") {
            b := shower.get_window_state("catalog_window");
            dbg_win.show_catalog_window(catalog.created_catalogs[..], &b);
            shower.set_window_state("catalog_window", b);
        }

        shower.try_show_window("texture_overview", dbg_win.show_gl_texture_overview);
        shower.try_show_window("debug_state",      shower.show_debug_windows_states);
        shower.try_show_window("xinput_info",      dbg_win.show_xinput_info_window);
        shower.try_show_window("xinput_state",     dbg_win.show_xinput_state_window);
        shower.try_show_window("console",          console.draw_console);
        shower.try_show_window("console_log",      console.draw_log);

        dbg_win.stat_overlay(nil);

        jinput.clear_char_queue(EngineContext.input);
        if(show_imgui) {
            imgui.render_proc(dear_state, width, height);
        }
        window.swap_buffers(wnd_handle);
        //brew.sleep(1);
    }

    console.log("Ending Application...");
    imgui.shutdown();
}
}