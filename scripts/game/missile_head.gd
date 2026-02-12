extends Node2D

@export var head_color: Color = Color(1.0, 1.0, 1.0)
@export var head_radius: float = 3.0


func _draw() -> void:
	draw_circle(Vector2.ZERO, head_radius, head_color)
