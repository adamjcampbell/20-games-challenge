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

        // Draw black background
        rl.ClearBackground(rl.BLACK)

        // Draw divider
        divider_width: i32 = 10
        divider_x := half_screen_width - divider_width / 2
        rl.DrawRectangle(divider_x, 0, divider_width, screen_height, rl.WHITE)

        // Draw scores
        zero_width := rl.MeasureText("0", 72)
        left_score_x := half_screen_width / 2 - zero_width / 2
        right_score_x := half_screen_width + left_score_x
        rl.DrawText("0", left_score_x, 0, 72, rl.WHITE)
        rl.DrawText("0", right_score_x, 0, 72, rl.WHITE)

        rl.EndDrawing()
    }

}
