extends Node2D

const SILO_SIZE := 8.0

func _draw() -> void:
	var silo: Node2D = get_parent()
	var color: Color

	match silo.state:
		silo.SiloState.READY:
			color = ColorPalette.SILO_READY
		silo.SiloState.RELOADING:
			color = ColorPalette.SILO_RELOADING
		silo.SiloState.DESTROYED:
			color = ColorPalette.SILO_DESTROYED

	if silo.state == silo.SiloState.DESTROYED:
		# Draw a small crater
		draw_circle(Vector2.ZERO, SILO_SIZE * 0.6, color)
	else:
		# Draw a triangle pointing radially outward
		var dir := Vector2.UP.rotated(silo.rotation)
		var perp := dir.rotated(PI / 2.0)
		var tip := dir * SILO_SIZE
		var base_l := -dir * SILO_SIZE * 0.4 + perp * SILO_SIZE * 0.5
		var base_r := -dir * SILO_SIZE * 0.4 - perp * SILO_SIZE * 0.5
		draw_colored_polygon(PackedVector2Array([tip, base_l, base_r]), color)
