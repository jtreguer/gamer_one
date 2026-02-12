extends Node2D

@export var star_count: int = 80
@export var background_color: Color = Color(0.039, 0.039, 0.078)
@export var star_color: Color = Color.WHITE
@export var twinkle_count: int = 8
@export var twinkle_speed: float = 2.0

var _star_positions: PackedVector2Array = PackedVector2Array()
var _star_sizes: PackedFloat32Array = PackedFloat32Array()
var _twinkle_indices: PackedInt32Array = PackedInt32Array()
var _twinkle_phase: float = 0.0


func _ready() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	for i in star_count:
		_star_positions.append(Vector2(randf() * vp_size.x, randf() * vp_size.y))
		_star_sizes.append(randf_range(0.5, 1.5))

	# Pick some stars to twinkle
	var indices: Array[int] = []
	for i in star_count:
		indices.append(i)
	indices.shuffle()
	for i in mini(twinkle_count, star_count):
		_twinkle_indices.append(indices[i])

	queue_redraw()


func _process(delta: float) -> void:
	_twinkle_phase += twinkle_speed * delta
	queue_redraw()


func _draw() -> void:
	# Background fill
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), background_color)

	# Stars
	for i in _star_positions.size():
		var alpha: float = 0.6
		if _twinkle_indices.has(i):
			alpha = 0.3 + 0.7 * absf(sin(_twinkle_phase + float(i)))
		var color := star_color
		color.a = alpha
		draw_circle(_star_positions[i], _star_sizes[i], color)
