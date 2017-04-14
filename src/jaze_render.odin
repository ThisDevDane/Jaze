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

Draw :: proc() { 
    gl.UseProgram(mainProgram);
    gl.BindVertexArray(vao);
    r : f32 = cast(f32)math.sin(time.GetTimeSinceStart()+1);
    g : f32 = cast(f32)math.sin(time.GetTimeSinceStart()+2);
    b : f32 = cast(f32)math.sin(time.GetTimeSinceStart()+3);

    gl.Uniform(mainProgram.Uniforms["Color"], r, g, b, 1.0);
    gl.DrawArrays(gl.DrawModes.Triangles, 0, 3);
}

Init :: proc(cat : ^catalog.Catalog) {
    vertexAsset, ok1 := catalog.Find(cat, "test_vert");
    fragAsset, ok2 := catalog.Find(cat, "test_frag");
    if ok1 != catalog.ERR_SUCCESS || ok2 != catalog.ERR_SUCCESS {
        panic("FUCK COULDN'T FIND YA SHADERS M8");
    }
    vertex := union_cast(ja.Asset.Shader)vertexAsset;
    frag := union_cast(ja.Asset.Shader)fragAsset;

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

    vertices : [9]f32;
    vertices[0] = -0.5;
    vertices[1] = -0.5;
    vertices[2] =  0.0;
    vertices[3] =  0.5;
    vertices[4] = -0.5;
    vertices[5] =  0.0;
    vertices[6] =  0.0;
    vertices[7] =  0.5;
    vertices[8] =  0.0;

    gl.BufferData(gl.BufferTargets.Array, size_of_val(vertices), ^vertices[0], gl.BufferDataUsage.StaticDraw);

    mainProgram.Uniforms["Color"] = gl.GetUniformLocation(mainProgram, "Color");
    mainProgram.Attributes["Position"] = gl.GetAttribLocation(mainProgram, "Position");
    gl.VertexAttribPointer(cast(u32)mainProgram.Attributes["Position"], 3, gl.VertexAttribDataType.Float, false, 3 * size_of(f32), nil);
    gl.EnableVertexAttribArray(cast(u32)mainProgram.Attributes["Position"]);
}