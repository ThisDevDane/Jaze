#import "fmt.odin";
#import win32 "sys/windows.odin";
#import "gl.odin";
#import "xinput.odin";
#import "imgui.odin";
#import "main.odin";
#import "time.odin";
#import "catalog.odin";
#import "console.odin";
#import "game.odin";
#import jinput "input.odin";
#import ja "asset.odin";
#import je "entity.odin";
#import p32 "platform_win32.odin";

STD_WINDOW :: /*imgui.GuiWindowFlags.ShowBorders |*/  imgui.GuiWindowFlags.NoCollapse;

_GlobalDebugWndBools : map[string]bool;
_ChosenCatalog : i32;
_PreviewSize := imgui.Vec2{20, 20};
_ShowID : gl.Texture = 1;

GetWindowState :: proc(str : string) -> bool {
    return _GlobalDebugWndBools[str];
}

SetWindowState :: proc(str : string, state : bool) {
    _GlobalDebugWndBools[str] = state;
}

ToggleWindow :: proc(str : string) {
    _GlobalDebugWndBools[str] = !_GlobalDebugWndBools[str];
}

TryShowWindow :: proc(id : string, p : proc(b : ^bool)) {
    if GetWindowState(id) {
        b := GetWindowState(id);
        p(&b);
        SetWindowState(id, b);
    }
}

_ChosenEntity : ^je.Entity;

ShowEntityList :: proc(gameCtx : ^game.Context_t, show : ^bool) {
    PrintNormalTower :: proc(t : je.Tower) {
        imgui.Indent(10);
        {
            if imgui.CollapsingHeader("Transform", 0) {
                imgui.Indent(10);
                imgui.Text("Position: %v", t.Position);
                imgui.Text("Scale: %v", t.Scale);
                imgui.Text("Rotation: %v", t.Rotation);
                imgui.Unindent(10);
            }
            imgui.Text("Damage: %v", t.Damage);
            imgui.Text("Attack Speed: %v", t.AttackSpeed);
            if t.Texture != nil {
                imgui.TextWrapped("Texture: %v", t.Texture^);
            } else {
                imgui.Text("Texture: N/A");
            } 
        }
        imgui.Unindent(10);
    }
    
    PrintSlowTower :: proc(e : je.Tower.Slow) {
        imgui.Indent(10);
        {
            imgui.Text("Slow Rate: %v", e.SlowFactor);
        }
        imgui.Unindent(10);
    }

    imgui.Begin("Entity List", show, STD_WINDOW);
    {
        imgui.Columns(2, nil, false);
        imgui.BeginChild("Entities", imgui.Vec2{0, -20}, true, 0);
        {
            for i := gameCtx.EntityList.Front;
                i != nil;
                i = i.Next {

                buf : [256]byte;
                str := fmt.bprintf(buf[..], "%s(%d)", i.Entity.Name, i.Entity.GUID);
                if imgui.Button(str, imgui.Vec2{-1, 0}) {
                    _ChosenEntity = i.Entity;   
                }
            }
        }
        imgui.EndChild();
        imgui.NextColumn();
        imgui.BeginChild("Entity", imgui.Vec2{0, -20}, true, 0);
        {
            if _ChosenEntity != nil {
                imgui.Text("GUID: %v", _ChosenEntity.GUID);
                imgui.Text("Name: %v", _ChosenEntity.Name);
                match e in _ChosenEntity {
                    case je.Entity.Tower : {
                        match t in e.T {
                            case je.Tower.Slow : {
                                imgui.Text("Match: %d", e.T.__tag);
                                PrintNormalTower(e.T);
                                PrintSlowTower(t);
                            }

                            case je.Tower.Basic : {
                                imgui.Text("Match: %d", e.T.__tag);
                                PrintNormalTower(e.T);
                            }

                            default : {
                                imgui.Text("Match: %d", e.T.__tag);
                            }
                        }
                    }
                }
            }
        }
        imgui.EndChild();
        imgui.Columns(1, nil, false);
        imgui.Separator();
        imgui.TextColored(imgui.Vec4{1, 1, 1, 0.2}, "Entities: %d", gameCtx.EntityList.Count);
    }
    imgui.End();


}

