extends Node2D


func _draw() -> void:
	var blast: Node2D = get_parent()
	var radius: float = blast.current_radius
	var alpha: float = blast.current_alpha

	if radius <= 0.0:
		return

	# Outer glow ring
	var glow_color := Color(0.251, 0.816, 1.0, alpha * 0.15)
	draw_circle(Vector2.ZERO, radius * 1.3, glow_color)

	# Edge ring (blue)
	var edge_color := Color(0.251, 0.816, 1.0, alpha * 0.5)
	draw_circle(Vector2.ZERO, radius, edge_color)

	# Core circle (white)
	var core_color := Color(1.0, 1.0, 1.0, alpha * 0.8)
	draw_circle(Vector2.ZERO, radius * 0.6, core_color)
