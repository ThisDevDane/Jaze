#import "fmt.odin";
#import "math.odin";
#import "os.odin";
#import "strings.odin";
#import "gl.odin";
#import glUtil "gl_util.odin";
#import "time.odin";
#import "main.odin";
#import "console.odin";
#import "catalog.odin";
#import ja "asset.odin";
#import rnd "pcg.odin";
#import "imgui.odin";
#import debugWnd "debug_windows.odin";
#import win32 "sys/windows.odin";

mainProgram : gl.Program; 
mainvao : gl.VAO;
textures : [dynamic]gl.Texture;
back : gl.Texture;

pos := [..]math.Vec3 {
    {0, 0, 0},
    {2, 1, 0}, 
};

Camera : Camera_t;
Camera_t :: struct {
    Pos  : math.Vec3,
    Rot  : f32,
    Zoom : f32,
    Near : f32,
    Far  : f32,
}

basicProgram : gl.Program;
basicvao : gl.VAO;

CameraWindow :: proc() {
     if debugWnd.GetWindowState("ShowCameraSettings") {
        b := debugWnd.GetWindowState("ShowCameraSettings");
        imgui.Begin("Camera Settings", &b, imgui.GuiWindowFlags.ShowBorders | imgui.GuiWindowFlags.NoCollapse);
        {
            imgui.DragFloat("Scale",  &Camera.Zoom,  0.05, 0, 0, "%.2f", 1);
            imgui.DragFloat("Near", &Camera.Near, 0.05, 0, 0, "%.2f", 1);
            imgui.DragFloat("Far",  &Camera.Far,  0.05, 0, 0, "%.2f", 1);
            imgui.DragFloat("//Rotation",  &Camera.Rot,  0.05, 0, 0, "%.2f", 1);
            imgui.Separator();
            pos : [3]f32;
            pos[0] = Camera.Pos.x;
            pos[1] = Camera.Pos.y;
            pos[2] = Camera.Pos.z;
            imgui.DragFloat3("Pos", &pos, 0.1, 0, 0, "%.2f", 1);
            Camera.Pos.x = pos[0];
            Camera.Pos.y = pos[1];
            Camera.Pos.z = pos[2];
        }
        imgui.End();
        debugWnd.SetWindowState("ShowCameraSettings", b);
    }
}

CalculateOrtho :: proc(window : math.Vec2, scaleFactor : math.Vec2, far, near : f32) -> math.Mat4 {
    w := (window.x);
    h := (window.y);
    l := -(w/ 2);
    r := w / 2;
    b := -(h / 2);
    t := h / 2;
    proj  := math.ortho3d(l, r, t, b, far, near);
    return math.scale(proj, math.Vec3{scaleFactor.x, scaleFactor.y, 1.0});
}

CreateViewMatrixFromCamera :: proc(camera : Camera_t) -> math.Mat4 {
    view := math.scale(math.mat4_identity(), math.Vec3{camera.Zoom, camera.Zoom, 1});
    //rot := math.mat4_rotate(math.Vec3{0, 0, 1}, math.to_radians(camera.Rot));
    //view = math.mul(view, rot);
    tr := math.mat4_translate(-camera.Pos);
    return math.mul(view, tr);
}

