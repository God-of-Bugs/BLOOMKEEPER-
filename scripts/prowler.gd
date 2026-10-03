class_name BloomkeeperProwler
extends CharacterBody3D

signal pacified
signal shrine_transformed(shrine_position: Vector3)
signal absorption_changed(progress: float)

enum State { AGGRESSIVE, CALMING, PACIFIED }

@export var state: State = State.AGGRESSIVE
@export var roam_center: Vector3 = Vector3.ZERO
@export var roam_radius: float = 5.5
@export var roam_speed: float = 0.62
@export var roam_seed: int = 1

var absorption_progress: float = 0.0
var _roam_target: Vector3 = Vector3.ZERO
var _roam_wait_timer: float = 0.0
var _calm_timer: float = 0.0
var _animation_clock: float = 0.0
var _being_absorbed: bool = false
var _shrine_light: OmniLight3D = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _walk_distance: float = 0.0
var _target_is_set: bool = false

@onready var model: Node3D = $Model
@onready var patch: Node3D = get_node_or_null("ForestPatch") as Node3D
@onready var left_root: Node3D = $Model/LeftRootPivot
@onready var right_root: Node3D = $Model/RightRootPivot
@onready var left_leg: Node3D = $Model/LeftLegPivot
@onready var right_leg: Node3D = $Model/RightLegPivot


func _ready() -> void:
	add_to_group("creatures")
	add_to_group("prowlers")
	_rng.seed = int(roam_seed) if roam_seed > 0 else int(Time.get_ticks_usec())
	if state == State.PACIFIED:
		_update_visuals_pacified()
	if not _target_is_set:
		_choose_roam_target()


func _physics_process(delta: float) -> void:
	_animation_clock += delta
	if not is_on_floor():
		velocity.y -= get_gravity().length() * delta
	else:
		velocity.y = 0.0

	if state == State.AGGRESSIVE:
		_process_roaming(delta)
	elif state == State.CALMING:
		velocity.x = move_toward(velocity.x, 0.0, roam_speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, roam_speed * 8.0 * delta)
		if not _being_absorbed:
			_calm_timer = maxf(_calm_timer - delta, 0.0)
			if _calm_timer <= 0.0:
				state = State.AGGRESSIVE
	else:
		velocity.x = move_toward(velocity.x, 0.0, roam_speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, roam_speed * 8.0 * delta)

	move_and_slide()
	_animate_roots(delta)


func _process_roaming(delta: float) -> void:
	if _roam_wait_timer > 0.0:
		_roam_wait_timer = maxf(_roam_wait_timer - delta, 0.0)
		velocity.x = move_toward(velocity.x, 0.0, roam_speed * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, roam_speed * 5.0 * delta)
		return

	var direction: Vector3 = _roam_target - global_position
	direction.y = 0.0
	if direction.length() < 0.75:
		_roam_wait_timer = _rng.randf_range(0.7, 2.0)
		_choose_roam_target()
		velocity.x = 0.0
		velocity.z = 0.0
		return

	direction = direction.normalized()
	velocity.x = direction.x * roam_speed
	velocity.z = direction.z * roam_speed
	var target_yaw: float = atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 5.5 * delta)
	_walk_distance += roam_speed * delta


func _choose_roam_target() -> void:
	var angle: float = _rng.randf_range(0.0, TAU)
	var distance: float = sqrt(_rng.randf()) * roam_radius
	var x_target: float = clampf(roam_center.x + cos(angle) * distance, -29.0, 29.0)
	var z_target: float = clampf(roam_center.z + sin(angle) * distance, -29.0, 29.0)
	_roam_target = Vector3(x_target, global_position.y, z_target)
	_target_is_set = true


func _animate_roots(delta: float) -> void:
	var walking: bool = state == State.AGGRESSIVE and velocity.length_squared() > 0.08
	var swing: float = sin(_walk_distance * 3.0) * 0.28 if walking else 0.0
	left_root.rotation.x = lerpf(left_root.rotation.x, swing, 6.0 * delta)
	right_root.rotation.x = lerpf(right_root.rotation.x, -swing, 6.0 * delta)
	left_leg.rotation.x = lerpf(left_leg.rotation.x, -swing * 0.85, 7.0 * delta)
	right_leg.rotation.x = lerpf(right_leg.rotation.x, swing * 0.85, 7.0 * delta)
	model.position.y = 0.035 * sin(_animation_clock * 3.1) if state != State.PACIFIED else 0.0


