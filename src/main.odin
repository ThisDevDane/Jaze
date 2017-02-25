#import win32 "sys/windows.odin" when ODIN_OS == "windows";
#import win32wgl "sys/wgl.odin" when ODIN_OS == "windows";
#import win32ext "jaze_win32.odin";
#import gl "jaze_gl.odin";
#import wgl "jaze_wgl.odin";
#import "fmt.odin";
#import "../../oToolkit/odimgui/src/imgui.odin";
#import "strings.odin";

OpenGLVars_ :: struct {
    Ctx               : win32wgl.HGLRC,
    VersionMajorMax   : i32,
    VersionMajorCur   : i32,
    VersionMinorMax   : i32,
    VersionMinorCur   : i32,
    VersionString     : string,
    GLSLVersionString : string,

    NumExtensions     : i32,
    Extensions        : [dynamic]string,
}

Win32Vars_ :: struct {
    AppHandle    : win32.HINSTANCE,
    WindowHandle : win32.HWND,
    DeviceCtx    : win32.HDC,
    Ogl          : OpenGLVars_,
}

GetOpenGLInfo :: proc(vars : ^OpenGLVars_) {
    vars.VersionMajorCur = gl.GetInteger(gl.GetIntegerNames.MajorVersion);
    vars.VersionMinorCur = gl.GetInteger(gl.GetIntegerNames.MinorVersion);

    vars.VersionString = gl.GetString(gl.GetStringNames.Version);
    vars.GLSLVersionString = gl.GetString(gl.GetStringNames.ShadingLanguageVersion);

    vars.NumExtensions = gl.GetInteger(gl.GetIntegerNames.NumExtensions);
    reserve(vars.Extensions, vars.NumExtensions);
    for i : i32; i < vars.NumExtensions; i += 1 {
        ext := gl.GetString(gl.GetStringNames.Extensions, cast(u32)i);
        append(vars.Extensions, ext);
    }
}

