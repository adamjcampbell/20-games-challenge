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

    float2 paddle_pos = float2(center.x - 100, uniforms.screen_size.y - 100);
    float2 paddle_size = float2(300, 50);
    // An implementation of point in rect; compares the vectors in catesian space
    float2 relative_pos = position - paddle_pos; // Distance from top left point
    // relative_pos is inside; not above, left of, right of, or beneath
    bool paddle_check = all(relative_pos >= 0.0) && all(relative_pos < paddle_size);

    if (d < length || paddle_check) {
        return float4(1.0, 1.0, 1.0, 1.0);
    } else {
        return float4(0.0, 0.0, 0.0, 0.0);
    }
}

