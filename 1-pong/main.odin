package pong

import "core:fmt"
import rl "vendor:raylib"

// Padding from the edge for drawn elements
Padding: f32 : 32

// Paddle movement velocity
PaddleVelocity :: 200

// A player movable paddle
Paddle :: rl.Rectangle

// Creation of a padde at the desired x value centered vertically
init_paddle :: proc(x: f32) -> Paddle {
    height: f32 = 64
    y: f32 = f32(rl.GetScreenHeight() / 2) - height / 2
    return {x, y, 8, height}
}

// The ball!
Ball :: struct {
    rectangle: rl.Rectangle,
    direction: rl.Vector2,
}

init_ball :: proc() -> Ball {
    ball_width: f32 = 8
    return {
        {
            f32(rl.GetScreenWidth() / 2) - (ball_width / 2),
            f32(rl.GetScreenHeight() / 2) - (ball_width / 2),
            ball_width,
            ball_width,
        },
        {1, -1},
    }
}

update_paddle :: proc(
    up: rl.KeyboardKey,
    down: rl.KeyboardKey,
    paddle: ^Paddle,
) {
    paddle_dv := f32(PaddleVelocity) * rl.GetFrameTime()

    if rl.IsKeyDown(up) {
        paddle.y = clamp(
            paddle.y - paddle_dv,
            0,
            f32(rl.GetScreenHeight()) - paddle.height,
        )
    }

    if rl.IsKeyDown(down) {
        paddle.y = clamp(
            paddle.y + paddle_dv,
            0,
            f32(rl.GetScreenHeight()) - paddle.height,
        )
    }
}

main :: proc() {

    // Initialise the raylib window
    rl.InitWindow(640, 480, "Pong")
    rl.SetTargetFPS(200)
    defer rl.CloseWindow()

    // Game State
    score_left := 0
    score_right := 0
    paddle_left := init_paddle(x = Padding)
    paddle_right := init_paddle(x = f32(rl.GetScreenWidth()) - Padding)
    ball := init_ball()

    // Start the game loop
    for !rl.WindowShouldClose() {
        screen_height := rl.GetScreenHeight()
        screen_width := rl.GetScreenWidth()
        screen_width_halved := screen_width / 2

        rl.BeginDrawing()

        // Draw a black background
        rl.ClearBackground(rl.BLACK)

        // Draw the segmented divider
        segment_count := 30
        segment_width := 4
        segment_length := int(screen_height) / (segment_count * 2)

        // Loop drawing one segment of the line at a time
        for i := 0; i <= segment_count; i += 1 {
            x := f32(screen_width_halved)
            // start_y is iteration * length * 2 to account for negative space
            start_y := f32(i) * f32(segment_length) * 2
            end_y := start_y + f32(segment_length)
            start_pos: rl.Vector2 = {x, start_y}
            end_pos: rl.Vector2 = {x, end_y}
            rl.DrawLineEx(start_pos, end_pos, f32(segment_width), rl.WHITE)
        }

        // Draw scores
        {
            font_size: i32 = 72
            padding := i32(Padding)

            lstring := fmt.ctprintf("%v", score_left)
            rstring := fmt.ctprintf("%v", score_right)

            lwidth := rl.MeasureText(lstring, font_size)
            rwidth := rl.MeasureText(rstring, font_size)

            lx := screen_width / 4 - lwidth / 2
            rx := 3 * (screen_width / 4) - rwidth / 2

            rl.DrawText(lstring, lx, padding, font_size, rl.WHITE)
            rl.DrawText(rstring, rx, padding, font_size, rl.WHITE)
        }

        // Draw paddles
        rl.DrawRectangleRec(paddle_left, rl.WHITE)
        rl.DrawRectangleRec(paddle_right, rl.WHITE)

        // Draw ball
        rl.DrawRectangleRec(ball.rectangle, rl.WHITE)

        rl.EndDrawing()

        // Update paddle positions
        update_paddle(.W, .S, &paddle_left)
        update_paddle(.UP, .DOWN, &paddle_right)

        // Update ball position
        ball_dv := f32(PaddleVelocity) * rl.GetFrameTime()
        ball_max_x := f32(screen_width) - ball.rectangle.width
        ball_max_y := f32(screen_height) - ball.rectangle.height

        ball.rectangle.x += ball.direction.x * ball_dv
        ball.rectangle.y += ball.direction.y * ball_dv

        if ball.rectangle.x <= 0 {
            score_right += 1
            ball = init_ball()
        } else if ball.rectangle.x >= ball_max_x {
            score_left += 1
            ball = init_ball()
        }

        if ball.rectangle.y <= 0 {
            ball.direction.y = 1
        } else if ball.rectangle.y >= ball_max_y {
            ball.direction.y = -1
        }

        if rl.CheckCollisionRecs(ball.rectangle, paddle_left) ||
            rl.CheckCollisionRecs(ball.rectangle, paddle_right) {
            ball.direction.x = -ball.direction.x
        }
    }

}
