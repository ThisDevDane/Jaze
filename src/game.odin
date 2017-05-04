#import "entity.odin";
#import "jmap.odin";

Context_t :: struct {
    EntityList : ^entity.List,
    Map        : ^jmap.Data_t
}