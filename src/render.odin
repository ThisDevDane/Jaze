#import "fmt.odin";
#import "math.odin";
#import "os.odin";
#import "strings.odin";
#import "gl.odin";
#import glUtil "gl_util.odin";
#import "time.odin";
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
    {0,  1, 0},
    {10, 0, 0}, 
};

scale : f32 = 10;
near : f32 = 0.1;
far : f32 = 500;

cameraPos := math.Vec3{0, 0, 15};

basicProgram : gl.Program;
basicvao : gl.VAO;

Draw :: proc(handle : win32.Hwnd, window : math.Vec2) { 
    gl.Enable(gl.Capabilities.DepthTest);
    gl.Enable(gl.Capabilities.Blend);
    gl.DepthFunc(gl.DepthFuncs.Lequal);
    gl.BlendFunc(gl.BlendFactors.SrcAlpha, gl.BlendFactors.OneMinusSrcAlpha);  

    if debugWnd.GetWindowState("ShowCameraSettings") {
        b := debugWnd.GetWindowState("ShowCameraSettings");
        imgui.Begin("Camera Settings", ^b, imgui.GuiWindowFlags.ShowBorders | imgui.GuiWindowFlags.NoCollapse);
        {
            imgui.DragFloat("Scale",  ^scale,  0.1, 0, 0, "%.2f", 1);
            imgui.DragFloat("Near", ^near, 0.1, 0, 0, "%.2f", 1);
            imgui.DragFloat("Far",  ^far,  0.1, 0, 0, "%.2f", 1);
            imgui.Separator();
            pos : [3]f32;
            pos[0] = cameraPos.x;
            pos[1] = cameraPos.y;
            pos[2] = cameraPos.z;
            imgui.DragFloat3("Pos", ^pos, 0.1, 0, 0, "%.2f", 1);
            cameraPos.x = pos[0];
            cameraPos.y = pos[1];
            cameraPos.z = pos[2];
        }
        imgui.End();
        debugWnd.SetWindowState("ShowCameraSettings", b);
    }
    
    gl.UseProgram(mainProgram);
    gl.BindVertexArray(mainvao);

    view  := math.mat4_translate(-cameraPos);
    //proj  := math.perspective(math.to_radians(45), window.x / window.y, near, far);
    ratio := window.x / window.y;
    w :f32= (scale * ratio) * 0.5;
    h :f32= (scale) * 0.5;

    l :f32= -w;
    r := w;
    t :f32= -h;
    b := h;

    proj  := math.ortho3d(l, r, t, b, far, near);




    gl.UniformMatrix4fv(mainProgram.Uniforms["View"],  view,  false);
    gl.UniformMatrix4fv(mainProgram.Uniforms["Proj"],  proj,  false);

    gl.BindTexture(gl.TextureTargets.Texture2D, back);
    tr := math.mat4_translate(math.Vec3{0, 0, 0});
    model := math.scale(tr, math.Vec3{24, 22, 1});
    gl.UniformMatrix4fv(mainProgram.Uniforms["Model"], model, false);
    gl.DrawElements(gl.DrawModes.Triangles, 6, gl.DrawElementsType.UInt, nil);
    
    for p, i in pos {
        gl.BindTexture(gl.TextureTargets.Texture2D, textures[i]);
        t := math.mat4_translate(p);
        model := math.scale(t, math.Vec3{0.7, 1, 1});
        gl.UniformMatrix4fv(mainProgram.Uniforms["Model"], model, false);
        gl.DrawElements(gl.DrawModes.Triangles, 6, gl.DrawElementsType.UInt, nil);
    }



    {
        gl.UseProgram(basicProgram);
        gl.BindVertexArray(basicvao);
        gl.UniformMatrix4fv(basicProgram.Uniforms["View"],  view,  false);
        gl.UniformMatrix4fv(basicProgram.Uniforms["Proj"],  proj,  false);
        
        mousePos : win32.Point;
        win32.GetCursorPos(^mousePos);
        win32.ScreenToClient(handle, ^mousePos);
        pos := math.Vec4{cast(f32)mousePos.x, cast(f32)mousePos.y, 0, 0};
        {
            pos.x = ((pos.x / window.x) * 2.0 - 1.0)* w + cameraPos.x;
            pos.y = ((pos.y / window.y) * 2.0 - 1.0)* h + cameraPos.y;
            pos.y = -pos.y;
        }

        off := math.mat4_translate(math.Vec3{-0.5, -0.5, 0});
        t := math.mat4_translate(math.Vec3{pos.x, pos.y, 0});
        model := math.mul(off, t);
        gl.UniformMatrix4fv(basicProgram.Uniforms["Model"], model, false);
        gl.Uniform(basicProgram.Uniforms["Color"], cast(f32)1.0, 0.0, 0.0, 1.0);
        gl.DrawElements(gl.DrawModes.Triangles, 6, gl.DrawElementsType.UInt, nil);

        model = math.scale(math.mat4_identity(), math.Vec3{0.1, 0.1, 0.1});
        model = math.mul(model, off);
        gl.UniformMatrix4fv(basicProgram.Uniforms["Model"], model, false);
        gl.Uniform(basicProgram.Uniforms["Color"], cast(f32)0.0, 1.0, 0.0, 1.0);
        gl.DrawElements(gl.DrawModes.Triangles, 6, gl.DrawElementsType.UInt, nil);

    }
}

