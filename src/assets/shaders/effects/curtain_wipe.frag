#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;
    float reveal;
    float s28;
    vec4 color0;
    vec4 color1;
    vec4 color2;
    vec4 color3;
    vec4 color4;
};

const float PI = 3.141592653589793;

void main() {
    if (reveal <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    vec2 p = qt_TexCoord0 * itemSize;
    float t = clamp(p.x / max(itemSize.x, 1.0), 0.0, 1.0);
    float b1 = 3.0 * (1.0 - t) * (1.0 - t) * t;
    float b2 = 3.0 * (1.0 - t) * t * t;
    float phase = reveal * 7.853981633974483;

    vec4 colors[5] = vec4[](color0, color1, color2, color3, color4);
    float amps[5] = float[](1.5, 1.3, 1.1, 0.9, 0.6);
    float offsets[5] = float[](0.0, 0.5, 1.0, 1.5, 2.0);

    vec4 accum = vec4(0.0);

    for (int i = 0; i < 5; ++i) {
        float prog = (reveal - float(i) * 0.07) * 1.55;
        if (prog <= 0.0) continue;

        if (prog >= 1.0) {
            accum = colors[i];
            continue;
        }

        float smoothProg = pow(prog, 1.4);
        float currentY = itemSize.y * smoothProg;
        float waveAmp = s28 * sin(smoothProg * PI) * amps[i];
        float cp1y = currentY + sin(phase + offsets[i]) * waveAmp;
        float cp2y = currentY - cos(phase + offsets[i]) * waveAmp;

        float surfaceY = (1.0 - t)*(1.0 - t)*(1.0 - t)*currentY + b1 * cp1y + b2 * cp2y + t*t*t*currentY;
        float edge = clamp(0.5 - (p.y - surfaceY), 0.0, 1.0);

        accum = mix(accum, colors[i], edge);
    }

    fragColor = accum * qt_Opacity;
}
