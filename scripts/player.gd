class_name BloomkeeperPlayer
extends CharacterBody3D

signal bloom_pulse_emitted(origin: Vector3, radius: float)
signal energy_changed(current: float, max_energy: float)
signal health_changed(current_health: int, max_health: int)
signal absorption_status_changed(progress: float, is_active: bool, is_available: bool, is_in_range: bool)
signal player_defeated

const MOVE_SPEED: float = 5.0
const TURN_SPEED: float = 10.0
const MOUSE_SENSITIVITY: float = 0.0024
const MIN_CAMERA_PITCH: float = deg_to_rad(-62.0)
const MAX_CAMERA_PITCH: float = deg_to_rad(18.0)
const DASH_DISTANCE: float = 1.8
const DASH_DURATION: float = 0.22
const DASH_COOLDOWN: float = 1.2
const PULSE_MIN_RADIUS: float = 3.0
const PULSE_MAX_RADIUS: float = 7.5
const PULSE_CHARGE_RATE: float = 4.0
const PULSE_COOLDOWN: float = 0.6
const MAX_ENERGY: float = 100.0
const ENERGY_REGEN_RATE: float = 8.0
const BASE_PULSE_COST: float = 20.0
const MAX_PULSE_COST: float = 45.0
const MAX_HEALTH: int = 3
const INVULNERABILITY_DURATION: float = 1.5
const ABSORPTION_RANGE: float = 3.0
const ABSORPTION_PROMPT_RANGE: float = 6.0
const ABSORPTION_RATE: float = 52.0
const ABSORPTION_ENERGY_RATE: float = 22.0

var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
var _is_charging_pulse: bool = false
var _pulse_charge_radius: float = PULSE_MIN_RADIUS
var _pulse_cooldown_timer: float = 0.0
var _pulse_visual_timer: float = 0.0
var _is_absorbing: bool = false
var _absorption_target: CharacterBody3D = null
var _animation_clock: float = 0.0
var _walk_distance: float = 0.0
var current_energy: float = MAX_ENERGY
var current_health: int = MAX_HEALTH
var _invulnerability_timer: float = 0.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var model: Node3D = $Model
@onready var pulse_ring: Node3D = get_node_or_null("PulseRing") as Node3D
@onready var absorption_beam: MeshInstance3D = get_node_or_null("AbsorptionBeam") as MeshInstance3D
@onready var absorb_prompt: Label3D = get_node_or_null("AbsorbPrompt") as Label3D
@onready var left_arm: Node3D = get_node_or_null("Model/LeftArmPivot") as Node3D
@onready var right_arm: Node3D = get_node_or_null("Model/RightArmPivot") as Node3D
@onready var left_leg: Node3D = get_node_or_null("Model/LeftLegPivot") as Node3D
@onready var right_leg: Node3D = get_node_or_null("Model/RightLegPivot") as Node3D


func _ready() -> void:
	add_to_group("player")
	_register_move_action("move_forward", KEY_W)
	_register_move_action("move_back", KEY_S)
	_register_move_action("move_left", KEY_A)
	_register_move_action("move_right", KEY_D)
	_register_move_action("dash", KEY_SHIFT)
	_register_move_action("absorb", KEY_F)
	_register_move_action("bloom_pulse", KEY_E)
	_register_mouse_pulse_action("bloom_pulse", MOUSE_BUTTON_RIGHT)
	if absorption_beam:
		absorption_beam.visible = false
	if absorb_prompt:
		absorb_prompt.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	energy_changed.emit(current_energy, MAX_ENERGY)
	health_changed.emit(current_health, MAX_HEALTH)
	absorption_status_changed.emit(0.0, false, false, false)


