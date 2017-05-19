/*
 *  @Name:     gl
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 26-04-2017 16:23:18
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 20-05-2017 00:45:18
 *  
 *  @Description:
 *  
 */
#foreign_system_library lib "opengl32.lib";
#import win32 "sys/windows.odin";
#import win32wgl "sys/wgl.odin";
#import "fmt.odin";
#import "strings.odin";
#import "math.odin";
#load "gl_enums.odin";

#import "console.odin";

TRUE  :: 1;
FALSE :: 0;

// Types
VAO          :: u32;
VBO          :: u32;
EBO          :: u32;
BufferObject :: u32;
Texture      :: u32;
Shader       :: u32; 

Program :: struct {
    ID         : u32,
    Vertex     : Shader,
    Fragment   : Shader,
    Uniforms   : map[string]i32,
    Attributes : map[string]i32,
}

OpenGLVars_t :: struct {
    Ctx               : win32wgl.Hglrc,

    VersionMajorMax   : i32,
    VersionMajorCur   : i32,
    VersionMinorMax   : i32,
    VersionMinorCur   : i32,
    VersionString     : string,
    GLSLVersionString : string,

    VendorString      : string,
    RendererString    : string,

    ContextFlags      : i32,

    NumExtensions     : i32,
    Extensions        : [dynamic]string,
    NumWglExtensions  : i32,
    WglExtensions     : [dynamic]string,
}

DebugFunctionLoadStatus :: struct {
    Name    : string,
    Address : int,
    Success : bool,
    TypeInfo : ^Type_Info,
}

DebugInfo_t :: struct {
    LibAddress : int,
    NumberOfFunctionsLoaded : i32,
    NumberOfFunctionsLoadedSuccessed : i32,
    Statuses : [dynamic]DebugFunctionLoadStatus,
    LoadedTextures : [dynamic]Texture,

    DrawCalls : int,
}

DebugInfo : DebugInfo_t;

DebugMessageCallbackProc :: #type proc(source : DebugSource, type : DebugType, id : i32, severity : DebugSeverity, length : i32, message : ^byte, userParam : rawptr) #cc_c;

// API 

