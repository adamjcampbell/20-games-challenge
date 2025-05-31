#include <metal_stdlib>

using namespace metal;

struct VertexIn {
    float3 pos [[ attribute(0) ]];
};

vertex float4 vertex_main(
    VertexIn in [[ stage_in ]],
    unsigned int vid [[ vertex_id ]]
) {
    return float4(in.pos, 1.0);
}

fragment float4 fragment_main() {
    return float4(1.0, 0.0, 0.0, 1.0);
}

