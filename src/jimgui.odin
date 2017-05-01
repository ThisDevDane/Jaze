#import "imgui.odin";
#import win32 "sys/windows.odin";
#import "fmt.odin";
#import "math.odin";
#import "main.odin";
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
    style := imgui.GetStyle();

    style.WindowRounding = 1.0;
    style.ChildWindowRounding = 1.0;
    style.FrameRounding = 1.0;
    style.GrabRounding = 1.0;

    style.ScrollbarSize = 12.0;

    style.Colors[imgui.GuiCol.Text]                  = imgui.Vec4{1.00, 1.00, 1.00, 1.00};
    style.Colors[imgui.GuiCol.TextDisabled]          = imgui.Vec4{0.63, 0.63, 0.63, 1.00};
    style.Colors[imgui.GuiCol.WindowBg]              = imgui.Vec4{0.23, 0.23, 0.23, 0.98};
    style.Colors[imgui.GuiCol.ChildWindowBg]         = imgui.Vec4{0.20, 0.20, 0.20, 1.00};
    style.Colors[imgui.GuiCol.PopupBg]               = imgui.Vec4{0.25, 0.25, 0.25, 0.96};
    style.Colors[imgui.GuiCol.Column]                = imgui.Vec4{0.18, 0.18, 0.18, 0.98};
    style.Colors[imgui.GuiCol.Border]                = imgui.Vec4{0.18, 0.18, 0.18, 0.98};
    style.Colors[imgui.GuiCol.BorderShadow]          = imgui.Vec4{0.00, 0.00, 0.00, 0.04};
    style.Colors[imgui.GuiCol.FrameBg]               = imgui.Vec4{0.00, 0.00, 0.00, 0.29};
    style.Colors[imgui.GuiCol.TitleBg]               = imgui.Vec4{0.25, 0.25, 0.25, 0.98};
    style.Colors[imgui.GuiCol.TitleBgCollapsed]      = imgui.Vec4{0.25, 0.25, 0.25, 0.49};
    style.Colors[imgui.GuiCol.TitleBgActive]         = imgui.Vec4{0.33, 0.33, 0.33, 0.98};
    style.Colors[imgui.GuiCol.MenuBarBg]             = imgui.Vec4{0.11, 0.11, 0.11, 0.42};
    style.Colors[imgui.GuiCol.ScrollbarBg]           = imgui.Vec4{0.00, 0.00, 0.00, 0.08};
    style.Colors[imgui.GuiCol.ScrollbarGrab]         = imgui.Vec4{0.27, 0.27, 0.27, 1.00};
    style.Colors[imgui.GuiCol.ScrollbarGrabHovered]  = imgui.Vec4{0.78, 0.78, 0.78, 0.40};
    style.Colors[imgui.GuiCol.CheckMark]             = imgui.Vec4{0.78, 0.78, 0.78, 0.94};
    style.Colors[imgui.GuiCol.SliderGrab]            = imgui.Vec4{0.78, 0.78, 0.78, 0.94};
    style.Colors[imgui.GuiCol.Button]                = imgui.Vec4{0.42, 0.42, 0.42, 0.60};
    style.Colors[imgui.GuiCol.ButtonHovered]         = imgui.Vec4{0.78, 0.78, 0.78, 0.40};
    style.Colors[imgui.GuiCol.Header]                = imgui.Vec4{0.31, 0.31, 0.31, 0.98};
    style.Colors[imgui.GuiCol.HeaderHovered]         = imgui.Vec4{0.78, 0.78, 0.78, 0.40};
    style.Colors[imgui.GuiCol.HeaderActive]          = imgui.Vec4{0.80, 0.50, 0.50, 1.00};
    style.Colors[imgui.GuiCol.TextSelectedBg]        = imgui.Vec4{0.65, 0.35, 0.35, 0.26};
    style.Colors[imgui.GuiCol.ModalWindowDarkening]  = imgui.Vec4{0.20, 0.20, 0.20, 0.35};
}

