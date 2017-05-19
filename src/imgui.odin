/*
 *  @Name:     imgui
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 10-05-2017 21:11:30
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 20-05-2017 00:45:10
 *  
 *  @Description:
 *  
 */
#foreign_library "../external/cimgui.lib";
#import "fmt.odin";
#import "strings.odin";
 
DrawIdx   :: u16;
Wchar     :: u16;
TextureID :: rawptr;
GuiID     :: u32;

c_string  :: ^byte; // Just for clarity

GuiTextEditCallbackData :: struct #ordered {
    EventFlag      : GuiInputTextFlags,
    Flags          : GuiInputTextFlags,
    UserData       : rawptr,
    ReadOnly       : bool,
    EventChar      : Wchar,
    EventKey       : GuiKey,
    Buf            : c_string,
    BufTextLen     : i32,
    BufSize        : i32,
    BufDirty       : bool,
    CursorPos      : i32,
    SelectionStart : i32,
    SelectionEnd   : i32,
}

GuiSizeConstraintCallbackData :: struct #ordered {
    UserData    : rawptr,
    Pos         : Vec2,
    CurrentSize : Vec2,
    DesiredSize : Vec2,
}

DrawCmd :: struct #ordered {
    ElemCount        : u32,
    ClipRect         : Vec4,
    TextureId        : TextureID,
    UserCallback     : DrawCallback,
    UserCallbackData : rawptr,
}

Vec2 :: struct #ordered {
    x : f32,
    y : f32,
}

Vec4 :: struct #ordered {
    x : f32,
    y : f32,
    z : f32,
    w : f32,
}

DrawVert :: struct #ordered {
    pos : Vec2,
    uv  : Vec2,
    col : u32,
}

DrawData :: struct #ordered {
    Valid         : bool,
    CmdLists      : ^^DrawList,
    CmdListsCount : i32,
    TotalVtxCount : i32,
    TotalIdxCount : i32,
}

Font :: struct #ordered {}
GuiStorage :: struct #ordered {}
GuiContext :: struct #ordered {}
FontAtlas :: struct #ordered {}
DrawList :: struct #ordered {}

FontConfig :: struct #ordered {
    FontData                : rawptr,
    FontDataSize            : i32,
    FontDataOwnedByAtlas    : bool,
    FontNo                  : i32,
    SizePixels              : f32,
    OversampleH             : i32, OversampleV,
    PixelSnapH              : bool,
    GlyphExtraSpacing       : Vec2,
    GlyphRanges             : ^Wchar,
    MergeMode               : bool,
    MergeGlyphCenterV       : bool,
    Name                    : [32]byte,
    DstFont                 : ^Font,
};

GuiStyle :: struct #ordered {
    Alpha                   : f32,
    WindowPadding           : Vec2,
    WindowMinSize           : Vec2,
    WindowRounding          : f32,
    WindowTitleAlign        : GuiAlign,
    ChildWindowRounding     : f32,
    FramePadding            : Vec2,
    FrameRounding           : f32,
    ItemSpacing             : Vec2,
    ItemInnerSpacing        : Vec2,
    TouchExtraPadding       : Vec2,
    IndentSpacing           : f32,
    ColumnsMinSpacing       : f32,
    ScrollbarSize           : f32,
    ScrollbarRounding       : f32,
    GrabMinSize             : f32,
    GrabRounding            : f32,
    DisplayWindowPadding    : Vec2,
    DisplaySafeAreaPadding  : Vec2,
    AntiAliasedLines        : bool,
    AntiAliasedShapes       : bool,
    CurveTessellationTol    : f32,
    Colors                  : [GuiCol.COUNT]Vec4,
}

GuiIO :: struct #ordered {
    DisplaySize             : Vec2,
    DeltaTime               : f32,
    IniSavingRate           : f32,
    IniFilename             : c_string,
    LogFilename             : c_string,
    MouseDoubleClickTime    : f32,
    MouseDoubleClickMaxDist : f32,
    MouseDragThreshold      : f32,
    KeyMap                  : [GuiKey.COUNT]i32,
    KeyRepeatDelay          : f32,
    KeyRepeatRate           : f32,
    UserData                : rawptr,
    Fonts                   : ^FontAtlas, 
    FontGlobalScale         : f32,
    FontAllowUserScaling    : bool,
    DisplayFramebufferScale : Vec2,
    DisplayVisibleMin       : Vec2,
    DisplayVisibleMax       : Vec2,
    WordMovementUsesAltKey  : bool,
    ShortcutsUseSuperKey    : bool,
    DoubleClickSelectsWord  : bool,
    MultiSelectUsesSuperKey : bool,

    RenderDrawListsFn       : #type proc(data : ^DrawData) #cc_c,
    GetClipboardTextFn      : #type proc() -> c_string #cc_c,
    SetClipboardTextFn      : #type proc(text : c_string) #cc_c,
    MemAllocFn              : #type proc(sz : u64 /*size_t*/) -> rawptr #cc_c,
    MemFreeFn               : #type proc(ptr : rawptr) #cc_c,
    ImeSetInputScreenPosFn  : #type proc(x : i32, y : i32) #cc_c,

    ImeWindowHandle         : rawptr,
    MousePos                : Vec2,
    MouseDown               : [5]bool,
    MouseWheel              : f32,
    MouseDrawCursor         : bool,
    KeyCtrl                 : bool,
    KeyShift                : bool,
    KeyAlt                  : bool,
    KeySuper                : bool,
    KeysDown                : [512]bool,
    InputCharacters         : [16 + 1]Wchar,
    WantCaptureMouse        : bool,
    WantCaptureKeyboard     : bool,
    WantTextInput           : bool,
    Framerate               : f32,
    MetricsAllocs           : i32,
    MetricsRenderVertices   : i32,
    MetricsRenderIndices    : i32,
    MetricsActiveWindows    : i32,
    MousePosPrev            : Vec2,
    MouseDelta              : Vec2,
    MouseClicked            : [5]bool,
    MouseClickedPos         : [5]Vec2,
    MouseClickedTime        : [5]f32,
    MouseDoubleClicked      : [5]bool,
    MouseReleased           : [5]bool,
    MouseDownOwned          : [5]bool,
    MouseDownDuration       : [5]f32,
    MouseDownDurationPrev   : [5]f32,
    MouseDragMaxDistanceSqr : [5]f32,
    KeysDownDuration        : [512]f32,
    KeysDownDurationPrev    : [512]f32,
}

GuiTextEditCallback       :: #type proc(data : ^GuiTextEditCallbackData) -> i32 #cc_c;
GuiSizeConstraintCallback :: #type proc(data : ^GuiSizeConstraintCallbackData) #cc_c;
DrawCallback              :: #type proc(parent_list : ^DrawList, cmd : ^DrawCmd) #cc_c;

GuiWindowFlags :: enum i32 {
    NoTitleBar                = 1 << 0,
    NoResize                  = 1 << 1,
    NoMove                    = 1 << 2,
    NoScrollbar               = 1 << 3,
    NoScrollWithMouse         = 1 << 4,
    NoCollapse                = 1 << 5,
    AlwaysAutoResize          = 1 << 6,
    ShowBorders               = 1 << 7,
    NoSavedSettings           = 1 << 8,
    NoInputs                  = 1 << 9,
    MenuBar                   = 1 << 10,
    HorizontalScrollbar       = 1 << 11,
    NoFocusOnAppearing        = 1 << 12,
    NoBringToFrontOnFocus     = 1 << 13,
    AlwaysVerticalScrollbar   = 1 << 14,
    AlwaysHorizontalScrollbar = 1 << 15,
    AlwaysUseWindowPadding    = 1 << 16
}

GuiInputTextFlags :: enum i32 {
    CharsDecimal              = 1 << 0,
    CharsHexadecimal          = 1 << 1,
    CharsUppercase            = 1 << 2,
    CharsNoBlank              = 1 << 3,
    AutoSelectAll             = 1 << 4,
    EnterReturnsTrue          = 1 << 5,
    CallbackCompletion        = 1 << 6,
    CallbackHistory           = 1 << 7,
    CallbackAlways            = 1 << 8,
    CallbackCharFilter        = 1 << 9,
    AllowTabInput             = 1 << 10,
    CtrlEnterForNewLine       = 1 << 11,
    NoHorizontalScroll        = 1 << 12,
    AlwaysInsertMode          = 1 << 13,
    ReadOnly                  = 1 << 14,
    Password                  = 1 << 15
}

GuiTreeNodeFlags :: enum i32 {
    Selected                  = 1 << 0,
    Framed                    = 1 << 1,
    AllowOverlapMode          = 1 << 2,
    NoTreePushOnOpen          = 1 << 3,
    NoAutoOpenOnLog           = 1 << 4,
    DefaultOpen               = 1 << 5,
    OpenOnDoubleClick         = 1 << 6,
    OpenOnArrow               = 1 << 7,
    Leaf                      = 1 << 8,
    Bullet                    = 1 << 9,
    CollapsingHeader          = Framed | NoAutoOpenOnLog
}

GuiSelectableFlags :: enum {
    DontClosePopups           = 1 << 0,
    SpanAllColumns            = 1 << 1,
    AllowDoubleClick          = 1 << 2
}

GuiKey :: enum i32 {
    Tab,
    LeftArrow,
    RightArrow,
    UpArrow,
    DownArrow,
    PageUp,
    PageDown,
    Home,
    End,
    Delete,
    Backspace,
    Enter,
    Escape,
    A,
    C,
    V,
    X,
    Y,
    Z,
    COUNT
}

