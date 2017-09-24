/*
 *  @Name:     gl
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 26-04-2017 16:23:18
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 24-09-2017 22:00:40
 *  
 *  @Description:
 *      This is an OpenGL wrapper. Currently assumes GL 3.3 Core.
 *      It late binds requested functions. Currently a hardcoded list.
 *      It wraps each function to check if it has been loaded and will output to in engine console if not.
 */
foreign_system_library lib "opengl32.lib";
import win32 "sys/windows.odin";
import win32_wgl "sys/wgl.odin";
import "core:fmt.odin";
import "core:strings.odin";
import "core:math.odin";
using import "gl_enums.odin";

import "console.odin";

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

OpenGLVars :: struct {
    ctx                 : win32_wgl.Hglrc,

    version_major_max   : i32,
    version_major_cur   : i32,
    version_minor_max   : i32,
    version_minor_cur   : i32,
    version_string      : string,
    glsl_version_string : string,

    vendor_string       : string,
    renderer_string     : string,

    context_flags       : i32,

    num_extensions      : i32,
    extensions          : [dynamic]string,
    num_wgl_extensions  : i32,
    wgl_extensions      : [dynamic]string,
}

DebugFunctionLoadStatus :: struct {
    name    : string,
    address : int,
    success : bool,
    type_info : ^TypeInfo,
}

DebugInfo :: struct {
    lib_address : int,
    number_of_functions_loaded : i32,
    number_of_functions_loaded_successed : i32,
    statuses : [dynamic]DebugFunctionLoadStatus,
    loaded_textures : [dynamic]Texture,

    draw_calls : int,
}

debug_info : DebugInfo;

DebugMessageCallbackProc :: #type proc(source : DebugSource, type_ : DebugType, id : i32, severity : DebugSeverity, length : i32, message : ^byte, userParam : rawptr) #cc_c;

// API 