Init :: proc(windowHandle : win32.Hwnd) {
    io := imgui.GetIO();
    io.ImeWindowHandle = windowHandle;
    io.RenderDrawListsFn = RenderProc;

    io.KeyMap[imgui.GuiKey.Tab]        = i32(win32.Key_Code.TAB);
    io.KeyMap[imgui.GuiKey.LeftArrow]  = i32(win32.Key_Code.LEFT);
    io.KeyMap[imgui.GuiKey.RightArrow] = i32(win32.Key_Code.RIGHT);
    io.KeyMap[imgui.GuiKey.UpArrow]    = i32(win32.Key_Code.UP);
    io.KeyMap[imgui.GuiKey.DownArrow]  = i32(win32.Key_Code.DOWN);
    io.KeyMap[imgui.GuiKey.PageUp]     = i32(win32.Key_Code.NEXT);
    io.KeyMap[imgui.GuiKey.PageDown]   = i32(win32.Key_Code.PRIOR);
    io.KeyMap[imgui.GuiKey.Home]       = i32(win32.Key_Code.HOME);
    io.KeyMap[imgui.GuiKey.End]        = i32(win32.Key_Code.END);
    io.KeyMap[imgui.GuiKey.Delete]     = i32(win32.Key_Code.DELETE);
    io.KeyMap[imgui.GuiKey.Backspace]  = i32(win32.Key_Code.BACK);
    io.KeyMap[imgui.GuiKey.Enter]      = i32(win32.Key_Code.RETURN);
    io.KeyMap[imgui.GuiKey.Escape]     = i32(win32.Key_Code.ESCAPE);
    io.KeyMap[imgui.GuiKey.A]          = 'A';
    io.KeyMap[imgui.GuiKey.C]          = 'C';
    io.KeyMap[imgui.GuiKey.V]          = 'V';
    io.KeyMap[imgui.GuiKey.X]          = 'X';
    io.KeyMap[imgui.GuiKey.Y]          = 'Y';
    io.KeyMap[imgui.GuiKey.Z]          = 'Z';

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

    State.VBOHandle = gl.VBO(gl.GenBuffer());
    State.EBOHandle = gl.EBO(gl.GenBuffer());
    State.VAOHandle = gl.GenVertexArray();

    gl.BindBuffer(State.VBOHandle);
    gl.BindBuffer(State.EBOHandle);
    gl.BindVertexArray(State.VAOHandle);

    gl.EnableVertexAttribArray(u32(State.MainProgram.Attributes["Position"]));
    gl.EnableVertexAttribArray(u32(State.MainProgram.Attributes["UV"]));
    gl.EnableVertexAttribArray(u32(State.MainProgram.Attributes["Color"]));

    gl.VertexAttribPointer(u32(State.MainProgram.Attributes["Position"]),   2, gl.VertexAttribDataType.Float, false, size_of(imgui.DrawVert), rawptr(int(offset_of(imgui.DrawVert, pos))));
    gl.VertexAttribPointer(u32(State.MainProgram.Attributes["UV"]),         2, gl.VertexAttribDataType.Float, false, size_of(imgui.DrawVert), rawptr(int(offset_of(imgui.DrawVert, uv))));
    gl.VertexAttribPointer(u32(State.MainProgram.Attributes["Color"]),      4, gl.VertexAttribDataType.UByte, true,  size_of(imgui.DrawVert), rawptr(int(offset_of(imgui.DrawVert, col))));
    
    //CreateFont
    pixels : ^byte;
    width : i32;
    height : i32;
    bytePer : i32;
    imgui.FontAtlas_GetTexDataAsRGBA32(io.Fonts, &pixels, &width, &height, &bytePer);
    State.FontTexture = gl.GenTexture();
    gl.BindTexture(gl.TextureTargets.Texture2D, State.FontTexture);
    gl.TexParameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.MinFilter, gl.TextureParametersValues.Linear);
    gl.TexParameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.MagFilter, gl.TextureParametersValues.Linear);
    gl.TexImage2D(gl.TextureTargets.Texture2D, 0, gl.InternalColorFormat.RGBA, 
                  width, height, gl.PixelDataFormat.RGBA, 
                  gl.Texture2DDataType.UByte, pixels);
    imgui.FontAtlas_SetTexID(io.Fonts, rawptr(uint(State.FontTexture)));

    SetStyle();
}

