/*
 *  @Name:     renderer
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 13-05-2017 23:48:58
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 24-09-2017 23:08:32
 *  
 *  @Description:
 *      Functions and data related to the renderer. 
 */
import "core:math.odin";

//import rq"render_queue.odin";
import gl "libbrew/win/opengl.odin";
import "engine.odin";
import "catalog.odin";
import "console.odin";
//import glUtil "gl_util.odin";
import ja "asset.odin";

PixelsToUnits :: 64;

Command :: struct {
    render_pos : math.Vec3,
    rotation  : f32, 
    scale     : math.Vec3,
    
    derived : union { BitmapCmd, RectCmd, CircleCmd},
}
BitmapCmd :: struct {
    texture : ^ja.Asset.Texture,
}

RectCmd :: struct {
    color : math.Vec4,
}

CircleCmd :: struct {
    diameter : f32,
}

State_t :: struct {
    bitmap_program : gl.Program,
    solid_program : gl.Program,
    vao : gl.VAO,
    vbo : gl.VBO,
    ebo : gl.EBO,
}

Camera_t :: struct {
    pos  : math.Vec3,
    rot  : f32,
    zoom : f32,
    near : f32,
    far  : f32,
}

DrawRegion :: struct {
    x : i32,
    y : i32,
    width : i32,
    height : i32,
}

VirtualScreen :: struct {
    dimension : math.Vec2,
    aspect_ratio : f32,
}

create_virtual_screen :: proc(w, h : int) -> ^VirtualScreen {
    screen := new(VirtualScreen);
    screen.dimension.x = 1280;
    screen.dimension.y = 720;
    screen.aspect_ratio = screen.dimension.x / screen.dimension.y;

    return screen;
}

