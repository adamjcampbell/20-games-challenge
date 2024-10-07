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
        half_screen_width := rl.GetScreenWidth() / 2

        rl.BeginDrawing()

        // Draw a black background
        rl.ClearBackground(rl.BLACK)

        // Draw the segmented divider
        segments := 32
        segment_width := 4
        segment_length := int(screen_height) / (segments * 2)

        // Loop drawing one segment of the line at a time
        for i := 0; i <= segments; i += 1 {
            x := f32(half_screen_width)
            // start_y is iteration * length * 2 to account for negative space
            start_y := f32(i) * f32(segment_length) * 2
            end_y := start_y + f32(segment_length)
            start_pos: rl.Vector2 = {x, start_y}
            end_pos: rl.Vector2 = {x, end_y}
            rl.DrawLineEx(start_pos, end_pos, f32(segment_width), rl.WHITE)
        }

        // Draw scores
        zero_width := rl.MeasureText("0", 72)
        left_score_x := half_screen_width / 2 - zero_width / 2
        right_score_x := half_screen_width + left_score_x
        rl.DrawText("0", left_score_x, 0, 72, rl.WHITE)
        rl.DrawText("0", right_score_x, 0, 72, rl.WHITE)

        rl.EndDrawing()
    }

}
