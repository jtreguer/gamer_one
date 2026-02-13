extends Node2D

signal blast_enemy_caught(enemy: Node2D, blast_position: Vector2)
signal multi_kill_detected(count: int, pos: Vector2)

enum BlastPhase {
	EXPANDING,
	HOLDING,
	FADING,
}

var max_radius: float = 40.0
var expand_time: float = 0.3
var hold_time: float = 0.2
var fade_time: float = 0.2

var current_radius: float = 0.0
var current_alpha: float = 1.0
var phase: BlastPhase = BlastPhase.EXPANDING
var _elapsed: float = 0.0
var _caught_enemies: Dictionary = {}  # Track which enemies this blast already caught
var _kill_count: int = 0
var _enemies_container: Node2D = null
var _cached_radius_sq: float = 0.0

@onready var blast_visual: Node2D = $BlastVisual


func setup(pos: Vector2, radius: float, enemies_container: Node2D) -> void:
	global_position = pos
	max_radius = radius
	_enemies_container = enemies_container
	expand_time = GameManager.config.blast_expand_time
	hold_time = GameManager.config.blast_hold_time
	fade_time = GameManager.config.blast_fade_time


func _process(delta: float) -> void:
	_elapsed += delta

	match phase:
		BlastPhase.EXPANDING:
			current_radius = max_radius * (_elapsed / expand_time)
			current_alpha = 1.0
			_cached_radius_sq = current_radius * current_radius
			if _elapsed >= expand_time:
				current_radius = max_radius
				_cached_radius_sq = max_radius * max_radius
				_elapsed = 0.0
				phase = BlastPhase.HOLDING
		BlastPhase.HOLDING:
			current_radius = max_radius
			current_alpha = 1.0
			if _elapsed >= hold_time:
				_elapsed = 0.0
				phase = BlastPhase.FADING
				if _kill_count >= 3:
					multi_kill_detected.emit(_kill_count, global_position)
		BlastPhase.FADING:
			current_radius = max_radius
			current_alpha = 1.0 - (_elapsed / fade_time)
			if _elapsed >= fade_time:
				queue_free()
				return

	# Hit detection during lethal phases
	if phase != BlastPhase.FADING and _enemies_container:
		_check_enemy_hits()

	blast_visual.queue_redraw()


func _check_enemy_hits() -> void:
	var count: int = _enemies_container.get_child_count()
	for i in count:
		var enemy: Node2D = _enemies_container.get_child(i) as Node2D
		if enemy == null:
			continue
		if not enemy.is_alive():
			continue
		if _caught_enemies.has(enemy.get_instance_id()):
			continue
		var dist_sq: float = global_position.distance_squared_to(enemy.global_position)
		if dist_sq <= _cached_radius_sq:
			_caught_enemies[enemy.get_instance_id()] = true
			_kill_count += 1
			enemy.destroy()
			blast_enemy_caught.emit(enemy, global_position)
			GameManager.record_shot_hit()
