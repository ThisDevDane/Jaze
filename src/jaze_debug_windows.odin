#import "fmt.odin";
#import gl "jaze_gl.odin";
#import xinput "jaze_xinput.odin";
#import "odimgui/src/imgui.odin";
#import "main.odin";

GlobalDebugWndBools : map[string]bool;
CurrentViewTexture : gl.Texture;

OpenGLExtensions :: proc(name : string, extensions : [dynamic]string, show : ^bool) {
    imgui.Begin(name, show, imgui.GuiWindowFlags.ShowBorders | imgui.GuiWindowFlags.NoCollapse); 
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
    imgui.Begin("Loaded Textures", show, imgui.GuiWindowFlags.ShowBorders | imgui.GuiWindowFlags.NoCollapse);
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
    imgui.Begin("Texture View", show, imgui.GuiWindowFlags.ShowBorders | imgui.GuiWindowFlags.NoCollapse);
    {
        imgui.Image(cast(imgui.TextureID)cast(uint)1, imgui.Vec2{100, 100}, imgui.Vec2{0, 0}, imgui.Vec2{1, 1}, imgui.Vec4{1, 1, 1, 1}, imgui.Vec4{0, 0, 0, 0});
    }
    imgui.End();
}
OpenGLInfo :: proc(vars : ^gl.OpenGLVars_t, show : ^bool) {
    imgui.Begin("OpenGL Info", show, imgui.GuiWindowFlags.ShowBorders | imgui.GuiWindowFlags.NoCollapse);
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
                    imgui.Text("%d", test2.names.count);
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

        imgui.Text("Number of loaded textures: %d", gl.DebugInfo.LoadedTextures.count); imgui.SameLine(0, -1);
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
    imgui.Begin("Win32Vars Info", show, imgui.GuiWindowFlags.ShowBorders | imgui.GuiWindowFlags.NoCollapse);
    {
        imgui.Text("Application Handle:    0x%X", cast(int)vars.AppHandle);
        imgui.Text("Window Handle:         0x%X", cast(int)vars.WindowHandle);
        imgui.Text("Window Size:           {%.3f, %.3f}", vars.WindowSize.x, vars.WindowSize.y);
        imgui.Text("Device Context Handle: 0x%X", cast(int)vars.DeviceCtx);
    }
    imgui.End();
}

ShowXinputWindow :: proc(show : ^bool) {
    imgui.Begin("XInput", show, imgui.GuiWindowFlags.ShowBorders | imgui.GuiWindowFlags.NoCollapse);
    {
        imgui.Text("Version: %s", xinput.Version);
        imgui.Text("Lib Address: 0x%x", cast(int)xinput.xDebugInfo.LibAddress);
        imgui.Text("Number of functions loaded: %d/%d", xinput.xDebugInfo.NumberOfFunctionsLoadedSuccessed, xinput.xDebugInfo.NumberOfFunctionsLoaded); 
        if imgui.CollapsingHeader("Loaded Functions", 0) {
            imgui.BeginChild("Functions", imgui.Vec2{0, 0}, true, 0);
            imgui.Columns(2, nil, false);
            for status in xinput.xDebugInfo.Statuses {
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
            imgui.Text("Capabilites:");
            imgui.Indent(20.0);
                if err == xinput.Success {
                    imgui.Text("Subtype %s", cap.SubType);
                    imgui.Text("Flags:");
                    imgui.Indent(10.0);
                        imgui.Text("Voice:         %t", cap.Flags & xinput.CapabilitiesFlags.Voice == xinput.CapabilitiesFlags.Voice);
                        imgui.Text("FFB:           %t", cap.Flags & xinput.CapabilitiesFlags.FFB == xinput.CapabilitiesFlags.FFB);
                        imgui.Text("Wireless:      %t", cap.Flags & xinput.CapabilitiesFlags.Wireless == xinput.CapabilitiesFlags.Wireless);
                        imgui.Text("PMD:           %t", cap.Flags & xinput.CapabilitiesFlags.PMD == xinput.CapabilitiesFlags.PMD);
                        imgui.Text("NoNavigations: %t", cap.Flags & xinput.CapabilitiesFlags.NoNavigations == xinput.CapabilitiesFlags.NoNavigations);
                    imgui.Unindent(10.0);    
                }
            imgui.Unindent(20.0);
            imgui.Text("Battery Information:");
            imgui.Indent(20.0);
                imgui.Text("Battery Type:  %s", "N/A");
                imgui.Text("Battery Level: %s", "N/A");
            imgui.Unindent(20.0);
        }
    }
    imgui.End();
}