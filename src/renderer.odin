/*
 *  @Name:     renderer
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 13-05-2017 23:48:58
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 28-05-2017 17:01:11
 *  
 *  @Description:
 *      Functions and data related to the renderer. 
 */
#import "math.odin";

#import "render_queue.odin";
#import "gl.odin";
#import "engine.odin";
#import "catalog.odin";
#import "console.odin";
#import glUtil "gl_util.odin";
#import ja "asset.odin";

PixelsToUnits :: 64;

Command :: union {
    RenderPos : math.Vec3,
    Rotation  : f32, 
    Scale     : math.Vec3,
    
    Bitmap{
        Texture : ^ja.Asset.Texture,
    },
    Rect{
        Color : math.Vec4,
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

DrawRegion :: struct {
    X : i32,
    Y : i32,
    Width : i32,
    Height : i32,
}

VirtualScreen_t :: struct {
    Dimension : math.Vec2,
    AspectRatio : f32,
}

CreateVirtualScreen :: proc(w, h : int) -> ^VirtualScreen_t {
    screen := new(VirtualScreen_t);
    screen.Dimension.x = 1280;
    screen.Dimension.y = 720;
    screen.AspectRatio = screen.Dimension.x / screen.Dimension.y;

    return screen;
}

Init :: proc(shaderCat : ^catalog.Catalog) -> ^State_t {
    state := new(State_t); 

    vertexAsset, ok1 := catalog.find(shaderCat, "test_vert");
    fragAsset, ok2 := catalog.find(shaderCat, "test_frag");

    if ok1 != catalog.ERR_SUCCESS || ok2 != catalog.ERR_SUCCESS {
        panic("Couldn't find the Bitmap shaders");
    }

    vertex := vertexAsset.(^ja.Asset.Shader);
    frag :=   fragAsset.(^ja.Asset.Shader);
    state.BitmapProgram = glUtil.create_program(vertex^, frag^);

    vertexAsset, ok1 = catalog.find(shaderCat, "basic_vert");
    fragAsset, ok2 = catalog.find(shaderCat, "basic_frag");

    if ok1 != catalog.ERR_SUCCESS || ok2 != catalog.ERR_SUCCESS {
        panic("Couldn't find the Solid shaders");
    }

    vertex = vertexAsset.(^ja.Asset.Shader);
    frag   = fragAsset.(^ja.Asset.Shader);
    state.SolidProgram = glUtil.create_program(vertex^, frag^);


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

    state.SolidProgram.Uniforms["Model"] = gl.GetUniformLocation(state.SolidProgram, "Model");
    state.SolidProgram.Uniforms["View"]  = gl.GetUniformLocation(state.SolidProgram, "View");
    state.SolidProgram.Uniforms["Proj"]  = gl.GetUniformLocation(state.SolidProgram, "Proj");

    state.SolidProgram.Uniforms["Color"]  = gl.GetUniformLocation(state.SolidProgram, "Color");

    state.SolidProgram.Attributes["VertPos"] = gl.GetAttribLocation(state.SolidProgram, "VertPos");
    gl.VertexAttribPointer(u32(state.BitmapProgram.Attributes["VertPos"]),  3, gl.VertexAttribDataType.Float, false, 5 * size_of(f32), nil);
    gl.VertexAttribPointer(u32(state.BitmapProgram.Attributes["UV"]),       2, gl.VertexAttribDataType.Float, false, 5 * size_of(f32), rawptr(int(3 * size_of(f32))));
    gl.EnableVertexAttribArray(u32(state.SolidProgram.Attributes["VertPos"]));


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

ScreenToWorld :: proc(screenPos : math.Vec2, proj, view : math.Mat4, area : DrawRegion, cam : ^Camera_t) -> math.Vec3 {
    MapToRange :: proc(t : f32, min : f32, max : f32) -> f32 {
        return (t - min) / (max - min);
    }
    u := MapToRange(screenPos.x, f32(area.X), f32(area.X + area.Width));
    v := MapToRange(screenPos.y, f32(area.Y), f32(area.Y + area.Height));
    p := math.Vec4{u * 2 - 1,
                   v * 2 - 1,
                   -1, 1};

    p = math.mul(math.inverse(proj), p);
    p = math.Vec4{p.x, p.y, -1, 0};
    world := math.mul(math.inverse(view), p);
    return math.Vec3{world.x + cam.Pos.x, -world.y + cam.Pos.y, 0}; 
}

/*    TestRender(mainProgram, 
               ScreenToWorld(ctx.Input.MousePos, proj, view, ctx.GameDrawRegion, Camera), 
               f32(ctx.Time.TimeSinceStart * 200.0),
               math.Vec3{0.4, 0.4, 0.4});*/

RenderQueue :: proc(ctx : ^engine.Context, camera : ^Camera_t, queue : ^render_queue.Queue) {
    gl.Enable(gl.Capabilities.DepthTest);
    gl.Enable(gl.Capabilities.Blend);
    gl.DepthFunc(gl.DepthFuncs.Lequal);
    gl.BlendFunc(gl.BlendFactors.SrcAlpha, gl.BlendFactors.OneMinusSrcAlpha);  
    view := CreateViewMatrixFromCamera(camera);
    proj := CalculateOrtho(ctx.window_size, ctx.scale_factor, camera.Far, camera.Near);

    CreateModelMat :: proc(pos, texSize, scale : math.Vec3, rotation_ : f32) -> math.Mat4 {
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

    gl.BindVertexArray(ctx.render_state.VAO);    

    for !render_queue.IsEmpty(queue) {
        rcmd, _ := render_queue.Dequeue(queue);

        match cmd in rcmd {
            case Command.Bitmap : {
                height := f32(cmd.Texture.height) / PixelsToUnits;
                width := f32(cmd.Texture.width) / PixelsToUnits;
                texSize := math.Vec3{width, height, 1};

                if lastProgram != int(ctx.render_state.BitmapProgram.ID) {
                    gl.UseProgram(ctx.render_state.BitmapProgram);
                    lastProgram = int(ctx.render_state.BitmapProgram.ID);
                }
                if !vpu {
                    gl.UniformMatrix4fv(ctx.render_state.BitmapProgram.Uniforms["View"],  view,  false);
                    gl.UniformMatrix4fv(ctx.render_state.BitmapProgram.Uniforms["Proj"],  proj,  false);
                    vpu = true;
                }

                gl.UniformMatrix4fv(ctx.render_state.BitmapProgram.Uniforms["Model"], CreateModelMat(cmd.RenderPos, texSize, cmd.Scale, cmd.Rotation), false);

                if lastTex != int(cmd.Texture.gl_id) {
                    gl.BindTexture(gl.TextureTargets.Texture2D, cmd.Texture.gl_id);
                    lastTex = int(cmd.Texture.gl_id);
                }
                gl.DrawElements(gl.DrawModes.Triangles, 6, gl.DrawElementsType.UInt, nil);
            }

            case Command.Rect : {

                if lastProgram != int(ctx.render_state.SolidProgram.ID) {
                    gl.UseProgram(ctx.render_state.SolidProgram);
                    lastProgram = int(ctx.render_state.SolidProgram.ID);
                }
                if !vpu {
                    gl.UniformMatrix4fv(ctx.render_state.SolidProgram.Uniforms["View"],  view,  false);
                    gl.UniformMatrix4fv(ctx.render_state.SolidProgram.Uniforms["Proj"],  proj,  false);
                    vpu = true;
                }
                gl.UniformMatrix4fv(ctx.render_state.SolidProgram.Uniforms["Model"], CreateModelMat(cmd.RenderPos, math.Vec3{1,1,1}, cmd.Scale, cmd.Rotation), false);

                gl.Uniform(ctx.render_state.SolidProgram.Uniforms["Color"], cmd.Color);

                gl.DrawElements(gl.DrawModes.Triangles, 6, gl.DrawElementsType.UInt, nil);
            }
        }
    }
}