/*
 *  @Name:     entity
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 21-04-2017 23:32:08
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 20-05-2017 01:18:55
 *  
 *  @Description:
 *  
 */
#import "math.odin";

#import "render_queue.odin";
#import "game.odin";
#import "engine.odin";
#import "renderer.odin";
#import ja "asset.odin";

GUID : int = 0;

Entity :: union {
    GUID : int,
    Name : string,

    Tower{
        T : Tower,
    },
    Enemy{
        using Transform : Transform_t,
    }
}

Transform_t :: struct {    
    Position : math.Vec3,
    Scale : math.Vec3,
    Rotation : f32,
    RenderOffset : math.Vec3,
}

Tower :: union {
    using Transform : Transform_t,
    Damage : int,
    AttackSpeed : f32,
    Texture : ^ja.Asset.Texture,

    Basic{},
    Slow{
        SlowFactor : f32,
    },
}

DrawTowers :: proc(ctx : ^engine.Context_t, gCtx : ^game.Context_t, queue : ^render_queue.Queue) {
    for i := gCtx.EntityList.Front;
        i != nil;
        i = i.Next {
        if i.Entity == nil {
            continue;
        }
        match e in i.Entity {
            case Entity.Tower : {
                match t in e.T {
                    case Tower.Basic : {
                        cmd := renderer.Command.Bitmap{};
                        cmd.RenderPos = t.Position;
                        cmd.Scale = math.Vec3{1, 1, 1};
                        cmd.Rotation = 0;        
                        cmd.Texture = gCtx.TowerBasicBottomTexture;
                        render_queue.Enqueue(queue, cmd);

                        cmd.RenderPos = t.Position;
                        cmd.Rotation = f32(ctx.Time.TimeSinceStart) * 20;        
                        cmd.Texture = gCtx.TowerBasicTopTexture;
                        render_queue.Enqueue(queue, cmd);
                    }
                }
            }
        }
    }
} 

CreateEntity :: proc() -> ^Entity {
    e := new(Entity);
    GUID++;
    e.GUID = GUID; 
    e.Name = "Unnamed";
    return e;
}

CreateTower :: proc() -> ^Entity {
    e := new(Entity);
    t := Entity.Tower{};    
    //t.T = new(Tower);
    t.T = Tower.Basic{};
    e^ = t;
    GUID++;
    e.GUID = GUID;
    e.Name = "Basic Tower";
    return e;
}

CreateSlowTower :: proc() -> ^Entity {
    e := new(Entity);
    t := Entity.Tower{};    
    //t.T = new(Tower);
    s := Tower.Slow{};
    s.SlowFactor = 342;
    t.T = s;
    e^ = t;
    GUID++;
    e.GUID = GUID;
    e.Name = "Slow Tower";
    return e;
}

ListItem :: struct {
    Entity : ^Entity,
    Next : ^ListItem,
}

List :: struct {
    Front : ^ListItem,
    End : ^ListItem,
    Count : int,
}

AddEntity :: proc(list : ^List, entity : ^Entity) {
    if list.Front.Entity == nil {
        list.Front.Entity = entity;
    } else {
        item := new(ListItem);
        item.Entity = entity; 
        list.End.Next = item;
        list.End = item;
    }
    list.Count++;
}

RemoveEntity :: proc(list : ^List, entity : ^Entity) {
    p : ^ListItem;
    for e := list.Front;
        e != nil;
        e = e.Next {
        if e.Entity.GUID == entity.GUID {
            p.Next = e.Next;
            free(e.Entity); //Note(@Hoej): Should this free the entity?
            free(e);
            list.Count--;
        }
        p = e;
    }
}

MakeList :: proc() -> ^List {
    list := new(List);
    front := new(ListItem);
    list.Front = front;
    list.End = front;
    list.Count = 0;

    return list;
}