func _register_move_action(action_name: String, physical_key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var key_event: InputEventKey = InputEventKey.new()
	key_event.physical_keycode = physical_key
	InputMap.action_add_event(action_name, key_event)


func _register_mouse_pulse_action(action_name: String, mouse_button: MouseButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var mouse_event: InputEventMouseButton = InputEventMouseButton.new()
	mouse_event.button_index = mouse_button
	InputMap.action_add_event(action_name, mouse_event)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		camera_pivot.rotation.x = clampf(
			camera_pivot.rotation.x - event.relative.y * MOUSE_SENSITIVITY,
			MIN_CAMERA_PITCH,
			MAX_CAMERA_PITCH
		)


func _physics_process(delta: float) -> void:
	_animation_clock += delta
	_dash_cooldown_timer = maxf(_dash_cooldown_timer - delta, 0.0)
	_pulse_cooldown_timer = maxf(_pulse_cooldown_timer - delta, 0.0)
	_invulnerability_timer = maxf(_invulnerability_timer - delta, 0.0)
	_pulse_visual_timer = maxf(_pulse_visual_timer - delta, 0.0)
	_process_bloom_pulse(delta)
	_process_absorption(delta)

	if current_energy < MAX_ENERGY:
		current_energy = minf(current_energy + ENERGY_REGEN_RATE * delta, MAX_ENERGY)
		energy_changed.emit(current_energy, MAX_ENERGY)

	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var camera_forward: Vector3 = -camera_pivot.global_basis.z
	var camera_right: Vector3 = camera_pivot.global_basis.x
	camera_forward.y = 0.0
	camera_right.y = 0.0
	camera_forward = camera_forward.normalized()
	camera_right = camera_right.normalized()
	var move_direction: Vector3 = camera_right * input_vector.x + camera_forward * -input_vector.y
	if _is_absorbing:
		move_direction = Vector3.ZERO
	if move_direction.length_squared() > 1.0:
		move_direction = move_direction.normalized()

	if Input.is_action_just_pressed("dash") and _dash_cooldown_timer <= 0.0 and not _is_absorbing:
		_dash_direction = move_direction
		if _dash_direction.length_squared() <= 0.001:
			_dash_direction = -model.global_basis.z
			_dash_direction.y = 0.0
		_dash_direction = _dash_direction.normalized()
		_dash_timer = DASH_DURATION
		_dash_cooldown_timer = DASH_COOLDOWN

	if _dash_timer > 0.0:
		var active_dash_delta: float = minf(delta, _dash_timer)
		_dash_timer = maxf(_dash_timer - delta, 0.0)
		var dash_speed: float = DASH_DISTANCE / DASH_DURATION
		var frame_speed_scale: float = active_dash_delta / delta if delta > 0.0 else 0.0
		velocity.x = _dash_direction.x * dash_speed * frame_speed_scale
		velocity.z = _dash_direction.z * dash_speed * frame_speed_scale
	else:
		velocity.x = move_direction.x * MOVE_SPEED
		velocity.z = move_direction.z * MOVE_SPEED

	if not is_on_floor():
		velocity.y -= get_gravity().length() * delta
	else:
		velocity.y = 0.0

	move_and_slide()
	if move_direction.length_squared() > 0.001:
		var target_yaw: float = atan2(-move_direction.x, -move_direction.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_yaw, TURN_SPEED * delta)
	_update_player_animation(delta, move_direction.length_squared() > 0.001 or _dash_timer > 0.0)


func _update_player_animation(delta: float, is_walking: bool) -> void:
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	if is_walking:
		_walk_distance += maxf(horizontal_speed, MOVE_SPEED * 0.45) * delta
	var stride: float = sin(_walk_distance * 2.0) * 0.48 if is_walking else 0.0
	if left_arm:
		left_arm.rotation.x = lerpf(left_arm.rotation.x, -stride * 0.72, 10.0 * delta)
	if right_arm:
		right_arm.rotation.x = lerpf(right_arm.rotation.x, stride * 0.72, 10.0 * delta)
	if left_leg:
		left_leg.rotation.x = lerpf(left_leg.rotation.x, stride, 12.0 * delta)
	if right_leg:
		right_leg.rotation.x = lerpf(right_leg.rotation.x, -stride, 12.0 * delta)
	var idle_breath: float = 0.018 * sin(_animation_clock * 2.2) if not is_walking else 0.025 * absf(stride)
	model.position.y = lerpf(model.position.y, idle_breath, 7.0 * delta)


func _process_absorption(delta: float) -> void:
	var nearest_target: CharacterBody3D = _find_nearest_prowler()
	var target_changed: bool = nearest_target != _absorption_target
	var target_distance: float = INF
	if nearest_target:
		target_distance = _planar_distance_to(nearest_target)
	var available: bool = is_instance_valid(nearest_target)
	var in_range: bool = available and target_distance <= ABSORPTION_RANGE
	var can_absorb: bool = in_range and Input.is_action_pressed("absorb")

	if _is_absorbing and (target_changed or not can_absorb):
		if is_instance_valid(_absorption_target):
			_absorption_target.call("stop_absorption")
		_is_absorbing = false

	_absorption_target = nearest_target
	var progress: float = 0.0
	if can_absorb and is_instance_valid(_absorption_target):
		_is_absorbing = true
		var energy_restored: float = float(_absorption_target.call("absorb_bloom", delta, ABSORPTION_RATE))
		current_energy = minf(current_energy + energy_restored * ABSORPTION_ENERGY_RATE, MAX_ENERGY)
		progress = float(_absorption_target.call("get_absorption_progress"))
		energy_changed.emit(current_energy, MAX_ENERGY)
	elif available:
		progress = float(nearest_target.call("get_absorption_progress"))

	var is_absorbing_target: bool = _is_absorbing and nearest_target == _absorption_target
	_update_absorption_prompt(nearest_target, progress, is_absorbing_target, in_range)
	absorption_status_changed.emit(progress, is_absorbing_target, available, in_range)


func _find_nearest_prowler() -> CharacterBody3D:
	var prowlers: Array[Node] = get_tree().get_nodes_in_group("prowlers")
	var nearest: CharacterBody3D = null
	var nearest_distance: float = ABSORPTION_PROMPT_RANGE
	for prowler_node: Node in prowlers:
		var prowler: CharacterBody3D = prowler_node as CharacterBody3D
		if not is_instance_valid(prowler):
			continue
		if int(prowler.get("state")) == 2:
			continue
		var distance: float = _planar_distance_to(prowler)
		if distance < nearest_distance:
			nearest = prowler
			nearest_distance = distance
	return nearest


func _planar_distance_to(target: Node3D) -> float:
	var offset: Vector3 = target.global_position - global_position
	offset.y = 0.0
	return offset.length()


func _update_absorption_prompt(target: CharacterBody3D, progress: float, active: bool, in_range: bool) -> void:
	if absorb_prompt:
		absorb_prompt.visible = is_instance_valid(target)
		if is_instance_valid(target):
			if active:
				absorb_prompt.text = "BLOOMING  %d%%" % roundi(progress * 100.0)
			elif in_range:
				absorb_prompt.text = "F  ·  HOLD TO ABSORB"
			else:
				absorb_prompt.text = "APPROACH TO BLOOM"
			absorb_prompt.global_position = target.global_position + Vector3(0.0, 3.35, 0.0)
			absorb_prompt.modulate = Color("b8ff9a") if in_range else Color("f1d99a")
	if absorption_beam:
		absorption_beam.visible = active and in_range and is_instance_valid(target)
		if absorption_beam.visible:
			var beam_start: Vector3 = global_position + model.global_basis * Vector3(0.5, 1.0, -0.1)
			var beam_end: Vector3 = target.global_position + Vector3(0.0, 1.25, 0.0)
			var beam_vector: Vector3 = beam_end - beam_start
			var beam_length: float = maxf(beam_vector.length(), 0.1)
			var beam_rotation: Quaternion = Quaternion(Vector3.UP, beam_vector.normalized())
			absorption_beam.global_transform = Transform3D(Basis(beam_rotation), (beam_start + beam_end) * 0.5)
			absorption_beam.scale = Vector3(0.055, beam_length * 0.5, 0.055)


func _process_bloom_pulse(delta: float) -> void:
	if _pulse_cooldown_timer > 0.0 or current_energy < BASE_PULSE_COST:
		if pulse_ring and not _is_charging_pulse and _pulse_visual_timer <= 0.0:
			pulse_ring.visible = false
		return
	if Input.is_action_just_pressed("bloom_pulse"):
		_is_charging_pulse = true
		_pulse_charge_radius = PULSE_MIN_RADIUS
	if _is_charging_pulse and Input.is_action_pressed("bloom_pulse"):
		_pulse_charge_radius = minf(_pulse_charge_radius + PULSE_CHARGE_RATE * delta, PULSE_MAX_RADIUS)
		if pulse_ring:
			pulse_ring.visible = true
			pulse_ring.scale = Vector3(_pulse_charge_radius, 1.0, _pulse_charge_radius)
	if _is_charging_pulse and Input.is_action_just_released("bloom_pulse"):
		var cost: float = lerpf(
			BASE_PULSE_COST,
			MAX_PULSE_COST,
			(_pulse_charge_radius - PULSE_MIN_RADIUS) / (PULSE_MAX_RADIUS - PULSE_MIN_RADIUS)
		)
		if current_energy >= cost:
			current_energy -= cost
			energy_changed.emit(current_energy, MAX_ENERGY)
			execute_bloom_pulse(_pulse_charge_radius)
			_pulse_cooldown_timer = PULSE_COOLDOWN
		_is_charging_pulse = false


func execute_bloom_pulse(radius: float) -> void:
	var pulse_origin: Vector3 = global_position
	if pulse_ring:
		pulse_ring.visible = true
		pulse_ring.scale = Vector3(radius, 1.0, radius)
		_pulse_visual_timer = 0.35
	var creatures: Array[Node] = get_tree().get_nodes_in_group("creatures")
	for creature: Node in creatures:
		if creature.has_method("apply_bloom_pulse"):
			creature.call("apply_bloom_pulse", pulse_origin, radius)
	bloom_pulse_emitted.emit(pulse_origin, radius)


func take_damage(amount: int = 1) -> void:
	if _invulnerability_timer > 0.0 or current_health <= 0:
		return
	current_health = maxi(current_health - amount, 0)
	_invulnerability_timer = INVULNERABILITY_DURATION
	health_changed.emit(current_health, MAX_HEALTH)
	if current_health <= 0:
		player_defeated.emit()
