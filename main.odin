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

	asteroids: [dynamic]Asteroid
	defer delete(asteroids)


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
			asteroid := create_asteroid()
			append(&asteroids, asteroid)
		}

		for &missile, i in missiles {
			if missile_out_of_bounds(missile) {
				unordered_remove(&missiles, i)
			} else {
				update_missile(&missile, dt)
			}
		}

		for &asteroid, i in asteroids {
			if asteroid_out_of_bounds(asteroid) {
				unordered_remove(&asteroids, i)
				fmt.printf("removed asteroid at index: %d\n", i)
			} else {
				update_asteroid(&asteroid, dt)
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

			for &asteroid in asteroids {
				draw_asteroid(&asteroid)
			}
		}
	}
}
