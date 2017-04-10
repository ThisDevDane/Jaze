#import "fmt.odin";
#import "strings.odin";
#import win32 "sys/windows.odin";
#import j32 "jaze_win32.odin";

Err :: int;

ERR_SUCCESS        : Err : 0;
ERR_PATH_NOT_FOUND : Err : 1;
ERR_NO_FILES_FOUND : Err : 2;

Catalog :: struct {
    Name : string,
    Items : map[string]File,
    AcceptedExtensions : [dynamic]string,
}

File :: struct {
    Name : string,
    Path : string,
}

CreateNew :: proc(path : string, acceptedExtensions : string) -> (Catalog, Err) {
    return CreateNew(path, path, acceptedExtensions);
}

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
    //TODO
    panic("WAA");
    return "";
}

_IsDirectory :: proc(attr : u32) -> bool {
   return (cast(i32)attr != j32.INVALID_FILE_ATTRIBUTES) && 
          ((attr & j32.FILE_ATTRIBUTE_DIRECTORY) == j32.FILE_ATTRIBUTE_DIRECTORY);
}

CreateNew :: proc(identifier : string, path : string, acceptedExtensions : string) -> (Catalog, Err) {
    res : Catalog;
    res.Name = identifier;

    //Check if path exists
    pstr := strings.new_c_string(path); defer free(pstr);
    attr := j32.GetFileAttributes(pstr);
    if _IsDirectory(attr) {

        if acceptedExtensions != "" {
            strlen := len(acceptedExtensions);
            last := 0;
            for i := 0; i < strlen; i++ {
                if acceptedExtensions[i] == ',' {
                    append(^res.AcceptedExtensions, acceptedExtensions[last..i]);
                    last = i+1;
                }

                if i == strlen-1 {
                    append(^res.AcceptedExtensions, acceptedExtensions[last..i+1]);
                }
            } 
        }

        

        data := j32.FindData{};
        buf : [1024]byte;
        fmt.sprintf(buf[..0], "%s%s", path, path[len(path)-1] == '\\' ? "*" : "\\*");
        fileH := j32.FindFirstFile(^buf[0], ^data);

        if fileH != win32.INVALID_HANDLE {
            for j32.FindNextFile(fileH, ^data) == win32.TRUE {
                str := strings.to_odin_string(^data.FileName[0]);
                for ext in res.AcceptedExtensions {
                    fmt.printf("Accepted: %s == %s : %s\n", _GetFileExtension(str), ext, _GetFileExtension(str) == ext ? "yes" : "no");
                }
            }
        } else {
            return Catalog{}, ERR_NO_FILES_FOUND;
        }

    } else {
        return Catalog{}, ERR_PATH_NOT_FOUND;
    }

    return res, ERR_SUCCESS;
}

Find :: proc(catalog : ^Catalog, filename : string) -> (any, Err) {
    return nil, ERR_SUCCESS;
}