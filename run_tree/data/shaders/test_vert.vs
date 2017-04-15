#version 330

in vec3 Position;
in vec2 UV;
out vec2 uv;

uniform mat4 Model;
uniform mat4 View;
uniform mat4 Proj;

void main() {
    gl_Position = Proj * View * Model * vec4(Position, 1.0);
    uv = vec2(UV.x, UV.y);
}