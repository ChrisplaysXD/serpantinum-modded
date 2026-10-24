#version 120
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(binding = 0) uniform sampler2D qt_Texture;
uniform float saturation;
uniform float contrast;
uniform float brightness;

vec3 toLinear(vec3 c) {
    return c * c;
}
vec3 toSRGB(vec3 c) {
    return sqrt(c);
}

void main() {
    vec4 color = texture(qt_Texture, qt_TexCoord0);
    vec3 rgb = color.rgb;
    // Saturation
    float gray = dot(rgb, vec3(0.299, 0.587, 0.114));
    rgb = mix(vec3(gray), rgb, saturation);
    // Contrast
    rgb = (rgb - 0.5) * contrast + 0.5;
    // Brightness
    rgb *= brightness;
    fragColor = vec4(rgb, color.a);
}
