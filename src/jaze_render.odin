#import "fmt.odin";
#import "math.odin";
#import "os.odin";
#import "strings.odin";
#import gl "jaze_gl.odin";
#import glUtil "jaze_gl_util.odin";
#import time "jaze_time.odin";
#import catalog "jaze_catalog.odin";
#import ja "jaze_asset.odin";

mainProgram : gl.Program; 
vao : gl.VAO;
texture : gl.Texture;

Draw :: proc(window : math.Vec2) { 
    gl.UseProgram(mainProgram);
    gl.BindVertexArray(vao);

    d2a :: proc(d : f32) -> f32 {
        return d * (math.PI/180);
    }

    model := math.mat4_rotate(math.Vec3{1.0, 0.0, 0.0}, d2a(-55.0));
    view  := math.mat4_translate(math.Vec3{0.0, 0.0, -3.0});
    proj  := math.perspective(d2a(90.0), window.x / window.y, 0.1, 100.0);

    gl.BindTexture(gl.TextureTargets.Texture2D, texture);
    gl.DrawElements(gl.DrawModes.Triangles, 6, gl.DrawElementsType.UInt, nil);

    gl.PolygonMode(gl.PolygonFace.FrontAndBack, gl.PolygonModes.Line);
    gl.DrawElements(gl.DrawModes.Triangles, 6, gl.DrawElementsType.UInt, nil);
    gl.PolygonMode(gl.PolygonFace.FrontAndBack, gl.PolygonModes.Fill);
}

Init :: proc(shaderCat : ^catalog.Catalog, textureCat : ^catalog.Catalog) {
    vertexAsset, ok1 := catalog.Find(shaderCat, "test_vert");
    fragAsset, ok2 := catalog.Find(shaderCat, "test_frag");
    textureAsset, ok3 := catalog.Find(textureCat, "test");

    if ok1 != catalog.ERR_SUCCESS || ok2 != catalog.ERR_SUCCESS || ok3 != catalog.ERR_SUCCESS {
        panic("FUCK COULDN'T FIND YA SHADERS M8");
    }

    vertex := union_cast(^ja.Asset.Shader)vertexAsset;
    frag := union_cast(^ja.Asset.Shader)fragAsset;
    texturea := union_cast(^ja.Asset.Texture)textureAsset;
    texture = texturea.GLID;
    mainProgram = gl.CreateProgram();
    gl.AttachShader(mainProgram, vertex.GLID);
    gl.AttachShader(mainProgram, frag.GLID);

    gl.BindFragDataLocation(mainProgram, 0, "OutColor");

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
         0.5,  0.5, 0.0, 1.0, 1.0, //tr
         0.5, -0.5, 0.0, 1.0, 0.0, //br
        -0.5, -0.5, 0.0, 0.0, 0.0, //bl
        -0.5,  0.5, 0.0, 0.0, 1.0, //tl
    };

    elements := [..]u32 {
        0, 1, 3,
        1, 2, 3,
    };


    /* Produces IR error
    vertices := []f32 {
        -0.5, -0.5, 0.0,
         0.5, -0.5, 0.0,
         0.0,  0.5, 0.0
    };
    */

    gl.BufferData(gl.BufferTargets.Array,        size_of_val(vertices), ^vertices[0], gl.BufferDataUsage.StaticDraw);
    gl.BufferData(gl.BufferTargets.ElementArray, size_of_val(elements), ^elements[0], gl.BufferDataUsage.StaticDraw);

    mainProgram.Uniforms["color"] = gl.GetUniformLocation(mainProgram, "color");
    mainProgram.Attributes["Position"] = gl.GetAttribLocation(mainProgram, "Position");
    mainProgram.Attributes["UV"] = gl.GetAttribLocation(mainProgram, "UV");
    gl.VertexAttribPointer(cast(u32)mainProgram.Attributes["Position"], 3, gl.VertexAttribDataType.Float, false, 5 * size_of(f32), nil);
    gl.VertexAttribPointer(cast(u32)mainProgram.Attributes["UV"],       2, gl.VertexAttribDataType.Float, false, 5 * size_of(f32), cast(rawptr)cast(int)(3 * size_of(f32)));
    gl.EnableVertexAttribArray(cast(u32)mainProgram.Attributes["Position"]);
    gl.EnableVertexAttribArray(cast(u32)mainProgram.Attributes["UV"]);
}