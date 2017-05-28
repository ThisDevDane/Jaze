/*
 *  @Name:     jimgui
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 02-05-2017 21:38:35
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 28-05-2017 22:21:42
 *  
 *  @Description:
 *      Contains user specific data and functions related to using Dear ImGui.
 */
#import "imgui.odin";
#import win32 "sys/windows.odin";
#import "fmt.odin";
#import "math.odin";
#import "main.odin";
#import "gl.odin";
#import "engine.odin";
#import gl_util "gl_util.odin";

State :: struct {
    //Misc
    mouse_wheel_delta : i32,

    //Render
    main_program      : gl.Program,

    vbo_handle        : gl.VBO,
    ebo_handle        : gl.EBO,
    vao_handle        : gl.VAO,

    font_texture      : gl.Texture,
}

set_style :: proc() {
    style := imgui.get_style();

    style.window_rounding = 1.0;
    style.child_window_rounding  = 1.0;
    style.frame_rounding = 1.0;
    style.grab_rounding = 1.0;

    style.scrollbar_size = 12.0;

    style.colors[imgui.GuiCol.Text]                  = imgui.Vec4{1.00, 1.00, 1.00, 1.00};
    style.colors[imgui.GuiCol.TextDisabled]          = imgui.Vec4{0.63, 0.63, 0.63, 1.00};
    style.colors[imgui.GuiCol.WindowBg]              = imgui.Vec4{0.23, 0.23, 0.23, 0.98};
    style.colors[imgui.GuiCol.ChildWindowBg]         = imgui.Vec4{0.20, 0.20, 0.20, 1.00};
    style.colors[imgui.GuiCol.PopupBg]               = imgui.Vec4{0.25, 0.25, 0.25, 0.96};
    style.colors[imgui.GuiCol.Column]                = imgui.Vec4{0.18, 0.18, 0.18, 0.98};
    style.colors[imgui.GuiCol.Border]                = imgui.Vec4{0.18, 0.18, 0.18, 0.98};
    style.colors[imgui.GuiCol.BorderShadow]          = imgui.Vec4{0.00, 0.00, 0.00, 0.04};
    style.colors[imgui.GuiCol.FrameBg]               = imgui.Vec4{0.00, 0.00, 0.00, 0.29};
    style.colors[imgui.GuiCol.TitleBg]               = imgui.Vec4{0.25, 0.25, 0.25, 0.98};
    style.colors[imgui.GuiCol.TitleBgCollapsed]      = imgui.Vec4{0.25, 0.25, 0.25, 0.49};
    style.colors[imgui.GuiCol.TitleBgActive]         = imgui.Vec4{0.33, 0.33, 0.33, 0.98};
    style.colors[imgui.GuiCol.MenuBarBg]             = imgui.Vec4{0.11, 0.11, 0.11, 0.42};
    style.colors[imgui.GuiCol.ScrollbarBg]           = imgui.Vec4{0.00, 0.00, 0.00, 0.08};
    style.colors[imgui.GuiCol.ScrollbarGrab]         = imgui.Vec4{0.27, 0.27, 0.27, 1.00};
    style.colors[imgui.GuiCol.ScrollbarGrabHovered]  = imgui.Vec4{0.78, 0.78, 0.78, 0.40};
    style.colors[imgui.GuiCol.CheckMark]             = imgui.Vec4{0.78, 0.78, 0.78, 0.94};
    style.colors[imgui.GuiCol.SliderGrab]            = imgui.Vec4{0.78, 0.78, 0.78, 0.94};
    style.colors[imgui.GuiCol.Button]                = imgui.Vec4{0.42, 0.42, 0.42, 0.60};
    style.colors[imgui.GuiCol.ButtonHovered]         = imgui.Vec4{0.78, 0.78, 0.78, 0.40};
    style.colors[imgui.GuiCol.Header]                = imgui.Vec4{0.31, 0.31, 0.31, 0.98};
    style.colors[imgui.GuiCol.HeaderHovered]         = imgui.Vec4{0.78, 0.78, 0.78, 0.40};
    style.colors[imgui.GuiCol.HeaderActive]          = imgui.Vec4{0.80, 0.50, 0.50, 1.00};
    style.colors[imgui.GuiCol.TextSelectedBg]        = imgui.Vec4{0.65, 0.35, 0.35, 0.26};
    style.colors[imgui.GuiCol.ModalWindowDarkening]  = imgui.Vec4{0.20, 0.20, 0.20, 0.35};
}

