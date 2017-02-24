#foreign_system_library lib "opengl32.lib";
#import win32 "sys/windows.odin";
#import win32wgl "sys/wgl.odin";
#import "fmt.odin";
#load "jaze_gl_enums.odin";

to_c_string :: proc(s : string) -> ^byte {
    c := new_slice(byte, s.count+1);
    copy(c, cast([]byte)s);
    c[s.count] = 0;
    return c.data;
}

to_odin_string :: proc(c: ^byte) -> string {
    s: string;
    s.data = c;
    for (c + s.count)^ != 0 {
        s.count += 1;
    }
    return s;
}

TRUE  :: 1;
FALSE :: 0;

// Types
ShaderObject :: u32;
Program      :: u32;
VAO          :: u32;
VBO          :: u32;
EBO          :: u32;
Texture      :: u32;
BufferObject :: u32;

DebugMessageCallbackProc :: #type proc(source : DebugSource, type : DebugType, id : i32, severity : DebugSeverity, length : i32, message : ^byte, userParam : rawptr) #cc_c;

// Functions
    // Function variables
    _BufferData              : proc(target: i32, size: i32, data: rawptr, usage: i32)                                   #cc_c;
    _BindBuffer              : proc(target : i32, buffer : u32)                                                         #cc_c;
    _GenBuffers              : proc(n : i32, buffer : ^u32)                                                             #cc_c;
    _GenVertexArrays         : proc(count: i32, buffers: ^u32)                                                          #cc_c;
    _EnableVertexAttribArray : proc(index: u32)                                                                         #cc_c;
    _VertexAttribPointer     : proc(index: u32, size: i32, type: i32, normalized: bool, stride: u32, pointer: rawptr)     #cc_c;
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

    // Foreign Function Declarations
    Viewport       :: proc(x : i32, y : i32, width : i32, height : i32)                                             #foreign lib "glViewport";
    ClearColor     :: proc(red: f32, blue: f32, green: f32, alpha: f32)                                              #foreign lib "glClearColor";
    Scissor        :: proc(x : i32, y : i32, width : i32, height : i32)                                             #foreign lib "glScissor";
    _GetString     :: proc(name : i32) -> ^byte                                                                     #foreign lib "glGetString";
    _TexImage2D    :: proc(target, level, internal_format, width, height, border, format, _type: i32, data: rawptr) #foreign lib "glTexImage2D";
    _TexParameteri :: proc(target, pname, param: i32)                                                               #foreign lib "glTexParameteri";
    _BindTexture   :: proc(target: i32, texture: u32)                                                               #foreign lib "glBindTexture";
    _GenTextures   :: proc(count: i32, result: ^u32)                                                                #foreign lib "glGenTextures";
    _BlendFunc     :: proc(sfactor : i32, dfactor: i32)                                                             #foreign lib "glBlendFunc";
    _GetIntegerv   :: proc(name: i32, v: ^i32)                                                                      #foreign lib "glGetIntegerv";
    _Enable        :: proc(cap: i32)                                                                                #foreign lib "glEnable";
    _Disable       :: proc(cap: i32)                                                                                #foreign lib "glDisable";
    _Clear         :: proc(mask: i32)                                                                               #foreign lib "glClear";

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
        res := new_slice(BufferObject, n);
        _GenBuffers(n, cast(^u32)res.data);
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

BindBuffer_EBO :: proc(ebo : EBO) {
    BindBuffer(BufferTargets.ElementArray, cast(BufferObject)ebo);
     
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
        res := new_slice(VAO, count);
        _GenVertexArrays(count, cast(^u32)res.data);
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
    }       
}

VertexAttribPointer :: proc(index : u32, size : i32, type : VertexAttribDataType, normalized : bool, stride : u32, pointer : rawptr) {
    if _VertexAttribPointer != nil {
        _VertexAttribPointer(index, size, cast(i32)type, normalized, stride, pointer);
    } else {
        //Todo: logging
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
        _UniformMatrix4fv(loc, cast(u32)values.count, cast(i32)transpose, values.data);
    } else {
        //Todo: logging
    }
}

GetUniformLocation :: proc(program : Program, name : string) -> i32{
    if _GetUniformLocation != nil {
        str := to_c_string(name); defer free(str);
        res := _GetUniformLocation(cast(u32)program, str);
        return res;
    } else {
        //Todo: logging
        return 0;
    }
}

GetAttribLocation :: proc(program : Program, name : string) -> i32 {
    if _GetAttribLocation != nil {
        str := to_c_string(name); defer free(str);
        res := _GetAttribLocation(cast(u32)program, str);
        return res;
    } else {
        //Todo: logging
        return 0;
    }
}

