extends Node2D

signal click_rejected(reason: String)
signal multi_kill(count: int, pos: Vector2)

@onready var planet: Node2D = $GameWorld/Planet
@onready var crosshair: Sprite2D = $Crosshair
@onready var camera: Camera2D = $Camera2D
@onready var game_world: Node2D = $GameWorld
@onready var interceptors_container: Node2D = $GameWorld/Missiles/Interceptors
@onready var enemies_container: Node2D = $GameWorld/Missiles/Enemies
@onready var blasts_container: Node2D = $GameWorld/Blasts
@onready var effects_container: Node2D = $GameWorld/Effects
@onready var hud: Control = $UILayer/HUD

const InterceptorScene := preload("res://scenes/game/interceptor.tscn")
const EnemyMissileScene := preload("res://scenes/game/enemy_missile.tscn")
const MIRVMissileScene := preload("res://scenes/game/mirv_missile.tscn")
const BlastScene := preload("res://scenes/game/blast.tscn")

# Wave spawning state
var _spawning_active: bool = false
var _burst_index: int = 0
var _missiles_spawned_in_burst: int = 0
var _missiles_per_burst: int = 0
var _total_spawned: int = 0
var _burst_timer: float = 0.0
var _spawn_timer: float = 0.0
var _wave_start_timer: float = 0.0
var _waiting_wave_start: bool = false


func _ready() -> void:
	click_rejected.connect(_on_click_rejected)
	multi_kill.connect(_on_multi_kill)

	# Connect silo manager signals
	planet.silo_manager.silo_destroyed.connect(_on_silo_destroyed)
	planet.silo_manager.all_silos_destroyed.connect(_on_all_silos_destroyed)

	# Connect GameManager signals
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.silo_repair_requested.connect(_on_silo_repair_requested)
	GameManager.game_restarted.connect(_on_game_restarted)

	# Connect HUD to silo manager
	hud.connect_silo_manager(planet.silo_manager)

	# Start the game immediately (skip MENU for now)
	GameManager.start_game()


func _process(delta: float) -> void:
	# Wave start delay
	if _waiting_wave_start:
		_wave_start_timer -= delta
		if _wave_start_timer <= 0.0:
			_waiting_wave_start = false
			_begin_spawning()
		return

	# Handle wave spawning
	if _spawning_active:
		_update_spawning(delta)

	# Check if wave is complete (all spawned and all resolved)
	if GameManager.wave_enemies_spawned and GameManager.current_state == GameManager.GameState.PLAYING:
		if enemies_container.get_child_count() == 0:
			GameManager.on_all_enemies_resolved()


func _unhandled_input(event: InputEvent) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos: Vector2 = get_global_mouse_position()
		_process_click(click_pos)


func _process_click(click_pos: Vector2) -> void:
	if planet.is_point_inside(click_pos):
		click_rejected.emit("inside_planet")
		return

	var silo: Node2D = planet.silo_manager.get_nearest_available_silo(click_pos)
	if silo == null:
		click_rejected.emit("no_silo")
		return

	silo.fire()
	_spawn_interceptor(silo.global_position, click_pos)
	GameManager.record_shot_fired()


# --- Interceptor spawning ---

func _spawn_interceptor(from: Vector2, to: Vector2) -> void:
	var interceptor: Node2D = InterceptorScene.instantiate()
	interceptors_container.add_child(interceptor)
	interceptor.setup(from, to, GameManager.get_effective_interceptor_speed())
	interceptor.detonated.connect(_on_interceptor_detonated)


func _on_interceptor_detonated(pos: Vector2) -> void:
	_spawn_blast(pos)
	camera.shake(camera.detonation_shake_intensity)
	AudioManager.play_sfx("detonation")


# --- Blast spawning ---

func _spawn_blast(pos: Vector2) -> void:
	var blast: Node2D = BlastScene.instantiate()
	blasts_container.add_child(blast)
	blast.setup(pos, GameManager.get_effective_blast_radius(), enemies_container)
	blast.blast_enemy_caught.connect(_on_blast_enemy_caught)


