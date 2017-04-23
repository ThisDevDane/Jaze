#import "fmt.odin";
#import "strings.odin";
#import "gl.odin";
#import "console.odin";
#import ja "asset.odin";

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

        console.Log("------ Shader Error(%s) ---", type);
        console.Log(strings.to_odin_string(^logBytes[0])); 
        console.Log("--------------------------");
        //DeleteShader(shader.ID);
        return shader, false;
    }

    return shader, true;
}


CreateProgram :: proc(vertex, frag : ja.Asset.Shader) -> gl.Program {
    result := gl.CreateProgram();
    gl.AttachShader(result, vertex.GLID);
    gl.AttachShader(result, frag.GLID);

    result.Vertex = vertex.GLID;
    result.Fragment = frag.GLID;

    gl.LinkProgram(result);
    return result;
}