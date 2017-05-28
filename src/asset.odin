/*
 *  @Name:     asset
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 21-04-2017 03:04:34
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 28-05-2017 16:07:34
 *  
 *  @Description:
 *      Contains the asset construct and associated data.
 */
#import "gl.odin";

FileInfo :: struct {
    name : string,
    ext  : string,
    path : string,
    size : u64,
}

Asset :: union {
    file_info : FileInfo,
    loaded_from_disk : bool,

    Texture {
        gl_id : gl.Texture,
        width : int,
        height : int,
        comp : int,
        data : ^byte,
    },
    Shader {
        gl_id : gl.Shader,
        type : gl.ShaderTypes,
        source : string,
        data : []byte,
        //Program : ^ShaderProgram, //Gets Undeclared name... Tell bill xD maybe it makes sense
    },
    Sound {
        //????
    },
    ShaderProgram {
        gl_id : gl.Program,
        vertex : ^Shader,
        fragment : ^Shader,
        uniforms : map[string]i32,
        attributes : map[string]i32,
    }
}