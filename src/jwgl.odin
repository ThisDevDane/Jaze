#import win32 "sys/windows.odin";
#import win32wgl "sys/wgl.odin";
#import "gl.odin";
#import "fmt.odin";
#import "strings.odin";

Attrib :: struct {
    type  : i32,
    value : i32,
}

ACCELERATION_ARB_VALUES :: enum i32 {
    NO_ACCELERATION_ARB      = 0x2025,
    GENERIC_ACCELERATION_ARB = 0x2026,
    FULL_ACCELERATION_ARB    = 0x2027,
}

PIXEL_TYPE_ARB_VALUES :: enum i32 {
    RGBA_ARB = 0x202B,
    COLORINDEX_ARB = 0x202C,
}

CONTEXT_FLAGS_ARB_VALUES :: enum i32 {
    DEBUG_BIT_ARB = 0x0001,
    FORWARD_COMPATIBLE_BIT_ARB = 0x0002,
}

CONTEXT_PROFILE_MASK_ARB_VALUES :: enum i32 {
    CORE_PROFILE_BIT_ARB = 0x00000001,
    COMPATIBILITY_PROFILE_BIT_ARB = 0x00000002,
}

DRAW_TO_WINDOW_ARB :: proc(value : bool) -> Attrib {
    res : Attrib;
    res.type = 0x2001;
    res.value = cast(i32)value;
    return res;
}

DOUBLE_BUFFER_ARB  :: proc(value : bool) -> Attrib {
    res : Attrib;
    res.type = 0x2011;
    res.value = cast(i32)value;
    return res;
}

SUPPORT_OPENGL_ARB :: proc(value : bool) -> Attrib {
    res : Attrib;
    res.type = 0x2010;
    res.value = cast(i32)value;
    return res;
}

ACCELERATION_ARB   :: proc(value : ACCELERATION_ARB_VALUES) -> Attrib {
    res : Attrib;
    res.type = 0x2003;
    res.value = cast(i32)value;
    return res;
}

PIXEL_TYPE_ARB     :: proc(value : PIXEL_TYPE_ARB_VALUES) -> Attrib {
    res : Attrib;
    res.type = 0x2013;
    res.value = cast(i32)value;
    return res;
}

COLOR_BITS_ARB :: proc(value : i32) -> Attrib {
    res : Attrib;
    res.type = 0x2014;
    res.value = value;
    return res;
}

ALPHA_BITS_ARB :: proc(value : i32) -> Attrib {
    res : Attrib;
    res.type = 0x201B;
    res.value = value;
    return res;
}

DEPTH_BITS_ARB :: proc(value : i32) -> Attrib {
    res : Attrib;
    res.type = 0x2022;
    res.value = value;
    return res;
}

FRAMEBUFFER_SRGB_CAPABLE_ARB :: proc(value : bool) -> Attrib {
    res : Attrib;
    res.type = 0x20A9;
    res.value = cast(i32)value;
    return res;
}

CONTEXT_MAJOR_VERSION_ARB :: proc(value : i32) -> Attrib {
    res : Attrib;
    res.type = 0x2091;
    res.value = value;
    return res;
}

CONTEXT_MINOR_VERSION_ARB :: proc(value : i32) -> Attrib {
    res : Attrib;
    res.type = 0x2092;
    res.value = value;
    return res;
}

CONTEXT_FLAGS_ARB :: proc(value : CONTEXT_FLAGS_ARB_VALUES) -> Attrib {
    res : Attrib;
    res.type = 0x2094;
    res.value = cast(i32)value;
    return res;
}

CONTEXT_PROFILE_MASK_ARB :: proc(value : CONTEXT_PROFILE_MASK_ARB_VALUES) -> Attrib {
    res : Attrib;
    res.type = 0x9126;
    res.value = cast(i32)value;
    return res;
}

PrepareAttribArray :: proc(attribList : [dynamic]Attrib) -> [dynamic]i32 {
    array : [dynamic]i32;
    for attr in attribList {
        append(array, attr.type);
        append(array, attr.value);
    }

    append(array, 0);
    return array;
}

CreateContextAttribsARB_t :: #type proc(hdc : win32.Hdc, shareContext : win32wgl.Hglrc, attribList : ^i32) -> win32wgl.Hglrc #cc_c;
ChoosePixelFormatARB_t    :: #type proc(hdc : win32.Hdc, piAttribIList : ^i32, pfAttribFList : ^f32, nMaxFormats : u32, piFormats : ^i32, nNumFormats : ^u32) -> win32.Bool #cc_c;
SwapIntervalEXT_t         :: #type proc(interval : i32) -> bool #cc_c;
GetExtensionsStringARB_t  :: #type proc(win32.Hdc) -> ^byte #cc_c;

CreateContextAttribsARB : CreateContextAttribsARB_t;
ChoosePixelFormatARB    : ChoosePixelFormatARB_t;
SwapIntervalEXT         : SwapIntervalEXT_t;
GetExtensionsStringARB  : GetExtensionsStringARB_t;

TryGetExtensionList :: struct {
    Exts : map[string]rawptr,
}

TryGetExtension :: proc(list : ^TryGetExtensionList, p : rawptr, name : string) {
    list.Exts[name] = p;
}

LoadExtensions :: proc(GLContext : win32wgl.Hglrc, WindowDC : win32.Hdc, list : TryGetExtensionList) {
     if win32wgl.MakeCurrent(WindowDC, GLContext) == win32.TRUE {
        defer win32wgl.MakeCurrent(nil, nil);

        set_proc_address :: proc(p: rawptr, name : string) #inline { 
            txt := strings.new_c_string(name); defer free(txt);
            res := win32wgl.GetProcAddress(txt);
            assert(res != nil);
            (cast(^(proc() #cc_c))p)^ = res;
        }

        for val, key in list.Exts {
            set_proc_address(val, key);
        }
    }
}

GetInfo :: proc(vars : ^gl.OpenGLVars_t, dc : win32.Hdc) {
    wglExts := strings.to_odin_string(GetExtensionsStringARB(dc));
    s := 0;
    for r, i in wglExts {
        if r == ' ' {
            append(vars.WglExtensions, wglExts[s..i]);
            vars.NumWglExtensions += 1;
            s = i+1;
        }
    }
}