init :: proc(shaderCat : ^catalog.Catalog) -> ^State_t {
    state := new(State_t); 

    vertexAsset, ok1 := catalog.find(shaderCat, "test_vert");
    fragAsset, ok2 := catalog.find(shaderCat, "test_frag");

    if ok1 != catalog.ERR_SUCCESS || ok2 != catalog.ERR_SUCCESS {
        panic("Couldn't find the Bitmap shaders");
    }

    vertex := vertexAsset.(^ja.Asset.Shader);
    frag :=   fragAsset.(^ja.Asset.Shader);
    state.bitmap_program = glUtil.create_program(vertex^, frag^);

    vertexAsset, ok1 = catalog.find(shaderCat, "basic_vert");
    fragAsset, ok2 = catalog.find(shaderCat, "basic_frag");

    if ok1 != catalog.ERR_SUCCESS || ok2 != catalog.ERR_SUCCESS {
        panic("Couldn't find the Solid shaders");
    }

    vertex = vertexAsset.(^ja.Asset.Shader);
    frag   = fragAsset.(^ja.Asset.Shader);
    state.solid_program = glUtil.create_program(vertex^, frag^);


    state.vao = gl.gen_vertex_array();
    gl.bind_vertex_array(state.vao);
    state.vbo = gl.gen_vbo();
    gl.bind_buffer(state.vbo);
    state.ebo = gl.gen_ebo();
    gl.bind_buffer(state.ebo);

    vertices := []f32 {
         1, 1, 0,  1.0, 0.0, // Top Right
         1, 0, 0,  1.0, 1.0, // Bottom Right
         0, 0, 0,  0.0, 1.0, // Bottom Left
         0, 1, 0,  0.0, 0.0, // Top Left
    };

    elements := []u32 {
        0, 1, 3,
        1, 2, 3,
    };

    gl.buffer_data(gl.BufferTargets.Array, size_of_val(vertices), &vertices[0], gl.BufferDataUsage.StaticDraw);
    gl.buffer_data(gl.BufferTargets.ElementArray, size_of_val(elements), &elements[0], gl.BufferDataUsage.StaticDraw);


    state.bitmap_program.Uniforms["Model"] = gl.get_uniform_location(state.bitmap_program, "Model");
    state.bitmap_program.Uniforms["View"]  = gl.get_uniform_location(state.bitmap_program, "View");
    state.bitmap_program.Uniforms["Proj"]  = gl.get_uniform_location(state.bitmap_program, "Proj");

    state.bitmap_program.Attributes["Position"] = gl.get_attrib_location(state.bitmap_program, "Position");
    state.bitmap_program.Attributes["UV"] = gl.get_attrib_location(state.bitmap_program, "UV");
    gl.vertex_attrib_pointer(u32(state.bitmap_program.Attributes["Position"]), 3, gl.VertexAttribDataType.Float, false, 5 * size_of(f32), nil);
    gl.vertex_attrib_pointer(u32(state.bitmap_program.Attributes["UV"]),       2, gl.VertexAttribDataType.Float, false, 5 * size_of(f32), rawptr(int(3 * size_of(f32))));
    gl.enable_vertex_attrib_array(u32(state.bitmap_program.Attributes["Position"]));
    gl.enable_vertex_attrib_array(u32(state.bitmap_program.Attributes["UV"]));

    state.solid_program.Uniforms["Model"] = gl.get_uniform_location(state.solid_program, "Model");
    state.solid_program.Uniforms["View"]  = gl.get_uniform_location(state.solid_program, "View");
    state.solid_program.Uniforms["Proj"]  = gl.get_uniform_location(state.solid_program, "Proj");

    state.solid_program.Uniforms["Color"]  = gl.get_uniform_location(state.solid_program, "Color");

    state.solid_program.Attributes["VertPos"] = gl.get_attrib_location(state.solid_program, "VertPos");
    gl.vertex_attrib_pointer(u32(state.bitmap_program.Attributes["VertPos"]),  3, gl.VertexAttribDataType.Float, false, 5 * size_of(f32), nil);
    gl.vertex_attrib_pointer(u32(state.bitmap_program.Attributes["UV"]),       2, gl.VertexAttribDataType.Float, false, 5 * size_of(f32), rawptr(int(3 * size_of(f32))));
    gl.enable_vertex_attrib_array(u32(state.solid_program.Attributes["VertPos"]));


    return state;
}

calculate_ortho :: proc(window : math.Vec2, scaleFactor : math.Vec2, far, near : f32) -> math.Mat4 {
    w := (window.x);
    h := (window.y);
    l := -(w/ 2);
    r := w / 2;
    b := h / 2;
    t := -(h / 2);
    proj  := math.ortho3d(l, r, t, b, far, near);
    return math.scale(proj, math.Vec3{scaleFactor.x, scaleFactor.y, 1.0});
}

create_view_matrix_from_camera :: proc(camera : ^Camera_t) -> math.Mat4 {
    view := math.scale(math.mat4_identity(), math.Vec3{camera.zoom, camera.zoom, 1});
    //rot := math.mat4_rotate(math.Vec3{0, 0, 1}, math.to_radians(camera.Rot));
    //view = math.mul(view, rot);
    tr := math.mat4_translate(-camera.pos);
    return math.mul(view, tr);
}

screen_to_world :: proc(screen_pos : math.Vec2, proj, view : math.Mat4, area : DrawRegion, cam : ^Camera_t) -> math.Vec3 {
    map_to_range :: proc(t : f32, min : f32, max : f32) -> f32 {
        return (t - min) / (max - min);
    }
    u := map_to_range(screen_pos.x, f32(area.x), f32(area.x + area.width));
    v := map_to_range(screen_pos.y, f32(area.y), f32(area.y + area.height));
    p := math.Vec4{u * 2 - 1,
                   v * 2 - 1,
                   -1, 1};

    p = math.mul(math.inverse(proj), p);
    p = math.Vec4{p.x, p.y, -1, 0};
    world := math.mul(math.inverse(view), p);
    return math.Vec3{world.x + cam.pos.x, -world.y + cam.pos.y, 0}; 
}

