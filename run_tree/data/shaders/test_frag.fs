#version 330

in vec2 uv;

out vec4 OutColor;

uniform sampler2D textureSampler;

void main() {
    OutColor = texture(textureSampler, uv);
}