package pong

import rl "vendor:raylib"

// Padding from the edge for drawn elements
Padding: f32 : 32

// Paddle movement velocity
PaddleVelocity :: 200

// A player movable paddle
Paddle :: struct {
    size:     rl.Vector2,
    position: rl.Vector2,
}

// Creation of a padde at the desired x value centered vertically
init_paddle :: proc(x: f32) -> Paddle {
    size := rl.Vector2{8, 64}
    y: f32 = f32(rl.GetScreenHeight() / 2) - size.y / 2
    return {size, {x, y}}
}

update_paddle :: proc(
    up: rl.KeyboardKey,
    down: rl.KeyboardKey,
    paddle: ^Paddle,
) {
    paddle_dv := f32(PaddleVelocity) * rl.GetFrameTime()

    if rl.IsKeyDown(up) {
        paddle.position.y = clamp(
            paddle.position.y - paddle_dv,
            0,
            f32(rl.GetScreenHeight()) - paddle.size.y,
        )
    }

    if rl.IsKeyDown(down) {
        paddle.position.y = clamp(
            paddle.position.y + paddle_dv,
            0,
            f32(rl.GetScreenHeight()) - paddle.size.y,
        )
    }
}

main :: proc() {

    // Initialise the raylib window
    rl.InitWindow(640, 480, "Pong")
    rl.SetTargetFPS(200)
    defer rl.CloseWindow()

    // Game State
    paddle_left := init_paddle(x = Padding)
    paddle_right := init_paddle(x = f32(rl.GetScreenWidth()) - Padding)
    ball_going_left := true
    ball_width: f32 = 8
    ball := rl.Rectangle {
        f32(rl.GetScreenWidth() / 2) - (ball_width / 2),
        f32(rl.GetScreenHeight() / 2) - (ball_width / 2),
        ball_width,
        ball_width,
    }

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
        zero_width := rl.MeasureText("0", 72)
        score_left_x := screen_width_halved / 2 - zero_width / 2
        score_right_x := screen_width_halved + score_left_x
        rl.DrawText("0", score_left_x, i32(Padding), 72, rl.WHITE)
        rl.DrawText("0", score_right_x, i32(Padding), 72, rl.WHITE)

        // Draw paddles
        rl.DrawRectangleV(paddle_left.position, paddle_left.size, rl.WHITE)
        rl.DrawRectangleV(paddle_right.position, paddle_right.size, rl.WHITE)

        // Draw ball
        rl.DrawRectangleRec(ball, rl.WHITE)

        rl.EndDrawing()

        // Update paddle positions
        update_paddle(.W, .S, &paddle_left)
        update_paddle(.UP, .DOWN, &paddle_right)

        // Update ball position
        ball_dv := f32(PaddleVelocity) * rl.GetFrameTime()
        if ball_going_left {
            ball.x -= ball_dv
        } else {
            ball.x += ball_dv
        }

        if rl.CheckCollisionRecs(
            ball,
            {
                paddle_left.position.x,
                paddle_left.position.y,
                paddle_left.size.x,
                paddle_left.size.y,
            },
        ) {
            ball_going_left = false
        }

        if rl.CheckCollisionRecs(
            ball,
            {
                paddle_right.position.x,
                paddle_right.position.y,
                paddle_right.size.x,
                paddle_right.size.y,
            },
        ) {
            ball_going_left = true
        }
    }

}