depth_func :: proc(func : DepthFuncs) {
    if _depth_func != nil {
        _depth_func(i32(func));
    } else {
        console.log_error("%s ins't loaded!", #procedure);
    }
}

generate_mipmap :: proc(target : MipmapTargets) {
    if _generate_mipmap != nil {
        _generate_mipmap(i32(target));
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

polygon_mode :: proc(face : PolygonFace, mode : PolygonModes) {
    if _polygon_mode != nil {
        _polygon_mode(i32(face), i32(mode));
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

debug_message_control :: proc(source : DebugSource, type_ : DebugType, severity : DebugSeverity, count : i32, ids : ^u32, enabled : bool) {
    if _debug_message_control != nil {
        _debug_message_control(i32(source), i32(type_), i32(severity), count, ids, enabled);
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

debug_message_callback :: proc(callback : DebugMessageCallbackProc, userParam : rawptr) {
    if _debug_message_callback != nil {
        _debug_message_callback(callback, userParam);
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}


clear :: proc(mask : ClearFlags) {
    _clear(i32(mask));
}

buffer_data :: proc(target : BufferTargets, data : []f32, usage : BufferDataUsage) {
    if _buffer_data != nil {
        _buffer_data(i32(target), size_of_val(data), &data[0], i32(usage));
    } else {
        console.log("%s isn't loaded!", #procedure);
    }     
}

buffer_data :: proc(target : BufferTargets, data : []u32, usage : BufferDataUsage) {
    if _buffer_data != nil {
        _buffer_data(i32(target), size_of_val(data), &data[0], i32(usage));
    } else {
        console.log("%s isn't loaded!", #procedure);
    }     
}


buffer_data :: proc(target : BufferTargets, size : i32, data : rawptr, usage : BufferDataUsage) {
    if _buffer_data != nil {
        _buffer_data(i32(target), size, data, i32(usage));
    } else {
        console.log("%s isn't loaded!", #procedure);
    }     
}

gen_vbo :: proc() -> VBO {
    bo := gen_buffer();
    return VBO(bo);
}

gen_ebo :: proc() -> EBO {
    bo := gen_buffer();
    return EBO(bo);
}

gen_buffer :: proc() -> BufferObject {
    if _gen_buffers != nil {
        res : BufferObject;
        _gen_buffers(1, ^u32(&res));
        return res;
    } else {
        console.log("%s isn't loaded!", #procedure);
        return 0;
    }      
}

gen_buffers :: proc(n : i32) -> []BufferObject {
    if _gen_buffers != nil {
        res := make([]BufferObject, n);
        _gen_buffers(n, ^u32(&res[0]));
        return res;
    } else {
        console.log("%s isn't loaded!", #procedure);
        return nil;
    }       
}

bind_buffer :: proc(target : BufferTargets, buffer : BufferObject) {
    if _bind_buffer != nil {
        _bind_buffer(i32(target), u32(buffer));
    } else {
        console.log("%s isn't loaded!", #procedure);
    }       
}

bind_buffer :: proc(vbo : VBO) {
    bind_buffer(BufferTargets.Array, BufferObject(vbo));
}

bind_buffer :: proc(ebo : EBO) {
    bind_buffer(BufferTargets.ElementArray, BufferObject(ebo));
     
}

bind_frag_data_location :: proc(program : Program, colorNumber : u32, name : string) {
    if _bind_frag_data_location != nil {
        c := strings.new_c_string(name);
        _bind_frag_data_location(program.ID, colorNumber, c);
    } else {
        console.log("%s isn't loaded!", #procedure);      
    }
}

gen_vertex_array :: proc() -> VAO {
    if _gen_vertex_arrays != nil {
        res : VAO;
        _gen_vertex_arrays(1, ^u32(&res));
        return res;
    } else {
        console.log("%s isn't loaded!", #procedure);
    }  

    return 0;
}

gen_vertex_arrays :: proc(count : i32) -> []VAO {
    if _gen_vertex_arrays != nil {
        res := make([]VAO, count);
        _gen_vertex_arrays(count, ^u32(&res[0]));
        return res;
    } else {
        console.log("%s isn't loaded!", #procedure);
    }  

    return nil;
}

enable_vertex_attrib_array :: proc(index : u32) {
    if _enable_vertex_attrib_array != nil {
        _enable_vertex_attrib_array(index);
    } else {
        console.log("%s isn't loaded!", #procedure);
    }       
}

vertex_attrib_pointer :: proc(index : u32, size : i32, type_ : VertexAttribDataType, normalized : bool, stride : u32, pointer : rawptr) {
    if _vertex_attrib_pointer != nil {
        _vertex_attrib_pointer(index, size, i32(type_), normalized, stride, pointer);
    } else {
        console.log("%s isn't loaded!", #procedure);
    }       
}


bind_vertex_array :: proc(buffer : VAO) {
    if _bind_vertex_array != nil {
        _bind_vertex_array(u32(buffer));
    } else {
        console.log("%s isn't loaded!", #procedure);
    }    
}

uniform :: proc(loc : i32, v0 : i32) {
    if _uniform1i != nil {
        _uniform1i(loc, v0);
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

uniform :: proc(loc: i32, v0, v1: i32) {
    if _uniform2i != nil {
        _uniform2i(loc, v0, v1);
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

uniform :: proc(loc: i32, v0, v1, v2: i32) {
    if _uniform3i != nil {
        _uniform3i(loc, v0, v1, v2);
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

uniform :: proc(loc: i32, v0, v1, v2, v3: i32) {
    if _uniform4i != nil {
        _uniform4i(loc, v0, v1, v2, v3);
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

uniform :: proc(loc: i32, v0: f32) {
    if _uniform1f != nil {
        _uniform1f(loc, v0);
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

uniform :: proc(loc: i32, v0, v1: f32) {
    if _uniform2f != nil {
        _uniform2f(loc, v0, v1);
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

uniform :: proc(loc: i32, v0, v1, v2: f32) {
    if _uniform3f != nil {
        _uniform3f(loc, v0, v1, v2);
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

uniform :: proc(loc: i32, v0, v1, v2, v3: f32) {
    if _uniform4f != nil {
        _uniform4f(loc, v0, v1, v2, v3);
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

uniform :: proc(loc: i32, v: math.Vec4) {
    uniform(loc, v.x, v.y, v.z, v.w);
}

uniform_matrix4fv :: proc(loc : i32, matrix : math.Mat4, transpose : bool) {
    if _uniform_matrix4fv != nil {
        _uniform_matrix4fv(loc, 1, i32(transpose), ^f32(&matrix));
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

get_uniform_location :: proc(program : Program, name : string) -> i32{
    if _get_uniform_location != nil {
        str := strings.new_c_string(name); defer free(str);
        res := _get_uniform_location(u32(program.ID), str);
        return res;
    } else {
        console.log("%s isn't loaded!", #procedure);
        return 0;
    }
}

get_attrib_location :: proc(program : Program, name : string) -> i32 {
    if _get_attrib_location != nil {
        str := strings.new_c_string(name); defer free(str);
        res := _get_attrib_location(u32(program.ID), str);
        return res;
    } else {
        console.log("%s isn't loaded!", #procedure);
        return 0;
    }
}

draw_elements :: proc(mode : DrawModes, count : i32, type_ : DrawElementsType, indices : rawptr) {
    if _draw_elements != nil {
        _draw_elements(i32(mode), count, i32(type_), indices);
        debug_info.draw_calls += 1;
    } else {
        console.log("%s isn't loaded!", #procedure);
    }    
}

draw_arrays :: proc(mode : DrawModes, first : i32, count : i32) {
    if _draw_arrays != nil {
        _draw_arrays(i32(mode), first, count);
        debug_info.draw_calls += 1;
    } else {
        console.log("%s isn't loaded!", #procedure);
    }    
}

use_program :: proc(program : Program) {
    if _use_program != nil {
        _use_program(program.ID);
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

link_program :: proc(program : Program) {
    if _link_program != nil {
        _link_program(program.ID);
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

tex_image2d :: proc(target : TextureTargets, lod : i32, internalFormat : InternalColorFormat,
                   width : i32, height : i32, format : PixelDataFormat, type_ : Texture2DDataType,
                   data : rawptr) {
    _tex_image2d(i32(target), lod, i32(internalFormat), width, height, 0,
                i32(format), i32(type_), data);
}

tex_parameteri  :: proc(target : TextureTargets, pname : TextureParameters, param : TextureParametersValues) {
    _tex_parameteri(i32(target), i32(pname), i32(param));
}

bind_texture :: proc(target : TextureTargets, texture : Texture) {
    _bind_texture(i32(target), u32(texture));
}

active_texture :: proc(texture : TextureUnits) {
    if _active_texture != nil {
        _active_texture(i32(texture));
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

gen_texture :: proc() -> Texture {
    res := gen_textures(1);
    return res[0];
}

gen_textures :: proc(count : i32) -> []Texture {
    res := make([]Texture, count);
    _gen_textures(count, ^u32(&res[0]));
    for id in res {
        append(debug_info.loaded_textures, id);
    }
    return res;
}

blend_equation_separate :: proc(modeRGB : BlendEquations, modeAlpha : BlendEquations) {
    if _blend_equation_separate != nil {
        _blend_equation_separate(i32(modeRGB), i32(modeAlpha));
    } else {
        console.log("%s isn't loaded!", #procedure);
    }    
}

blend_equation :: proc(mode : BlendEquations) {
    if _blend_equation != nil {
        _blend_equation(i32(mode));
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

blend_func :: proc(sfactor : BlendFactors, dfactor : BlendFactors) {
    if _blend_func != nil {
        _blend_func(i32(sfactor), i32(dfactor));
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

get_shader_value :: proc(shader : Shader, name : GetShaderNames) -> i32 {
    if _get_shaderiv != nil {
        res : i32;
        _get_shaderiv(u32(shader), i32(name), &res);
        return res;
    } else {

    }

    return 0;
}

get_string :: proc(name : GetStringNames, index : u32) -> string {
    if _get_stringi != nil {
        res := _get_stringi(i32(name), index);
        return strings.to_odin_string(res);
    } else {
        console.log("%s isn't loaded!", #procedure);
        return "nil";
    }
}

get_string :: proc(name : GetStringNames) -> string {
    if _get_string != nil {
        res := _get_string(i32(name));
        return strings.to_odin_string(res);
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
    return "nil";
}

get_integer :: proc(name : GetIntegerNames) -> i32 {
    if _get_integerv != nil { 
        res : i32;
        _get_integerv(i32(name), &res);
        return res;
    } else {
        console.log("%s isn't loaded!", #procedure);
        return 0;
    }
}

get_integer :: proc(name : GetIntegerNames, res : ^i32) {
    if _get_integerv != nil { 
        _get_integerv(i32(name), res);
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

enable  :: proc(cap : Capabilities) {
    if _enable != nil {
        _enable(i32(cap));
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

disable  :: proc(cap : Capabilities) {
    if _disable != nil {
        _disable(i32(cap));
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

attach_shader :: proc(program : Program, shader : Shader) {
    if _attach_shader != nil {
        _attach_shader(program.ID, u32(shader));
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

create_program :: proc() -> Program {
    if _create_program != nil {
        id := _create_program();
        res : Program;
        res.ID = id;

        return res;
    } else {
        console.log("%s isn't loaded!", #procedure);
    }

    return Program{};
}

shader_source :: proc(obj : Shader, str : string) {
    array : [1]string;
    array[0] = str;
    shader_source(obj, array[..]);
}

shader_source :: proc(obj : Shader, strs : []string) {
    if _shader_source != nil {
        newStrs := make([]^byte, len(strs)); defer free(newStrs);
        lengths := make([]i32, len(strs)); defer free(lengths);
        for s, i in strs {
            newStrs[i] = &([]byte(s))[0];
            lengths[i] = i32(len(s));
        }
        _shader_source(u32(obj), u32(len(strs)), &newStrs[0], &lengths[0]);
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

create_shader :: proc(type_ : ShaderTypes) -> Shader {
    if _create_shader != nil {
        res := _create_shader(i32(type_));
        return Shader(res);
    } else {
        console.log("%s isn't loaded!", #procedure);
        return Shader{};
    }
}

compile_shader :: proc(obj : Shader) {
    if _compile_shader != nil {
        _compile_shader(u32(obj));
    } else {
        console.log("%s isn't loaded!", #procedure);
    }
}

get_info :: proc(vars : ^OpenGLVars) {
    vars.version_major_cur = get_integer(GetIntegerNames.MajorVersion);
    vars.version_minor_cur = get_integer(GetIntegerNames.MinorVersion);
    vars.context_flags = get_integer(GetIntegerNames.ContextFlags);
    vars.version_string = get_string(GetStringNames.Version);
    vars.glsl_version_string = get_string(GetStringNames.ShadingLanguageVersion);
    vars.vendor_string = get_string(GetStringNames.Vendor);
    vars.renderer_string = get_string(GetStringNames.Renderer);
    vars.num_extensions = get_integer(GetIntegerNames.NumExtensions);
    reserve(vars.extensions, vars.num_extensions);
    for i in 0..vars.num_extensions {
        ext := get_string(GetStringNames.Extensions, u32(i));
        append(vars.extensions, ext);
    }
}

// Functions
    // Function variables
    _buffer_data                : proc(target: i32, size: i32, data: rawptr, usage: i32)                                        #cc_c;
    _bind_buffer                : proc(target : i32, buffer : u32)                                                              #cc_c;
    _gen_buffers                : proc(n : i32, buffer : ^u32)                                                                  #cc_c;
    _gen_vertex_arrays          : proc(count: i32, buffers: ^u32)                                                               #cc_c;
    _enable_vertex_attrib_array : proc(index: u32)                                                                              #cc_c;
    _vertex_attrib_pointer      : proc(index: u32, size: i32, type_: i32, normalized: bool, stride: u32, pointer: rawptr)        #cc_c;
    _bind_vertex_array          : proc(buffer: u32)                                                                             #cc_c;
    _uniform1i                  : proc(loc: i32, v0: i32)                                                                       #cc_c;
    _uniform2i                  : proc(loc: i32, v0, v1: i32)                                                                   #cc_c;
    _uniform3i                  : proc(loc: i32, v0, v1, v2: i32)                                                               #cc_c;
    _uniform4i                  : proc(loc: i32, v0, v1, v2, v3: i32)                                                           #cc_c;
    _uniform1f                  : proc(loc: i32, v0: f32)                                                                       #cc_c;
    _uniform2f                  : proc(loc: i32, v0, v1: f32)                                                                   #cc_c;
    _uniform3f                  : proc(loc: i32, v0, v1, v2: f32)                                                               #cc_c;
    _uniform4f                  : proc(loc: i32, v0, v1, v2, v3: f32)                                                           #cc_c;
    _uniform_matrix4fv          : proc(loc: i32, count: u32, transpose: i32, value: ^f32)                                       #cc_c;
    _get_uniform_location       : proc(program: u32, name: ^byte) -> i32                                                        #cc_c;
    _get_attrib_location        : proc(program: u32, name: ^byte) -> i32                                                        #cc_c;
    _draw_elements              : proc(mode: i32, count: i32, type_: i32, indices: rawptr)                                      #cc_c;
    _draw_arrays                : proc(mode: i32, first : i32, count : i32)                                                     #cc_c;
    _use_program                : proc(program: u32)                                                                            #cc_c;
    _link_program               : proc(program: u32)                                                                            #cc_c;
    _active_texture             : proc(texture: i32)                                                                            #cc_c;
    _blend_equation_separate    : proc(modeRGB : i32, modeAlpha : i32)                                                          #cc_c;
    _blend_equation             : proc(mode : i32)                                                                              #cc_c;
    _attach_shader              : proc(program, shader: u32)                                                                    #cc_c;
    _create_program             : proc() -> u32                                                                                 #cc_c;
    _shader_source              : proc(shader: u32, count: u32, str: ^^byte, length: ^i32)                                      #cc_c;
    _create_shader              : proc(shader_type: i32) -> u32                                                                 #cc_c;
    _compile_shader             : proc(shader: u32)                                                                             #cc_c;
    _debug_message_control      : proc(source : i32, type_ : i32, severity : i32, count : i32, ids : ^u32, enabled : bool)       #cc_c;
    _debug_message_callback     : proc(callback : DebugMessageCallbackProc, userParam : rawptr)                                 #cc_c;
    _get_shaderiv               : proc(shader : u32, pname : i32, params : ^i32)                                                #cc_c;
    _get_shader_info_log        : proc(shader : u32, maxLength : i32, length : ^i32, infolog : ^byte)                           #cc_c;
    _get_stringi                : proc(name : i32, index : u32) -> ^byte                                                        #cc_c;
    _bind_frag_data_location    : proc(program : u32, colorNumber : u32, name : ^byte)                                          #cc_c;
    _polygon_mode               : proc(face : i32, mode : i32)                                                                  #cc_c;
    _generate_mipmap            : proc(target : i32)                                                                            #cc_c;
    _enable                     : proc(cap: i32)                                                                                #cc_c;
    _depth_func                 : proc(func: i32)                                                                               #cc_c;
    _get_string                 : proc(name : i32) -> ^byte                                                                     #cc_c;
    _tex_image2d                : proc(target, level, internal_format, width, height, border, format, _type: i32, data: rawptr) #cc_c;
    _tex_parameteri             : proc(target, pname, param: i32)                                                               #cc_c;
    _bind_texture               : proc(target: i32, texture: u32)                                                               #cc_c;
    _gen_textures               : proc(count: i32, result: ^u32)                                                                #cc_c;
    _blend_func                 : proc(sfactor : i32, dfactor: i32)                                                             #cc_c;
    _get_integerv               : proc(name: i32, v: ^i32)                                                                      #cc_c;
    _disable                    : proc(cap: i32)                                                                                #cc_c;
    _clear                      : proc(mask: i32)                                                                               #cc_c;
    
    viewport                    : proc(x : i32, y : i32, width : i32, height : i32)                                             #cc_c;
    clear_color                 : proc(red : f32, blue : f32, green : f32, alpha : f32)                                         #cc_c;
    scissor                     : proc(x : i32, y : i32, width : i32, height : i32)                                             #cc_c;

    // Here because we're trying to get out the max version number before we have finished creating our context. Which we need to load out of the DLL apperently.
foreign lib {    
    _GetIntegervStatic   :: proc(name: i32, v: ^i32);
}
init :: proc() {
    libString := "opengl32.dll\x00";
    lib := win32.load_library_a(&libString[0]); defer win32.free_library(lib);
    debug_info.lib_address = int(lib);
    set_proc_address :: proc(h : win32.Hmodule, p: rawptr, name: string, info : ^TypeInfo) #inline {
        txt := strings.new_c_string(name); defer free(txt);

        res := win32_wgl.get_proc_address(txt);
        if res == nil {
            res = win32.get_proc_address(h, txt);
        }   

        ^(proc() #cc_c)(p)^ = res;

        status := DebugFunctionLoadStatus{};
        status.name = name;
        status.address = int(rawptr(res));
        status.success = false;
        status.type_info = info;
        debug_info.number_of_functions_loaded += 1;

        if status.address != 0 {
            status.success = true;
            debug_info.number_of_functions_loaded_successed += 1;
        }
        append(debug_info.statuses, status);
    }

    set_proc_address(lib, &_draw_elements,              "glDrawElements"            );
    set_proc_address(lib, &_draw_arrays,                "glDrawArrays"              );
    set_proc_address(lib, &_bind_vertex_array,          "glBindVertexArray"         );
    set_proc_address(lib, &_vertex_attrib_pointer,      "glVertexAttribPointer"     );
    set_proc_address(lib, &_enable_vertex_attrib_array, "glEnableVertexAttribArray" );
    set_proc_address(lib, &_gen_vertex_arrays,          "glGenVertexArrays"         );
    set_proc_address(lib, &_buffer_data,                "glBufferData"              );
    set_proc_address(lib, &_bind_buffer,                "glBindBuffer"              );
    set_proc_address(lib, &_gen_buffers,                "glGenBuffers"              );
    set_proc_address(lib, &_debug_message_control,      "glDebugMessageControlARB"  );
    set_proc_address(lib, &_debug_message_callback,     "glDebugMessageCallbackARB" );
    set_proc_address(lib, &_get_shaderiv,               "glGetShaderiv"             );
    set_proc_address(lib, &_get_shader_info_log,        "glGetShaderInfoLog"        );
    set_proc_address(lib, &_get_stringi,                "glGetStringi"              );
    set_proc_address(lib, &_blend_equation,             "glBlendEquation"           );
    set_proc_address(lib, &_blend_equation_separate,    "glBlendEquationSeparate"   );
    set_proc_address(lib, &_compile_shader,             "glCompileShader"           );
    set_proc_address(lib, &_create_shader,              "glCreateShader"            );
    set_proc_address(lib, &_shader_source,              "glShaderSource"            );
    set_proc_address(lib, &_attach_shader,              "glAttachShader"            ); 
    set_proc_address(lib, &_create_program,             "glCreateProgram"           );
    set_proc_address(lib, &_link_program,               "glLinkProgram"             );
    set_proc_address(lib, &_use_program,                "glUseProgram"              );
    set_proc_address(lib, &_active_texture,             "glActiveTexture"           );
    set_proc_address(lib, &_uniform1i,                  "glUniform1i"               );
    set_proc_address(lib, &_uniform2i,                  "glUniform2i"               );
    set_proc_address(lib, &_uniform3i,                  "glUniform3i"               );
    set_proc_address(lib, &_uniform4i,                  "glUniform4i"               );
    set_proc_address(lib, &_uniform1f,                  "glUniform1f"               );
    set_proc_address(lib, &_uniform2f,                  "glUniform2f"               );
    set_proc_address(lib, &_uniform3f,                  "glUniform3f"               );
    set_proc_address(lib, &_uniform4f,                  "glUniform4f"               );
    set_proc_address(lib, &_uniform_matrix4fv,          "glUniformMatrix4fv"        );
    set_proc_address(lib, &_get_uniform_location,       "glGetUniformLocation"      );
    set_proc_address(lib, &_get_attrib_location,        "glGetAttribLocation"       );
    set_proc_address(lib, &_polygon_mode,               "glPolygonMode"             );
    set_proc_address(lib, &_generate_mipmap,            "glGenerateMipmap"          );
    set_proc_address(lib, &_enable,                     "glEnable"                  );
    set_proc_address(lib, &_depth_func,                 "glDepthFunc"               );
    set_proc_address(lib, &_bind_frag_data_location,    "glBindFragDataLocation"    );
    set_proc_address(lib, &_get_string,                 "glGetString"               );
    set_proc_address(lib, &_tex_image2d,                "glTexImage2D"              );
    set_proc_address(lib, &_tex_parameteri,             "glTexParameteri"           );
    set_proc_address(lib, &_bind_texture,               "glBindTexture"             );
    set_proc_address(lib, &_gen_textures,               "glGenTextures"             );
    set_proc_address(lib, &_blend_func,                 "glBlendFunc"               );
    set_proc_address(lib, &_get_integerv,               "glGetIntegerv"             );
    set_proc_address(lib, &_disable,                    "glDisable"                 );
    set_proc_address(lib, &_clear,                      "glClear"                   );
    set_proc_address(lib, &viewport,                    "glViewport"                );
    set_proc_address(lib, &clear_color,                 "glClearColor"              );
    set_proc_address(lib, &scissor,                     "glScissor"                 );
}