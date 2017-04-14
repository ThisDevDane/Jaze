#import gl "jaze_gl.odin";

FileInfo_t :: struct {
    Name : string,
    Path : string,
    Size : u64,
}

Asset :: union {
    FileInfo : FileInfo_t,
    LoadedFromDisk : bool,

    Texture {
        GLID : gl.Texture,
        Width : i32,
        Height : i32,
        Comp : i32,
        Data : ^byte,
    },
    Shader {
        GLID : gl.Shader,
        Type : gl.ShaderTypes,
        Source : string,
        Data : []byte,
    },
    Sound {
        //????
    },
    Program {
        GLID : gl.Program,
        Vertex : ^Shader,
        Fragment : ^Shader,
        Uniforms : map[string]i32,
        Attributes : map[string]i32,
    }
}

MetaTag :: enum {
    Program,
}

ParseMetaTag :: proc() {

}

ParseMetaProgram :: proc() {
    
}