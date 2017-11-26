/*
 *  @Name:     key_value_store
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 16-05-2017 21:52:47
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 26-11-2017 23:37:29
 *  
 *  @Description:
 *      Contains a "generic" key value storage.
 */
import "console.odin";

KeyValueStore :: struct {
    _data : map[string]any,
}

Set       :: proc(store : ^KeyValueStore, id : string, value : any) {
    store._data[id] = value; 
}

GetF64    :: proc(store : ^KeyValueStore, id : string) -> f64 {
    val, ok := store._data[id];
    if !ok { return 0; }
    switch v in val {
        case f64 : { return v; }
        case  : { return 0; }
    }
}

GetF32    :: proc(store : ^KeyValueStore, id : string) -> f32 {
    val, ok := store._data[id];
    if !ok { return 0; }
    switch v in val {
        case f32 : { return v; }
        case  : { return 0; }
    }
}

GetInt    :: proc(store : ^KeyValueStore, id : string) -> int {
    val, ok := store._data[id];
    if !ok { return 0; }
    switch v in val {
        case int : { return v; }
        case  : { return 0; }
    }
}

GetString :: proc(store : ^KeyValueStore, id : string) -> string {
    val, ok := store._data[id];
    if !ok { return "<nil>"; }
    switch v in val {
        case string : { return v; }
        case     : { return "<nil>"; }
    }
}

GetAny    :: proc(store : ^KeyValueStore, id : string) -> any {
    val, ok := store._data[id];
    return ok ? val : any{};
}