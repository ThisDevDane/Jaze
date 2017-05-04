#import "math.odin";

Tile :: union {
    Pos : math.Vec3,

    Build{},
    Walk{},
}

Data_t :: struct {
          // C  R
    Tiles : [ ][ ]Tile,
}

CreateMap :: proc(w, h : int) -> ^Data_t {
    res := new(Data_t);
    res.Tiles = make([][]Tile, h);
    for _, i in res.Tiles {
        res.Tiles[i] = make([]Tile, w);
    }
    return res;
}