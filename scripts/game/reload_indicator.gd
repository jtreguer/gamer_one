extends Node2D

const INDICATOR_RADIUS := 12.0
const INDICATOR_WIDTH := 2.0

func _process(_delta: float) -> void:
	var silo: Node2D = get_parent()
	if silo.state == silo.SiloState.RELOADING:
		queue_redraw()


func _draw() -> void:
	var silo: Node2D = get_parent()
	if silo.state != silo.SiloState.RELOADING:
		return

	var progress: float = silo.get_reload_progress()
	var arc_angle: float = progress * TAU
	var color := Color(0.251, 1.0, 0.251)
	color.a = 0.6
	draw_arc(Vector2.ZERO, INDICATOR_RADIUS, -PI / 2.0, -PI / 2.0 + arc_angle, 16, color, INDICATOR_WIDTH)
