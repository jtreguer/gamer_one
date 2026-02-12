class_name SpawnValidator
extends RefCounted


static func generate_valid_spawn(
	target_pos: Vector2,
	planet_center: Vector2,
	planet_radius: float,
	viewport_size: Vector2,
	margin: float
) -> Vector2:
	for _attempt in range(10):
		var spawn_pos: Vector2 = _random_screen_edge_point(viewport_size, margin)
		if not MathUtils.line_intersects_circle(spawn_pos, target_pos, planet_center, planet_radius - 5.0):
			return spawn_pos

	# Fallback: place opposite to the target relative to planet center
	var away_dir: Vector2 = (target_pos - planet_center).normalized() * -1.0
	var spawn_pos: Vector2 = planet_center + away_dir * (viewport_size.length() * 0.5)
	spawn_pos.x = clampf(spawn_pos.x, margin, viewport_size.x - margin)
	spawn_pos.y = clampf(spawn_pos.y, margin, viewport_size.y - margin)
	return spawn_pos


static func _random_screen_edge_point(viewport_size: Vector2, margin: float) -> Vector2:
	var edge: int = randi() % 4
	match edge:
		0:  # Top
			return Vector2(randf_range(margin, viewport_size.x - margin), margin)
		1:  # Bottom
			return Vector2(randf_range(margin, viewport_size.x - margin), viewport_size.y - margin)
		2:  # Left
			return Vector2(margin, randf_range(margin, viewport_size.y - margin))
		3:  # Right
			return Vector2(viewport_size.x - margin, randf_range(margin, viewport_size.y - margin))
	return Vector2(margin, margin)
