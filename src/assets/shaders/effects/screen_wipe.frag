#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;
    float reveal;
    float phase;
    vec4 color0;
    vec4 color1;
    vec4 color2;
    vec4 color3;
    vec4 color4;
    vec4 params;
};

const float PI = 3.141592653589793;

void main() {
    if (reveal <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    vec2 p = qt_TexCoord0 * itemSize;
    float t = clamp(p.y / max(itemSize.y, 1.0), 0.0, 1.0);
    float b1 = 3.0 * (1.0 - t) * (1.0 - t) * t;
    float b2 = 3.0 * (1.0 - t) * t * t;
    float baseAmp = params.x > 0.0 ? params.x : 45.0;

    vec4 colors[5] = vec4[](color0, color1, color2, color3, color4);
    float amps[5] = float[](1.8, 1.5, 1.2, 0.9, 0.6);
    float offsets[5] = float[](0.0, 0.5, 1.0, 1.5, 2.0);

    vec4 accum = vec4(0.0);

    for (int i = 0; i < 5; ++i) {
        float prog = clamp((reveal - float(i) * 0.05) * 2.5, 0.0, 1.0);
        if (prog <= 0.0) continue;

        if (prog >= 1.0) {
            accum = colors[i];
            continue;
        }

        float currentX = itemSize.x * prog;
        float waveAmp = baseAmp * sin(prog * PI) * amps[i];
        float cp1x = currentX + sin(phase + offsets[i]) * waveAmp;
        float cp2x = currentX - cos(phase + offsets[i]) * waveAmp;

        float surfaceX = (1.0 - t)*(1.0 - t)*(1.0 - t)*currentX + b1 * cp1x + b2 * cp2x + t*t*t*currentX;
        float edge = clamp(0.5 - (p.x - surfaceX), 0.0, 1.0);

        accum = mix(accum, colors[i], edge);
    }

    fragColor = accum * qt_Opacity;
}
