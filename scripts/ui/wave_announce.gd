extends Control

@onready var wave_text: Label = $WaveText

var _tween: Tween = null


func _ready() -> void:
	GameManager.wave_started.connect(_on_wave_started)
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_wave_started(wave_number: int) -> void:
	announce(wave_number)


func announce(wave_number: int) -> void:
	wave_text.text = "WAVE " + str(wave_number)

	if _tween and _tween.is_valid():
		_tween.kill()

	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.3)
	_tween.tween_interval(0.8)
	_tween.tween_property(self, "modulate:a", 0.0, 0.4)
