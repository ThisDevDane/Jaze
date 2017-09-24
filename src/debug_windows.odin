/*
 *  @Name:     debug_windows
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 10-05-2017 21:11:30
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 24-09-2017 23:13:07
 *  
 *  @Description:
 *      Contains all the drawing code for debug windows.
 */
import "core:fmt.odin";
import win32 "core:sys/windows.odin";
import gl "libbrew/win/opengl.odin";
import "xinput.odin";
import imgui "libbrew/brew_imgui.odin";
import "main.odin";
import "time.odin";
import "catalog.odin";
import "console.odin";
//import "game.odin";
import jinput "input.odin";
import ja "asset.odin";
//import je "entity.odin";
//import p32 "platform_win32.odin";

STD_WINDOW :: /*imgui.GuiWindowFlags.ShowBorders |*/  imgui.GuiWindowFlags.NoCollapse;

_GlobalDebugWndBools : map[string]bool;
_ChosenCatalog : i32;
_PreviewSize := imgui.Vec2{20, 20};
_ShowID : gl.Texture = 1;
_ChosenEntity : ^je.Entity;

get_window_state :: proc(str : string) -> bool {
    return _GlobalDebugWndBools[str];
}

set_window_state :: proc(str : string, state : bool) {
    _GlobalDebugWndBools[str] = state;
}

toggle_window_state :: proc(str : string) {
    _GlobalDebugWndBools[str] = !_GlobalDebugWndBools[str];
}

try_show_window :: proc(id : string, p : proc(b : ^bool)) {
    if get_window_state(id) {
        b := get_window_state(id);
        p(&b);
        set_window_state(id, b);
    }
}

show_struct_info :: proc(name : string, show : ^bool, data : any) {
    imgui.begin(name, show, STD_WINDOW);
    {
        imgui.columns(2, "nil", true);
        info := type_info_base(data.type_info).(^TypeInfo.Struct);
        for n, i in info.names {
            imgui.text("%s", n);
            imgui.next_column();
            match t in info.types[i] {
                case TypeInfo.Pointer : {
                    if t.elem == nil {
                        imgui.text("RAWPTR");
                    } else {
                        buf : [128]byte;
                        s := fmt.bprintf(buf[..], "%s##%s", "Show Value", n);
                        if imgui.collapsing_header(s, 0) {
                            ptr := ^byte(data.data) + info.offsets[i];
                            value := ^rawptr(ptr)^;
                            v := any{rawptr(value), t.elem};
                            show_struct_info(n, nil, v);
                        }
                    }
                }

                case TypeInfo.Boolean : {
                    value := ^byte(data.data) + info.offsets[i];
                    col := bool(value^) ? imgui.Vec4{0, 1, 0, 1} : imgui.Vec4{1, 0, 0, 1};
                    v := any{rawptr(value), type_info_base(info.types[i])};
                    imgui.text_colored(col, "%t", v);
                }                

                case : {
                    value := ^byte(data.data) + info.offsets[i];
                    v := any{rawptr(value), info.types[i]};
                    imgui.text_wrapped("%v", v);
                } 
            }
            imgui.separator();
            imgui.next_column();
        }
    }
    imgui.end();
}

