#import "fmt.odin";
#import "os.odin";
#import "strings.odin";
#import win32 "sys/windows.odin";
#import j32 "jwin32.odin";
#import ja "asset.odin";
#import "gl.odin";
#import glUtil "gl_util.odin";
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
    Name : string,
    Path : string,
    Kind : Kind,
    FilesInFolder : int,
    Items : map[string]^ja.Asset,
    MaxSize : uint, // This is if all assets are loaded
    CurrentSize: uint, // This is the currently loaded asset size
    AcceptedExtensions : [dynamic]string,
}

DebugInfo_t :: struct {
    NumberOfCatalogs : int,
    CatalogNames : [dynamic]string,
    Catalogs : [dynamic]^Catalog,
}

DebugInfo : DebugInfo_t;

CreateNew :: proc(kind : Kind, path : string, acceptedExtensions : string) -> (^Catalog, Err) {
    return CreateNew(kind, path, path, acceptedExtensions);
}

CreateNew :: proc(kind : Kind, identifier : string, path : string, acceptedExtensions : string) -> (^Catalog, Err) {
    
    AddTexture :: proc(res : ^Catalog file : ja.FileInfo_t) {
        asset := new(ja.Asset);
        texture := ja.Asset.Texture{};
        texture.FileInfo = file;
        texture.LoadedFromDisk = false;
        c_str := strings.new_c_string(file.Path); defer free(c_str);
        w, h, c : i32;
        stbi.info(c_str, &w, &h, &c);
        texture.Width  = int(w);
        texture.Height = int(h);
        texture.Comp   = int(c);
        asset^ = texture;
        res.Items[asset.FileInfo.Name] = asset;
    }

    AddShader :: proc(res : ^Catalog file : ja.FileInfo_t) {
        asset := new(ja.Asset);
        shader := ja.Asset.Shader{};
        shader.FileInfo = file;
        shader.LoadedFromDisk = false;

        //TODO(@Hoej): Fix this, this is bad
        match shader.FileInfo.Ext {
            case ".vs" : { shader.Type = gl.ShaderTypes.Vertex; }
            case ".glslv" : { shader.Type = gl.ShaderTypes.Vertex; }
            case ".vert" : { shader.Type = gl.ShaderTypes.Vertex; }

            case ".fs" : { shader.Type = gl.ShaderTypes.Fragment; }
            case ".frag" : { shader.Type = gl.ShaderTypes.Fragment; }
            case ".glslf" : { shader.Type = gl.ShaderTypes.Fragment; }
        }

        asset^ = shader;
        res.Items[asset.FileInfo.Name] = asset;
    }

    AddSound :: proc(res : ^Catalog file : ja.FileInfo_t) {
        asset := new(ja.Asset);
        sound := ja.Asset.Sound{};
        sound.FileInfo = file;
        sound.LoadedFromDisk = false;
        asset^ = sound;
        res.Items[asset.FileInfo.Name] = asset;        
    }    

    ExtractAcceptedExtensions :: proc(res : ^Catalog, acceptedExtensions : string) {
        if acceptedExtensions != "" {
            strlen := len(acceptedExtensions);
            last := 0;
            for i := 0; i < strlen; i++ {
                if acceptedExtensions[i] == ',' {
                    append(res.AcceptedExtensions, acceptedExtensions[last..<i]);
                    last = i+1;
                }

                if i == strlen-1 {
                    append(res.AcceptedExtensions, acceptedExtensions[last..<i+1]);
                }
            } 
        }
    }

    //Check if path exists
    pstr := strings.new_c_string(path); defer free(pstr);
    attr := j32.GetFileAttributes(pstr);
    if _IsDirectory(attr) {

        res := new(Catalog);
        res.Name = identifier;
        buf := make([]byte, j32.MAX_PATH);
        res.Path = fmt.bprintf(buf[..], "%s%s", path, path[len(path)-1] == '/' ? "" : "/");
        res.Kind = kind;
        ExtractAcceptedExtensions(res, acceptedExtensions);
        data := j32.FindData{};
        fmt.bprintf(buf[..], "%s%s", path, path[len(path)-1] == '\\' ? "*" : "\\*");
        fileH := j32.FindFirstFile(&buf[0], &data);

        if fileH != win32.INVALID_HANDLE {
            for j32.FindNextFile(fileH, &data) == win32.TRUE {
                if _IsDirectory(data.FileAttributes) {
                    continue;
                }
                nameBuf := make([]byte, len(data.FileName));
                copy(nameBuf, data.FileName[..]);
                str := strings.to_odin_string(&nameBuf[0]);
                for ext in res.AcceptedExtensions {
                    if _GetFileExtension(str) == ext {                        
                        file := _CreateFileInfo(res.Path, str, data);
                        res.MaxSize += uint(file.Size);
                        match kind {
                            case Kind.Texture : {
                                AddTexture(res, file);
                            }

                            case Kind.Shader : {
                                AddShader(res, file);
                            }

                            case Kind.Sound : {
                                AddSound(res, file);
                            }

                            default : {
                                fmt.println(kind);
                                panic("FUCK");
                            }
                        }

                        break;
                    }
                }
                res.FilesInFolder++;
            }

            DebugInfo.NumberOfCatalogs++;
            append(DebugInfo.CatalogNames, res.Name);
            append(DebugInfo.Catalogs, res);
            return res, ERR_SUCCESS;
        } else {
            free(res);
            return nil, ERR_NO_FILES_FOUND;
        }

    } else {
        return nil, ERR_PATH_NOT_FOUND;
    }
}

