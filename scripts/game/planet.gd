extends Node2D

@export var planet_radius: float = 80.0
@export var rotation_speed: float = 0.15

var current_rotation: float = 0.0

@onready var planet_body: Node2D = $PlanetBody
@onready var silo_manager: Node2D = $Silos


func _process(delta: float) -> void:
	current_rotation += rotation_speed * delta
	if current_rotation > TAU:
		current_rotation -= TAU
	planet_body.queue_redraw()


func is_point_inside(point: Vector2) -> bool:
	return global_position.distance_to(point) < planet_radius
