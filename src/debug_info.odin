/*
 *  @Name:     debug_info
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hoej@northwolfprod.com
 *  @Creation: 27-10-2017 23:21:47
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 13-11-2017 00:46:31
 *  
 *  @Description:
 *  
 */

import "mantle:libbrew/gl.odin";

Function_Load_Status :: struct {
    name    : string,
    address : int,
    success : bool,
}

Info :: struct {
    lib_address : int,
    number_of_functions_loaded : i32,
    number_of_functions_loaded_successed : i32,
    statuses : [dynamic]Function_Load_Status,
}

Ogl_Info :: struct {
    using _ : Info,
    textures : [dynamic]gl.Texture
}

ogl : Ogl_Info;
xinput : Info;