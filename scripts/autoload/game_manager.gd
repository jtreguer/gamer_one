extends Node

enum GameState {
	MENU,
	PLAYING,
	WAVE_TRANSITION,
	UPGRADE_SHOP,
	GAME_OVER,
}

signal game_state_changed(new_state: GameState)
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal wave_enemies_all_spawned()
signal score_changed(new_score: int)
signal game_over_triggered()
signal silo_repair_requested()
signal game_restarted()

var config: GameConfig
var current_state: GameState = GameState.MENU
var current_wave: int = 0
var score: int = 0
var high_score: int = 0
var shots_fired: int = 0
var shots_hit: int = 0
var upgrade_levels: Dictionary = {
	"interceptor_speed": 0,
	"blast_radius": 0,
	"reload_speed": 0,
}
var current_wave_data: WaveData = null
var wave_enemies_spawned: bool = false
var active_silo_count: int = 0
var total_enemies_destroyed: int = 0
var total_shots_fired: int = 0
var total_shots_hit: int = 0


func _ready() -> void:
	config = preload("res://assets/data/default_config.tres")
	_load_high_score()


func transition_to(new_state: GameState) -> void:
	current_state = new_state
	game_state_changed.emit(new_state)


func start_game() -> void:
	score = 0
	current_wave = 0
	shots_fired = 0
	shots_hit = 0
	total_enemies_destroyed = 0
	total_shots_fired = 0
	total_shots_hit = 0
	upgrade_levels = {
		"interceptor_speed": 0,
		"blast_radius": 0,
		"reload_speed": 0,
	}
	score_changed.emit(score)
	_start_next_wave()


func restart_game() -> void:
	game_restarted.emit()
	start_game()


func _start_next_wave() -> void:
	current_wave += 1
	wave_enemies_spawned = false
	shots_fired = 0
	shots_hit = 0
	current_wave_data = generate_wave_data(current_wave)
	transition_to(GameState.PLAYING)
	wave_started.emit(current_wave)


func on_wave_enemies_all_spawned() -> void:
	wave_enemies_spawned = true
	wave_enemies_all_spawned.emit()


func on_all_enemies_resolved() -> void:
	if current_state != GameState.PLAYING:
		return
	var bonuses: int = calculate_wave_bonuses()
	add_score(bonuses)
	wave_completed.emit(current_wave)
	transition_to(GameState.UPGRADE_SHOP)


func on_shop_closed() -> void:
	_start_next_wave()


func on_all_silos_destroyed() -> void:
	if score > high_score:
		high_score = score
		_save_high_score()
	transition_to(GameState.GAME_OVER)
	game_over_triggered.emit()


func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)


func record_shot_fired() -> void:
	shots_fired += 1
	total_shots_fired += 1


func record_shot_hit() -> void:
	shots_hit += 1
	total_shots_hit += 1


func record_enemy_destroyed() -> void:
	total_enemies_destroyed += 1


func get_overall_accuracy() -> float:
	if total_shots_fired == 0:
		return 0.0
	return clampf(float(total_shots_hit) / float(total_shots_fired), 0.0, 1.0)


func get_wave_accuracy() -> float:
	if shots_fired == 0:
		return 0.0
	return clampf(float(shots_hit) / float(shots_fired), 0.0, 1.0)


func calculate_wave_bonuses() -> int:
	var bonus: int = 0

	# Wave clear bonus (only if no silos lost this wave — simplified: always award)
	bonus += config.wave_clear_bonus * current_wave

	# Silo survival bonus
	bonus += config.silo_survival_bonus * active_silo_count * current_wave

	# Accuracy bonus
	if get_wave_accuracy() >= config.accuracy_bonus_threshold:
		bonus += config.accuracy_bonus * current_wave

	return bonus


# --- Effective values (base + upgrades) ---

func get_effective_interceptor_speed() -> float:
	return config.interceptor_speed + upgrade_levels["interceptor_speed"] * 60.0


func get_effective_blast_radius() -> float:
	return config.blast_radius + upgrade_levels["blast_radius"] * 6.0


func get_effective_reload_time() -> float:
	return maxf(config.silo_reload_time + upgrade_levels["reload_speed"] * (-0.18), 0.6)


func purchase_upgrade(upgrade_id: String, cost: int) -> bool:
	if score < cost:
		return false
	score -= cost
	if upgrade_levels.has(upgrade_id):
		upgrade_levels[upgrade_id] += 1
	score_changed.emit(score)
	return true


# --- Wave generation (GDD 5.1 formulas) ---

func generate_wave_data(wave_num: int) -> WaveData:
	var data := WaveData.new()
	data.wave_number = wave_num

	data.enemy_count = mini(
		config.initial_enemy_count + (wave_num - 1) * config.enemy_count_escalation,
		config.enemy_count_cap
	)

	data.speed_min = minf(
		config.enemy_speed_min_base + (wave_num - 1) * config.enemy_speed_escalation,
		config.enemy_speed_cap - 20.0
	)
	data.speed_max = minf(
		config.enemy_speed_max_base + (wave_num - 1) * config.enemy_speed_max_escalation,
		config.enemy_speed_cap
	)

	if wave_num < config.mirv_start_wave:
		data.mirv_chance = 0.0
	else:
		data.mirv_chance = minf(
			config.mirv_base_chance + (wave_num - config.mirv_start_wave) * config.mirv_chance_per_wave,
			config.mirv_chance_cap
		)

	data.mirv_min_warheads = config.mirv_min_warheads
	if wave_num >= 15:
		data.mirv_max_warheads = config.mirv_max_warheads
	elif wave_num >= 8:
		data.mirv_max_warheads = 3
	else:
		data.mirv_max_warheads = 2

	data.burst_count = mini(2 + floori(float(wave_num) / 3.0), 7)
	data.silo_target_ratio = config.silo_target_ratio

	return data


# --- High score persistence ---

const SAVE_PATH := "user://highscore.save"

func _load_high_score() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			high_score = file.get_32()
			file.close()


func _save_high_score() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_32(high_score)
		file.close()