CreateOpenGLContext :: proc (vars : ^Win32Vars_, modern : bool) -> win32wgl.HGLRC
 {
    if !modern {
        pfd := win32.PIXELFORMATDESCRIPTOR {};
        pfd.size = size_of(win32.PIXELFORMATDESCRIPTOR);
        pfd.version = 1;
        pfd.flags = win32.PFD_DRAW_TO_WINDOW | win32.PFD_SUPPORT_OPENGL | win32.PFD_DOUBLEBUFFER;
        pfd.color_bits = 32;
        pfd.alpha_bits = 8;
        pfd.depth_bits = 24;
        format := win32.ChoosePixelFormat(vars.DeviceCtx, ^pfd);
        win32.DescribePixelFormat(vars.DeviceCtx, format, size_of(win32.PIXELFORMATDESCRIPTOR), ^pfd);
        win32.SetPixelFormat(vars.DeviceCtx, format, ^pfd);
        ctx := win32wgl.CreateContext(vars.DeviceCtx);
        assert(ctx != nil);
        win32wgl.MakeCurrent(vars.DeviceCtx, ctx);

        vars.Ogl.VersionMajorMax = gl.GetInteger(gl.GetIntegerNames.MajorVersion);
        vars.Ogl.VersionMinorMax = gl.GetInteger(gl.GetIntegerNames.MinorVersion);

        return ctx;
    } else {
        {
            wndHandle := win32.CreateWindowExA(0, 
                           strings.new_c_string("STATIC"), 
                           strings.new_c_string("OpenGL Loader"), 
                           win32.WS_OVERLAPPED, 
                           win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT,
                           nil, nil, nil, nil);
            assert(wndHandle != nil);
            wndDc := win32.GetDC(wndHandle);
            assert(wndDc != nil);

            temp := vars.DeviceCtx;
            vars.DeviceCtx = wndDc;
            oldCtx := CreateOpenGLContext(vars, false);
            vars.DeviceCtx = temp;
            assert(oldCtx != nil);
            extensions := wgl.TryGetExtensionList{};
            wgl.TryGetExtension(^extensions, ^wgl.ChoosePixelFormatARB, "wglChoosePixelFormatARB");
            wgl.TryGetExtension(^extensions, ^wgl.CreateContextAttribsARB, "wglCreateContextAttribsARB");
            wgl.LoadExtensions(oldCtx, wndDc, extensions);

            win32wgl.MakeCurrent(nil, nil);
            win32wgl.DeleteContext(oldCtx);
            win32.ReleaseDC(wndHandle, wndDc);
            win32ext.DestroyWindow(wndHandle);
        }
        
        attribs : [dynamic]wgl.Attrib;
        append(attribs, wgl.DRAW_TO_WINDOW_ARB(true),
                        wgl.ACCELERATION_ARB(wgl.ACCELERATION_ARB_VALUES.FULL_ACCELERATION_ARB),
                        wgl.SUPPORT_OPENGL_ARB(true),
                        wgl.DOUBLE_BUFFER_ARB(true),
                        wgl.PIXEL_TYPE_ARB(wgl.PIXEL_TYPE_ARB_VALUES.RGBA_ARB),
                        wgl.COLOR_BITS_ARB(32),
                        wgl.ALPHA_BITS_ARB(8),
                        wgl.DEPTH_BITS_ARB(24),
                        wgl.FRAMEBUFFER_SRGB_CAPABLE_ARB(true));
        attribArray := wgl.PrepareAttribArray(attribs);

        format : i32;
        formats : u32;
        success := wgl.ChoosePixelFormatARB(vars.DeviceCtx, attribArray.data, nil, 1, ^format, ^formats);

        if (success == win32.TRUE) && (formats == 0) {
            panic("Couldn't find suitable pixel format");
        }

        pfd : win32.PIXELFORMATDESCRIPTOR;
        pfd.version = 1;
        pfd.size = size_of(win32.PIXELFORMATDESCRIPTOR);
        
        win32.DescribePixelFormat(vars.DeviceCtx, format, size_of(win32.PIXELFORMATDESCRIPTOR), ^pfd);
        win32.SetPixelFormat(vars.DeviceCtx, format, ^pfd);

        createAttr : [dynamic]wgl.Attrib;
        append(createAttr, wgl.CONTEXT_MAJOR_VERSION_ARB(3),
                           wgl.CONTEXT_MINOR_VERSION_ARB(3),
                           wgl.CONTEXT_FLAGS_ARB(wgl.CONTEXT_FLAGS_ARB_VALUES.DEBUG_BIT_ARB),
                           wgl.CONTEXT_PROFILE_MASK_ARB(wgl.CONTEXT_PROFILE_MASK_ARB_VALUES.CORE_PROFILE_BIT_ARB));
        attribArray = wgl.PrepareAttribArray(createAttr);
        
        ctx := wgl.CreateContextAttribsARB(vars.DeviceCtx, nil, attribArray.data);
        assert(ctx != nil);
        win32wgl.MakeCurrent(vars.DeviceCtx, ctx);

        return ctx;
    }
}

CreateWindow :: proc (instance : win32.HINSTANCE) -> win32.HWND {
    using win32;
    wndClass : WNDCLASSEXA;
    wndClass.size = size_of(WNDCLASSEXA);
    wndClass.style = CS_OWNDC|CS_HREDRAW|CS_VREDRAW;
    wndClass.wnd_proc = WindowProc;
    wndClass.instance = instance;
    wndClass.class_name = strings.new_c_string("jaze_class");

    if RegisterClassExA(^wndClass) == 0 {
        panic("Could Not Register Class");
    }

    windowStyle : u32 = WS_OVERLAPPEDWINDOW|WS_VISIBLE;
    clientRect := RECT{0,0,1280,720};
    AdjustWindowRect(^clientRect, windowStyle, 0);

    windowHandle := CreateWindowExA(0,
                                    wndClass.class_name,
                                    strings.new_c_string("Jaze"),
                                    windowStyle,
                                    CW_USEDEFAULT,
                                    CW_USEDEFAULT,
                                    clientRect.right - clientRect.left,
                                    clientRect.bottom - clientRect.top,
                                    nil,
                                    nil,
                                    instance,
                                    nil);

    if windowHandle == nil {
        panic("Could Not Create Window");
    }

    return windowHandle;
}

