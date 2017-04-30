#import "fmt.odin";
GlobalState : state_t;

state_t :: struct {    
    State : u64,             
    Inc   : u64,            
}

Init :: proc(initState : u64, initSeq : u64) {
    GlobalState = InitNew(initState, initSeq);
} 

InitNew :: proc(initState : u64, initSeq : u64) -> state_t {
    rng : state_t;
    rng.State = 0;
    rng.Inc = (initSeq << 1) | 1;
    Gen(&rng);
    rng.State += initState;
    Gen(&rng);
    return rng;
}

Gen :: proc() -> u32 {
    return Gen(&GlobalState);
}

Gen :: proc(rng : ^state_t) -> u32 {
    oldState := rng.State;
    rng.State = oldState * 6364136223846793005 + rng.Inc;
    xorshifted := u32(((oldState >> 18) ~ oldState) >> 27);
    rot := u32(oldState >> 59);
    r := (xorshifted >> rot) | (xorshifted << ((-rot) & 31));
    return r;
}

// Number returned (r) will be bound like this 0 <= r <= bound
Gen :: proc(rng : ^state_t, bound : u32) -> u32 {
    r : u32;
    threshold : u32 = -bound % bound;
    for {
        foo := Gen(rng);
        if foo >= threshold {
            r = foo % bound;
            break;
        }
    }
    return r;
}

Gen :: proc(bound : u32) -> u32 {
    return Gen(&GlobalState, bound);
}

GenFloat :: proc() -> f64 {
    return GenFloat(&GlobalState);
}

UINT32_MAX :: 4294967295;

GenFloat :: proc(rng : ^state_t) -> f64 {
    r := Gen(rng);
    return f64((f64(r) - 0.0) / (f64(UINT32_MAX) - 0.0));
}