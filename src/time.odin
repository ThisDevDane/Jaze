/*
 *  @Name:     time
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hjortshoej@handmade.network
 *  @Creation: 21-04-2017 03:04:34
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 28-05-2017 17:32:40
 *  
 *  @Description:
 *      Contains the time construct.
 */
#import win32 "sys/windows.odin";

Data :: struct {
    time_scale : f64,
    delta_time : f64,
    unscaled_delta_time : f64,
    time_since_start : f64,
    frame_count_since_start : i64,

    _pf_freq : i64,
    _pf_old : i64,
} 

create_data :: proc() -> ^Data {
    res := new(Data);

    win32.QueryPerformanceFrequency(&res._pf_freq);
    win32.QueryPerformanceCounter(&res._pf_old);
    res.time_scale = 1;

    return res;
}

update :: proc(data : ^Data) {
    newTime : i64;
    win32.QueryPerformanceCounter(&newTime);
    data.unscaled_delta_time = f64((newTime - data._pf_old));
    data._pf_old = newTime;
    data.unscaled_delta_time /= f64(data._pf_freq);
    data.delta_time = data.unscaled_delta_time * data.time_scale;

    data.time_since_start += data.unscaled_delta_time;
    data.frame_count_since_start++;
}