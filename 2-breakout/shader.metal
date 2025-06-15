#include <metal_stdlib>

using namespace metal;

struct Size {
    float width;
    float height;
};

struct Uniforms {
    Size screen_size;

    float2 ball_pos;

    float2 paddle_pos;
    Size paddle_size;

    float2 bricks_pos;
    Size bricks_size;

    float ball_radius;

    float bricks_line_width;
    float bricks_h_spacing;
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

// Checks the point is in rect by making a relative point and checking it is within bounds
bool point_in_rect(float2 point, float2 top_left, Size size) {
    float2 rel = point - top_left;
    return all(rel >= 0.0) && all(rel < float2(size.width, size.height));
}

fragment float4 fragment_main(
    VertexOut in [[ stage_in ]],
    constant Uniforms& uniforms [[buffer(0)]]
) {
    float2 position = in.position.xy;

    float d = distance(position, uniforms.ball_pos);
    float length = uniforms.ball_radius;
    bool ball_check = d < length;

    bool paddle_check = point_in_rect(position, uniforms.paddle_pos, uniforms.paddle_size);

    float bricks_rel_x = position.x - uniforms.bricks_pos.x;
    float line_width = uniforms.bricks_line_width;
    float line_spacing = uniforms.bricks_h_spacing;
    bool not_brick_gap = fract(bricks_rel_x / line_spacing) > (line_width / line_spacing) || bricks_rel_x < line_width;
    bool in_brick_rect = point_in_rect(position, uniforms.bricks_pos, uniforms.bricks_size);

    if (in_brick_rect && not_brick_gap) {
        return float4(1.0, 1.0, 1.0, 1.0);
    } else if (in_brick_rect) {
        return float4(1.0, 0.0, 0.0, 0.0);
    }

    if (ball_check || paddle_check) {
        return float4(1.0, 1.0, 1.0, 1.0);
    } else {
        return float4(0.0, 0.0, 0.0, 0.0);
    }
}

