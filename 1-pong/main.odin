package pong

import "core:fmt"
import rl "vendor:raylib"

main :: proc() {

    // Initialise the raylib window
    rl.InitWindow(1280, 720, "Pong")
    rl.SetTargetFPS(200)
    defer rl.CloseWindow()

    // Start the game loop
    for !rl.WindowShouldClose() {
        screen_height := rl.GetScreenHeight()
        screen_width := rl.GetScreenWidth()
        screen_width_halved := screen_width / 2
        padding: i32 = 32

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
        rl.DrawText("0", score_left_x, padding, 72, rl.WHITE)
        rl.DrawText("0", score_right_x, padding, 72, rl.WHITE)

        // Draw paddles
        paddle_height: i32 = 64
        paddle_y := screen_height / 2 - paddle_height / 2
        paddle_left_x := padding
        paddle_right_x := screen_width - padding
        rl.DrawRectangle(paddle_left_x, paddle_y, 8, paddle_height, rl.WHITE)
        rl.DrawRectangle(paddle_right_x, paddle_y, 8, paddle_height, rl.WHITE)

        rl.EndDrawing()
    }

}
