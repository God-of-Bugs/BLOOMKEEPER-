class_name BloomkeeperProwler
extends CharacterBody3D

signal pacified
signal shrine_transformed(shrine_position: Vector3)

enum State { AGGRESSIVE, CALMING, PACIFIED }

@export var state: State = State.AGGRESSIVE
@export var chase_speed: float = 3.2
@export var turn_speed: float = 8.0
@export var stopping_distance: float = 1.05

var target_player: Node3D = null
var _shrine_light: OmniLight3D = null


func _ready() -> void:
	add_to_group("creatures")
	add_to_group("prowlers")
	if state == State.PACIFIED:
		_update_visuals_pacified()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= get_gravity().length() * delta
	else:
		velocity.y = 0.0

	match state:
		State.AGGRESSIVE:
			_process_chase(delta)
		State.CALMING, State.PACIFIED:
			velocity.x = 0.0
			velocity.z = 0.0

	move_and_slide()


func _process_chase(delta: float) -> void:
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Node3D

	if not target_player:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var diff: Vector3 = target_player.global_position - global_position
	diff.y = 0.0
	var dist: float = diff.length()

	if dist > stopping_distance:
		var dir: Vector3 = diff / dist
		velocity.x = dir.x * chase_speed
		velocity.z = dir.z * chase_speed
		var target_yaw: float = atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		_attack_player()


func _attack_player() -> void:
	if is_instance_valid(target_player) and target_player.has_method("take_damage"):
		target_player.take_damage(1)


func apply_bloom_pulse(pulse_origin: Vector3, pulse_radius: float) -> void:
	if state == State.PACIFIED:
		return

	var dist: float = global_position.distance_to(pulse_origin)
	if dist <= pulse_radius:
		pacify()


func pacify() -> void:
	if state == State.PACIFIED:
		return
	state = State.PACIFIED
	velocity = Vector3.ZERO
	remove_from_group("creatures")
	add_to_group("shrines")
	add_to_group("pacified_creatures")
	_update_visuals_pacified()
	pacified.emit()
	shrine_transformed.emit(global_position)


func _update_visuals_pacified() -> void:
	var body_mesh: MeshInstance3D = get_node_or_null("Body") as MeshInstance3D
	if body_mesh:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.82, 0.62, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(0.25, 0.70, 0.45, 1.0)
		mat.emission_energy_multiplier = 0.6
		body_mesh.material_override = mat

	var crest_mesh: MeshInstance3D = get_node_or_null("Crest") as MeshInstance3D
	if crest_mesh:
		var mat_crest: StandardMaterial3D = StandardMaterial3D.new()
		mat_crest.albedo_color = Color(0.85, 0.95, 0.75, 1.0)
		mat_crest.emission_enabled = true
		mat_crest.emission = Color(0.80, 0.90, 0.60, 1.0)
		mat_crest.emission_energy_multiplier = 1.0
		crest_mesh.material_override = mat_crest

	if not _shrine_light:
		_shrine_light = OmniLight3D.new()
		_shrine_light.name = "ShrineLight"
		_shrine_light.light_color = Color(0.92, 0.88, 0.55, 1.0)
		_shrine_light.light_energy = 2.5
		_shrine_light.omni_range = 6.0
		_shrine_light.position = Vector3(0, 1.2, 0)
		add_child(_shrine_light)
