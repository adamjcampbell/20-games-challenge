#include <metal_stdlib>

using namespace metal;

struct Position {
    float x;
    float y;
};

struct Size {
    float width;
    float height;
};

struct Ball {
    Position pos;
    float radius;
};

struct Paddle {
    Position pos;
    Size size;
};

struct Bricks {
    Position pos;
    Size size;
    float line_width;
    float h_spacing;
};

struct Uniforms {
    Size screen_size; // (width, height)
    Ball ball;
    Paddle paddle;
    Bricks bricks;
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

float2 to_float2(Position position) {
    return float2(position.x, position.y);
}

float2 to_float2(Size size) {
    return float2(size.width, size.height);
}

// Checks the point is in rect by making a relative point and checking it is within bounds
bool point_in_rect(float2 point, Position top_left, Size size) {
    float2 rel = point - to_float2(top_left);
    return all(rel >= 0.0) && all(rel < to_float2(size));
}

fragment float4 fragment_main(
    VertexOut in [[ stage_in ]],
    constant Uniforms& uniforms [[buffer(0)]]
) {
    float2 position = in.position.xy;

    float d = distance(position, to_float2(uniforms.ball.pos));
    float length = uniforms.ball.radius;
    bool ball_check = d < length;

    bool paddle_check = point_in_rect(position, uniforms.paddle.pos, uniforms.paddle.size);

    float bricks_rel_x = position.x - uniforms.bricks.pos.x;
    float line_width = uniforms.bricks.line_width;
    float line_spacing = uniforms.bricks.h_spacing;
    bool not_brick_gap = fract(bricks_rel_x / line_spacing) > (line_width / line_spacing) || bricks_rel_x < line_width;
    bool in_brick_rect = point_in_rect(position, uniforms.bricks.pos, uniforms.bricks.size);

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

