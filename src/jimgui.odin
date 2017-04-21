#load "imgui.odin";
#import win32 "sys/windows.odin";
#import "fmt.odin";
#import "gl.odin";
#import glUtil "gl_util.odin";

State_t :: struct {
    //Misc
    MouseWheelDelta  : i32,

    //Render
    MainProgram      : gl.Program,

    VBOHandle        : gl.VBO,
    EBOHandle        : gl.EBO,
    VAOHandle        : gl.VAO,

    FontTexture      : gl.Texture,
}

State : State_t;

SetStyle :: proc() {
    style := GetStyle();

    style.WindowRounding = 1.0;
    style.ChildWindowRounding = 1.0;
    style.FrameRounding = 1.0;
    style.GrabRounding = 1.0;

    style.ScrollbarSize = 12.0;

    style.Colors[GuiCol.Text]                  = Vec4{1.00, 1.00, 1.00, 1.00};
    style.Colors[GuiCol.TextDisabled]          = Vec4{0.63, 0.63, 0.63, 1.00};
    style.Colors[GuiCol.WindowBg]              = Vec4{0.23, 0.23, 0.23, 0.98};
    style.Colors[GuiCol.ChildWindowBg]         = Vec4{0.20, 0.20, 0.20, 1.00};
    style.Colors[GuiCol.PopupBg]               = Vec4{0.25, 0.25, 0.25, 0.96};
    style.Colors[GuiCol.Column]                = Vec4{0.18, 0.18, 0.18, 0.98};
    style.Colors[GuiCol.Border]                = Vec4{0.18, 0.18, 0.18, 0.98};
    style.Colors[GuiCol.BorderShadow]          = Vec4{0.00, 0.00, 0.00, 0.04};
    style.Colors[GuiCol.FrameBg]               = Vec4{0.00, 0.00, 0.00, 0.29};
    style.Colors[GuiCol.TitleBg]               = Vec4{0.25, 0.25, 0.25, 0.98};
    style.Colors[GuiCol.TitleBgCollapsed]      = Vec4{0.25, 0.25, 0.25, 0.49};
    style.Colors[GuiCol.TitleBgActive]         = Vec4{0.33, 0.33, 0.33, 0.98};
    style.Colors[GuiCol.MenuBarBg]             = Vec4{0.11, 0.11, 0.11, 0.42};
    style.Colors[GuiCol.ScrollbarBg]           = Vec4{0.00, 0.00, 0.00, 0.08};
    style.Colors[GuiCol.ScrollbarGrab]         = Vec4{0.27, 0.27, 0.27, 1.00};
    style.Colors[GuiCol.ScrollbarGrabHovered]  = Vec4{0.78, 0.78, 0.78, 0.40};
    style.Colors[GuiCol.CheckMark]             = Vec4{0.78, 0.78, 0.78, 0.94};
    style.Colors[GuiCol.SliderGrab]            = Vec4{0.78, 0.78, 0.78, 0.94};
    style.Colors[GuiCol.Button]                = Vec4{0.42, 0.42, 0.42, 0.60};
    style.Colors[GuiCol.ButtonHovered]         = Vec4{0.78, 0.78, 0.78, 0.40};
    style.Colors[GuiCol.Header]                = Vec4{0.31, 0.31, 0.31, 0.98};
    style.Colors[GuiCol.HeaderHovered]         = Vec4{0.78, 0.78, 0.78, 0.40};
    style.Colors[GuiCol.HeaderActive]          = Vec4{0.80, 0.50, 0.50, 1.00};
    style.Colors[GuiCol.TextSelectedBg]        = Vec4{0.65, 0.35, 0.35, 0.26};
    style.Colors[GuiCol.ModalWindowDarkening]  = Vec4{0.20, 0.20, 0.20, 0.35};
}