func _on_blast_enemy_caught(_enemy: Node2D, _blast_position: Vector2) -> void:
	AudioManager.play_sfx("enemy_destroy")


# --- Enemy / MIRV spawning ---

func _spawn_enemy_or_mirv(is_silo_targeted: bool) -> void:
	var wave_data: WaveData = GameManager.current_wave_data
	var p_center: Vector2 = planet.global_position
	var p_radius: float = planet.planet_radius
	var vp_size: Vector2 = get_viewport_rect().size

	# Determine target on planet circumference
	var target_pos: Vector2 = _pick_target(is_silo_targeted, p_center, p_radius)

	# Generate valid spawn position
	var spawn_pos: Vector2 = SpawnValidator.generate_valid_spawn(
		target_pos, p_center, p_radius, vp_size, GameManager.config.spawn_margin
	)

	var missile_speed: float = randf_range(wave_data.speed_min, wave_data.speed_max)

	# Decide if this is a MIRV
	var is_mirv: bool = randf() < wave_data.mirv_chance

	if is_mirv:
		_spawn_mirv(spawn_pos, target_pos, missile_speed, p_center, p_radius, wave_data)
	else:
		_spawn_regular_enemy(spawn_pos, target_pos, missile_speed, p_center, p_radius)


func _spawn_regular_enemy(spawn_pos: Vector2, target_pos: Vector2, missile_speed: float, p_center: Vector2, p_radius: float) -> void:
	var enemy: Node2D = EnemyMissileScene.instantiate()
	enemies_container.add_child(enemy)
	enemy.setup(spawn_pos, target_pos, missile_speed, p_center, p_radius)
	enemy.enemy_impacted.connect(_on_enemy_impacted)
	enemy.enemy_destroyed.connect(_on_enemy_destroyed)


func _spawn_mirv(spawn_pos: Vector2, target_pos: Vector2, missile_speed: float, p_center: Vector2, p_radius: float, wave_data: WaveData) -> void:
	var mirv: Node2D = MIRVMissileScene.instantiate()
	enemies_container.add_child(mirv)

	var split_dist: float = randf_range(
		GameManager.config.mirv_split_dist_min,
		GameManager.config.mirv_split_dist_max
	)
	var num_warheads: int = randi_range(wave_data.mirv_min_warheads, wave_data.mirv_max_warheads)

	mirv.setup(spawn_pos, target_pos, missile_speed, p_center, p_radius, split_dist, num_warheads)
	mirv.mirv_split.connect(_on_mirv_split)
	mirv.enemy_destroyed.connect(_on_mirv_destroyed)


func _spawn_warhead(from: Vector2, target_pos: Vector2, p_center: Vector2, p_radius: float) -> void:
	var wave_data: WaveData = GameManager.current_wave_data
	var missile_speed: float = randf_range(wave_data.speed_min, wave_data.speed_max)

	var warhead: Node2D = EnemyMissileScene.instantiate()
	enemies_container.add_child(warhead)
	warhead.is_warhead = true
	warhead.head_radius = 3.0
	warhead.head_color = Color(1.0, 0.376, 0.125)  # Orange-red warhead color
	warhead.trail_color = Color(1.0, 0.376, 0.125)
	warhead.setup(from, target_pos, missile_speed, p_center, p_radius)
	warhead.enemy_impacted.connect(_on_enemy_impacted)
	warhead.enemy_destroyed.connect(_on_enemy_destroyed)


func _pick_target(is_silo_targeted: bool, p_center: Vector2, p_radius: float) -> Vector2:
	if is_silo_targeted:
		var silo: Node2D = _get_random_active_silo()
		if silo:
			return silo.global_position
	var angle: float = randf() * TAU
	return MathUtils.angle_to_point(p_center, p_radius, angle)


func _get_random_active_silo() -> Node2D:
	var active: Array[Node2D] = []
	for silo in planet.silo_manager.silos:
		if silo.state != Silo.SiloState.DESTROYED:
			active.append(silo)
	if active.is_empty():
		return null
	return active[randi() % active.size()]