show_entity_list :: proc(gameCtx : ^game.Context, show : ^bool) {
    PrintNormalTower :: proc(t : je.Tower) {
        imgui.indent(10);
        {
            if imgui.collapsing_header("Transform", 0) {
                imgui.indent(10);
                imgui.text("Position: %v", t.Position);
                imgui.text("Scale: %v", t.Scale);
                imgui.text("Rotation: %v", t.Rotation);
                imgui.unindent(10);
            }
            imgui.text("Damage: %v", t.Damage);
            imgui.text("Attack Speed: %v", t.AttackSpeed);
            if t.Texture != nil {
                imgui.text_wrapped("texture: %v", t.Texture^);
            } else {
                imgui.text("texture: N/A");
            } 
        }
        imgui.unindent(10);
    }
    
    PrintSlowTower :: proc(e : je.Tower.Slow) {
        imgui.indent(10);
        {
            imgui.text("Slow Rate: %v", e.SlowFactor);
        }
        imgui.unindent(10);
    }

    imgui.begin("Entity List", show, STD_WINDOW);
    {
        imgui.columns(2, "nil", false);
        imgui.begin_child("Entities", imgui.Vec2{0, -20}, true, 0);
        {
            for i := gameCtx.entity_list.Front;
                i != nil;
                i = i.Next {
                if i.Entity == nil {
                    continue;
                }
                buf : [256]byte;
                str := fmt.bprintf(buf[..], "%s(%d)", i.Entity.Name, i.Entity.GUID);
                if imgui.button(str, imgui.Vec2{-1, 0}) {
                    _ChosenEntity = i.Entity;   
                }
            }
        }
        imgui.end_child();
        imgui.next_column();
        imgui.begin_child("Entity", imgui.Vec2{0, -20}, true, 0);
        {
            if _ChosenEntity != nil {
                imgui.text("GUID: %v", _ChosenEntity.GUID);
                imgui.text("Name: %v", _ChosenEntity.Name);
                match e in _ChosenEntity {
                    case je.Entity.Tower : {
                        match t in e.T {
                            case je.Tower.Slow : {
                                imgui.text("Match: %d", e.T.__tag);
                                PrintNormalTower(e.T);
                                PrintSlowTower(t);
                            }

                            case je.Tower.Basic : {
                                imgui.text("Match: %d", e.T.__tag);
                                PrintNormalTower(e.T);
                            }

                            case : {
                                imgui.text("Match: %d", e.T.__tag);
                            }
                        }
                    }
                }
            }
        }
        imgui.end_child();
        imgui.columns(1, "nil", false);
        imgui.separator();
        imgui.text_colored(imgui.Vec4{1, 1, 1, 0.2}, "Entities: %d", gameCtx.entity_list.Count);
    }
    imgui.end();


}

show_debug_windows_states :: proc(show : ^bool) {
    imgui.begin("Debug Window States", show, STD_WINDOW);
    {
        imgui.text("Chosen Catalog Index: %d", _ChosenCatalog);
        imgui.text("texture Preview Sixe: <%.2f,%.2f>", _PreviewSize.x, _PreviewSize.y);
        imgui.text("texture Show ID:      %d", _ShowID);
        imgui.separator();

        imgui.begin_child("Window States", imgui.Vec2{0, 0}, true, 0);
        imgui.columns(2, "nil", true);
        for val, id in _GlobalDebugWndBools {
            imgui.text("%s", id);
            imgui.next_column();
            imgui.text("%t", val);
            imgui.next_column();
            imgui.separator();
        }
        imgui.columns(1, "nil", true);
        imgui.end_child();
    }
    imgui.end();
}

stat_overlay :: proc(show : ^bool) {
    imgui.set_next_window_pos(imgui.Vec2{5, 25}, 0);
    imgui.push_style_color(imgui.GuiCol.WindowBg, imgui.Vec4{0.23, 0.23, 0.23, 0.4});
    imgui.begin("Stat Overlay", show, imgui.GuiWindowFlags.NoMove | imgui.GuiWindowFlags.NoTitleBar | imgui.GuiWindowFlags.NoResize | imgui.GuiWindowFlags.NoSavedSettings); 
    {
        io := imgui.get_io();
        imgui.text("Framerate: %.1ffps (%fms) ", io.framerate, 1000.0 / io.framerate);
        imgui.separator();
        imgui.text("Draw Calls: %d calls", gl.debug_info.draw_calls);
    }   
    imgui.end();
    imgui.pop_style_color(1);
}

opengl_extensions :: proc(name : string, extensions : [dynamic]string, show : ^bool) {
    imgui.begin(name, show, STD_WINDOW); 
    {
        for ext in extensions {
            imgui.text(ext);
        }
    }   
    imgui.end();
}

