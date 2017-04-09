#import win32 "sys/windows.odin";

Time_t :: struct {
    TimeScale : f64,
    DeltaTime : f64,
    TimeSinceStart : f64,
    FrameCountSinceStart : i64,

    pfFreq : i64,
    pfOld : i64,
} 

_Time := Time_t{};

Init :: proc() {
    win32.QueryPerformanceFrequency(^_Time.pfFreq);
    win32.QueryPerformanceCounter(^_Time.pfOld);
    _Time.TimeScale = 1;
}

Update :: proc() {
    newTime : i64;
    win32.QueryPerformanceCounter(^newTime);
    _Time.DeltaTime = cast(f64)(newTime - _Time.pfOld);
    _Time.pfOld = newTime;
    _Time.DeltaTime /= cast(f64)_Time.pfFreq;

    _Time.TimeSinceStart += _Time.DeltaTime;
    _Time.FrameCountSinceStart++;
}

GetDeltaTime :: proc() -> f64 {
    return _Time.DeltaTime * _Time.TimeScale;
}

GetUnscaledDeltaTime :: proc() -> f64 {
    return _Time.DeltaTime;
}

GetFrameCountSinceStart :: proc() -> i64 {
    return _Time.FrameCountSinceStart;
}

GetTimeSinceStart :: proc() -> f64 {
    return _Time.TimeSinceStart;
}

SetTimeScale :: proc(scale : f64) {
    _Time.TimeScale = scale;
}

GetTimeScale :: proc() -> f64 {
    return _Time.TimeScale;
}