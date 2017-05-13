#import "math.odin";
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