GuiCol :: enum i32 {
    Text,
    TextDisabled,
    WindowBg,
    ChildWindowBg,
    PopupBg,
    Border,
    BorderShadow,
    FrameBg,
    FrameBgHovered,
    FrameBgActive,
    TitleBg,
    TitleBgCollapsed,
    TitleBgActive,
    MenuBarBg,
    ScrollbarBg,
    ScrollbarGrab,
    ScrollbarGrabHovered,
    ScrollbarGrabActive,
    ComboBg,
    CheckMark,
    SliderGrab,
    SliderGrabActive,
    Button,
    ButtonHovered,
    ButtonActive,
    Header,
    HeaderHovered,
    HeaderActive,
    Column,
    ColumnHovered,
    ColumnActive,
    ResizeGrip,
    ResizeGripHovered,
    ResizeGripActive,
    CloseButton,
    CloseButtonHovered,
    CloseButtonActive,
    PlotLines,
    PlotLinesHovered,
    PlotHistogram,
    PlotHistogramHovered,
    TextSelectedBg,
    ModalWindowDarkening,
    COUNT
}

GuiStyleVar :: enum i32 {
    Alpha,
    WindowPadding,
    WindowRounding,
    WindowMinSize,
    ChildWindowRounding,
    FramePadding,
    FrameRounding,
    ItemSpacing,
    ItemInnerSpacing,
    IndentSpacing,
    GrabMinSize
}

GuiAlign :: enum i32 {
    Left     = 1 << 0,
    Center   = 1 << 1,
    Right    = 1 << 2,
    Top      = 1 << 3,
    VCenter  = 1 << 4,
    Default  = Left | Top
}

GuiColorEditMode :: enum i32 {
    UserSelect = -2,
    UserSelectShowButton = -1,
    RGB = 0,
    HSV = 1,
    HEX = 2
}

GuiMouseCursor :: enum i32 {
    Arrow = 0,
    TextInput,
    Move,
    ResizeNS,
    ResizeEW,
    ResizeNESW,
    ResizeNWSE,
    Count_
}

GuiSetCond :: enum i32 {
    Always        = 1 << 0,
    Once          = 1 << 1,
    FirstUseEver  = 1 << 2,
    Appearing     = 1 << 3
}

/////////// Functions ////////////////////////
GetIO                                                   :: proc() -> ^GuiIO                                                                                                                                                                                                    #foreign cimgui "igGetIO";
GetStyle                                                :: proc() -> ^GuiStyle                                                                                                                                                                                                 #foreign cimgui "igGetStyle";
GetDrawData                                             :: proc() -> ^DrawData                                                                                                                                                                                                 #foreign cimgui "igGetDrawData";
NewFrame                                                :: proc()                                                                                                                                                                                                              #foreign cimgui "igNewFrame";
Render                                                  :: proc()                                                                                                                                                                                                              #foreign cimgui "igRender";
Shutdown                                                :: proc()                                                                                                                                                                                                              #foreign cimgui "igShutdown";
ShowUserGuide                                           :: proc()                                                                                                                                                                                                              #foreign cimgui "igShowUserGuide";
ShowStyleEditor                                         :: proc(ref : ^GuiStyle)                                                                                                                                                                                               #foreign cimgui "igShowStyleEditor";
ShowTestWindow                                          :: proc(opened : ^bool)                                                                                                                                                                                                #foreign cimgui "igShowTestWindow";
ShowMetricsWindow                                       :: proc(opened : ^bool)                                                                                                                                                                                                #foreign cimgui "igShowMetricsWindow";

// Window
Begin :: proc(name : string, open : ^bool, flags : GuiWindowFlags) -> bool{
    ImBegin :: proc(name : c_string, p_open : ^bool, flags : GuiWindowFlags) -> bool #foreign cimgui "igBegin";

    str := strings.new_c_string(name); defer free(str);
    return ImBegin(str, open, flags);
}
//Begin                                                   :: proc(name : c_string, p_open : ^bool, size_on_first_use : Vec2, bg_alpha : f32, flags : GuiWindowFlags) -> bool                                                                                                     #foreign cimgui "igBegin2";
End                                                     :: proc()                                                                                                                                                                                                              #foreign cimgui "igEnd";
BeginChild :: proc(str_id : string, size : Vec2, border : bool, extra_flags : GuiWindowFlags) -> bool {
    ImBeginChild :: proc(str_id : c_string, size : Vec2, border : bool, extra_flags : GuiWindowFlags) -> bool #foreign cimgui "igBeginChild";
    str := strings.new_c_string(str_id); defer free(str);
    return ImBeginChild(str, size, border, extra_flags);
}

//BeginChild                                              :: proc(str_id : c_string, size : Vec2, border : bool, extra_flags : GuiWindowFlags) -> bool                                                                                                                           #foreign cimgui "igBeginChild";
BeginChildEx                                            :: proc(id : GuiID, size : Vec2, border : bool, extra_flags : GuiWindowFlags) -> bool                                                                                                                                  #foreign cimgui "igBeginChildEx";
EndChild                                                :: proc()                                                                                                                                                                                                              #foreign cimgui "igEndChild";
GetContentRegionMax                                     :: proc(out : ^Vec2)                                                                                                                                                                                                   #foreign cimgui "igGetContentRegionMax";
GetContentRegionAvail                                   :: proc(out : ^Vec2)                                                                                                                                                                                                   #foreign cimgui "igGetContentRegionAvail";
GetContentRegionAvailWidth                              :: proc() -> f32                                                                                                                                                                                                       #foreign cimgui "igGetContentRegionAvailWidth";
GetWindowContentRegionMin                               :: proc(out : ^Vec2)                                                                                                                                                                                                   #foreign cimgui "igGetWindowContentRegionMin";
GetWindowContentRegionMax                               :: proc(out : ^Vec2)                                                                                                                                                                                                   #foreign cimgui "igGetWindowContentRegionMax";
GetWindowContentRegionWidth                             :: proc() -> f32                                                                                                                                                                                                       #foreign cimgui "igGetWindowContentRegionWidth";
GetWindowDrawList                                       :: proc() -> ^DrawList                                                                                                                                                                                                 #foreign cimgui "igGetWindowDrawList";
GetWindowPos                                            :: proc(out : ^Vec2)                                                                                                                                                                                                   #foreign cimgui "igGetWindowPos";
GetWindowSize                                           :: proc(out : ^Vec2)                                                                                                                                                                                                   #foreign cimgui "igGetWindowSize";
GetWindowWidth                                          :: proc() -> f32                                                                                                                                                                                                       #foreign cimgui "igGetWindowWidth";
GetWindowHeight                                         :: proc() -> f32                                                                                                                                                                                                       #foreign cimgui "igGetWindowHeight";
IsWindowCollapsed                                       :: proc() -> bool                                                                                                                                                                                                      #foreign cimgui "igIsWindowCollapsed";
SetWindowFontScale                                      :: proc(scale : f32)                                                                                                                                                                                                   #foreign cimgui "igSetWindowFontScale";

SetNextWindowPos                                        :: proc(pos : Vec2, cond : GuiSetCond)                                                                                                                                                                                 #foreign cimgui "igSetNextWindowPos";
SetNextWindowPosCenter                                  :: proc(cond : GuiSetCond)                                                                                                                                                                                             #foreign cimgui "igSetNextWindowPosCenter";
SetNextWindowSize                                       :: proc(size : Vec2, cond : GuiSetCond)                                                                                                                                                                                #foreign cimgui "igSetNextWindowSize";
SetNextWindowSizeConstraints                            :: proc(size_min : Vec2, size_max : Vec2, custom_callback : GuiSizeConstraintCallback, custom_callback_data : rawptr)                                                                                                  #foreign cimgui "igSetNextWindowSizeConstraints";
SetNextWindowContentSize                                :: proc(size : Vec2)                                                                                                                                                                                                   #foreign cimgui "igSetNextWindowContentSize";
SetNextWindowContentWidth                               :: proc(width : f32)                                                                                                                                                                                                   #foreign cimgui "igSetNextWindowContentWidth";
SetNextWindowCollapsed                                  :: proc(collapsed : bool, cond : GuiSetCond)                                                                                                                                                                           #foreign cimgui "igSetNextWindowCollapsed";
SetNextWindowFocus                                      :: proc()                                                                                                                                                                                                              #foreign cimgui "igSetNextWindowFocus";
SetWindowPos                                            :: proc(pos : Vec2, cond : GuiSetCond)                                                                                                                                                                                 #foreign cimgui "igSetWindowPos";
SetWindowSize                                           :: proc(size : Vec2, cond : GuiSetCond)                                                                                                                                                                                #foreign cimgui "igSetWindowSize";
SetWindowCollapsed                                      :: proc(collapsed : bool, cond : GuiSetCond)                                                                                                                                                                           #foreign cimgui "igSetWindowCollapsed";
SetWindowFocus                                          :: proc()                                                                                                                                                                                                              #foreign cimgui "igSetWindowFocus";
SetWindowPosByName                                      :: proc(name : c_string, pos : Vec2, cond : GuiSetCond)                                                                                                                                                                #foreign cimgui "igSetWindowPosByName";
SetWindowSize2                                          :: proc(name : c_string, size : Vec2, cond : GuiSetCond)                                                                                                                                                               #foreign cimgui "igSetWindowSize2";
SetWindowCollapsed2                                     :: proc(name : c_string, collapsed : bool, cond : GuiSetCond)                                                                                                                                                          #foreign cimgui "igSetWindowCollapsed2";
SetWindowFocus2                                         :: proc(name : c_string)                                                                                                                                                                                               #foreign cimgui "igSetWindowFocus2";

GetScrollX                                              :: proc() -> f32                                                                                                                                                                                                       #foreign cimgui "igGetScrollX";
GetScrollY                                              :: proc() -> f32                                                                                                                                                                                                       #foreign cimgui "igGetScrollY";
GetScrollMaxX                                           :: proc() -> f32                                                                                                                                                                                                       #foreign cimgui "igGetScrollMaxX";
GetScrollMaxY                                           :: proc() -> f32                                                                                                                                                                                                       #foreign cimgui "igGetScrollMaxY";
SetScrollX                                              :: proc(scroll_x : f32)                                                                                                                                                                                                #foreign cimgui "igSetScrollX";
SetScrollY                                              :: proc(scroll_y : f32)                                                                                                                                                                                                #foreign cimgui "igSetScrollY";
SetScrollHere                                           :: proc(center_y_ratio : f32)                                                                                                                                                                                          #foreign cimgui "igSetScrollHere";
SetScrollFromPosY                                       :: proc(pos_y : f32, center_y_ratio : f32)                                                                                                                                                                             #foreign cimgui "igSetScrollFromPosY";
SetKeyboardFocusHere                                    :: proc(offset : i32)                                                                                                                                                                                                  #foreign cimgui "igSetKeyboardFocusHere";
SetStateStorage                                         :: proc(tree : ^GuiStorage)                                                                                                                                                                                            #foreign cimgui "igSetStateStorage";
GetStateStorage                                         :: proc() -> ^GuiStorage                                                                                                                                                                                               #foreign cimgui "igGetStateStorage";