DepthFunc :: proc(func : DepthFuncs) {
    if _DepthFunc != nil {
        _DepthFunc(i32(func));
    } else {
        console.LogError("%s ins't loaded!", #procedure);
    }
}

GenerateMipmap :: proc(target : MipmapTargets) {
    if _GenerateMipmap != nil {
        _GenerateMipmap(i32(target));
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

PolygonMode :: proc(face : PolygonFace, mode : PolygonModes) {
    if _PolygonMode != nil {
        _PolygonMode(i32(face), i32(mode));
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

DebugMessageControl :: proc(source : DebugSource, type : DebugType, severity : DebugSeverity, count : i32, ids : ^u32, enabled : bool) {
    if _DebugMessageControl != nil {
        _DebugMessageControl(i32(source), i32(type), i32(severity), count, ids, enabled);
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

DebugMessageCallback :: proc(callback : DebugMessageCallbackProc, userParam : rawptr) {
    if _DebugMessageCallback != nil {
        _DebugMessageCallback(callback, userParam);
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}


Clear :: proc(mask : ClearFlags) {
    _Clear(i32(mask));
}

BufferData :: proc(target : BufferTargets, data : []f32, usage : BufferDataUsage) {
    if _BufferData != nil {
        _BufferData(i32(target), size_of_val(data), &data[0], i32(usage));
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }     
}

BufferData :: proc(target : BufferTargets, data : []u32, usage : BufferDataUsage) {
    if _BufferData != nil {
        _BufferData(i32(target), size_of_val(data), &data[0], i32(usage));
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }     
}


BufferData :: proc(target : BufferTargets, size : i32, data : rawptr, usage : BufferDataUsage) {
    if _BufferData != nil {
        _BufferData(i32(target), size, data, i32(usage));
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }     
}

GenVBO :: proc() -> VBO {
    bo := GenBuffer();
    return VBO(bo);
}

GenEBO :: proc() -> EBO {
    bo := GenBuffer();
    return EBO(bo);
}

GenBuffer :: proc() -> BufferObject {
    if _GenBuffers != nil {
        res : BufferObject;
        _GenBuffers(1, ^u32(&res));
        return res;
    } else {
        console.Log("%s isn't loaded!", #procedure);
        return 0;
    }      
}

GenBuffers :: proc(n : i32) -> []BufferObject {
    if _GenBuffers != nil {
        res := make([]BufferObject, n);
        _GenBuffers(n, ^u32(&res[0]));
        return res;
    } else {
        console.Log("%s isn't loaded!", #procedure);
        return nil;
    }       
}

BindBuffer :: proc(target : BufferTargets, buffer : BufferObject) {
    if _BindBuffer != nil {
        _BindBuffer(i32(target), u32(buffer));
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }       
}

BindBuffer :: proc(vbo : VBO) {
    BindBuffer(BufferTargets.Array, BufferObject(vbo));
}

BindBuffer :: proc(ebo : EBO) {
    BindBuffer(BufferTargets.ElementArray, BufferObject(ebo));
     
}

BindFragDataLocation :: proc(program : Program, colorNumber : u32, name : string) {
    if _BindFragDataLocation != nil {
        c := strings.new_c_string(name);
        _BindFragDataLocation(program.ID, colorNumber, c);
    } else {
        console.Log("%s isn't loaded!", #procedure);      
    }
}

GenVertexArray :: proc() -> VAO {
    if _GenVertexArrays != nil {
        res : VAO;
        _GenVertexArrays(1, ^u32(&res));
        return res;
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }  

    return 0;
}

GenVertexArrays :: proc(count : i32) -> []VAO {
    if _GenVertexArrays != nil {
        res := make([]VAO, count);
        _GenVertexArrays(count, ^u32(&res[0]));
        return res;
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }  

    return nil;
}

EnableVertexAttribArray :: proc(index : u32) {
    if _EnableVertexAttribArray != nil {
        _EnableVertexAttribArray(index);
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }       
}

VertexAttribPointer :: proc(index : u32, size : i32, type : VertexAttribDataType, normalized : bool, stride : u32, pointer : rawptr) {
    if _VertexAttribPointer != nil {
        _VertexAttribPointer(index, size, i32(type), normalized, stride, pointer);
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }       
}


BindVertexArray :: proc(buffer : VAO) {
    if _BindVertexArray != nil {
        _BindVertexArray(u32(buffer));
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }    
}

Uniform :: proc(loc : i32, v0 : i32) {
    if _Uniform1i != nil {
        _Uniform1i(loc, v0);
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

Uniform :: proc(loc: i32, v0, v1: i32) {
    if _Uniform2i != nil {
        _Uniform2i(loc, v0, v1);
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

Uniform :: proc(loc: i32, v0, v1, v2: i32) {
    if _Uniform3i != nil {
        _Uniform3i(loc, v0, v1, v2);
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

Uniform :: proc(loc: i32, v0, v1, v2, v3: i32) {
    if _Uniform4i != nil {
        _Uniform4i(loc, v0, v1, v2, v3);
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

Uniform :: proc(loc: i32, v0: f32) {
    if _Uniform1f != nil {
        _Uniform1f(loc, v0);
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

Uniform :: proc(loc: i32, v0, v1: f32) {
    if _Uniform2f != nil {
        _Uniform2f(loc, v0, v1);
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

Uniform :: proc(loc: i32, v0, v1, v2: f32) {
    if _Uniform3f != nil {
        _Uniform3f(loc, v0, v1, v2);
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

Uniform :: proc(loc: i32, v0, v1, v2, v3: f32) {
    if _Uniform4f != nil {
        _Uniform4f(loc, v0, v1, v2, v3);
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

UniformMatrix4fv :: proc(loc : i32, matrix : math.Mat4, transpose : bool) {
    if _UniformMatrix4fv != nil {
        _UniformMatrix4fv(loc, 1, i32(transpose), ^f32(&matrix));
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

GetUniformLocation :: proc(program : Program, name : string) -> i32{
    if _GetUniformLocation != nil {
        str := strings.new_c_string(name); defer free(str);
        res := _GetUniformLocation(u32(program.ID), str);
        return res;
    } else {
        console.Log("%s isn't loaded!", #procedure);
        return 0;
    }
}

GetAttribLocation :: proc(program : Program, name : string) -> i32 {
    if _GetAttribLocation != nil {
        str := strings.new_c_string(name); defer free(str);
        res := _GetAttribLocation(u32(program.ID), str);
        return res;
    } else {
        console.Log("%s isn't loaded!", #procedure);
        return 0;
    }
}

DrawElements :: proc(mode : DrawModes, count : i32, type : DrawElementsType, indices : rawptr) {
    if _DrawElements != nil {
        _DrawElements(i32(mode), count, i32(type), indices);
        DebugInfo.DrawCalls++;
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }    
}

DrawArrays :: proc(mode : DrawModes, first : i32, count : i32) {
    if _DrawArrays != nil {
        _DrawArrays(i32(mode), first, count);
        DebugInfo.DrawCalls++;
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }    
}

UseProgram :: proc(program : Program) {
    if _UseProgram != nil {
        _UseProgram(program.ID);
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

LinkProgram :: proc(program : Program) {
    if _LinkProgram != nil {
        _LinkProgram(program.ID);
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

TexImage2D :: proc(target : TextureTargets, lod : i32, internalFormat : InternalColorFormat,
                   width : i32, height : i32, format : PixelDataFormat, type_ : Texture2DDataType,
                   data : rawptr) {
    _TexImage2D(i32(target), lod, i32(internalFormat), width, height, 0,
                i32(format), i32(type_), data);
}

TexParameteri  :: proc(target : TextureTargets, pname : TextureParameters, param : TextureParametersValues) {
    _TexParameteri(i32(target), i32(pname), i32(param));
}

BindTexture :: proc(target : TextureTargets, texture : Texture) {
    _BindTexture(i32(target), u32(texture));
}

ActiveTexture :: proc(texture : TextureUnits) {
    if _ActiveTexture != nil {
        _ActiveTexture(i32(texture));
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

GenTexture :: proc() -> Texture {
    res := GenTextures(1);
    return res[0];
}

GenTextures :: proc(count : i32) -> []Texture {
    res := make([]Texture, count);
    _GenTextures(count, ^u32(&res[0]));
    for id in res {
        append(DebugInfo.LoadedTextures, id);
    }
    return res;
}

BlendEquationSeparate :: proc(modeRGB : BlendEquations, modeAlpha : BlendEquations) {
    if _BlendEquationSeparate != nil {
        _BlendEquationSeparate(i32(modeRGB), i32(modeAlpha));
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }    
}

BlendEquation :: proc(mode : BlendEquations) {
    if _BlendEquation != nil {
        _BlendEquation(i32(mode));
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

BlendFunc :: proc(sfactor : BlendFactors, dfactor : BlendFactors) {
    if _BlendFunc != nil {
        _BlendFunc(i32(sfactor), i32(dfactor));
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

GetShaderValue :: proc(shader : Shader, name : GetShaderNames) -> i32 {
    if _GetShaderiv != nil {
        res : i32;
        _GetShaderiv(u32(shader), i32(name), &res);
        return res;
    } else {

    }

    return 0;
}

GetString :: proc(name : GetStringNames, index : u32) -> string {
    if _GetStringi != nil {
        res := _GetStringi(i32(name), index);
        return strings.to_odin_string(res);
    } else {
        console.Log("%s isn't loaded!", #procedure);
        return "nil";
    }
}

GetString :: proc(name : GetStringNames) -> string {
    if _GetString != nil {
        res := _GetString(i32(name));
        return strings.to_odin_string(res);
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
    return "nil";
}

GetInteger :: proc(name : GetIntegerNames) -> i32 {
    if _GetIntegerv != nil { 
        res : i32;
        _GetIntegerv(i32(name), &res);
        return res;
    } else {
        console.Log("%s isn't loaded!", #procedure);
        return 0;
    }
}

GetInteger :: proc(name : GetIntegerNames, res : ^i32) {
    if _GetIntegerv != nil { 
        _GetIntegerv(i32(name), res);
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

Enable  :: proc(cap : Capabilities) {
    if _Enable != nil {
        _Enable(i32(cap));
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

Disable  :: proc(cap : Capabilities) {
    if _Disable != nil {
        _Disable(i32(cap));
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

AttachShader :: proc(program : Program, shader : Shader) {
    if _AttachShader != nil {
        _AttachShader(program.ID, u32(shader));
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

CreateProgram :: proc() -> Program {
    if _CreateProgram != nil {
        id := _CreateProgram();
        res : Program;
        res.ID = id;

        return res;
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }

    return Program{};
}

ShaderSource :: proc(obj : Shader, str : string) {
    array : [1]string;
    array[0] = str;
    ShaderSource(obj, array[..]);
}

ShaderSource :: proc(obj : Shader, strs : []string) {
    if _ShaderSource != nil {
        newStrs := make([]^byte, len(strs)); defer free(newStrs);
        lengths := make([]i32, len(strs)); defer free(lengths);
        for s, i in strs {
            newStrs[i] = &([]byte(s))[0];
            lengths[i] = i32(len(s));
        }
        _ShaderSource(u32(obj), u32(len(strs)), &newStrs[0], &lengths[0]);
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

CreateShader :: proc(type : ShaderTypes) -> Shader {
    if _CreateShader != nil {
        res := _CreateShader(i32(type));
        return Shader(res);
    } else {
        console.Log("%s isn't loaded!", #procedure);
        return Shader{};
    }
}

CompileShader :: proc(obj : Shader) {
    if _CompileShader != nil {
        _CompileShader(u32(obj));
    } else {
        console.Log("%s isn't loaded!", #procedure);
    }
}

GetInfo :: proc(vars : ^OpenGLVars_t) {
    vars.VersionMajorCur = GetInteger(GetIntegerNames.MajorVersion);
    vars.VersionMinorCur = GetInteger(GetIntegerNames.MinorVersion);
    vars.ContextFlags = GetInteger(GetIntegerNames.ContextFlags);
    vars.VersionString = GetString(GetStringNames.Version);
    vars.GLSLVersionString = GetString(GetStringNames.ShadingLanguageVersion);
    vars.VendorString = GetString(GetStringNames.Vendor);
    vars.RendererString = GetString(GetStringNames.Renderer);
    vars.NumExtensions = GetInteger(GetIntegerNames.NumExtensions);
    reserve(vars.Extensions, vars.NumExtensions);
    for i in 0..<vars.NumExtensions {
        ext := GetString(GetStringNames.Extensions, u32(i));
        append(vars.Extensions, ext);
    }
}

// Functions
    // Function variables
    _BufferData              : proc(target: i32, size: i32, data: rawptr, usage: i32)                                        #cc_c;
    _BindBuffer              : proc(target : i32, buffer : u32)                                                              #cc_c;
    _GenBuffers              : proc(n : i32, buffer : ^u32)                                                                  #cc_c;
    _GenVertexArrays         : proc(count: i32, buffers: ^u32)                                                               #cc_c;
    _EnableVertexAttribArray : proc(index: u32)                                                                              #cc_c;
    _VertexAttribPointer     : proc(index: u32, size: i32, type: i32, normalized: bool, stride: u32, pointer: rawptr)        #cc_c;
    _BindVertexArray         : proc(buffer: u32)                                                                             #cc_c;
    _Uniform1i               : proc(loc: i32, v0: i32)                                                                       #cc_c;
    _Uniform2i               : proc(loc: i32, v0, v1: i32)                                                                   #cc_c;
    _Uniform3i               : proc(loc: i32, v0, v1, v2: i32)                                                               #cc_c;
    _Uniform4i               : proc(loc: i32, v0, v1, v2, v3: i32)                                                           #cc_c;
    _Uniform1f               : proc(loc: i32, v0: f32)                                                                       #cc_c;
    _Uniform2f               : proc(loc: i32, v0, v1: f32)                                                                   #cc_c;
    _Uniform3f               : proc(loc: i32, v0, v1, v2: f32)                                                               #cc_c;
    _Uniform4f               : proc(loc: i32, v0, v1, v2, v3: f32)                                                           #cc_c;
    _UniformMatrix4fv        : proc(loc: i32, count: u32, transpose: i32, value: ^f32)                                       #cc_c;
    _GetUniformLocation      : proc(program: u32, name: ^byte) -> i32                                                        #cc_c;
    _GetAttribLocation       : proc(program: u32, name: ^byte) -> i32                                                        #cc_c;
    _DrawElements            : proc(mode: i32, count: i32, type_: i32, indices: rawptr)                                      #cc_c;
    _DrawArrays              : proc(mode: i32, first : i32, count : i32)                                                     #cc_c;
    _UseProgram              : proc(program: u32)                                                                            #cc_c;
    _LinkProgram             : proc(program: u32)                                                                            #cc_c;
    _ActiveTexture           : proc(texture: i32)                                                                            #cc_c;
    _BlendEquationSeparate   : proc(modeRGB : i32, modeAlpha : i32)                                                          #cc_c;
    _BlendEquation           : proc(mode : i32)                                                                              #cc_c;
    _AttachShader            : proc(program, shader: u32)                                                                    #cc_c;
    _CreateProgram           : proc() -> u32                                                                                 #cc_c;
    _ShaderSource            : proc(shader: u32, count: u32, str: ^^byte, length: ^i32)                                      #cc_c;
    _CreateShader            : proc(shader_type: i32) -> u32                                                                 #cc_c;
    _CompileShader           : proc(shader: u32)                                                                             #cc_c;
    _DebugMessageControl     : proc(source : i32, type : i32, severity : i32, count : i32, ids : ^u32, enabled : bool)       #cc_c;
    _DebugMessageCallback    : proc(callback : DebugMessageCallbackProc, userParam : rawptr)                                 #cc_c;
    _GetShaderiv             : proc(shader : u32, pname : i32, params : ^i32)                                                #cc_c;
    _GetShaderInfoLog        : proc(shader : u32, maxLength : i32, length : ^i32, infoLog : ^byte)                           #cc_c;
    _GetStringi              : proc(name : i32, index : u32) -> ^byte                                                        #cc_c;
    _BindFragDataLocation    : proc(program : u32, colorNumber : u32, name : ^byte)                                          #cc_c;
    _PolygonMode             : proc(face : i32, mode : i32)                                                                  #cc_c;
    _GenerateMipmap          : proc(target : i32)                                                                            #cc_c;
    _Enable                  : proc(cap: i32)                                                                                #cc_c;
    _DepthFunc               : proc(func: i32)                                                                               #cc_c;
    _GetString               : proc(name : i32) -> ^byte                                                                     #cc_c;
    _TexImage2D              : proc(target, level, internal_format, width, height, border, format, _type: i32, data: rawptr) #cc_c;
    _TexParameteri           : proc(target, pname, param: i32)                                                               #cc_c;
    _BindTexture             : proc(target: i32, texture: u32)                                                               #cc_c;
    _GenTextures             : proc(count: i32, result: ^u32)                                                                #cc_c;
    _BlendFunc               : proc(sfactor : i32, dfactor: i32)                                                             #cc_c;
    _GetIntegerv             : proc(name: i32, v: ^i32)                                                                      #cc_c;
    _Disable                 : proc(cap: i32)                                                                                #cc_c;
    _Clear                   : proc(mask: i32)                                                                               #cc_c;

    // Here because we're trying to get out the max version number before we have finished creating our context. Which we need to load out of the DLL apperently.
    _GetIntegervStatic   :: proc(name: i32, v: ^i32)                                                                     #foreign lib "glGetIntegerv";
    // BUG: Figure out why we crash if we late-bind these
    Viewport       :: proc(x : i32, y : i32, width : i32, height : i32)                                                  #foreign lib "glViewport";
    ClearColor     :: proc(red : f32, blue : f32, green : f32, alpha : f32)                                              #foreign lib "glClearColor";
    Scissor        :: proc(x : i32, y : i32, width : i32, height : i32)                                                  #foreign lib "glScissor";

Init :: proc() {
    libString := "opengl32.dll\x00";
    lib := win32.LoadLibraryA(&libString[0]); defer win32.FreeLibrary(lib);
    DebugInfo.LibAddress = int(lib);
    set_proc_address :: proc(h : win32.Hmodule, p: rawptr, name: string, info : ^Type_Info) #inline {
        txt := strings.new_c_string(name); defer free(txt);

        res := win32wgl.GetProcAddress(txt);
        if res == nil {
            res = win32.GetProcAddress(h, txt);
        }   

        ^(proc() #cc_c)(p)^ = res;

        status := DebugFunctionLoadStatus{};
        status.Name = name;
        status.Address = int(rawptr(res));
        status.Success = false;
        status.TypeInfo = info;
        DebugInfo.NumberOfFunctionsLoaded += 1;

        if status.Address != 0 {
            status.Success = true;
            DebugInfo.NumberOfFunctionsLoadedSuccessed += 1;
        }
        append(DebugInfo.Statuses, status);
    }

    set_proc_address(lib, &_DrawElements,            "glDrawElements",            type_info_of_val(_DrawElements)           );
    set_proc_address(lib, &_DrawArrays,              "glDrawArrays",              type_info_of_val(_DrawArrays)             );
    set_proc_address(lib, &_BindVertexArray,         "glBindVertexArray",         type_info_of_val(_BindVertexArray)        );
    set_proc_address(lib, &_VertexAttribPointer,     "glVertexAttribPointer",     type_info_of_val(_VertexAttribPointer)    );
    set_proc_address(lib, &_EnableVertexAttribArray, "glEnableVertexAttribArray", type_info_of_val(_EnableVertexAttribArray));
    set_proc_address(lib, &_GenVertexArrays,         "glGenVertexArrays",         type_info_of_val(_GenVertexArrays)        );
    set_proc_address(lib, &_BufferData,              "glBufferData",              type_info_of_val(_BufferData)             );
    set_proc_address(lib, &_BindBuffer,              "glBindBuffer",              type_info_of_val(_BindBuffer)             );
    set_proc_address(lib, &_GenBuffers,              "glGenBuffers",              type_info_of_val(_GenBuffers)             );
    set_proc_address(lib, &_DebugMessageControl,     "glDebugMessageControlARB",  type_info_of_val(_DebugMessageControl)    );
    set_proc_address(lib, &_DebugMessageCallback,    "glDebugMessageCallbackARB", type_info_of_val(_DebugMessageCallback)   );
    set_proc_address(lib, &_GetShaderiv,             "glGetShaderiv",             type_info_of_val(_GetShaderiv)            );
    set_proc_address(lib, &_GetShaderInfoLog,        "glGetShaderInfoLog",        type_info_of_val(_GetShaderInfoLog)       );
    set_proc_address(lib, &_GetStringi,              "glGetStringi",              type_info_of_val(_GetStringi)             );
    set_proc_address(lib, &_BlendEquation,           "glBlendEquation",           type_info_of_val(_BlendEquation)          );
    set_proc_address(lib, &_BlendEquationSeparate,   "glBlendEquationSeparate",   type_info_of_val(_BlendEquationSeparate)  );
    set_proc_address(lib, &_CompileShader,           "glCompileShader",           type_info_of_val(_CompileShader)          );
    set_proc_address(lib, &_CreateShader,            "glCreateShader",            type_info_of_val(_CreateShader)           );
    set_proc_address(lib, &_ShaderSource,            "glShaderSource",            type_info_of_val(_ShaderSource)           );
    set_proc_address(lib, &_AttachShader,            "glAttachShader",            type_info_of_val(_AttachShader)           ); 
    set_proc_address(lib, &_CreateProgram,           "glCreateProgram",           type_info_of_val(_CreateProgram)          );
    set_proc_address(lib, &_LinkProgram,             "glLinkProgram",             type_info_of_val(_LinkProgram)            );
    set_proc_address(lib, &_UseProgram,              "glUseProgram",              type_info_of_val(_UseProgram)             );
    set_proc_address(lib, &_ActiveTexture,           "glActiveTexture",           type_info_of_val(_ActiveTexture)          );
    set_proc_address(lib, &_Uniform1i,               "glUniform1i",               type_info_of_val(_Uniform1i)              );
    set_proc_address(lib, &_Uniform2i,               "glUniform2i",               type_info_of_val(_Uniform2i)              );
    set_proc_address(lib, &_Uniform3i,               "glUniform3i",               type_info_of_val(_Uniform3i)              );
    set_proc_address(lib, &_Uniform4i,               "glUniform4i",               type_info_of_val(_Uniform4i)              );
    set_proc_address(lib, &_Uniform1f,               "glUniform1f",               type_info_of_val(_Uniform1f)              );
    set_proc_address(lib, &_Uniform2f,               "glUniform2f",               type_info_of_val(_Uniform2f)              );
    set_proc_address(lib, &_Uniform3f,               "glUniform3f",               type_info_of_val(_Uniform3f)              );
    set_proc_address(lib, &_Uniform4f,               "glUniform4f",               type_info_of_val(_Uniform4f)              );
    set_proc_address(lib, &_UniformMatrix4fv,        "glUniformMatrix4fv",        type_info_of_val(_UniformMatrix4fv)       );
    set_proc_address(lib, &_GetUniformLocation,      "glGetUniformLocation",      type_info_of_val(_GetUniformLocation)     );
    set_proc_address(lib, &_GetAttribLocation,       "glGetAttribLocation",       type_info_of_val(_GetAttribLocation)      );
    set_proc_address(lib, &_PolygonMode,             "glPolygonMode",             type_info_of_val(_PolygonMode)            );
    set_proc_address(lib, &_GenerateMipmap,          "glGenerateMipmap",          type_info_of_val(_GenerateMipmap)         );
    set_proc_address(lib, &_Enable,                  "glEnable",                  type_info_of_val(_Enable)                 );
    set_proc_address(lib, &_DepthFunc,               "glDepthFunc",               type_info_of_val(_DepthFunc)              );
    set_proc_address(lib, &_BindFragDataLocation,    "glBindFragDataLocation",    type_info_of_val(_BindFragDataLocation)   );
    set_proc_address(lib, &_GetString,               "glGetString",               type_info_of_val(_GetString)              );
    set_proc_address(lib, &_TexImage2D,              "glTexImage2D",              type_info_of_val(_TexImage2D)             );
    set_proc_address(lib, &_TexParameteri,           "glTexParameteri",           type_info_of_val(_TexParameteri)          );
    set_proc_address(lib, &_BindTexture,             "glBindTexture",             type_info_of_val(_BindTexture)            );
    set_proc_address(lib, &_GenTextures,             "glGenTextures",             type_info_of_val(_GenTextures)            );
    set_proc_address(lib, &_BlendFunc,               "glBlendFunc",               type_info_of_val(_BlendFunc)              );
    set_proc_address(lib, &_GetIntegerv,             "glGetIntegerv",             type_info_of_val(_GetIntegerv)            );
    set_proc_address(lib, &_Disable,                 "glDisable",                 type_info_of_val(_Disable)                );
    set_proc_address(lib, &_Clear,                   "glClear",                   type_info_of_val(_Clear)                  );
}