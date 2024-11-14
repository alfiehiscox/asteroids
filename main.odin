package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:mem"
import "core:strings"
import rl "vendor:raylib"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 800

GameState :: enum {
	GamePlaying,
	GameOverAnimation,
}

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

	ship := create_ship()
	destroyed_ship: DestroyedShip

	missiles: [dynamic]Missile
	defer delete(missiles)

	asteroids: [dynamic]Asteroid
	defer deinit_asteroids(asteroids)
	defer delete(asteroids)

	game_state := GameState.GamePlaying
	end := false

	score: f32 = 0

	game_over_animation_timer: f32 = 0

	for !rl.WindowShouldClose() && !end {
		dt := rl.GetFrameTime()

		switch game_state {
		case .GamePlaying:
			game_state = game_playing_update(&ship, &missiles, &asteroids, &score, dt)
			if game_state == .GameOverAnimation {
				game_over_animation_timer = SHIP_DESTROY_ANIMATION_LENGTH
				destroyed_ship = create_destroyed_ship()
			}
		case .GameOverAnimation:
			game_state, game_over_animation_timer = game_over_animation_update(
				&destroyed_ship,
				game_over_animation_timer,
				dt,
			)
			if game_state == .GamePlaying {
				clear(&missiles)
				deinit_asteroids(asteroids)
				clear(&asteroids)
				ship = create_ship()
			}
		}

		{
			// Draw Loop 
			rl.BeginDrawing()
			defer rl.EndDrawing()

			rl.ClearBackground(rl.BLACK)

			switch game_state {
			case .GamePlaying:
				draw_ship(&ship)
			case .GameOverAnimation:
				draw_destroyed_ship(&destroyed_ship, score)
			}

			draw_score(score)

			for missile in missiles {
				draw_missile(missile)
			}

			for &asteroid in asteroids {
				draw_asteroid(&asteroid)
			}
		}
	}
}

game_playing_update :: proc(
	ship: ^Ship,
	missiles: ^[dynamic]Missile,
	asteroids: ^[dynamic]Asteroid,
	score: ^f32,
	dt: f32,
) -> GameState {

	update_ship(ship, dt)

	if rl.IsKeyPressed(.SPACE) {
		missile := new_missile(ship.dir)
		append(missiles, missile)
		asteroid := init_asteroid()
		append(asteroids, asteroid)
	}

	for &missile, i in missiles {
		if missile_out_of_bounds(missile) {
			unordered_remove(missiles, i)
		} else {
			update_missile(&missile, dt)
		}
	}

	for &asteroid, i in asteroids {
		if asteroid_out_of_bounds(asteroid) {
			deinit_asteroid(&asteroid)
			unordered_remove(asteroids, i)
		} else if asteroid_collides_with_ship(asteroid) {
			return .GameOverAnimation
		} else {
			collision := false
			for missile, j in missiles {
				asteroid_collides_with_missile(asteroid, missile) or_continue

				score^ += ASTEROID_SCORE

				if asteroid.size != .Small {
					a, b := split_asteroid(asteroid)
					append(asteroids, a, b)
				}

				deinit_asteroid(&asteroid)
				unordered_remove(asteroids, i)
				unordered_remove(missiles, j)
				collision = true
				break
			}

			// Only update if the asteroid hasn't had a collision
			if !collision {
				update_asteroid(&asteroid, dt)
			}
		}
	}

	return .GamePlaying
}


game_over_animation_update :: proc(
	ship: ^DestroyedShip,
	current_timer: f32,
	dt: f32,
) -> (
	new_state: GameState,
	new_timer: f32,
) {

	update_destroyed_ship(ship, dt)

	// Do state machine things
	new_timer = current_timer - dt
	if new_timer <= 0 {
		new_state = .GamePlaying
	} else {
		new_state = .GameOverAnimation
	}

	return new_state, new_timer
}

draw_score :: proc(score: f32) {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	fmt.sbprintf(&sb, "Score %f", score)
	str := strings.clone_to_cstring(strings.to_string(sb))
	defer delete(str)
	rl.DrawText(str, 20, 20, 10, rl.WHITE)
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
