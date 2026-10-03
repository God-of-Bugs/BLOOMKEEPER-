class_name BloomkeeperUI
extends CanvasLayer

signal game_started

@onready var spirits_label: Label = $HUD/MarginContainer/VBoxContainer/SpiritsLabel
@onready var health_label: Label = $HUD/MarginContainer/VBoxContainer/HealthLabel
@onready var energy_bar: ProgressBar = $HUD/MarginContainer/VBoxContainer/EnergyBox/EnergyBar
@onready var absorption_bar: ProgressBar = $HUD/MarginContainer/VBoxContainer/AbsorptionBox/AbsorptionBar
@onready var absorption_label: Label = $HUD/MarginContainer/VBoxContainer/AbsorptionBox/AbsorptionLabel
@onready var energy_label: Label = $HUD/MarginContainer/VBoxContainer/EnergyBox/EnergyLabel
@onready var title_panel: PanelContainer = $TitlePanel
@onready var pause_panel: PanelContainer = $PausePanel
@onready var victory_panel: PanelContainer = $VictoryPanel
@onready var game_over_panel: PanelContainer = $GameOverPanel

var is_game_started: bool = false
var is_paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	title_panel.visible = true
	pause_panel.visible = false
	victory_panel.visible = false
	game_over_panel.visible = false
	title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().process_frame

	var main_node: Node = get_parent()
	var game_manager: Node = main_node.get_node_or_null("GameManager")
	var player: Node = main_node.get_node_or_null("Player")
	if game_manager:
		if game_manager.has_signal("status_updated"):
			game_manager.connect("status_updated", _on_status_updated)
		if game_manager.has_signal("victory_achieved"):
			game_manager.connect("victory_achieved", _on_victory)
		if game_manager.has_signal("game_over_triggered"):
			game_manager.connect("game_over_triggered", _on_game_over)
	if player:
		if player.has_signal("health_changed"):
			player.connect("health_changed", _on_health_changed)
		if player.has_signal("energy_changed"):
			player.connect("energy_changed", _on_energy_changed)
		if player.has_signal("absorption_status_changed"):
			player.connect("absorption_status_changed", _on_absorption_status_changed)


func start_game() -> void:
	if is_game_started:
		return
	is_game_started = true
	title_panel.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	game_started.emit()


func toggle_pause() -> void:
	if not is_game_started or victory_panel.visible or game_over_panel.visible:
		return
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_panel.visible = is_paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_paused else Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if not is_game_started:
		if event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
			start_game()
		elif event is InputEventMouseButton and event.pressed:
			start_game()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if is_paused:
			is_paused = false
			get_tree().paused = false
			pause_panel.visible = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			toggle_pause()


func _on_status_updated(bloomed: int, total: int) -> void:
	spirits_label.text = "PROWLERS BLOOMED  ·  %d / %d" % [bloomed, total]


func _on_health_changed(current_hp: int, _max_hp: int) -> void:
	var hearts: String = ""
	for heart_index: int in range(current_hp):
		hearts += "♥ "
	health_label.text = "VITALITY  %s" % hearts.strip_edges()


func _on_energy_changed(current_energy: float, max_energy: float) -> void:
	energy_bar.max_value = max_energy
	energy_bar.value = current_energy
	energy_label.text = "LUMEN  %d%%" % roundi(current_energy)


func _on_absorption_status_changed(progress: float, active: bool, available: bool, in_range: bool) -> void:
	if absorption_bar:
		absorption_bar.value = progress * 100.0
		absorption_bar.visible = available and in_range
	if absorption_label:
		absorption_label.visible = available and in_range
		absorption_label.text = "ABSORBING  %d%%" % roundi(progress * 100.0) if active else "HOLD F TO ABSORB"


func _on_victory() -> void:
	victory_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_game_over() -> void:
	game_over_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
