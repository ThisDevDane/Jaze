/*
 *  @Name:     obj_parser
 *  
 *  @Author:   Mikkel Hjortshoej
 *  @Email:    hoej@northwolfprod.com
 *  @Creation: 23-11-2017 00:26:57
 *
 *  @Last By:   Mikkel Hjortshoej
 *  @Last Time: 24-11-2017 23:59:23
 *  
 *  @Description:
 *      A (bad) Wavefront OBJ parser.
 */

import "core:strconv.odin";

import "mantle:libbrew/string_util.odin";

import    "console.odin"
import ja "asset.odin";

parse :: proc(text : string) -> ja.Model_3d {
    result := ja.Model_3d{};
    line, rem := string_util.get_line_and_remainder(text);
    for rem != "" {
        line_header := get_line_header(line);

        if line_header == "v" {
            parse_f32_triple_line(line[len("v")+1..], &result.vertices);
        }

        if line_header == "vn" {
            parse_f32_triple_line(line[len("vn")+1..], &result.normals);
        }

        if line_header == "vt" {
            parse_f32_triple_line(line[len("vt")+1..], &result.uvs);
        }

        //TODO(Hoej): Parse uv and normal indices, remember that UVs are optional eg 'f 23//2 25//1 73//9'
        if line_header == "f" {
            parse_indices_line(line[len("f")+1..], &result.vert_indices, 
                                                   &result.norm_indicies,
                                                   &result.uv_indicies);
        }

        line, rem = string_util.get_line_and_remainder(rem);
    }

    result.vert_num = len(result.vertices);
    result.norm_num = len(result.normals);
    result.uvs_num = len(result.uvs);
    
    result.vert_ind_num = len(result.vert_indices);
    result.norm_ind_num = len(result.norm_indicies);
    result.uv_ind_num   = len(result.uv_indicies);

    return result;
}

get_line_header :: proc(line : string) -> string {
    for r, idx in line {
        if r == ' ' || r == '\n' {
            return line[..idx];
        }
    }
    return "INVALID";
}

parse_f32_triple_line :: proc(line : string, array : ^[dynamic]f32) {
    start := 0;
    for r, end in line {
        if r == ' ' || r == '\n' {
            f := line[start..end];
            start = end+1;
            append(array, cast(f32)strconv.parse_f64(f));
            if r == '\n' {
                break;
            }
        }
    }
}

parse_indices_line :: proc(line : string, vert, norm, uv : ^[dynamic]u32) {
    start := 0;
    for r, end in line {
        if r == ' ' || r == '\n' {
            index_trio := line[start..end];
            start = end+1;
            k := 0;
            for ru, idx in index_trio {
                if ru == '/' {
                    append(vert, u32(strconv.parse_uint(index_trio[k..idx], 0))-1);
                    break;
                }
            }
            if r == '\n' {
                break;
            }
        }
    }
}