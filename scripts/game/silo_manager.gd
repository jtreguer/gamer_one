extends Node2D

signal silo_destroyed(silo_index: int, silo_position: Vector2)
signal all_silos_destroyed()
signal silo_count_changed(active_count: int)

@export var initial_silo_count: int = 6
@export var silo_hit_tolerance: float = 15.0

var silos: Array[Node2D] = []

const SiloScene := preload("res://scenes/game/silo.tscn")


func _ready() -> void:
	_spawn_silos()


func _spawn_silos() -> void:
	for i in initial_silo_count:
		var silo: Node2D = SiloScene.instantiate()
		var angle: float = (float(i) / float(initial_silo_count)) * TAU
		add_child(silo)
		silo.setup(angle, GameManager.config.silo_reload_time)
		silos.append(silo)
	_update_silo_positions()
	_emit_silo_count()


func _process(_delta: float) -> void:
	_update_silo_positions()


func _update_silo_positions() -> void:
	var planet: Node2D = get_parent()
	var radius: float = planet.planet_radius
	var rot: float = planet.current_rotation

	for silo in silos:
		var angle: float = silo.base_angle + rot
		silo.position = Vector2(cos(angle), sin(angle)) * radius
		silo.rotation = angle + PI / 2.0  # Point outward


func get_nearest_available_silo(target_pos: Vector2) -> Node2D:
	var best_silo: Node2D = null
	var best_distance: float = INF

	for silo in silos:
		if silo.state != silo.SiloState.READY:
			continue
		var dist: float = silo.global_position.distance_to(target_pos)
		if dist < best_distance:
			best_distance = dist
			best_silo = silo

	return best_silo


func check_silo_hit(impact_position: Vector2) -> void:
	var planet: Node2D = get_parent()
	var planet_center: Vector2 = planet.global_position
	var planet_radius: float = planet.planet_radius

	var impact_dir: Vector2 = (impact_position - planet_center).normalized()
	var impact_angle: float = impact_dir.angle()

	for i in silos.size():
		var silo: Node2D = silos[i]
		if silo.state == silo.SiloState.DESTROYED:
			continue

		var silo_dir: Vector2 = (silo.global_position - planet_center).normalized()
		var silo_angle: float = silo_dir.angle()

		var arc_distance: float = MathUtils.angle_diff(impact_angle, silo_angle) * planet_radius
		if arc_distance < silo_hit_tolerance:
			silo.destroy()
			silo_destroyed.emit(i, silo.global_position)
			_emit_silo_count()

			if get_active_silo_count() == 0:
				all_silos_destroyed.emit()
			break


func get_active_silo_count() -> int:
	var count: int = 0
	for silo in silos:
		if silo.state != silo.SiloState.DESTROYED:
			count += 1
	return count


func repair_one_silo() -> void:
	for silo in silos:
		if silo.state == Silo.SiloState.DESTROYED:
			silo.state = Silo.SiloState.READY
			silo.silo_sprite.queue_redraw()
			_emit_silo_count()
			return


func reset_all_silos() -> void:
	for silo in silos:
		silo.state = Silo.SiloState.READY
		silo.reload_timer.stop()
		silo.reload_indicator.visible = false
		silo.silo_sprite.queue_redraw()
	_emit_silo_count()


func _emit_silo_count() -> void:
	var count: int = get_active_silo_count()
	GameManager.active_silo_count = count
	silo_count_changed.emit(count)
