extends Control

@onready var score_label: Label = $ScoreLabel
@onready var high_score_label: Label = $HighScoreLabel
@onready var wave_label: Label = $WaveLabel
@onready var silo_label: Label = $SiloLabel
@onready var warning_vignette: ColorRect = $WarningVignette

var _vignette_active: bool = false
var _vignette_phase: float = 0.0
const VIGNETTE_PULSE_SPEED := 3.0
const VIGNETTE_WARN_THRESHOLD := 2


func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.game_state_changed.connect(_on_game_state_changed)

	warning_vignette.visible = false
	warning_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_on_score_changed(GameManager.score)
	_update_high_score()
	_update_silo_count(GameManager.active_silo_count)


func _process(delta: float) -> void:
	if _vignette_active and warning_vignette.visible:
		_vignette_phase += VIGNETTE_PULSE_SPEED * delta
		var alpha: float = 0.08 + 0.07 * sin(_vignette_phase)
		warning_vignette.color = Color(1.0, 0.0, 0.0, alpha)


func connect_silo_manager(silo_manager: Node2D) -> void:
	silo_manager.silo_count_changed.connect(_update_silo_count)


func _on_score_changed(new_score: int) -> void:
	score_label.text = "SCORE: " + str(new_score)
	_update_high_score()


func _update_high_score() -> void:
	high_score_label.text = "HI: " + str(GameManager.high_score)


func _on_wave_started(wave_number: int) -> void:
	wave_label.text = "WAVE " + str(wave_number)


func _update_silo_count(active_count: int) -> void:
	silo_label.text = "SILOS: " + str(active_count)
	if active_count <= VIGNETTE_WARN_THRESHOLD and active_count > 0:
		_vignette_active = true
		warning_vignette.visible = true
	else:
		_vignette_active = false
		warning_vignette.visible = false


func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	visible = (new_state == GameManager.GameState.PLAYING or new_state == GameManager.GameState.WAVE_TRANSITION)
