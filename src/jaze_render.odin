#import "fmt.odin";
#import "math.odin";
#import "os.odin";
#import "strings.odin";
#import gl "jaze_gl.odin";
#import glUtil "jaze_gl_util.odin";
#import time "jaze_time.odin";
#import catalog "jaze_catalog.odin";
#import ja "jaze_asset.odin";
#import rnd "pcg.odin";

mainProgram : gl.Program; 
vao : gl.VAO;
texture : gl.Texture;

pos := [..]math.Vec3 {
    {0, 1, 9}, {9, -2, -9}, {7, -8, -2}, {-4, -3, -8},
    {8, -8, -7}, {-9, 10, 3}, {-3, 2, 7}, {-6, -10, 7},
    {-6, -2, 10}, {7, -9, 8}, {9, -3, 5}, {7, 8, -4},
    {7, 1, -3}, {-10, 9, 10}, {-5, -4, 2}, {9, 5, -2},
    {10, 2, -8}, {4, -2, -3}, {9, -2, -5}, {1, -8, -10},
    {-2, 8, -5}, {6, -2, -7}, {-2, 0, 10}, {1, 2, -5},
    {5, 8, 2}, {1, 8, 4}, {-9, 9, -5}, {-1, 5, 3},
    {-9, 0, -5}, {-3, -7, -5}, {8, 1, -5}, {-6, 7, -2},
    {-6, -10, 8}, {-3, 4, -7}, {4, -7, 3}, {4, 2, 0},
    {10, -2, -6}, {8, 10, 4}, {1, -6, 5}, {3, 5, -10},
    {0, -1, 5}, {8, 5, -8}, {-3, -4, 0}, {-5, 1, 6},
    {9, -4, 7}, {-2, -4, 9}, {-9, 9, -2}, {-7, 4, -8},
    {9, -2, 2}, {4, -4, 5},
};

rrate := [..]f32 {
    -5.6021761520e-2,   1.3306000960e+0,
    -6.4909592360e-1,   1.1820793200e+0,
     1.1412866910e+0,  -3.8013518010e-2,
     7.3344250530e-1,  -7.1755797060e-1,
     7.7277465560e-1,  -1.9521073080e-1,
     9.7535409250e-1,   5.7684197620e-2,
     9.2850572990e-3,   1.4078277350e+0,
    -5.9980045000e-1,  -2.4675947840e+0,
     4.3278974470e-1,   2.6004661980e-2,
     1.7668193290e+0,  -1.3611024510e+0,
    -1.7416462010e+0,  -2.3837359780e-1,
    -7.1349862630e-1,  -1.6974207740e+0,
    -1.1830463350e+0,   1.8418947450e-1,
     1.6140134230e+0,   1.1056760100e+0,
    -1.0872448130e+0,   5.6057794840e-1,
    -5.8859800090e-1,  -1.3524637410e-1,
     2.1154867420e-1,  -9.4311134010e-1,
     1.1374231430e+0,  -1.2822973270e+0,
     5.6583587600e-1,   1.5943054850e+0,
    -1.2985412640e+0,   7.4322278830e-1,
    -2.0327122210e-1,   8.0544290770e-1,
     4.7871231270e-1,   1.7456113910e-1,
     1.0935329370e-1,   3.6630484170e-1,
    -3.4442705390e-1,  -2.4210176660e-2,
    -3.2400754700e-1,  -8.8363862150e-1,
};

Draw :: proc(window : math.Vec2) { 
    gl.UseProgram(mainProgram);
    gl.BindVertexArray(vao);
    gl.Enable(gl.Capabilities.DepthTest);
    gl.Enable(gl.Capabilities.Multisample);  
    gl.Enable(gl.Capabilities.Blend);
    gl.BlendFunc(gl.BlendFactors.SrcAlpha, gl.BlendFactors.OneMinusSrcAlpha);  

    view  := math.mat4_translate(math.Vec3{0.0, 0.0, -15.0});
    proj  := math.perspective(math.to_radians(45.0), window.x / window.y, 0.1, 100.0);
    gl.UniformMatrix4fv(mainProgram.Uniforms["View"],  view,  false);
    gl.UniformMatrix4fv(mainProgram.Uniforms["Proj"],  proj,  false);
    gl.BindTexture(gl.TextureTargets.Texture2D, texture);

    for p, idx in pos {
        rate := rrate[idx];
        a := (20.0 * cast(f32)time.GetTimeSinceStart()) * rate;
        r := math.mat4_rotate(math.Vec3{1.0, 0.3, 0.5}, math.to_radians(a));
        t := math.mat4_translate(p);
        model := math.mul(t, r);
        
        gl.UniformMatrix4fv(mainProgram.Uniforms["Model"], model, false);
        gl.PolygonMode(gl.PolygonFace.FrontAndBack, gl.PolygonModes.Fill);
        gl.DrawArrays(gl.DrawModes.Triangles, 0, 36);
        gl.PolygonMode(gl.PolygonFace.FrontAndBack, gl.PolygonModes.Fill);
    }

    
}

Init :: proc(shaderCat : ^catalog.Catalog, textureCat : ^catalog.Catalog) {
    vertexAsset, ok1 := catalog.Find(shaderCat, "test_vert");
    fragAsset, ok2 := catalog.Find(shaderCat, "test_frag");
    textureAsset, ok3 := catalog.Find(textureCat, "yellow_cross");

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
    //ebo := gl.GenEBO();
    //gl.BindBuffer(ebo);

    //Pos, UV
    vertices := [..]f32 {
        -0.5, -0.5, -0.5,  0.0, 0.0,
         0.5, -0.5, -0.5,  1.0, 0.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
        -0.5,  0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 0.0,

        -0.5, -0.5,  0.5,  0.0, 0.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 1.0,
         0.5,  0.5,  0.5,  1.0, 1.0,
        -0.5,  0.5,  0.5,  0.0, 1.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,

        -0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5,  0.5, -0.5,  1.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,
        -0.5,  0.5,  0.5,  1.0, 0.0,

         0.5,  0.5,  0.5,  1.0, 0.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5,  0.5,  0.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 0.0,

        -0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5, -0.5,  1.0, 1.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,

        -0.5,  0.5, -0.5,  0.0, 1.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5,  0.5,  0.5,  1.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5,  0.5,  0.5,  0.0, 0.0,
        -0.5,  0.5, -0.5,  0.0, 1.0,
    };

    /*elements := [..]u32 {
        0, 1, 3,
        1, 2, 3,
    };*/


    /* Produces IR error
    vertices := []f32 {
        -0.5, -0.5, 0.0,
         0.5, -0.5, 0.0,
         0.0,  0.5, 0.0
    };
    */


    gl.BufferData(gl.BufferTargets.Array, size_of_val(vertices), ^vertices[0], gl.BufferDataUsage.StaticDraw);
    //gl.BufferData(gl.BufferTargets.ElementArray, size_of_val(elements), ^elements[0], gl.BufferDataUsage.StaticDraw);

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
}