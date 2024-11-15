package main

import "core:math"
import "core:math/linalg"
import "core:math/rand"
import rl "vendor:raylib"

CENTER :: rl.Vector2{WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2}

MISSILE_SPEED :: rl.Vector2{200, 200}
MISSILE_LENGTH :: 5
SHIP_COLLISION_RADIUS :: 10
SHIP_ROTATION_SPEED :: 5
SHIP_DESTROY_ANIMATION_LENGTH :: 2 // seconds
SHIP_INITIAL_VERTICES :: [5][2]rl.Vector2 {
	{{0, -10}, {-10, 10}},
	{{0, -10}, {10, 10}},
	{{-7, 7}, {7, 7}},
	{{-10, 10}, {-7, +7}},
	{{10, 10}, {7, 7}},
}

DESTROYED_SHIP_SPEED :: 20
DESTROYED_SHIP_INITIAL_VERTICES :: [6][2]rl.Vector2 {
	{{-2, -10}, {-8, 4}},
	{{0, -12}, {3, -9}},
	{{2, -7}, {12, -6}},
	{{10, 0}, {13, 8}},
	{{2, 2}, {6, 1}},
	{{-2, 2}, {0, 9}},
}

Ship :: struct {
	rot:   f32, // In radians 
	dir:   rl.Vector2,
	verts: [5][2]rl.Vector2,
}

create_ship :: proc() -> Ship {
	return Ship{verts = SHIP_INITIAL_VERTICES}
}

update_ship :: proc(ship: ^Ship, dt: f32) {
	if rl.IsKeyDown(.LEFT) {
		ship.rot -= SHIP_ROTATION_SPEED * dt
	} else if rl.IsKeyDown(.RIGHT) {
		ship.rot += SHIP_ROTATION_SPEED * dt
	}
}

draw_ship :: proc(ship: ^Ship) {
	// Apply Rotation to points
	for vec, i in ship.verts {
		newx := rotate(vec[0], ship.rot) + CENTER
		newy := rotate(vec[1], ship.rot) + CENTER
		rl.DrawLineV(newx, newy, rl.WHITE)

		// Calculate current direction
		if i == 2 {
			temp := newx - newy
			ship.dir = linalg.normalize(rl.Vector2{-temp.y, temp.x})
		}
	}
}

DestroyedShip :: struct {
	verts: [6][2]rl.Vector2,
}

create_destroyed_ship :: proc() -> DestroyedShip {
	return DestroyedShip{verts = DESTROYED_SHIP_INITIAL_VERTICES}
}

update_destroyed_ship :: proc(ship: ^DestroyedShip, dt: f32) {
	for &vert in ship.verts {
		center_start, center_end := vert[0] + CENTER, vert[1] + CENTER
		midpoint := rl.Vector2 {
			(center_start.x + center_end.x) / 2,
			(center_start.y + center_end.y) / 2,
		}
		dir := linalg.normalize(midpoint - CENTER)
		vel := dir * DESTROYED_SHIP_SPEED
		vert[0] += vel * dt
		vert[1] += vel * dt
	}
}

draw_destroyed_ship :: proc(ship: ^DestroyedShip, score: f32) {
	for &vec, i in ship.verts {
		rl.DrawLineV(vec[0] + CENTER, vec[1] + CENTER, rl.WHITE)
	}
}

rotate :: proc(vec: rl.Vector2, rotation: f32) -> rl.Vector2 {
	c, s := math.cos(rotation), math.sin(rotation)
	// translated_x := vec.x - center.x
	// translated_y := vec.y - center.y
	new_x := (vec.x * c) - (vec.y * s)
	new_y := (vec.x * s) + (vec.y * c)
	//return rl.Vector2{new_x + center.x, new_y + center.y}
	return rl.Vector2{new_x, new_y}
}

Missile :: struct {
	pos: rl.Vector2,
	vel: rl.Vector2,
}

new_missile :: proc(dir: rl.Vector2) -> Missile {
	return Missile{pos = CENTER, vel = dir * MISSILE_SPEED}
}

update_missile :: proc(missile: ^Missile, dt: f32) {
	missile.pos += missile.vel * dt
}

draw_missile :: proc(missile: Missile) {
	missile_start := missile.pos
	missile_end := missile.pos + linalg.normalize(missile.vel) * MISSILE_LENGTH
	rl.DrawLineV(missile_start, missile_end, rl.WHITE)
}

missile_out_of_bounds :: proc(missile: Missile) -> bool {
	if missile.pos.x < 0 || missile.pos.x > WINDOW_WIDTH {
		return true
	}

	if missile.pos.y < 0 || missile.pos.y > WINDOW_HEIGHT {
		return true
	}

	return false
}
