#include <flutter/runtime_effect.glsl>

// Three stacked translucent wave bands that rise from the bottom (or hang
// from the top). Each band adds a little more of the colour, so the result is
// a layered, paper-cut look rather than a single hard edge.
uniform vec2 uResolution;  // 0-1
uniform float uTime;       // 2 (unused)
uniform vec3 uColor;       // 3-5
uniform float uBaseY;      // 6   where the first band's crest sits (0..1)
uniform float uAmp;        // 7   wave height (0..0.2)
uniform float uFreq;       // 8   waves across the width (0.5..3)
uniform float uAlpha;      // 9   opacity added per band
uniform float uSeed;       // 10
uniform float uFlip;       // 11  0 = from bottom, 1 = from top

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float y = uFlip > 0.5 ? 1.0 - uv.y : uv.y;

    float acc = 0.0;
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        float crest = uBaseY + fi * 0.09;
        float w = sin(uv.x * uFreq * 6.2832 + uSeed + fi * 1.9) * uAmp
                + sin(uv.x * uFreq * 6.2832 * 1.7 - fi * 0.8 + uSeed * 0.5) * uAmp * 0.45;
        float edge = crest + w;
        acc += smoothstep(edge, edge + 0.004, y) * uAlpha;
    }
    acc = clamp(acc, 0.0, 1.0);
    fragColor = vec4(uColor * acc, acc);
}
