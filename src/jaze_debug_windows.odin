#import "fmt.odin";
#import gl "jaze_gl.odin";
#import xinput "jaze_xinput.odin";
#import "odimgui/src/imgui.odin";
#import "main.odin";
#import time "jaze_time.odin";
#import catalog "jaze_catalog.odin";
#import ja "jaze_asset.odin";

_StdWindowFlags :: imgui.GuiWindowFlags.ShowBorders | imgui.GuiWindowFlags.NoCollapse;

_GlobalDebugWndBools : map[string]bool;
_CurrentViewTexture : gl.Texture;
_ChosenCatalog : i32;

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
        p(^b);
        SetWindowState(id, b);
    }
}

OpenGLExtensions :: proc(name : string, extensions : [dynamic]string, show : ^bool) {
    imgui.Begin(name, show, _StdWindowFlags); 
    {
        //imgui.BeginChild("Ext", imgui.Vec2{0, 0}, true, 0);
        for ext in extensions {
            imgui.Text(ext);
        }
        //imgui.EndChild();   
    }   
    imgui.End();
}

OpenGLTextureOverview :: proc(show : ^bool) {
    imgui.Begin("Loaded Textures", show, _StdWindowFlags);
    {
        for id in gl.DebugInfo.LoadedTextures {
            imgui.PushIdInt(cast(i32)id);
            imgui.Text("Texture %d:", id); imgui.SameLine(0, -1);
            if imgui.Button("View", imgui.Vec2{0, 0}) {
                _CurrentViewTexture = id;
                SetWindowState("ViewGLTexture", true);
            }
            imgui.PopId();
        }
    }
    imgui.End();

    if GetWindowState("ViewGLTexture") {
        b := GetWindowState("ViewGLTexture");
        OpenGLTextureView(_CurrentViewTexture, ^b);
        SetWindowState("ViewGLTexture", b);
    }
}

OpenGLTextureView :: proc(textureId : gl.Texture, show : ^bool) {
    imgui.Begin("Texture View", show, _StdWindowFlags);
    {
        imgui.Image(cast(imgui.TextureID)cast(uint)1, imgui.Vec2{100, 100}, imgui.Vec2{0, 0}, imgui.Vec2{1, 1}, imgui.Vec4{1, 1, 1, 1}, imgui.Vec4{0, 0, 0, 0});
    }
    imgui.End();
}
OpenGLInfo :: proc(vars : ^gl.OpenGLVars_t, show : ^bool) {
    imgui.Begin("OpenGL Info", show, _StdWindowFlags);
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
            if imgui.Button("View##Ext", imgui.Vec2{0, 0}) {
                SetWindowState("OpenGLShowExtensions", true);
            }
            imgui.Text("Number of WGL extensions:   %d", vars.NumWglExtensions); imgui.SameLine(0, -1); 
            if imgui.Button("View##WGL", imgui.Vec2{0, 0}) {
                SetWindowState("OpenGLShowWGLExtensions", true);
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
                if status.Success {
                    suc = "true";
                } else {
                    suc = "false";
                }
                imgui.Text("Loaded: %s", suc);
                imgui.NextColumn();

            }
            imgui.Columns(1, nil, false);
            imgui.EndChild();
        }

        imgui.Text("Number of loaded textures: %d", len(gl.DebugInfo.LoadedTextures)); imgui.SameLine(0, -1);
        if imgui.Button("View##Texture", imgui.Vec2{0, 0}) {
            SetWindowState("ShowGLTextureOverview", true);
        }
    }
    imgui.End();

    if GetWindowState("OpenGLShowExtensions") {
        b := GetWindowState("OpenGLShowExtensions");
        OpenGLExtensions("Extensions##Ext", vars.Extensions, ^b);
        SetWindowState("OpenGLShowExtensions", b);
    }

    if GetWindowState("OpenGLShowWGLExtensions") {
        b := GetWindowState("OpenGLShowWGLExtensions");
        OpenGLExtensions("WGL Extensions", vars.WglExtensions, ^b);
        SetWindowState("OpenGLShowWGLExtensions", b);
    }

    TryShowWindow("ShowGLTextureOverview", OpenGLTextureOverview);
}

Win32VarsInfo :: proc(vars : ^main.Win32Vars_t, show : ^bool) {
    imgui.Begin("Win32Vars Info", show, _StdWindowFlags);
    {
        imgui.Text("Application Handle:    0x%X", cast(int)vars.AppHandle);
        imgui.Text("Window Handle:         0x%X", cast(int)vars.WindowHandle);
        imgui.Text("Window Size:           {%.3f, %.3f}", vars.WindowSize.x, vars.WindowSize.y);
        imgui.Text("Device Context Handle: 0x%X", cast(int)vars.DeviceCtx);
    }
    imgui.End();
}

