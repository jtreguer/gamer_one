extends Node2D

func _draw() -> void:
	var planet: Node2D = get_parent()
	var radius: float = planet.planet_radius
	var rot: float = planet.current_rotation

	# Planet disk
	draw_circle(Vector2.ZERO, radius, ColorPalette.PLANET_BODY)

	# Surface detail: rotating arcs to convey spin
	for i in range(3):
		var arc_angle: float = rot + i * (TAU / 3.0)
		var arc_color := Color(0.15, 0.4, 0.5, 0.3)
		draw_arc(Vector2.ZERO, radius * (0.4 + i * 0.2), arc_angle, arc_angle + PI, 16, arc_color, 1.0)

	# Atmosphere ring
	var atmo_color := ColorPalette.PLANET_ATMOSPHERE
	atmo_color.a = 0.15
	draw_arc(Vector2.ZERO, radius + 4, 0, TAU, 64, atmo_color, 3.0)