func _on_enemy_impacted(impact_pos: Vector2) -> void:
	planet.silo_manager.check_silo_hit(impact_pos)
	AudioManager.play_sfx("enemy_impact")


func _on_enemy_destroyed(_pos: Vector2, is_warhead: bool, _is_mirv_presplit: bool) -> void:
	GameManager.record_enemy_destroyed()
	if is_warhead:
		GameManager.add_score(GameManager.config.points_warhead_kill)
	else:
		GameManager.add_score(GameManager.config.points_enemy_kill)


func _on_mirv_destroyed(_pos: Vector2, _is_warhead: bool, is_mirv_presplit: bool) -> void:
	GameManager.record_enemy_destroyed()
	if is_mirv_presplit:
		GameManager.add_score(GameManager.config.points_mirv_presplit)
	AudioManager.play_sfx("mirv_split")


func _on_mirv_split(pos: Vector2, warhead_targets: Array[Vector2]) -> void:
	AudioManager.play_sfx("mirv_split")
	camera.shake(camera.detonation_shake_intensity * 0.5)
	var p_center: Vector2 = planet.global_position
	var p_radius: float = planet.planet_radius
	for t in warhead_targets:
		_spawn_warhead(pos, t, p_center, p_radius)


# --- Wave spawning logic ---

func _on_wave_started(_wave_number: int) -> void:
	_waiting_wave_start = true
	_wave_start_timer = GameManager.config.wave_start_delay


func _begin_spawning() -> void:
	var wave_data: WaveData = GameManager.current_wave_data
	_spawning_active = true
	_burst_index = 0
	_total_spawned = 0
	_missiles_per_burst = ceili(float(wave_data.enemy_count) / float(wave_data.burst_count))
	_missiles_spawned_in_burst = 0
	_spawn_timer = 0.0
	_burst_timer = 0.0


func _update_spawning(delta: float) -> void:
	var wave_data: WaveData = GameManager.current_wave_data

	if _total_spawned >= wave_data.enemy_count:
		_spawning_active = false
		GameManager.on_wave_enemies_all_spawned()
		return

	# Wait between bursts
	if _missiles_spawned_in_burst >= _missiles_per_burst:
		_burst_timer += delta
		if _burst_timer >= GameManager.config.burst_interval:
			_burst_timer = 0.0
			_burst_index += 1
			_missiles_spawned_in_burst = 0
		return

	# Spawn within burst
	_spawn_timer += delta
	if _spawn_timer >= GameManager.config.spawn_interval:
		_spawn_timer = 0.0
		var targets_silo: bool = randf() < wave_data.silo_target_ratio
		_spawn_enemy_or_mirv(targets_silo)
		_missiles_spawned_in_burst += 1
		_total_spawned += 1


# --- Callbacks ---

func _on_click_rejected(_reason: String) -> void:
	crosshair.flash_reject()
	AudioManager.play_sfx("click_rejected")


func _on_multi_kill(count: int, _pos: Vector2) -> void:
	camera.shake(camera.multi_kill_shake_intensity)
	AudioManager.play_sfx("multi_kill")


func _on_silo_destroyed(_silo_index: int, _silo_position: Vector2) -> void:
	camera.shake(camera.silo_destroyed_shake_intensity)
	AudioManager.play_sfx("silo_destroyed")


func _on_all_silos_destroyed() -> void:
	GameManager.on_all_silos_destroyed()


func _on_silo_repair_requested() -> void:
	planet.silo_manager.repair_one_silo()


func _on_game_restarted() -> void:
	# Clear all missiles and blasts
	for child in interceptors_container.get_children():
		child.queue_free()
	for child in enemies_container.get_children():
		child.queue_free()
	for child in blasts_container.get_children():
		child.queue_free()
	for child in effects_container.get_children():
		child.queue_free()

	# Reset spawning state
	_spawning_active = false
	_waiting_wave_start = false

	# Reset silos
	planet.silo_manager.reset_all_silos()
