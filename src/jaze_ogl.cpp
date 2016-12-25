#define GL_VERSION 					   	  0x1F02
#define GL_MAJOR_VERSION                  0x821B
#define GL_MINOR_VERSION                  0x821C
#define GL_VENDOR                         0x1F00
#define GL_RENDERER                       0x1F01
#define GL_NUM_EXTENSIONS                 0x821D
#define GL_SHADING_LANGUAGE_VERSION       0x8B8C
#define GL_EXTENSIONS                     0x1F03
#define GL_DEPTH_BUFFER_BIT               0x00000100
#define GL_STENCIL_BUFFER_BIT             0x00000400
#define GL_COLOR_BUFFER_BIT               0x00004000

typedef void GLvoid;
typedef unsigned int GLenum;

typedef float GLfloat;
typedef float GLclampf;
typedef double GLclampd;

typedef int GLint;
typedef int GLsizei;
typedef unsigned int GLbitfield;
typedef double GLdouble;
typedef unsigned int GLuint;
typedef unsigned char GLboolean;
typedef unsigned char GLubyte;

struct _openglvars
{
    HGLRC context;
    i32 majorVersion;
    i32 minorVersion;
    
    char* vendor;
    char* renderer;
    char* shadingVersion;
    
    i32 numExtensions;
    char* extensions;
};

#define GLDECL WINAPI

#define JAZE_GL_LIST \
	GLF(const GLubyte*, GetString, GLenum name) \
	GLF(void, GetIntegerv, GLenum pname, GLint* params) \
	GLF(void, Clear, GLbitfield mask) \
	GLF(void, ClearColor, GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha) \
	GLF(void, Flush, void) \


#define GLF(ret, name, ...) typedef ret GLDECL name##proc(__VA_ARGS__); ht_global name##proc * gl##name;
JAZE_GL_LIST
#undef GLF

b8
Win32LoadGLFunctions()
{
    b8 result = true;
    b8 dllOpen = false;
    HINSTANCE dll = LoadLibrary("opengl32.dll");
    dllOpen = dll != NULL;
    
    typedef PROC WINAPI wglGetProcAddressproc(LPCSTR lpszProc);
    wglGetProcAddressproc* wglGetProcAddress = (wglGetProcAddressproc*)GetProcAddress(dll, "wglGetProcAddress");
    
    if(dllOpen)
    {
#define GLF(ret, name, ...) \
        gl##name = (name##proc*)wglGetProcAddress("gl" #name); \
        if(!gl##name) \
        { \
            gl##name = (name##proc*)GetProcAddress(dll, "gl" #name); \
            if(!gl##name) \
            { \
                Log(LOG_ERROR, "Function gl" #name " couldn't be loaded from opengl32.dll\n"); \
                result = false; \
            }\
        }
        JAZE_GL_LIST
#undef GLF
    }
    else
    {
        result = false;
        Log(LOG_ERROR, "Couldn't open opengl32.dll");
    }
    return result;
}

ht_internal void
InitWin32OpenGL(_win32vars* var, _openglvars *ogl)
{
    PIXELFORMATDESCRIPTOR format =
    {
        sizeof(PIXELFORMATDESCRIPTOR),
        1,
        PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER,    //Flags
        PFD_TYPE_RGBA,            //The kind of framebuffer. RGBA or palette.
        32,                        //Colordepth of the framebuffer.
        0, 0, 0, 0, 0, 0,
        0,
        0,
        0,
        0, 0, 0, 0,
        32,                       //Number of bits for the depthbuffer
        8,                        //Number of bits for the stencilbuffer
        0,                        //Number of Aux buffers in the framebuffer.
        PFD_MAIN_PLANE,
        0,
        0, 0, 0
    };
    
    HDC deviceContext = GetDC(var->wndHandle);
    i32 formatIndex = ChoosePixelFormat(deviceContext, &format);
    SetPixelFormat(deviceContext, formatIndex, &format);
    
    ogl->context = wglCreateContext(deviceContext);
    wglMakeCurrent(deviceContext, ogl->context);
    
    ASSERT_MSG(Win32LoadGLFunctions(), "Failed to load all neccesary ogl functions");
    
    glGetIntegerv(GL_MAJOR_VERSION, &ogl->majorVersion);
    glGetIntegerv(GL_MINOR_VERSION, &ogl->minorVersion);
    ogl->vendor   = (char*)glGetString(GL_VENDOR);
    ogl->renderer = (char*)glGetString(GL_RENDERER);
    ogl->shadingVersion = (char*)glGetString(GL_SHADING_LANGUAGE_VERSION);
    
    glGetIntegerv(GL_NUM_EXTENSIONS, &ogl->numExtensions);
    ogl->extensions = (char*)glGetString(GL_EXTENSIONS);

    Log(LOG_NORMAL, "OpenGL info:\n\tVersion: %d.%d\n\tVendor: %s\n\tRenderer: %s\n\tShading Version: %s\n\n",
        ogl->majorVersion,
        ogl->minorVersion,
        ogl->vendor,
        ogl->renderer,
        ogl->shadingVersion);
    
    if(ogl->majorVersion > 3 && ogl->minorVersion > 2)
    { 
    }
    else
    {
        Log(LOG_ERROR, "GPU doesn't support opengl 3.2 or above");
        PostQuitMessage(0);
    }
}