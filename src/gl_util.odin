/*
 *  @Name:     gl_util
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 21-04-2017 03:04:34
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 02-11-2017 23:45:48
 *  
 *  @Description:
 *      Contains random GL utility functions.
 */

import "core:fmt.odin";
import "core:strings.odin";
import "mantle:libbrew/gl.odin";
import "console.odin";
import ja "asset.odin";

create_and_compile_shader :: proc(shader : ^ja.Shader) -> bool {
    shader.gl_id = gl.create_shader(shader.type_);
    gl.shader_source(shader.gl_id, shader.source);
    gl.compile_shader(shader.gl_id);

    success := gl.get_shader_value(shader.gl_id, gl.GetShaderNames.CompileStatus);
    if success == 0 {
        console.log_error("------ Shader Error(%s|%v) ---", shader.info.file_name, shader.type_);
        console.log_error(gl.get_shader_info_log(shader.gl_id)); 
        console.log_error("--------------------------");
        gl.delete_shader(shader.gl_id);
        return false;
    }

    return true;
}

create_program :: proc(vertex, frag : ^ja.Shader) -> gl.Program {
    result := gl.create_program();
    gl.attach_shader(result, vertex.gl_id);
    gl.attach_shader(result, frag.gl_id);

    result.Vertex = vertex.gl_id;
    result.Fragment = frag.gl_id;

    gl.link_program(result);
    return result;
}