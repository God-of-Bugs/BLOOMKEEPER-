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
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _spawned_positions: Array[Vector3] = []
var _reserved_relocation_positions: Array[Vector3] = []
const SPAWN_BOUNDARY: float = 27.0
const MIN_ENEMY_SPACING: float = 8.0
const MIN_PLAYER_SPAWN_DISTANCE: float = 9.0


func _ready() -> void:
	_rng.randomize()
	add_to_group("game_manager")
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

	_spawned_positions.clear()
	var player_position: Vector3 = (player as Node3D).global_position if player else Vector3.ZERO
	total_creatures = 5
	pacified_count = 0

	for index: int in range(total_creatures):
		var spawn_position: Vector3 = _choose_valid_enemy_position(player_position, _spawned_positions)
		_spawned_positions.append(spawn_position)
		var prowler_inst: CharacterBody3D = prowler_scene.instantiate() as CharacterBody3D
		prowler_inst.set("roam_center", spawn_position)
		prowler_inst.set("roam_radius", 3.0)
		prowler_inst.set("roam_seed", _rng.randi_range(1, 2147483647))
		prowler_inst.set("absorption_progress", 0.0)
		main_node.add_child(prowler_inst)
		prowler_inst.global_position = spawn_position
		if prowler_inst.has_signal("pacified"):
			prowler_inst.connect("pacified", _on_creature_pacified)

	_update_world_transformation(0.0)
	status_updated.emit(pacified_count, total_creatures)


func _choose_valid_enemy_position(player_position: Vector3, other_positions: Array[Vector3]) -> Vector3:
	for attempt: int in range(100):
		var candidate: Vector3 = Vector3(
			_rng.randf_range(-SPAWN_BOUNDARY, SPAWN_BOUNDARY),
			0.0,
			_rng.randf_range(-SPAWN_BOUNDARY, SPAWN_BOUNDARY)
		)
		if _planar_distance(candidate, player_position) < MIN_PLAYER_SPAWN_DISTANCE:
			continue
		var has_clearance: bool = true
		for other_position: Vector3 in other_positions:
			if _planar_distance(candidate, other_position) < MIN_ENEMY_SPACING:
				has_clearance = false
				break
		if has_clearance:
			return candidate
	for fallback_attempt: int in range(200):
		var fallback: Vector3 = Vector3(
			_rng.randf_range(-SPAWN_BOUNDARY, SPAWN_BOUNDARY),
			0.0,
			_rng.randf_range(-SPAWN_BOUNDARY, SPAWN_BOUNDARY)
		)
		var spacing_ok: bool = _planar_distance(fallback, player_position) >= MIN_PLAYER_SPAWN_DISTANCE
		for other_position: Vector3 in other_positions:
			spacing_ok = spacing_ok and _planar_distance(fallback, other_position) >= MIN_ENEMY_SPACING
		if spacing_ok:
			return fallback
	for grid_x: int in range(-6, 7):
		for grid_z: int in range(-6, 7):
			var grid_candidate: Vector3 = Vector3(float(grid_x) * 4.0, 0.0, float(grid_z) * 4.0)
			if _planar_distance(grid_candidate, player_position) < MIN_PLAYER_SPAWN_DISTANCE:
				continue
			var grid_clear: bool = true
			for other_position: Vector3 in other_positions:
				if _planar_distance(grid_candidate, other_position) < MIN_ENEMY_SPACING:
					grid_clear = false
					break
			if grid_clear:
				return grid_candidate
	push_error("No safe enemy spawn position could be found within arena bounds.")
	return Vector3.ZERO


func _planar_distance(first: Vector3, second: Vector3) -> float:
	var offset: Vector3 = first - second
	offset.y = 0.0
	return offset.length()


func request_enemy_relocation(enemy: Node3D) -> Vector3:
	var player_node: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	var player_position: Vector3 = player_node.global_position if player_node else Vector3.ZERO
	var occupied_positions: Array[Vector3] = _reserved_relocation_positions.duplicate()
	for active_node: Node in get_tree().get_nodes_in_group("prowlers"):
		var active_enemy: Node3D = active_node as Node3D
		if active_enemy:
			occupied_positions.append(active_enemy.global_position)
	occupied_positions.append(enemy.global_position)
	var destination: Vector3 = _choose_valid_enemy_position(player_position, occupied_positions)
	_reserved_relocation_positions.append(destination)
	return destination


func release_enemy_relocation(position: Vector3) -> void:
	for index: int in range(_reserved_relocation_positions.size()):
		if _reserved_relocation_positions[index].distance_to(position) < 0.01:
			_reserved_relocation_positions.remove_at(index)
			return


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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		if is_game_over or is_victory or get_tree().paused:
			get_tree().reload_current_scene()
