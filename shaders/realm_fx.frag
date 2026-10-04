#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uMode;      // 0: Classic, 1: Cyber, 2: Space, 3: Conquest
uniform float uIntensity; // Dynamic intensity (e.g. EMP, Slow-Mo, Combo)

out vec4 fragColor;

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 uv = fragCoord / uSize;
  vec2 centered = uv - vec2(0.5, 0.5);
  centered.x *= uSize.x / max(uSize.y, 1.0);
  float dist = length(centered);

  vec4 color = vec4(0.0);

  if (uMode < 0.5) {
    // MODE 0: Classic Sky - Warm Golden Sunbeam & Soft Atmospheric Vignette
    float sunRay = sin((uv.x * 6.0 - uv.y * 3.0) + uTime * 0.8) * 0.5 + 0.5;
    float topGlow = smoothstep(0.65, 0.0, uv.y) * 0.045 * sunRay;
    float vignette = smoothstep(0.42, 0.92, dist) * 0.14;
    color = vec4(1.0, 0.92, 0.65, topGlow) + vec4(0.04, 0.06, 0.12, vignette);
  } else if (uMode < 1.5) {
    // MODE 1: Cyber Neon - CRT Scanlines + Synthwave Edge Glow + Chromatic Pulse
    float scanline = sin(fragCoord.y * 1.6 - uTime * 14.0) * 0.5 + 0.5;
    float scanAlpha = scanline * 0.038;
    float edgeGlow = smoothstep(0.32, 0.85, dist);
    float pulse = 0.5 + 0.5 * sin(uTime * 3.5);
    vec3 neonTint = mix(vec3(0.0, 0.95, 1.0), vec3(1.0, 0.0, 0.48), uv.y + pulse * 0.2);
    float alpha = scanAlpha + edgeGlow * (0.14 + uIntensity * 0.12);
    color = vec4(neonTint * alpha, alpha);
  } else if (uMode < 2.5) {
    // MODE 2: Space Orbit - Gravitational Lensing Rings & Deep Nebula Warp
    float ringWave = sin(dist * 28.0 - uTime * 4.2) * 0.5 + 0.5;
    float lensingBand = smoothstep(0.08, 0.24, dist) * (1.0 - smoothstep(0.24, 0.48, dist));
    float warpAlpha = lensingBand * ringWave * (0.075 + uIntensity * 0.08);
    float outerVoid = smoothstep(0.38, 0.88, dist) * 0.18;
    vec3 cosmicColor = mix(vec3(0.48, 0.18, 0.96), vec3(0.0, 0.89, 1.0), ringWave);
    float totalAlpha = warpAlpha + outerVoid;
    color = vec4(cosmicColor * warpAlpha, totalAlpha);
  } else {
    // MODE 3: 1453 Conquest - Torchlight Ember Shimmer & Historical Vignette
    float wave = sin(uv.y * 22.0 + uTime * 3.2 + sin(uv.x * 10.0)) * 0.5 + 0.5;
    float emberGlow = smoothstep(0.45, 0.88, dist) * (0.12 + 0.04 * wave + uIntensity * 0.10);
    vec3 fireTint = mix(vec3(0.85, 0.22, 0.12), vec3(0.95, 0.72, 0.22), wave);
    color = vec4(fireTint * emberGlow * 0.65, emberGlow);
  }

  fragColor = color;
}
