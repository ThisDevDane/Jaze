#import "math.odin";

#import "render_queue.odin";
#import "renderer.odin";
#import "catalog.odin";
#import ja "asset.odin";

Tile :: union {
    Pos : math.Vec3,

    Build{},
    Walk{},
}

Data_t :: struct {
    Width : int,
    Height : int,
          // H  W
    Tiles : [ ][ ]Tile,
    WalkTexture : ^ja.Asset.Texture,
    BuildTexture : ^ja.Asset.Texture,
}

CreateMap :: proc(w, h : int, textureCat : ^catalog.Catalog) -> ^Data_t {
    res := new(Data_t);
    res.Width = w;
    res.Height = h;

    walk, _ := catalog.Find(textureCat, "towerDefense_tile162");
    res.WalkTexture = walk.(^ja.Asset.Texture);

    build, _ := catalog.Find(textureCat, "towerDefense_tile158");
    res.BuildTexture = build.(^ja.Asset.Texture);


    res.Tiles = make([][]Tile, h);
    for _, i in res.Tiles {
        res.Tiles[i] = make([]Tile, w);
    }

    i := 0;
    for y := 0; y < h; y++ {
        i++;
        for x := 0; x < w; x++ {
            i++;
            if i % 2 == 1 {
                res.Tiles[y][x] = Tile.Walk{};
            } else {
                res.Tiles[y][x] = Tile.Build{};
            }
            res.Tiles[y][x].Pos = math.Vec3{f32(x), f32(y), 0};

        }
    }

    return res;
}

DrawMap :: proc(immutable data : ^Data_t) -> ^render_queue.Queue {
    queue := render_queue.Make();
    for y := 0; y < data.Height; y++ {
        for x := 0; x < data.Width; x++ {
            tile := data.Tiles[y][x];
            cmd := renderer.Command.Bitmap{};
            cmd.RenderPos = tile.Pos;
            cmd.Scale = math.Vec3{1, 1, 1};
            cmd.Rotation = 0;
            match t in tile {
                case Tile.Walk : {
                    cmd.Texture = data.WalkTexture;
                }

                case Tile.Build : {
                    cmd.Texture = data.BuildTexture;
                }
            }
            render_queue.Enqueue(queue, cmd);
        }
    }

    return queue;
}