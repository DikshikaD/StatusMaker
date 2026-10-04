#include <flutter/runtime_effect.glsl>

// Soft volumetric light rays spreading from one point (a sunrise, a diya, a
// spotlight). Transparent overlay: premultiplied RGBA, so it composites over
// any base layer with plain source-over.
uniform vec2 uResolution;  // 0-1
uniform float uTime;       // 2 (unused)
uniform vec2 uOrigin;      // 3-4   ray origin, normalised (may sit off-canvas)
uniform vec3 uColor;       // 5-7
uniform float uIntensity;  // 8     overall opacity (0..1.5)
uniform float uCount;      // 9     angular frequency — roughly the ray count
uniform float uFalloff;    // 10    how quickly rays fade with distance (1..5)
uniform float uSeed;       // 11

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

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    float aspect = uResolution.x / uResolution.y;

    vec2 d = uv - uOrigin;
    d.x *= aspect;
    float dist = length(d);
    float ang = atan(d.y, d.x);

    // Two interleaved angular frequencies so the rays aren't a perfect fan.
    float rays = 0.5 + 0.5 * sin(ang * uCount + uSeed);
    rays *= 0.55 + 0.45 * (0.5 + 0.5 * sin(ang * uCount * 0.37 + uSeed * 1.7 + 1.3));
    rays = pow(rays, 3.0);
    // Break each ray up a little along its length.
    rays *= 0.7 + 0.3 * noise(vec2(ang * 4.0 + uSeed, dist * 2.5));

    float fall = exp(-dist * uFalloff);
    float core = exp(-dist * dist * 9.0) * 0.9;   // bright, soft centre glow

    float a = clamp((rays * fall * 0.85 + core) * uIntensity, 0.0, 1.0);
    fragColor = vec4(uColor * a, a);
}
