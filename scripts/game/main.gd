extends Node2D

signal click_rejected(reason: String)

@onready var planet: Node2D = $GameWorld/Planet
@onready var crosshair: Sprite2D = $Crosshair
@onready var camera: Camera2D = $Camera2D
@onready var game_world: Node2D = $GameWorld
@onready var interceptors_container: Node2D = $GameWorld/Missiles/Interceptors
@onready var enemies_container: Node2D = $GameWorld/Missiles/Enemies
@onready var blasts_container: Node2D = $GameWorld/Blasts
@onready var effects_container: Node2D = $GameWorld/Effects


func _ready() -> void:
	click_rejected.connect(_on_click_rejected)

	# Connect silo manager signals
	planet.silo_manager.silo_destroyed.connect(_on_silo_destroyed)
	planet.silo_manager.all_silos_destroyed.connect(_on_all_silos_destroyed)

	# Start the game immediately (skip MENU for now)
	GameManager.start_game()


func _unhandled_input(event: InputEvent) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos: Vector2 = get_global_mouse_position()
		_process_click(click_pos)


func _process_click(click_pos: Vector2) -> void:
	# Step 1: Reject clicks inside planet (GDD 8.7)
	if planet.is_point_inside(click_pos):
		click_rejected.emit("inside_planet")
		return

	# Step 2: Find nearest available silo (GDD 4.2)
	var silo: Node2D = planet.silo_manager.get_nearest_available_silo(click_pos)
	if silo == null:
		click_rejected.emit("no_silo")
		return

	# Step 3: Launch interceptor
	silo.fire()
	GameManager.record_shot_fired()
	# Interceptor spawning will be added in Phase 2


func _on_click_rejected(_reason: String) -> void:
	crosshair.flash_reject()
	AudioManager.play_sfx("click_rejected")


func _on_silo_destroyed(_silo_index: int, _silo_position: Vector2) -> void:
	camera.shake(camera.silo_destroyed_shake_intensity)
	AudioManager.play_sfx("silo_destroyed")


func _on_all_silos_destroyed() -> void:
	GameManager.on_all_silos_destroyed()