ShowDebugWindowStates :: proc(show : ^bool) {
    imgui.Begin("Debug Window States", show, STD_WINDOW);
    {
        imgui.Text("Chosen Catalog Index: %d", _ChosenCatalog);
        imgui.Text("Texture Preview Sixe: <%.2f,%.2f>", _PreviewSize.x, _PreviewSize.y);
        imgui.Text("Texture Show ID:      %d", _ShowID);
        imgui.Separator();_CurrentViewTexture : gl.Texture;
_ChosenCatalog : i32;
_PreviewSize := imgui.Vec2{20, 20};
_ShowID : gl.Texture = 1;

        imgui.BeginChild("Window States", imgui.Vec2{0, 0}, true, 0);
        imgui.Columns(2, nil, true);
        for val, id in _GlobalDebugWndBools {
            imgui.Text("%s", id);
            imgui.NextColumn();
            imgui.Text("%t", val);
            imgui.NextColumn();
            imgui.Separator();
        }
        imgui.Columns(1, nil, true);
        imgui.EndChild();
    }
    imgui.End();
}

StatOverlay :: proc(show : ^bool) {
    imgui.SetNextWindowPos(imgui.Vec2{5, 25}, 0);
    imgui.PushStyleColor(imgui.GuiCol.WindowBg, imgui.Vec4{0.23, 0.23, 0.23, 0.4});
    imgui.Begin("Stat Overlay", show, imgui.GuiWindowFlags.NoMove | imgui.GuiWindowFlags.NoTitleBar | imgui.GuiWindowFlags.NoResize | imgui.GuiWindowFlags.NoSavedSettings); 
    {
        io := imgui.GetIO();
        imgui.Text("Framerate: %.1ffps (%fms) ", io.Framerate, 1000.0 / io.Framerate);
        imgui.Separator();
    }   
    imgui.End();
    imgui.PopStyleColor(1);
}

OpenGLExtensions :: proc(name : string, extensions : [dynamic]string, show : ^bool) {
    imgui.Begin(name, show, STD_WINDOW); 
    {
        for ext in extensions {
            imgui.Text(ext);
        }
    }   
    imgui.End();
}

OpenGLTextureOverview :: proc(show : ^bool) {
    _CalculateMaxColumns :: proc(w : f32, csize : f32, max : i32) -> i32 {
        Columns := i32(w / csize);
        if Columns > max {
            Columns = max;
        }

        if Columns <= 0 {
            Columns = 1;
        }
        return Columns;
    }

    imgui.Begin("Loaded Textures", show, STD_WINDOW);
    {
        imgui.DragFloat("Preview Size:", &_PreviewSize.x, 0.2, 20, 100, "%.0f", 1);
        imgui.Separator();
        _PreviewSize.y = _PreviewSize.x;
        size : imgui.Vec2;
        imgui.GetWindowSize(&size);
        Columns := _CalculateMaxColumns(size.x, _PreviewSize.x + 24, i32(len(gl.DebugInfo.LoadedTextures)));
        imgui.BeginChild("", imgui.Vec2{0, 0}, false, 0);
        {
            imgui.Columns(Columns, nil, false);
            for id in gl.DebugInfo.LoadedTextures {
                imgui.Image(imgui.TextureID(uint(id)), _PreviewSize, imgui.Vec2{0, 0}, imgui.Vec2{1, 1}, imgui.Vec4{1, 1, 1, 1}, imgui.Vec4{0.91, 0.4, 0.23, 1});
                if imgui.IsItemHovered() {
                    imgui.BeginTooltip();
                    {
                        imgui.Text("ID: %d", id);
                    }
                    imgui.EndTooltip();
                }
                if imgui.IsItemClicked(0) {
                    _ShowID = id;
                }
                imgui.NextColumn();
            }
            imgui.Columns(1, nil, false);
            }
        imgui.EndChild();
    }
    imgui.End();

    imgui.Begin("Texture View", nil, STD_WINDOW | imgui.GuiWindowFlags.NoScrollbar);
    {
        size : imgui.Vec2;
        imgui.GetWindowSize(&size);
        imgui.Image(imgui.TextureID(uint(_ShowID)), imgui.Vec2{size.x-16, size.y-35}, imgui.Vec2{0, 0}, imgui.Vec2{1, 1}, imgui.Vec4{1, 1, 1, 1}, imgui.Vec4{0.91, 0.4, 0.23, 0});
    }
    imgui.End();
}

