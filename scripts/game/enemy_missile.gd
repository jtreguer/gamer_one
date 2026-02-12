extends Node2D

signal enemy_destroyed(pos: Vector2, is_warhead: bool, is_mirv_presplit: bool)
signal enemy_impacted(impact_position: Vector2)

@export var speed: float = 100.0
@export var trail_color: Color = Color(1.0, 0.251, 0.251)
@export var trail_width: float = 2.5
@export var head_color: Color = Color(1.0, 0.251, 0.251)
@export var head_radius: float = 4.0
@export var is_warhead: bool = false
@export var trail_lifetime: float = 2.0

var target: Vector2 = Vector2.ZERO
var planet_center: Vector2 = Vector2.ZERO
var planet_radius: float = 80.0
var _direction: Vector2 = Vector2.ZERO
var _is_alive: bool = true
var _frame_count: int = 0

@onready var trail: Line2D = $Trail
@onready var head: Node2D = $Head

const TRAIL_POINT_CAP := 100


func setup(from: Vector2, to: Vector2, missile_speed: float, p_center: Vector2, p_radius: float) -> void:
	global_position = from
	target = to
	speed = missile_speed
	planet_center = p_center
	planet_radius = p_radius
	_direction = from.direction_to(to)
	# Configure trail — top_level so it stays in world space
	$Trail.top_level = true
	$Trail.global_position = Vector2.ZERO
	$Trail.clear_points()
	$Trail.width = trail_width
	var gradient := Gradient.new()
	gradient.set_color(0, Color(trail_color.r, trail_color.g, trail_color.b, 0.0))
	gradient.set_color(1, Color(trail_color.r, trail_color.g, trail_color.b, 1.0))
	$Trail.gradient = gradient
	# Configure head
	$Head.head_color = head_color
	$Head.head_radius = head_radius
	$Head.queue_redraw()


func _process(delta: float) -> void:
	if not _is_alive:
		return

	# Move toward target
	global_position += _direction * speed * delta

	# Add trail point (every other frame for performance)
	_frame_count += 1
	if _frame_count % 2 == 0:
		trail.add_point(trail.to_local(global_position))
		if trail.get_point_count() > TRAIL_POINT_CAP:
			trail.remove_point(0)

	# Check if reached planet circumference
	var dist_to_center: float = global_position.distance_to(planet_center)
	if dist_to_center <= planet_radius:
		_impact()


func is_alive() -> bool:
	return _is_alive


func destroy() -> void:
	if not _is_alive:
		return
	_is_alive = false
	head.visible = false
	enemy_destroyed.emit(global_position, is_warhead, false)
	# Fade trail then free
	var tween := create_tween()
	tween.tween_property(trail, "modulate:a", 0.0, trail_lifetime)
	tween.tween_callback(queue_free)


func _impact() -> void:
	if not _is_alive:
		return
	_is_alive = false
	head.visible = false
	enemy_impacted.emit(global_position)
	# Fade trail then free
	var tween := create_tween()
	tween.tween_property(trail, "modulate:a", 0.0, trail_lifetime)
	tween.tween_callback(queue_free)
