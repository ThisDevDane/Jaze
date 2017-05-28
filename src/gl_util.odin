/*
 *  @Name:     gl_util
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 21-04-2017 03:04:34
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 28-05-2017 17:00:51
 *  
 *  @Description:
 *      Contains random GL utility functions.
 */
#import "fmt.odin";
#import "strings.odin";
#import "gl.odin";
#import "console.odin";
#import ja "asset.odin";

create_and_compile_shader :: proc(type : gl.ShaderTypes, source : string) -> (gl.Shader, bool) {
    shader : gl.Shader;
    shader = gl.CreateShader(type);
    gl.ShaderSource(shader, source);
    gl.CompileShader(shader);

    success := gl.GetShaderValue(shader, gl.GetShaderNames.CompileStatus);
    if success == 0 {
        logSize := gl.GetShaderValue(shader, gl.GetShaderNames.InfoLogLength);
        logBytes := make([]byte, logSize);
        gl._GetShaderInfoLog(u32(shader), logSize, &logSize, &logBytes[0]);

        console.log("------ Shader Error(%s) ---", type);
        console.log(strings.to_odin_string(&logBytes[0])); 
        console.log("--------------------------");
        //DeleteShader(shader.ID);
        return shader, false;
    }

    return shader, true;
}


create_program :: proc(vertex, frag : ja.Asset.Shader) -> gl.Program {
    result := gl.CreateProgram();
    gl.AttachShader(result, vertex.gl_id);
    gl.AttachShader(result, frag.gl_id);

    result.Vertex = vertex.gl_id;
    result.Fragment = frag.gl_id;

    gl.LinkProgram(result);
    return result;
}