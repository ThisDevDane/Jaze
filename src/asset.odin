/*
 *  @Name:     asset
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 21-04-2017 03:04:34
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 24-09-2017 23:12:30
 *  
 *  @Description:
 *      Contains the asset construct and associated data.
 */
import gl "libbrew/win/opengl.odin";

FileInfo :: struct {
    name : string,
    ext  : string,
    path : string,
    size : u64,
}

Asset :: struct {
    file_info : FileInfo,
    loaded_from_disk : bool,

    derived : union {Texture, Shader, Sound, ShaderProgram},
}

Texture :: struct {
    gl_id : gl.Texture,
    width : int,
    height : int,
    comp : int,
    data : ^byte,
}

Shader :: struct {
    gl_id : gl.Shader,
    type_ : gl.ShaderTypes,
    source : string,
    data : []byte,
    //Program : ^ShaderProgram, //Gets Undeclared name... Tell bill xD maybe it makes sense
}

Sound :: struct {
    //????
}

ShaderProgram :: struct {
    gl_id : gl.Program,
    vertex : ^Shader,
    fragment : ^Shader,
    uniforms : map[string]i32,
    attributes : map[string]i32,
}