BeginNewFrame :: proc(deltaTime : f64, ctx : ^main.EngineContext_t) {
    io := imgui.GetIO();
    io.DisplaySize.x = ctx.WindowSize.x;
    io.DisplaySize.y = ctx.WindowSize.y;

    if win32.GetActiveWindow() == win32.Hwnd(io.ImeWindowHandle) {
        io.MousePos.x = ctx.MousePos.x;
        io.MousePos.y = ctx.MousePos.y;
        io.MouseDown[0] = win32.is_key_down(win32.Key_Code.LBUTTON);
        io.MouseDown[1] = win32.is_key_down(win32.Key_Code.RBUTTON);

        io.MouseWheel = f32(State.MouseWheelDelta); 

        io.KeyCtrl =  win32.is_key_down(win32.Key_Code.LCONTROL) || win32.is_key_down(win32.Key_Code.RCONTROL);
        io.KeyShift = win32.is_key_down(win32.Key_Code.LSHIFT)   || win32.is_key_down(win32.Key_Code.RSHIFT);
        io.KeyAlt =   win32.is_key_down(win32.Key_Code.LMENU)    || win32.is_key_down(win32.Key_Code.RMENU);
        io.KeySuper = win32.is_key_down(win32.Key_Code.LWIN)     || win32.is_key_down(win32.Key_Code.RWIN);

        for i in 0..257 {
            io.KeysDown[i] = win32.is_key_down(win32.Key_Code(i));
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
    io.DeltaTime = f32(deltaTime);
    imgui.NewFrame();
}
 
RenderProc :: proc(data : ^imgui.DrawData) #cc_c {
    io := imgui.GetIO();
    rect : win32.Rect;
    win32.GetClientRect(win32.Hwnd(io.ImeWindowHandle), &rect);
    io.DisplaySize.x = f32(rect.right);
    io.DisplaySize.y = f32(rect.bottom);
    width := i32(io.DisplaySize.x * io.DisplayFramebufferScale.x);
    height := i32(io.DisplaySize.y * io.DisplayFramebufferScale.y);
    if height == 0 || width == 0 {
        //return;
    }
    //draw_data->ScaleClipRects(io.DisplayFramebufferScale);

    //@TODO(Hoej): BACKUP STATE!
    lastViewport : [4]i32;
    gl.GetInteger(gl.GetIntegerNames.Viewport, &lastViewport[0]);

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
    gl.Uniform(State.MainProgram.Uniforms["Texture"], 0);
    gl._UniformMatrix4fv(State.MainProgram.Uniforms["ProjMtx"], 1, 0, &ortho_projection[0][0]);
    gl.BindVertexArray(State.VAOHandle);

    newList := slice_ptr(data.CmdLists, data.CmdListsCount);
    for n : i32 = 0; n < data.CmdListsCount; n += 1 {
        list := newList[n];
        idxBufferOffset : ^imgui.DrawIdx = nil;

        gl.BindBuffer(State.VBOHandle);
        gl.BufferData(gl.BufferTargets.Array, i32(imgui.DrawList_GetVertexBufferSize(list) * size_of(imgui.DrawVert)), imgui.DrawList_GetVertexPtr(list, 0), gl.BufferDataUsage.StreamDraw);

        gl.BindBuffer(State.EBOHandle);
        gl.BufferData(gl.BufferTargets.ElementArray, i32(imgui.DrawList_GetIndexBufferSize(list) * size_of(imgui.DrawIdx)), imgui.DrawList_GetIndexPtr(list, 0), gl.BufferDataUsage.StreamDraw);

        for j : i32 = 0; j < imgui.DrawList_GetCmdSize(list); j += 1 {
            cmd := imgui.DrawList_GetCmdPtr(list, j);
            gl.BindTexture(gl.TextureTargets.Texture2D, gl.Texture(uint(cmd.TextureId)));
            gl.Scissor(i32(cmd.ClipRect.x), height - i32(cmd.ClipRect.w), i32(cmd.ClipRect.z - cmd.ClipRect.x), i32(cmd.ClipRect.w - cmd.ClipRect.y));
            gl.DrawElements(gl.DrawModes.Triangles, i32(cmd.ElemCount), gl.DrawElementsType.UShort, idxBufferOffset);
            idxBufferOffset += cmd.ElemCount;
        }
    }

    //TODO: Restore state
    gl.Scissor(0, 0, width, height);
    gl.Viewport(lastViewport[0], lastViewport[1], lastViewport[2], lastViewport[3]);
}