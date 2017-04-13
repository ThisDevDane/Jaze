#foreign_library stbi "../external/stb_image.lib" when ODIN_OS == "windows";

//
// load image by filename, open file, or memory buffer
//
Io_Callbacks :: struct {
    read: proc(user: rawptr, data: ^byte, size: i32) -> i32 #cc_c, // fill 'data' with 'size' bytes.  return number of bytes actually read
    skip: proc(user: rawptr, n: i32) #cc_c,                        // skip the next 'n' bytes, or 'unget' the last -n bytes if negative
    eof:  proc(user: rawptr) -> i32 #cc_c,                         // returns nonzero if we are at end of file/data
}

////////////////////////////////////
//
// 8-bits-per-channel interface
//
load                :: proc(filename: ^byte,                   x, y, channels_in_file: ^i32, desired_channels: i32) -> ^byte #foreign stbi "stbi_load";
load_from_memory    :: proc(buffer: ^byte, len: i32,           x, y, channels_in_file: ^i32, desired_channels: i32) -> ^byte #foreign stbi "stbi_load_from_memory";
load_from_callbacks :: proc(clbk: ^Io_Callbacks, user: rawptr, x, y, channels_in_file: ^i32, desired_channels: i32) -> ^byte #foreign stbi "stbi_load_from_callbacks";

////////////////////////////////////
//
// 16-bits-per-channel interface
//
load_16 :: proc(filename: ^byte, x, y, channels_in_file: ^i32, desired_channels: i32) -> ^u16  #foreign stbi "stbi_load_16";

////////////////////////////////////
//
// float-per-channel interface
//
loadf                 :: proc(filename: ^byte,                   x, y, channels_in_file: ^i32, desired_channels: i32) -> ^f32 #foreign stbi "stbi_loadf";
loadf_from_memory     :: proc(buffer: ^byte, len: i32,           x, y, channels_in_file: ^i32, desired_channels: i32) -> ^f32 #foreign stbi "stbi_loadf_from_memory";
loadf_from_callbacks  :: proc(clbk: ^Io_Callbacks, user: rawptr, x, y, channels_in_file: ^i32, desired_channels: i32) -> ^f32 #foreign stbi "stbi_loadf_from_callbacks";


hdr_to_ldr_gamma :: proc(gamma: f32) #foreign stbi "stbi_hdr_to_ldr_gamma";
hdr_to_ldr_scale :: proc(scale: f32) #foreign stbi "stbi_hdr_to_ldr_scale";

is_hdr_from_callbacks :: proc(clbk: ^Io_Callbacks, user: rawptr) -> i32 #foreign stbi "stbi_is_hdr_from_callbacks";
is_hdr_from_memory    :: proc(buffer: ^byte, len: i32)           -> i32 #foreign stbi "stbi_is_hdr_from_memory";

is_hdr :: proc(filename: ^byte) -> i32 #foreign stbi "stbi_is_hdr";

// get a VERY brief reason for failure
// NOT THREADSAFE
failure_reason :: proc() -> ^byte #foreign stbi "stbi_failure_reason";

// free the loaded image -- this is just free()
image_free     :: proc(retval_from_load: rawptr) #foreign stbi "stbi_image_free";

// get image dimensions & components without fully decoding
info_from_memory    :: proc(buffer: ^byte, len: i32,           x, y, comp: ^i32) -> i32 #foreign stbi "stbi_info_from_memory";
info_from_callbacks :: proc(clbk: ^Io_Callbacks, user: rawptr, x, y, comp: ^i32) -> i32 #foreign stbi "stbi_info_from_callbacks";
info                :: proc(filename: ^byte, x, y, comp: ^i32)                   -> i32 #foreign stbi "stbi_info";

// for image formats that explicitly notate that they have premultiplied alpha,
// we just return the colors as stored in the file. set this flag to force
// unpremultiplication. results are undefined if the unpremultiply overflow.
set_unpremultiply_on_load :: proc (flag_true_if_should_unpremultiply: i32) #foreign stbi "stbi_set_unpremultiply_on_load";


// indicate whether we should process iphone images back to canonical format,
// or just pass them through "as-is"
convert_iphone_png_to_rgb :: proc(flag_true_if_should_convert: i32) #foreign stbi "stbi_convert_iphone_png_to_rgb";

// flip the image vertically, so the first pixel in the output array is the bottom left
set_flip_vertically_on_load :: proc(flag_true_if_should_flip: i32) #foreign stbi "stbi_set_flip_vertically_on_load";

// ZLIB client - used by PNG, available for other purposes

zlib_decode_malloc_guesssize            :: proc(buffer: ^byte, len, initial_size: i32, outlen: ^i32)                    -> ^byte #foreign stbi "stbi_zlib_decode_malloc_guesssize";
zlib_decode_malloc_guesssize_headerflag :: proc(buffer: ^byte, len, initial_size: i32, outlen: ^i32, parse_header: i32) -> ^byte #foreign stbi "stbi_zlib_decode_malloc_guesssize_headerflag";
zlib_decode_malloc                      :: proc(buffer: ^byte, len: i32, outlen: ^i32)                                  -> ^byte #foreign stbi "stbi_zlib_decode_malloc";
zlib_decode_buffer                      :: proc(out_buffer: ^byte, olen: i32, in_buffer: ^byte, ilen: i32)              -> i32   #foreign stbi "stbi_zlib_decode_buffer";

zlib_decode_noheader_malloc             :: proc(buffer: ^byte, len: i32, outlen: ^int)                                  -> ^byte #foreign stbi "stbi_zlib_decode_noheader_malloc";
zlib_decode_noheader_buffer             :: proc(obuffer: ^byte, olen: i32, ibuffer: ^byte, ilen: i32)                   -> i32   #foreign stbi "stbi_zlib_decode_noheader_buffer";