OpenGLInfo :: proc(vars : ^gl.OpenGLVars_t, show : ^bool) {
    imgui.Begin("OpenGL Info", show, STD_WINDOW);
    {
        imgui.Text("Versions:");
        imgui.Indent(20.0);
            imgui.Text("Highest: %d.%d", vars.VersionMajorMax, vars.VersionMinorMax);
            imgui.Text("Current: %d.%d", vars.VersionMajorCur, vars.VersionMajorCur);
            imgui.Text("GLSL:    %s", vars.GLSLVersionString);
        imgui.Unindent(20.0);
        imgui.Text("Lib Address 0x%x", gl.DebugInfo.LibAddress);
        imgui.Separator();
            imgui.Text("Vendor:   %s", vars.VendorString);
            imgui.Text("Render:   %s", vars.RendererString);
            imgui.Text("CtxFlags: %d", vars.ContextFlags);
        imgui.Separator();
            imgui.Text("Number of extensions:       %d", vars.NumExtensions); imgui.SameLine(0, -1);
            if imgui.SmallButton("View##Ext") {
                SetWindowState("OpenGLShowExtensions", true);
            }
            imgui.Text("Number of WGL extensions:   %d", vars.NumWglExtensions);imgui.SameLine(0, -1);
            if imgui.SmallButton("View##WGL") {
                SetWindowState("OpenGLShowWGLExtensions", true);
            }
            imgui.Text("Number of loaded textures: %d", len(gl.DebugInfo.LoadedTextures)); imgui.SameLine(0, -1);
            if imgui.SmallButton("View##Texture") {
                SetWindowState("ShowGLTextureOverview", true);
            }
            imgui.Text("Number of functions loaded: %d/%d", gl.DebugInfo.NumberOfFunctionsLoadedSuccessed, gl.DebugInfo.NumberOfFunctionsLoaded); 
        imgui.Separator();
        if imgui.CollapsingHeader("Loaded Functions", 0) {
            imgui.BeginChild("Functions###FuncLoad", imgui.Vec2{0, 0}, true, 0);
            imgui.Columns(2, nil, false);
            suc : string;
            for status in gl.DebugInfo.Statuses {
                imgui.Text(status.Name);
/*                if(imgui.IsItemHovered()) {
                    imgui.BeginTooltip();
                    imgui.PushTextWrapPos(450.0);
                    imgui.Text("%s @ 0x%X", status.Name, status.Address);
                    /*buf : [4095]byte;
                    procString : string;
                    */
                    
                    test1, ok1 := union_cast(^Type_Info.Procedure)status.TypeInfo;
                    test2, ok2 := union_cast(^Type_Info.Tuple)test1.params;
                    imgui.Text("%t", ok1);
                    imgui.Text("%t", ok2);
                    imgui.Text("%d", len(test2.names));
                    for info in test2.names {
                        imgui.Text(info);
                    }

                    imgui.PopTextWrapPos();
                    imgui.EndTooltip();
                }*/
                imgui.NextColumn();
                c : imgui.Vec4;
                if status.Success {
                    c = imgui.Vec4{0,0.78,0,1};
                    suc = "true";
                } else {
                    c = imgui.Vec4{1,0,0,1};
                    suc = "false";
                }

                imgui.TextColored(c, "Loaded: %s", suc);
                imgui.NextColumn();

            }
            imgui.Columns(1, nil, false);
            imgui.EndChild();
        }
    }
    imgui.End();

    if GetWindowState("OpenGLShowExtensions") {
        b := GetWindowState("OpenGLShowExtensions");
        OpenGLExtensions("Extensions##Ext", vars.Extensions, &b);
        SetWindowState("OpenGLShowExtensions", b);
    }

    if GetWindowState("OpenGLShowWGLExtensions") {
        b := GetWindowState("OpenGLShowWGLExtensions");
        OpenGLExtensions("WGL Extensions", vars.WglExtensions, &b);
        SetWindowState("OpenGLShowWGLExtensions", b);
    }

    TryShowWindow("ShowGLTextureOverview", OpenGLTextureOverview);
}

Win32VarsInfo :: proc(vars : ^p32.Data_t, show : ^bool) {
    imgui.Begin("Win32Vars Info", show, STD_WINDOW);
    {
        imgui.Text("Application Handle:    0x%X", int(vars.AppHandle));
        imgui.Text("Window Handle:         0x%X", int(vars.WindowHandle));
        imgui.Text("Device Context Handle: 0x%X", int(vars.DeviceCtx));
    }
    imgui.End();
}

_PrintGamepadName :: proc(id : int, err : xinput.Error) {
    imgui.Text("Gamepad %d(", id+1);
    b := err == xinput.Success;
    c : imgui.Vec4;
    if b {
        c = imgui.Vec4{0,0.78,0,1};
    } else {
        c = imgui.Vec4{1,0,0,1};
    }
    imgui.SameLine(0, 0);
    imgui.TextColored(c, "%s", b ? "Connected" : "Not Connected");
    imgui.SameLine(0, 0);
    imgui.Text("):");
}