Draw :: proc(ctx : ^main.EngineContext_t) { 
    gl.Enable(gl.Capabilities.DepthTest);
    gl.Enable(gl.Capabilities.Blend);
    gl.DepthFunc(gl.DepthFuncs.Lequal);
    gl.BlendFunc(gl.BlendFactors.SrcAlpha, gl.BlendFactors.OneMinusSrcAlpha);  

    CameraWindow();
    
    gl.UseProgram(mainProgram);
    gl.BindVertexArray(mainvao);

    view := CreateViewMatrixFromCamera(Camera);
    proj := CalculateOrtho(ctx.WindowSize, ctx.ScaleFactor, Camera.Far, Camera.Near);

    gl.UniformMatrix4fv(mainProgram.Uniforms["View"],  view,  false);
    gl.UniformMatrix4fv(mainProgram.Uniforms["Proj"],  proj,  false);

    TestRender :: proc(program : gl.Program, pos : math.Vec3, angle : f32, scale : math.Vec3) {
        matScale := math.scale(math.mat4_identity(), scale);
        rotation := math.mat4_rotate(math.Vec3{0, 0, 1}, math.to_radians(angle));
        model := math.mul(matScale, rotation);
        offset := math.mat4_translate(math.Vec3{-0.5, -0.5, 0});
        model = math.mul(model, offset);
        translation := math.mat4_translate(pos);
        model = math.mul(translation, model);

        gl.UniformMatrix4fv(program.Uniforms["Model"], model, false);

        gl.DrawElements(gl.DrawModes.Triangles, 6, gl.DrawElementsType.UInt, nil);
    }
    
    for p, i in pos {
        gl.BindTexture(gl.TextureTargets.Texture2D, textures[i]);
        TestRender(mainProgram, p, 0, math.Vec3{1, 1, 1});
    }

    gl.UseProgram(basicProgram);
    gl.BindVertexArray(basicvao);
    gl.UniformMatrix4fv(basicProgram.Uniforms["View"],  view,  false);
    gl.UniformMatrix4fv(basicProgram.Uniforms["Proj"],  proj,  false);

    MapToRange :: proc(t : f32, min : f32, max : f32) -> f32 {
        return (t - min) / (max - min);
    }

    ScreenToWorld :: proc(screenPos : math.Vec2, proj, view : math.Mat4, area : main.DrawArea, cam : Camera_t) -> math.Vec3 {
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

    //gl.Uniform(basicProgram.Uniforms["Color"], cast(f32)1.0, 0.0, 0.0, 1.0);
    
    gl.Uniform(basicProgram.Uniforms["Color"], 0.0, 1.0, 0.0, 1.0);
    TestRender(basicProgram, math.Vec3{1, 0, 0}, f32(time.GetTimeSinceStart() * 20.0), math.Vec3{0.5, 0.5, 0.5});

    gl.UseProgram(mainProgram);
    gl.BindVertexArray(mainvao);
    gl.UniformMatrix4fv(mainProgram.Uniforms["View"],  view,  false);
    gl.UniformMatrix4fv(mainProgram.Uniforms["Proj"],  proj,  false);
    gl.BindTexture(gl.TextureTargets.Texture2D, textures[0]);
    TestRender(mainProgram, 
               ScreenToWorld(ctx.MousePos, proj, view, ctx.GameDrawArea, Camera), 
               f32(time.GetTimeSinceStart() * 100.0),
               math.Vec3{0.2, 0.2, 0.2});
}



Init :: proc(shaderCat : ^catalog.Catalog, textureCat : ^catalog.Catalog) {
    Camera.Pos = math.Vec3{0, 0, 15};
    Camera.Zoom = 100;
    Camera.Near = 0.1;
    Camera.Far = 50;
    Camera.Rot = 45;
    Test(shaderCat, textureCat);
    Test2(shaderCat);
}

Test2 :: proc(shaderCat : ^catalog.Catalog) {
    vertexAsset, ok1 := catalog.Find(shaderCat, "basic_vert");
    fragAsset, ok2 := catalog.Find(shaderCat, "basic_frag");
    vertex := vertexAsset.(^ja.Asset.Shader);
    frag := fragAsset.(^ja.Asset.Shader);

    basicProgram = glUtil.CreateProgram(vertex^, frag^);
    gl.UseProgram(basicProgram);

    basicvao = gl.GenVertexArray();
    gl.BindVertexArray(basicvao);
    vbo := gl.GenVBO();
    gl.BindBuffer(vbo);
    ebo := gl.GenEBO();
    gl.BindBuffer(ebo);

    //Pos
    vertices := [..]f32 {
         1, 1, 0, // Top Right
         1, 0, 0, // Bottom Right
         0, 0, 0, // Bottom Left
         0, 1, 0, // Top Left
    };

    elements := [..]u32 {
        0, 1, 3,
        1, 2, 3,
    };

    gl.BufferData(gl.BufferTargets.Array, size_of_val(vertices), &vertices[0], gl.BufferDataUsage.StaticDraw);
    gl.BufferData(gl.BufferTargets.ElementArray, size_of_val(elements), &elements[0], gl.BufferDataUsage.StaticDraw);

    basicProgram.Uniforms["Model"] = gl.GetUniformLocation(basicProgram, "Model");
    basicProgram.Uniforms["View"]  = gl.GetUniformLocation(basicProgram, "View");
    basicProgram.Uniforms["Proj"]  = gl.GetUniformLocation(basicProgram, "Proj");

    basicProgram.Uniforms["Color"]  = gl.GetUniformLocation(basicProgram, "Color");

    basicProgram.Attributes["VertPos"] = gl.GetAttribLocation(basicProgram, "VertPos");
    gl.VertexAttribPointer(u32(mainProgram.Attributes["VertPos"]), 3, gl.VertexAttribDataType.Float, false, 3 * size_of(f32), nil);
    gl.EnableVertexAttribArray(u32(mainProgram.Attributes["VertPos"]));
    gl.BindFragDataLocation(mainProgram, 0, "out_color");
}

Test :: proc(shaderCat : ^catalog.Catalog, textureCat : ^catalog.Catalog) {
    vertexAsset, ok1 := catalog.Find(shaderCat, "test_vert");
    fragAsset, ok2 := catalog.Find(shaderCat, "test_frag");
    kickAsset, ok3 := catalog.Find(textureCat, "test22");
    holdAsset, ok4 := catalog.Find(textureCat, "test22");
    backAsset, ok5 := catalog.Find(textureCat, "back");
    if ok1 != catalog.ERR_SUCCESS || ok2 != catalog.ERR_SUCCESS || ok3 != catalog.ERR_SUCCESS {
        panic("FUCK COULDN'T FIND YA SHADERS M8");
    }

    vertex := vertexAsset.(^ja.Asset.Shader);
    frag :=   fragAsset.(^ja.Asset.Shader);
    kick :=   kickAsset.(^ja.Asset.Texture);
    hold :=   holdAsset.(^ja.Asset.Texture);
    back = backAsset.(^ja.Asset.Texture).GLID;
    append(textures, hold.GLID);
    append(textures, kick.GLID);
    mainProgram = gl.CreateProgram();
    gl.AttachShader(mainProgram, vertex.GLID);
    gl.AttachShader(mainProgram, frag.GLID);

    mainProgram.Vertex = vertex.GLID;
    mainProgram.Fragment = frag.GLID;


    gl.LinkProgram(mainProgram);
    gl.UseProgram(mainProgram);


    mainvao = gl.GenVertexArray();
    gl.BindVertexArray(mainvao);
    vbo := gl.GenVBO();
    gl.BindBuffer(vbo);
    ebo := gl.GenEBO();
    gl.BindBuffer(ebo);

    //Pos, UV
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

    //mainProgram.Uniforms["color"] = gl.GetUniformLocation(mainProgram, "color");
    mainProgram.Uniforms["Model"] = gl.GetUniformLocation(mainProgram, "Model");
    mainProgram.Uniforms["View"]  = gl.GetUniformLocation(mainProgram, "View");
    mainProgram.Uniforms["Proj"]  = gl.GetUniformLocation(mainProgram, "Proj");

    mainProgram.Attributes["Position"] = gl.GetAttribLocation(mainProgram, "Position");
    mainProgram.Attributes["UV"] = gl.GetAttribLocation(mainProgram, "UV");
    gl.VertexAttribPointer(u32(mainProgram.Attributes["Position"]), 3, gl.VertexAttribDataType.Float, false, 5 * size_of(f32), nil);
    gl.VertexAttribPointer(u32(mainProgram.Attributes["UV"]),       2, gl.VertexAttribDataType.Float, false, 5 * size_of(f32), rawptr(int(3 * size_of(f32))));
    gl.EnableVertexAttribArray(u32(mainProgram.Attributes["Position"]));
    gl.EnableVertexAttribArray(u32(mainProgram.Attributes["UV"]));
    gl.BindFragDataLocation(mainProgram, 0, "OutColor");
}