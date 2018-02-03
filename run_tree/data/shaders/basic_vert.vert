#version 330

in vec3 model_pos;
in vec3 model_norm;
out vec3 vert_norm;

uniform float angle;
uniform vec2 res;

vec3 convert(vec3 model_pos) {
    return vec3(model_pos.x*cos(angle) - model_pos.z*sin(angle), 
                model_pos.y, 
                model_pos.x*sin(angle) + model_pos.z*cos(angle));
} 

void main() {
    vec3 pos = model_pos;
    pos += 1;
    gl_Position.xyz = convert(pos);
    gl_Position.x *= res.y/res.x;
    gl_Position.w   = 1.0;
    //vert_norm = convert(model_norm);
    vert_norm = model_norm;
}
