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
    VersionMajor      : i32,
    VersionMinor      : i32,
    VersionString     : string,
    GLSLVersionString : string,
}

Win32Vars_ :: struct {
    AppHandle    : win32.HINSTANCE,
    WindowHandle : win32.HWND,
    DeviceCtx    : win32.HDC,
    Ogl          : OpenGLVars_,
}

GetOpenGLInfo :: proc(vars : ^OpenGLVars_) {
    vars.VersionMajor = gl.GetInteger(gl.GetIntegerNames.MajorVersion);
    vars.VersionMinor = gl.GetInteger(gl.GetIntegerNames.MinorVersion);

    vars.VersionString = gl.GetString(gl.GetStringNames.Version);
    vars.GLSLVersionString = gl.GetString(gl.GetStringNames.ShadingLanguageVersion);
}

CreateOpenGLContext :: proc (dc : win32.HDC, modern : bool) -> win32wgl.HGLRC
 {
    if !modern {
        pfd := win32.PIXELFORMATDESCRIPTOR {};
        pfd.size = size_of(win32.PIXELFORMATDESCRIPTOR);
        pfd.version = 1;
        pfd.flags = win32.PFD_DRAW_TO_WINDOW | win32.PFD_SUPPORT_OPENGL | win32.PFD_DOUBLEBUFFER;
        pfd.color_bits = 32;
        pfd.alpha_bits = 8;
        pfd.depth_bits = 24;
        format := win32.ChoosePixelFormat(dc, ^pfd);
        win32.DescribePixelFormat(dc, format, size_of(win32.PIXELFORMATDESCRIPTOR), ^pfd);
        win32.SetPixelFormat(dc, format, ^pfd);
        ctx := win32wgl.CreateContext(dc);
        assert(ctx != nil);
        win32wgl.MakeCurrent(dc, ctx);
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
            oldCtx := CreateOpenGLContext(wndDc, false);
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
        success := wgl.ChoosePixelFormatARB(dc, attribArray.data, nil, 1, ^format, ^formats);

        if (success == win32.TRUE) && (formats == 0) {
            panic("Couldn't find suitable pixel format");
        }

        pfd : win32.PIXELFORMATDESCRIPTOR;
        pfd.version = 1;
        pfd.size = size_of(win32.PIXELFORMATDESCRIPTOR);
        
        win32.DescribePixelFormat(dc, format, size_of(win32.PIXELFORMATDESCRIPTOR), ^pfd);
        win32.SetPixelFormat(dc, format, ^pfd);

        createAttr : [dynamic]wgl.Attrib;
        append(createAttr, wgl.CONTEXT_MAJOR_VERSION_ARB(3),
                           wgl.CONTEXT_MINOR_VERSION_ARB(3),
                           wgl.CONTEXT_FLAGS_ARB(wgl.CONTEXT_FLAGS_ARB_VALUES.DEBUG_BIT_ARB),
                           wgl.CONTEXT_PROFILE_MASK_ARB(wgl.CONTEXT_PROFILE_MASK_ARB_VALUES.CORE_PROFILE_BIT_ARB));
        attribArray = wgl.PrepareAttribArray(createAttr);
        
        ctx := wgl.CreateContextAttribsARB(dc, nil, attribArray.data);
        assert(ctx != nil);
        win32wgl.MakeCurrent(dc, ctx);

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

        default : {
            result = DefWindowProcA(hwnd, msg, wparam, lparam);
        }
        break;
    }
    
    return result;
}

ImguiRenderState_ :: struct {
    MainProgram      : gl.Program,
    VertexShader     : gl.ShaderObject,
    FragmentShader   : gl.ShaderObject,

    AttribLocTex     : u32,
    AttribLocProjMtx : u32,
    AttribLocPos     : u32,
    AttribLocUV      : u32,
    AttribLocColor   : u32,

    VBOHandle : gl.VBO,
    EBOHandle : gl.EBO,
    VAOHandle : gl.VAO,

    FontTexture : gl.Texture,
}

ImguiRenderState : ImguiRenderState_;