WindowProc :: proc(hwnd: win32.HWND, 
                   msg: u32, 
                   wparam: win32.WPARAM, 
                   lparam: win32.LPARAM) -> win32.LRESULT #cc_c {
    using win32;
    result : LRESULT = 0;
    match(msg) {
        case WM_DESTROY : {
            PostQuitMessage(0);
        }

        /*case win32ext.WM_MOUSEWHEEL : {
            delta := cast(i16)(cast(u16)((cast(u32)((lparam >> 16) & 0xFFFF))));
            delta /= 120;
            fmt.println(delta);
            if(delta > 1) {
                ImGuiState.MouseWheelDelta += 1;
            }
            if(delta < 1) {
                ImGuiState.MouseWheelDelta -= 1;
            }

            result = 1;
        } 
        */

        case WM_CHAR : {
            imgui.GuiIO_AddInputCharacter(cast(u16)wparam); 
            result = 1;
        }
        break;

        default : {
            result = DefWindowProcA(hwnd, msg, wparam, lparam);
        }
    }
    
    return result;
}

ImGuiState_ :: struct {
    //Misc
    MouseWheelDelta  : i32,


    //Render
    MainProgram      : gl.Program,
    VertexShader     : gl.Shader,
    FragmentShader   : gl.Shader,

    AttribLocTex     : i32,
    AttribLocProjMtx : i32,
    AttribLocPos     : i32,
    AttribLocUV      : i32,
    AttribLocColor   : i32,

    VBOHandle        : gl.VBO,
    EBOHandle        : gl.EBO,
    VAOHandle        : gl.VAO,

    FontTexture      : gl.Texture,
}

ImGuiState : ImGuiState_;

