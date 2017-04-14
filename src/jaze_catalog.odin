#import "fmt.odin";
#import "os.odin";
#import "strings.odin";
#import win32 "sys/windows.odin";
#import j32 "jaze_win32.odin";
#import ja "jaze_asset.odin";
#import gl "jaze_gl.odin";
#import glUtil "jaze_gl_util.odin";
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
    Items : map[string]ja.Asset,
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
    res := new(Catalog);
    res.Name = identifier;
    buf := make([]byte, j32.MAX_PATH);
    res.Path = fmt.sprintf(buf[..0], "%s%s", path, path[len(path)-1] == '/' ? "" : "/");
    res.Kind = kind;
    //Check if path exists
    pstr := strings.new_c_string(path); defer free(pstr);
    attr := j32.GetFileAttributes(pstr);
    if _IsDirectory(attr) {

        if acceptedExtensions != "" {
            strlen := len(acceptedExtensions);
            last := 0;
            for i := 0; i < strlen; i++ {
                if acceptedExtensions[i] == ',' {
                    append(res.AcceptedExtensions, acceptedExtensions[last..i]);
                    last = i+1;
                }

                if i == strlen-1 {
                    append(res.AcceptedExtensions, acceptedExtensions[last..i+1]);
                }
            } 
        }

        data := j32.FindData{};
        fmt.sprintf(buf[..0], "%s%s", path, path[len(path)-1] == '\\' ? "*" : "\\*");
        fileH := j32.FindFirstFile(^buf[0], ^data);
        res.FilesInFolder++;
        if fileH != win32.INVALID_HANDLE {
            for j32.FindNextFile(fileH, ^data) == win32.TRUE {
                nameBuf := make([]byte, len(data.FileName));
                copy(nameBuf, data.FileName[..]);
                str := strings.to_odin_string(^nameBuf[0]);
                for ext in res.AcceptedExtensions {
                    if _GetFileExtension(str) == ext {
                        file := ja.FileInfo_t{};
                        file.Name = _GetFileNameWithoutExtension(str);
                        pathBuf := make([]byte, j32.MAX_PATH);
                        file.Path = fmt.sprintf(pathBuf[..0], "%s%s", res.Path, str);
                        MAXDWORD :: 0xffffffff;
                        file.Size =  cast(u64)(cast(u64)data.FileSizeHigh * cast(u64)(MAXDWORD+1)) + cast(u64)data.FileSizeLow;
                        res.MaxSize += cast(uint)file.Size;
                        match kind {
                            case Kind.Texture : {
                                asset := ja.Asset.Texture{};
                                asset.FileInfo = file;
                                asset.LoadedFromDisk = false;
                                c_str := strings.new_c_string(file.Path); defer free(c_str);
                                stbi.info(c_str, ^asset.Width, ^asset.Height, ^asset.Comp);
                                res.Items[asset.FileInfo.Name] = asset;
                            }

                            case Kind.Shader : {
                                asset := ja.Asset.Shader{};
                                asset.FileInfo = file;
                                asset.LoadedFromDisk = false;

                                match ext {
                                    case ".vs" : {
                                        asset.Type = gl.ShaderTypes.Vertex;
                                    }
                                    case ".fs" : {
                                        asset.Type = gl.ShaderTypes.Fragment;
                                    }
                                }

                                res.Items[asset.FileInfo.Name] = asset;
                            }

                            case Kind.Sound : {
                                asset := ja.Asset.Sound{};
                                asset.FileInfo = file;
                                asset.LoadedFromDisk = false;
                                res.Items[asset.FileInfo.Name] = asset;
                            }
                        }

                        break;
                    }
                }
                res.FilesInFolder++;
            }
        } else {
            return nil, ERR_NO_FILES_FOUND;
        }

    } else {
        return nil, ERR_PATH_NOT_FOUND;
    }

    DebugInfo.NumberOfCatalogs++;
    append(DebugInfo.CatalogNames, res.Name);
    append(DebugInfo.Catalogs, res);
    return res, ERR_SUCCESS;
}

Find :: proc(catalog : ^Catalog, assetName : string) -> (ja.Asset, Err) {
    _, ok := catalog.Items[assetName];

    if ok {
        asset := catalog.Items[assetName];
        if !asset.LoadedFromDisk {
            match e in ^asset {
                case ja.Asset.Texture : {
                    if e.GLID == 0 {
                        c_str := strings.new_c_string(e.FileInfo.Path); defer free(c_str);
                        w, h, c : i32;
                        data := stbi.load(c_str, ^w, ^h, ^c, 0); defer stbi.image_free(data);
                        e.Width = w;
                        e.Height = h;
                        e.Comp = c;
                        e.GLID = gl.GenTexture();
                        gl.BindTexture(gl.TextureTargets.Texture2D, e.GLID);
                        gl.TexParameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.MinFilter, gl.TextureParametersValues.Linear);
                        gl.TexParameteri(gl.TextureTargets.Texture2D, gl.TextureParameters.MagFilter, gl.TextureParametersValues.Linear);
                        gl.TexImage2D(gl.TextureTargets.Texture2D, 0, gl.InternalColorFormat.RGBA, 
                                      e.Width, e.Height, gl.PixelDataFormat.RGBA, 
                                      gl.Texture2DDataType.UByte, data);
                    }
                }

                case ja.Asset.Shader : {
                    if !e.LoadedFromDisk {
                        e.LoadedFromDisk = true;
                        data, _ := os.read_entire_file(e.FileInfo.Path);
                        e.Data = data;
                        e.Source = strings.to_odin_string(^data[0]);
                        catalog.CurrentSize += cast(uint)len(data);
                    }

                    if e.GLID == 0 {
                        e.GLID, _ = glUtil.CreateAndCompileShader(e.Type, e.Source);
                    }
                }
            }
        }
        catalog.Items[assetName] = asset;
        return asset, ERR_SUCCESS;
    }

    return ja.Asset{}, ERR_ASSET_NOT_FOUND;
}

/////////////////////////////
//////// Util
_GetFileExtension :: proc(filename : string) -> string {
    strLen := len(filename);

    for i := strLen-1; i > 0; i-- {
        if filename[i] == '.' {
            res := filename[i..strLen];
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
    return filename[..(namelen-extlen)];
}

_IsDirectory :: proc(attr : u32) -> bool {
   return (cast(i32)attr != j32.INVALID_FILE_ATTRIBUTES) && 
          ((attr & j32.FILE_ATTRIBUTE_DIRECTORY) == j32.FILE_ATTRIBUTE_DIRECTORY);
}
