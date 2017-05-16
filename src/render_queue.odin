#import "renderer.odin";

QueueNode :: struct {
    Command : renderer.Command,
    Next : ^QueueNode,
}

Queue :: struct {
    Count : int,
    Front : ^QueueNode,
    Tail : ^QueueNode,
} 

Make :: proc() -> ^Queue {
    res := new(Queue);
    res.Count = 0;
    res.Front = nil;
    res.Tail = nil;
    return res;
}

Enqueue :: proc(queue : ^Queue, cmd : renderer.Command) {
    node := new(QueueNode);
    node.Command = cmd;
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

Dequeue :: proc(queue : ^Queue) -> (renderer.Command, bool) {
    if !IsEmpty(queue) {
        node := queue.Front;
        cmd := node.Command;

        queue.Front = node.Next;
        queue.Count--;
        free(node);
        if queue.Count == 0 {
            queue.Front = nil;
            queue.Tail = nil;
        }
        return cmd, true;

    } else {
        return renderer.Command{}, false;
    }
}

IsEmpty :: proc(queue : ^Queue) -> bool {
    if queue.Front == nil {
        return true;
    } else if queue.Count == 0 {
        return true;
    } else {
        return false;
    }
}