ImGuiSetStyle :: proc() {
    style := imgui.GetStyle();

    style.WindowRounding = 2.0;
    style.ChildWindowRounding = 2.0;
    style.FrameRounding = 2.0;
    style.GrabRounding = 2.0;

    style.ScrollbarSize = 15.0;

    style.Colors[imgui.GuiCol.Text]                 = imgui.Vec4{56.0  / 255.0, 56.0  / 255.0, 56.0  / 255.0, 255.0 / 255.0};
    style.Colors[imgui.GuiCol.TextDisabled]         = imgui.Vec4{180.0 / 255.0, 180.0 / 255.0, 180.0 / 255.0, 255.0 / 255.0};

    style.Colors[imgui.GuiCol.WindowBg]             = imgui.Vec4{255.0 / 255.0, 255.0 / 255.0, 255.0 / 255.0, 240.0 / 255.0};
    style.Colors[imgui.GuiCol.ChildWindowBg]        = imgui.Vec4{255.0 / 255.0, 255.0 / 255.0, 255.0 / 255.0, 0.0   / 255.0};

    style.Colors[imgui.GuiCol.PopupBg]              = imgui.Vec4{250.0 / 255.0, 250.0 / 255.0, 250.0 / 255.0, 240.0 / 255.0};

    style.Colors[imgui.GuiCol.Border]               = imgui.Vec4{140.0 / 255.0, 140.0 / 255.0, 140.0 / 255.0, 255.0 / 255.0};
    style.Colors[imgui.GuiCol.BorderShadow]         = imgui.Vec4{0.0   / 255.0, 0.0   / 255.0, 0.0   / 255.0, 10.0  / 255.0};

    style.Colors[imgui.GuiCol.FrameBg]              = imgui.Vec4{215.0 / 255.0, 215.0 / 255.0, 215.0 / 255.0, 115.0 / 255.0};

    style.Colors[imgui.GuiCol.TitleBg]              = imgui.Vec4{200.0 / 255.0, 50.0  / 255.0, 50.0  / 255.0, 255.0 / 255.0};
    style.Colors[imgui.GuiCol.TitleBgCollapsed]     = imgui.Vec4{102.0 / 255.0, 102.0 / 255.0, 204.0 / 255.0, 102.0 / 255.0};
    style.Colors[imgui.GuiCol.TitleBgActive]        = imgui.Vec4{255.0 / 255.0, 50.0  / 255.0, 50.0  / 255.0, 255.0 / 255.0};

    style.Colors[imgui.GuiCol.MenuBarBg]            = imgui.Vec4{240.0 / 255.0, 240.0 / 255.0, 240.0 / 255.0, 255.0 / 255.0};

    style.Colors[imgui.GuiCol.ScrollbarBg]          = imgui.Vec4{240.0 / 255.0, 240.0 / 255.0, 240.0 / 255.0, 244.0 / 255.0};
    style.Colors[imgui.GuiCol.ScrollbarGrab]        = imgui.Vec4{204.0 / 255.0, 102.0 / 255.0, 102.0 / 255.0, 77.0  / 255.0};
    style.Colors[imgui.GuiCol.ScrollbarGrabHovered] = imgui.Vec4{240.0 / 255.0, 102.0 / 255.0, 102.0 / 255.0, 102.0 / 255.0};
    style.Colors[imgui.GuiCol.ScrollbarGrabActive]  = imgui.Vec4{255.0 / 255.0, 128.0 / 255.0, 128.0 / 255.0, 102.0 / 255.0};

    style.Colors[imgui.GuiCol.ComboBg]              = imgui.Vec4{230.0 / 255.0, 230.0 / 255.0, 230.0 / 255.0, 252.0 / 255.0};

    style.Colors[imgui.GuiCol.CheckMark]            = imgui.Vec4{100.0 / 255.0, 100.0 / 255.0, 100.0 / 255.0, 252.0 / 255.0};

    style.Colors[imgui.GuiCol.SliderGrab]           = imgui.Vec4{100.0 / 255.0, 100.0 / 255.0, 100.0 / 255.0, 100.0 / 255.0};
    style.Colors[imgui.GuiCol.SliderGrabActive]     = imgui.Vec4{150.0 / 255.0, 100.0 / 255.0, 100.0 / 255.0, 255.0 / 255.0};
    
    style.Colors[imgui.GuiCol.Button]               = imgui.Vec4{200.0 / 255.0, 50.0  / 255.0, 50.0  / 255.0, 153.0 / 255.0};
    style.Colors[imgui.GuiCol.ButtonHovered]        = imgui.Vec4{255.0 / 255.0, 50.0  / 255.0, 50.0  / 255.0, 255.0 / 255.0};

    style.Colors[imgui.GuiCol.Header]               = imgui.Vec4{240.0 / 255.0, 102.0 / 255.0, 102.0 / 255.0, 115.0 / 255.0};
    style.Colors[imgui.GuiCol.HeaderHovered]        = imgui.Vec4{240.0 / 255.0, 115.0 / 255.0, 155.0 / 255.0, 204.0 / 255.0};
    style.Colors[imgui.GuiCol.HeaderActive]         = imgui.Vec4{222.0 / 255.0, 135.0 / 255.0, 145.0 / 255.0, 204.0 / 255.0};

    style.Colors[imgui.GuiCol.ResizeGrip]           = imgui.Vec4{150.0 / 255.0, 150.0 / 255.0, 150.0 / 255.0, 77.0  / 255.0};
    style.Colors[imgui.GuiCol.ResizeGripHovered]    = imgui.Vec4{150.0 / 255.0, 150.0 / 255.0, 150.0 / 255.0, 153.0 / 255.0};
    style.Colors[imgui.GuiCol.ResizeGripActive]     = imgui.Vec4{150.0 / 255.0, 150.0 / 255.0, 150.0 / 255.0, 230.0 / 255.0};

    style.Colors[imgui.GuiCol.PlotLines]            = imgui.Vec4{100.0 / 255.0, 100.0 / 255.0, 100.0 / 255.0, 255.0 / 255.0};
    style.Colors[imgui.GuiCol.PlotHistogramHovered] = imgui.Vec4{255.0 / 255.0, 116.0 / 255.0, 0.0   / 255.0, 255.0 / 255.0};

    style.Colors[imgui.GuiCol.TextSelectedBg]       = imgui.Vec4{255.0 / 255.0, 0.0   / 255.0, 0.0   / 255.0, 89.0  / 255.0};

    style.Colors[imgui.GuiCol.ModalWindowDarkening] = imgui.Vec4{51.0  / 255.0, 51.0  / 255.0, 51.0  / 255.0, 90.0 / 255.0};
}

