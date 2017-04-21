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

mainProgram : gl.Program; 
vao : gl.VAO;
textures : [dynamic]gl.Texture;
back : gl.Texture;

pos := [..]math.Vec3 {
    {0,  1, 0},
    {10, 0, 0}, 
};

fov : f32 = 45;
near : f32 = 0.1;
far : f32 = 50;

cameraPos := math.Vec3{0, 0, -15};

Draw :: proc(window : math.Vec2) { 
    gl.Enable(gl.Capabilities.DepthTest);
    gl.Enable(gl.Capabilities.Blend);
    gl.UseProgram(mainProgram);
    gl.BindVertexArray(vao);

    gl.DepthFunc(gl.DepthFuncs.Lequal);
    gl.BlendFunc(gl.BlendFactors.SrcAlpha, gl.BlendFactors.OneMinusSrcAlpha);  

    if debugWnd.GetWindowState("ShowCameraSettings") {
        b := debugWnd.GetWindowState("ShowCameraSettings");
        imgui.Begin("Camera Settings", ^b, imgui.GuiWindowFlags.ShowBorders | imgui.GuiWindowFlags.NoCollapse);
        {
            imgui.DragFloat("FOV",  ^fov,  0.1, 0, 0, "%.2f", 1);
            imgui.DragFloat("Near", ^near, 0.1, 0, 0, "%.2f", 1);
            imgui.DragFloat("Far",  ^far,  0.1, 0, 0, "%.2f", 1);
            imgui.Separator();
            pos : [3]f32;
            pos[0] = -cameraPos.x;
            pos[1] = -cameraPos.y;
            pos[2] = -cameraPos.z;
            imgui.DragFloat3("Pos", ^pos, 0.1, 0, 0, "%.2f", 1);
            cameraPos.x = -pos[0];
            cameraPos.y = -pos[1];
            cameraPos.z = -pos[2];
        }
        imgui.End();
        debugWnd.SetWindowState("ShowCameraSettings", b);
    }
    
    view  := math.mat4_translate(cameraPos);
    proj  := math.perspective(math.to_radians(fov), window.x / window.y, near, far);
    gl.UniformMatrix4fv(mainProgram.Uniforms["View"],  view,  false);
    gl.UniformMatrix4fv(mainProgram.Uniforms["Proj"],  proj,  false);

    gl.BindTexture(gl.TextureTargets.Texture2D, back);
    t := math.mat4_translate(math.Vec3{-12,-10, -1});
    model := math.scale(t, math.Vec3{24, 22, 1});
    gl.UniformMatrix4fv(mainProgram.Uniforms["Model"], model, false);
    gl.DrawElements(gl.DrawModes.Triangles, 6, gl.DrawElementsType.UInt, nil);
    
    for p, i in pos {
        gl.BindTexture(gl.TextureTargets.Texture2D, textures[i]);
        t := math.mat4_translate(p);
        model := math.scale(t, math.Vec3{0.7, 1, 1});
        gl.UniformMatrix4fv(mainProgram.Uniforms["Model"], model, false);
        gl.DrawElements(gl.DrawModes.Triangles, 6, gl.DrawElementsType.UInt, nil);
    }


}

Init :: proc(shaderCat : ^catalog.Catalog, textureCat : ^catalog.Catalog) {
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


    vao = gl.GenVertexArray();
    gl.BindVertexArray(vao);
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