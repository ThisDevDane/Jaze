#import "fmt.odin";
#import "math.odin";
#import "os.odin";
#import "strings.odin";
#import gl "jaze_gl.odin";
#import glUtil "jaze_gl_util.odin";
#import time "jaze_time.odin";

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

Init :: proc() {
    vertex_bytes, _ := os.read_entire_file("data/shaders/test_vert.vs");
    frag_bytes, _    := os.read_entire_file("data/shaders/test_frag.fs");

    defer {
        free(vertex_bytes);
        free(frag_bytes);
    }

    vertex : string = strings.to_odin_string(^vertex_bytes[0]);
    frag : string   = strings.to_odin_string(^frag_bytes[0]);

    VertexShader, _ := glUtil.CreateAndCompileShader(gl.ShaderTypes.Vertex, vertex);
    FragShader, _ := glUtil.CreateAndCompileShader(gl.ShaderTypes.Fragment, frag);

    mainProgram = gl.CreateProgram();
    gl.AttachShader(mainProgram, VertexShader);
    gl.AttachShader(mainProgram, FragShader);


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