ImGuiInit :: proc(windowHandle : win32.HWND) {
    io := imgui.GetIO();
    io.ImeWindowHandle = windowHandle;
    io.RenderDrawListsFn = ImGuiRender;

    io.KeyMap[imgui.GuiKey.Tab]        = cast(i32)win32.Key_Code.TAB;
    io.KeyMap[imgui.GuiKey.LeftArrow]  = cast(i32)win32.Key_Code.LEFT;
    io.KeyMap[imgui.GuiKey.RightArrow] = cast(i32)win32.Key_Code.RIGHT;
    io.KeyMap[imgui.GuiKey.UpArrow]    = cast(i32)win32.Key_Code.UP;
    io.KeyMap[imgui.GuiKey.DownArrow]  = cast(i32)win32.Key_Code.DOWN;
    io.KeyMap[imgui.GuiKey.PageUp]     = cast(i32)win32.Key_Code.NEXT;
    io.KeyMap[imgui.GuiKey.PageDown]   = cast(i32)win32.Key_Code.PRIOR;
    io.KeyMap[imgui.GuiKey.Home]       = cast(i32)win32.Key_Code.HOME;
    io.KeyMap[imgui.GuiKey.End]        = cast(i32)win32.Key_Code.END;
    io.KeyMap[imgui.GuiKey.Delete]     = cast(i32)win32.Key_Code.DELETE;
    io.KeyMap[imgui.GuiKey.Backspace]  = cast(i32)win32.Key_Code.BACK;
    io.KeyMap[imgui.GuiKey.Enter]      = cast(i32)win32.Key_Code.RETURN;
    io.KeyMap[imgui.GuiKey.Escape]     = cast(i32)win32.Key_Code.ESCAPE;
    io.KeyMap[imgui.GuiKey.A]          = 'A';
    io.KeyMap[imgui.GuiKey.C]          = 'C';
    io.KeyMap[imgui.GuiKey.V]          = 'V';
    io.KeyMap[imgui.GuiKey.X]          = 'X';
    io.KeyMap[imgui.GuiKey.Y]          = 'Y';
    io.KeyMap[imgui.GuiKey.Z]          = 'Z';

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

    ImGuiState.MainProgram       = gl.CreateProgram();
    ImGuiState.VertexShader, _   = gl.UtilCreateAndCompileShader(gl.ShaderTypes.Vertex, vertexShaderString);
    ImGuiState.FragmentShader, _ = gl.UtilCreateAndCompileShader(gl.ShaderTypes.Fragment, fragmentShaderString);
   
    gl.CompileShader(ImGuiState.FragmentShader);
    gl.AttachShader(ImGuiState.MainProgram, ImGuiState.VertexShader);
    gl.AttachShader(ImGuiState.MainProgram, ImGuiState.FragmentShader);
    gl.LinkProgram(ImGuiState.MainProgram);
    ImGuiState.AttribLocTex     = gl.GetUniformLocation(ImGuiState.MainProgram, "Texture");    
    ImGuiState.AttribLocProjMtx = gl.GetUniformLocation(ImGuiState.MainProgram, "ProjMtx");
    ImGuiState.AttribLocPos     = gl.GetAttribLocation(ImGuiState.MainProgram, "Position");    
    ImGuiState.AttribLocUV      = gl.GetAttribLocation(ImGuiState.MainProgram, "UV");     
    ImGuiState.AttribLocColor   = gl.GetAttribLocation(ImGuiState.MainProgram, "Color");  

    ImGuiState.VBOHandle = cast(gl.VBO)gl.GenBuffer();
    ImGuiState.EBOHandle = cast(gl.EBO)gl.GenBuffer();
    ImGuiState.VAOHandle = gl.GenVertexArray();

    gl.BindBuffer(ImGuiState.VBOHandle);
    gl.BindBuffer(ImGuiState.EBOHandle);
    gl.BindVertexArray(ImGuiState.VAOHandle);


    gl.EnableVertexAttribArray(cast(u32)ImGuiState.AttribLocPos);
    gl.EnableVertexAttribArray(cast(u32)cast(u32)ImGuiState.AttribLocUV);
    gl.EnableVertexAttribArray(cast(u32)ImGuiState.AttribLocColor);

    gl.VertexAttribPointer(cast(u32)ImGuiState.AttribLocPos,   2, gl.VertexAttribDataType.Float, false, size_of(imgui.DrawVert), cast(rawptr)cast(int)offset_of(imgui.DrawVert, pos));
    gl.VertexAttribPointer(cast(u32)ImGuiState.AttribLocUV,    2, gl.VertexAttribDataType.Float, false, size_of(imgui.DrawVert), cast(rawptr)cast(int)offset_of(imgui.DrawVert, uv));
    gl.VertexAttribPointer(cast(u32)ImGuiState.AttribLocColor, 4, gl.VertexAttribDataType.UByte, true,  size_of(imgui.DrawVert), cast(rawptr)cast(int)offset_of(imgui.DrawVert, col));
    
    //CreateFont
    pixels : ^byte;
    width : i32;
    height : i32;
    bytePer : i32;
    imgui.FontAtlas_GetTexDataAsRGBA32(io.Fonts, ^pixels, ^width, ^height, ^bytePer);
    ImGuiState.FontTexture = gl.GenTexture();
    gl.BindTexture(gl.TextureTargets.Texture2D, ImGuiState.FontTexture);
    gl.TexParameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.MinFilter, gl.TextureParametersValues.Linear);
    gl.TexParameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.MagFilter, gl.TextureParametersValues.Linear);
    gl.TexImage2D(gl.TextureTargets.Texture2D, 0, gl.InternalColorFormat.RGBA, 
                  width, height, gl.PixelDataFormat.RGBA, 
                  gl.Texture2DDataType.UByte, pixels);
    imgui.FontAtlas_SetTexID(io.Fonts, cast(rawptr)^ImGuiState.FontTexture);

    ImGuiSetStyle();
}

