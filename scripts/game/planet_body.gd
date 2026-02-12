extends Node2D

func _draw() -> void:
	var planet: Node2D = get_parent()
	var radius: float = planet.planet_radius
	var rot: float = planet.current_rotation

	# Planet disk
	draw_circle(Vector2.ZERO, radius, Color(0.102, 0.290, 0.353))

	# Surface detail: rotating arcs to convey spin
	for i in range(3):
		var arc_angle: float = rot + i * (TAU / 3.0)
		draw_arc(Vector2.ZERO, radius * (0.4 + i * 0.2), arc_angle, arc_angle + PI, 16, Color(0.15, 0.4, 0.5, 0.3), 1.0)

	# Atmosphere ring
	var atmo_color := Color(0.227, 0.941, 0.910, 0.15)
	draw_arc(Vector2.ZERO, radius + 4, 0, TAU, 64, atmo_color, 3.0)