init :: proc(ctx : ^engine.Context) {
    io := imgui.get_io();
    io.ime_window_handle = ctx.win32.WindowHandle;
    //io.RenderDrawListsFn = RenderProc;

    io.key_map[imgui.GuiKey.Tab]        = i32(win32.KeyCode.Tab);
    io.key_map[imgui.GuiKey.LeftArrow]  = i32(win32.KeyCode.Left);
    io.key_map[imgui.GuiKey.RightArrow] = i32(win32.KeyCode.Right);
    io.key_map[imgui.GuiKey.UpArrow]    = i32(win32.KeyCode.Up);
    io.key_map[imgui.GuiKey.DownArrow]  = i32(win32.KeyCode.Down);
    io.key_map[imgui.GuiKey.PageUp]     = i32(win32.KeyCode.Next);
    io.key_map[imgui.GuiKey.PageDown]   = i32(win32.KeyCode.Prior);
    io.key_map[imgui.GuiKey.Home]       = i32(win32.KeyCode.Home);
    io.key_map[imgui.GuiKey.End]        = i32(win32.KeyCode.End);
    io.key_map[imgui.GuiKey.Delete]     = i32(win32.KeyCode.Delete);
    io.key_map[imgui.GuiKey.Backspace]  = i32(win32.KeyCode.Back);
    io.key_map[imgui.GuiKey.Enter]      = i32(win32.KeyCode.Return);
    io.key_map[imgui.GuiKey.Escape]     = i32(win32.KeyCode.Escape);
    io.key_map[imgui.GuiKey.A]          = 'A';
    io.key_map[imgui.GuiKey.C]          = 'C';
    io.key_map[imgui.GuiKey.V]          = 'V';
    io.key_map[imgui.GuiKey.X]          = 'X';
    io.key_map[imgui.GuiKey.Y]          = 'Y';
    io.key_map[imgui.GuiKey.Z]          = 'Z';

    vertexShaderString ::
        `#version 330
        uniform mat4 ProjMtx;
        in vec2 Position;
        in vec2 UV;
        in vec4 Color;
        out vec2 Frag_UV;
        out vec4 Frag_Color;
        void main()
        {
           Frag_UV = UV;
           Frag_Color = Color;
           gl_Position = ProjMtx * vec4(Position.xy,0,1);
        }`;

    fragmentShaderString :: 
        `#version 330
        uniform sampler2D Texture;
        in vec2 Frag_UV;
        in vec4 Frag_Color;
        out vec4 Out_Color;
        void main()
        {
           Out_Color = Frag_Color * texture( Texture, Frag_UV.st);
        }`;


    ctx.imgui_state.main_program    = gl.create_program();
    vertexShader,   ok1 := gl_util.create_and_compile_shader(gl.ShaderTypes.Vertex, vertexShaderString);
    fragmentShader, ok2 := gl_util.create_and_compile_shader(gl.ShaderTypes.Fragment, fragmentShaderString);
   
    if !ok1 || !ok2 {
        panic("FUUUCK");
    }

    gl.attach_shader(ctx.imgui_state.main_program, vertexShader);
    ctx.imgui_state.main_program.Vertex = vertexShader;
    gl.attach_shader(ctx.imgui_state.main_program, fragmentShader);
    ctx.imgui_state.main_program.Fragment = fragmentShader;
    gl.link_program(ctx.imgui_state.main_program);
    ctx.imgui_state.main_program.Uniforms["Texture"] = gl.get_uniform_location(ctx.imgui_state.main_program, "Texture");    
    ctx.imgui_state.main_program.Uniforms["ProjMtx"] = gl.get_uniform_location(ctx.imgui_state.main_program, "ProjMtx");

    ctx.imgui_state.main_program.Attributes["Position"] = gl.get_attrib_location(ctx.imgui_state.main_program, "Position");    
    ctx.imgui_state.main_program.Attributes["UV"]       = gl.get_attrib_location(ctx.imgui_state.main_program, "UV");    
    ctx.imgui_state.main_program.Attributes["Color"]    = gl.get_attrib_location(ctx.imgui_state.main_program, "Color");    

    ctx.imgui_state.vbo_handle = gl.VBO(gl.gen_buffer());
    ctx.imgui_state.ebo_handle = gl.EBO(gl.gen_buffer());
    ctx.imgui_state.vao_handle = gl.gen_vertex_array();

    gl.bind_buffer(ctx.imgui_state.vbo_handle);
    gl.bind_buffer(ctx.imgui_state.ebo_handle);
    gl.bind_vertex_array(ctx.imgui_state.vao_handle);

    gl.enable_vertex_attrib_array(u32(ctx.imgui_state.main_program.Attributes["Position"]));
    gl.enable_vertex_attrib_array(u32(ctx.imgui_state.main_program.Attributes["UV"]));
    gl.enable_vertex_attrib_array(u32(ctx.imgui_state.main_program.Attributes["Color"]));

    gl.vertex_attrib_pointer(u32(ctx.imgui_state.main_program.Attributes["Position"]),   2, gl.VertexAttribDataType.Float, false, size_of(imgui.DrawVert), rawptr(int(offset_of(imgui.DrawVert, pos))));
    gl.vertex_attrib_pointer(u32(ctx.imgui_state.main_program.Attributes["UV"]),         2, gl.VertexAttribDataType.Float, false, size_of(imgui.DrawVert), rawptr(int(offset_of(imgui.DrawVert, uv))));
    gl.vertex_attrib_pointer(u32(ctx.imgui_state.main_program.Attributes["Color"]),      4, gl.VertexAttribDataType.UByte, true,  size_of(imgui.DrawVert), rawptr(int(offset_of(imgui.DrawVert, col))));
    
    //CreateFont
    pixels : ^byte;
    width : i32;
    height : i32;
    bytePer : i32;
    imgui.font_atlas_get_text_data_as_rgba32(io.fonts, &pixels, &width, &height, &bytePer);
    ctx.imgui_state.font_texture = gl.gen_texture();
    gl.bind_texture(gl.TextureTargets.Texture2D, ctx.imgui_state.font_texture);
    gl.tex_parameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.MinFilter, gl.TextureParametersValues.Linear);
    gl.tex_parameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.MagFilter, gl.TextureParametersValues.Linear);
    gl.tex_image2d(gl.TextureTargets.Texture2D, 0, gl.InternalColorFormat.RGBA, 
                  width, height, gl.PixelDataFormat.RGBA, 
                  gl.Texture2DDataType.UByte, pixels);
    imgui.font_atlas_set_text_id(io.fonts, rawptr(uint(ctx.imgui_state.font_texture)));

    set_style();
}

