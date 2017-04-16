#version 330

in vec2 uv;

out vec4 OutColor;

uniform sampler2D textureSampler;

void main() {
    vec4 texColor = texture(textureSampler, uv);
    //if(texColor.a < 0.1)
    //    discard;
    OutColor = texColor;
}