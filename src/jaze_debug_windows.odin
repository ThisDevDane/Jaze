#import "fmt.odin";
#import gl "jaze_gl.odin";
#import xinput "jaze_xinput.odin";
#import "odimgui/src/imgui.odin";
#import "main.odin";
#import time "jaze_time.odin";
#import catalog "jaze_catalog.odin";
#import ja "jaze_asset.odin";

StdWindowFlags :: imgui.GuiWindowFlags.ShowBorders | imgui.GuiWindowFlags.NoCollapse;

GlobalDebugWndBools : map[string]bool;
CurrentViewTexture : gl.Texture;

OpenGLExtensions :: proc(name : string, extensions : [dynamic]string, show : ^bool) {
    imgui.Begin(name, show, StdWindowFlags); 
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
    imgui.Begin("Loaded Textures", show, StdWindowFlags);
    {
        for id in gl.DebugInfo.LoadedTextures {
            imgui.PushIdInt(cast(i32)id);
            imgui.Text("Texture %d:", id); imgui.SameLine(0, -1);
            if imgui.Button("View", imgui.Vec2{0, 0}) {
                CurrentViewTexture = id;
                GlobalDebugWndBools["ViewGLTexture"] = true;
            }
            imgui.PopId();
        }
    }
    imgui.End();

    if GlobalDebugWndBools["ViewGLTexture"] == true {
        b := GlobalDebugWndBools["ViewGLTexture"];
        OpenGLTextureView(CurrentViewTexture, ^b);
        GlobalDebugWndBools["ViewGLTexture"] = b;
    }
}

OpenGLTextureView :: proc(textureId : gl.Texture, show : ^bool) {
    imgui.Begin("Texture View", show, StdWindowFlags);
    {
        imgui.Image(cast(imgui.TextureID)cast(uint)1, imgui.Vec2{100, 100}, imgui.Vec2{0, 0}, imgui.Vec2{1, 1}, imgui.Vec4{1, 1, 1, 1}, imgui.Vec4{0, 0, 0, 0});
    }
    imgui.End();
}
OpenGLInfo :: proc(vars : ^gl.OpenGLVars_t, show : ^bool) {
    imgui.Begin("OpenGL Info", show, StdWindowFlags);
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
                GlobalDebugWndBools["OpenGLShowExtensions"] = true;
            }
            imgui.Text("Number of WGL extensions:   %d", vars.NumWglExtensions); imgui.SameLine(0, -1); 
            if imgui.Button("View##WGL", imgui.Vec2{0, 0}) {
                GlobalDebugWndBools["OpenGLShowWGLExtensions"] = true;
            }
            imgui.Text("Number of functions loaded: %d/%d", gl.DebugInfo.NumberOfFunctionsLoadedSuccessed, gl.DebugInfo.NumberOfFunctionsLoaded); 
        imgui.Separator();
        if imgui.CollapsingHeader("Loaded Functions", 0) {
            imgui.BeginChild("Functions###FuncLoad", imgui.Vec2{0, 0}, true, 0);
            imgui.Columns(2, nil, false);
            suc : string;
            for status in gl.DebugInfo.Statuses {
                imgui.Text(status.Name);
                if(imgui.IsItemHovered()) {
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
                }
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
            GlobalDebugWndBools["ShowGLTextureOverview"] = true;
        }
    }
    imgui.End();

    if GlobalDebugWndBools["OpenGLShowExtensions"] == true {
        b := GlobalDebugWndBools["OpenGLShowExtensions"];
        OpenGLExtensions("Extensions##Ext", vars.Extensions, ^b);
        GlobalDebugWndBools["OpenGLShowExtensions"] = b;
    }

    if GlobalDebugWndBools["OpenGLShowWGLExtensions"] == true {
        b := GlobalDebugWndBools["OpenGLShowWGLExtensions"];
        OpenGLExtensions("WGL Extensions", vars.WglExtensions, ^b);
        GlobalDebugWndBools["OpenGLShowWGLExtensions"] = b;
    }

    if GlobalDebugWndBools["ShowGLTextureOverview"] == true {
        b := GlobalDebugWndBools["ShowGLTextureOverview"];
        OpenGLTextureOverview(^b);
        GlobalDebugWndBools["ShowGLTextureOverview"] = b;
    }
}

Win32VarsInfo :: proc(vars : ^main.Win32Vars_t, show : ^bool) {
    imgui.Begin("Win32Vars Info", show, StdWindowFlags);
    {
        imgui.Text("Application Handle:    0x%X", cast(int)vars.AppHandle);
        imgui.Text("Window Handle:         0x%X", cast(int)vars.WindowHandle);
        imgui.Text("Window Size:           {%.3f, %.3f}", vars.WindowSize.x, vars.WindowSize.y);
        imgui.Text("Device Context Handle: 0x%X", cast(int)vars.DeviceCtx);
    }
    imgui.End();
}

