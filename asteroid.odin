package main

import "core:c"
import "core:fmt"
import "core:math"
import "core:math/linalg"
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
	verts: []rl.Vector2,
}

init_asteroid :: proc() -> Asteroid {
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

	verts := make_asteroid_verts(size, pos)

	ast := Asteroid {
		pos   = pos,
		vel   = vel,
		size  = size,
		verts = verts,
	}

	return ast
}

deinit_asteroids :: proc(asteroids: [dynamic]Asteroid) {
	for &asteroid in asteroids {
		deinit_asteroid(&asteroid)
	}
}

deinit_asteroid :: proc(asteroid: ^Asteroid) {
	delete(asteroid.verts)
}

// Returns a allocated slice of vertices
make_asteroid_verts :: proc(size: AsteroidSize, pos: rl.Vector2) -> []rl.Vector2 {

	min_rad, max_rad: f32
	switch size {
	case .Large:
		min_rad, max_rad = ASTEROID_LARGE_MIN_RAD, ASTEROID_LARGE_MAX_RAD
	case .Medium:
		min_rad, max_rad = ASTEROID_MEDIUM_MIN_RAD, ASTEROID_MEDIUM_MAX_RAD
	case .Small:
		min_rad, max_rad = ASTEROID_SMALL_MIN_RAD, ASTEROID_SMALL_MAX_RAD
	}

	verts := make([]rl.Vector2, ASTEROID_EDGES + 1)

	for &vert, i in verts {
		if i == len(verts) - 1 {
			vert = verts[0]
		} else {
			rads := f32(i) * (360 / ASTEROID_EDGES) * (math.PI / 180)
			scalar := rand.float32_range(min_rad, max_rad)
			vert = pos + rl.Vector2{math.cos(rads), math.sin(rads)} * scalar
		}
	}

	return verts
}

// Splits one asteroid into two at a smaller size. Each asteroid has allocated memory 
// and needs to be deallocated. Asteroid passed in also need deallocating. 
split_asteroid :: proc(asteroid: Asteroid) -> (a: Asteroid, b: Asteroid) {
	switch asteroid.size {

	case .Large:
		a.size = .Medium
		a.pos = asteroid.pos
		a.vel = vel_at_45_degrees(asteroid.vel, true)
		a.verts = make_asteroid_verts(a.size, asteroid.pos)

		b.size = .Medium
		b.pos = asteroid.pos
		b.vel = vel_at_45_degrees(asteroid.vel, false)
		b.verts = make_asteroid_verts(b.size, asteroid.pos)
	case .Medium:
		a.size = .Small
		a.pos = asteroid.pos
		a.vel = vel_at_45_degrees(asteroid.vel, true)
		a.verts = make_asteroid_verts(a.size, asteroid.pos)

		b.size = .Small
		b.pos = asteroid.pos
		b.vel = vel_at_45_degrees(asteroid.vel, false)
		b.verts = make_asteroid_verts(b.size, asteroid.pos)
	case .Small:
		a.size = .Small
		a.pos = asteroid.pos
		a.vel = vel_at_45_degrees(asteroid.vel, true)
		a.verts = make_asteroid_verts(a.size, asteroid.pos)

		b.size = .Small
		b.pos = asteroid.pos
		b.vel = vel_at_45_degrees(asteroid.vel, false)
		b.verts = make_asteroid_verts(b.size, asteroid.pos)
	}

	return a, b
}

vel_at_45_degrees :: proc(vel: rl.Vector2, clockwise: bool) -> (nvel: rl.Vector2) {
	angle: f32 = math.PI / 4.0
	angle = clockwise ? -angle : angle
	c, s := math.cos(angle), math.sin(angle)
	nvel.x = vel.x * c - vel.y * s
	nvel.y = vel.x * s + vel.y * c
	return
}

draw_asteroid :: proc(asteroid: ^Asteroid) {
	rl.DrawLineStrip(raw_data(asteroid.verts), i32(len(asteroid.verts)), rl.WHITE)
}

update_asteroid :: proc(asteroid: ^Asteroid, dt: f32) {
	for &vert in asteroid.verts {
		vert += asteroid.vel * dt
	}
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

asteroid_collides_with_missile :: proc(asteroid: Asteroid, missile: Missile) -> bool {
	switch asteroid.size {
	case .Large:
		return linalg.distance(asteroid.pos, missile.pos) < ASTEROID_LARGE_MAX_RAD
	case .Medium:
		return linalg.distance(asteroid.pos, missile.pos) < ASTEROID_MEDIUM_MAX_RAD
	case .Small:
		return linalg.distance(asteroid.pos, missile.pos) < ASTEROID_SMALL_MAX_RAD
	case:
		return false
	}
}

asteroid_collides_with_ship :: proc(asteroid: Asteroid) -> bool {
	dir := linalg.normalize(CENTER - asteroid.pos)
	scaled: rl.Vector2
	switch asteroid.size {
	case .Large:
		scaled = dir * ASTEROID_LARGE_MAX_RAD
	case .Medium:
		scaled = dir * ASTEROID_MEDIUM_MAX_RAD
	case .Small:
		scaled = dir * ASTEROID_SMALL_MAX_RAD
	}

	positioned := asteroid.pos + scaled
	dist := linalg.distance(positioned, CENTER)
	return dist < SHIP_COLLISION_RADIUS

}