// Parameters stacks (shared)
PushFont                                                :: proc(font : ^Font)                                                                                                                                                                                                  #foreign cimgui "igPushFont";
PopFont                                                 :: proc()                                                                                                                                                                                                              #foreign cimgui "igPopFont";
PushStyleColor                                          :: proc(idx : GuiCol, col : Vec4)                                                                                                                                                                                      #foreign cimgui "igPushStyleColor";
PopStyleColor                                           :: proc(count : i32)                                                                                                                                                                                                   #foreign cimgui "igPopStyleColor";
PushStyleVar                                            :: proc(idx : GuiStyleVar, val : f32)                                                                                                                                                                                  #foreign cimgui "igPushStyleVar";
PushStyleVarVec                                         :: proc(idx : GuiStyleVar, val : Vec2)                                                                                                                                                                                 #foreign cimgui "igPushStyleVarVec";
PopStyleVar                                             :: proc(count : i32)                                                                                                                                                                                                   #foreign cimgui "igPopStyleVar";
GetFont                                                 :: proc() -> ^Font                                                                                                                                                                                                     #foreign cimgui "igGetFont";
GetFontSize                                             :: proc() -> f32                                                                                                                                                                                                       #foreign cimgui "igGetFontSize";
GetFontTexUvWhitePixel                                  :: proc(pOut : ^Vec2)                                                                                                                                                                                                  #foreign cimgui "igGetFontTexUvWhitePixel";
GetColorU32                                             :: proc(idx : GuiCol, alpha_mul : f32) -> u32                                                                                                                                                                          #foreign cimgui "igGetColorU32";
GetColorU32Vec                                          :: proc(col : ^Vec4) -> u32                                                                                                                                                                                            #foreign cimgui "igGetColorU32Vec";

// Parameters stacks (current window)
PushItemWidth                                           :: proc(item_width : f32)                                                                                                                                                                                              #foreign cimgui "igPushItemWidth";
PopItemWidth                                            :: proc()                                                                                                                                                                                                              #foreign cimgui "igPopItemWidth";
CalcItemWidth                                           :: proc() -> f32                                                                                                                                                                                                       #foreign cimgui "igCalcItemWidth";
PushTextWrapPos                                         :: proc(wrap_pos_x : f32)                                                                                                                                                                                              #foreign cimgui "igPushTextWrapPos";
PopTextWrapPos                                          :: proc()                                                                                                                                                                                                              #foreign cimgui "igPopTextWrapPos";
PushAllowKeyboardFocus                                  :: proc(v : bool)                                                                                                                                                                                                      #foreign cimgui "igPushAllowKeyboardFocus";
PopAllowKeyboardFocus                                   :: proc()                                                                                                                                                                                                              #foreign cimgui "igPopAllowKeyboardFocus";
PushButtonRepeat                                        :: proc(repeat : bool)                                                                                                                                                                                                 #foreign cimgui "igPushButtonRepeat";
PopButtonRepeat                                         :: proc()                                                                                                                                                                                                              #foreign cimgui "igPopButtonRepeat";

// Layout
Separator                                               :: proc()                                                                                                                                                                                                              #foreign cimgui "igSeparator";
SameLine                                                :: proc(pos_x : f32, spacing_w : f32)                                                                                                                                                                                  #foreign cimgui "igSameLine";
NewLine                                                 :: proc()                                                                                                                                                                                                              #foreign cimgui "igNewLine";
Spacing                                                 :: proc()                                                                                                                                                                                                              #foreign cimgui "igSpacing";
Dummy                                                   :: proc(size : ^Vec2)                                                                                                                                                                                                  #foreign cimgui "igDummy";
Indent                                                  :: proc(indent_w : f32)                                                                                                                                                                                                #foreign cimgui "igIndent";
Unindent                                                :: proc(indent_w : f32)                                                                                                                                                                                                #foreign cimgui "igUnindent";
BeginGroup                                              :: proc()                                                                                                                                                                                                              #foreign cimgui "igBeginGroup";
EndGroup                                                :: proc()                                                                                                                                                                                                              #foreign cimgui "igEndGroup";
GetCursorPos                                            :: proc(pOut : ^Vec2)                                                                                                                                                                                                  #foreign cimgui "igGetCursorPos";
GetCursorPosX                                           :: proc() -> f32                                                                                                                                                                                                       #foreign cimgui "igGetCursorPosX";
GetCursorPosY                                           :: proc() -> f32                                                                                                                                                                                                       #foreign cimgui "igGetCursorPosY";
SetCursorPos                                            :: proc(local_pos : Vec2)                                                                                                                                                                                              #foreign cimgui "igSetCursorPos";
SetCursorPosX                                           :: proc(x : f32)                                                                                                                                                                                                       #foreign cimgui "igSetCursorPosX";
SetCursorPosY                                           :: proc(y : f32)                                                                                                                                                                                                       #foreign cimgui "igSetCursorPosY";
GetCursorStartPos                                       :: proc(pOut : ^Vec2)                                                                                                                                                                                                  #foreign cimgui "igGetCursorStartPos";
GetCursorScreenPos                                      :: proc(pOut : ^Vec2)                                                                                                                                                                                                  #foreign cimgui "igGetCursorScreenPos";
SetCursorScreenPos                                      :: proc(pos : Vec2)                                                                                                                                                                                                    #foreign cimgui "igSetCursorScreenPos";
AlignFirstTextHeightToWidgets                           :: proc()                                                                                                                                                                                                              #foreign cimgui "igAlignFirstTextHeightToWidgets";
GetTextLineHeight                                       :: proc() -> f32                                                                                                                                                                                                       #foreign cimgui "igGetTextLineHeight";
GetTextLineHeightWithSpacing                            :: proc() -> f32                                                                                                                                                                                                       #foreign cimgui "igGetTextLineHeightWithSpacing";
GetItemsLineHeightWithSpacing                           :: proc() -> f32                                                                                                                                                                                                       #foreign cimgui "igGetItemsLineHeightWithSpacing";

//Columns
Columns                                                 :: proc(count : i32, id : c_string, border : bool)                                                                                                                                                                     #foreign cimgui "igColumns";
NextColumn                                              :: proc()                                                                                                                                                                                                              #foreign cimgui "igNextColumn";
GetColumnIndex                                          :: proc() -> i32                                                                                                                                                                                                       #foreign cimgui "igGetColumnIndex";
GetColumnOffset                                         :: proc(column_index : i32) -> f32                                                                                                                                                                                     #foreign cimgui "igGetColumnOffset";
SetColumnOffset                                         :: proc(column_index : i32, offset_x : f32)                                                                                                                                                                            #foreign cimgui "igSetColumnOffset";
GetColumnWidth                                          :: proc(column_index : i32) -> f32                                                                                                                                                                                     #foreign cimgui "igGetColumnWidth";
GetColumnsCount                                         :: proc() -> i32                                                                                                                                                                                                       #foreign cimgui "igGetColumnsCount";

// ID scopes
// If you are creating widgets in a loop you most likely want to push a unique identifier so ImGui can differentiate them
// You can also use "##extra" within your widget name to distinguish them from each others (see 'Programmer Guide')
PushIdStr                                               :: proc(str_id : c_string)                                                                                                                                                                                             #foreign cimgui "igPushIdStr";
PushIdStrRange                                          :: proc(str_begin : c_string, str_end : c_string)                                                                                                                                                                      #foreign cimgui "igPushIdStrRange";
PushIdPtr                                               :: proc(ptr_id : rawptr)                                                                                                                                                                                               #foreign cimgui "igPushIdPtr";
PushIdInt                                               :: proc(int_id : i32)                                                                                                                                                                                                  #foreign cimgui "igPushIdInt";
PopId                                                   :: proc()                                                                                                                                                                                                              #foreign cimgui "igPopId";
GetIdStr                                                :: proc(str_id : c_string) -> GuiID                                                                                                                                                                                    #foreign cimgui "igGetIdStr";
GetIdStrRange                                           :: proc(str_begin : c_string, str_end : c_string) -> GuiID                                                                                                                                                             #foreign cimgui "igGetIdStrRange";
GetIdPtr                                                :: proc(ptr_id : rawptr) -> GuiID                                                                                                                                                                                      #foreign cimgui "igGetIdPtr";

/// FUNCTIONS SIGNATURES!!!! TODO!!!
// Widgets

BUF_SIZE :: 4096;

// Bill says this might work as a workaround
Text :: proc(fmt_: string, args: ..any) {
    ImText :: proc(fmt: ^byte) #cc_c #foreign cimgui "igText"; 

    buf: [BUF_SIZE]byte;
    s := fmt.bprintf(buf[..], fmt_, ..args);

    ImText(&buf[0]);
}

TextColored :: proc(col : Vec4, fmt_: string, args: ..any) {
    ImTextColored :: proc(col : Vec4, fmt : ^byte) #cc_c #foreign cimgui "igTextColored";

    buf: [BUF_SIZE]byte;
    s := fmt.bprintf(buf[..], fmt_, ..args);

    ImTextColored(col, &buf[0]);
}
/*
TextDisabled                                            :: proc(CONST char* fmt, ...)                                                                                                                                                                                          #foreign cimgui "igTextDisabled";
*/
TextWrapped :: proc(fmt_: string, args: ..any) {
    ImTextWrapped :: proc(fmt: ^byte) #foreign cimgui "igTextWrapped";

    buf: [BUF_SIZE]byte;
    //NOTE(Bill): Crashing inside this.
    s := fmt.bprintf(buf[..], fmt_, ..args);

    ImTextWrapped(&buf[0]);
}

