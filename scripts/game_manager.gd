class_name BloomkeeperGameManager
extends Node

signal victory_achieved
signal game_over_triggered
signal status_updated(bloomed: int, total: int)

@export var prowler_scene: PackedScene = preload("res://scenes/Prowler.tscn")

var total_creatures: int = 5
var pacified_count: int = 0
var is_game_over: bool = false
var is_victory: bool = false

@onready var world_env: WorldEnvironment = get_node_or_null("../WorldEnvironment") as WorldEnvironment
@onready var dir_light: DirectionalLight3D = get_node_or_null("../DirectionalLight3D") as DirectionalLight3D
@onready var audio_mgr: Node = get_node_or_null("../AudioManager")
@onready var forest: Node = get_node_or_null("../Arena/Forest")

var _last_player_hp: int = 3


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_forest_arena.call_deferred()


func _setup_forest_arena() -> void:
	var main_node: Node = get_parent()
	var player: Node = main_node.get_node_or_null("Player")
	if player:
		if player.has_signal("player_defeated") and not player.is_connected("player_defeated", _on_player_defeated):
			player.connect("player_defeated", _on_player_defeated)
		if player.has_signal("bloom_pulse_emitted") and not player.is_connected("bloom_pulse_emitted", _on_player_pulse):
			player.connect("bloom_pulse_emitted", _on_player_pulse)
		if player.has_signal("health_changed") and not player.is_connected("health_changed", _on_player_health_changed):
			player.connect("health_changed", _on_player_health_changed)

	if prowler_scene and not prowler_scene.resource_path.is_empty():
		var prowler_packed_scene: PackedScene = load(prowler_scene.resource_path) as PackedScene
		if prowler_packed_scene:
			prowler_scene = prowler_packed_scene

	for existing_prowler: Node in get_tree().get_nodes_in_group("prowlers"):
		existing_prowler.queue_free()

	var spawn_positions: Array[Vector3] = [
		Vector3(0.0, 0.0, -4.0),
		Vector3(4.8, 0.0, -3.2),
		Vector3(4.8, 0.0, 3.2),
		Vector3(-4.8, 0.0, 3.2),
		Vector3(-4.8, 0.0, -3.2)
	]
	total_creatures = spawn_positions.size()
	pacified_count = 0

	for index: int in range(spawn_positions.size()):
		var spawn_position: Vector3 = spawn_positions[index]
		var prowler_inst: CharacterBody3D = prowler_scene.instantiate() as CharacterBody3D
		prowler_inst.set("roam_center", spawn_position)
		prowler_inst.set("roam_radius", 3.0)
		prowler_inst.set("roam_seed", index + 11)
		prowler_inst.set("absorption_progress", 0.0)
		main_node.add_child(prowler_inst)
		prowler_inst.global_position = spawn_position
		if prowler_inst.has_signal("pacified"):
			prowler_inst.connect("pacified", _on_creature_pacified)

	_update_world_transformation(0.0)
	status_updated.emit(pacified_count, total_creatures)


func _on_player_pulse(_origin: Vector3, _radius: float) -> void:
	if audio_mgr and audio_mgr.has_method("play_pulse"):
		audio_mgr.call("play_pulse")


func _on_player_health_changed(current_hp: int, _max_hp: int) -> void:
	if current_hp < _last_player_hp and audio_mgr and audio_mgr.has_method("play_damage"):
		audio_mgr.call("play_damage")
	_last_player_hp = current_hp


func _on_creature_pacified() -> void:
	if is_game_over or is_victory or pacified_count >= total_creatures:
		return
	if audio_mgr and audio_mgr.has_method("play_pacify"):
		audio_mgr.call("play_pacify")

	pacified_count += 1
	status_updated.emit(pacified_count, total_creatures)
	if pacified_count >= total_creatures:
		is_victory = true
		_update_world_transformation(1.0)
		if forest and forest.has_method("restore_forest"):
			forest.call("restore_forest")
		if audio_mgr and audio_mgr.has_method("play_victory"):
			audio_mgr.call("play_victory")
		_finish_victory_sequence()


func _finish_victory_sequence() -> void:
	await get_tree().create_timer(2.8).timeout
	print("--- ALL FIVE PROWLERS HAVE BLOOMED: FOREST RESTORED! ---")
	victory_achieved.emit()
	get_tree().paused = true


func _update_world_transformation(ratio: float) -> void:
	if ratio < 1.0:
		return
	if world_env and world_env.environment:
		var environment: Environment = world_env.environment
		var light_tween: Tween = create_tween()
		light_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		light_tween.set_parallel(true)
		light_tween.tween_property(environment, "ambient_light_color", Color("a7d59c"), 2.6)
		light_tween.tween_property(environment, "ambient_light_energy", 1.5, 2.6)
		light_tween.tween_property(environment, "fog_light_color", Color("c2e4b0"), 2.6)
		light_tween.tween_property(environment, "fog_density", 0.0007, 2.6)
	if dir_light:
		var sunlight_tween: Tween = create_tween()
		sunlight_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		sunlight_tween.set_parallel(true)
		sunlight_tween.tween_property(dir_light, "light_energy", 2.2, 2.6)
		sunlight_tween.tween_property(dir_light, "light_color", Color("fff0c5"), 2.6)


func _on_player_defeated() -> void:
	if is_victory or is_game_over:
		return
	is_game_over = true
	if audio_mgr and audio_mgr.has_method("play_game_over"):
		audio_mgr.call("play_game_over")
	game_over_triggered.emit()
	get_tree().paused = true
	print("--- GAME OVER! Press R to Restart ---")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		if is_game_over or is_victory or get_tree().paused:
			get_tree().reload_current_scene()