ShowXinputInfoWindow :: proc(show : ^bool) {
    imgui.Begin("XInput Info", show, _StdWindowFlags);
    {
        imgui.Text("Version: %s", xinput.Version);
        imgui.Text("Lib Address: 0x%x", cast(int)xinput.DebugInfo.LibAddress);
        imgui.Text("Number of functions loaded: %d/%d", xinput.DebugInfo.NumberOfFunctionsLoadedSuccessed, xinput.DebugInfo.NumberOfFunctionsLoaded); 
        if imgui.CollapsingHeader("Loaded Functions", 0) {
            imgui.BeginChild("Functions", imgui.Vec2{0, 0}, true, 0);
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

        for i in 0..4 { //I WANT TO DO THIS Pl0x for(user in xinput.Users) 
            cap, err := xinput.GetCapabilities(cast(xinput.User)i);
            imgui.Text("Gamepad %d(%s):", i+1, err == xinput.Success ? "Connected" : "Not Connected");
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
            imgui.Separator();
        }
    }
    imgui.End();
}

ShowXinputStateWindow :: proc(show : ^bool) {
    imgui.Begin("XInput State", show, _StdWindowFlags);
    {
        for i in 0..4 {
            state, err := xinput.GetState(cast(xinput.User)i);
            imgui.Text("Gamepad %d(%s):", i+1, err == xinput.Success ? "Connected" : "Not Connected");
            if err == xinput.Success {
                imgui.Indent(10.0);
                {
                    imgui.Separator();
                    imgui.Text("Button States:");
                    imgui.Indent(10.0);
                    {
                        IsButtonPressed :: proc(state : xinput.State, b : xinput.Buttons) -> bool {
                            return state.Gamepad.Buttons & cast(u16)b == cast(u16)b;
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
                        imgui.Text("Left Trigger:  %d(%.1f%%)", state.Gamepad.LeftTrigger,  (cast(f32)state.Gamepad.LeftTrigger/255.0)*100.0);
                        imgui.Text("Right Trigger: %d(%.1f%%)", state.Gamepad.RightTrigger, (cast(f32)state.Gamepad.RightTrigger/255.0)*100.0);
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
        }
    }
    imgui.End();
}

ShowTimeDataWindow :: proc(show : ^bool) {
    imgui.Begin("Time Data", show, _StdWindowFlags);
    {
        data := time.GetTimeData();
        imgui.Text("Time Scale:               %f", data.TimeScale);
        imgui.Text("Unscaled DeltaTime:       %.10f", data.DeltaTime);
        imgui.Text("DeltaTime:                %.10f", data.DeltaTime * data.TimeScale);
        imgui.Text("Time Since Start:         %f", data.TimeSinceStart);
        imgui.Text("Frame Count Since Start:  %d", data.FrameCountSinceStart);
        imgui.NewLine();
        imgui.Text("pfFreq: %d", data.pfFreq);
        imgui.Text("pfOld:  %d", data.pfOld);
    }
    imgui.End();
}

ShowCatalogWindow :: proc(show : ^bool) {

    PrintName :: proc(asset : ja.Asset) {
        PrintLoadedUploaded :: proc(name : string, load : bool, up : bool) {
            imgui.Text("%s %s%s", name, load ? "[Loaded]" : "",
                       up ? "[Uploaded]" : "");
        }

        match a in asset {
            case ja.Asset.Texture : {
                PrintLoadedUploaded(a.FileInfo.Name, a.LoadedFromDisk, a.GLID != 0);
            }

            case ja.Asset.Shader : {
                PrintLoadedUploaded(a.FileInfo.Name, a.LoadedFromDisk, a.GLID != 0);
            }

            default : {
                imgui.Text("%s %s", a.FileInfo.Name, a.LoadedFromDisk ? "[Loaded]" : "");
            }
        }
    }

    imgui.Begin("Catalogs", show, _StdWindowFlags);
    {
        imgui.Combo("Catalog", ^_ChosenCatalog, catalog.DebugInfo.CatalogNames[..], -1);
        imgui.Separator();
        cat := catalog.DebugInfo.Catalogs[_ChosenCatalog];
        imgui.Text("Folder Path:     %s", cat.Path);
        imgui.Text("Kind:            %v", cat.Kind);
        imgui.Text("Number of files: %d/%d", len(cat.Items), cat.FilesInFolder);
        imgui.Text("Size:            %.2fKB/%.2fKB", cast(f32)cat.CurrentSize/1024.0, cast(f32)cat.MaxSize/1024.0);
        imgui.Text("Accepted Extensions: ");
        imgui.Indent(10.0);
        for ext in cat.AcceptedExtensions {
            imgui.Text(ext);
        }
        imgui.Unindent(10.0);
        imgui.Separator();
        imgui.BeginChild("Files", imgui.Vec2{0, 0}, true, 0);
        for val in cat.Items {
            PrintName(val^);
            if(imgui.IsItemHovered()) {
                imgui.BeginTooltip();
                imgui.Text("Path:   %s", val.FileInfo.Path);
                imgui.Text("Size:   %.2fKB", cast(f32)val.FileInfo.Size/1024.0);
                match e in val {
                    case ja.Asset.Texture : {
                        imgui.Text("ID:     %d", e.GLID);
                        imgui.Text("Width:  %d", e.Width);
                        imgui.Text("Height: %d", e.Height);
                        imgui.Text("Comp:   %d", e.Comp);
                    }

                    case ja.Asset.Shader : {
                        imgui.Text("ID:     %d", e.GLID);
                        imgui.Text("Type:   %v", e.Type);
                    }
                }
                imgui.EndTooltip();
            }
        }
        imgui.EndChild();
    }
    imgui.End();
}