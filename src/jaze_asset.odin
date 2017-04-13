#import gl "jaze_gl.odin";

FileInfo_t :: struct {
    Name : string,
    Path : string,
}

Asset :: union {
    FileInfo : FileInfo_t,

    LoadedFromDisk : bool,
    Texture {
        GLID : gl.Texture,
        Width : i32,
        Height : i32,
        Comp : i32,
    },
    Shader {
        GLShader : gl.Shader,
        Type : gl.ShaderTypes,
        Source : string,
    },
    Sound {
        //????
    }
}