render_queue :: proc(ctx : ^engine.Context, camera : ^Camera_t, queue : ^rq.Queue) {
    gl.enable(gl.Capabilities.DepthTest);
    gl.enable(gl.Capabilities.Blend);
    gl.depth_func(gl.DepthFuncs.Lequal);
    gl.blend_func(gl.BlendFactors.SrcAlpha, gl.BlendFactors.OneMinusSrcAlpha);  
    view := create_view_matrix_from_camera(camera);
    proj := calculate_ortho(ctx.window_size, ctx.scale_factor, camera.far, camera.near);

    create_model_mat :: proc(pos, texSize, scale : math.Vec3, rotation_ : f32) -> math.Mat4 {
        textureScale := math.scale(math.mat4_identity(), texSize);
        cmdScale := math.scale(math.mat4_identity(), scale);
        matScale := math.mul(textureScale, cmdScale);

        rotation := math.mat4_rotate(math.Vec3{0, 0, 1}, math.to_radians(rotation_));
        model := math.mul(matScale, rotation);

        offset := math.mat4_translate(math.Vec3{-0.5, -0.5, 0});
        model = math.mul(model, offset);                

        translation := math.mat4_translate(pos);
        model = math.mul(translation, model);
        return model;
    }
    lastTex := 0;
    lastProgram := 0;
    vpu := false;

    gl.bind_vertex_array(ctx.render_state.vao);    

    for !rq.IsEmpty(queue) {
        rcmd, _ := rq.Dequeue(queue);

        match cmd in rcmd {
            case Command.Bitmap : {
                height := f32(cmd.texture.height) / PixelsToUnits;
                width := f32(cmd.texture.width) / PixelsToUnits;
                texSize := math.Vec3{width, height, 1};

                if lastProgram != int(ctx.render_state.bitmap_program.ID) {
                    gl.use_program(ctx.render_state.bitmap_program);
                    lastProgram = int(ctx.render_state.bitmap_program.ID);
                }
                if !vpu {
                    gl.uniform_matrix4fv(ctx.render_state.bitmap_program.Uniforms["View"],  view,  false);
                    gl.uniform_matrix4fv(ctx.render_state.bitmap_program.Uniforms["Proj"],  proj,  false);
                    vpu = true;
                }

                gl.uniform_matrix4fv(ctx.render_state.bitmap_program.Uniforms["Model"], create_model_mat(cmd.render_pos, texSize, cmd.scale, cmd.rotation), false);

                if lastTex != int(cmd.texture.gl_id) {
                    gl.bind_texture(gl.TextureTargets.Texture2D, cmd.texture.gl_id);
                    lastTex = int(cmd.texture.gl_id);
                }
                gl.draw_elements(gl.DrawModes.Triangles, 6, gl.DrawElementsType.UInt, nil);
            }

            case Command.Rect : {

                if lastProgram != int(ctx.render_state.solid_program.ID) {
                    gl.use_program(ctx.render_state.solid_program);
                    lastProgram = int(ctx.render_state.solid_program.ID);
                }
                if !vpu {
                    gl.uniform_matrix4fv(ctx.render_state.solid_program.Uniforms["View"],  view,  false);
                    gl.uniform_matrix4fv(ctx.render_state.solid_program.Uniforms["Proj"],  proj,  false);
                    vpu = true;
                }
                gl.uniform_matrix4fv(ctx.render_state.solid_program.Uniforms["Model"], create_model_mat(cmd.render_pos, math.Vec3{1,1,1}, cmd.scale, cmd.rotation), false);

                gl.uniform(ctx.render_state.solid_program.Uniforms["Color"], cmd.color);

                gl.draw_elements(gl.DrawModes.Triangles, 6, gl.DrawElementsType.UInt, nil);
            }
        }
    }
}