/*
 *  @Name:     leakcheck_allocator
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hoej@northwolfprod.com
 *  @Creation: 26-11-2017 23:54:49
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 27-11-2017 00:15:15
 *  
 *  @Description:
 *  
 */

import "core:fmt.odin";

leakcheck :: proc() -> Allocator {
    return Allocator{leakcheck_proc, nil};
}

leakcheck_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int, 
                             flags: u64 = 0, loc := #caller_location) -> rawptr {
    switch mode {
    case Allocator_Mode.Alloc :
        fmt.println("Alloc:", loc);
    case Allocator_Mode.Free :
        fmt.println("Free:", loc);
    case Allocator_Mode.Resize :
        fmt.println("Resize:", loc);
    }
    ptr := default_allocator_proc(allocator_data, mode, size, alignment, old_memory, old_size, flags, loc);
    return ptr;
}
