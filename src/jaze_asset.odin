#import gl "jaze_gl.odin";

FileInfo_t :: struct {
    Name : string,
    Ext  : string,
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
        //Program : ^ShaderProgram, //Gets Undeclared name... Tell bill xD maybe it makes sense
    },
    Sound {
        //????
    },
    ShaderProgram {
        GLID : gl.Program,
        Vertex : ^Shader,
        Fragment : ^Shader,
        Uniforms : map[string]i32,
        Attributes : map[string]i32,
    }
}

MetaTag :: enum {
    Unknown,
    ShaderProgram,
}

ParseMetaTag :: proc(metastr : string) -> MetaTag {
    return MetaTag.Unknown;
}

ParseShaderProgram :: proc() -> Asset.ShaderProgram {
    return Asset.ShaderProgram{};
}