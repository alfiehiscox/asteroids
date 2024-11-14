package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:mem"
import rl "vendor:raylib"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 800

SHIP_ROTATION_SPEED :: 5

main :: proc() {
	// Tracking Allocator
	default := context.allocator
	tracking: mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracking, default)
	context.allocator = mem.tracking_allocator(&tracking)
	defer check_leaks(&tracking)

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Asteroids")
	defer rl.CloseWindow()
	rl.SetTargetFPS(120)

	ship := Ship {
		rot = 0,
	}

	missiles: [dynamic]Missile
	defer delete(missiles)

	asteroids: [dynamic]Asteroid
	defer deinit_asteroids(asteroids[:])
	defer delete(asteroids)

	end := false

	for !rl.WindowShouldClose() && !end {
		dt := rl.GetFrameTime()

		if rl.IsKeyDown(.LEFT) {
			ship.rot -= SHIP_ROTATION_SPEED * dt
		} else if rl.IsKeyDown(.RIGHT) {
			ship.rot += SHIP_ROTATION_SPEED * dt
		}

		if rl.IsKeyPressed(.SPACE) {
			missile := new_missile(ship.dir)
			append(&missiles, missile)
			asteroid := init_asteroid()
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
				deinit_asteroid(&asteroid)
				unordered_remove(&asteroids, i)
			} else if asteroid_collides_with_ship(asteroid) {
				fmt.println("You Lost!")
				end = true
			} else {
				collision := false
				for missile, j in missiles {
					asteroid_collides_with_missile(asteroid, missile) or_continue

					if asteroid.size != .Small {
						a, b := split_asteroid(asteroid)
						append(&asteroids, a, b)
					}

					deinit_asteroid(&asteroid)
					unordered_remove(&asteroids, i)
					unordered_remove(&missiles, j)
					collision = true
					break
				}

				// Only update if the asteroid hasn't had a collision
				if !collision {
					update_asteroid(&asteroid, dt)
				}
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

check_leaks :: proc(tracking: ^mem.Tracking_Allocator) {
	fmt.printf(">>>>>>>>> Tracking >>>>>>>>>>>\n")

	if len(tracking.allocation_map) > 0 {
		for _, value in tracking.allocation_map {
			fmt.printf("Leaked Bytes: %v [%v]\n", value.size, value.location)
		}
	} else {
		fmt.println("Leaked Bytes: 0")
	}

	if len(tracking.bad_free_array) > 0 {
		for value in tracking.bad_free_array {
			fmt.printf("Bad Free at %v Bytes\n", value.location)
		}
	} else {
		fmt.println("Bad Frees   : 0")
	}
}
