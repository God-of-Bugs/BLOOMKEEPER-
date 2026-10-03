class_name BloomkeeperProwlerModel
extends Node3D

var _bark: StandardMaterial3D
var _bark_light: StandardMaterial3D
var _root_material: StandardMaterial3D
var _ember: StandardMaterial3D
var _eye: StandardMaterial3D
var _moss: StandardMaterial3D


func _ready() -> void:
	var old_body: MeshInstance3D = get_node_or_null("Body") as MeshInstance3D
	var old_crest: MeshInstance3D = get_node_or_null("Crest") as MeshInstance3D
	if old_body:
		old_body.visible = false
	if old_crest:
		old_crest.visible = false
	_bark = _material(Color("34251f"))
	_bark_light = _material(Color("493327"))
	_root_material = _material(Color("64402f"))
	_ember = _material(Color("cb4935"), Color("f04a3b"), 2.0)
	_eye = _material(Color("f4ca72"), Color("ffb543"), 3.2)
	_moss = _material(Color("40513a"))
	_build_body()
	_build_head()
	_build_roots()
	_build_growths()


func _build_body() -> void:
	_add_sphere("BarkCore", Vector3(0.0, 0.98, 0.02), Vector3(0.48, 0.69, 0.39), _bark, 9, 5)
	_add_sphere("BarkPlate", Vector3(0.0, 1.07, -0.31), Vector3(0.43, 0.55, 0.16), _bark_light, 8, 4)
	_add_capsule("Muzzle", Vector3(0.0, 0.63, -0.48), 0.25, 0.55, _bark_light, Vector3(1.1, 0.7, 0.75))
	_add_sphere("Scar", Vector3(0.0, 1.13, -0.48), Vector3(0.23, 0.09, 0.05), _ember, 7, 3)
	_add_sphere("EyeLeft", Vector3(-0.25, 1.46, -0.29), Vector3(0.075, 0.08, 0.045), _eye, 7, 3)
	_add_sphere("EyeRight", Vector3(0.25, 1.46, -0.29), Vector3(0.075, 0.08, 0.045), _eye, 7, 3)
	_add_sphere("ShoulderBurlLeft", Vector3(-0.45, 1.42, 0.0), Vector3(0.22, 0.25, 0.25), _bark_light, 8, 4)
	_add_sphere("ShoulderBurlRight", Vector3(0.45, 1.42, 0.0), Vector3(0.22, 0.25, 0.25), _bark_light, 8, 4)
	_add_sphere("MossBrow", Vector3(0.0, 1.7, -0.12), Vector3(0.43, 0.12, 0.32), _moss, 8, 4)


func _build_head() -> void:
	_add_sphere("WoodSkull", Vector3(0.0, 1.78, -0.02), Vector3(0.44, 0.45, 0.36), _bark, 9, 5)
	_add_sphere("BrowPlate", Vector3(0.0, 1.99, -0.15), Vector3(0.43, 0.17, 0.31), _bark_light, 8, 4)
	_add_capsule("Snout", Vector3(0.0, 1.69, -0.36), 0.22, 0.48, _bark_light, Vector3(1.25, 0.8, 0.8))
	_add_sphere("EyeLeft", Vector3(-0.21, 1.84, -0.345), Vector3(0.07, 0.085, 0.045), _eye, 7, 3)
	_add_sphere("EyeRight", Vector3(0.21, 1.84, -0.345), Vector3(0.07, 0.085, 0.045), _eye, 7, 3)
	_add_capsule("RootAntlerLeft", Vector3(-0.31, 2.23, 0.04), 0.12, 0.72, _root_material, Vector3(0.9, 1.0, 0.9))
	_add_capsule("RootAntlerRight", Vector3(0.31, 2.23, 0.04), 0.12, 0.72, _root_material, Vector3(0.9, 1.0, 0.9))
	_add_sphere("AntlerTipLeft", Vector3(-0.39, 2.57, 0.0), Vector3(0.11, 0.14, 0.1), _root_material, 7, 3)
	_add_sphere("AntlerTipRight", Vector3(0.39, 2.57, 0.0), Vector3(0.11, 0.14, 0.1), _root_material, 7, 3)


func _build_roots() -> void:
	var left_root: Node3D = _create_joint("LeftRootPivot", Vector3(-0.49, 1.44, -0.04))
	var right_root: Node3D = _create_joint("RightRootPivot", Vector3(0.49, 1.44, -0.04))
	_add_capsule_to(left_root, "LeftRoot", Vector3(0.0, -0.34, 0.0), 0.15, 0.85, _root_material, Vector3(1.0, 1.0, 1.0))
	_add_sphere_to(left_root, "LeftClaw", Vector3(-0.06, -0.72, -0.025), Vector3(0.16, 0.18, 0.16), _bark_light)
	_add_capsule_to(right_root, "RightRoot", Vector3(0.0, -0.34, 0.0), 0.15, 0.85, _root_material, Vector3(1.0, 1.0, 1.0))
	_add_sphere_to(right_root, "RightClaw", Vector3(0.06, -0.72, -0.025), Vector3(0.16, 0.18, 0.16), _bark_light)
	var left_leg: Node3D = _create_joint("LeftLegPivot", Vector3(-0.2, 0.48, 0.01))
	var right_leg: Node3D = _create_joint("RightLegPivot", Vector3(0.2, 0.48, 0.01))
	_add_capsule_to(left_leg, "LeftLeg", Vector3(0.0, -0.2, 0.0), 0.15, 0.58, _bark, Vector3(1.0, 1.0, 0.9))
	_add_sphere_to(left_leg, "LeftFoot", Vector3(0.0, -0.47, -0.07), Vector3(0.17, 0.12, 0.24), _root_material)
	_add_capsule_to(right_leg, "RightLeg", Vector3(0.0, -0.2, 0.0), 0.15, 0.58, _bark, Vector3(1.0, 1.0, 0.9))
	_add_sphere_to(right_leg, "RightFoot", Vector3(0.0, -0.47, -0.07), Vector3(0.17, 0.12, 0.24), _root_material)


func _build_growths() -> void:
	for index: int in range(4):
		var side: float = -1.0 if index % 2 == 0 else 1.0
		var height: float = 0.82 + float(index) * 0.18
		_add_sphere("BarkKnot%d" % index, Vector3(side * (0.38 + float(index % 2) * 0.13), height, 0.02), Vector3(0.14, 0.18, 0.12), _root_material if index % 2 == 0 else _moss, 7, 3)
	_add_sphere("BackEmber", Vector3(0.0, 1.44, 0.39), Vector3(0.12, 0.17, 0.06), _ember, 7, 3)


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


func _add_capsule(mesh_name: String, mesh_position: Vector3, radius: float, height: float, material: StandardMaterial3D, mesh_scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	return _add_capsule_to(self, mesh_name, mesh_position, radius, height, material, mesh_scale)


func _add_capsule_to(parent_node: Node3D, mesh_name: String, mesh_position: Vector3, radius: float, height: float, material: StandardMaterial3D, mesh_scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var capsule: CapsuleMesh = CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = height
	capsule.radial_segments = 7
	capsule.rings = 4
	mesh_instance.mesh = capsule
	mesh_instance.position = mesh_position
	mesh_instance.scale = mesh_scale
	mesh_instance.material_override = material
	parent_node.add_child(mesh_instance)
	return mesh_instance


func _material(albedo: Color, glow: Color = Color.BLACK, glow_energy: float = 0.0) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.97
	if glow_energy > 0.0:
		material.emission_enabled = true
		material.emission = glow
		material.emission_energy_multiplier = glow_energy
	return material
