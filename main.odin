package main

import "core:math"
import rl "vendor:raylib"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 800

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Asteroids")
	defer rl.CloseWindow()
	rl.SetTargetFPS(120)

	ship := Ship {
		rot = 1.5708,
	}

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()
		{
			// Draw Loop 
			rl.BeginDrawing()
			defer rl.EndDrawing()

			rl.ClearBackground(rl.BLACK)
			draw_ship(ship)
		}
	}
}
