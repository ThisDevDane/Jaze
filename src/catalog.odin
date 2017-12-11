/*
 *  @Name:     catalog
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hoej@northwolfprod.com
 *  @Creation: 29-10-2017 21:45:51
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 11-12-2017 04:32:51
 *  
 *  @Description:
 *  
 */

import "core:os.odin";
import "core:fmt.odin";
import "core:strings.odin";

import "mantle:libbrew/gl.odin";
import "mantle:libbrew/win/file.odin";
import "mantle:libbrew/string_util.odin";

import      "gl_util.odin";
import      "debug_info.odin";
import      "console.odin";
import ja   "asset.odin";
import obj  "obj_parser.odin";
import stbi "stb_image.odin";

Asset_Kind :: enum {
    Texture,
    Sound,
    ShaderSource,
    Font,
    Model3D,
    Meta,
    TextAsset,
    Unknown,
}

_extensions_to_types : map[string]Asset_Kind;
created_catalogs : [dynamic]^Catalog;

Catalog :: struct {
    name : string,
    path : string,

    items      : map[string]^ja.Asset,
    items_kind : map[Asset_Kind]int,

    files_in_catalog : int,
    max_size         : int,
    current_size     : int,
}

add_default_extensions :: proc() {
    add_extensions(Asset_Kind.Texture, ".png", ".bmp", ".PNG", ".jpg", ".jpeg");
    add_extensions(Asset_Kind.Sound, ".ogg");
    add_extensions(Asset_Kind.ShaderSource, ".vs", ".vert", ".glslv");
    add_extensions(Asset_Kind.ShaderSource, ".fs", ".frag", ".glslf");
    add_extensions(Asset_Kind.Font, ".ttf");
    add_extensions(Asset_Kind.Model3D, ".obj");
}

add_extensions :: proc(kind : Asset_Kind, exts : ...string) {
    for e in exts {
        _extensions_to_types[e] = kind;
    }
}

create :: proc(path : string) -> ^Catalog {
    return create(path, path);
}

create :: proc(name : string, path : string) -> ^Catalog {
    add_texture :: proc(asset : ^ja.Asset) {
        texture := new(ja.Texture);
        err := stbi.info(&asset.info.path[0], &texture.width, &texture.height, &texture.comp);
        if err == 0 {
            console.logf_error("asset %s could not be opened or is not a recognized format by stb_image", asset.file_name);
        }
        texture.asset = asset;
        asset.derived = texture;
    }

    add_shader :: proc(asset : ^ja.Asset) {
        shader := new(ja.Shader);

        //TODO(@Hoej): Fix this, this is bad
        switch string_util.get_last_extension(asset.path) {
            case ".vs" : { shader.type_ = gl.ShaderTypes.Vertex; }
            case ".glslv" : { shader.type_ = gl.ShaderTypes.Vertex; }
            case ".vert" : { shader.type_ = gl.ShaderTypes.Vertex; }

            case ".fs" : { shader.type_ = gl.ShaderTypes.Fragment; }
            case ".frag" : { shader.type_ = gl.ShaderTypes.Fragment; }
            case ".glslf" : { shader.type_ = gl.ShaderTypes.Fragment; }
        }
        shader.asset = asset;
        asset.derived = shader;
    }

    add_text_asset :: proc(asset : ^ja.Asset) {
        text_asset := new(ja.TextAsset);
        text_asset.extension = string_util.get_last_extension(asset.info.path);
        text_asset.asset = asset;
        asset.derived = text_asset;
    }

    add_font :: proc(asset : ^ja.Asset) {
        font := new(ja.Font);
        font.asset = asset;
        asset.derived = font;
    }

    add_model_3d :: proc(asset : ^ja.Asset) {
        model := new(ja.Model_3d);
        model.asset = asset;
        asset.derived = model;
    }

    if file.is_directory(path) {
        res := new(Catalog);
        res.name = name;
        res.path = path;

        entries := file.get_all_entries_in_directory(path, true);
        res.files_in_catalog = len(entries);
        for entry_path in entries {
            ext := string_util.get_last_extension(entry_path);

            asset := new(ja.Asset);

            info := ja.Asset_Info{};
            //NOTE(Hoej): Looks funny but is correct, first removes the extension but the path is still there
            //            so the second one removes it
            asset.info.file_name = string_util.remove_last_extension(entry_path);
            asset.info.file_name = string_util.remove_path_from_file(asset.info.file_name);
            asset.info.path = entry_path;
            asset.info.size += file.get_file_size(entry_path);
            res.max_size += asset.info.size;            
            if val, ok := _extensions_to_types[ext]; ok {
                switch val {
                    case Asset_Kind.Texture: {
                        add_texture(asset);
                    }

                    case Asset_Kind.ShaderSource: {
                        add_shader(asset);
                    }

                    case Asset_Kind.TextAsset: {
                        add_text_asset(asset);
                    }

                    case Asset_Kind.Model3D: {
                        add_model_3d(asset);
                    }
                }
                res.items_kind[val] += 1;
            } else {
                res.items_kind[Asset_Kind.Unknown] += 1;
                free(asset);
                continue;
            }
            
            val, exists := res.items[asset.info.file_name];
            if exists {
                console.logf_error("(%s catalog) Asset id: %s already exists, overwriting...\n%s vs %s", res.name, 
                                                                                                        asset.info.file_name, 
                                                                                                        val.info.path, 
                                                                                                        asset.info.path);
                free(val); 
            }

            res.items[asset.info.file_name] = asset;
        }
        append(&created_catalogs, res);
        return res;
    } else {
        console.logf_error("(%s catalog) %s is either not a folder or does not exists.", name, path);
        return nil;
    }
}

