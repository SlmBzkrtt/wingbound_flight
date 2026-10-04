#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uMode;      // 0: Classic, 1: Cyber, 2: Space, 3: Conquest
uniform float uIntensity; // Dynamic intensity (e.g. EMP, Slow-Mo, Combo)

out vec4 fragColor;

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 uv = fragCoord / max(uSize, vec2(1.0));
  vec2 centered = uv - vec2(0.5, 0.5);
  centered.x *= uSize.x / max(uSize.y, 1.0);
  float dist = length(centered);

  vec3 rgb = vec3(0.0);
  float alpha = 0.0;

  if (uMode < 0.5) {
    // MODE 0: Classic Sky - Subtle Golden Sun-Ray & Crisp Cinema Vignette (Premultiplied Alpha!)
    float sunRay = max(0.0, sin((uv.x * 5.0 - uv.y * 2.5) + uTime * 0.6));
    float topSunGlow = smoothstep(0.45, 0.0, uv.y) * sunRay * 0.05;
    float edgeVignette = smoothstep(0.45, 0.95, dist) * 0.16;
    rgb = mix(vec3(0.02, 0.05, 0.12), vec3(1.0, 0.94, 0.72), topSunGlow / max(topSunGlow + edgeVignette, 0.0001));
    alpha = topSunGlow + edgeVignette;
  } else if (uMode < 1.5) {
    // MODE 1: Cyber Neon - Subtle CRT Scanlines + Neon Edge Aura
    float scanline = sin(fragCoord.y * 1.8 - uTime * 12.0) * 0.5 + 0.5;
    float scanAlpha = scanline * 0.028;
    float edgeGlow = smoothstep(0.36, 0.88, dist) * (0.12 + uIntensity * 0.10);
    float pulse = 0.5 + 0.5 * sin(uTime * 3.5);
    rgb = mix(vec3(0.0, 0.95, 1.0), vec3(1.0, 0.0, 0.48), uv.y * 0.8 + pulse * 0.2);
    alpha = scanAlpha + edgeGlow;
  } else if (uMode < 2.5) {
    // MODE 2: Space Orbit - Gravitational Lensing Shimmer & Deep Space Vignette
    float ringWave = sin(dist * 30.0 - uTime * 4.5) * 0.5 + 0.5;
    float lensingBand = smoothstep(0.07, 0.22, dist) * (1.0 - smoothstep(0.22, 0.44, dist));
    float warpAlpha = lensingBand * ringWave * (0.065 + uIntensity * 0.08);
    float outerVoid = smoothstep(0.40, 0.90, dist) * 0.18;
    vec3 cosmicColor = mix(vec3(0.48, 0.18, 0.96), vec3(0.0, 0.89, 1.0), ringWave);
    rgb = cosmicColor * (warpAlpha / max(warpAlpha + outerVoid, 0.0001));
    alpha = warpAlpha + outerVoid;
  } else {
    // MODE 3: 1453 Conquest - Warm TorchlightShore Glow & Maritime Vignette
    float wave = sin(uv.y * 20.0 + uTime * 3.5) * 0.5 + 0.5;
    float shoreDist = abs(uv.x - 0.5) * 2.0;
    float torchGlow = smoothstep(0.65, 1.0, shoreDist) * (0.10 + 0.04 * wave + uIntensity * 0.08);
    rgb = mix(vec3(0.85, 0.25, 0.08), vec3(1.0, 0.78, 0.22), wave);
    alpha = torchGlow;
  }

  // Impeller requires premultiplied alpha output: vec4(rgb * alpha, alpha)
  fragColor = vec4(rgb * alpha, alpha);
}
