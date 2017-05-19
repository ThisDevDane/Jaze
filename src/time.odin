/*
 *  @Name:     time
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 21-04-2017 03:04:34
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 20-05-2017 00:44:16
 *  
 *  @Description:
 *  
 */
#import win32 "sys/windows.odin";

Data_t :: struct {
    TimeScale : f64,
    DeltaTime : f64,
    UnscaledDeltaTime : f64,
    TimeSinceStart : f64,
    FrameCountSinceStart : i64,

    pfFreq : i64,
    pfOld : i64,
} 

CreateData :: proc() -> ^Data_t {
    res := new(Data_t);

    win32.QueryPerformanceFrequency(&res.pfFreq);
    win32.QueryPerformanceCounter(&res.pfOld);
    res.TimeScale = 1;

    return res;
}

Update :: proc(data : ^Data_t) {
    newTime : i64;
    win32.QueryPerformanceCounter(&newTime);
    data.UnscaledDeltaTime = f64((newTime - data.pfOld));
    data.pfOld = newTime;
    data.UnscaledDeltaTime /= f64(data.pfFreq);
    data.DeltaTime = data.UnscaledDeltaTime * data.TimeScale;

    data.TimeSinceStart += data.UnscaledDeltaTime;
    data.FrameCountSinceStart++;
}