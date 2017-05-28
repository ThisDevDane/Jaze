/*
 *  @Name:     catalog
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 01-05-2017 18:28:11
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 28-05-2017 22:44:07
 *  
 *  @Description:
 *      Contains the catalog construct.
 *      A catalog is a collection of asset that may or may not have been put in memory.
 *      When querying a catalog for an asset it may do relevant work related to the asset to make it ready for usage,
 *      such include;
 *          - Texture: it will be uploaded the the GPU.
 *          - Shader:  it will be compiled and if success it will upload it to the GPU.
 */
#import "fmt.odin";
#import "os.odin";
#import "strings.odin";
#import win32 "sys/windows.odin";
#import j32 "jwin32.odin";
#import ja "asset.odin";
#import "gl.odin";
#import gl_util "gl_util.odin";
#import "console.odin";
#import stbi "stb_image.odin";

Err :: int;

ERR_SUCCESS         : Err : 0;
ERR_PATH_NOT_FOUND  : Err : 1;
ERR_NO_FILES_FOUND  : Err : 2;
ERR_ASSET_NOT_FOUND : Err : 2;

Kind :: enum {
    Texture,
    Shader,
    Sound,
}

Catalog :: struct {
    name : string,
    path : string,
    kind : Kind,
    files_in_folder : int,
    items: map[string]^ja.Asset,
    max_size : uint, // This is if all assets are loaded
    current_size: uint, // This is the currently loaded asset size
    accepted_extensions : [dynamic]string,
}

DebugInfo :: struct {
    number_of_catalogs : int,
    catalog_names : [dynamic]string,
    catalogs : [dynamic]^Catalog,
}

debug_info : DebugInfo;

create_new :: proc(kind : Kind, path : string, acceptedExtensions : string) -> (^Catalog, Err) {
    return create_new(kind, path, path, acceptedExtensions);
}

create_new :: proc(kind : Kind, identifier : string, path : string, acceptedExtensions : string) -> (^Catalog, Err) {
    
    add_texture :: proc(res : ^Catalog file : ja.FileInfo) {
        asset := new(ja.Asset);
        texture := ja.Asset.Texture{};
        texture.file_info = file;
        texture.loaded_from_disk = false;
        c_str := strings.new_c_string(file.path); defer free(c_str);
        w, h, c : i32;
        stbi.info(c_str, &w, &h, &c);
        texture.width  = int(w);
        texture.height = int(h);
        texture.comp   = int(c);
        asset^ = texture;
        res.items[asset.file_info.name] = asset;
    }

    add_shader :: proc(res : ^Catalog file : ja.FileInfo) {
        asset := new(ja.Asset);
        shader := ja.Asset.Shader{};
        shader.file_info = file;
        shader.loaded_from_disk = false;

        //TODO(@Hoej): Fix this, this is bad
        match shader.file_info.ext {
            case ".vs" : { shader.type = gl.ShaderTypes.Vertex; }
            case ".glslv" : { shader.type = gl.ShaderTypes.Vertex; }
            case ".vert" : { shader.type = gl.ShaderTypes.Vertex; }

            case ".fs" : { shader.type = gl.ShaderTypes.Fragment; }
            case ".frag" : { shader.type = gl.ShaderTypes.Fragment; }
            case ".glslf" : { shader.type = gl.ShaderTypes.Fragment; }
        }

        asset^ = shader;
        res.items[asset.file_info.name] = asset;
    }

    add_sound :: proc(res : ^Catalog file : ja.FileInfo) {
        asset := new(ja.Asset);
        sound := ja.Asset.Sound{};
        sound.file_info = file;
        sound.loaded_from_disk = false;
        asset^ = sound;
        res.items[asset.file_info.name] = asset;        
    }    

    extract_accepted_extensions :: proc(res : ^Catalog, acceptedExtensions : string) {
        if acceptedExtensions != "" {
            strlen := len(acceptedExtensions);
            last := 0;
            for i := 0; i < strlen; i++ {
                if acceptedExtensions[i] == ',' {
                    append(res.accepted_extensions, acceptedExtensions[last..<i]);
                    last = i+1;
                }

                if i == strlen-1 {
                    append(res.accepted_extensions, acceptedExtensions[last..<i+1]);
                }
            } 
        }
    }

    //Check if path exists
    pstr := strings.new_c_string(path); defer free(pstr);
    attr := win32.get_file_attributes_a(pstr);
    if _is_directory(attr) {

        res := new(Catalog);
        res.name = identifier;
        buf := make([]byte, win32.MAX_PATH);
        res.path = fmt.bprintf(buf[..], "%s%s", path, path[len(path)-1] == '/' ? "" : "/");
        res.kind = kind;
        extract_accepted_extensions(res, acceptedExtensions);
        data := win32.FindData{};
        fmt.bprintf(buf[..], "%s%s", path, path[len(path)-1] == '\\' ? "*" : "\\*");
        fileH := win32.find_first_file_a(&buf[0], &data);

        if fileH != win32.INVALID_HANDLE {
            for win32.find_next_file_a(fileH, &data) == win32.TRUE {
                if _is_directory(data.file_attributes) {
                    continue;
                }
                nameBuf := make([]byte, len(data.file_name));
                copy(nameBuf, data.file_name[..]);
                str := strings.to_odin_string(&nameBuf[0]);
                for ext in res.accepted_extensions {
                    if _get_file_extension(str) == ext {                        
                        file := _create_file_info(res.path, str, data);
                        res.max_size += uint(file.size);
                        //Check for meta file and make if not existing
                        if !_meta_file_check(res.path) {

                        }
                        match kind {
                            case Kind.Texture : {
                                add_texture(res, file);
                            }

                            case Kind.Shader : {
                                add_shader(res, file);
                            }

                            case Kind.Sound : {
                                add_sound(res, file);
                            }

                            case : {
                                fmt.println(kind);
                                panic("FUCK");
                            }
                        }

                        break;
                    }
                }
                res.files_in_folder++;
            }

            debug_info.number_of_catalogs++;
            append(debug_info.catalog_names, res.name);
            append(debug_info.catalogs, res);
            return res, ERR_SUCCESS;
        } else {
            free(res);
            return nil, ERR_NO_FILES_FOUND;
        }

    } else {
        return nil, ERR_PATH_NOT_FOUND;
    }
}

