/*
 *  @Name:     key_value_store
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 16-05-2017 21:52:47
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 28-05-2017 15:31:26
 *  
 *  @Description:
 *      Contains a "generic" key value storage.
 */
KeyValueStore :: struct {
    _data : map[string]any,
}

Set       :: proc(store : ^KeyValueStore, id : string, value : any) {
    store._data[id] = value; 
}

GetF64    :: proc(store : ^KeyValueStore, id : string) -> f64 {
    val, ok := store._data[id];
    if !ok { return 0; }
    match v in val {
        case f64 : { return v; }
        case  : { return 0; }
    }
}

GetF32    :: proc(store : ^KeyValueStore, id : string) -> f32 {
    val, ok := store._data[id];
    if !ok { return 0; }
    match v in val {
        case f32 : { return v; }
        case  : { return 0; }
    }
}

GetInt    :: proc(store : ^KeyValueStore, id : string) -> int {
    val, ok := store._data[id];
    if !ok { return 0; }
    match v in val {
        case int : { return v; }
        case  : { return 0; }
    }
}

GetString :: proc(store : ^KeyValueStore, id : string) -> string {
    val, ok := store._data[id];
    if !ok { return "<nil>"; }
    match v in val {
        case string : { return v; }
        case     : { return "<nil>"; }
    }
}

GetAny    :: proc(store : ^KeyValueStore, id : string) -> any {
    val, ok := store._data[id];
    return ok ? val : any{};
}