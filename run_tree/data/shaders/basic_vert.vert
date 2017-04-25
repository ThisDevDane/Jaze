#version 330

in vec3 VertPos;

uniform mat4 Model;
uniform mat4 View;
uniform mat4 Proj;

void main() {

    gl_Position = Proj * View * Model * vec4(VertPos, 1.0);

}
