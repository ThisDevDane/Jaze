/*
 *  @Name:     path
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 21-05-2017 15:35:05
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 21-05-2017 15:51:00
 *  
 *  @Description:
 *  
 */
#import "math.odin";

#import "jmap.odin";

QueueNode :: struct {
    Tile : jmap.Tile,
    Next : ^QueueNode,
}

Queue :: struct {
    Count : int,
    Front : ^QueueNode,
    Tail : ^QueueNode,
} 

Find :: proc(immutable map_ : ^jmap.Data_t, start : jmap.Tile, end : jmap.Tile) -> []math.Vec3{
    Heuristic :: proc(a, b : math.Vec3) -> f32 {
        foo := a.x - b.x; 
        bar := a.y - b.y;
        return (foo > 0 ? foo : -foo) + (bar > 0 ? bar : -bar); 
    }

    cameFrom : map[int]jmap.Tile;

    closedSet : map[int]jmap.Tile;
    openSet   := MakeQueue();
    Enqueue(&openSet, start);

    for IsEmpty(openSet) {
        current, _ := Dequeue(&openSet);

        if current.Pos.x == end.Pos.x &&
           current.Pos.y == end.Pos.y {
            return nil;
        }

        for /*neighbours*/ {
            
        }
    }

    return nil;
}

MakeQueue :: proc() -> Queue {
    res : Queue;
    res.Count = 0;
    res.Front = nil;
    res.Tail = nil;
    return res;
}

Enqueue :: proc(queue : ^Queue, tile : jmap.Tile) {
    node := new(QueueNode);
    node.Tile = tile;
    node.Next = nil;

    if queue.Tail == nil { //No items enqueued
        queue.Front = node;
        queue.Tail = node;
        queue.Count++;  
        return;
    }

    queue.Tail.Next = node;
    queue.Tail = node;
    queue.Count++;
}

Dequeue :: proc(queue : ^Queue) -> (jmap.Tile, bool) {
    if !IsEmpty(queue^) {
        node := queue.Front;
        tile := node.Tile;

        queue.Front = node.Next;
        queue.Count--;
        free(node);
        if queue.Count == 0 {
            queue.Front = nil;
            queue.Tail = nil;
        }
        return tile, true;

    } else {
        return jmap.Tile{}, false;
    }
}

IsEmpty :: proc(queue : Queue) -> bool {
    if queue.Front == nil {
        return true;
    } else if queue.Count == 0 {
        return true;
    } else {
        return false;
    }
}