TextUnformatted                                         :: proc(text : c_string, text_end : c_string)                                                                                                                                                                          #foreign cimgui "igTextUnformatted";
/*
LabelText                                               :: proc(CONST char* label, CONST char* fmt, ...)                                                                                                                                                                       #foreign cimgui "igLabelText";
*/
Bullet                                                  :: proc()                                                                                                                                                                                                              #foreign cimgui "igBullet";
/*
BulletText                                              :: proc(CONST char* fmt, ...)                                                                                                                                                                                          #foreign cimgui "igBulletText";
*/

Button :: proc(label : string, size : Vec2) -> bool {
    ImButton :: proc(label : c_string, size : Vec2) -> bool #foreign cimgui "igButton";
    str := strings.new_c_string(label); defer free(str);
    return ImButton(str, size);
}

SmallButton :: proc(label : string) -> bool {
    ImSmallButton :: proc(label : c_string) -> bool #foreign cimgui "igSmallButton";
    str := strings.new_c_string(label); defer free(str);
    return ImSmallButton(str);
}
InvisibleButton                                         :: proc(str_id : c_string, size : Vec2) -> bool                                                                                                                                                                        #foreign cimgui "igInvisibleButton";
Image :: proc(user_texture_id : TextureID, size : Vec2, uv0 : Vec2, uv1 : Vec2, tint_col : Vec4, border_col : Vec4) #foreign cimgui "igImage";


