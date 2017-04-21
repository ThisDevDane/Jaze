#import ja "asset.odin";

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