/*
 *  @Name:     jmap
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 04-05-2017 16:09:02
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 22-05-2017 01:19:31
 *  
 *  @Description:
 *      
 */
#import "fmt.odin";
#import "math.odin";

#import "render_queue.odin";
#import "renderer.odin";
#import "catalog.odin";
#import "console.odin";
#import ja "asset.odin";

Tile :: union {
    ID  : int,
    Pos : math.Vec3,

    Build{},
    Walk{},
}

Data_t :: struct {
    Width : int,
    Height : int,

    StartTile : Tile,
    EndTile   : Tile,
          
    Tiles        : [/*H*/][/*W*/]Tile,
    Occupied     : [/*H*/][/*W*/]bool,
    WalkTexture  : [2]^ja.Asset.Texture,
    BuildTexture : [2]^ja.Asset.Texture,
}

_id := 0;

CreateMap :: proc(mapData : ^ja.Asset.Texture, textureCat : ^catalog.Catalog) -> ^Data_t {
    res := new(Data_t);
    res.Width = mapData.Width;
    res.Height = mapData.Height;

    walk, _ := catalog.Find(textureCat, "towerDefense_tile162");
    walk1, _ := catalog.Find(textureCat, "towerDefense_tile044");
    res.WalkTexture[0] = walk.(^ja.Asset.Texture);
    res.WalkTexture[1] = walk1.(^ja.Asset.Texture);

    build, _ := catalog.Find(textureCat, "towerDefense_tile158");
    build1, _ := catalog.Find(textureCat, "towerDefense_tile065");
    res.BuildTexture[0] = build.(^ja.Asset.Texture);
    res.BuildTexture[1] = build1.(^ja.Asset.Texture);


    res.Tiles    = make([][]Tile, res.Height);
    res.Occupied = make([][]bool, res.Height);
    for _, i in res.Tiles {
        res.Tiles[i]    = make([]Tile, res.Width);
        res.Occupied[i] = make([]bool, res.Width);
    }

    i := 0;
    datap := mapData.Data;
    for y := 0; y < res.Height; y++ {
        i++;
        for x := 0; x < res.Width; x++ {
            r := datap^;
            datap += 1;
            g := datap^;
            datap += 1;
            b := datap^;
            datap += 1;

            if r == 0 {
                res.Tiles[y][x] = Tile.Walk{};
            } else {
                res.Tiles[y][x] = Tile.Build{};
            }



            res.Tiles[y][x].Pos = math.Vec3{f32(x), f32(y), 0};
            res.Tiles[y][x].ID = _id;
            _id++;
            
            if g == 0 {
                res.StartTile = res.Tiles[y][x];
            } 
            
            if b == 0 {
                res.EndTile = res.Tiles[y][x];
            }
        }
    }

    return res;
}

TileIsBuildable :: proc(immutable data : ^Data_t, pos : math.Vec2) -> bool {
    tile := data.Tiles[int(pos.y)][int(pos.x)];
    match t in tile {
        case Tile.Build : {
            return true;
        }
    }

    return false;
}

DrawMap :: proc(immutable data : ^Data_t, queue : ^render_queue.Queue, inBuildMode : bool) {
    for y := 0; y < data.Height; y++ {
        for x := 0; x < data.Width; x++ {
            tile := data.Tiles[y][x];
            cmd := renderer.Command.Bitmap{};
            cmd.RenderPos = tile.Pos;
            cmd.Scale = math.Vec3{1, 1, 1};
            cmd.Rotation = 0;
            match t in tile {
                case Tile.Walk : {
                    i := inBuildMode ? 1 : 0;
                    cmd.Texture =  data.WalkTexture[i];
                }

                case Tile.Build : {
                    i := inBuildMode ? 1 : 0;
                    cmd.Texture = data.BuildTexture[i];
                }
            }
            render_queue.Enqueue(queue, cmd);
        }
    }
}

/*GetNeighbors :: proc(immutable map_ : ^Data_t, tile : Tile, onlyWalkable : bool) -> []Tile {
    IsInsideMap :: proc(immutable map_ : ^Data_t, x, y : f32) {
        foo := x < map_.Width && x > -1;
        bar := y < map_.Width && y > -1;
        return foo && bar;
    }
    res := new([]Tile);
    tilePos := Tile.Pos;
    for y := tilePos.y-1; y < tilePos.y+1; y++ {
        for x := tilePos.x-1; x < tilePos.x+1; x++ {
            if !IsInsideMap(map_, x, y) { continue; }

            if onlyWalkable {
                match t in map_.Tiles[y][x] {
                    case Tile.Walk : {
                        append(res, map_.Tiles[y][x]);
                    }
                }
            }
        }
    }

    return nil;
}*/