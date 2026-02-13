extends Node2D

signal detonated(pos: Vector2)

var target: Vector2 = Vector2.ZERO
var speed: float = 400.0
var _direction: Vector2 = Vector2.ZERO
var _arrived: bool = false
var _trail_timer: float = 0.0

@onready var trail: Line2D = $Trail
@onready var head: Node2D = $Head

const TRAIL_POINT_CAP := 200
const ARRIVAL_THRESHOLD := 5.0
const TRAIL_INTERVAL: float = 0.03  # Slightly faster than enemies since interceptors move quicker


func setup(from: Vector2, to: Vector2, interceptor_speed: float) -> void:
	global_position = from
	target = to
	speed = interceptor_speed
	_direction = from.direction_to(to)
	# Configure trail — top_level so it stays in world space
	trail.top_level = true
	trail.global_position = Vector2.ZERO
	trail.clear_points()
	trail.width = 2.0
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.251, 0.816, 1.0, 0.0))
	gradient.set_color(1, Color(0.251, 0.816, 1.0, 1.0))
	trail.gradient = gradient


func _process(delta: float) -> void:
	if _arrived:
		return

	# Move toward target
	var step: float = speed * delta
	var dist: float = global_position.distance_to(target)

	if dist <= step + ARRIVAL_THRESHOLD:
		global_position = target
		_arrive()
		return

	global_position += _direction * step

	# Add trail point (time-based for frame-rate independence)
	_trail_timer += delta
	if _trail_timer >= TRAIL_INTERVAL:
		_trail_timer -= TRAIL_INTERVAL
		trail.add_point(trail.to_local(global_position))
		if trail.get_point_count() > TRAIL_POINT_CAP:
			trail.remove_point(0)


func _arrive() -> void:
	_arrived = true
	head.visible = false
	detonated.emit(global_position)
	# Start trail fade then free
	var tween := create_tween()
	tween.tween_property(trail, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)