opengl_texture_overview :: proc(show : ^bool) {
    _CalculateMaxcolumns :: proc(w : f32, csize : f32, max : i32) -> i32 {
        columns := i32(w / csize);
        if columns > max {
            columns = max;
        }

        if columns <= 0 {
            columns = 1;
        }
        return columns;
    }

    imgui.begin("Loaded Textures", show, STD_WINDOW);
    {
        imgui.drag_float("Preview Size:", &_PreviewSize.x, 0.2, 20, 100, "%.0f", 1);
        imgui.separator();
        _PreviewSize.y = _PreviewSize.x;
        size : imgui.Vec2;
        imgui.get_window_size(&size);
        columns := _CalculateMaxcolumns(size.x, _PreviewSize.x + 24, i32(len(gl.debug_info.loaded_textures)));
        imgui.begin_child("", imgui.Vec2{0, 0}, false, 0);
        {
            imgui.columns(columns, "nil", false);
            for id in gl.debug_info.loaded_textures {
                imgui.image(imgui.TextureID(uint(id)), _PreviewSize, imgui.Vec2{0, 0}, imgui.Vec2{1, 1}, imgui.Vec4{1, 1, 1, 1}, imgui.Vec4{0.91, 0.4, 0.23, 1});
                if imgui.is_item_hovered() {
                    imgui.begin_tooltip();
                    {
                        imgui.text("ID: %d", id);
                    }
                    imgui.end_tooltip();
                }
                if imgui.is_item_clicked(0) {
                    _ShowID = id;
                }
                imgui.next_column();
            }
            imgui.columns(1, "nil", false);
            }
        imgui.end_child();
    }
    imgui.end();

    imgui.begin("texture View", nil, STD_WINDOW | imgui.GuiWindowFlags.NoScrollbar);
    {
        size : imgui.Vec2;
        imgui.get_window_size(&size);
        imgui.image(imgui.TextureID(uint(_ShowID)), imgui.Vec2{size.x-16, size.y-35}, imgui.Vec2{0, 0}, imgui.Vec2{1, 1}, imgui.Vec4{1, 1, 1, 1}, imgui.Vec4{0.91, 0.4, 0.23, 0});
    }
    imgui.end();
}

opengl_info :: proc(vars : ^gl.OpenGLVars, show : ^bool) {
    imgui.begin("OpenGL Info", show, STD_WINDOW);
    {
        imgui.text("Versions:");
        imgui.indent(20.0);
            imgui.text("Highest: %d.%d", vars.version_major_max, vars.version_minor_max);
            imgui.text("Current: %d.%d", vars.version_major_cur, vars.version_major_cur);
            imgui.text("GLSL:    %s", vars.glsl_version_string);
        imgui.unindent(20.0);
        imgui.text("Lib Address 0x%x", gl.debug_info.lib_address);
        imgui.separator();
            imgui.text("Vendor:   %s", vars.vendor_string);
            imgui.text("Render:   %s", vars.renderer_string);
            imgui.text("CtxFlags: %d", vars.context_flags);
        imgui.separator();
            imgui.text("Number of extensions:       %d", vars.num_extensions); imgui.same_line(0, -1);
            if imgui.small_button("View##Ext") {
                set_window_state("OpenGLShowExtensions", true);
            }
            imgui.text("Number of WGL extensions:   %d", vars.num_wgl_extensions);imgui.same_line(0, -1);
            if imgui.small_button("View##WGL") {
                set_window_state("OpenGLShowWGLExtensions", true);
            }
            imgui.text("Number of loaded Textures: %d", len(gl.debug_info.loaded_textures)); imgui.same_line(0, -1);
            if imgui.small_button("View##texture") {
                set_window_state("ShowGLtextureOverview", true);
            }
            imgui.text("Number of functions loaded: %d/%d", gl.debug_info.number_of_functions_loaded_successed, gl.debug_info.number_of_functions_loaded); 
        imgui.separator();
        if imgui.collapsing_header("Loaded Functions", 0) {
            imgui.begin_child("Functions###FuncLoad", imgui.Vec2{0, 0}, true, 0);
            imgui.columns(2, "nil", false);
            suc : string;
            for status in gl.debug_info.statuses {
                imgui.text(status.name);
/*                if(imgui.is_item_hovered()) {
                    imgui.BeginTooltip();
                    imgui.PushtextWrapPos(450.0);
                    imgui.text("%s @ 0x%X", status.Name, status.Address);
                    /*buf : [4095]byte;
                    procString : string;
                    */
                    
                    test1, ok1 := union_cast(^Type_Info.Procedure)status.TypeInfo;
                    test2, ok2 := union_cast(^Type_Info.Tuple)test1.params;
                    imgui.text("%t", ok1);
                    imgui.text("%t", ok2);
                    imgui.text("%d", len(test2.names));
                    for info in test2.names {
                        imgui.text(info);
                    }

                    imgui.PoptextWrapPos();
                    imgui.endTooltip();
                }*/
                imgui.next_column();
                c : imgui.Vec4;
                if status.success {
                    c = imgui.Vec4{0,0.78,0,1};
                    suc = "true";
                } else {
                    c = imgui.Vec4{1,0,0,1};
                    suc = "false";
                }

                imgui.text_colored(c, "Loaded: %s", suc);
                imgui.next_column();

            }
            imgui.columns(1, "nil", false);
            imgui.end_child();
        }
    }
    imgui.end();

    if get_window_state("OpenGLShowExtensions") {
        b := get_window_state("OpenGLShowExtensions");
        opengl_extensions("Extensions##Ext", vars.extensions, &b);
        set_window_state("OpenGLShowExtensions", b);
    }

    if get_window_state("OpenGLShowWGLExtensions") {
        b := get_window_state("OpenGLShowWGLExtensions");
        opengl_extensions("WGL Extensions", vars.wgl_extensions, &b);
        set_window_state("OpenGLShowWGLExtensions", b);
    }

    try_show_window("ShowGLtextureOverview", opengl_texture_overview);
}

