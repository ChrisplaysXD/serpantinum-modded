#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;
    float fillLevel;
    float wavePhase;
    vec4 baseColor;
    vec4 params;
};

const float PI = 3.141592653589793;

void main() {
    if (fillLevel <= 0.001) {
        fragColor = vec4(0.0);
        return;
    }

    vec2 p = qt_TexCoord0 * itemSize;
    float s16 = params.x > 0.0 ? params.x : 16.0;

    float amps[5] = float[](1.8, 1.5, 1.2, 0.9, 0.6);
    float offsets[5] = float[](0.0, 0.5, 1.0, 1.5, 2.0);
    float darken[5] = float[](2.5, 2.0, 1.5, 1.1, 1.0);

    vec4 accum = vec4(0.0);

    for (int k = 0; k < 5; ++k) {
        float prog = clamp((fillLevel - float(k) * 0.15) * 1.25, 0.0, 1.0);
        if (prog <= 0.0) continue;

        vec4 col = vec4(baseColor.rgb / darken[k], baseColor.a);

        if (prog >= 1.0) {
            accum = col;
            continue;
        }

        float fillY = itemSize.y * (1.0 - prog);
        float baseAmp = s16 * sin(prog * PI) * amps[k];
        float localPhase = wavePhase + offsets[k];

        float waveHeight = 0.0;
        for (int w = 1; w <= 3; ++w) {
            float freq = float(w) * 1.5;
            float amp = baseAmp * (1.0 - float(w - 1) * 0.3);
            waveHeight += sin(localPhase * freq + p.x * 0.01 * freq) * amp;
        }

        float surfaceY = fillY + waveHeight * 0.6;
        float edge = clamp(0.5 - (surfaceY - p.y), 0.0, 1.0);

        accum = mix(accum, col, edge);
    }

    fragColor = accum * qt_Opacity;
}