ImGuiNewFrame :: proc(deltaTime : f64) {
    io := imgui.GetIO();
    rect : win32.RECT;
    win32.GetClientRect(cast(win32.HWND)io.ImeWindowHandle, ^rect);
    io.DisplaySize.x = cast(f32)rect.right;
    io.DisplaySize.y = cast(f32)rect.bottom;

    pos : win32.POINT;
    win32.GetCursorPos(^pos);
    win32.ScreenToClient(cast(win32.HWND)io.ImeWindowHandle, ^pos);
    io.MousePos.x = cast(f32)pos.x;
    io.MousePos.y = cast(f32)pos.y;
    io.MouseDown[0] = win32.is_key_down(win32.Key_Code.LBUTTON);
    io.MouseDown[1] = win32.is_key_down(win32.Key_Code.RBUTTON);

    io.MouseWheel = cast(f32)ImGuiState.MouseWheelDelta; 
    ImGuiState.MouseWheelDelta = 0;

    io.KeyCtrl =  win32.is_key_down(win32.Key_Code.LCONTROL) || win32.is_key_down(win32.Key_Code.RCONTROL);
    io.KeyShift = win32.is_key_down(win32.Key_Code.LSHIFT)   || win32.is_key_down(win32.Key_Code.RSHIFT);
    io.KeyAlt =   win32.is_key_down(win32.Key_Code.LMENU)    || win32.is_key_down(win32.Key_Code.RMENU);
    io.KeySuper = win32.is_key_down(win32.Key_Code.LWIN)     || win32.is_key_down(win32.Key_Code.RWIN);

    for i in 0..<257 { //0..256 doesn't work tell bill
        io.KeysDown[i] = win32.is_key_down(cast(win32.Key_Code)i);
    }

    io.DeltaTime = cast(f32)deltaTime;
    imgui.NewFrame();
}
 
