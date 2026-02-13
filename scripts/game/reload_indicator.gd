extends Node2D

const INDICATOR_RADIUS := 12.0
const INDICATOR_WIDTH := 2.0
const REDRAW_INTERVAL: float = 0.05  # 20fps for reload arc

var _redraw_accumulator: float = 0.0

@onready var _silo: Node2D = get_parent()

func _process(delta: float) -> void:
	if _silo.state == _silo.SiloState.RELOADING:
		_redraw_accumulator += delta
		if _redraw_accumulator >= REDRAW_INTERVAL:
			_redraw_accumulator = 0.0
			queue_redraw()
	else:
		_redraw_accumulator = 0.0


func _draw() -> void:
	if _silo.state != _silo.SiloState.RELOADING:
		return

	var progress: float = _silo.get_reload_progress()
	var arc_angle: float = progress * TAU
	var color := Color(0.251, 1.0, 0.251)
	color.a = 0.6
	draw_arc(Vector2.ZERO, INDICATOR_RADIUS, -PI / 2.0, -PI / 2.0 + arc_angle, 16, color, INDICATOR_WIDTH)
