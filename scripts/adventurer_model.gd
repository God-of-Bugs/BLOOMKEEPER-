class_name BloomkeeperAdventurerModel
extends Node3D

var _skin: StandardMaterial3D
var _hood: StandardMaterial3D
var _cloth: StandardMaterial3D
var _cloak: StandardMaterial3D
var _leather: StandardMaterial3D
var _gold: StandardMaterial3D
var _eye: StandardMaterial3D


func _ready() -> void:
	var old_body: MeshInstance3D = get_node_or_null("Body") as MeshInstance3D
	var old_head: MeshInstance3D = get_node_or_null("Head") as MeshInstance3D
	if old_body:
		old_body.visible = false
	if old_head:
		old_head.visible = false
	_skin = _material(Color("d7a985"))
	_hood = _material(Color("8a5a3e"))
	_cloth = _material(Color("335f53"))
	_cloak = _material(Color("25473f"))
	_leather = _material(Color("4a3429"))
	_gold = _material(Color("dba85e"), Color("f1bd62"), 0.35)
	_eye = _material(Color("332a29"))
	_build_torso()
	_build_head()
	_build_gear()
	_build_limbs()
	_build_glow()


func _build_torso() -> void:
	_add_sphere("Tunic", Vector3(0.0, 0.91, 0.0), Vector3(0.39, 0.61, 0.29), _cloth, 10, 5)
	_add_sphere("Cloak", Vector3(0.0, 0.91, 0.22), Vector3(0.42, 0.64, 0.18), _cloak, 8, 4)
	var tunic_front: MeshInstance3D = _add_capsule("FrontTunicPanel", Vector3(0.0, 0.91, -0.25), 0.21, 0.91, _cloth)
	tunic_front.scale = Vector3(0.88, 1.0, 0.25)
	_add_cylinder("LeatherBelt", Vector3(0.0, 0.67, 0.0), 0.32, 0.32, 0.11, _leather, 9)
	_add_sphere("BeltBuckle", Vector3(0.0, 0.68, -0.326), Vector3(0.075, 0.08, 0.045), _gold, 7, 3)
	_add_sphere("ShoulderMantle", Vector3(0.0, 1.31, 0.0), Vector3(0.46, 0.19, 0.34), _hood, 9, 4)
	_add_sphere("Satchel", Vector3(-0.32, 0.95, 0.1), Vector3(0.19, 0.26, 0.2), _leather, 8, 4)
	_add_sphere("LightAmulet", Vector3(0.0, 1.17, -0.326), Vector3(0.12, 0.15, 0.07), _gold, 8, 4)


func _build_head() -> void:
	_add_sphere("Face", Vector3(0.0, 1.76, -0.01), Vector3(0.285, 0.32, 0.27), _skin, 10, 6)
	_add_sphere("HairCap", Vector3(0.0, 1.96, 0.035), Vector3(0.34, 0.22, 0.31), _hood, 9, 4)
	_add_sphere("HoodBack", Vector3(0.0, 1.78, 0.16), Vector3(0.33, 0.4, 0.25), _hood, 9, 5)
	_add_sphere("EarLeft", Vector3(-0.29, 1.76, 0.0), Vector3(0.08, 0.12, 0.09), _skin, 7, 3)
	_add_sphere("EarRight", Vector3(0.29, 1.76, 0.0), Vector3(0.08, 0.12, 0.09), _skin, 7, 3)
	_add_sphere("EyeLeft", Vector3(-0.105, 1.78, -0.255), Vector3(0.035, 0.052, 0.025), _eye, 7, 3)
	_add_sphere("EyeRight", Vector3(0.105, 1.78, -0.255), Vector3(0.035, 0.052, 0.025), _eye, 7, 3)
	_add_sphere("Nose", Vector3(0.0, 1.72, -0.295), Vector3(0.055, 0.07, 0.045), _skin, 7, 3)


func _build_gear() -> void:
	_add_capsule("ScarfTail", Vector3(0.0, 1.36, 0.2), 0.09, 0.62, _gold)
	var scarf_tail: MeshInstance3D = get_node("ScarfTail") as MeshInstance3D
	scarf_tail.rotation.x = -0.62
	scarf_tail.scale = Vector3(0.75, 1.0, 0.72)
	_add_sphere("LanternHandle", Vector3(0.53, 1.11, -0.02), Vector3(0.045, 0.31, 0.045), _leather, 7, 3)
	_add_sphere("LanternCore", Vector3(0.55, 0.84, -0.03), Vector3(0.105, 0.15, 0.105), _gold, 8, 4)


