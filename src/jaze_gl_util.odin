#import "fmt.odin";
#import "strings.odin";
#import gl "jaze_gl.odin";

CreateAndCompileShader :: proc(type : gl.ShaderTypes, source : string) -> (gl.Shader, bool) {
    shader : gl.Shader;
    shader = gl.CreateShader(type);
    gl.ShaderSource(shader, source);
    gl.CompileShader(shader);

    success := gl.GetShaderValue(shader, gl.GetShaderNames.CompileStatus);
    if success == 0 {
        logSize := gl.GetShaderValue(shader, gl.GetShaderNames.InfoLogLength);
        logBytes := make([]byte, logSize);
        gl._GetShaderInfoLog(cast(u32)shader, logSize, ^logSize, ^logBytes[0]);

        fmt.println("------ Shader Error ------");
        fmt.print(strings.to_odin_string(^logBytes[0])); 
        fmt.println("--------------------------");
        //DeleteShader(shader.ID);
        return shader, false;
    }

    return shader, true;
}