Init :: proc(shaderCat : ^catalog.Catalog, textureCat : ^catalog.Catalog) {
    Test(shaderCat, textureCat);
    Test2(shaderCat);
}

Test2 :: proc(shaderCat : ^catalog.Catalog) {
    vertexAsset, ok1 := catalog.Find(shaderCat, "basic_vert");
    fragAsset, ok2 := catalog.Find(shaderCat, "basic_frag");
    vertex := union_cast(^ja.Asset.Shader)vertexAsset;
    frag := union_cast(^ja.Asset.Shader)fragAsset;

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

    gl.BufferData(gl.BufferTargets.Array, size_of_val(vertices), ^vertices[0], gl.BufferDataUsage.StaticDraw);
    gl.BufferData(gl.BufferTargets.ElementArray, size_of_val(elements), ^elements[0], gl.BufferDataUsage.StaticDraw);

    basicProgram.Uniforms["Model"] = gl.GetUniformLocation(basicProgram, "Model");
    basicProgram.Uniforms["View"]  = gl.GetUniformLocation(basicProgram, "View");
    basicProgram.Uniforms["Proj"]  = gl.GetUniformLocation(basicProgram, "Proj");

    basicProgram.Uniforms["Color"]  = gl.GetUniformLocation(basicProgram, "Color");

    basicProgram.Attributes["VertPos"] = gl.GetAttribLocation(basicProgram, "VertPos");
    gl.VertexAttribPointer(cast(u32)mainProgram.Attributes["VertPos"], 3, gl.VertexAttribDataType.Float, false, 3 * size_of(f32), nil);
    gl.EnableVertexAttribArray(cast(u32)mainProgram.Attributes["VertPos"]);
    gl.BindFragDataLocation(mainProgram, 0, "out_color");
}

Test :: proc(shaderCat : ^catalog.Catalog, textureCat : ^catalog.Catalog) {
    vertexAsset, ok1 := catalog.Find(shaderCat, "test_vert");
    fragAsset, ok2 := catalog.Find(shaderCat, "test_frag");
    kickAsset, ok3 := catalog.Find(textureCat, "player_kick");
    holdAsset, ok4 := catalog.Find(textureCat, "player_hold1");
    backAsset, ok5 := catalog.Find(textureCat, "back");

    if ok1 != catalog.ERR_SUCCESS || ok2 != catalog.ERR_SUCCESS || ok3 != catalog.ERR_SUCCESS {
        panic("FUCK COULDN'T FIND YA SHADERS M8");
    }

    vertex := union_cast(^ja.Asset.Shader)vertexAsset;
    frag := union_cast(^ja.Asset.Shader)fragAsset;
    kick := union_cast(^ja.Asset.Texture)kickAsset;
    hold := union_cast(^ja.Asset.Texture)holdAsset;
    back = (union_cast(^ja.Asset.Texture)backAsset).GLID;
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


    gl.BufferData(gl.BufferTargets.Array, size_of_val(vertices), ^vertices[0], gl.BufferDataUsage.StaticDraw);
    gl.BufferData(gl.BufferTargets.ElementArray, size_of_val(elements), ^elements[0], gl.BufferDataUsage.StaticDraw);

    //mainProgram.Uniforms["color"] = gl.GetUniformLocation(mainProgram, "color");
    mainProgram.Uniforms["Model"] = gl.GetUniformLocation(mainProgram, "Model");
    mainProgram.Uniforms["View"]  = gl.GetUniformLocation(mainProgram, "View");
    mainProgram.Uniforms["Proj"]  = gl.GetUniformLocation(mainProgram, "Proj");

    mainProgram.Attributes["Position"] = gl.GetAttribLocation(mainProgram, "Position");
    mainProgram.Attributes["UV"] = gl.GetAttribLocation(mainProgram, "UV");
    gl.VertexAttribPointer(cast(u32)mainProgram.Attributes["Position"], 3, gl.VertexAttribDataType.Float, false, 5 * size_of(f32), nil);
    gl.VertexAttribPointer(cast(u32)mainProgram.Attributes["UV"],       2, gl.VertexAttribDataType.Float, false, 5 * size_of(f32), cast(rawptr)cast(int)(3 * size_of(f32)));
    gl.EnableVertexAttribArray(cast(u32)mainProgram.Attributes["Position"]);
    gl.EnableVertexAttribArray(cast(u32)mainProgram.Attributes["UV"]);
    gl.BindFragDataLocation(mainProgram, 0, "OutColor");
}