func _build_limbs() -> void:
	var left_arm: Node3D = _create_joint("LeftArmPivot", Vector3(-0.39, 1.27, 0.0))
	var right_arm: Node3D = _create_joint("RightArmPivot", Vector3(0.39, 1.27, 0.0))
	_add_capsule_to(left_arm, "LeftSleeve", Vector3(0.0, -0.28, 0.0), 0.14, 0.66, _cloth, Vector3(0.92, 1.0, 0.92))
	_add_sphere_to(left_arm, "LeftHand", Vector3(0.0, -0.58, -0.01), Vector3(0.115, 0.13, 0.12), _skin)
	_add_capsule_to(right_arm, "RightSleeve", Vector3(0.0, -0.28, 0.0), 0.14, 0.66, _cloth, Vector3(0.92, 1.0, 0.92))
	_add_sphere_to(right_arm, "RightHand", Vector3(0.0, -0.58, -0.01), Vector3(0.115, 0.13, 0.12), _skin)
	var left_leg: Node3D = _create_joint("LeftLegPivot", Vector3(-0.17, 0.48, 0.0))
	var right_leg: Node3D = _create_joint("RightLegPivot", Vector3(0.17, 0.48, 0.0))
	_add_capsule_to(left_leg, "LeftTrouser", Vector3(0.0, -0.17, 0.0), 0.13, 0.49, _leather, Vector3(0.88, 1.0, 0.95))
	_add_sphere_to(left_leg, "LeftBoot", Vector3(0.0, -0.39, -0.095), Vector3(0.16, 0.13, 0.23), _hood)
	_add_capsule_to(right_leg, "RightTrouser", Vector3(0.0, -0.17, 0.0), 0.13, 0.49, _leather, Vector3(0.88, 1.0, 0.95))
	_add_sphere_to(right_leg, "RightBoot", Vector3(0.0, -0.39, -0.095), Vector3(0.16, 0.13, 0.23), _hood)


func _build_glow() -> void:
	var lantern_light: OmniLight3D = OmniLight3D.new()
	lantern_light.name = "LanternGlow"
	lantern_light.light_color = Color("f4c979")
	lantern_light.light_energy = 0.8
	lantern_light.omni_range = 4.0
	lantern_light.position = Vector3(0.55, 0.9, -0.08)
	add_child(lantern_light)


func _create_joint(joint_name: String, joint_position: Vector3) -> Node3D:
	var joint: Node3D = Node3D.new()
	joint.name = joint_name
	joint.position = joint_position
	add_child(joint)
	return joint


func _add_sphere(mesh_name: String, mesh_position: Vector3, mesh_scale: Vector3, material: StandardMaterial3D, segments: int, rings: int) -> MeshInstance3D:
	return _add_sphere_to(self, mesh_name, mesh_position, mesh_scale, material, segments, rings)


func _add_sphere_to(parent_node: Node3D, mesh_name: String, mesh_position: Vector3, mesh_scale: Vector3, material: StandardMaterial3D, segments: int = 8, rings: int = 4) -> MeshInstance3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = segments
	sphere.rings = rings
	mesh_instance.mesh = sphere
	mesh_instance.position = mesh_position
	mesh_instance.scale = mesh_scale
	mesh_instance.material_override = material
	parent_node.add_child(mesh_instance)
	return mesh_instance


func _add_capsule(mesh_name: String, mesh_position: Vector3, radius: float, height: float, material: StandardMaterial3D) -> MeshInstance3D:
	return _add_capsule_to(self, mesh_name, mesh_position, radius, height, material)


func _add_capsule_to(parent_node: Node3D, mesh_name: String, mesh_position: Vector3, radius: float, height: float, material: StandardMaterial3D, mesh_scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var capsule: CapsuleMesh = CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = height
	capsule.radial_segments = 8
	capsule.rings = 4
	mesh_instance.mesh = capsule
	mesh_instance.position = mesh_position
	mesh_instance.scale = mesh_scale
	mesh_instance.material_override = material
	parent_node.add_child(mesh_instance)
	return mesh_instance


func _add_cylinder(mesh_name: String, mesh_position: Vector3, top_radius: float, bottom_radius: float, height: float, material: StandardMaterial3D, segments: int) -> MeshInstance3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = top_radius
	cylinder.bottom_radius = bottom_radius
	cylinder.height = height
	cylinder.radial_segments = segments
	mesh_instance.mesh = cylinder
	mesh_instance.position = mesh_position
	mesh_instance.material_override = material
	add_child(mesh_instance)
	return mesh_instance


func _material(albedo: Color, glow: Color = Color.BLACK, glow_energy: float = 0.0) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.88
	if glow_energy > 0.0:
		material.emission_enabled = true
		material.emission = glow
		material.emission_energy_multiplier = glow_energy
	return material
