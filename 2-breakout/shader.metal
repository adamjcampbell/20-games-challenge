#include <metal_stdlib>

using namespace metal;

struct Uniforms {
    float2 screen_size; // (width, height)
};

struct VertexIn {
    float3 position [[ attribute(0) ]];
    uchar4 color [[ attribute(1) ]];
};

struct VertexOut {
    float4 position [[ position ]];
    float4 color;
};

vertex VertexOut vertex_main(
    VertexIn in [[ stage_in ]]
) {
    VertexOut out;
    out.position = float4(in.position, 1.0);
    out.color = float4(in.color) / 255.0;
    return out;
}

fragment float4 fragment_main(
    VertexOut in [[ stage_in ]],
    constant Uniforms& uniforms [[buffer(0)]]
) {
    float2 center = float2(uniforms.screen_size.x * 0.5, uniforms.screen_size.y * 0.5);
    float2 position = in.position.xy;

    float d = distance(position, center);
    float length = 20;

    if (d < length) {
        return float4(1.0, 1.0, 1.0, 1.0);
    } else {
        return float4(0.0, 0.0, 0.0, 0.0);
    }
}

