#include <metal_stdlib>

using namespace metal;

vertex float4 vertex_main(unsigned int vid [[ vertex_id ]]) {
    float4 positions[3] = {
        float4(-0.5, -0.5, 0.0, 1.0),
        float4( 0.0,  0.5, 0.0, 1.0),
        float4( 0.5, -0.5, 0.0, 1.0)
    };

    return positions[vid];
}

fragment float4 fragment_main() {
    return float4(1.0, 0.0, 0.0, 1.0);
}

