/*
 *  @Name:     jwin32
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 02-05-2017 21:38:35
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 28-05-2017 17:29:06
 *  
 *  @Description:
 *      Contains windows API not covered by Odin Core.
 */
#foreign_system_library user32 "User32.lib";
#foreign_system_library kernel32 "Kernel32.lib";
#import win32 "sys/windows.odin";

// User32
combine_hi_lo :: proc(lo : u32, hi : u32) -> u64 {
    return u64(u64(lo) << 32 | u64(hi));
}