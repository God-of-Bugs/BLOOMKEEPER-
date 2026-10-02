class_name BloomkeeperUI
extends CanvasLayer

@onready var spirits_label: Label = $HUD/MarginContainer/VBoxContainer/SpiritsLabel
@onready var health_label: Label = $HUD/MarginContainer/VBoxContainer/HealthLabel
@onready var energy_bar: ProgressBar = $HUD/MarginContainer/EnergyBox/EnergyBar

@onready var victory_panel: PanelContainer = $VictoryPanel
@onready var game_over_panel: PanelContainer = $GameOverPanel


func _ready() -> void:
	victory_panel.visible = false
	game_over_panel.visible = false
	await get_tree().process_frame

	var main_node: Node = get_parent()
	var game_manager: Node = main_node.get_node_or_null("GameManager")
	var player: CharacterBody3D = main_node.get_node_or_null("Player") as CharacterBody3D

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


func _on_status_updated(pacified: int, total: int) -> void:
	if spirits_label:
		spirits_label.text = "Spirits Pacified: %d / %d" % [pacified, total]


func _on_health_changed(current_hp: int, max_hp: int) -> void:
	if health_label:
		var hearts: String = ""
		for i in range(current_hp):
			hearts += "❤ "
		health_label.text = "Health: %s" % hearts.strip_edges()


func _on_energy_changed(current_energy: float, max_energy: float) -> void:
	if energy_bar:
		energy_bar.max_value = max_energy
		energy_bar.value = current_energy


func _on_victory() -> void:
	if victory_panel:
		victory_panel.visible = true


func _on_game_over() -> void:
	if game_over_panel:
		game_over_panel.visible = true
