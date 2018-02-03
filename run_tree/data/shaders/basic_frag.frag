#version 330

in vec3 vert_norm;
out vec4 out_color;

void main() {
    float costheta = clamp(dot(vert_norm, vec3(0, 0, -1)), 0, 1);

    out_color = vec4(vec3(costheta), 1.0);
    out_color = vec4(0.5 + 0.5 *vert_norm, 1.0);      
}