_print_gamepad_name :: proc(id : int, err : xinput.Error) {
    imgui.text("Gamepad %d(", id+1);
    b := err == xinput.Success;
    c : imgui.Vec4;
    if b {
        c = imgui.Vec4{0,0.78,0,1};
    } else {
        c = imgui.Vec4{1,0,0,1};
    }
    imgui.same_line(0, 0);
    imgui.text_colored(c, "%s", b ? "Connected" : "Not Connected");
    imgui.same_line(0, 0);
    imgui.text("):");
}

show_xinput_info_window :: proc(show : ^bool) {
    imgui.begin("XInput Info", show, STD_WINDOW);
    {
        imgui.text("Version: %s", xinput.Version);
        imgui.text("Lib Address: 0x%x", int(xinput.DebugInfo.LibAddress));
        imgui.text("Number of functions loaded: %d/%d", xinput.DebugInfo.NumberOfFunctionsLoadedSuccessed, xinput.DebugInfo.NumberOfFunctionsLoaded); 
        if imgui.collapsing_header("Loaded Functions", 0) {
            imgui.begin_child("Functions", imgui.Vec2{0, 150}, true, 0);
            imgui.columns(2, "nil", false);
            for status in xinput.DebugInfo.Statuses {
                imgui.text(status.Name);
                imgui.next_column();
                imgui.text("Loaded: %t @ 0x%x", status.Success, status.Address);
                imgui.next_column();

            }
            imgui.columns(1, "nil", false);
            imgui.end_child();
        }

        imgui.columns(2, "nil", true);
        for user, i in xinput.User {
            cap, err := xinput.GetCapabilities(user);
            _print_gamepad_name(i, err);
            if err == xinput.Success {
                imgui.text("Capabilites:");
                imgui.indent(20.0);
                    imgui.text("Subtype %s", cap.sub_type);
                    imgui.text("Flags:");
                    imgui.indent(10.0);
                        CheckCapability :: proc(cap : xinput.Capabilities, c : xinput.CapabilitiesFlags) -> bool {
                            return cap.flags & c == c;
                        }

                        imgui.text("Voice:         %t", CheckCapability(cap, xinput.CapabilitiesFlags.Voice)        );
                        imgui.text("FFB:           %t", CheckCapability(cap, xinput.CapabilitiesFlags.FFB)          );
                        imgui.text("Wireless:      %t", CheckCapability(cap, xinput.CapabilitiesFlags.Wireless)     );
                        imgui.text("PMD:           %t", CheckCapability(cap, xinput.CapabilitiesFlags.PMD)          );
                        imgui.text("NoNavigations: %t", CheckCapability(cap, xinput.CapabilitiesFlags.NoNavigations));
                    imgui.unindent(10.0);    
                imgui.unindent(20.0);
                imgui.text("Battery Information:");
                imgui.indent(20.0);
                    imgui.text("Battery Type:  %s", "N/A");
                    imgui.text("Battery Level: %s", "N/A");
                imgui.unindent(20.0);
            }

            imgui.next_column();
            if i%2 == 1 {
                imgui.separator();
            }
        }
        imgui.columns(1, "nil", false);
    }
    imgui.end();
}

