#include <flutter/runtime_effect.glsl>

// Surface textures layered over a base gradient. One shader, several modes,
// so the whole catalogue needs a single compiled program:
//   0 grain          — fine film grain (paint with BlendMode.softLight)
//   1 paper          — fibrous paper (paint with BlendMode.softLight)
//   2 halftone       — rotated print dots that grow towards the bottom
//   3 dot grid       — tiny uniform dots
//   4 diagonal lines — fine pinstripes
// Modes 2–4 output the given colour; 0–1 output neutral grey for blending.
//
// Patterns are measured in *logical* canvas units (a 640-tall space), not in
// device pixels, so a 3x export shows the same grain density as the screen.
uniform vec2 uResolution;  // 0-1
uniform float uTime;       // 2 (unused)
uniform float uMode;       // 3
uniform float uStrength;   // 4   opacity (0..1)
uniform float uScale;      // 5   pattern density multiplier (1 = default)
uniform vec3 uColor;       // 6-8
uniform float uSeed;       // 9

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
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p = p * 2.1 + vec2(3.1, 1.7);
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float aspect = uResolution.x / uResolution.y;
    // Logical-space coordinates (height = 640 units) — see header comment.
    vec2 lp = vec2(uv.x * aspect, uv.y) * 640.0;

    float mode = floor(uMode + 0.5);
    vec4 outColor = vec4(0.0);

    if (mode < 0.5) {
        // --- grain ---
        float n = hash(floor(lp * uScale) + uSeed);
        float a = uStrength;
        outColor = vec4(vec3(n) * a, a);
    } else if (mode < 1.5) {
        // --- paper ---
        float fibre = fbm(lp * 0.02 * uScale + uSeed);
        float fine = hash(floor(lp * uScale) + uSeed * 3.0);
        // Faint long fibres running mostly horizontally.
        float strands = noise(vec2(lp.x * 0.004, lp.y * 0.08) * uScale + uSeed);
        float g = 0.5 + (fibre - 0.5) * 0.8 + (fine - 0.5) * 0.22 + (strands - 0.5) * 0.18;
        float a = uStrength;
        outColor = vec4(vec3(clamp(g, 0.0, 1.0)) * a, a);
    } else if (mode < 2.5) {
        // --- halftone ---
        float c = cos(0.7854), s = sin(0.7854);
        vec2 r = vec2(lp.x * c - lp.y * s, lp.x * s + lp.y * c);
        vec2 cell = r * 0.045 * uScale;
        float d = length(fract(cell) - 0.5);
        float radius = mix(0.04, 0.42, pow(uv.y, 1.6));
        float a = smoothstep(radius, radius - 0.08, d) * uStrength;
        outColor = vec4(uColor * a, a);
    } else if (mode < 3.5) {
        // --- dot grid ---
        vec2 cell = lp * 0.06 * uScale;
        float d = length(fract(cell) - 0.5);
        float a = smoothstep(0.09, 0.05, d) * uStrength;
        outColor = vec4(uColor * a, a);
    } else {
        // --- diagonal pinstripes ---
        float v = fract((lp.x + lp.y) * 0.05 * uScale);
        float a = (1.0 - smoothstep(0.03, 0.07, abs(v - 0.5))) * uStrength;
        outColor = vec4(uColor * a, a);
    }

    fragColor = outColor;
}