ImGuiRender :: proc(data : ^imgui.DrawData) #cc_c {
    io := imgui.GetIO();
    width := cast(i32)(io.DisplaySize.x * io.DisplayFramebufferScale.x);
    height := cast(i32)(io.DisplaySize.y * io.DisplayFramebufferScale.y);
    if height == 0 || width == 0 {
        //return;
    }
    //draw_data->ScaleClipRects(io.DisplayFramebufferScale);

    //@TODO(Hoej): BACKUP STATE!

    gl.Enable(gl.Capabilities.Blend);
    gl.BlendEquation(gl.BlendEquations.FuncAdd);
    gl.BlendFunc(gl.BlendFactors.SrcAlpha, gl.BlendFactors.OneMinusSrcAlpha);
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

    gl.UseProgram(ImGuiState.MainProgram);
    gl.Uniform(cast(i32)ImGuiState.AttribLocTex, cast(i32)0);
    gl._UniformMatrix4fv(cast(i32)ImGuiState.AttribLocProjMtx, 1, 0, ^ortho_projection[0][0]);
    gl.BindVertexArray(ImGuiState.VAOHandle);

    newList := slice_ptr(data.CmdLists, data.CmdListsCount);
    for n : i32 = 0; n < data.CmdListsCount; n += 1 {
        list := newList[n];
        idxBufferOffset : ^imgui.DrawIdx = nil;
        gl.BindBuffer(ImGuiState.VBOHandle);
        gl.BufferData(gl.BufferTargets.Array, cast(i32)(imgui.DrawList_GetVertexBufferSize(list) * size_of(imgui.DrawVert)), imgui.DrawList_GetVertexPtr(list, 0), gl.BufferDataUsage.StreamDraw);

        gl.BindBuffer(ImGuiState.EBOHandle);
        gl.BufferData(gl.BufferTargets.ElementArray, cast(i32)(imgui.DrawList_GetIndexBufferSize(list) * size_of(imgui.DrawIdx)), imgui.DrawList_GetIndexPtr(list, 0), gl.BufferDataUsage.StreamDraw);

        for j : i32 = 0; j < imgui.DrawList_GetCmdSize(list); j += 1 {
            cmd := imgui.DrawList_GetCmdPtr(list, j);
            gl.BindTexture(gl.TextureTargets.Texture2D, cast(gl.Texture)((cast(^u32)cmd.TextureId)^));
            gl.Scissor(cast(i32)cmd.ClipRect.x, height - cast(i32)cmd.ClipRect.w, cast(i32)(cmd.ClipRect.z - cmd.ClipRect.x), cast(i32)(cmd.ClipRect.w - cmd.ClipRect.y));
            gl.DrawElements(gl.DrawModes.Triangles, cast(i32)cmd.ElemCount, gl.DrawElementsType.UShort, idxBufferOffset);
            idxBufferOffset += cmd.ElemCount;
        }
    }

    gl.Scissor(0, 0, width, height);
}

OpenGLDebugCallback :: proc(source : gl.DebugSource, type : gl.DebugType, id : i32, severity : gl.DebugSeverity, length : i32, message : ^byte, userParam : rawptr) #cc_c {
    match (source) {
    case gl.DebugSource.Api :
        fmt.print("[Source API");
        break;

    case gl.DebugSource.WindowSystem :
        fmt.print("[Window System");
        break;

    case gl.DebugSource.ShaderCompiler :
        fmt.print("[Shader Compiler");
        break;

    case gl.DebugSource.ThirdParty :
        fmt.print("[3rd Party");
        break;

    case gl.DebugSource.Application :
        fmt.print("[Application");
        break;

    case gl.DebugSource.Other :
        fmt.print("[Other");
        break;
    }
    fmt.print(" | ");
    match (type) {
    case gl.DebugType.Error :
        fmt.print("Error");
        break;

    case gl.DebugType.DeprecatedBehavior :
        fmt.print("Deptracted Behavior");
        break;

    case gl.DebugType.UndefinedBehavior :
        fmt.print("Undefined Behavior");
        break;

    case gl.DebugType.Portability :
        fmt.print("Portability");
        break;

    case gl.DebugType.Performance :
        fmt.print("Performance");
        break;

    case gl.DebugType.Marker :
        fmt.print("Marker");
        break;

    case gl.DebugType.PushGroup :
        fmt.print("Push Group");
        break;

    case gl.DebugType.PopGroup :
        fmt.print("Pop Group");
        break;

    case gl.DebugType.Other :
        fmt.print("Other");
        break;
    }
    fmt.print(" | ");
    match (severity) {
    case gl.DebugSeverity.High :
        fmt.print("High]");
        break;

    case gl.DebugSeverity.Medium :
        fmt.print("Medium]");
        break;

    case gl.DebugSeverity.Low :
        fmt.print("Low]");
        break;

    case gl.DebugSeverity.Notification :
        fmt.print("Notification]");
        break;
    }
    fmt.print(" ");
    fmt.print(strings.to_odin_string(message));
    fmt.print("\n");
}


