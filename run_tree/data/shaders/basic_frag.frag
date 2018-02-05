#version 330

in vec3 frag_norm;
in mat4 frag_modelview;
in vec2 frag_uv;
in vec3 frag_color;

out vec4 out_color;

uniform vec4 color;

void main() {
    vec3 n = normalize(mat3(frag_modelview) * frag_norm);
    out_color.rgb = 0.5 + 0.5 * n;
    out_color.rgb = frag_color;
}