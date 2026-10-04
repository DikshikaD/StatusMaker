#include <flutter/runtime_effect.glsl>

// Static mesh gradient: four coloured control points blended with
// inverse-distance weighting over a gently domain-warped plane. This is the
// base layer of almost every generated background — the "soft blur" look
// comes from the smooth falloff, so no separate blur pass is needed.
//
// Uniform layout follows the flutter_shaders_ui convention so one painter can
// drive both this file and that package's shaders:
//   0-1  uResolution   2 uTime (unused here — the output is a still image)
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uP1;        // 3-4   control point 1 (normalised 0..1)
uniform vec3 uC1;        // 5-7   colour 1 (RGB 0..1)
uniform vec2 uP2;        // 8-9
uniform vec3 uC2;        // 10-12
uniform vec2 uP3;        // 13-14
uniform vec3 uC3;        // 15-17
uniform vec2 uP4;        // 18-19
uniform vec3 uC4;        // 20-22
uniform float uWarp;     // 23    0 = clean blend, 1 = strong organic distortion
uniform float uSeed;     // 24    changes the warp pattern
uniform float uSoftness; // 25    1.5 = very soft wash, 4 = distinct blobs

out vec4 fragColor;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 3; i++) {
        v += a * noise(p);
        p = p * 2.03 + vec2(1.7, 9.2);
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float aspect = uResolution.x / uResolution.y;

    // Aspect-corrected plane so blobs stay round on a 9:16 canvas.
    vec2 p = vec2(uv.x * aspect, uv.y);
    if (uWarp > 0.001) {
        vec2 q = vec2(
            fbm(uv * 2.2 + uSeed),
            fbm(uv * 2.2 + uSeed + 7.31)
        );
        p += (q - 0.5) * uWarp * 0.7;
    }

    vec2 c1 = vec2(uP1.x * aspect, uP1.y);
    vec2 c2 = vec2(uP2.x * aspect, uP2.y);
    vec2 c3 = vec2(uP3.x * aspect, uP3.y);
    vec2 c4 = vec2(uP4.x * aspect, uP4.y);

    float k = max(uSoftness, 1.0);
    float w1 = 1.0 / pow(max(distance(p, c1), 0.03), k);
    float w2 = 1.0 / pow(max(distance(p, c2), 0.03), k);
    float w3 = 1.0 / pow(max(distance(p, c3), 0.03), k);
    float w4 = 1.0 / pow(max(distance(p, c4), 0.03), k);

    vec3 col = (uC1 * w1 + uC2 * w2 + uC3 * w3 + uC4 * w4) / (w1 + w2 + w3 + w4);

    // Tiny ordered dither so wide gradients don't band on 8-bit screens.
    col += (hash(uv * 977.0 + uSeed) - 0.5) * (1.5 / 255.0);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
