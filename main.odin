package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 800

SHIP_ROTATION_SPEED :: 5

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Asteroids")
	defer rl.CloseWindow()
	rl.SetTargetFPS(120)

	ship := Ship {
		rot = 0,
	}

	missiles: [dynamic]Missile
	defer delete(missiles)

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		if rl.IsKeyDown(.LEFT) {
			ship.rot -= SHIP_ROTATION_SPEED * dt
		} else if rl.IsKeyDown(.RIGHT) {
			ship.rot += SHIP_ROTATION_SPEED * dt
		}

		if rl.IsKeyPressed(.SPACE) {
			missile := new_missile(ship.dir)
			append(&missiles, missile)
		}

		for &missile, i in missiles {
			if missile_out_of_bounds(missile) {
				unordered_remove(&missiles, i)
			} else {
				update_missile(&missile, dt)
			}
		}

		{
			// Draw Loop 
			rl.BeginDrawing()
			defer rl.EndDrawing()

			rl.ClearBackground(rl.BLACK)

			draw_ship(&ship)

			for missile in missiles {
				draw_missile(missile)
			}

		}
	}
}