find :: proc(catalog : ^Catalog, assetName : string/*, upload : bool*/) -> (^ja.Asset, Err) {
    load_texture :: proc(e : ^ja.Asset.Texture, cat : ^Catalog) {
        if e.gl_id == 0/* && upload*/ {
            c_str := strings.new_c_string(e.file_info.path); defer free(c_str);
            w, h, c : i32;
            e.data = stbi.load(c_str, &w, &h, &c, 0); //defer stbi.image_free(data);
            e.loaded_from_disk = true;
            cat.current_size += uint(e.file_info.size);
            e.width  = int(w);
            e.height = int(h);
            e.comp   = int(c);
            e.gl_id = gl.gen_texture();
            gl.bind_texture(gl.TextureTargets.Texture2D, e.gl_id);
            format : gl.PixelDataFormat;
            match e.comp {
                case 1 : {
                    format = gl.PixelDataFormat.Red;
                }

                case 2 : {
                    format = gl.PixelDataFormat.RG;
                }

                case 3 : {
                    format = gl.PixelDataFormat.RGB;
                }

                case 4 : {
                    format = gl.PixelDataFormat.RGBA;
                }
            }
            gl.tex_image2d(gl.TextureTargets.Texture2D, 0, gl.InternalColorFormat.RGBA, 
                          i32(e.width), i32(e.height), format, 
                          gl.Texture2DDataType.UByte, e.data);
            gl.generate_mipmap(gl.MipmapTargets.Texture2D);

            gl.tex_parameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.MinFilter, gl.TextureParametersValues.LinearMipmapLinear);
            gl.tex_parameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.MagFilter, gl.TextureParametersValues.Linear);

            gl.tex_parameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.WrapS, gl.TextureParametersValues.ClampToEdge);
            gl.tex_parameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.WrapT, gl.TextureParametersValues.ClampToEdge);
        }
    }

    load_shader :: proc(e : ^ja.Asset.Shader, cat : ^Catalog) {
        if !e.loaded_from_disk {
            e.loaded_from_disk = true;
            data, _ := os.read_entire_file(e.file_info.path);
            e.data = data;
            e.source = strings.to_odin_string(&data[0]);
            cat.current_size += uint(len(data));
        }

        if e.gl_id == 0/* && upload*/ {
            e.gl_id, _ = gl_util.create_and_compile_shader(e.type, e.source);
        }
    }

    _, ok := catalog.items[assetName];

    if ok {
        asset := catalog.items[assetName];
        if !asset.loaded_from_disk {

            match e in asset {
                case ja.Asset.Texture : {
                    load_texture(e, catalog);
                }

                case ja.Asset.Shader : {
                    load_shader(e, catalog);
                }

                case ja.Asset.Sound : 
                case ja.Asset.ShaderProgram :
                case : {
                    console.log_error("Can't load asset of type: %T, yet...", e);
                }
            }
        }
        return asset, ERR_SUCCESS;
    }

    return nil, ERR_ASSET_NOT_FOUND;
}

/////////////////////////////
//////// Util
_get_file_extension :: proc(filename : string) -> string {
    strLen := len(filename);

    for i := strLen-1; i > 0; i-- {
        if filename[i] == '.' {
            res := filename[i..<strLen];
            if res == "." {
                return "";
            } else {
                return res;
            }
        }
    }

    return "";
}
_get_file_name_without_extension :: proc(filename : string) -> string {
    extlen := len(_get_file_extension(filename));
    namelen := len(filename);
    return filename[0..<(namelen-extlen)];
}

_is_directory :: proc(attr : u32) -> bool {
   return (i32(attr) != win32.INVALID_FILE_ATTRIBUTES) && 
          ((attr & win32.FILE_ATTRIBUTE_DIRECTORY) == win32.FILE_ATTRIBUTE_DIRECTORY);
}

_create_file_info :: proc(path : string filename : string, data : win32.FindData) -> ja.FileInfo {
    file := ja.FileInfo{};
    file.name = _get_file_name_without_extension(filename);
    file.ext  = _get_file_extension(filename);
    pathBuf := make([]byte, win32.MAX_PATH);
    file.path = fmt.bprintf(pathBuf[..], "%s%s", path, filename);
    MAXDWORD :: 0xffffffff;
    file.size =  u64(data.file_size_high) * u64(MAXDWORD+1) + u64(data.file_size_low);
    return file;
}

_meta_file_check :: proc(asset_path : string) {
    console.log(asset_path);
}