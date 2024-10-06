package pong

import "core:fmt"
import rl "vendor:raylib"

main :: proc() {
    // Initialise the raylib window
    rl.InitWindow(1280, 720, "Pong")
    rl.SetTargetFPS(200)
    defer rl.CloseWindow()

    divider_width: i32 = 20

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        // Draw divider
        rl.DrawRectangle(
            (rl.GetScreenWidth() / 2) - (divider_width / 2),
            0,
            divider_width,
            rl.GetScreenHeight(),
            rl.WHITE,
        )

        rl.EndDrawing()
    }
}