ProgramRunning : bool;

main :: proc() {
    win32vars := Win32Vars_{};
    win32vars.AppHandle = win32.GetModuleHandleA(nil);
    win32vars.WindowHandle = CreateWindow(win32vars.AppHandle); 
    win32vars.DeviceCtx = win32.GetDC(win32vars.WindowHandle);
    win32vars.Ogl.Ctx = CreateOpenGLContext(^win32vars, true);
    gl.Init();

    gl.DebugMessageCallback(OpenGLDebugCallback, nil);
    gl.Enable(gl.Capabilities.DebugOutputSynchronous);
    gl.DebugMessageControl(gl.DebugSource.DontCare, gl.DebugType.DontCare, gl.DebugSeverity.Notification, 0, nil, false);
    
    GetOpenGLInfo(^win32vars.Ogl);

    buf : [1024]byte;
    fmt.sprint(buf[:], "Jaze ", win32vars.Ogl.VersionString);
    win32.SetWindowTextA(win32vars.WindowHandle, buf[:].data);

    col : f32 = 56.0 / 255.0;
    gl.ClearColor(col, col, col, 1.0);
    ImGuiInit(win32vars.WindowHandle);

    ProgramRunning = true;

    freq : i64;
    win32.QueryPerformanceFrequency(^freq);
    oldTime : i64;
    win32.QueryPerformanceCounter(^oldTime);

    ShowOpenGLInfo : bool = false;
    ShowTestWindow : bool = false;

    for ProgramRunning {
        msg : win32.MSG;
        for win32.PeekMessageA(^msg, nil, 0, 0, win32.PM_REMOVE) == win32.TRUE {
            if msg.message == win32.WM_QUIT {
                ProgramRunning = false;
                break;
            }
            win32.TranslateMessage(^msg);
            win32.DispatchMessageA(^msg);
        }
        newTime : i64;
        win32.QueryPerformanceCounter(^newTime);
        deltaTime : f64 = cast(f64)(newTime - oldTime);
        oldTime = newTime;
        deltaTime /= cast(f64)freq;

        ImGuiNewFrame(deltaTime);

        imgui.BeginMainMenuBar();
        if imgui.BeginMenu("Misc", true) {
            if imgui.MenuItem("OpenGL Info", "", false, true) {
                ShowOpenGLInfo = !ShowOpenGLInfo;
            }
            if imgui.MenuItem("Show Test Window", "", false, true) {
                ShowTestWindow = !ShowTestWindow;
            }
            imgui.EndMenu();
        }
        
        imgui.EndMainMenuBar();

        if ShowOpenGLInfo == true {
            imgui.Begin("OpenGL Info", ^ShowOpenGLInfo, imgui.GuiWindowFlags.ShowBorders | imgui.GuiWindowFlags.NoCollapse);
            imgui.Text("Versions:");
            imgui.Indent(10.0);
            imgui.Text("Highest Version: %d.%d", win32vars.Ogl.VersionMajorMax, win32vars.Ogl.VersionMinorMax);
            imgui.Text("Current Version: %d.%d", win32vars.Ogl.VersionMajorCur, win32vars.Ogl.VersionMajorCur);
            imgui.Unindent(10.0);
            imgui.Separator();
            imgui.Text("GLSL Version: %s", win32vars.Ogl.GLSLVersionString);
            imgui.Separator();
            if imgui.CollapsingHeader("Extensions", 0) {
                imgui.Text("Number of extensions: %d", win32vars.Ogl.NumExtensions);
                imgui.BeginChild("Extensions", imgui.Vec2{0, 0}, true, 0);
                for ext in win32vars.Ogl.Extensions {
                    imgui.Text(ext);
                }
                imgui.EndChild();
            }
            imgui.End();
        }
        
        if ShowTestWindow {
            imgui.ShowTestWindow(^ShowTestWindow);
        }
        
        gl.Clear(gl.ClearFlags.COLOR_BUFFER | gl.ClearFlags.DEPTH_BUFFER);
        imgui.Render();
        win32.SwapBuffers(win32vars.DeviceCtx);
    }
}