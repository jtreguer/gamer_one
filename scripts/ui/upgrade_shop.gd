extends Control

signal shop_closed()

@onready var title_label: Label = $Overlay/VBox/TitleLabel
@onready var score_display: Label = $Overlay/VBox/ScoreDisplay
@onready var card_container: HBoxContainer = $Overlay/VBox/CardContainer
@onready var continue_button: Button = $Overlay/VBox/ContinueButton

const UpgradeCardScene := preload("res://scenes/ui/upgrade_card.tscn")

# Upgrade definitions: id, display_name, icon, max_level, costs
const UPGRADES := [
	{
		"id": "interceptor_speed",
		"name": "Speed",
		"icon": ">>>",
		"max_level": 5,
		"costs": [3000, 6000, 12000, 24000, 48000],
	},
	{
		"id": "blast_radius",
		"name": "Blast",
		"icon": "(O)",
		"max_level": 5,
		"costs": [4000, 8000, 16000, 32000, 64000],
	},
	{
		"id": "reload_speed",
		"name": "Reload",
		"icon": "<->",
		"max_level": 5,
		"costs": [3500, 7000, 14000, 28000, 56000],
	},
	{
		"id": "silo_repair",
		"name": "Repair",
		"icon": "[+]",
		"max_level": 0,
		"costs": [],
	},
]

var _cards: Array[PanelContainer] = []


func _ready() -> void:
	GameManager.game_state_changed.connect(_on_game_state_changed)
	GameManager.score_changed.connect(_on_score_changed)
	continue_button.pressed.connect(_on_continue_pressed)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	if new_state == GameManager.GameState.UPGRADE_SHOP:
		_populate_cards()
		visible = true
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		visible = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE


func _populate_cards() -> void:
	# Clear old cards
	for card in _cards:
		card.queue_free()
	_cards.clear()

	for child in card_container.get_children():
		child.queue_free()

	var player_score: int = GameManager.score

	for def in UPGRADES:
		var card: PanelContainer = UpgradeCardScene.instantiate()
		card_container.add_child(card)

		var level: int = GameManager.upgrade_levels.get(def["id"], 0)
		var max_lvl: int = def["max_level"]
		var upgrade_cost: int = _get_cost(def, level)

		card.setup_upgrade(
			def["id"], def["name"], def["icon"],
			level, max_lvl, upgrade_cost, player_score
		)
		card.purchased.connect(_on_card_purchased)
		_cards.append(card)

	score_display.text = "SCORE: " + str(player_score)


func _get_cost(def: Dictionary, level: int) -> int:
	if def["id"] == "silo_repair":
		return GameManager.config.silo_repair_cost_mult * GameManager.current_wave
	var costs: Array = def["costs"]
	if level >= costs.size():
		return 999999
	return costs[level]


func _on_card_purchased(upgrade_id: String) -> void:
	if upgrade_id == "silo_repair":
		var cost: int = GameManager.config.silo_repair_cost_mult * GameManager.current_wave
		if GameManager.purchase_upgrade(upgrade_id, cost):
			AudioManager.play_sfx("purchase")
			_request_silo_repair()
			_refresh_cards()
	else:
		var level: int = GameManager.upgrade_levels.get(upgrade_id, 0)
		var def: Dictionary = _find_def(upgrade_id)
		if def.is_empty():
			return
		var cost: int = _get_cost(def, level)
		if GameManager.purchase_upgrade(upgrade_id, cost):
			AudioManager.play_sfx("purchase")
			_refresh_cards()


func _request_silo_repair() -> void:
	# Signal main.gd to repair a silo
	# We use a deferred call via GameManager signal
	GameManager.silo_repair_requested.emit()


func _find_def(upgrade_id: String) -> Dictionary:
	for def in UPGRADES:
		if def["id"] == upgrade_id:
			return def
	return {}


func _refresh_cards() -> void:
	score_display.text = "SCORE: " + str(GameManager.score)
	# Rebuild cards to reflect new levels/costs
	_populate_cards()


func _on_score_changed(_new_score: int) -> void:
	if visible:
		score_display.text = "SCORE: " + str(GameManager.score)


func _on_continue_pressed() -> void:
	shop_closed.emit()
	GameManager.on_shop_closed()
