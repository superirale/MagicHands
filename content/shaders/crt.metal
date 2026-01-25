#include <metal_stdlib>
using namespace metal;

struct VertexOutput {
    float4 position [[position]];
    float2 texCoord;
};

// Uniforms must align to 16 bytes for safe binding
struct Uniforms {
    float time;           // Scanline roll / Flickering
    float distortion;     // Curvature strength (e.g. 0.1)
    float scanStrength;   // Scanline darkness (e.g. 0.25)
    float chromaStr;      // Chromatic Aberration offset (e.g. 0.005)
};

fragment float4 post_fragment(VertexOutput in [[stage_in]],
                              texture2d<float> sceneTex [[texture(0)]],
                              sampler samp [[sampler(0)]],
                              constant Uniforms& uniforms [[buffer(0)]]) {
    
    float2 uv = in.texCoord;
    
    // --- 1. Curvature / Distortion ---
    float2 centered = uv - 0.5;
    float r2 = dot(centered, centered);
    float2 warped = centered * (1.0 + uniforms.distortion * r2 * r2); // Gentle warp
    uv = warped + 0.5;
    
    // Check bounds (Vignette Cutoff)
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        return float4(0.0, 0.0, 0.0, 1.0);
    }
    
    // --- 2. Chromatic Aberration ---
    float2 chromaOffset = float2(uniforms.chromaStr * (1.0 + r2), 0.0);
    
    // Sample texture with offsets
    float r = sceneTex.sample(samp, uv + chromaOffset).r;
    float g = sceneTex.sample(samp, uv).g;
    float b = sceneTex.sample(samp, uv - chromaOffset).b;
    
    float3 color = float3(r, g, b);
    
    // --- 3. Scanlines ---
    // Scanline count proportional to height, animated by time
    float scanlineCount = 720.0 * 0.5; // Roughly half resolution scanlines
    float s = sin(uv.y * scanlineCount * 6.28 + uniforms.time * 5.0);
    float scanlineVal = 0.5 + 0.5 * s; // 0..1
    
    // Darken scanlines
    color *= 1.0 - (uniforms.scanStrength * (1.0 - scanlineVal));
    
    // --- 4. Vignette (Smooth darkening at edges) ---
    float vignette = 1.0 - dot(centered, centered) * 1.5;
    color *= smoothstep(0.0, 1.0, vignette);
    
    return float4(color, 1.0);
}
