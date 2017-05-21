/*
 *  @Name:     jwin32
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 02-05-2017 21:38:35
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 22-05-2017 01:02:35
 *  
 *  @Description:
 *      Contains windows API not covered by Odin Core.
 */
#foreign_system_library user32 "User32.lib";
#foreign_system_library kernel32 "Kernel32.lib";
#import win32 "sys/windows.odin";

// User32
CombineLoHi :: proc(lo : u32, hi : u32) -> u64 {
    return u64(u64(lo) << 32 | u64(hi));
}

ShowCursor :: proc(show : win32.Bool) #foreign user32 "ShowCursor";

//Kernel32
MAX_PATH :: 0x00000104;
 
INVALID_FILE_ATTRIBUTES  :: -1;
FILE_ATTRIBUTE_DIRECTORY :: 0x10;

FindData :: struct #ordered {
    FileAttributes    : u32,
    CreationTime      : win32.Filetime,
    LastAccessTime    : win32.Filetime,
    LastWriteTime     : win32.Filetime,
    FileSizeHigh      : u32,
    FileSizeLow       : u32,
    Reserved0         : u32,
    Reserved1         : u32,
    FileName          : [MAX_PATH]byte,
    AlternateFileName : [14]byte,
}

GetFileAttributes :: proc(filename : ^byte) -> u32                             #foreign kernel32 "GetFileAttributesA";
FindFirstFile     :: proc(filename : ^byte, data : ^FindData) -> win32.Handle  #foreign kernel32 "FindFirstFileA";
FindNextFile      :: proc(file : win32.Handle, data : ^FindData) -> win32.Bool #foreign kernel32 "FindNextFileA";
FindClose         :: proc(file : win32.Handle) -> win32.Bool                   #foreign kernel32 "FindClose";