Init :: proc(windowHandle : win32.Hwnd) {
    io := GetIO();
    io.ImeWindowHandle = windowHandle;
    io.RenderDrawListsFn = RenderProc;

    io.KeyMap[GuiKey.Tab]        = cast(i32)win32.Key_Code.TAB;
    io.KeyMap[GuiKey.LeftArrow]  = cast(i32)win32.Key_Code.LEFT;
    io.KeyMap[GuiKey.RightArrow] = cast(i32)win32.Key_Code.RIGHT;
    io.KeyMap[GuiKey.UpArrow]    = cast(i32)win32.Key_Code.UP;
    io.KeyMap[GuiKey.DownArrow]  = cast(i32)win32.Key_Code.DOWN;
    io.KeyMap[GuiKey.PageUp]     = cast(i32)win32.Key_Code.NEXT;
    io.KeyMap[GuiKey.PageDown]   = cast(i32)win32.Key_Code.PRIOR;
    io.KeyMap[GuiKey.Home]       = cast(i32)win32.Key_Code.HOME;
    io.KeyMap[GuiKey.End]        = cast(i32)win32.Key_Code.END;
    io.KeyMap[GuiKey.Delete]     = cast(i32)win32.Key_Code.DELETE;
    io.KeyMap[GuiKey.Backspace]  = cast(i32)win32.Key_Code.BACK;
    io.KeyMap[GuiKey.Enter]      = cast(i32)win32.Key_Code.RETURN;
    io.KeyMap[GuiKey.Escape]     = cast(i32)win32.Key_Code.ESCAPE;
    io.KeyMap[GuiKey.A]          = 'A';
    io.KeyMap[GuiKey.C]          = 'C';
    io.KeyMap[GuiKey.V]          = 'V';
    io.KeyMap[GuiKey.X]          = 'X';
    io.KeyMap[GuiKey.Y]          = 'Y';
    io.KeyMap[GuiKey.Z]          = 'Z';

    vertexShaderString :=
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

    fragmentShaderString := 
        `#version 330
        uniform sampler2D Texture;
        in vec2 Frag_UV;
        in vec4 Frag_Color;
        out vec4 Out_Color;
        void main()
        {
           Out_Color = Frag_Color * texture( Texture, Frag_UV.st);
        }`;


    State.MainProgram    = gl.CreateProgram();
    vertexShader,   ok1 := glUtil.CreateAndCompileShader(gl.ShaderTypes.Vertex, vertexShaderString);
    fragmentShader, ok2 := glUtil.CreateAndCompileShader(gl.ShaderTypes.Fragment, fragmentShaderString);
   
    if !ok1 || !ok2 {
        panic("FUUUCK");
    }

    gl.AttachShader(State.MainProgram, vertexShader);
    State.MainProgram.Vertex = vertexShader;
    gl.AttachShader(State.MainProgram, fragmentShader);
    State.MainProgram.Fragment = fragmentShader;
    gl.LinkProgram(State.MainProgram);
    State.MainProgram.Uniforms["Texture"] = gl.GetUniformLocation(State.MainProgram, "Texture");    
    State.MainProgram.Uniforms["ProjMtx"] = gl.GetUniformLocation(State.MainProgram, "ProjMtx");

    State.MainProgram.Attributes["Position"] = gl.GetAttribLocation(State.MainProgram, "Position");    
    State.MainProgram.Attributes["UV"]       = gl.GetAttribLocation(State.MainProgram, "UV");    
    State.MainProgram.Attributes["Color"]    = gl.GetAttribLocation(State.MainProgram, "Color");    

    State.VBOHandle = cast(gl.VBO)gl.GenBuffer();
    State.EBOHandle = cast(gl.EBO)gl.GenBuffer();
    State.VAOHandle = gl.GenVertexArray();

    gl.BindBuffer(State.VBOHandle);
    gl.BindBuffer(State.EBOHandle);
    gl.BindVertexArray(State.VAOHandle);

    gl.EnableVertexAttribArray(cast(u32)State.MainProgram.Attributes["Position"]);
    gl.EnableVertexAttribArray(cast(u32)State.MainProgram.Attributes["UV"]);
    gl.EnableVertexAttribArray(cast(u32)State.MainProgram.Attributes["Color"]);

    gl.VertexAttribPointer(cast(u32)State.MainProgram.Attributes["Position"],   2, gl.VertexAttribDataType.Float, false, size_of(DrawVert), cast(rawptr)cast(int)offset_of(DrawVert, pos));
    gl.VertexAttribPointer(cast(u32)State.MainProgram.Attributes["UV"],         2, gl.VertexAttribDataType.Float, false, size_of(DrawVert), cast(rawptr)cast(int)offset_of(DrawVert, uv));
    gl.VertexAttribPointer(cast(u32)State.MainProgram.Attributes["Color"],      4, gl.VertexAttribDataType.UByte, true,  size_of(DrawVert), cast(rawptr)cast(int)offset_of(DrawVert, col));
    
    //CreateFont
    pixels : ^byte;
    width : i32;
    height : i32;
    bytePer : i32;
    FontAtlas_GetTexDataAsRGBA32(io.Fonts, ^pixels, ^width, ^height, ^bytePer);
    State.FontTexture = gl.GenTexture();
    gl.BindTexture(gl.TextureTargets.Texture2D, State.FontTexture);
    gl.TexParameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.MinFilter, gl.TextureParametersValues.Linear);
    gl.TexParameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.MagFilter, gl.TextureParametersValues.Linear);
    gl.TexImage2D(gl.TextureTargets.Texture2D, 0, gl.InternalColorFormat.RGBA, 
                  width, height, gl.PixelDataFormat.RGBA, 
                  gl.Texture2DDataType.UByte, pixels);
    FontAtlas_SetTexID(io.Fonts, cast(rawptr)cast(uint)State.FontTexture);

    SetStyle();
}