ImguiInit :: proc(windowHandle : win32.HWND) {
    io := imgui.GetIO();
    io.ImeWindowHandle = windowHandle;
    io.RenderDrawListsFn = ImguiRender;

    vertexShaderString :=
        "#version 330\n"
        "uniform mat4 ProjMtx;\n"
        "in vec2 Position;\n"
        "in vec2 UV;\n"
        "in vec4 Color;\n"
        "out vec2 Frag_UV;\n"
        "out vec4 Frag_Color;\n"
        "void main()\n"
        "{\n"
        "   Frag_UV = UV;\n"
        "   Frag_Color = Color;\n"
        "   gl_Position = ProjMtx * vec4(Position.xy,0,1);\n"
        "}\n";

    fragmentShaderString := 
        "#version 330\n"
        "uniform sampler2D Texture;\n"
        "in vec2 Frag_UV;\n"
        "in vec4 Frag_Color;\n"
        "out vec4 Out_Color;\n"
        "void main()\n"
        "{\n"
        "   Out_Color = Frag_Color * texture( Texture, Frag_UV.st);\n"
        "}\n";

    ImguiRenderState.MainProgram = gl.CreateProgram();
    ImguiRenderState.VertexShader = gl.CreateShader(gl.ShaderTypes.Vertex);
    ImguiRenderState.FragmentShader = gl.CreateShader(gl.ShaderTypes.Fragment);
    gl.ShaderSource(ImguiRenderState.VertexShader, vertexShaderString);
    gl.ShaderSource(ImguiRenderState.FragmentShader, fragmentShaderString);
    gl.CompileShader(ImguiRenderState.VertexShader);
    gl.CompileShader(ImguiRenderState.FragmentShader);
    gl.AttachShader(ImguiRenderState.MainProgram, ImguiRenderState.VertexShader);
    gl.AttachShader(ImguiRenderState.MainProgram, ImguiRenderState.FragmentShader);
    gl.LinkProgram(ImguiRenderState.MainProgram);
    ImguiRenderState.AttribLocTex = cast(u32)gl.GetUniformLocation(ImguiRenderState.MainProgram, "Texture");    
    ImguiRenderState.AttribLocProjMtx = cast(u32)gl.GetUniformLocation(ImguiRenderState.MainProgram, "ProjMtx");
    ImguiRenderState.AttribLocPos = cast(u32)gl.GetAttribLocation(ImguiRenderState.MainProgram, "Position");    
    ImguiRenderState.AttribLocUV = cast(u32)gl.GetAttribLocation(ImguiRenderState.MainProgram, "UV");     
    ImguiRenderState.AttribLocColor = cast(u32)gl.GetAttribLocation(ImguiRenderState.MainProgram, "Color");  

    ImguiRenderState.VBOHandle = cast(gl.VBO)gl.GenBuffer();
    ImguiRenderState.EBOHandle = cast(gl.EBO)gl.GenBuffer();
    ImguiRenderState.VAOHandle = gl.GenVertexArray();

    gl.BindVertexArray(ImguiRenderState.VAOHandle);
    gl.EnableVertexAttribArray(ImguiRenderState.AttribLocPos);
    gl.EnableVertexAttribArray(ImguiRenderState.AttribLocUV);
    gl.EnableVertexAttribArray(ImguiRenderState.AttribLocColor);

    gl.VertexAttribPointer(ImguiRenderState.AttribLocPos,   2, gl.VertexAttribDataType.Float, false, size_of(imgui.DrawVert), cast(rawptr)cast(int)offset_of(imgui.DrawVert, pos));
    gl.VertexAttribPointer(ImguiRenderState.AttribLocUV,    2, gl.VertexAttribDataType.Float, false, size_of(imgui.DrawVert), cast(rawptr)cast(int)offset_of(imgui.DrawVert, uv));
    gl.VertexAttribPointer(ImguiRenderState.AttribLocColor, 4, gl.VertexAttribDataType.UByte, true,  size_of(imgui.DrawVert), cast(rawptr)cast(int)offset_of(imgui.DrawVert, col));
    
    //CreateFont
    pixels : ^byte;
    width : i32;
    height : i32;
    bytePer : i32;
    imgui.FontAtlas_GetTexDataAsRGBA32(io.Fonts, ^pixels, ^width, ^height, ^bytePer);
    ImguiRenderState.FontTexture = gl.GenTexture();
    gl.BindTexture(gl.TextureTargets.Texture2D, ImguiRenderState.FontTexture);
    gl.TexParameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.MinFilter, gl.TextureParametersValues.Linear);
    gl.TexParameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.MagFilter, gl.TextureParametersValues.Linear);
    gl.TexImage2D(gl.TextureTargets.Texture2D, 0, gl.InternalColorFormat.RGBA, 
                  width, height, gl.PixelDataFormat.RGBA, 
                  gl.Texture2DDataType.UByte, pixels);
    imgui.FontAtlas_SetTexID(io.Fonts, cast(rawptr)^ImguiRenderState.FontTexture);
}

ImguiNewFrame :: proc() {
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
    io.MouseDown[0] = (win32.GetKeyState(cast(i32)win32.Key_Code.LBUTTON) & 0x100) != 0;
    io.MouseDown[1] = (win32.GetKeyState(cast(i32)win32.Key_Code.RBUTTON) & 0x100) != 0;

    io.DeltaTime = 1.0 / 60.0;
    imgui.NewFrame();
}
 
