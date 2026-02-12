class_name Silo
extends Node2D

enum SiloState {
	READY,
	RELOADING,
	DESTROYED,
}

signal launched(silo_position: Vector2)
signal reloaded(silo_position: Vector2)

var state: SiloState = SiloState.READY
var base_angle: float = 0.0  # Angle on the circumference (without rotation offset)

@onready var silo_sprite: Node2D = $SiloSprite
@onready var reload_timer: Timer = $ReloadTimer
@onready var reload_indicator: Node2D = $ReloadIndicator


func _ready() -> void:
	reload_timer.one_shot = true
	reload_timer.timeout.connect(_on_reload_complete)
	reload_indicator.visible = false


func setup(angle: float, reload_time: float) -> void:
	base_angle = angle
	reload_timer.wait_time = reload_time


func fire() -> void:
	if state != SiloState.READY:
		return
	state = SiloState.RELOADING
	reload_timer.wait_time = GameManager.get_effective_reload_time()
	reload_timer.start()
	reload_indicator.visible = true
	silo_sprite.queue_redraw()
	launched.emit(global_position)


func destroy() -> void:
	state = SiloState.DESTROYED
	reload_timer.stop()
	reload_indicator.visible = false
	silo_sprite.queue_redraw()


func _on_reload_complete() -> void:
	if state == SiloState.RELOADING:
		state = SiloState.READY
		reload_indicator.visible = false
		silo_sprite.queue_redraw()
		reloaded.emit(global_position)


func get_reload_progress() -> float:
	if state != SiloState.RELOADING:
		return 1.0
	if reload_timer.wait_time <= 0.0:
		return 1.0
	return 1.0 - (reload_timer.time_left / reload_timer.wait_time)
