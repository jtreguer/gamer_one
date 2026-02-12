extends PanelContainer

signal purchased(upgrade_id: String)

var upgrade_id: String = ""
var cost: int = 0
var is_affordable: bool = false
var is_maxed: bool = false

@onready var icon_label: Label = $VBox/IconLabel
@onready var name_label: Label = $VBox/NameLabel
@onready var level_label: Label = $VBox/LevelLabel
@onready var cost_label: Label = $VBox/CostLabel

const COLOR_AFFORDABLE := Color(0.3, 1.0, 0.3, 1.0)
const COLOR_UNAFFORDABLE := Color(0.6, 0.6, 0.6, 0.5)
const COLOR_MAXED := Color(1.0, 0.85, 0.2, 0.7)


func setup_upgrade(id: String, display_name: String, icon_text: String, level: int, max_level: int, upgrade_cost: int, player_score: int) -> void:
	upgrade_id = id
	cost = upgrade_cost

	icon_label.text = icon_text
	name_label.text = display_name

	if max_level == 0:
		# Special case: silo repair (one-time purchase)
		level_label.text = "REPAIR"
		is_maxed = false
	elif level >= max_level:
		level_label.text = "MAX"
		is_maxed = true
	else:
		level_label.text = "Lv " + str(level) + "/" + str(max_level)
		is_maxed = false

	if is_maxed:
		cost_label.text = "MAXED"
		is_affordable = false
	else:
		cost_label.text = str(cost) + " pts"
		is_affordable = player_score >= cost

	_update_visuals()


func refresh_affordability(player_score: int) -> void:
	if is_maxed:
		is_affordable = false
	else:
		is_affordable = player_score >= cost
	_update_visuals()


func _update_visuals() -> void:
	if is_maxed:
		modulate = COLOR_MAXED
	elif is_affordable:
		modulate = COLOR_AFFORDABLE
	else:
		modulate = COLOR_UNAFFORDABLE


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_affordable and not is_maxed:
			purchased.emit(upgrade_id)
