package pong

import rl "vendor:raylib"

// Padding from the edge for drawn elements
Padding: f32 : 32

// A player movable paddle
Paddle :: struct {
    size:     rl.Vector2,
    position: rl.Vector2,
}

// Creation of a padde at the desired x value centered vertically
paddle :: proc(x: f32) -> Paddle {
    size := rl.Vector2{8, 64}
    y: f32 = f32(rl.GetScreenHeight() / 2) - size.y / 2
    return {size, {x, y}}
}

main :: proc() {

    // Initialise the raylib window
    rl.InitWindow(640, 480, "Pong")
    rl.SetTargetFPS(200)
    defer rl.CloseWindow()

    // Game State
    paddle_left := paddle(x = Padding)
    paddle_right := paddle(x = f32(rl.GetScreenWidth()) - Padding)

    // Start the game loop
    for !rl.WindowShouldClose() {
        screen_height := rl.GetScreenHeight()
        screen_width := rl.GetScreenWidth()
        screen_width_halved := screen_width / 2

        rl.BeginDrawing()

        // Draw a black background
        rl.ClearBackground(rl.BLACK)

        // Draw the segmented divider
        segment_count := 32
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

        paddle_velocity := 200
        paddle_dv := f32(paddle_velocity) * rl.GetFrameTime()

        // Update paddle positions
        if rl.IsKeyDown(.W) {
            paddle_left.position.y = clamp(
                paddle_left.position.y - paddle_dv,
                0,
                f32(screen_height) - paddle_left.size.y,
            )
        }

        if rl.IsKeyDown(.S) {
            paddle_left.position.y = clamp(
                paddle_left.position.y + paddle_dv,
                0,
                f32(screen_height) - paddle_left.size.y,
            )
        }

        if rl.IsKeyDown(.UP) {
            paddle_right.position.y = clamp(
                paddle_right.position.y - paddle_dv,
                0,
                f32(screen_height) - paddle_right.size.y,
            )
        }

        if rl.IsKeyDown(.DOWN) {
            paddle_right.position.y = clamp(
                paddle_right.position.y + paddle_dv,
                0,
                f32(screen_height) - paddle_right.size.y,
            )
        }

        rl.EndDrawing()
    }

}