show_xinput_state_window :: proc(show : ^bool) {
    imgui.begin("XInput State", show, STD_WINDOW);
    {
        imgui.columns(2, "nil", true);
        for user, i in xinput.User {
            state, err := xinput.GetState(user);
            _print_gamepad_name(i, err);
            if err == xinput.Success {
                imgui.indent(10.0);
                {
                    imgui.separator();
                    imgui.text("button States:");
                    imgui.indent(10.0);
                    {
                        IsButtonPressed :: proc(state : xinput.State, b : xinput.Buttons) -> bool {
                            return state.gamepad.buttons & u16(b) == u16(b);
                        }

                        imgui.text("DpadUp:        %t", IsButtonPressed(state, xinput.Buttons.DpadUp)       );
                        imgui.text("DpadDown:      %t", IsButtonPressed(state, xinput.Buttons.DpadDown)     );
                        imgui.text("DpadLeft:      %t", IsButtonPressed(state, xinput.Buttons.DpadLeft)     );
                        imgui.text("DpadRight:     %t", IsButtonPressed(state, xinput.Buttons.DpadRight)    );
                        imgui.text("Start:         %t", IsButtonPressed(state, xinput.Buttons.Start)        );
                        imgui.text("Back:          %t", IsButtonPressed(state, xinput.Buttons.Back)         );
                        imgui.text("LeftThumb:     %t", IsButtonPressed(state, xinput.Buttons.LeftThumb)    );
                        imgui.text("RightThumb:    %t", IsButtonPressed(state, xinput.Buttons.RightThumb)   );
                        imgui.text("LeftShoulder:  %t", IsButtonPressed(state, xinput.Buttons.LeftShoulder) );
                        imgui.text("RightShoulder: %t", IsButtonPressed(state, xinput.Buttons.RightShoulder));
                        imgui.text("A:             %t", IsButtonPressed(state, xinput.Buttons.A)            );
                        imgui.text("B:             %t", IsButtonPressed(state, xinput.Buttons.B)            );
                        imgui.text("X:             %t", IsButtonPressed(state, xinput.Buttons.X)            );
                        imgui.text("Y:             %t", IsButtonPressed(state, xinput.Buttons.Y)            );
                    }
                    imgui.unindent(10.0);
                    imgui.separator();
                    imgui.text("Trigger States:");
                    imgui.indent(10.0);
                    {
                        imgui.text("Left Trigger:  %d(%.1f%%)", state.gamepad.left_trigger,  (f32(state.gamepad.left_trigger)/255.0)*100.0);
                        imgui.text("Right Trigger: %d(%.1f%%)", state.gamepad.right_trigger, (f32(state.gamepad.right_trigger)/255.0)*100.0);
                    }
                    imgui.unindent(10.0);
                    imgui.separator();
                    imgui.text("Stick States:");
                    imgui.indent(10.0);
                    {
                        imgui.text("Left Stick:  <%d, %d>", state.gamepad.lx, state.gamepad.ly);
                        imgui.text("Right Stick: <%d, %d>", state.gamepad.rx, state.gamepad.ry);
                    }
                    imgui.unindent(10.0);
                    imgui.separator();
                }
                imgui.unindent(10.0);
            }
            
            imgui.next_column();
            if i%2 == 1 {
                imgui.separator();
            }
        }
        imgui.columns(1, "nil", false);
    }
    imgui.end();
}

