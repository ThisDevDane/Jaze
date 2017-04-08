#import "fmt.odin";
#import gl "jaze_gl.odin";
#import glUtil "jaze_gl_util.odin";

mainProgram : gl.Program; 
vao : gl.VAO;

Draw :: proc() { 
    gl.UseProgram(mainProgram);
    gl.BindVertexArray(vao);
    gl.DrawArrays(gl.DrawModes.Triangles, 0, 3);
}

Init :: proc() {
    vertex := `
        #version 330

        in vec3 Position;

        void main() {
            gl_Position = vec4(Position, 1.0);
        }
    `;

    frag := `
        #version 330

        out vec4 OutColor;

        void main() {
            OutColor = vec4(0.0, 1.0, 1.0, 1.0);
        }
    `;

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

    mainProgram.Attributes["Position"] = gl.GetAttribLocation(mainProgram, "Position");
    gl.VertexAttribPointer(cast(u32)mainProgram.Attributes["Position"], 3, gl.VertexAttribDataType.Float, false, 3 * size_of(f32), nil);
    gl.EnableVertexAttribArray(cast(u32)mainProgram.Attributes["Position"]);
}