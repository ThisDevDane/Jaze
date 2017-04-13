#foreign_system_library lib "opengl32.lib";
#import win32 "sys/windows.odin";
#import win32wgl "sys/wgl.odin";
#import "fmt.odin";
#import "strings.odin";
#load "jaze_gl_enums.odin";

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
}

DebugInfo : DebugInfo_t;

DebugMessageCallbackProc :: #type proc(source : DebugSource, type : DebugType, id : i32, severity : DebugSeverity, length : i32, message : ^byte, userParam : rawptr) #cc_c;

// Functions
    // Function variables
    _BufferData              : proc(target: i32, size: i32, data: rawptr, usage: i32)                                   #cc_c;
    _BindBuffer              : proc(target : i32, buffer : u32)                                                         #cc_c;
    _GenBuffers              : proc(n : i32, buffer : ^u32)                                                             #cc_c;
    _GenVertexArrays         : proc(count: i32, buffers: ^u32)                                                          #cc_c;
    _EnableVertexAttribArray : proc(index: u32)                                                                         #cc_c;
    _VertexAttribPointer     : proc(index: u32, size: i32, type: i32, normalized: bool, stride: u32, pointer: rawptr)   #cc_c;
    _BindVertexArray         : proc(buffer: u32)                                                                        #cc_c;
    _Uniform1i               : proc(loc: i32, v0: i32)                                                                  #cc_c;
    _Uniform2i               : proc(loc: i32, v0, v1: i32)                                                              #cc_c;
    _Uniform3i               : proc(loc: i32, v0, v1, v2: i32)                                                          #cc_c;
    _Uniform4i               : proc(loc: i32, v0, v1, v2, v3: i32)                                                      #cc_c;
    _Uniform1f               : proc(loc: i32, v0: f32)                                                                  #cc_c;
    _Uniform2f               : proc(loc: i32, v0, v1: f32)                                                              #cc_c;
    _Uniform3f               : proc(loc: i32, v0, v1, v2: f32)                                                          #cc_c;
    _Uniform4f               : proc(loc: i32, v0, v1, v2, v3: f32)                                                      #cc_c;
    _UniformMatrix4fv        : proc(loc: i32, count: u32, transpose: i32, value: ^f32)                                  #cc_c;
    _GetUniformLocation      : proc(program: u32, name: ^byte) -> i32                                                   #cc_c;
    _GetAttribLocation       : proc(program: u32, name: ^byte) -> i32                                                   #cc_c;
    _DrawElements            : proc(mode: i32, count: i32, type_: i32, indices: rawptr)                                 #cc_c;
    _DrawArrays              : proc(mode: i32, first : i32, count : i32)                                                #cc_c;
    _UseProgram              : proc(program: u32)                                                                       #cc_c;
    _LinkProgram             : proc(program: u32)                                                                       #cc_c;
    _ActiveTexture           : proc(texture: i32)                                                                       #cc_c;
    _BlendEquationSeparate   : proc(modeRGB : i32, modeAlpha : i32)                                                     #cc_c;
    _BlendEquation           : proc(mode : i32)                                                                         #cc_c;
    _AttachShader            : proc(program, shader: u32)                                                               #cc_c;
    _CreateProgram           : proc() -> u32                                                                            #cc_c;
    _ShaderSource            : proc(shader: u32, count: u32, str: ^^byte, length: ^i32)                                 #cc_c;
    _CreateShader            : proc(shader_type: i32) -> u32                                                            #cc_c;
    _CompileShader           : proc(shader: u32)                                                                        #cc_c;
    _DebugMessageControl     : proc(source : i32, type : i32, severity : i32, count : i32, ids : ^u32, enabled : bool)  #cc_c;
    _DebugMessageCallback    : proc(callback : DebugMessageCallbackProc, userParam : rawptr)                            #cc_c;
    _GetShaderiv             : proc(shader : u32, pname : i32, params : ^i32)                                           #cc_c;
    _GetShaderInfoLog        : proc(shader : u32, maxLength : i32, length : ^i32, infoLog : ^byte)                      #cc_c;
    _GetStringi              : proc(name : i32, index : u32) -> ^byte                                                   #cc_c;
    _BindFragDataLocation    : proc(program : u32, colorNumber : u32, name : ^byte)                                     #cc_c;

    // Foreign Function Declarations
    Viewport       :: proc(x : i32, y : i32, width : i32, height : i32)                                                  #foreign lib "glViewport";
    ClearColor     :: proc(red : f32, blue : f32, green : f32, alpha : f32)                                              #foreign lib "glClearColor";
    Scissor        :: proc(x : i32, y : i32, width : i32, height : i32)                                                  #foreign lib "glScissor";
    _GetString     :: proc(name : i32) -> ^byte                                                                          #foreign lib "glGetString";
    _TexImage2D    :: proc(target, level, internal_format, width, height, border, format, _type: i32, data: rawptr)      #foreign lib "glTexImage2D";
    _TexParameteri :: proc(target, pname, param: i32)                                                                    #foreign lib "glTexParameteri";
    _BindTexture   :: proc(target: i32, texture: u32)                                                                    #foreign lib "glBindTexture";
    _GenTextures   :: proc(count: i32, result: ^u32)                                                                     #foreign lib "glGenTextures";
    _BlendFunc     :: proc(sfactor : i32, dfactor: i32)                                                                  #foreign lib "glBlendFunc";
    _GetIntegerv   :: proc(name: i32, v: ^i32)                                                                           #foreign lib "glGetIntegerv";
    _Enable        :: proc(cap: i32)                                                                                     #foreign lib "glEnable";
    _Disable       :: proc(cap: i32)                                                                                     #foreign lib "glDisable";
    _Clear         :: proc(mask: i32)                                                                                    #foreign lib "glClear";