show_catalog_window :: proc(show : ^bool) {

    PrintName :: proc(asset : ^ja.Asset) {
        PrintLoadedUploaded :: proc(name : string, load : bool, up : bool, asset : ^ja.Asset) {
            imgui.text(name);
            ToolTip(asset);
            imgui.same_line(0, 0);
            imgui.text_colored(imgui.Vec4{1,0,0,1}, " %s", load ? "[Loaded]" : "");
            imgui.same_line(0, 0);
            imgui.text_colored(imgui.Vec4{0,0.78,0,1}, "%s", up ? "[Uploaded]" : "");
        }

        match a in asset {
            case ja.Asset.Texture : {
                PrintLoadedUploaded(a.file_info.name, a.loaded_from_disk, a.gl_id != 0, asset);
            }

            case ja.Asset.Shader : {
                PrintLoadedUploaded(a.file_info.name, a.loaded_from_disk, a.gl_id != 0, asset);
            }

            case : {
                imgui.text("%s %s", a.file_info.name, a.loaded_from_disk ? "[Loaded]" : "");
                ToolTip(asset);
            }
        }
    }

    ToolTip :: proc(val : ^ja.Asset) {
      if(imgui.is_item_hovered()) {
            imgui.begin_tooltip();
            imgui.text("Path:        %s", val.file_info.path);
            imgui.text("Disk Size:   %.2fKB", f32(val.file_info.size)/1024.0);
            match e in val {
                case ja.Asset.Texture : {
                    imgui.text("ID:          %d", e.gl_id);
                    imgui.text("Size:        %dx%d", e.width, e.height);
                    imgui.text("Comp:        %d", e.comp);
                }

                case ja.Asset.Shader : {
                    imgui.text("ID:          %d", e.gl_id);
                    imgui.text("Type:        %v", e.type_);
                }
            }
            imgui.end_tooltip();
        }
    }

    imgui.begin("Catalogs", show, STD_WINDOW);
    {
        imgui.combo("Catalog", &_ChosenCatalog, catalog.debug_info.catalog_names[..], -1);
        imgui.separator();
        cat := catalog.debug_info.catalogs[_ChosenCatalog];
        imgui.text("Folder Path:     %s", cat.path);
        imgui.text("Kind:            %v", cat.kind);
        imgui.text("Accepted Extensions: ");
        imgui.indent(10.0);
        for ext in cat.accepted_extensions {
            imgui.text(ext);
        }
        imgui.unindent(10.0);
        imgui.separator();
        imgui.begin_child("Files", imgui.Vec2{0, -18}, true, 0);
        for val in cat.items {
            PrintName(val);
        }
        imgui.end_child();
        imgui.separator();
        imgui.text("No. of files: %d/%d", len(cat.items), cat.files_in_folder);
        imgui.same_line(0, -1);
        imgui.text("In Memory: %.2fKB/%.2fKB", f32(cat.current_size)/1024.0, f32(cat.max_size)/1024.0);
    }
    imgui.end();
}

show_input_window :: proc(input : ^jinput.Input, show : ^bool) {
    imgui.begin("Input##TESTIUYHSEIFUSEYGF", show, STD_WINDOW);
    {
    imgui.columns(4, "nil", true);
        imgui.text("ID");
        imgui.next_column();
        imgui.text("Key");
        imgui.next_column();
        imgui.text("Xinput button");
        imgui.next_column();
        imgui.text("State");
        imgui.separator();
        imgui.next_column();

        if len(input.bindings) > 0 {
            for v in input.bindings {
                imgui.text("%v", v.id);
                imgui.next_column();
                imgui.text("%v", v.key);
                imgui.next_column();
                imgui.text("%v", v.x_button);
                imgui.next_column();
                imgui.text("%v", jinput.get_button_state(input, v.id));
                imgui.next_column();
            }
        } else {
            imgui.text("No bindings found!");
            imgui.next_column();
            imgui.text("N/A");
            imgui.next_column();
            imgui.text("N/A");
            imgui.next_column();
            imgui.text("N/A");
            imgui.next_column();
        }

        imgui.columns(1, "nil", true);

        PrintDownHeld :: proc(keyStates : []jinput.ButtonStates) {
            imgui.columns(2, "nil", true);
            imgui.text("Key");
            imgui.next_column();
            imgui.text("State");
            imgui.separator();
            imgui.next_column();
            for k in win32.KeyCode {
                if keyStates[k] == jinput.ButtonStates.Down || 
                   keyStates[k] == jinput.ButtonStates.Held {
                    imgui.text("%v", k);
                    imgui.next_column();
                    imgui.text("%v", keyStates[k]);
                    imgui.next_column();
                }      
            }
        }

        PrintUpNeutral :: proc(keyStates : []jinput.ButtonStates) {
            imgui.columns(2, "nil", true);
            imgui.text("Key");
            imgui.next_column();
            imgui.text("State");
            imgui.separator();
            imgui.next_column();
            for k in win32.KeyCode {
                if keyStates[k] == jinput.ButtonStates.Up || 
                   keyStates[k] == jinput.ButtonStates.Neutral {
                    imgui.text("%v", k);
                    imgui.next_column();
                    imgui.text("%v", keyStates[k]);
                    imgui.next_column();
                }      
            }
        }

        imgui.separator();
        if imgui.collapsing_header("Key states", 0) {
            imgui.columns(2, "nil", true);
            imgui.begin_child("Down Held", imgui.Vec2{0, 0}, true, 0);
            PrintDownHeld(input.key_states[..]);
            imgui.end_child();
            imgui.next_column();
            imgui.begin_child("Up Neutral", imgui.Vec2{0, 0}, true, 0);
            PrintUpNeutral(input.key_states[..]);
            imgui.end_child();
            imgui.next_column();
        }
    }
    imgui.end();
}