ShowXinputInfoWindow :: proc(show : ^bool) {
    imgui.Begin("XInput Info", show, STD_WINDOW);
    {
        imgui.Text("Version: %s", xinput.Version);
        imgui.Text("Lib Address: 0x%x", int(xinput.DebugInfo.LibAddress));
        imgui.Text("Number of functions loaded: %d/%d", xinput.DebugInfo.NumberOfFunctionsLoadedSuccessed, xinput.DebugInfo.NumberOfFunctionsLoaded); 
        if imgui.CollapsingHeader("Loaded Functions", 0) {
            imgui.BeginChild("Functions", imgui.Vec2{0, 150}, true, 0);
            imgui.Columns(2, nil, false);
            for status in xinput.DebugInfo.Statuses {
                imgui.Text(status.Name);
                imgui.NextColumn();
                imgui.Text("Loaded: %t @ 0x%x", status.Success, status.Address);
                imgui.NextColumn();

            }
            imgui.Columns(1, nil, false);
            imgui.EndChild();
        }

        imgui.Columns(2, nil, true);
        for user, i in xinput.User {
            cap, err := xinput.GetCapabilities(user);
            _PrintGamepadName(i, err);
            if err == xinput.Success {
                imgui.Text("Capabilites:");
                imgui.Indent(20.0);
                    imgui.Text("Subtype %s", cap.SubType);
                    imgui.Text("Flags:");
                    imgui.Indent(10.0);
                        CheckCapability :: proc(cap : xinput.Capabilities, c : xinput.CapabilitiesFlags) -> bool {
                            return cap.Flags & c == c;
                        }

                        imgui.Text("Voice:         %t", CheckCapability(cap, xinput.CapabilitiesFlags.Voice)        );
                        imgui.Text("FFB:           %t", CheckCapability(cap, xinput.CapabilitiesFlags.FFB)          );
                        imgui.Text("Wireless:      %t", CheckCapability(cap, xinput.CapabilitiesFlags.Wireless)     );
                        imgui.Text("PMD:           %t", CheckCapability(cap, xinput.CapabilitiesFlags.PMD)          );
                        imgui.Text("NoNavigations: %t", CheckCapability(cap, xinput.CapabilitiesFlags.NoNavigations));
                    imgui.Unindent(10.0);    
                imgui.Unindent(20.0);
                imgui.Text("Battery Information:");
                imgui.Indent(20.0);
                    imgui.Text("Battery Type:  %s", "N/A");
                    imgui.Text("Battery Level: %s", "N/A");
                imgui.Unindent(20.0);
            }

            imgui.NextColumn();
            if i%2 == 1 {
                imgui.Separator();
            }
        }
        imgui.Columns(1, nil, false);
    }
    imgui.End();
}