ShowXinputInfoWindow :: proc(show : ^bool) {
    imgui.Begin("XInput Info", show, StdWindowFlags);
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
                        imgui.Text("Voice:         %t", cap.Flags & xinput.CapabilitiesFlags.Voice == xinput.CapabilitiesFlags.Voice);
                        imgui.Text("FFB:           %t", cap.Flags & xinput.CapabilitiesFlags.FFB == xinput.CapabilitiesFlags.FFB);
                        imgui.Text("Wireless:      %t", cap.Flags & xinput.CapabilitiesFlags.Wireless == xinput.CapabilitiesFlags.Wireless);
                        imgui.Text("PMD:           %t", cap.Flags & xinput.CapabilitiesFlags.PMD == xinput.CapabilitiesFlags.PMD);
                        imgui.Text("NoNavigations: %t", cap.Flags & xinput.CapabilitiesFlags.NoNavigations == xinput.CapabilitiesFlags.NoNavigations);
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
    imgui.Begin("XInput State", show, StdWindowFlags);
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
                        imgui.Text("DpadUp:        %t", state.Gamepad.Buttons & cast(u16)xinput.Buttons.DpadUp == cast(u16)xinput.Buttons.DpadUp);
                        imgui.Text("DpadDown:      %t", state.Gamepad.Buttons & cast(u16)xinput.Buttons.DpadDown == cast(u16)xinput.Buttons.DpadDown);
                        imgui.Text("DpadLeft:      %t", state.Gamepad.Buttons & cast(u16)xinput.Buttons.DpadLeft == cast(u16)xinput.Buttons.DpadLeft);
                        imgui.Text("DpadRight:     %t", state.Gamepad.Buttons & cast(u16)xinput.Buttons.DpadRight == cast(u16)xinput.Buttons.DpadRight);
                        imgui.Text("Start:         %t", state.Gamepad.Buttons & cast(u16)xinput.Buttons.Start == cast(u16)xinput.Buttons.Start);
                        imgui.Text("Back:          %t", state.Gamepad.Buttons & cast(u16)xinput.Buttons.Back == cast(u16)xinput.Buttons.Back);
                        imgui.Text("LeftThumb:     %t", state.Gamepad.Buttons & cast(u16)xinput.Buttons.LeftThumb == cast(u16)xinput.Buttons.LeftThumb);
                        imgui.Text("RightThumb:    %t", state.Gamepad.Buttons & cast(u16)xinput.Buttons.RightThumb == cast(u16)xinput.Buttons.RightThumb);
                        imgui.Text("LeftShoulder:  %t", state.Gamepad.Buttons & cast(u16)xinput.Buttons.LeftShoulder == cast(u16)xinput.Buttons.LeftShoulder);
                        imgui.Text("RightShoulder: %t", state.Gamepad.Buttons & cast(u16)xinput.Buttons.RightShoulder == cast(u16)xinput.Buttons.RightShoulder);
                        imgui.Text("A:             %t", state.Gamepad.Buttons & cast(u16)xinput.Buttons.A == cast(u16)xinput.Buttons.A);
                        imgui.Text("B:             %t", state.Gamepad.Buttons & cast(u16)xinput.Buttons.B == cast(u16)xinput.Buttons.B);
                        imgui.Text("X:             %t", state.Gamepad.Buttons & cast(u16)xinput.Buttons.X == cast(u16)xinput.Buttons.X);
                        imgui.Text("Y:             %t", state.Gamepad.Buttons & cast(u16)xinput.Buttons.Y == cast(u16)xinput.Buttons.Y);
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
    imgui.Begin("Time Data", show, StdWindowFlags);
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

ChosenCatalog : i32;
ShowCatalogWindow :: proc(show : ^bool) {

    PrintName :: proc(asset : ja.Asset) {
        match a in asset {
            case ja.Asset.Texture : {
                imgui.Text("%s %s%s", a.FileInfo.Name, a.LoadedFromDisk ? "[Loaded]" : "",
                           a.GLID != 0 ? "[Uploaded]" : "");
            }

            case ja.Asset.Shader : {
                imgui.Text("%s %s%s", a.FileInfo.Name, a.LoadedFromDisk ? "[Loaded]" : "",
                           a.GLID != 0 ? "[Uploaded]" : "");
            }

            default : {
                imgui.Text("%s %s", a.FileInfo.Name, a.LoadedFromDisk ? "[Loaded]" : "");
            }
        }
    }

    imgui.Begin("Catalogs", show, StdWindowFlags);
    {
        imgui.Combo("Catalog", ^ChosenCatalog, catalog.DebugInfo.CatalogNames[..], -1);
        imgui.Separator();
        cat := catalog.DebugInfo.Catalogs[ChosenCatalog];
        imgui.Text("Folder Path:     %s", cat.Path);
        imgui.Text("Kind:            %v", cat.Kind);
        imgui.Text("Number of files: %d[%d]", len(cat.Items), cat.FilesInFolder);
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