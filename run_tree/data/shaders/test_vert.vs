#version 330

in vec3 Position;
in vec2 UV;
out vec2 uv;
void main() {
    gl_Position = vec4(Position, 1.0);
    uv = vec2(UV.x, 1.0 - UV.y);
}