find :: proc(catalog : ^Catalog, id_str : string, T : type) -> ^T {
    ptr := find(catalog, id_str);
    if ptr != nil {
        res, ok := ptr.derived.(^T);
        if ok {
            return res;
        } else {
            return nil;
        }
    } else {
        return nil;       
    }
}

find :: proc(catalog : ^Catalog, id_str : string) -> ^ja.Asset {
    asset, ok := catalog.items[id_str];

    if ok {
        switch b in asset.derived {
            case ^ja.Texture : {
                _load_texture(b, catalog);
            }

            case ^ja.Shader : {
                _load_shader(b, catalog);
            }

            case ^ja.Shader : {
                _load_shader(b, catalog);
            }

            case ^ja.Model_3d : {
                _load_model_3d(b, catalog);
            }

            case : 
                //TODO(Hoej): Make better error message
                console.logf_error("(%s Catalog) System does not know how to load '%s' of type %T", catalog.name, id_str, b);
        }

        return asset;
    }
    console.logf_error("(%s Catalog) Could not find an asset named '%s'", catalog.name, id_str);
    return nil;
}

_load_model_3d :: proc(model : ^ja.Model_3d, cat : ^Catalog) {
    if !model.info.loaded {
        text, ok := os.read_entire_file(model.info.path); defer free(text);
        if ok {
            asset := model.asset;
            model^ = obj.parse(string(text));
            model.asset = asset;
        } else {
            console.logf_error("(%s Catalog) Could not read %s", cat.name, model.file_name);
        }
    } 
}

_load_texture :: proc(texture : ^ja.Texture, cat : ^Catalog) {
    if !texture.info.loaded {
        //TODO(Hoej): Probably shouldn't keep this around. Should free it.
        texture.data = stbi.load(&texture.info.path[0], &texture.width, &texture.height, &texture.comp, 0);
        if texture.data != nil {
            texture.info.loaded = true;
            cat.current_size += texture.info.size;
        } else {
            console.logf_error("Image %s could not be loaded by stb_image", texture.info.file_name);
        }
    }

    if texture.gl_id == 0 && texture.info.loaded {
        texture.gl_id = gl.gen_texture();
        append(&debug_info.ogl.textures, texture.gl_id);
        prev_id := gl.get_integer(gl.GetIntegerNames.TextureBinding2D);
        gl.bind_texture(gl.TextureTargets.Texture2D, texture.gl_id);
        format : gl.PixelDataFormat;
        switch texture.comp {
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
        gl.tex_image2d(gl.TextureTargets.Texture2D, 0,              gl.InternalColorFormat.RGBA,
                       texture.width,               texture.height, format, 
                       gl.Texture2DDataType.UByte,  texture.data); 
        gl.generate_mipmap(gl.MipmapTargets.Texture2D);

        gl.tex_parameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.MinFilter, gl.TextureParametersValues.LinearMipmapLinear);
        gl.tex_parameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.MagFilter, gl.TextureParametersValues.Linear);

        gl.tex_parameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.WrapS, gl.TextureParametersValues.ClampToEdge);
        gl.tex_parameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.WrapT, gl.TextureParametersValues.ClampToEdge);

        gl.bind_texture(gl.TextureTargets.Texture2D, gl.Texture(prev_id));
    }
}

_load_shader :: proc(shader : ^ja.Shader, cat : ^Catalog) {
    if !shader.info.loaded {
        data, success := os.read_entire_file(shader.info.path);
        if success {
            shader.data = data;
            shader.source = strings.to_odin_string(&shader.data[0]);

            shader.info.loaded = true;
            cat.current_size += shader.info.size;
        } else {
            console.logf_error("%s could not be read from disk", shader.info.file_name);
        }
    }

    if shader.gl_id == 0 && shader.info.loaded {
        success := gl_util.create_and_compile_shader(shader);
        if !success {
            console.logf_error("Shader %s could not be compiled", shader.info.file_name);
        }
    }
}

_load_font :: proc(font : ^ja.Font, cat : ^Catalog) {
    if !font.loaded {
        data, ok := os.read_entire_file(font.path);
        if ok {
            font.data = data;
        } else {
            console.logf_error("Could not load font %s", font.file_name);
        }
    }
}