extends Control

@onready var final_score_label: Label = $Overlay/Center/VBox/FinalScoreLabel
@onready var waves_label: Label = $Overlay/Center/VBox/StatsBox/WavesLabel
@onready var destroyed_label: Label = $Overlay/Center/VBox/StatsBox/DestroyedLabel
@onready var accuracy_label: Label = $Overlay/Center/VBox/StatsBox/AccuracyLabel
@onready var restart_button: Button = $Overlay/Center/VBox/RestartButton


func _ready() -> void:
	GameManager.game_state_changed.connect(_on_game_state_changed)
	restart_button.pressed.connect(_on_restart_pressed)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	if new_state == GameManager.GameState.GAME_OVER:
		_show_stats()
		visible = true
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		visible = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE


func _show_stats() -> void:
	final_score_label.text = str(GameManager.score)
	waves_label.text = "Waves Survived: " + str(GameManager.current_wave)
	destroyed_label.text = "Enemies Destroyed: " + str(GameManager.total_enemies_destroyed)

	var accuracy: float = GameManager.get_overall_accuracy()
	accuracy_label.text = "Accuracy: " + str(roundi(accuracy * 100.0)) + "%"


func _on_restart_pressed() -> void:
	GameManager.restart_game()