begin_new_frame :: proc(deltaTime : f64, ctx : ^engine.Context) {
    io := imgui.get_io();
    io.display_size.x = ctx.window_size.x;
    io.display_size.y = ctx.window_size.y;

    if win32.get_active_window() == win32.Hwnd(io.ime_window_handle) {
        io.mouse_pos.x = ctx.input.mouse_pos.x;
        io.mouse_pos.y = ctx.input.mouse_pos.y;
        io.mouse_down[0] = win32.is_key_down(win32.KeyCode.Lbutton);
        io.mouse_down[1] = win32.is_key_down(win32.KeyCode.Rbutton);

        io.mouse_wheel = f32(ctx.imgui_state.mouse_wheel_delta); 

        io.key_ctrl =  win32.is_key_down(win32.KeyCode.Lcontrol) || win32.is_key_down(win32.KeyCode.Rcontrol);
        io.key_shift = win32.is_key_down(win32.KeyCode.Lshift)   || win32.is_key_down(win32.KeyCode.Rshift);
        io.key_alt =   win32.is_key_down(win32.KeyCode.Lmenu)    || win32.is_key_down(win32.KeyCode.Rmenu);
        io.key_super = win32.is_key_down(win32.KeyCode.Lwin)     || win32.is_key_down(win32.KeyCode.Rwin);

        for i in 0..257 {
            io.keys_down[i] = win32.is_key_down(win32.KeyCode(i));
        }
    } else {
        io.mouse_down[0] = false;
        io.mouse_down[1] = false;
        io.key_ctrl  = false;  
        io.key_shift = false; 
        io.key_alt   = false;   
        io.key_super = false;

        for i in 0..256 { 
            io.keys_down[i] = false;
        }
    }
    
    ctx.imgui_state.mouse_wheel_delta = 0;
    io.delta_time = f32(deltaTime);
    imgui.new_frame();
}
 