// Utility

// API

DebugMessageControl :: proc(source : DebugSource, type : DebugType, severity : DebugSeverity, count : i32, ids : ^u32, enabled : bool) {
    if _DebugMessageControl != nil {
        _DebugMessageControl(cast(i32)source, cast(i32)type, cast(i32)severity, count, ids, enabled);
    } else {
        //TODO logging
    }
}

DebugMessageCallback :: proc(callback : DebugMessageCallbackProc, userParam : rawptr) {
    if _DebugMessageCallback != nil {
        _DebugMessageCallback(callback, userParam);
    } else {
        //TODO logging
    }
}


Clear :: proc(mask : ClearFlags) {
    _Clear(cast(i32)mask);
}

BufferData :: proc(target : BufferTargets, size : i32, data : rawptr, usage : BufferDataUsage) {
    if _BufferData != nil {
        _BufferData(cast(i32)target, size, data, cast(i32)usage);
    } else {
        //Todo: logging
    }     
}

GenVBO :: proc() -> VBO {
    bo := GenBuffer();
    return cast(VBO)bo;
}

GenBuffer :: proc() -> BufferObject {
    if _GenBuffers != nil {
        res : BufferObject;
        _GenBuffers(1, cast(^u32)^res);
        return res;
    } else {
        //Todo: logging
        return 0;
    }      
}

GenBuffers :: proc(n : i32) -> []BufferObject {
    if _GenBuffers != nil {
        res := make([]BufferObject, n);
        _GenBuffers(n, cast(^u32)^res[0]);
        return res;
    } else {
        //Todo: logging
        return nil;
    }       
}

BindBuffer :: proc(target : BufferTargets, buffer : BufferObject) {
    if _BindBuffer != nil {
        _BindBuffer(cast(i32)target, cast(u32)buffer);
    } else {
        //Todo: logging
    }       
}

BindBuffer :: proc(vbo : VBO) {
    BindBuffer(BufferTargets.Array, cast(BufferObject)vbo);
}

BindBuffer :: proc(ebo : EBO) {
    BindBuffer(BufferTargets.ElementArray, cast(BufferObject)ebo);
     
}

BindFragDataLocation :: proc(program : Program, colorNumber : u32, name : string) {
    if _BindFragDataLocation != nil {
        c := strings.new_c_string(name); defer free(name);
        _BindFragDataLocation(program.ID, colorNumber, c);
    } else {
        // TODO: Logging        
    }
}

GenVertexArray :: proc() -> VAO {
    if _GenVertexArrays != nil {
        res : VAO;
        _GenVertexArrays(1, cast(^u32)^res);
        return res;
    } else {
        //Todo: logging
    }  

    return 0;
}

GenVertexArrays :: proc(count : i32) -> []VAO {
    if _GenVertexArrays != nil {
        res := make([]VAO, count);
        _GenVertexArrays(count, cast(^u32)^res[0]);
        return res;
    } else {
        //Todo: logging
    }  

    return nil;
}

