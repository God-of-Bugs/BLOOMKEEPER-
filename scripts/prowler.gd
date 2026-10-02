class_name BloomkeeperProwler
extends CharacterBody3D

enum State { AGGRESSIVE, CALMING, PACIFIED }

@export var state: State = State.AGGRESSIVE
@export var chase_speed: float = 3.2
@export var turn_speed: float = 8.0
@export var stopping_distance: float = 1.05

var target_player: Node3D = null


func _ready() -> void:
	add_to_group("creatures")
	add_to_group("prowlers")


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