ShowXinputStateWindow :: proc(show : ^bool) {
    imgui.Begin("XInput State", show, STD_WINDOW);
    {
        imgui.Columns(2, nil, true);
        for user, i in xinput.User {
            state, err := xinput.GetState(user);
            _PrintGamepadName(i, err);
            if err == xinput.Success {
                imgui.Indent(10.0);
                {
                    imgui.Separator();
                    imgui.Text("Button States:");
                    imgui.Indent(10.0);
                    {
                        IsButtonPressed :: proc(state : xinput.State, b : xinput.Buttons) -> bool {
                            return state.Gamepad.Buttons & u16(b) == u16(b);
                        }

                        imgui.Text("DpadUp:        %t", IsButtonPressed(state, xinput.Buttons.DpadUp)       );
                        imgui.Text("DpadDown:      %t", IsButtonPressed(state, xinput.Buttons.DpadDown)     );
                        imgui.Text("DpadLeft:      %t", IsButtonPressed(state, xinput.Buttons.DpadLeft)     );
                        imgui.Text("DpadRight:     %t", IsButtonPressed(state, xinput.Buttons.DpadRight)    );
                        imgui.Text("Start:         %t", IsButtonPressed(state, xinput.Buttons.Start)        );
                        imgui.Text("Back:          %t", IsButtonPressed(state, xinput.Buttons.Back)         );
                        imgui.Text("LeftThumb:     %t", IsButtonPressed(state, xinput.Buttons.LeftThumb)    );
                        imgui.Text("RightThumb:    %t", IsButtonPressed(state, xinput.Buttons.RightThumb)   );
                        imgui.Text("LeftShoulder:  %t", IsButtonPressed(state, xinput.Buttons.LeftShoulder) );
                        imgui.Text("RightShoulder: %t", IsButtonPressed(state, xinput.Buttons.RightShoulder));
                        imgui.Text("A:             %t", IsButtonPressed(state, xinput.Buttons.A)            );
                        imgui.Text("B:             %t", IsButtonPressed(state, xinput.Buttons.B)            );
                        imgui.Text("X:             %t", IsButtonPressed(state, xinput.Buttons.X)            );
                        imgui.Text("Y:             %t", IsButtonPressed(state, xinput.Buttons.Y)            );
                    }
                    imgui.Unindent(10.0);
                    imgui.Separator();
                    imgui.Text("Trigger States:");
                    imgui.Indent(10.0);
                    {
                        imgui.Text("Left Trigger:  %d(%.1f%%)", state.Gamepad.LeftTrigger,  (f32(state.Gamepad.LeftTrigger)/255.0)*100.0);
                        imgui.Text("Right Trigger: %d(%.1f%%)", state.Gamepad.RightTrigger, (f32(state.Gamepad.RightTrigger)/255.0)*100.0);
                    }
                    imgui.Unindent(10.0);
                    imgui.Separator();
                    imgui.Text("Stick States:");
                    imgui.Indent(10.0);
                    {
                        imgui.Text("Left Stick:  <%d, %d>", state.Gamepad.LX, state.Gamepad.LY);
                        imgui.Text("Right Stick: <%d, %d>", state.Gamepad.RX, state.Gamepad.RY);
                    }
                    imgui.Unindent(10.0);
                    imgui.Separator();
                }
                imgui.Unindent(10.0);
            }
            
            imgui.NextColumn();
            if i%2 == 1 {
                imgui.Separator();
            }
        }
        imgui.Columns(1, nil, false);
    }
    imgui.End();
}

ShowTimeDataWindow :: proc(data : ^time.Data_t, show : ^bool) {
    imgui.Begin("Time Data", show, STD_WINDOW);
    {
        imgui.Text("Time Scale:               %f", data.TimeScale);
        imgui.Text("Unscaled DeltaTime:       %.10f", data.UnscaledDeltaTime);
        imgui.Text("DeltaTime:                %.10f", data.DeltaTime);
        imgui.Text("Time Since Start:         %f", data.TimeSinceStart);
        imgui.Text("Frame Count Since Start:  %d", data.FrameCountSinceStart);
        imgui.NewLine();
        imgui.Text("pfFreq: %d", data.pfFreq);
        imgui.Text("pfOld:  %d", data.pfOld);
    }
    imgui.End();
}

ShowCatalogWindow :: proc(show : ^bool) {

    PrintName :: proc(asset : ^ja.Asset) {
        PrintLoadedUploaded :: proc(name : string, load : bool, up : bool, asset : ^ja.Asset) {
            imgui.Text(name);
            ToolTip(asset);
            imgui.SameLine(0, 0);
            imgui.TextColored(imgui.Vec4{1,0,0,1}, " %s", load ? "[Loaded]" : "");
            imgui.SameLine(0, 0);
            imgui.TextColored(imgui.Vec4{0,0.78,0,1}, "%s", up ? "[Uploaded]" : "");
        }

        match a in asset {
            case ja.Asset.Texture : {
                PrintLoadedUploaded(a.FileInfo.Name, a.LoadedFromDisk, a.GLID != 0, asset);
            }

            case ja.Asset.Shader : {
                PrintLoadedUploaded(a.FileInfo.Name, a.LoadedFromDisk, a.GLID != 0, asset);
            }

            default : {
                imgui.Text("%s %s", a.FileInfo.Name, a.LoadedFromDisk ? "[Loaded]" : "");
                ToolTip(asset);
            }
        }
    }

    ToolTip :: proc(val : ^ja.Asset) {
      if(imgui.IsItemHovered()) {
            imgui.BeginTooltip();
            imgui.Text("Path:        %s", val.FileInfo.Path);
            imgui.Text("Disk Size:   %.2fKB", f32(val.FileInfo.Size)/1024.0);
            match e in val {
                case ja.Asset.Texture : {
                    imgui.Text("ID:          %d", e.GLID);
                    imgui.Text("Size:        %dx%d", e.Width, e.Height);
                    imgui.Text("Comp:        %d", e.Comp);
                }

                case ja.Asset.Shader : {
                    imgui.Text("ID:          %d", e.GLID);
                    imgui.Text("Type:        %v", e.Type);
                }
            }
            imgui.EndTooltip();
        }
    }

    imgui.Begin("Catalogs", show, STD_WINDOW);
    {
        imgui.Combo("Catalog", &_ChosenCatalog, catalog.DebugInfo.CatalogNames[..], -1);
        imgui.Separator();
        cat := catalog.DebugInfo.Catalogs[_ChosenCatalog];
        imgui.Text("Folder Path:     %s", cat.Path);
        imgui.Text("Kind:            %v", cat.Kind);
        imgui.Text("Accepted Extensions: ");
        imgui.Indent(10.0);
        for ext in cat.AcceptedExtensions {
            imgui.Text(ext);
        }
        imgui.Unindent(10.0);
        imgui.Separator();
        imgui.BeginChild("Files", imgui.Vec2{0, -18}, true, 0);
        for val in cat.Items {
            PrintName(val);
        }
        imgui.EndChild();
        imgui.Separator();
        imgui.Text("No. of files: %d/%d", len(cat.Items), cat.FilesInFolder);
        imgui.SameLine(0, -1);
        imgui.Text("In Memory: %.2fKB/%.2fKB", f32(cat.CurrentSize)/1024.0, f32(cat.MaxSize)/1024.0);
    }
    imgui.End();
}

