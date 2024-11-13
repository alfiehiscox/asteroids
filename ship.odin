package main

import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

MISSILE_SPEED :: rl.Vector2{100, 100}
MISSILE_LENGTH :: 10
CENTER :: rl.Vector2{WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2}
POINTS :: [5][2]rl.Vector2 {
	{{CENTER.x, CENTER.y - 10}, {CENTER.x - 10, CENTER.y + 10}},
	{{CENTER.x, CENTER.y - 10}, {CENTER.x + 10, CENTER.y + 10}},
	{{CENTER.x - 7, CENTER.y + 7}, {CENTER.x + 7, CENTER.y + 7}},
	{{CENTER.x - 10, CENTER.y + 10}, {CENTER.x - 7, CENTER.y + 7}},
	{{CENTER.x + 10, CENTER.y + 10}, {CENTER.x + 7, CENTER.y + 7}},
}

Ship :: struct {
	rot: f32, // In radians 
	dir: rl.Vector2,
}

draw_ship :: proc(ship: ^Ship) {
	// Apply Rotation to points
	for vec, i in POINTS {
		newx := rotate(vec[0], CENTER, ship.rot)
		newy := rotate(vec[1], CENTER, ship.rot)
		rl.DrawLineV(newx, newy, rl.WHITE)

		// Calculate current direction
		if i == 2 {
			temp := newx - newy
			ship.dir = linalg.normalize(rl.Vector2{-temp.y, temp.x})
		}
	}
}

rotate :: proc(vec: rl.Vector2, center: rl.Vector2, rotation: f32) -> rl.Vector2 {
	c, s := math.cos(rotation), math.sin(rotation)
	translated_x := vec.x - center.x
	translated_y := vec.y - center.y
	new_x := (translated_x * c) - (translated_y * s)
	new_y := (translated_x * s) + (translated_y * c)
	return rl.Vector2{new_x + center.x, new_y + center.y}
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
