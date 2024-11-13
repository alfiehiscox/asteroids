package main

import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

ASTEROID_EDGES :: 10
ASTEROID_MIN_SPEED :: 80
ASTEROID_MAX_SPEED :: 200
ASTEROID_LARGE_MIN_RAD :: 20
ASTEROID_LARGE_MAX_RAD :: 30
ASTEROID_MEDIUM_MIN_RAD :: 10
ASTEROID_MEDIUM_MAX_RAD :: 20
ASTEROID_SMALL_MIN_RAD :: 2
ASTEROID_SMALL_MAX_RAD :: 10

AsteroidSize :: enum {
	Small,
	Medium,
	Large,
}

AsteroidDir :: enum {
	North,
	East,
	South,
	West,
}

Asteroid :: struct {
	pos:   rl.Vector2,
	vel:   rl.Vector2,
	size:  AsteroidSize,
	verts: [ASTEROID_EDGES + 1]rl.Vector2,
}

create_asteroid :: proc() -> Asteroid {
	size := rand.choice_enum(AsteroidSize)

	pos, vel: rl.Vector2
	origin := rand.choice_enum(AsteroidDir)
	switch origin {
	case .North:
		pos.x = rand.float32_range(0, WINDOW_WIDTH)
		pos.y = -ASTEROID_LARGE_MAX_RAD
		vel.y = rand.float32_range(ASTEROID_MIN_SPEED, ASTEROID_MAX_SPEED)
		vel.x = rand.float32_range(-90, 90)
	case .South:
		pos.x = rand.float32_range(0, WINDOW_WIDTH)
		pos.y = WINDOW_HEIGHT + ASTEROID_LARGE_MAX_RAD
		vel.y = -rand.float32_range(ASTEROID_MIN_SPEED, ASTEROID_MAX_SPEED)
		vel.x = rand.float32_range(-90, 90)
	case .West:
		pos.y = rand.float32_range(0, WINDOW_HEIGHT)
		pos.x = -ASTEROID_LARGE_MAX_RAD
		vel.x = rand.float32_range(ASTEROID_MIN_SPEED, ASTEROID_MAX_SPEED)
		vel.y = rand.float32_range(-90, 90)
	case .East:
		pos.y = rand.float32_range(0, WINDOW_HEIGHT)
		pos.x = WINDOW_WIDTH + ASTEROID_LARGE_MAX_RAD
		vel.x = -rand.float32_range(ASTEROID_MIN_SPEED, ASTEROID_MAX_SPEED)
		vel.y = rand.float32_range(-90, 90)
	}

	ast := Asteroid {
		pos  = pos,
		vel  = vel,
		size = size,
	}

	min_rad, max_rad: f32
	switch size {
	case .Large:
		min_rad, max_rad = ASTEROID_LARGE_MIN_RAD, ASTEROID_LARGE_MAX_RAD
	case .Medium:
		min_rad, max_rad = ASTEROID_MEDIUM_MIN_RAD, ASTEROID_MEDIUM_MAX_RAD
	case .Small:
		min_rad, max_rad = ASTEROID_SMALL_MIN_RAD, ASTEROID_SMALL_MAX_RAD
	}

	verts: [ASTEROID_EDGES + 1]rl.Vector2
	for _, i in verts {
		if i == len(verts) - 1 {
			verts[i] = verts[0]
		} else {
			rads := f32(i) * (360 / ASTEROID_EDGES) * (math.PI / 180)
			scalar := rand.float32_range(min_rad, max_rad)
			verts[i] = rl.Vector2{math.cos(rads), math.sin(rads)} * scalar
		}
	}

	ast.verts = verts

	return ast
}

draw_asteroid :: proc(asteroid: ^Asteroid) {
	points: [len(asteroid.verts)]rl.Vector2
	for vert, i in asteroid.verts {
		points[i] = asteroid.pos + vert
	}
	rl.DrawLineStrip(raw_data(points[:]), len(points), rl.WHITE)
}

update_asteroid :: proc(asteroid: ^Asteroid, dt: f32) {
	asteroid.pos += asteroid.vel * dt
}

asteroid_out_of_bounds :: proc(asteroid: Asteroid) -> bool {
	if asteroid.pos.x + ASTEROID_LARGE_MAX_RAD < 0 ||
	   asteroid.pos.x - ASTEROID_LARGE_MAX_RAD > WINDOW_WIDTH {
		return true
	}

	if asteroid.pos.y + ASTEROID_LARGE_MAX_RAD < 0 ||
	   asteroid.pos.y - ASTEROID_LARGE_MAX_RAD > WINDOW_HEIGHT {
		return true
	}

	return false
}
