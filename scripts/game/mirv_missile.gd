extends Node2D

signal mirv_split(pos: Vector2, warhead_targets: Array[Vector2])
signal enemy_destroyed(pos: Vector2, is_warhead: bool, is_mirv_presplit: bool)

@export var speed: float = 100.0
@export var trail_color: Color = Color(1.0, 0.667, 0.125)
@export var trail_width: float = 3.0
@export var head_color: Color = Color(1.0, 0.667, 0.125)
@export var head_radius: float = 5.0
@export var trail_lifetime: float = 2.0

var target: Vector2 = Vector2.ZERO
var planet_center: Vector2 = Vector2.ZERO
var planet_radius: float = 80.0
var split_distance: float = 200.0
var warhead_count: int = 2
var _direction: Vector2 = Vector2.ZERO
var _is_alive: bool = true
var _has_split: bool = false
var _frame_count: int = 0
var _pulse_phase: float = 0.0

@onready var trail: Line2D = $Trail
@onready var head: Node2D = $Head

const TRAIL_POINT_CAP := 300
const PULSE_SPEED := 4.0


func setup(
	from: Vector2, to: Vector2, missile_speed: float,
	p_center: Vector2, p_radius: float,
	split_dist: float, num_warheads: int
) -> void:
	global_position = from
	target = to
	speed = missile_speed
	planet_center = p_center
	planet_radius = p_radius
	split_distance = split_dist
	warhead_count = num_warheads
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
	# Configure head (larger, pulsing)
	$Head.head_color = head_color
	$Head.head_radius = head_radius
	$Head.queue_redraw()


func _process(delta: float) -> void:
	if not _is_alive:
		return

	# Pulsing glow effect
	_pulse_phase += PULSE_SPEED * delta
	var pulse_scale: float = 1.0 + 0.3 * sin(_pulse_phase)
	$Head.head_radius = head_radius * pulse_scale
	$Head.queue_redraw()

	# Move toward target
	global_position += _direction * speed * delta

	# Add trail point
	trail.add_point(trail.to_local(global_position))
	if trail.get_point_count() > TRAIL_POINT_CAP:
		trail.remove_point(0)

	# Check if close enough to planet to split
	var dist_to_center: float = global_position.distance_to(planet_center)
	if not _has_split and dist_to_center <= split_distance:
		_split()


func is_alive() -> bool:
	return _is_alive


func destroy() -> void:
	if not _is_alive:
		return
	_is_alive = false
	$Head.visible = false
	# Pre-split kill — bonus points
	enemy_destroyed.emit(global_position, false, true)
	# Fade trail then free
	var tween := create_tween()
	tween.tween_property(trail, "modulate:a", 0.0, trail_lifetime)
	tween.tween_callback(queue_free)


func _split() -> void:
	_has_split = true
	_is_alive = false
	$Head.visible = false

	# Generate spread warhead targets on the circumference
	var targets: Array[Vector2] = _generate_warhead_targets()
	mirv_split.emit(global_position, targets)

	# Fade trail then free
	var tween := create_tween()
	tween.tween_property(trail, "modulate:a", 0.0, trail_lifetime)
	tween.tween_callback(queue_free)


func _generate_warhead_targets() -> Array[Vector2]:
	var targets: Array[Vector2] = []
	var min_spread: float = GameManager.config.mirv_warhead_spread

	# Start from a random base angle
	var base_angle: float = randf() * TAU

	for i in warhead_count:
		var angle: float = base_angle + i * min_spread
		angle += randf_range(-0.1, 0.1)
		var t: Vector2 = planet_center + Vector2(cos(angle), sin(angle)) * planet_radius
		targets.append(t)

	return targets
