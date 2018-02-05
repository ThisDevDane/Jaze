#version 330

in vec3 vert_pos;
in vec2 vert_uv;
in vec3 vert_norm;
in vec3 vert_color;

out vec3 frag_norm;
out mat4 frag_modelview;
out vec2 frag_uv;
out vec3 frag_color;

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

void main() {
    gl_Position = proj * view * model * vec4(vert_pos, 1.0);
    frag_norm = vert_norm;
    frag_modelview = view * model;
    frag_uv = vert_uv;
    frag_color = vert_color;
}
