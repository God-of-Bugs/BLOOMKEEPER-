class_name BloomkeeperPlayer
extends CharacterBody3D

const MOVE_SPEED: float = 5.0
const TURN_SPEED: float = 10.0
const MOUSE_SENSITIVITY: float = 0.003
const MIN_CAMERA_PITCH: float = deg_to_rad(-65.0)
const MAX_CAMERA_PITCH: float = deg_to_rad(15.0)
const DASH_DISTANCE: float = 1.8
const DASH_DURATION: float = 0.22
const DASH_COOLDOWN: float = 1.2

var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO

@onready var camera_pivot: Node3D = $CameraPivot
@onready var model: Node3D = $Model


func _ready() -> void:
	add_to_group("player")
	_register_move_action("move_forward", KEY_W)
	_register_move_action("move_back", KEY_S)
	_register_move_action("move_left", KEY_A)
	_register_move_action("move_right", KEY_D)
	_register_move_action("dash", KEY_SHIFT)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _register_move_action(action_name: String, physical_key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var key_event: InputEventKey = InputEventKey.new()
	key_event.physical_keycode = physical_key
	InputMap.action_add_event(action_name, key_event)


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
	_dash_cooldown_timer = maxf(_dash_cooldown_timer - delta, 0.0)
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var camera_forward: Vector3 = -camera_pivot.global_basis.z
	var camera_right: Vector3 = camera_pivot.global_basis.x
	camera_forward.y = 0.0
	camera_right.y = 0.0
	camera_forward = camera_forward.normalized()
	camera_right = camera_right.normalized()

	var move_direction: Vector3 = camera_right * input_vector.x + camera_forward * -input_vector.y
	if move_direction.length_squared() > 1.0:
		move_direction = move_direction.normalized()

	if Input.is_action_just_pressed("dash") and _dash_cooldown_timer <= 0.0:
		_dash_direction = move_direction
		if _dash_direction.length_squared() <= 0.001:
			_dash_direction = -model.global_basis.z
			_dash_direction.y = 0.0
		_dash_direction = _dash_direction.normalized()
		_dash_timer = DASH_DURATION
		_dash_cooldown_timer = DASH_COOLDOWN

	if _dash_timer > 0.0:
		_dash_timer = maxf(_dash_timer - delta, 0.0)
		velocity.x = _dash_direction.x * (DASH_DISTANCE / DASH_DURATION)
		velocity.z = _dash_direction.z * (DASH_DISTANCE / DASH_DURATION)
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
