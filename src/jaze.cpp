#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include "ht.h"

ht_global b8     IsRunning;
ht_global HANDLE LogHandle;

#define LOG_NORMAL  0
#define LOG_WARNING 1
#define LOG_ERROR   2

void
InternalLog(char* msg)
{
#if JA_LOGGING
    if(LogHandle)
    {
        SetFilePointer(LogHandle, 0, 0, FILE_END);
        DWORD _ignored;
        WriteFile(LogHandle, msg, cast(DWORD)strlen(msg), &_ignored, NULL);
        WriteFile(LogHandle, "\r\n", 2, &_ignored, NULL);
    }
#endif
}

void
Log(i32 wlevel, char* msg, ...)
{
#if JA_LOGGING
    va_list va;
    char buffer[4096];
    char* p = buffer;
    
    char* wlevelText = "1";
    switch(wlevel)
    {
        case LOG_WARNING:
        {
            wlevelText = "2";
        } break;
        
        case LOG_ERROR:
        {
            wlevelText = "3";
        } break;
    }
    
    p += sprintf(p, "[%-1s]", wlevelText);
        
    va_start(va, msg);
    vsprintf(p, msg, va);
    va_end(va);
    
    InternalLog(buffer);
#endif
}

struct _win32vars
{
    WNDCLASSEX wndClass;
    HWND wndHandle;
};

#include"win32_jaze_ogl.cpp"

LRESULT CALLBACK
WindowProc(HWND hwnd,
           UINT uMsg,
           WPARAM wParam,
           LPARAM lParam)
{
    LRESULT result = 0;
    switch(uMsg)
    {
        case WM_DESTROY :
        {
            IsRunning = false;
            result = TRUE;
        } break;
        
        case WM_CLOSE :
        {
            IsRunning = false;
            result = TRUE;
        } break;
        
        case WM_QUIT :
        {
            IsRunning = false;
            result = TRUE;
        } break;
        
        default :
        {
            result = DefWindowProc(hwnd, uMsg, wParam, lParam);
        }
        break;
    }
    
    return result;
}

ht_internal void
CreateWin32Window(_win32vars* var, char* windowName, HINSTANCE hInstance)
{
    var->wndClass.cbSize = sizeof(var->wndClass);
    var->wndClass.style = CS_OWNDC|CS_HREDRAW|CS_VREDRAW;
    var->wndClass.lpfnWndProc = WindowProc;
    var->wndClass.hInstance = hInstance;
    
    char buf[256];
    sprintf(buf, "%s_class", windowName);
    var->wndClass.lpszClassName = buf;
    ASSERT_MSG(RegisterClassEx(&var->wndClass),
               "Couldn't Register Class");
    
    DWORD style = WS_OVERLAPPEDWINDOW|WS_VISIBLE;
    RECT clientRect = {0,0,1280,720};
    AdjustWindowRect(&clientRect, style, false);
    var->wndHandle = CreateWindowEx(
        0,
        var->wndClass.lpszClassName,
        windowName,
        style,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        clientRect.right - clientRect.left,
        clientRect.bottom - clientRect.top,
        0,
        0,
        hInstance,
        0
        );
    ASSERT_MSG(var->wndHandle, "Couldn't Create Window");
}

int CALLBACK
WinMain(HINSTANCE hInstance,
        HINSTANCE hPrevInstance,
        LPSTR lpCmdLine,
        int nCmdShow)
{
    _win32vars win32 = {};
    _openglvars ogl = {};
    
    SYSTEMTIME time = {};
    GetSystemTime(&time);
    char logName[256];
    sprintf(logName, "log_%d%d%d-%d%d%d.txt",
            time.wDay,
            time.wMonth,
            time.wYear,
            time.wHour,
            time.wMinute,
            time.wSecond);
    LogHandle = CreateFile(logName, GENERIC_WRITE|GENERIC_READ, 0, 0, CREATE_ALWAYS, 0, 0);
    
    CreateWin32Window(&win32, "Jaze", hInstance);
    InitWin32OpenGL(&win32, &ogl);
    IsRunning = true;
    glClearColor(1,0,0,1);
    
    while(IsRunning)
    {
        MSG message;
        while(PeekMessage(&message, 0, 0, 0, PM_REMOVE))
        {
            TranslateMessage(&message);
            DispatchMessage(&message);
        }
        
        
        glClear(GL_COLOR_BUFFER_BIT);
        HDC dc = GetDC(win32.wndHandle);
        SwapBuffers(dc);
        ReleaseDC(win32.wndHandle, dc);
    }
    return 0;
}

