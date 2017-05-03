#import ja "asset.odin";

GUID : int = 0;

Entity :: union {
    GUID : int,
    Name : string,

    NormalTower{
        using Tower : TowerStats,
    },
    SlowTower{
        using Tower : TowerStats,
        SlowFactor : f32,
    },
}

TowerStats :: struct {
    Damage : int,
    AttackSpeed : f32,
    Texture : ja.Asset.Texture,
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

CreateEntity :: proc() -> ^Entity {
    e := new(Entity);
    GUID++;
    e.GUID = GUID; 
    e.Name = "Unnamed";
    return e;
}

CreateTower :: proc() -> ^Entity {
    e := new(Entity);
    t := Entity.NormalTower{};    
    e^ = t;
    GUID++;
    e.GUID = GUID;
    e.Name = "Tower";
    return e;
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
            free(e.Entity);
            free(e);
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