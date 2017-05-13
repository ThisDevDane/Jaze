#import "math.odin";

#import "render_queue.odin";
#import "gl.odin";
#import "engine.odin";
#import "catalog.odin";
#import glUtil "gl_util.odin";
#import ja "asset.odin";

PixelsToUnits :: 64;

Command :: union {
    RenderPos : math.Vec3,
    Rotation : f32, 
    Scale : math.Vec3,
    
    Bitmap{
        Texture : ^ja.Asset.Texture,
    },
    Rect{
    },
    Circle{
        Diameter : f32,
    },
}

State_t :: struct {
    BitmapProgram : gl.Program,
    SolidProgram : gl.Program,
    VAO : gl.VAO,
    VBO : gl.VBO,
    EBO : gl.EBO,
}

Camera_t :: struct {
    Pos  : math.Vec3,
    Rot  : f32,
    Zoom : f32,
    Near : f32,
    Far  : f32,
}

Init :: proc(shaderCat : ^catalog.Catalog) -> ^State_t {
    state := new(State_t); 

    vertexAsset, ok1 := catalog.Find(shaderCat, "test_vert");
    fragAsset, ok2 := catalog.Find(shaderCat, "test_frag");

    if ok1 != catalog.ERR_SUCCESS || ok2 != catalog.ERR_SUCCESS {
        panic("Couldn't find the Bitmap shaders");
    }

    vertex := vertexAsset.(^ja.Asset.Shader);
    frag :=   fragAsset.(^ja.Asset.Shader);
    state.BitmapProgram = glUtil.CreateProgram(vertex^, frag^);

    gl.UseProgram(state.BitmapProgram);

    state.VAO = gl.GenVertexArray();
    gl.BindVertexArray(state.VAO);
    state.VBO = gl.GenVBO();
    gl.BindBuffer(state.VBO);
    state.EBO = gl.GenEBO();
    gl.BindBuffer(state.EBO);

    vertices := [..]f32 {
         1, 1, 0,  1.0, 0.0, // Top Right
         1, 0, 0,  1.0, 1.0, // Bottom Right
         0, 0, 0,  0.0, 1.0, // Bottom Left
         0, 1, 0,  0.0, 0.0, // Top Left
    };

    elements := [..]u32 {
        0, 1, 3,
        1, 2, 3,
    };

    gl.BufferData(gl.BufferTargets.Array, size_of_val(vertices), &vertices[0], gl.BufferDataUsage.StaticDraw);
    gl.BufferData(gl.BufferTargets.ElementArray, size_of_val(elements), &elements[0], gl.BufferDataUsage.StaticDraw);


    state.BitmapProgram.Uniforms["Model"] = gl.GetUniformLocation(state.BitmapProgram, "Model");
    state.BitmapProgram.Uniforms["View"]  = gl.GetUniformLocation(state.BitmapProgram, "View");
    state.BitmapProgram.Uniforms["Proj"]  = gl.GetUniformLocation(state.BitmapProgram, "Proj");

    state.BitmapProgram.Attributes["Position"] = gl.GetAttribLocation(state.BitmapProgram, "Position");
    state.BitmapProgram.Attributes["UV"] = gl.GetAttribLocation(state.BitmapProgram, "UV");
    gl.VertexAttribPointer(u32(state.BitmapProgram.Attributes["Position"]), 3, gl.VertexAttribDataType.Float, false, 5 * size_of(f32), nil);
    gl.VertexAttribPointer(u32(state.BitmapProgram.Attributes["UV"]),       2, gl.VertexAttribDataType.Float, false, 5 * size_of(f32), rawptr(int(3 * size_of(f32))));
    gl.EnableVertexAttribArray(u32(state.BitmapProgram.Attributes["Position"]));
    gl.EnableVertexAttribArray(u32(state.BitmapProgram.Attributes["UV"]));
    gl.BindFragDataLocation(state.BitmapProgram, 0, "OutColor");

    return state;
}

CalculateOrtho :: proc(window : math.Vec2, scaleFactor : math.Vec2, far, near : f32) -> math.Mat4 {
    w := (window.x);
    h := (window.y);
    l := -(w/ 2);
    r := w / 2;
    b := h / 2;
    t := -(h / 2);
    proj  := math.ortho3d(l, r, t, b, far, near);
    return math.scale(proj, math.Vec3{scaleFactor.x, scaleFactor.y, 1.0});
}

CreateViewMatrixFromCamera :: proc(immutable camera : ^Camera_t) -> math.Mat4 {
    view := math.scale(math.mat4_identity(), math.Vec3{camera.Zoom, camera.Zoom, 1});
    //rot := math.mat4_rotate(math.Vec3{0, 0, 1}, math.to_radians(camera.Rot));
    //view = math.mul(view, rot);
    tr := math.mat4_translate(-camera.Pos);
    return math.mul(view, tr);
}

RenderQueue :: proc(ctx : ^engine.Context_t, camera : ^Camera_t, queue : ^render_queue.Queue) {
    gl.Enable(gl.Capabilities.DepthTest);
    gl.Enable(gl.Capabilities.Blend);
    gl.DepthFunc(gl.DepthFuncs.Lequal);
    gl.BlendFunc(gl.BlendFactors.SrcAlpha, gl.BlendFactors.OneMinusSrcAlpha);  
    view := CreateViewMatrixFromCamera(camera);
    proj := CalculateOrtho(ctx.WindowSize, ctx.ScaleFactor, camera.Far, camera.Near);
    
    for !render_queue.IsEmpty(queue) {
        rcmd, _ := render_queue.Dequeue(queue);

        match cmd in rcmd {
            case Command.Bitmap : {
                height := f32(cmd.Texture.Height) / PixelsToUnits;
                width := f32(cmd.Texture.Width) / PixelsToUnits;

                gl.UseProgram(ctx.RenderState.BitmapProgram);
                gl.BindVertexArray(ctx.RenderState.VAO);

                gl.UniformMatrix4fv(ctx.RenderState.BitmapProgram.Uniforms["View"],  view,  false);
                gl.UniformMatrix4fv(ctx.RenderState.BitmapProgram.Uniforms["Proj"],  proj,  false);

                textureScale := math.scale(math.mat4_identity(), math.Vec3{width, height, 1});
                cmdScale := math.scale(math.mat4_identity(), cmd.Scale);
                matScale := math.mul(textureScale, cmdScale);
                rotation := math.mat4_rotate(math.Vec3{0, 0, 1}, math.to_radians(cmd.Rotation));
                model := math.mul(matScale, rotation);
                offset := math.mat4_translate(math.Vec3{-0.5, -0.5, 0});
                model = math.mul(model, offset);
                translation := math.mat4_translate(cmd.RenderPos);
                model = math.mul(translation, model);

                gl.UniformMatrix4fv(ctx.RenderState.BitmapProgram.Uniforms["Model"], model, false);

                gl.BindTexture(gl.TextureTargets.Texture2D, cmd.Texture.GLID);
                gl.DrawElements(gl.DrawModes.Triangles, 6, gl.DrawElementsType.UInt, nil);
            }
        }
    }
}