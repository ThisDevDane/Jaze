/*
 *  @Name:     asset
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 21-04-2017 03:04:34
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 24-11-2017 23:22:22
 *  
 *  @Description:
 *      Contains the asset construct and associated data.
 */
import gl "mantle:libbrew/gl.odin";

Asset_Info :: struct {
    file_name : string,
    path      : string,
    size      : int,
    loaded    : bool,
}

Asset :: struct {
    using info : Asset_Info,
    derived    : union {^Texture, ^Shader, ^TextAsset, ^Font, ^Model_3d, ^Unknown},
}

Texture :: struct {
    using asset : ^Asset,
    gl_id       : gl.Texture,
    width       : i32,
    height      : i32,
    comp        : i32,
    data        : ^u8
}

Shader :: struct {
    using asset : ^Asset,
    gl_id       : gl.Shader,
    type_       : gl.ShaderTypes,
    source      : string,
    data        : []u8,
}

TextAsset :: struct {
    using asset : ^Asset,
    text        : string,
    extension   : string,
}

Font :: struct {
    using asset : ^Asset,
    data        : []u8,
}

Model_3d :: struct {
    using asset : ^Asset,
    vertices : [dynamic]f32,
    normals  : [dynamic]f32,
    uvs      : [dynamic]f32,

    vert_indices  : [dynamic]u32,  
    norm_indicies : [dynamic]u32,  
    uv_indicies   : [dynamic]u32,

    vert_num : int,
    norm_num : int,
    uvs_num  : int,

    vert_ind_num : int,
    norm_ind_num : int,
    uv_ind_num   : int,
}

Unknown :: struct {
}