render_proc :: proc(ctx : ^engine.Context) {
    imgui.render();
    data := imgui.get_draw_data();

    io := imgui.get_io();
    rect : win32.Rect;
    win32.get_client_rect(win32.Hwnd(io.ime_window_handle), &rect);
    io.display_size.x = f32(rect.right);
    io.display_size.y = f32(rect.bottom);
    width := i32(io.display_size.x * io.display_framebuffer_scale.x);
    height := i32(io.display_size.y * io.display_framebuffer_scale.y);
    if height == 0 || width == 0 {
        //return;
    }
    //draw_data->ScaleClipRects(io.DisplayFramebufferScale);

    //@TODO(Hoej): BACKUP STATE!
    lastViewport : [4]i32;
    lastScissor  : [4]i32;
    gl.get_integer(gl.GetIntegerNames.Viewport, &lastViewport[0]);
    gl.get_integer(gl.GetIntegerNames.ScissorTest, &lastScissor[0]);

    gl.enable(gl.Capabilities.Blend);
    gl.blend_func(gl.BlendFactors.SrcAlpha, gl.BlendFactors.OneMinusSrcAlpha);
    gl.blend_equation(gl.BlendEquations.FuncAdd);
    gl.disable(gl.Capabilities.CullFace);
    gl.disable(gl.Capabilities.DepthTest);
    gl.enable(gl.Capabilities.ScissorTest);
    gl.active_texture(gl.TextureUnits.Texture0);

    gl.viewport(0, 0, width, height);
    ortho_projection := [4][4]f32
    {
        { 2.0 / io.display_size.x,   0.0,                        0.0,    0.0 },
        { 0.0,                      2.0 / -io.display_size.y,    0.0,    0.0 },
        { 0.0,                      0.0,                        -1.0,   0.0 },
        { -1.0,                     1.0,                        0.0,    1.0 },
    };

    gl.use_program(ctx.imgui_state.main_program);
    gl.uniform(ctx.imgui_state.main_program.Uniforms["Texture"], 0);
    gl._uniform_matrix4fv(ctx.imgui_state.main_program.Uniforms["ProjMtx"], 1, 0, &ortho_projection[0][0]);
    gl.bind_vertex_array(ctx.imgui_state.vao_handle);

    newList := slice_ptr(data.cmd_lists, data.cmd_lists_count);
    for n : i32 = 0; n < data.cmd_lists_count; n += 1 {
        list := newList[n];
        idxBufferOffset : ^imgui.DrawIdx = nil;

        gl.bind_buffer(ctx.imgui_state.vbo_handle);
        gl.buffer_data(gl.BufferTargets.Array, i32(imgui.draw_list_get_vertex_buffer_size(list) * size_of(imgui.DrawVert)), imgui.draw_list_get_vertex_ptr(list, 0), gl.BufferDataUsage.StreamDraw);

        gl.bind_buffer(ctx.imgui_state.ebo_handle);
        gl.buffer_data(gl.BufferTargets.ElementArray, i32(imgui.draw_list_get_index_buffer_size(list) * size_of(imgui.DrawIdx)), imgui.draw_list_get_index_ptr(list, 0), gl.BufferDataUsage.StreamDraw);

        for j : i32 = 0; j < imgui.draw_list_get_cmd_size(list); j += 1 {
            cmd := imgui.draw_list_get_cmd_ptr(list, j);
            gl.bind_texture(gl.TextureTargets.Texture2D, gl.Texture(uint(cmd.texture_id)));
            gl.scissor(i32(cmd.clip_rect.x), height - i32(cmd.clip_rect.w), i32(cmd.clip_rect.z - cmd.clip_rect.x), i32(cmd.clip_rect.w - cmd.clip_rect.y));
            gl.draw_elements(gl.DrawModes.Triangles, i32(cmd.elem_count), gl.DrawElementsType.UShort, idxBufferOffset);
            idxBufferOffset += cmd.elem_count;
        }
    }

    //TODO: Restore state
    gl.scissor(lastScissor[0], lastScissor[1], lastScissor[2], lastScissor[3]);
    gl.viewport(lastViewport[0], lastViewport[1], lastViewport[2], lastViewport[3]);
}