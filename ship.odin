package main

import "core:math"
import rl "vendor:raylib"

CENTER :: rl.Vector2{WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2}

Ship :: struct {
	rot: f32, // In radians 
}

draw_ship :: proc(ship: Ship) {
	points := [4][2]rl.Vector2 {
		{{CENTER.x - 20, CENTER.y - 20}, {CENTER.x - 20, CENTER.y + 20}},
		{{CENTER.x - 20, CENTER.y + 20}, {CENTER.x + 20, CENTER.y + 20}},
		{{CENTER.x + 20, CENTER.y + 20}, {CENTER.x + 20, CENTER.y - 20}},
		{{CENTER.x + 20, CENTER.y - 20}, {CENTER.x - 20, CENTER.y - 20}},
	}

	// Apply Rotation
	for vec, i in points {
		newx := rotate(vec[0], CENTER, ship.rot)
		newy := rotate(vec[1], CENTER, ship.rot)
		rl.DrawLineV(newx, newy, rl.WHITE)
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