/*Find :: proc(catalog : ^Catalog, assetName : string) -> (^ja.Asset, Err) {
    return Find(catalog, assetName, true);
}*/
Find :: proc(catalog : ^Catalog, assetName : string/*, upload : bool*/) -> (^ja.Asset, Err) {
    LoadTexture :: proc(e : ^ja.Asset.Texture, cat : ^Catalog) {
        if e.GLID == 0/* && upload*/ {
            c_str := strings.new_c_string(e.FileInfo.Path); defer free(c_str);
            w, h, c : i32;
            e.Data = stbi.load(c_str, &w, &h, &c, 0); //defer stbi.image_free(data);
            e.LoadedFromDisk = true;
            cat.CurrentSize += uint(e.FileInfo.Size);
            e.Width  = int(w);
            e.Height = int(h);
            e.Comp   = int(c);
            e.GLID = gl.GenTexture();
            gl.BindTexture(gl.TextureTargets.Texture2D, e.GLID);
            format : gl.PixelDataFormat;
            match e.Comp {
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
            gl.TexImage2D(gl.TextureTargets.Texture2D, 0, gl.InternalColorFormat.RGBA, 
                          i32(e.Width), i32(e.Height), format, 
                          gl.Texture2DDataType.UByte, e.Data);
            gl.GenerateMipmap(gl.MipmapTargets.Texture2D);

            gl.TexParameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.MinFilter, gl.TextureParametersValues.LinearMipmapLinear);
            gl.TexParameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.MagFilter, gl.TextureParametersValues.Linear);

            gl.TexParameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.WrapS, gl.TextureParametersValues.ClampToEdge);
            gl.TexParameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.WrapT, gl.TextureParametersValues.ClampToEdge);
        }
    }

    LoadShader :: proc(e : ^ja.Asset.Shader, cat : ^Catalog) {
        if !e.LoadedFromDisk {
            e.LoadedFromDisk = true;
            data, _ := os.read_entire_file(e.FileInfo.Path);
            e.Data = data;
            e.Source = strings.to_odin_string(&data[0]);
            cat.CurrentSize += uint(len(data));
        }

        if e.GLID == 0/* && upload*/ {
            e.GLID, _ = glUtil.CreateAndCompileShader(e.Type, e.Source);
        }
    }

    _, ok := catalog.Items[assetName];

    if ok {
        asset := catalog.Items[assetName];
        if !asset.LoadedFromDisk {

            match e in asset {
                case ja.Asset.Texture : {
                    LoadTexture(e, catalog);
                }

                case ja.Asset.Shader : {
                    LoadShader(e, catalog);
                }

                case ja.Asset.Sound : 
                case ja.Asset.ShaderProgram :
                default : {
                    console.LogError("Can't load asset of type: %T, yet...", e);
                }
            }
        }
        return asset, ERR_SUCCESS;
    }

    return nil, ERR_ASSET_NOT_FOUND;
}

/////////////////////////////
//////// Util
_GetFileExtension :: proc(filename : string) -> string {
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

_GetFileNameWithoutExtension :: proc(filename : string) -> string {
    extlen := len(_GetFileExtension(filename));
    namelen := len(filename);
    return filename[0..<(namelen-extlen)];
}

_IsDirectory :: proc(attr : u32) -> bool {
   return (i32(attr) != j32.INVALID_FILE_ATTRIBUTES) && 
          ((attr & j32.FILE_ATTRIBUTE_DIRECTORY) == j32.FILE_ATTRIBUTE_DIRECTORY);
}

_CreateFileInfo :: proc(path : string filename : string, data : j32.FindData) -> ja.FileInfo_t {
    file := ja.FileInfo_t{};
    file.Name = _GetFileNameWithoutExtension(filename);
    file.Ext  = _GetFileExtension(filename);
    pathBuf := make([]byte, j32.MAX_PATH);
    file.Path = fmt.bprintf(pathBuf[..], "%s%s", path, filename);
    MAXDWORD :: 0xffffffff;
    file.Size =  u64(data.FileSizeHigh) * u64(MAXDWORD+1) + u64(data.FileSizeLow);
    return file;
}