ImguiRender :: proc(data : ^imgui.DrawData) {
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
    //gl.Disable(gl.Capabilities.CullFace);
    //gl.Disable(gl.Capabilities.DepthTest);
    //gl.Enable(gl.Capabilities.ScissorTest);
    gl.ActiveTexture(gl.TextureUnits.Texture0);

    gl.Viewport(0, 0, width, height);
    ortho_projection := [4][4]f32
    {
        { 2.0 / io.DisplaySize.x,   0.0,                        0.0,    0.0 },
        { 0.0,                      2.0 / -io.DisplaySize.y,    0.0,    0.0 },
        { 0.0,                      0.0,                        -1.0,   0.0 },
        { -1.0,                     1.0,                        0.0,    1.0 },
    };

    gl.UseProgram(ImguiRenderState.MainProgram);
    gl.Uniform(cast(i32)ImguiRenderState.AttribLocTex, cast(i32)0);
    gl._UniformMatrix4fv(cast(i32)ImguiRenderState.AttribLocProjMtx, 1, 0, ^ortho_projection[0][0]);
    gl.BindVertexArray(ImguiRenderState.VAOHandle);

    newList := slice_ptr(data.CmdLists, data.CmdListsCount);
    for n : i32 = 0; n < data.CmdListsCount; n += 1 {
        list := newList[n];
        idxBufferOffset : ^imgui.DrawIdx = nil;
        gl.BindBuffer(ImguiRenderState.VBOHandle);
        gl.BufferData(gl.BufferTargets.Array, cast(i32)(imgui.DrawList_GetVertexBufferSize(list) * size_of(imgui.DrawVert)), imgui.DrawList_GetVertexPtr(list, 0), gl.BufferDataUsage.StreamDraw);

        gl.BindBuffer_EBO(ImguiRenderState.EBOHandle);
        gl.BufferData(gl.BufferTargets.ElementArray, cast(i32)(imgui.DrawList_GetIndexBufferSize(list) * size_of(imgui.DrawIdx)), imgui.DrawList_GetIndexPtr(list, 0), gl.BufferDataUsage.StreamDraw);

        for j : i32 = 0; j < imgui.DrawList_GetCmdSize(list); j += 1 {
            cmd := imgui.DrawList_GetCmdPtr(list, j);

            gl.BindTexture(gl.TextureTargets.Texture2D, cast(gl.Texture)((cast(^u32)cmd.TextureId)^));
            //glScissor
            gl.DrawElements(gl.DrawModes.Triangles, cast(i32)cmd.ElemCount, gl.DrawElementsType.UShort, idxBufferOffset);
            idxBufferOffset += cmd.ElemCount;
        }
    }
}

OpenGLDebugCallback :: proc(source : gl.DebugSource, type : gl.DebugType, id : i32, severity : gl.DebugSeverity, length : i32, message : ^byte, userParam : rawptr) #cc_c {
    match (source) {
    case gl.DebugSource.Api :
        fmt.print("[Source API");
        break;

    case gl.DebugSource.WindowSystem:
        fmt.print("[Window System");
        break;

    case gl.DebugSource.ShaderCompiler:
        fmt.print("[Shader Compiler");
        break;

    case gl.DebugSource.ThirdParty:
        fmt.print("[3rd Party");
        break;

    case gl.DebugSource.Application:
        fmt.print("[Application");
        break;

    case gl.DebugSource.Other:
        fmt.print("[Other");
        break;
    }
    fmt.print(" | ");
    match (type) {
    case gl.DebugType.Error:
        fmt.print("Error");
        break;

    case gl.DebugType.DeprecatedBehavior:
        fmt.print("Deptracted Behavior");
        break;

    case gl.DebugType.UndefinedBehavior:
        fmt.print("Undefined Behavior");
        break;

    case gl.DebugType.Portability:
        fmt.print("Portability");
        break;

    case gl.DebugType.Performance:
        fmt.print("Performance");
        break;

    case gl.DebugType.Marker:
        fmt.print("Marker");
        break;

    case gl.DebugType.PushGroup:
        fmt.print("Push Group");
        break;

    case gl.DebugType.PopGroup:
        fmt.print("Pop Group");
        break;

    case gl.DebugType.Other:
        fmt.print("Other");
        break;
    }
    fmt.print(" | ");
    match (severity) {
    case gl.DebugSeverity.High :
        fmt.print("High]");
        break;

    case gl.DebugSeverity.Medium:
        fmt.print("Medium]");
        break;

    case gl.DebugSeverity.Low:
        fmt.print("Low]");
        break;

    case gl.DebugSeverity.Notification:
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
    win32vars.Ogl.Ctx = CreateOpenGLContext(win32vars.DeviceCtx, true);
    gl.Init();

    gl.DebugMessageCallback(OpenGLDebugCallback, nil);
    gl.Enable(gl.Capabilities.DebugOutputSynchronous);
    gl.DebugMessageControl(gl.DebugSource.DontCare, gl.DebugType.DontCare, gl.DebugSeverity.Notification, 0, nil, false);
    
    GetOpenGLInfo(^win32vars.Ogl);
    fmt.println(win32vars.Ogl);
    gl.ClearColor(1.0, 0.0, 0.0, 1.0);
    ImguiInit(win32vars.WindowHandle);

    ProgramRunning = true;
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

        ImguiNewFrame();

        imgui.ShowUserGuide();

        imgui.Render();
        gl.Clear(gl.ClearFlags.COLOR_BUFFER | gl.ClearFlags.DEPTH_BUFFER);
        win32.SwapBuffers(win32vars.DeviceCtx);
    }
}