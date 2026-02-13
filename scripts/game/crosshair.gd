extends Sprite2D

@export var default_color: Color = Color(1.0, 1.0, 1.0)
@export var reject_color: Color = Color(1.0, 0.251, 0.251)
@export var reject_flash_duration: float = 0.15

const CROSSHAIR_SIZE := 12.0
const CROSSHAIR_GAP := 3.0
const CROSSHAIR_WIDTH := 2.0

var _flash_timer: float = 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	z_index = 10
	# We draw the crosshair procedurally, no texture needed
	texture = null


func _process(delta: float) -> void:
	global_position = get_global_mouse_position()

	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_flash_timer = 0.0
			queue_redraw()


func flash_reject() -> void:
	_flash_timer = reject_flash_duration
	queue_redraw()


func _draw() -> void:
	var color: Color = default_color if _flash_timer <= 0.0 else reject_color

	# Horizontal lines
	draw_line(Vector2(-CROSSHAIR_SIZE, 0), Vector2(-CROSSHAIR_GAP, 0), color, CROSSHAIR_WIDTH)
	draw_line(Vector2(CROSSHAIR_GAP, 0), Vector2(CROSSHAIR_SIZE, 0), color, CROSSHAIR_WIDTH)

	# Vertical lines
	draw_line(Vector2(0, -CROSSHAIR_SIZE), Vector2(0, -CROSSHAIR_GAP), color, CROSSHAIR_WIDTH)
	draw_line(Vector2(0, CROSSHAIR_GAP), Vector2(0, CROSSHAIR_SIZE), color, CROSSHAIR_WIDTH)
