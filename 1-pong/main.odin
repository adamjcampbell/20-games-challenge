package pong

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

// Padding from the edge for drawn elements
Padding: f32 : 32

// Movement velocity
Velocity :: 200

MaxBounceAngle :: (math.PI / 180) * 75

// A player movable paddle
Paddle :: rl.Rectangle

paddle_left: Paddle
paddle_right: Paddle

// Creation of a paddle at the desired x value centered vertically
init_paddle :: proc(x: f32) -> Paddle {
    height: f32 = 64
    y: f32 = f32(rl.GetScreenHeight() / 2) - height / 2
    return {x, y, 8, height}
}

// The ball containing a draw rect and normalised direction vector
Ball :: struct {
    rectangle: rl.Rectangle,
    direction: rl.Vector2,
    velocity:  f32,
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
        rl.Vector2Normalize({1, -1}),
        0.5,
    }
}

update_paddle :: proc(
    paddle: ^Paddle,
    up: rl.KeyboardKey,
    down: rl.KeyboardKey,
) {
    paddle_dv := f32(Velocity) * rl.GetFrameTime()

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

update_ball :: proc(ball: ^Ball, paddle: Paddle) {
    zero_rec := rl.Rectangle{}
    collision := rl.GetCollisionRec(ball.rectangle, paddle)
    // Check for collision
    if collision == zero_rec {
        return
    }
    // Get relative y intersection -32 to 32
    relative_y := paddle.y + paddle.height / 2 - collision.y
    fmt.printfln("relative_y: %v", relative_y)
    // Normalize the relative y to get -1 to 1
    normalised_y := relative_y / (paddle.height / 2)
    fmt.printfln("normalised_y: %v", normalised_y)
    // Multiply the normalised y by max angle in radians
    bounce_angle := normalised_y * MaxBounceAngle
    fmt.printfln("bounce_angle: %v", (180 / math.PI) * bounce_angle)
    // Calculate a direction vector on the unit circle
    direction := rl.Vector2 {
        math.cos_f32(bounce_angle),
        -math.sin_f32(bounce_angle),
    }
    fmt.printfln("direction: %v", direction)
    // Correctly update position and direction depending on paddle
    switch paddle {
    case paddle_left:
        ball.direction = direction
        ball.rectangle.x = paddle.x + paddle.width
    case paddle_right:
        ball.direction = -direction
        ball.rectangle.x = paddle.x - ball.rectangle.width
    }
}

main :: proc() {

    // Initialise the raylib window
    rl.InitWindow(640, 480, "Pong")
    rl.SetTargetFPS(200)
    defer rl.CloseWindow()

    // Load sound
    rl.InitAudioDevice()
    wall_sound := rl.LoadSound("wall.mp3")
    paddle_sound := rl.LoadSound("paddle.mp3")
    score_sound := rl.LoadSound("score.mp3")
    defer rl.CloseAudioDevice()

    // Game State
    score_left := 0
    score_right := 0
    paddle_left = init_paddle(x = Padding)
    paddle_right = init_paddle(x = f32(rl.GetScreenWidth()) - Padding)
    ball := init_ball()

    // Start the game loop
    for !rl.WindowShouldClose() {
        // Update
        {
            // User controlled paddle update
            update_paddle(&paddle_left, .W, .S)
            update_paddle(&paddle_right, .UP, .DOWN)

            // Update ball & scores
            {
                max_x := f32(rl.GetScreenWidth()) - ball.rectangle.width
                max_y := f32(rl.GetScreenHeight()) - ball.rectangle.height

                if ball.rectangle.x <= 0 {
                    rl.PlaySound(score_sound)
                    score_right += 1
                    ball = init_ball()
                } else if ball.rectangle.x >= max_x {
                    rl.PlaySound(score_sound)
                    score_left += 1
                    ball = init_ball()
                }

                if ball.rectangle.y <= 0 || ball.rectangle.y >= max_y {
                    rl.PlaySound(wall_sound)
                    ball.rectangle.y = clamp(ball.rectangle.y, 0, max_y)
                    ball.direction.y = -ball.direction.y
                }

                zero_rectangle := rl.Rectangle{}
                left_collision := rl.GetCollisionRec(
                    ball.rectangle,
                    paddle_left,
                )
                right_collision := rl.GetCollisionRec(
                    ball.rectangle,
                    paddle_right,
                )

                update_ball(&ball, paddle_left)
                update_ball(&ball, paddle_right)

                dv := (600 * ball.velocity) * rl.GetFrameTime()
                ball.rectangle.x += ball.direction.x * dv
                ball.rectangle.y += ball.direction.y * dv
            }
        }

        // Draw
        {
            rl.BeginDrawing()

            // Draw a black background
            rl.ClearBackground(rl.BLACK)

            // Draw the segmented divider
            {
                count := 30
                width := 4
                length := int(rl.GetScreenHeight()) / (count * 2)

                // Loop drawing one segment of the line at a time
                for i := 0; i <= count; i += 1 {
                    x := f32(rl.GetScreenWidth() / 2)

                    // iteration * length * 2 to account for negative space
                    start_y := f32(i) * f32(length) * 2
                    end_y := start_y + f32(length)

                    start := rl.Vector2{x, start_y}
                    end := rl.Vector2{x, end_y}
                    rl.DrawLineEx(start, end, f32(width), rl.WHITE)
                }
            }

            // Draw scores
            {
                font_size: i32 = 72
                padding := i32(Padding)

                lstring := fmt.ctprintf("%v", score_left)
                rstring := fmt.ctprintf("%v", score_right)

                lwidth := rl.MeasureText(lstring, font_size)
                rwidth := rl.MeasureText(rstring, font_size)

                lx := rl.GetScreenWidth() / 4 - lwidth / 2
                rx := 3 * (rl.GetScreenWidth() / 4) - rwidth / 2

                rl.DrawText(lstring, lx, padding, font_size, rl.WHITE)
                rl.DrawText(rstring, rx, padding, font_size, rl.WHITE)
            }

            // Draw paddles
            rl.DrawRectangleRec(paddle_left, rl.WHITE)
            rl.DrawRectangleRec(paddle_right, rl.WHITE)

            // Draw ball
            rl.DrawRectangleRec(ball.rectangle, rl.WHITE)

            rl.EndDrawing()
        }

    }

}
