extends Node2D

const SILO_SIZE := 8.0

@onready var _silo: Node2D = get_parent()

func _draw() -> void:
	var color: Color

	match _silo.state:
		_silo.SiloState.READY:
			color = Color(0.251, 1.0, 0.251)
		_silo.SiloState.RELOADING:
			color = Color(0.165, 0.400, 0.188)
		_silo.SiloState.DESTROYED:
			color = Color(0.290, 0.102, 0.039)

	if _silo.state == _silo.SiloState.DESTROYED:
		# Draw a small crater
		draw_circle(Vector2.ZERO, SILO_SIZE * 0.6, color)
	else:
		# Draw a triangle pointing radially outward
		var dir := Vector2.UP.rotated(_silo.rotation)
		var perp := dir.rotated(PI / 2.0)
		var tip := dir * SILO_SIZE
		var base_l := -dir * SILO_SIZE * 0.4 + perp * SILO_SIZE * 0.5
		var base_r := -dir * SILO_SIZE * 0.4 - perp * SILO_SIZE * 0.5
		draw_colored_polygon(PackedVector2Array([tip, base_l, base_r]), color)