func absorb_bloom(delta: float, absorption_rate: float) -> float:
	if state == State.PACIFIED:
		return 0.0
	_being_absorbed = true
	state = State.CALMING
	absorption_progress = minf(absorption_progress + absorption_rate * delta, 100.0)
	absorption_changed.emit(absorption_progress / 100.0)
	var restored_energy: float = delta
	if absorption_progress >= 100.0:
		pacify()
	return restored_energy


func get_absorption_progress() -> float:
	return absorption_progress / 100.0


func stop_absorption() -> void:
	if state == State.PACIFIED:
		return
	_being_absorbed = false
	_calm_timer = 0.0
	state = State.AGGRESSIVE


func apply_bloom_pulse(pulse_origin: Vector3, pulse_radius: float) -> void:
	if state == State.PACIFIED:
		return
	var planar_delta: Vector3 = global_position - pulse_origin
	planar_delta.y = 0.0
	if planar_delta.length() <= pulse_radius:
		absorption_progress = minf(absorption_progress + 18.0, 90.0)
		absorption_changed.emit(absorption_progress / 100.0)
		_being_absorbed = false
		state = State.CALMING
		_calm_timer = 1.0


func pacify() -> void:
	if state == State.PACIFIED:
		return
	state = State.PACIFIED
	absorption_progress = 100.0
	_being_absorbed = false
	velocity = Vector3.ZERO
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	var collider: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collider:
		collider.set_deferred("disabled", true)
	remove_from_group("creatures")
	add_to_group("shrines")
	add_to_group("pacified_creatures")
	_update_visuals_pacified()
	if patch and patch.has_method("restore"):
		patch.call("restore")
	pacified.emit()
	shrine_transformed.emit(global_position)


func _update_visuals_pacified() -> void:
	_set_mesh_material("BarkCore", Color("67864c"), Color("89ca74"), 0.55)
	_set_mesh_material("BarkPlate", Color("8eaa61"), Color("a7d978"), 0.45)
	_set_mesh_material("Muzzle", Color("a9bb75"), Color("c4df8a"), 0.55)
	_set_mesh_material("LeftRoot", Color("789451"), Color("9acb72"), 0.5)
	_set_mesh_material("RightRoot", Color("789451"), Color("9acb72"), 0.5)
	_set_mesh_material("RootAntlerLeft", Color("8eb96a"), Color("a6e28b"), 0.75)
	_set_mesh_material("RootAntlerRight", Color("8eb96a"), Color("a6e28b"), 0.75)
	_set_mesh_material("Scar", Color("bce98c"), Color("baff86"), 2.8)
	_set_mesh_material("EyeLeft", Color("e4f2a3"), Color("dcff9c"), 1.4)
	_set_mesh_material("EyeRight", Color("e4f2a3"), Color("dcff9c"), 1.4)
	left_root.rotation.x = 0.0
	right_root.rotation.x = 0.0
	left_leg.rotation.x = 0.0
	right_leg.rotation.x = 0.0
	if not _shrine_light:
		_shrine_light = OmniLight3D.new()
		_shrine_light.name = "BloomLight"
		_shrine_light.light_color = Color("a9e88a")
		_shrine_light.light_energy = 1.5
		_shrine_light.omni_range = 7.0
		_shrine_light.position = Vector3(0.0, 1.2, 0.0)
		add_child(_shrine_light)


func _set_mesh_material(node_name: String, albedo: Color, glow: Color, glow_energy: float) -> void:
	var mesh_instance: MeshInstance3D = model.get_node_or_null(node_name) as MeshInstance3D
	if not mesh_instance:
		return
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.94
	material.emission_enabled = glow_energy > 0.0
	material.emission = glow
	material.emission_energy_multiplier = glow_energy
	mesh_instance.material_override = material