EnableVertexAttribArray :: proc(index : u32) {
    if _EnableVertexAttribArray != nil {
        _EnableVertexAttribArray(index);
    } else {
        //Todo: logging
        fmt.println(#procedure, "failed!");
    }       
}

VertexAttribPointer :: proc(index : u32, size : i32, type : VertexAttribDataType, normalized : bool, stride : u32, pointer : rawptr) {
    if _VertexAttribPointer != nil {
        _VertexAttribPointer(index, size, cast(i32)type, normalized, stride, pointer);
    } else {
        //Todo: logging
        fmt.println(#procedure, "failed!");
    }       
}


BindVertexArray :: proc(buffer : VAO) {
    if _BindVertexArray != nil {
        _BindVertexArray(cast(u32)buffer);
    } else {
        //Todo: logging
    }    
}

Uniform :: proc(loc : i32, v0 : i32) {
    if _Uniform1i != nil {
        _Uniform1i(loc, v0);
    } else {
        //Todo: logging
    }
}

Uniform :: proc(loc: i32, v0, v1: i32) {
    if _Uniform2i != nil {
        _Uniform2i(loc, v0, v1);
    } else {
        //Todo: logging
    }
}

Uniform :: proc(loc: i32, v0, v1, v2: i32) {
    if _Uniform3i != nil {
        _Uniform3i(loc, v0, v1, v2);
    } else {
        //Todo: logging
    }
}

Uniform :: proc(loc: i32, v0, v1, v2, v3: i32) {
    if _Uniform4i != nil {
        _Uniform4i(loc, v0, v1, v2, v3);
    } else {
        //Todo: logging
    }
}

Uniform :: proc(loc: i32, v0: f32) {
    if _Uniform1f != nil {
        _Uniform1f(loc, v0);
    } else {
        //Todo: logging
    }
}

Uniform :: proc(loc: i32, v0, v1: f32) {
    if _Uniform2f != nil {
        _Uniform2f(loc, v0, v1);
    } else {
        //Todo: logging
    }
}

Uniform :: proc(loc: i32, v0, v1, v2: f32) {
    if _Uniform3f != nil {
        _Uniform3f(loc, v0, v1, v2);
    } else {
        //Todo: logging
    }
}

Uniform :: proc(loc: i32, v0, v1, v2, v3: f32) {
    if _Uniform4f != nil {
        _Uniform4f(loc, v0, v1, v2, v3);
    } else {
        //Todo: logging
    }
}

UniformMatrix4fv :: proc(loc : i32, values : []f32, transpose : bool) {
    if _UniformMatrix4fv != nil {
        _UniformMatrix4fv(loc, cast(u32)len(values), cast(i32)transpose, ^values[0]);
    } else {
        //Todo: logging
    }
}

GetUniformLocation :: proc(program : Program, name : string) -> i32{
    if _GetUniformLocation != nil {
        str := strings.new_c_string(name); defer free(str);
        res := _GetUniformLocation(cast(u32)program.ID, str);
        return res;
    } else {
        //Todo: logging
        return 0;
    }
}

GetAttribLocation :: proc(program : Program, name : string) -> i32 {
    if _GetAttribLocation != nil {
        str := strings.new_c_string(name); defer free(str);
        res := _GetAttribLocation(cast(u32)program.ID, str);
        return res;
    } else {
        //Todo: logging
        return 0;
    }
}

DrawElements :: proc(mode : DrawModes, count : i32, type : DrawElementsType, indices : rawptr) {
    if _DrawElements != nil {
        _DrawElements(cast(i32)mode, count, cast(i32)type, indices);
    } else {
        //Todo: logging
    }    
}

DrawArrays :: proc(mode : DrawModes, first : i32, count : i32) {
    if _DrawArrays != nil {
        _DrawArrays(cast(i32)mode, first, count);
    } else {
        //Todo: logging
    }    
}

UseProgram :: proc(program : Program) {
    if _UseProgram != nil {
        _UseProgram(program.ID);
    } else {
        //Todo: logging
    }
}

LinkProgram :: proc(program : Program) {
    if _LinkProgram != nil {
        _LinkProgram(program.ID);
    } else {
        //Todo: logging
    }
}

TexImage2D :: proc(target : TextureTargets, lod : i32, internalFormat : InternalColorFormat,
                   width : i32, height : i32, format : PixelDataFormat, type_ : Texture2DDataType,
                   data : rawptr) {
    _TexImage2D(cast(i32)target, lod, cast(i32)internalFormat, width, height, 0,
                cast(i32)format, cast(i32)type_, data);
}

TexParameteri  :: proc(target : TextureTargets, pname : TextureParameters, param : TextureParametersValues) {
    _TexParameteri(cast(i32)target, cast(i32)pname, cast(i32)param);
}

BindTexture :: proc(target : TextureTargets, texture : Texture) {
    _BindTexture(cast(i32)target, cast(u32)texture);
}

ActiveTexture :: proc(texture : TextureUnits) {
    if _ActiveTexture != nil {
        _ActiveTexture(cast(i32)texture);
    } else {
        //Todo: logging
    }
}

GenTexture :: proc() -> Texture {
    res : Texture;
    _GenTextures(1, cast(^u32)^res);
    return res;
}

GenTextures :: proc(count : i32) -> []Texture {
    res := make([]Texture, count);
    _GenTextures(count, cast(^u32)^res[0]);
    return res;
}

BlendEquationSeparate :: proc(modeRGB : BlendEquations, modeAlpha : BlendEquations) {
    if _BlendEquationSeparate != nil {
        _BlendEquationSeparate(cast(i32)modeRGB, cast(i32)modeAlpha);
    } else {
        //Todo: logging
    }    
}

BlendEquation :: proc(mode : BlendEquations) {
    if _BlendEquation != nil {
        _BlendEquation(cast(i32)mode);
    } else {
        //Todo: logging
    }
}
BlendFunc :: proc(sfactor : BlendFactors, dfactor : BlendFactors) {
    _BlendFunc(cast(i32)sfactor, cast(i32)dfactor);
}

GetShaderValue :: proc(shader : Shader, name : GetShaderNames) -> i32 {
    if _GetShaderiv != nil {
        res : i32;
        _GetShaderiv(cast(u32)shader, cast(i32)name, ^res);
        return res;
    } else {

    }

    return 0;
}

GetString :: proc(name : GetStringNames, index : u32) -> string {
    if _GetStringi != nil {
        res := _GetStringi(cast(i32)name, index);
        return strings.to_odin_string(res);
    } else {
        return "nil";
    }
}

GetString :: proc(name : GetStringNames) -> string {
    res := _GetString(cast(i32)name);
    return strings.to_odin_string(res);
}

GetInteger :: proc(name : GetIntegerNames) -> i32 {
    res : i32;
    _GetIntegerv(cast(i32)name, ^res);
    return res;
}

Enable  :: proc(cap : Capabilities) {
    _Enable(cast(i32)cap);
}

Disable  :: proc(cap : Capabilities) {
    _Disable(cast(i32)cap);
}

AttachShader :: proc(program : Program, shader : Shader) {
    if _AttachShader != nil {
        _AttachShader(program.ID, cast(u32)shader);
    } else {
        //Todo: logging
    }
}

CreateProgram :: proc() -> Program {
    if _CreateProgram != nil {
        id := _CreateProgram();
        res : Program;
        res.ID = id;

        return res;
    } else {
        //Todo: logging
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
            newStrs[i] = ^(cast([]byte)s)[0];
            lengths[i] = cast(i32)len(s);
        }
        _ShaderSource(cast(u32)obj, cast(u32)len(strs), ^newStrs[0], ^lengths[0]);
    } else {
        //Todo: logging
    }
}

CreateShader :: proc(type : ShaderTypes) -> Shader {
    if _CreateShader != nil {
        res := _CreateShader(cast(i32)type);
        return cast(Shader)res;
    } else {
        //Todo: logging
        return Shader{};
    }
}

CompileShader :: proc(obj : Shader) {
    if _CompileShader != nil {
        _CompileShader(cast(u32)obj);
    } else {
        //Todo: logging
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
    for i in 0..vars.NumExtensions {
        ext := GetString(GetStringNames.Extensions, cast(u32)i);
        append(vars.Extensions, ext);
    }
}



Init :: proc() {
    libString := "opengl32.dll\x00";
    lib := win32.LoadLibraryA(^libString[0]); defer win32.FreeLibrary(lib);
    DebugInfo.LibAddress = cast(int)lib;
    set_proc_address :: proc(h : win32.Hmodule, p: rawptr, name: string, info : ^Type_Info) #inline {
        txt := strings.new_c_string(name); defer free(txt);

        res := win32wgl.GetProcAddress(txt);
        if res == nil {
            res = win32.GetProcAddress(h, txt);
        }   

        (cast(^(proc() #cc_c))p)^ = res;

        status := DebugFunctionLoadStatus{};
        status.Name = name;
        status.Address = cast(int)cast(rawptr)res;
        status.Success = false;
        status.TypeInfo = info;
        DebugInfo.NumberOfFunctionsLoaded += 1;

        if status.Address != 0 {
            status.Success = true;
            DebugInfo.NumberOfFunctionsLoadedSuccessed += 1;
        }
        append(DebugInfo.Statuses, status);
    }

    set_proc_address(lib, ^_DrawElements,            "glDrawElements",            type_info_of_val(_DrawElements)           );
    set_proc_address(lib, ^_DrawArrays,              "glDrawArrays",              type_info_of_val(_DrawArrays)             );
    set_proc_address(lib, ^_BindVertexArray,         "glBindVertexArray",         type_info_of_val(_BindVertexArray)        );
    set_proc_address(lib, ^_VertexAttribPointer,     "glVertexAttribPointer",     type_info_of_val(_VertexAttribPointer)    );
    set_proc_address(lib, ^_EnableVertexAttribArray, "glEnableVertexAttribArray", type_info_of_val(_EnableVertexAttribArray));
    set_proc_address(lib, ^_GenVertexArrays,         "glGenVertexArrays",         type_info_of_val(_GenVertexArrays)        );
    set_proc_address(lib, ^_BufferData,              "glBufferData",              type_info_of_val(_BufferData)             );
    set_proc_address(lib, ^_BindBuffer,              "glBindBuffer",              type_info_of_val(_BindBuffer)             );
    set_proc_address(lib, ^_GenBuffers,              "glGenBuffers",              type_info_of_val(_GenBuffers)             );
    set_proc_address(lib, ^_DebugMessageControl,     "glDebugMessageControlARB",  type_info_of_val(_DebugMessageControl)    );
    set_proc_address(lib, ^_DebugMessageCallback,    "glDebugMessageCallbackARB", type_info_of_val(_DebugMessageCallback)   );
    set_proc_address(lib, ^_GetShaderiv,             "glGetShaderiv",             type_info_of_val(_GetShaderiv)            );
    set_proc_address(lib, ^_GetShaderInfoLog,        "glGetShaderInfoLog",        type_info_of_val(_GetShaderInfoLog)       );
    set_proc_address(lib, ^_GetStringi,              "glGetStringi",              type_info_of_val(_GetStringi)             );
    set_proc_address(lib, ^_BlendEquation,           "glBlendEquation",           type_info_of_val(_BlendEquation)          );
    set_proc_address(lib, ^_BlendEquationSeparate,   "glBlendEquationSeparate",   type_info_of_val(_BlendEquationSeparate)  );
    set_proc_address(lib, ^_CompileShader,           "glCompileShader",           type_info_of_val(_CompileShader)          );
    set_proc_address(lib, ^_CreateShader,            "glCreateShader",            type_info_of_val(_CreateShader)           );
    set_proc_address(lib, ^_ShaderSource,            "glShaderSource",            type_info_of_val(_ShaderSource)           );
    set_proc_address(lib, ^_AttachShader,            "glAttachShader",            type_info_of_val(_AttachShader)           ); 
    set_proc_address(lib, ^_CreateProgram,           "glCreateProgram",           type_info_of_val(_CreateProgram)          );
    set_proc_address(lib, ^_LinkProgram,             "glLinkProgram",             type_info_of_val(_LinkProgram)            );
    set_proc_address(lib, ^_UseProgram,              "glUseProgram",              type_info_of_val(_UseProgram)             );
    set_proc_address(lib, ^_ActiveTexture,           "glActiveTexture",           type_info_of_val(_ActiveTexture)          );
    set_proc_address(lib, ^_Uniform1i,               "glUniform1i",               type_info_of_val(_Uniform1i)              );
    set_proc_address(lib, ^_Uniform2i,               "glUniform2i",               type_info_of_val(_Uniform2i)              );
    set_proc_address(lib, ^_Uniform3i,               "glUniform3i",               type_info_of_val(_Uniform3i)              );
    set_proc_address(lib, ^_Uniform4i,               "glUniform4i",               type_info_of_val(_Uniform4i)              );
    set_proc_address(lib, ^_Uniform1f,               "glUniform1f",               type_info_of_val(_Uniform1f)              );
    set_proc_address(lib, ^_Uniform2f,               "glUniform2f",               type_info_of_val(_Uniform2f)              );
    set_proc_address(lib, ^_Uniform3f,               "glUniform3f",               type_info_of_val(_Uniform3f)              );
    set_proc_address(lib, ^_Uniform4f,               "glUniform4f",               type_info_of_val(_Uniform4f)              );
    set_proc_address(lib, ^_UniformMatrix4fv,        "glUniformMatrix4fv",        type_info_of_val(_UniformMatrix4fv)       );
    set_proc_address(lib, ^_GetUniformLocation,      "glGetUniformLocation",      type_info_of_val(_GetUniformLocation)     );
    set_proc_address(lib, ^_GetAttribLocation,       "glGetAttribLocation",       type_info_of_val(_GetAttribLocation)      );
}