DrawElements :: proc(mode : DrawModes, count : i32, type : DrawElementsType, indices : rawptr) {
    if _DrawElements != nil {
        fmt.println(#file, #line, #procedure);
        _DrawElements(cast(i32)mode, count, cast(i32)type, indices);
        fmt.println(#file, #line, #procedure);
    } else {
        //Todo: logging
    }    
}

UseProgram :: proc(program : Program) {
    if _UseProgram != nil {
        _UseProgram(cast(u32)program);
    } else {
        //Todo: logging
    }
}

LinkProgram :: proc(program : Program) {
    if _LinkProgram != nil {
        _LinkProgram(cast(u32)program);
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
    res := new_slice(Texture, count);
    _GenTextures(count, cast(^u32)res.data);
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

GetString :: proc(name : GetStringNames) -> string {
    res := _GetString(cast(i32)name);
    return to_odin_string(res);
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

AttachShader :: proc(program : Program, obj : ShaderObject) {
    if _AttachShader != nil {
        _AttachShader(cast(u32)program, cast(u32)obj);
    } else {
        //Todo: logging
    }
}

CreateProgram :: proc() -> Program {
    if _CreateProgram != nil {
        res := _CreateProgram();
        return cast(Program)res;
    } else {
        //Todo: logging
    }

    return 0;
}

ShaderSource :: proc(obj : ShaderObject, str : string) {
    array : [1]string;
    array[0] = str;
    ShaderSource(obj, array[:]);
}

ShaderSource :: proc(obj : ShaderObject, strs : []string) {
    if _ShaderSource != nil {
        newStrs := new_slice(^byte, strs.count); defer free(newStrs);
        lengths := new_slice(i32, strs.count); defer free(lengths);
        for s, i in strs {
            newStrs[i] = s.data;
            lengths[i] = cast(i32)s.count;
        }
        _ShaderSource(cast(u32)obj, cast(u32)strs.count, newStrs.data, lengths.data);
    } else {
        //Todo: logging
    }
}

CreateShader :: proc(type : ShaderTypes) -> ShaderObject {
    if _CreateShader != nil {
        res := _CreateShader(cast(i32)type);
        return cast(ShaderObject)res;
    } else {
        //Todo: logging
        return 0;
    }
}

CompileShader :: proc(obj : ShaderObject) {
    if _CompileShader != nil {
        _CompileShader(cast(u32)obj);
    } else {
        //Todo: logging
    }
}

Init :: proc() {
    lib := win32.LoadLibraryA((cast(string)("opengl32.dll\x00")).data); defer win32.FreeLibrary(lib);
    set_proc_address :: proc(h : win32.HMODULE, p: rawptr, name: string) #inline { 
        txt := to_c_string(name); defer free(txt);

        res := win32wgl.GetProcAddress(txt);
        if res == nil {
            res = win32.GetProcAddress(h, txt);
        }   

        (cast(^(proc() #cc_c))p)^ = res;
    }

    set_proc_address(lib, ^_BlendEquation,           "glBlendEquation");
    set_proc_address(lib, ^_BlendEquationSeparate,   "glBlendEquationSeparate");

    set_proc_address(lib, ^_CompileShader,           "glCompileShader");
    set_proc_address(lib, ^_CreateShader,            "glCreateShader");
    set_proc_address(lib, ^_ShaderSource,            "glShaderSource");
    set_proc_address(lib, ^_AttachShader,            "glAttachShader");
    
    set_proc_address(lib, ^_CreateProgram,           "glCreateProgram");
    set_proc_address(lib, ^_LinkProgram,             "glLinkProgram");
    set_proc_address(lib, ^_UseProgram,              "glUseProgram");

    set_proc_address(lib, ^_ActiveTexture,           "glActiveTexture");

    set_proc_address(lib, ^_Uniform1i,               "glUniform1i");
    set_proc_address(lib, ^_Uniform2i,               "glUniform2i");
    set_proc_address(lib, ^_Uniform3i,               "glUniform3i");
    set_proc_address(lib, ^_Uniform4i,               "glUniform4i");

    set_proc_address(lib, ^_Uniform1f,               "glUniform1f");
    set_proc_address(lib, ^_Uniform2f,               "glUniform2f");
    set_proc_address(lib, ^_Uniform3f,               "glUniform3f");
    set_proc_address(lib, ^_Uniform4f,               "glUniform4f");

    set_proc_address(lib, ^_UniformMatrix4fv,        "glUniformMatrix4fv");
    set_proc_address(lib, ^_GetUniformLocation,      "glGetUniformLocation");
    set_proc_address(lib, ^_GetAttribLocation,       "glGetAttribLocation");

    set_proc_address(lib, ^_DrawElements,            "glDrawElements");

    set_proc_address(lib, ^_BindVertexArray,         "glBindVertexArray");
    set_proc_address(lib, ^_VertexAttribPointer,     "glVertexAttribPointer");
    set_proc_address(lib, ^_EnableVertexAttribArray, "glEnableVertexAttribArray");
    set_proc_address(lib, ^_GenVertexArrays,         "glGenVertexArrays");

    set_proc_address(lib, ^_BufferData,              "glBufferData");
    set_proc_address(lib, ^_BindBuffer,              "glBindBuffer");
    set_proc_address(lib, ^_GenBuffers,              "glGenBuffers");

    set_proc_address(lib, ^_DebugMessageControl,     "glDebugMessageControlARB");
    set_proc_address(lib, ^_DebugMessageCallback,    "glDebugMessageCallbackARB");
}

