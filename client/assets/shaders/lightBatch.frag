#version 460

precision lowp float;

in BatchData {
    vec3 color;
    float alphaMult;
    vec2 uv;
} data;

layout (location = 0) out vec4 resultColor;

uniform sampler2D sampler;

void main() {
    vec4 pixel = texture(sampler, data.uv);
    float temp = pixel.r;
    pixel.r = pixel.b;
    pixel.b = temp;
    
    if (pixel.a == 0.0)
        discard;

    pixel.a *= data.alphaMult;
    pixel.rgb = data.color;

    resultColor = pixel; 
}