BeginNewFrame :: proc(deltaTime : f64) {
    io := GetIO();
    rect : win32.Rect;
    win32.GetClientRect(cast(win32.Hwnd)io.ImeWindowHandle, ^rect);
    io.DisplaySize.x = cast(f32)rect.right;
    io.DisplaySize.y = cast(f32)rect.bottom;

    if win32.GetActiveWindow() == cast(win32.Hwnd)io.ImeWindowHandle {
        pos : win32.Point;
        win32.GetCursorPos(^pos);
        win32.ScreenToClient(cast(win32.Hwnd)io.ImeWindowHandle, ^pos);
        io.MousePos.x = cast(f32)pos.x;
        io.MousePos.y = cast(f32)pos.y;
        io.MouseDown[0] = win32.is_key_down(win32.Key_Code.LBUTTON);
        io.MouseDown[1] = win32.is_key_down(win32.Key_Code.RBUTTON);

        io.MouseWheel = cast(f32)State.MouseWheelDelta; 

        io.KeyCtrl =  win32.is_key_down(win32.Key_Code.LCONTROL) || win32.is_key_down(win32.Key_Code.RCONTROL);
        io.KeyShift = win32.is_key_down(win32.Key_Code.LSHIFT)   || win32.is_key_down(win32.Key_Code.RSHIFT);
        io.KeyAlt =   win32.is_key_down(win32.Key_Code.LMENU)    || win32.is_key_down(win32.Key_Code.RMENU);
        io.KeySuper = win32.is_key_down(win32.Key_Code.LWIN)     || win32.is_key_down(win32.Key_Code.RWIN);

        for i in 0..257 {
            io.KeysDown[i] = win32.is_key_down(cast(win32.Key_Code)i);
        }
    } else {
        io.MouseDown[0] = false;
        io.MouseDown[1] = false;
        io.KeyCtrl  = false;  
        io.KeyShift = false; 
        io.KeyAlt   = false;   
        io.KeySuper = false;

        for i in 0..256 { 
            io.KeysDown[i] = false;
        }
    }
    
    State.MouseWheelDelta = 0;
    io.DeltaTime = cast(f32)deltaTime;
    NewFrame();
}
 
