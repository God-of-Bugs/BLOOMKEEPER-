class_name BloomkeeperGameManager
extends Node

signal victory_achieved
signal game_over_triggered
signal status_updated(pacified: int, total: int)

@export var prowler_scene: PackedScene = preload("res://scenes/Prowler.tscn")

var total_creatures: int = 5
var pacified_count: int = 0
var is_game_over: bool = false
var is_victory: bool = false

@onready var world_env: WorldEnvironment = get_node_or_null("../WorldEnvironment")
@onready var dir_light: DirectionalLight3D = get_node_or_null("../DirectionalLight3D")
@onready var audio_mgr: Node = get_node_or_null("../AudioManager")

var _last_player_hp: int = 3


func _ready() -> void:
	await get_tree().process_frame
	_setup_area_1()


func _setup_area_1() -> void:
	var main_node: Node = get_parent()
	var player: CharacterBody3D = main_node.get_node_or_null("Player") as CharacterBody3D

	if player:
		if player.has_signal("player_defeated") and not player.is_connected("player_defeated", _on_player_defeated):
			player.connect("player_defeated", _on_player_defeated)
		if player.has_signal("bloom_pulse_emitted") and not player.is_connected("bloom_pulse_emitted", _on_player_pulse):
			player.connect("bloom_pulse_emitted", _on_player_pulse)
		if player.has_signal("health_changed") and not player.is_connected("health_changed", _on_player_health_changed):
			player.connect("health_changed", _on_player_health_changed)

	var existing_prowlers: Array = get_tree().get_nodes_in_group("prowlers")
	for prowler in existing_prowlers:
		prowler.queue_free()

	await get_tree().physics_frame

	var spawn_positions: Array[Vector3] = [
		Vector3(3.5, 0.0, -1.5),
		Vector3(-4.0, 0.0, -3.0),
		Vector3(5.0, 0.0, 4.0),
		Vector3(-3.5, 0.0, 5.5),
		Vector3(0.0, 0.0, -7.0)
	]

	total_creatures = spawn_positions.size()
	pacified_count = 0

	for pos in spawn_positions:
		var prowler_inst: CharacterBody3D = prowler_scene.instantiate() as CharacterBody3D
		main_node.add_child(prowler_inst)
		prowler_inst.global_position = pos
		if prowler_inst.has_signal("pacified"):
			prowler_inst.connect("pacified", _on_creature_pacified)

	_update_world_transformation(0.0)
	status_updated.emit(pacified_count, total_creatures)


func _on_player_pulse(_origin: Vector3, _radius: float) -> void:
	if audio_mgr and audio_mgr.has_method("play_pulse"):
		audio_mgr.call("play_pulse")


func _on_player_health_changed(current_hp: int, _max_hp: int) -> void:
	if current_hp < _last_player_hp:
		if audio_mgr and audio_mgr.has_method("play_damage"):
			audio_mgr.call("play_damage")
	_last_player_hp = current_hp


func _on_creature_pacified() -> void:
	if is_game_over or is_victory:
		return

	if audio_mgr and audio_mgr.has_method("play_pacify"):
		audio_mgr.call("play_pacify")

	pacified_count += 1
	var ratio: float = float(pacified_count) / float(total_creatures)
	_update_world_transformation(ratio)
	status_updated.emit(pacified_count, total_creatures)

	if pacified_count >= total_creatures:
		is_victory = true
		if audio_mgr and audio_mgr.has_method("play_victory"):
			audio_mgr.call("play_victory")
		victory_achieved.emit()
		print("--- SANCTUARY RESTORED! VICTORY! ---")


func _update_world_transformation(ratio: float) -> void:
	if world_env and world_env.environment:
		var env: Environment = world_env.environment
		env.ambient_light_color = Color(0.29, 0.34, 0.48).lerp(Color(0.42, 0.65, 0.52), ratio)
		env.fog_light_color = Color(0.07, 0.1, 0.17).lerp(Color(0.3, 0.45, 0.4), ratio)
		env.fog_density = lerpf(0.001, 0.0002, ratio)

	if dir_light:
		dir_light.light_energy = lerpf(2.0, 3.2, ratio)
		dir_light.light_color = Color(0.72, 0.79, 1.0).lerp(Color(0.95, 0.98, 0.88), ratio)


func _on_player_defeated() -> void:
	if is_victory or is_game_over:
		return

	is_game_over = true
	if audio_mgr and audio_mgr.has_method("play_game_over"):
		audio_mgr.call("play_game_over")
	game_over_triggered.emit()
	print("--- GAME OVER! Press R to Restart ---")


func _unhandled_input(event: InputEvent) -> void:
	if (is_game_over or is_victory) and event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
