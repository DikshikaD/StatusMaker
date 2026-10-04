#include <flutter/runtime_effect.glsl>

// Scattered soft light discs — bokeh for Love/Birthday, floating diya light
// for Bhakti/Diwali, dust in a sunbeam for Morning. Three layers at different
// scales so it never reads as a grid. Premultiplied transparent overlay.
uniform vec2 uResolution;  // 0-1
uniform float uTime;       // 2 (unused)
uniform vec3 uColor;       // 3-5
uniform float uDensity;    // 6   0..1 how many cells get a disc
uniform float uSize;       // 7   0..1 disc radius multiplier
uniform float uSeed;       // 8
uniform float uYBias;      // 9   -1 = cluster at bottom, 0 = even, 1 = cluster at top
uniform float uSoft;       // 10  0 = crisp bokeh rings, 1 = fully diffused glow

out vec4 fragColor;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float aspect = uResolution.x / uResolution.y;
    vec2 p = vec2(uv.x * aspect, uv.y);

    float bias = 1.0;
    if (uYBias > 0.0) {
        bias = mix(1.0, 1.0 - uv.y, uYBias);
    } else if (uYBias < 0.0) {
        bias = mix(1.0, uv.y, -uYBias);
    }

    float acc = 0.0;
    for (int l = 0; l < 3; l++) {
        float fl = float(l);
        float cells = 3.0 + fl * 2.5;
        vec2 g = p * cells + fl * 13.1 + uSeed;
        vec2 cell = floor(g);
        vec2 f = fract(g) - 0.5;

        float pick = hash(cell + fl * 7.0);
        if (pick < uDensity * (0.55 - fl * 0.1)) {
            vec2 off = (vec2(hash(cell + 1.7), hash(cell + 9.2)) - 0.5) * 0.6;
            float rad = (0.12 + 0.2 * hash(cell + 3.3)) * uSize * (1.0 - fl * 0.2);
            float d = length(f - off);
            float soft = mix(0.02, rad * 0.9, uSoft);
            float disc = smoothstep(rad, rad - soft, d);
            // A thin brighter rim gives real bokeh its character.
            float rim = smoothstep(rad, rad - 0.015, d) * (1.0 - smoothstep(rad - 0.03, rad, d));
            disc += rim * 0.5 * (1.0 - uSoft);
            acc += disc * (0.35 + 0.45 * hash(cell + 5.5)) * bias;
        }
    }
    acc = clamp(acc, 0.0, 1.0);
    fragColor = vec4(uColor * acc, acc);
}