RenderProc :: proc(data : ^DrawData) #cc_c {
    io := GetIO();
    rect : win32.Rect;
    win32.GetClientRect(cast(win32.Hwnd)io.ImeWindowHandle, ^rect);
    io.DisplaySize.x = cast(f32)rect.right;
    io.DisplaySize.y = cast(f32)rect.bottom;
    width := cast(i32)(io.DisplaySize.x * io.DisplayFramebufferScale.x);
    height := cast(i32)(io.DisplaySize.y * io.DisplayFramebufferScale.y);
    if height == 0 || width == 0 {
        //return;
    }
    //draw_data->ScaleClipRects(io.DisplayFramebufferScale);

    //@TODO(Hoej): BACKUP STATE!

    gl.Enable(gl.Capabilities.Blend);
    gl.BlendFunc(gl.BlendFactors.SrcAlpha, gl.BlendFactors.OneMinusSrcAlpha);
    gl.BlendEquation(gl.BlendEquations.FuncAdd);
    gl.Disable(gl.Capabilities.CullFace);
    gl.Disable(gl.Capabilities.DepthTest);
    gl.Enable(gl.Capabilities.ScissorTest);
    gl.ActiveTexture(gl.TextureUnits.Texture0);

    gl.Viewport(0, 0, width, height);
    ortho_projection := [4][4]f32
    {
        { 2.0 / io.DisplaySize.x,   0.0,                        0.0,    0.0 },
        { 0.0,                      2.0 / -io.DisplaySize.y,    0.0,    0.0 },
        { 0.0,                      0.0,                        -1.0,   0.0 },
        { -1.0,                     1.0,                        0.0,    1.0 },
    };

    gl.UseProgram(State.MainProgram);
    gl.Uniform(State.MainProgram.Uniforms["Texture"], cast(i32)0);
    gl._UniformMatrix4fv(State.MainProgram.Uniforms["ProjMtx"], 1, 0, ^ortho_projection[0][0]);
    gl.BindVertexArray(State.VAOHandle);

    newList := slice_ptr(data.CmdLists, data.CmdListsCount);
    for n : i32 = 0; n < data.CmdListsCount; n += 1 {
        list := newList[n];
        idxBufferOffset : ^DrawIdx = nil;

        gl.BindBuffer(State.VBOHandle);
        gl.BufferData(gl.BufferTargets.Array, cast(i32)(DrawList_GetVertexBufferSize(list) * size_of(DrawVert)), DrawList_GetVertexPtr(list, 0), gl.BufferDataUsage.StreamDraw);

        gl.BindBuffer(State.EBOHandle);
        gl.BufferData(gl.BufferTargets.ElementArray, cast(i32)(DrawList_GetIndexBufferSize(list) * size_of(DrawIdx)), DrawList_GetIndexPtr(list, 0), gl.BufferDataUsage.StreamDraw);

        for j : i32 = 0; j < DrawList_GetCmdSize(list); j += 1 {
            cmd := DrawList_GetCmdPtr(list, j);
            gl.BindTexture(gl.TextureTargets.Texture2D, cast(gl.Texture)cast(uint)cmd.TextureId);
            gl.Scissor(cast(i32)cmd.ClipRect.x, height - cast(i32)cmd.ClipRect.w, cast(i32)(cmd.ClipRect.z - cmd.ClipRect.x), cast(i32)(cmd.ClipRect.w - cmd.ClipRect.y));
            gl.DrawElements(gl.DrawModes.Triangles, cast(i32)cmd.ElemCount, gl.DrawElementsType.UShort, idxBufferOffset);
            idxBufferOffset += cmd.ElemCount;
        }
    }

    //TODO: Restore state

    gl.Scissor(0, 0, width, height);
}