ImageButton                                             :: proc(user_texture_id : TextureID, size : Vec2, uv0 : Vec2, uv1 : Vec2, frame_padding : i32, bg_col : Vec4, tint_col : Vec4) -> bool                                                                                 #foreign cimgui "igImageButton";
Checkbox :: proc(label : string, v : ^bool) -> bool {
    ImCheckbox :: proc(label : c_string, v : ^bool) -> bool #foreign cimgui "igCheckbox";
    str := strings.new_c_string(label); defer free(str);
    return ImCheckbox(str, v);
}
CheckboxFlags                                           :: proc(label : c_string, flags : ^u32, flags_value : u32) -> bool                                                                                                                                                   #foreign cimgui "igCheckboxFlags";
RadioButtonBool                                         :: proc(label : c_string, active : bool) -> bool                                                                                                                                                                       #foreign cimgui "igRadioButtonBool";
RadioButton                                             :: proc(label : c_string, v : ^i32, v_button : i32) -> bool                                                                                                                                                            #foreign cimgui "igRadioButton";
Combo :: proc(label : string, current_item : ^i32, items : []string, height_in_items : i32) -> bool {
     ImCombo :: proc(label : c_string, current_item : ^i32, items : ^^byte, items_count : i32, height_in_items : i32) -> bool #foreign cimgui "igCombo";
     str := strings.new_c_string(label); defer free(str);

     data := make([]^byte, len(items)); defer free(data);
     for item, idx in items {
        data[idx] = strings.new_c_string(item);
     }

     return ImCombo(str, current_item, &data[0], i32(len(items)), height_in_items); 
}
Combo2                                                  :: proc(label : c_string, current_item : ^i32, items_separated_by_zeros : c_string, height_in_items : i32) -> bool                                                                                                     #foreign cimgui "igCombo2";
Combo3                                                  :: proc(label : c_string, current_item : ^i32, items_getter : proc(data : rawptr, idx : i32, out_text : ^^byte) -> bool #cc_c, data : rawptr, items_count : i32, height_in_items : i32) -> bool                        #foreign cimgui "igCombo3";
ColorButton                                             :: proc(col : Vec4, small_height : bool, outline_border : bool) -> bool                                                                                                                                                #foreign cimgui "igColorButton";
ColorEdit3                                              :: proc(label : c_string, col : [3]f32) -> bool                                                                                                                                                                        #foreign cimgui "igColorEdit3";
ColorEdit4                                              :: proc(label : c_string, col : [4]f32, show_alpha : bool) -> bool                                                                                                                                                     #foreign cimgui "igColorEdit4";
ColorEditMode                                           :: proc(mode : GuiColorEditMode)                                                                                                                                                                                       #foreign cimgui "igColorEditMode";
PlotLines                                               :: proc(label : c_string, values : ^f32, values_count : i32, values_offset : i32, overlay_text : c_string, scale_min : f32, scale_max : f32, graph_size : Vec2, stride : i32)                                          #foreign cimgui "igPlotLines";
PlotLines2                                              :: proc(label : c_string, values_getter : proc(data : rawptr, idx : i32) -> f32, data : rawptr, values_count : i32, values_offset : i32, overlay_text : c_string, scale_min : f32, scale_max : f32, graph_size : Vec2) #foreign cimgui "igPlotLines2";
PlotHistogram                                           :: proc(label : c_string, values : ^f32, values_count : i32, values_offset : i32, overlay_text : c_string, scale_min : f32, scale_max : f32, graph_size : Vec2, stride : i32)                                          #foreign cimgui "igPlotHistogram";
PlotHistogram2                                          :: proc(label : c_string, values_getter : proc(data : rawptr, idx : i32) -> f32, data : rawptr, values_count : i32, values_offset : i32, overlay_text : c_string, scale_min : f32, scale_max : f32, graph_size : Vec2) #foreign cimgui "igPlotHistogram2";
ProgressBar                                             :: proc(fraction : f32, size_arg : ^Vec2, overlay : c_string)                                                                                                                                                          #foreign cimgui "igProgressBar";

// Widgets: Sliders (tip: ctrl+click on a slider to input text)
SliderFloat                                             :: proc(label : c_string, v : ^f32, v_min : f32, v_max : f32, display_format : c_string, power : f32) -> bool                                                                                                          #foreign cimgui "igSliderFloat";
SliderFloat2                                            :: proc(label : c_string, v : [2]f32, v_min : f32, v_max : f32, display_format : c_string, power : f32) -> bool                                                                                                        #foreign cimgui "igSliderFloat2";
SliderFloat3                                            :: proc(label : c_string, v : [3]f32, v_min : f32, v_max : f32, display_format : c_string, power : f32) -> bool                                                                                                        #foreign cimgui "igSliderFloat3";
SliderFloat4                                            :: proc(label : c_string, v : [4]f32, v_min : f32, v_max : f32, display_format : c_string, power : f32) -> bool                                                                                                        #foreign cimgui "igSliderFloat4";
SliderAngle                                             :: proc(label : c_string, v_rad : ^f32, v_degrees_min : f32, v_degrees_max : f32) -> bool                                                                                                                              #foreign cimgui "igSliderAngle";
SliderInt                                               :: proc(label : c_string, v : ^i32, v_min : i32, v_max : i32, display_format : c_string) -> bool                                                                                                                       #foreign cimgui "igSliderInt";
SliderInt2                                              :: proc(label : c_string, v : [2]i32, v_min : i32, v_max : i32, display_format : c_string) -> bool                                                                                                                     #foreign cimgui "igSliderInt2";
SliderInt3                                              :: proc(label : c_string, v : [3]i32, v_min : i32, v_max : i32, display_format : c_string) -> bool                                                                                                                     #foreign cimgui "igSliderInt3";
SliderInt4                                              :: proc(label : c_string, v : [4]i32, v_min : i32, v_max : i32, display_format : c_string) -> bool                                                                                                                     #foreign cimgui "igSliderInt4";
VSliderFloat                                            :: proc(label : c_string, size : Vec2, v : ^f32, v_min : f32 , v_max : f32, display_format : c_string, power : f32) -> bool                                                                                            #foreign cimgui "igVSliderFloat";
VSliderInt                                              :: proc(label : c_string, size : Vec2, v : ^i32, v_min : i32, v_max : i32, display_format : c_string) -> bool                                                                                                          #foreign cimgui "igVSliderInt";

// Widgets: Drags                                         :: proc(tip: ctrl+click on a drag box to input text)
DragFloat :: proc(label : string, v : ^f32, v_speed : f32, v_min : f32, v_max : f32, display_format : string, power : f32) {
    ImDragFloat :: proc(label : c_string, v : ^f32, v_speed : f32, v_min : f32, v_max : f32, display_format : c_string, power : f32) #foreign cimgui "igDragFloat";

    str := strings.new_c_string(label); defer free(str);
    fstr := strings.new_c_string(display_format); defer free(fstr);
    ImDragFloat(str, v, v_speed, v_min, v_max, fstr, power);
}

DragFloat2                                              :: proc(label : c_string, v : [2]f32, v_speed : f32, v_min : f32, v_max : f32, display_format : c_string, power : f32) -> bool                                                                                         #foreign cimgui "igDragFloat2";

DragFloat3 :: proc(label : string, v : ^[3]f32, v_speed : f32, v_min : f32, v_max : f32, display_format : string, power : f32) -> bool {
    ImDragFloat3 :: proc(label : c_string, v : ^f32, v_speed : f32, v_min : f32, v_max : f32, display_format : c_string, power : f32) -> bool #foreign cimgui "igDragFloat3";

    str := strings.new_c_string(label); defer free(str);
    fstr := strings.new_c_string(display_format); defer free(fstr);
    return ImDragFloat3(str, &v[0], v_speed, v_min, v_max, fstr, power);
}

DragFloat4                                              :: proc(label : c_string, v : [4]f32, v_speed : f32, v_min : f32, v_max : f32, display_format : c_string, power : f32) -> bool                                                                                         #foreign cimgui "igDragFloat4";
DragFloatRange2                                         :: proc(label : c_string, v_current_min : ^f32, v_current_max : ^f32, v_speed : f32, v_min : f32, v_max : f32, display_format : c_string, display_format_max : c_string, power : f32) -> bool                          #foreign cimgui "igDragFloatRange2";
DragInt                                                 :: proc(label : c_string, v : ^i32, v_speed : f32, v_min : i32, v_max : i32, display_format : c_string)                                                                                                                #foreign cimgui "igDragInt";
DragInt2                                                :: proc(label : c_string, v : [2]i32, v_speed : f32, v_min : i32, v_max : i32, display_format : c_string) -> bool                                                                                                      #foreign cimgui "igDragInt2";
DragInt3                                                :: proc(label : c_string, v : [3]i32, v_speed : f32, v_min : i32, v_max : i32, display_format : c_string) -> bool                                                                                                      #foreign cimgui "igDragInt3";
DragInt4                                                :: proc(label : c_string, v : [4]i32, v_speed : f32, v_min : i32, v_max : i32, display_format : c_string) -> bool                                                                                                      #foreign cimgui "igDragInt4";
DragIntRange2                                           :: proc(label : c_string, v_current_min : ^i32, v_current_max : ^i32, v_speed : f32, v_min : i32, v_max : i32, display_format : c_string, display_format_max : c_string) -> bool                                       #foreign cimgui "igDragIntRange2";

// Widgets: Input
InputText :: proc(label : string, buf : []byte, flags : GuiInputTextFlags, callback : GuiTextEditCallback, user_data : rawptr) -> bool {
    ImInputText :: proc(label : c_string, buf : c_string, buf_size : u64 /*size_t*/, flags : GuiInputTextFlags, callback : GuiTextEditCallback, user_data : rawptr) -> bool #foreign cimgui "igInputText";
    str := strings.new_c_string(label); defer free(str);
    return ImInputText(str, &buf[0], u64(len(buf)), flags, callback, user_data);
}
InputTextMultiline                                      :: proc(label : c_string, buf : c_string, buf_size : u64 /*size_t*/, size : Vec2, flags : GuiInputTextFlags, callback : GuiTextEditCallback, user_data : rawptr) -> bool                                               #foreign cimgui "igInputTextMultiline";
InputFloat                                              :: proc(label : c_string, v : ^f32, step : f32, step_fast : f32, decimal_precision : i32, extra_flags : GuiInputTextFlags) -> bool                                                                                     #foreign cimgui "igInputFloat";
InputFloat2                                             :: proc(label : c_string, v : [2]f32, decimal_precision : i32, extra_flags : GuiInputTextFlags) -> bool                                                                                                                #foreign cimgui "igInputFloat2";
InputFloat3                                             :: proc(label : c_string, v : [3]f32, decimal_precision : i32, extra_flags : GuiInputTextFlags) -> bool                                                                                                                #foreign cimgui "igInputFloat3";
InputFloat4                                             :: proc(label : c_string, v : [4]f32, decimal_precision : i32, extra_flags : GuiInputTextFlags) -> bool                                                                                                                #foreign cimgui "igInputFloat4";
InputInt                                                :: proc(label : c_string, v : ^i32, step : i32, step_fast : i32, extra_flags : GuiInputTextFlags) -> bool                                                                                                              #foreign cimgui "igInputInt";
InputInt2                                               :: proc(label : c_string, v : [2]i32, extra_flags : GuiInputTextFlags) -> bool                                                                                                                                         #foreign cimgui "igInputInt2";
InputInt3                                               :: proc(label : c_string, v : [3]i32, extra_flags : GuiInputTextFlags) -> bool                                                                                                                                         #foreign cimgui "igInputInt3";
InputInt4                                               :: proc(label : c_string, v : [4]i32, extra_flags : GuiInputTextFlags) -> bool                                                                                                                                         #foreign cimgui "igInputInt4";

// Widgets: Trees
TreeNode                                                :: proc(label : c_string) -> bool                                                                                                                                                                                      #foreign cimgui "igTreeNode";
/*
TreeNodeStr                                             :: proc(CONST char* str_id, CONST char* fmt, ...) -> bool                                                                                                                                                              #foreign cimgui "igTreeNodeStr";
TreeNodePtr                                             :: proc(CONST void* ptr_id, CONST char* fmt, ...) -> bool                                                                                                                                                              #foreign cimgui "igTreeNodePtr";
TreeNodeStrV                                            :: proc(CONST char* str_id, CONST char* fmt, va_list args) -> bool                                                                                                                                                     #foreign cimgui "igTreeNodeStrV";
TreeNodePtrV                                            :: proc(CONST void* ptr_id, CONST char* fmt, va_list args) -> bool                                                                                                                                                     #foreign cimgui "igTreeNodePtrV";
*/
TreeNodeEx                                              :: proc(label : c_string, flags : GuiTreeNodeFlags) -> bool                                                                                                                                                            #foreign cimgui "igTreeNodeEx";
/*
TreeNodeExStr                                           :: proc(CONST char* str_id, ImGuiTreeNodeFlags flags, CONST char* fmt, ...) -> bool                                                                                                                                    #foreign cimgui "igTreeNodeExStr";
TreeNodeExPtr                                           :: proc(CONST void* ptr_id, ImGuiTreeNodeFlags flags, CONST char* fmt, ...) -> bool                                                                                                                                    #foreign cimgui "igTreeNodeExPtr";
TreeNodeExV                                             :: proc(CONST char* str_id, ImGuiTreeNodeFlags flags, CONST char* fmt, va_list args) -> bool                                                                                                                           #foreign cimgui "igTreeNodeExV";
TreeNodeExVPtr                                          :: proc(CONST void* ptr_id, ImGuiTreeNodeFlags flags, CONST char* fmt, va_list args) -> bool                                                                                                                           #foreign cimgui "igTreeNodeExVPtr";
*/
TreePushStr                                             :: proc(str_id : c_string)                                                                                                                                                                                             #foreign cimgui "igTreePushStr";
TreePushPtr                                             :: proc(ptr_id : rawptr)                                                                                                                                                                                               #foreign cimgui "igTreePushPtr";
TreePop                                                 :: proc()                                                                                                                                                                                                              #foreign cimgui "igTreePop";
TreeAdvanceToLabelPos                                   :: proc()                                                                                                                                                                                                              #foreign cimgui "igTreeAdvanceToLabelPos";
GetTreeNodeToLabelSpacing                               :: proc() -> f32                                                                                                                                                                                                       #foreign cimgui "igGetTreeNodeToLabelSpacing";
SetNextTreeNodeOpen                                     :: proc(opened : bool, cond : GuiSetCond)                                                                                                                                                                              #foreign cimgui "igSetNextTreeNodeOpen";
CollapsingHeader :: proc(label : string, flags : GuiTreeNodeFlags) -> bool {
    ImCollapsingHeader :: proc(label : c_string, flags : GuiTreeNodeFlags) -> bool #foreign cimgui "igCollapsingHeader";

    str := strings.new_c_string(label); defer free(str);
    return ImCollapsingHeader(str, flags);
}

CollapsingHeaderEx                                      :: proc(label : c_string, p_open : ^bool, flags : GuiTreeNodeFlags) -> bool                                                                                                                                            #foreign cimgui "igCollapsingHeaderEx";

// Widgets: Selectable / Lists
Selectable                                              :: proc(label : c_string, selected : bool, flags : GuiSelectableFlags, size : Vec2) -> bool                                                                                                                            #foreign cimgui "igSelectable";
SelectableEx                                            :: proc(label : c_string, p_selected : ^bool, flags : GuiSelectableFlags, size : Vec2) -> bool                                                                                                                         #foreign cimgui "igSelectableEx";
ListBox                                                 :: proc(label : c_string, current_item : ^i32, items : ^^byte, items_count : i32, height_in_items : i32) -> bool                                                                                                       #foreign cimgui "igListBox";
ListBox2                                                :: proc(label : c_string, current_item : ^i32, items_getter : proc(data : rawptr, idx : i32, out_text : ^^byte) -> bool #cc_c, data : rawptr, items_count : i32, height_in_items : i32) -> bool                        #foreign cimgui "igListBox2";
ListBoxHeader                                           :: proc(label : c_string, size : Vec2) -> bool                                                                                                                                                                         #foreign cimgui "igListBoxHeader";
ListBoxHeader2                                          :: proc(label : c_string, items_count : i32, height_in_items : i32) -> bool                                                                                                                                            #foreign cimgui "igListBoxHeader2";
ListBoxFooter                                           :: proc()                                                                                                                                                                                                              #foreign cimgui "igListBoxFooter";

// Widgets: Value() Helpers. Output single value in "name: value" format (tip: freely declare your own within the ImGui namespace!)
ValueBool                                               :: proc(prefix : c_string, b : bool)                                                                                                                                                                                   #foreign cimgui "igValueBool";
ValueInt                                                :: proc(prefix : c_string, v : i32)                                                                                                                                                                                    #foreign cimgui "igValueInt";
ValueUInt                                               :: proc(prefix : c_string, v : u32)                                                                                                                                                                                   #foreign cimgui "igValueUInt";
ValueFloat                                              :: proc(prefix : c_string, v : f32, float_format : c_string)                                                                                                                                                           #foreign cimgui "igValueFloat";
ValueColor                                              :: proc(prefix : c_string, v : Vec4)                                                                                                                                                                                   #foreign cimgui "igValueColor";
ValueColor2                                             :: proc(prefix : c_string, v : u32)                                                                                                                                                                                   #foreign cimgui "igValueColor2";

// Tooltip
/*
SetTooltip                                              :: proc(CONST char* fmt, ...)                                                                                                                                                                                          #foreign cimgui "igSetTooltip";
SetTooltipV                                             :: proc(CONST char* fmt, va_list args)                                                                                                                                                                                 #foreign cimgui "igSetTooltipV";
*/
BeginTooltip                                            :: proc()                                                                                                                                                                                                              #foreign cimgui "igBeginTooltip";
EndTooltip                                              :: proc()                                                                                                                                                                                                              #foreign cimgui "igEndTooltip";


// Widgets: Menus
BeginMainMenuBar                                        :: proc() -> bool                                                                                                                                                                                                      #foreign cimgui "igBeginMainMenuBar";
EndMainMenuBar                                          :: proc()                                                                                                                                                                                                              #foreign cimgui "igEndMainMenuBar";
BeginMenuBar                                            :: proc() -> bool                                                                                                                                                                                                      #foreign cimgui "igBeginMenuBar";
EndMenuBar                                              :: proc()                                                                                                                                                                                                              #foreign cimgui "igEndMenuBar";

BeginMenu :: proc(label : string, enabled : bool) -> bool {
    ImBeginMenu :: proc(label : c_string, enabled : bool) -> bool #foreign cimgui "igBeginMenu";

    str := strings.new_c_string(label); defer free(str);
    return ImBeginMenu(str, enabled);
}

//BeginMenu                                               :: proc(label : c_string, enabled : bool) -> bool                                                                                                                                                                      #foreign cimgui "igBeginMenu";

EndMenu                                                 :: proc()                                                                                                                                                                                                              #foreign cimgui "igEndMenu";
MenuItem :: proc(label : string, shortcut : string, selected : bool, enabled : bool) -> bool  {
    ImMenuItem :: proc(label : c_string, shortcut : c_string, selected : bool, enabled : bool) -> bool #foreign cimgui "igMenuItem";

    str := strings.new_c_string(label); defer free(str);
    shrt := strings.new_c_string(shortcut); defer free(shrt);
    return ImMenuItem(str, shrt, selected, enabled);
}
//MenuItem                                                :: proc(label : c_string, shortcut : c_string, selected : bool, enabled : bool) -> bool                                                                                                                                #foreign cimgui "igMenuItem";
MenuItemPtr :: proc(label : string, shortcut : string, selected : ^bool, enabled : bool) -> bool  {
    ImMenuItemPtr :: proc(label : c_string, shortcut : c_string, p_selected : ^bool, enabled : bool) -> bool #foreign cimgui "igMenuItemPtr";

    str := strings.new_c_string(label); defer free(str);
    shrt := strings.new_c_string(shortcut); defer free(shrt);
    return ImMenuItemPtr(str, shrt, selected, enabled);
}
//MenuItemPtr                                             :: proc(label : c_string, shortcut : c_string, p_selected : ^bool, enabled : bool) -> bool                                                                                                                             #foreign cimgui "igMenuItemPtr";

// Popup
OpenPopup :: proc(str_id : string) {
    ImOpenPopup :: proc(str_id : c_string) #foreign cimgui "igOpenPopup";
    str := strings.new_c_string(str_id); defer free(str);
    ImOpenPopup(str);
}
BeginPopup :: proc(str_id : string) -> bool {
    ImBeginPopup :: proc(str_id : c_string) -> bool #foreign cimgui "igBeginPopup";
    str := strings.new_c_string(str_id); defer free(str);
    return ImBeginPopup(str);
}
BeginPopupModal :: proc(name : string, open : ^bool, extra_flags : GuiWindowFlags) -> bool {
    ImBeginPopupModal :: proc(name : c_string, p_open : ^bool, extra_flags : GuiWindowFlags) -> bool #foreign cimgui "igBeginPopupModal";
    str := strings.new_c_string(name); defer free(str);
    return ImBeginPopupModal(str, open, extra_flags);
}
BeginPopupContextItem                                   :: proc(str_id : c_string, mouse_button : i32) -> bool                                                                                                                                                                 #foreign cimgui "igBeginPopupContextItem";
BeginPopupContextWindow                                 :: proc(also_over_items : bool, str_id : c_string, mouse_button : i32) -> bool                                                                                                                                         #foreign cimgui "igBeginPopupContextWindow";
BeginPopupContextVoid                                   :: proc(str_id : c_string, mouse_button : i32) -> bool                                                                                                                                                                 #foreign cimgui "igBeginPopupContextVoid";
EndPopup                                                :: proc()                                                                                                                                                                                                              #foreign cimgui "igEndPopup";
CloseCurrentPopup                                       :: proc()                                                                                                                                                                                                              #foreign cimgui "igCloseCurrentPopup";

// Logging: all text output from interface is redirected to tty/file/clipboard. Tree nodes are automatically opened.
LogToTTY                                                :: proc(max_depth : i32)                                                                                                                                                                                               #foreign cimgui "igLogToTTY";
LogToFile                                               :: proc(max_depth : i32, filename : c_string)                                                                                                                                                                          #foreign cimgui "igLogToFile";
LogToClipboard                                          :: proc(max_depth : i32)                                                                                                                                                                                               #foreign cimgui "igLogToClipboard";
LogFinish                                               :: proc()                                                                                                                                                                                                              #foreign cimgui "igLogFinish";
LogButtons                                              :: proc()                                                                                                                                                                                                              #foreign cimgui "igLogButtons";
//igLogText                                               :: proc(CONST char* fmt, ...)                                                                                                                                                                                          #foreign cimgui "igLogText";

// Clipping
PushClipRect                                            :: proc(clip_rect_min : Vec2, clip_rect_max : Vec2, intersect_with_current_clip_rect : bool)                                                                                                                           #foreign cimgui "igPushClipRect";
PopClipRect                                             :: proc()                                                                                                                                                                                                              #foreign cimgui "igPopClipRect";

// Utilities
IsItemHovered                                           :: proc() -> bool                                                                                                                                                                                                      #foreign cimgui "igIsItemHovered";
IsItemHoveredRect                                       :: proc() -> bool                                                                                                                                                                                                      #foreign cimgui "igIsItemHoveredRect";
IsItemActive                                            :: proc() -> bool                                                                                                                                                                                                      #foreign cimgui "igIsItemActive";
IsItemClicked                                           :: proc(mouse_button : i32) -> bool                                                                                                                                                                                    #foreign cimgui "igIsItemClicked";
IsItemVisible                                           :: proc() -> bool                                                                                                                                                                                                      #foreign cimgui "igIsItemVisible";
IsAnyItemHovered                                        :: proc() -> bool                                                                                                                                                                                                      #foreign cimgui "igIsAnyItemHovered";
IsAnyItemActive                                         :: proc() -> bool                                                                                                                                                                                                      #foreign cimgui "igIsAnyItemActive";
GetItemRectMin                                          :: proc(pOut : ^Vec2)                                                                                                                                                                                                  #foreign cimgui "igGetItemRectMin";
GetItemRectMax                                          :: proc(pOut : ^Vec2)                                                                                                                                                                                                  #foreign cimgui "igGetItemRectMax";
GetItemRectSize                                         :: proc(pOut : ^Vec2)                                                                                                                                                                                                  #foreign cimgui "igGetItemRectSize";
SetItemAllowOverlap                                     :: proc()                                                                                                                                                                                                              #foreign cimgui "igSetItemAllowOverlap";
IsWindowHovered                                         :: proc() -> bool                                                                                                                                                                                                      #foreign cimgui "igIsWindowHovered";
IsWindowFocused                                         :: proc() -> bool                                                                                                                                                                                                      #foreign cimgui "igIsWindowFocused";
IsRootWindowFocused                                     :: proc() -> bool                                                                                                                                                                                                      #foreign cimgui "igIsRootWindowFocused";
IsRootWindowOrAnyChildFocused                           :: proc() -> bool                                                                                                                                                                                                      #foreign cimgui "igIsRootWindowOrAnyChildFocused";
IsRootWindowOrAnyChildHovered                           :: proc() -> bool                                                                                                                                                                                                      #foreign cimgui "igIsRootWindowOrAnyChildHovered";
IsRectVisible                                           :: proc(item_size : Vec2) -> bool                                                                                                                                                                                      #foreign cimgui "igIsRectVisible";
IsPosHoveringAnyWindow                                  :: proc(pos : Vec2) -> bool                                                                                                                                                                                            #foreign cimgui "igIsPosHoveringAnyWindow";
GetTime                                                 :: proc() -> f32                                                                                                                                                                                                       #foreign cimgui "igGetTime";
GetFrameCount                                           :: proc() -> i32                                                                                                                                                                                                       #foreign cimgui "igGetFrameCount";
GetStyleColName                                         :: proc(idx : GuiCol) -> c_string                                                                                                                                                                                      #foreign cimgui "igGetStyleColName";
CalcItemRectClosestPoint                                :: proc(pOut : ^Vec2, pos : Vec2 , on_edge : bool, outward : f32)                                                                                                                                                      #foreign cimgui "igCalcItemRectClosestPoint";
CalcTextSize                                            :: proc(pOut : ^Vec2, text : c_string, text_end : c_string, hide_text_after_double_hash : bool, wrap_width : f32)                                                                                                      #foreign cimgui "igCalcTextSize";
CalcListClipping                                        :: proc(items_count : i32, items_height : f32, out_items_display_start : ^i32, out_items_display_end : ^i32)                                                                                                           #foreign cimgui "igCalcListClipping";

BeginChildFrame                                         :: proc(id : GuiID, size : Vec2, extra_flags : GuiWindowFlags) -> bool                                                                                                                                                 #foreign cimgui "igBeginChildFrame";
EndChildFrame                                           :: proc()                                                                                                                                                                                                              #foreign cimgui "igEndChildFrame";

ColorConvertU32ToFloat4                                 :: proc(pOut : ^Vec4 , in_ : u32)                                                                                                                                                                                      #foreign cimgui "igColorConvertU32ToFloat4";
ColorConvertFloat4ToU32                                 :: proc(in_ : Vec4) -> u32                                                                                                                                                                                             #foreign cimgui "igColorConvertFloat4ToU32";
ColorConvertRGBtoHSV                                    :: proc(r : f32, g : f32, b : f32, out_h : ^f32, out_s : ^f32, out_v : ^f32)                                                                                                                                           #foreign cimgui "igColorConvertRGBtoHSV";
ColorConvertHSVtoRGB                                    :: proc(h : f32, s : f32, v : f32, out_r : ^f32, out_g : ^f32, out_b : ^f32)                                                                                                                                           #foreign cimgui "igColorConvertHSVtoRGB";

GetKeyIndex                                             :: proc(key : GuiKey) -> i32                                                                                                                                                                                           #foreign cimgui "igGetKeyIndex";
IsKeyDown                                               :: proc(key_index : i32) -> bool                                                                                                                                                                                       #foreign cimgui "igIsKeyDown";
IsKeyPressed                                            :: proc(key_index : i32, repeat : bool) -> bool                                                                                                                                                                        #foreign cimgui "igIsKeyPressed";
IsKeyReleased                                           :: proc(key_index : i32) -> bool                                                                                                                                                                                       #foreign cimgui "igIsKeyReleased";
IsMouseDown                                             :: proc(button : i32) -> bool                                                                                                                                                                                          #foreign cimgui "igIsMouseDown";
IsMouseClicked                                          :: proc(button : i32, repeat : bool) -> bool                                                                                                                                                                           #foreign cimgui "igIsMouseClicked";
IsMouseDoubleClicked                                    :: proc(button : i32) -> bool                                                                                                                                                                                          #foreign cimgui "igIsMouseDoubleClicked";
IsMouseReleased                                         :: proc(button : i32) -> bool                                                                                                                                                                                          #foreign cimgui "igIsMouseReleased";
IsMouseHoveringWindow                                   :: proc() -> bool                                                                                                                                                                                                      #foreign cimgui "igIsMouseHoveringWindow";
IsMouseHoveringAnyWindow                                :: proc() -> bool                                                                                                                                                                                                      #foreign cimgui "igIsMouseHoveringAnyWindow";
IsMouseHoveringRect                                     :: proc(r_min : Vec2, r_max : Vec2, clip : bool) -> bool                                                                                                                                                               #foreign cimgui "igIsMouseHoveringRect";
IsMouseDragging                                         :: proc(button : i32, lock_threshold : f32) -> bool                                                                                                                                                                    #foreign cimgui "igIsMouseDragging";
GetMousePos                                             :: proc(pOut : ^Vec2)                                                                                                                                                                                                  #foreign cimgui "igGetMousePos";
GetMousePosOnOpeningCurrentPopup                        :: proc(pOut : ^Vec2)                                                                                                                                                                                                  #foreign cimgui "igGetMousePosOnOpeningCurrentPopup";
GetMouseDragDelta                                       :: proc(pOut : ^Vec2, button : i32, lock_threshold : f32)                                                                                                                                                              #foreign cimgui "igGetMouseDragDelta";
ResetMouseDragDelta                                     :: proc(button : i32)                                                                                                                                                                                                  #foreign cimgui "igResetMouseDragDelta";
GetMouseCursor                                          :: proc() -> GuiMouseCursor                                                                                                                                                                                            #foreign cimgui "igGetMouseCursor";
SetMouseCursor                                          :: proc(type_ : GuiMouseCursor)                                                                                                                                                                                        #foreign cimgui "igSetMouseCursor";
CaptureKeyboardFromApp                                  :: proc(capture : bool)                                                                                                                                                                                                #foreign cimgui "igCaptureKeyboardFromApp";
CaptureMouseFromApp                                     :: proc(capture : bool)                                                                                                                                                                                                #foreign cimgui "igCaptureMouseFromApp";

// Helpers functions to access functions pointers in ImGui::GetIO()
MemAlloc                                                :: proc(sz : u64 /*size_t*/) -> rawptr                                                                                                                                                                                 #foreign cimgui "igMemAlloc";
MemFree                                                 :: proc(ptr : rawptr)                                                                                                                                                                                                  #foreign cimgui "igMemFree";
GetClipboardText                                        :: proc() -> c_string                                                                                                                                                                                                  #foreign cimgui "igGetClipboardText";
SetClipboardText                                        :: proc(text : c_string)                                                                                                                                                                                               #foreign cimgui "igSetClipboardText";

// Internal state access - if you want to share ImGui state between modules (e.g. DLL) or allocate it yourself
GetVersion                                              :: proc() -> c_string                                                                                                                                                                                                  #foreign cimgui "igGetVersion";
CreateContext                                           :: proc(malloc_fn : proc(size : u64 /*size_t*/) -> rawptr, free_fn : proc(data : rawptr)) -> ^GuiContext                                                                                                               #foreign cimgui "igCreateContext";
DestroyContext                                          :: proc(ctx : ^GuiContext)                                                                                                                                                                                             #foreign cimgui "igDestroyContext";
GetCurrentContext                                       :: proc() -> ^GuiContext                                                                                                                                                                                               #foreign cimgui "igGetCurrentContext";
SetCurrentContext                                       :: proc(ctx : ^GuiContext)                                                                                                                                                                                             #foreign cimgui "igSetCurrentContext";

////////////////////////////////////// Misc    ///////////////////////////////////////////////
FontConfig_DefaultConstructor                           :: proc(config : ^FontConfig)                                                                                                                                                                                          #foreign cimgui "ImFontConfig_DefaultConstructor";
GuiIO_AddInputCharacter                                 :: proc(c : u16)                                                                                                                                                                                                       #foreign cimgui "ImGuiIO_AddInputCharacter";
GuiIO_AddInputCharactersUTF8                            :: proc(utf8_chars : ^byte)                                                                                                                                                                                            #foreign cimgui "ImGuiIO_AddInputCharactersUTF8";
GuiIO_ClearInputCharacters                              :: proc()                                                                                                                                                                                                              #foreign cimgui "ImGuiIO_ClearInputCharacters";

//////////////////////////////// FontAtlas  //////////////////////////////////////////////
FontAtlas_GetTexDataAsRGBA32                            :: proc(atlas : ^FontAtlas, out_pixels : ^^byte, out_width : ^i32, out_height : ^i32, out_bytes_per_pixel : ^i32)                                                                                                      #foreign cimgui "ImFontAtlas_GetTexDataAsRGBA32";
FontAtlas_GetTexDataAsAlpha8                            :: proc(atlas : ^FontAtlas, out_pixels : ^^byte, out_width : ^i32, out_height : ^i32, out_bytes_per_pixel : ^i32)                                                                                                      #foreign cimgui "ImFontAtlas_GetTexDataAsAlpha8";
FontAtlas_SetTexID                                      :: proc(atlas : ^FontAtlas, tex : rawptr)                                                                                                                                                                              #foreign cimgui "ImFontAtlas_SetTexID";
FontAtlas_AddFont                                       :: proc(atlas : ^FontAtlas, font_cfg : ^FontConfig ) -> ^Font                                                                                                                                                          #foreign cimgui "ImFontAtlas_AddFont";
FontAtlas_AddFontDefault                                :: proc(atlas : ^FontAtlas, font_cfg : ^FontConfig ) -> ^Font                                                                                                                                                          #foreign cimgui "ImFontAtlas_AddFontDefault";
FontAtlas_AddFontFromFileTTF                            :: proc(atlas : ^FontAtlas, filename : c_string, size_pixels : f32, font_cfg : ^FontConfig, glyph_ranges : ^Wchar) -> ^Font                                                                                            #foreign cimgui "ImFontAtlas_AddFontFromFileTTF";
FontAtlas_AddFontFromMemoryTTF                          :: proc(atlas : ^FontAtlas, ttf_data : rawptr, ttf_size : i32, size_pixels : f32, font_cfg : ^FontConfig, glyph_ranges : ^Wchar) -> ^Font                                                                              #foreign cimgui "ImFontAtlas_AddFontFromMemoryTTF";
FontAtlas_AddFontFromMemoryCompressedTTF                :: proc(atlas : ^FontAtlas, compressed_ttf_data : rawptr, compressed_ttf_size : i32, size_pixels : f32, font_cfg : ^FontConfig, glyph_ranges : ^Wchar) -> ^Font                                                        #foreign cimgui "ImFontAtlas_AddFontFromMemoryCompressedTTF";
FontAtlas_AddFontFromMemoryCompressedBase85TTF          :: proc(atlas : ^FontAtlas, compressed_ttf_data_base85 : c_string, size_pixels : f32, font_cfg : ^FontConfig, glyph_ranges : ^Wchar) -> ^Font                                                                          #foreign cimgui "ImFontAtlas_AddFontFromMemoryCompressedBase85TTF";
FontAtlas_ClearTexData                                  :: proc(atlas : ^FontAtlas)                                                                                                                                                                                            #foreign cimgui "ImFontAtlas_ClearTexData";
FontAtlas_Clear                                         :: proc(atlas : ^FontAtlas)                                                                                                                                                                                            #foreign cimgui "ImFontAtlas_Clear";

//////////////////////////////// DrawList  //////////////////////////////////////////////
DrawList_GetVertexBufferSize                            :: proc(list : ^DrawList) -> i32                                                                                                                                                                                       #foreign cimgui "ImDrawList_GetVertexBufferSize";
DrawList_GetVertexPtr                                   :: proc(list : ^DrawList, n : i32) -> ^DrawVert                                                                                                                                                                        #foreign cimgui "ImDrawList_GetVertexPtr";
DrawList_GetIndexBufferSize                             :: proc(list : ^DrawList) -> i32                                                                                                                                                                                       #foreign cimgui "ImDrawList_GetIndexBufferSize";
DrawList_GetIndexPtr                                    :: proc(list : ^DrawList, n : i32) -> ^DrawIdx                                                                                                                                                                         #foreign cimgui "ImDrawList_GetIndexPtr";
DrawList_GetCmdSize                                     :: proc(list : ^DrawList) -> i32                                                                                                                                                                                       #foreign cimgui "ImDrawList_GetCmdSize";
DrawList_GetCmdPtr                                      :: proc(list : ^DrawList, n : i32) -> ^DrawCmd                                                                                                                                                                         #foreign cimgui "ImDrawList_GetCmdPtr";

DrawList_Clear                                          :: proc(list : ^DrawList)                                                                                                                                                                                              #foreign cimgui "ImDrawList_Clear";
DrawList_ClearFreeMemory                                :: proc(list : ^DrawList)                                                                                                                                                                                              #foreign cimgui "ImDrawList_ClearFreeMemory";
DrawList_PushClipRect                                   :: proc(list : ^DrawList, clip_rect_min : Vec2, clip_rect_max : Vec2, intersect_with_current_clip_rect : bool)                                                                                                         #foreign cimgui "ImDrawList_PushClipRect";
DrawList_PushClipRectFullScreen                         :: proc(list : ^DrawList)                                                                                                                                                                                              #foreign cimgui "ImDrawList_PushClipRectFullScreen";
DrawList_PopClipRect                                    :: proc(list : ^DrawList)                                                                                                                                                                                              #foreign cimgui "ImDrawList_PopClipRect";
DrawList_PushTextureID                                  :: proc(list : ^DrawList, texture_id : TextureID)                                                                                                                                                                      #foreign cimgui "ImDrawList_PushTextureID";
DrawList_PopTextureID                                   :: proc(list : ^DrawList)                                                                                                                                                                                              #foreign cimgui "ImDrawList_PopTextureID";

// Primitives
DrawList_AddLine                                        :: proc(list : ^DrawList, a : Vec2, b : Vec2, col : u32, thickness : f32)                                                                                                                                              #foreign cimgui "ImDrawList_AddLine";
DrawList_AddRect                                        :: proc(list : ^DrawList, a : Vec2, b : Vec2, col : u32, rounding : f32, rounding_corners : i32, thickness : f32)                                                                                                      #foreign cimgui "ImDrawList_AddRect";
DrawList_AddRectFilled                                  :: proc(list : ^DrawList, a : Vec2, b : Vec2, col : u32, rounding : f32, rounding_corners : i32)                                                                                                                       #foreign cimgui "ImDrawList_AddRectFilled";
DrawList_AddRectFilledMultiColor                        :: proc(list : ^DrawList, a : Vec2, b : Vec2, col_upr_left : u32, col_upr_right : u32, col_bot_right : u32, col_bot_left : u32)                                                                                        #foreign cimgui "ImDrawList_AddRectFilledMultiColor";
DrawList_AddQuad                                        :: proc(list : ^DrawList, a : Vec2, b : Vec2, c : Vec2, d : Vec2, col : u32, thickness : f32)                                                                                                                          #foreign cimgui "ImDrawList_AddQuad";
DrawList_AddQuadFilled                                  :: proc(list : ^DrawList, a : Vec2, b : Vec2, c : Vec2, d : Vec2, col : u32)                                                                                                                                           #foreign cimgui "ImDrawList_AddQuadFilled";
DrawList_AddTriangle                                    :: proc(list : ^DrawList, a : Vec2, b : Vec2, c : Vec2, col : u32, thickness : f32)                                                                                                                                    #foreign cimgui "ImDrawList_AddTriangle";
DrawList_AddTriangleFilled                              :: proc(list : ^DrawList, a : Vec2, b : Vec2, c : Vec2, col : u32)                                                                                                                                                     #foreign cimgui "ImDrawList_AddTriangleFilled";
DrawList_AddCircle                                      :: proc(list : ^DrawList, centre : Vec2, radius : f32, col : u32, num_segments : i32, thickness : f32)                                                                                                                 #foreign cimgui "ImDrawList_AddCircle";
DrawList_AddCircleFilled                                :: proc(list : ^DrawList, centre : Vec2, radius : f32, col : u32, num_segments : i32)                                                                                                                                  #foreign cimgui "ImDrawList_AddCircleFilled";
DrawList_AddText                                        :: proc(list : ^DrawList, pos : Vec2, col : u32, text_begin : c_string, text_end : c_string)                                                                                                                           #foreign cimgui "ImDrawList_AddText";
DrawList_AddTextExt                                     :: proc(list : ^DrawList, font : ^Font, font_size : f32, pos : Vec2, col : u32, text_begin : c_string, text_end : c_string, wrap_width : f32, cpu_fine_clip_rect : ^Vec4)                                              #foreign cimgui "ImDrawList_AddTextExt";
DrawList_AddImage                                       :: proc(list : ^DrawList, user_texture_id : TextureID, a : Vec2, b : Vec2, uv0 : Vec2, uv1 : Vec2, col : u32)                                                                                                          #foreign cimgui "ImDrawList_AddImage";
DrawList_AddPolyline                                    :: proc(list : ^DrawList, points : ^Vec2, num_points : i32, col : u32, closed : bool, thickness : f32, anti_aliased : bool)                                                                                            #foreign cimgui "ImDrawList_AddPolyline";
DrawList_AddConvexPolyFilled                            :: proc(list : ^DrawList, points : ^Vec2, num_points : i32, col : u32, anti_aliased : bool)                                                                                                                            #foreign cimgui "ImDrawList_AddConvexPolyFilled";
DrawList_AddBezierCurve                                 :: proc(list : ^DrawList, pos0 : Vec2, cp0 : Vec2, cp1 : Vec2, pos1 : Vec2, col : u32, thickness : f32, num_segments : i32)                                                                                            #foreign cimgui "ImDrawList_AddBezierCurve";

// Stateful path API, add points then finish with PathFill() or PathStroke()
DrawList_PathClear                                      :: proc(list : ^DrawList)                                                                                                                                                                                              #foreign cimgui "ImDrawList_PathClear";
DrawList_PathLineTo                                     :: proc(list : ^DrawList, pos : Vec2)                                                                                                                                                                                  #foreign cimgui "ImDrawList_PathLineTo";
DrawList_PathLineToMergeDuplicate                       :: proc(list : ^DrawList, pos : Vec2)                                                                                                                                                                                  #foreign cimgui "ImDrawList_PathLineToMergeDuplicate";
DrawList_PathFill                                       :: proc(list : ^DrawList, col : u32)                                                                                                                                                                                   #foreign cimgui "ImDrawList_PathFill";
DrawList_PathStroke                                     :: proc(list : ^DrawList, col : u32, closed : bool, thickness : f32)                                                                                                                                                   #foreign cimgui "ImDrawList_PathStroke";
DrawList_PathArcTo                                      :: proc(list : ^DrawList, centre : Vec2, radius : f32, a_min : f32, a_max : f32, num_segments : i32)                                                                                                                   #foreign cimgui "ImDrawList_PathArcTo";
DrawList_PathArcToFast                                  :: proc(list : ^DrawList, centre : Vec2, radius : f32, a_min_of_12 : i32, a_max_of_12 : i32)                                                                                                                           #foreign cimgui "ImDrawList_PathArcToFast"; // Use precomputed angles for a 12 steps circle
DrawList_PathBezierCurveTo                              :: proc(list : ^DrawList, p1 : Vec2, p2 : Vec2, p3 : Vec2, num_segments : i32)                                                                                                                                         #foreign cimgui "ImDrawList_PathBezierCurveTo";
DrawList_PathRect                                       :: proc(list : ^DrawList, rect_min : Vec2, rect_max : Vec2, rounding : f32, rounding_corners : i32)                                                                                                                    #foreign cimgui "ImDrawList_PathRect";

// Channels
DrawList_ChannelsSplit                                  :: proc(list : ^DrawList, channels_count : i32)                                                                                                                                                                        #foreign cimgui "ImDrawList_ChannelsSplit";
DrawList_ChannelsMerge                                  :: proc(list : ^DrawList)                                                                                                                                                                                              #foreign cimgui "ImDrawList_ChannelsMerge";
DrawList_ChannelsSetCurrent                             :: proc(list : ^DrawList, channel_index : i32)                                                                                                                                                                         #foreign cimgui "ImDrawList_ChannelsSetCurrent";

// Advanced
// Your rendering function must check for 'UserCallback' in ImDrawCmd and call the function instead of rendering triangles.
DrawList_AddCallback                                    :: proc(list : ^DrawList, callback : DrawCallback, callback_data : rawptr)                                                                                                                                             #foreign cimgui "ImDrawList_AddCallback";
// This is useful if you need to forcefully create a new draw call(to allow for dependent rendering / blending). Otherwise primitives are merged into the same draw-call as much as possible
DrawList_AddDrawCmd                                     :: proc(list : ^DrawList)                                                                                                                                                                                              #foreign cimgui "ImDrawList_AddDrawCmd";
// Internal helpers
DrawList_PrimReserve                                    :: proc(list : ^DrawList, idx_count : i32, vtx_count : i32)                                                                                                                                                            #foreign cimgui "ImDrawList_PrimReserve";
DrawList_PrimRect                                       :: proc(list : ^DrawList, a : Vec2, b : Vec2, col : u32)                                                                                                                                                               #foreign cimgui "ImDrawList_PrimRect";
DrawList_PrimRectUV                                     :: proc(list : ^DrawList, a : Vec2, b : Vec2, uv_a : Vec2, uv_b : Vec2, col : u32)                                                                                                                                     #foreign cimgui "ImDrawList_PrimRectUV";
DrawList_PrimQuadUV                                     :: proc(list : ^DrawList,a : Vec2, b : Vec2, c : Vec2, d : Vec2, uv_a : Vec2, uv_b : Vec2, uv_c : Vec2, uv_d : Vec2, col : u32)                                                                                        #foreign cimgui "ImDrawList_PrimQuadUV";
DrawList_PrimWriteVtx                                   :: proc(list : ^DrawList, pos : Vec2, uv : Vec2, col : u32)                                                                                                                                                            #foreign cimgui "ImDrawList_PrimWriteVtx";
DrawList_PrimWriteIdx                                   :: proc(list : ^DrawList, idx : DrawIdx)                                                                                                                                                                               #foreign cimgui "ImDrawList_PrimWriteIdx";
DrawList_PrimVtx                                        :: proc(list : ^DrawList, pos : Vec2, uv : Vec2, col : u32)                                                                                                                                                            #foreign cimgui "ImDrawList_PrimVtx";
DrawList_UpdateClipRect                                 :: proc(list : ^DrawList)                                                                                                                                                                                              #foreign cimgui "ImDrawList_UpdateClipRect";
DrawList_UpdateTextureID                                :: proc(list : ^DrawList)                                                                                                                                                                                              #foreign cimgui "ImDrawList_UpdateTextureID";