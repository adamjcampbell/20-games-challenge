package pong

import "core:fmt"
import rl "vendor:raylib"

main :: proc() {
    // Initialise the raylib window
    rl.InitWindow(1280, 720, "Pong")
    rl.SetTargetFPS(200)
    defer rl.CloseWindow()

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        rl.EndDrawing()
    }
}
