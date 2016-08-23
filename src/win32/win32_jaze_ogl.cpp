#define GL_VERSION 					   0x1F02
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

#define GLDECL WINAPI

#define JAZE_GL_LIST \
	GLF(const GLubyte*, GetString, GLenum name) \
	GLF(void, GetIntegerv, GLenum pname, GLint* params) \
	GLF(void, Clear, GLbitfield mask) \
	GLF(void, ClearColor, GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha) \
	GLF(void, Flush, void ) \

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