ShowInputWindow :: proc(input : ^jinput.Input_t, show : ^bool) {
    imgui.Begin("Input##TESTIUYHSEIFUSEYGF", show, STD_WINDOW);
    {
    imgui.Columns(4, nil, true);
        imgui.Text("ID");
        imgui.NextColumn();
        imgui.Text("Key");
        imgui.NextColumn();
        imgui.Text("Xinput Button");
        imgui.NextColumn();
        imgui.Text("State");
        imgui.Separator();
        imgui.NextColumn();

        if len(input.Bindings) > 0 {
            for v in input.Bindings {
                imgui.Text("%v", v.ID);
                imgui.NextColumn();
                imgui.Text("%v", v.Key);
                imgui.NextColumn();
                imgui.Text("%v", v.XKey);
                imgui.NextColumn();
                imgui.Text("%v", jinput.GetButtonState(input, v.ID));
                imgui.NextColumn();
            }
        } else {
            imgui.Text("No bindings found!");
            imgui.NextColumn();
            imgui.Text("N/A");
            imgui.NextColumn();
            imgui.Text("N/A");
            imgui.NextColumn();
            imgui.Text("N/A");
            imgui.NextColumn();
        }

        imgui.Columns(1, nil, true);

        PrintDownHeld :: proc(keyStates : []jinput.ButtonStates) {
            imgui.Columns(2, nil, true);
            imgui.Text("Key");
            imgui.NextColumn();
            imgui.Text("State");
            imgui.Separator();
            imgui.NextColumn();
            for k in win32.Key_Code {
                if keyStates[k] == jinput.ButtonStates.Down || 
                   keyStates[k] == jinput.ButtonStates.Held {
                    imgui.Text("%v", k);
                    imgui.NextColumn();
                    imgui.Text("%v", keyStates[k]);
                    imgui.NextColumn();
                }      
            }
        }

        PrintUpNeutral :: proc(keyStates : []jinput.ButtonStates) {
            imgui.Columns(2, nil, true);
            imgui.Text("Key");
            imgui.NextColumn();
            imgui.Text("State");
            imgui.Separator();
            imgui.NextColumn();
            for k in win32.Key_Code {
                if keyStates[k] == jinput.ButtonStates.Up || 
                   keyStates[k] == jinput.ButtonStates.Neutral {
                    imgui.Text("%v", k);
                    imgui.NextColumn();
                    imgui.Text("%v", keyStates[k]);
                    imgui.NextColumn();
                }      
            }
        }

        imgui.Separator();
        if imgui.CollapsingHeader("Key states", 0) {
            imgui.Columns(2, nil, true);
            imgui.BeginChild("Down Held", imgui.Vec2{0, 0}, true, 0);
            PrintDownHeld(input.KeyStates[..]);
            imgui.EndChild();
            imgui.NextColumn();
            imgui.BeginChild("Up Neutral", imgui.Vec2{0, 0}, true, 0);
            PrintUpNeutral(input.KeyStates[..]);
            imgui.EndChild();
            imgui.NextColumn();
        }
    }
    imgui.End();
}