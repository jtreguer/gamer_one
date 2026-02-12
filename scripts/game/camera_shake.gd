extends Camera2D

@export var detonation_shake_intensity: float = 3.0
@export var multi_kill_shake_intensity: float = 8.0
@export var silo_destroyed_shake_intensity: float = 12.0
@export var shake_decay_rate: float = 5.0

var _current_intensity: float = 0.0


func _ready() -> void:
	# Center the camera on the viewport
	position = get_viewport_rect().size / 2.0


func _process(delta: float) -> void:
	if _current_intensity > 0.01:
		offset = Vector2(
			randf_range(-_current_intensity, _current_intensity),
			randf_range(-_current_intensity, _current_intensity)
		)
		_current_intensity = lerpf(_current_intensity, 0.0, shake_decay_rate * delta)
	else:
		offset = Vector2.ZERO
		_current_intensity = 0.0


func shake(intensity: float) -> void:
	_current_intensity = maxf(_current_intensity, intensity)
