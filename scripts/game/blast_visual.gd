extends Node2D

@onready var _blast: Node2D = get_parent()


func _draw() -> void:
	var radius: float = _blast.current_radius
	var alpha: float = _blast.current_alpha

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
