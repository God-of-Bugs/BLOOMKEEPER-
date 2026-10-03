class_name BloomkeeperRestoredFlower
extends Node3D

const PETAL_COUNT: int = 6

var _petal_material: StandardMaterial3D
var _center_material: StandardMaterial3D
var _stem_material: StandardMaterial3D
var _leaf_material: StandardMaterial3D
var _bloom_clock: float = 0.0
var _petals: Array[MeshInstance3D] = []
var _starting_scale: Vector3 = Vector3.ONE


func _ready() -> void:
	_starting_scale = scale
	scale = Vector3.ZERO
	_create_materials()
	_build_flower()
	var bloom_tween: Tween = create_tween()
	bloom_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	bloom_tween.set_trans(Tween.TRANS_BACK)
	bloom_tween.set_ease(Tween.EASE_OUT)
	bloom_tween.tween_property(self, "scale", _starting_scale, 0.75)


func _process(delta: float) -> void:
	_bloom_clock += delta
	for index: int in range(_petals.size()):
		var petal: MeshInstance3D = _petals[index]
		petal.rotation.z = sin(_bloom_clock * 1.4 + float(index)) * 0.035


func _create_materials() -> void:
	_petal_material = _make_material(Color("f4d264"), Color("f8e58d"), 0.35)
	_center_material = _make_material(Color("f5a940"), Color("ffcb5c"), 1.1)
	_stem_material = _make_material(Color("5a9a50"))
	_leaf_material = _make_material(Color("7dbb62"), Color("b4e98a"), 0.15)


func _build_flower() -> void:
	var stem_mesh: CylinderMesh = CylinderMesh.new()
	stem_mesh.top_radius = 0.065
	stem_mesh.bottom_radius = 0.095
	stem_mesh.height = 0.9
	stem_mesh.radial_segments = 7
	_add_mesh("Stem", stem_mesh, Vector3(0.0, 0.45, 0.0), Vector3.ONE, _stem_material)

	var leaf_mesh: SphereMesh = SphereMesh.new()
	leaf_mesh.radial_segments = 8
	leaf_mesh.rings = 4
	var left_leaf: MeshInstance3D = _add_mesh("LeafLeft", leaf_mesh, Vector3(-0.18, 0.31, 0.02), Vector3(0.38, 0.12, 0.18), _leaf_material)
	left_leaf.rotation.z = 0.38
	left_leaf.rotation.y = -0.45
	var right_leaf: MeshInstance3D = _add_mesh("LeafRight", leaf_mesh, Vector3(0.19, 0.52, 0.0), Vector3(0.34, 0.11, 0.16), _leaf_material)
	right_leaf.rotation.z = -0.45
	right_leaf.rotation.y = 0.5

	var petal_mesh: SphereMesh = SphereMesh.new()
	petal_mesh.radial_segments = 9
	petal_mesh.rings = 5
	for index: int in range(PETAL_COUNT):
		var angle: float = TAU * float(index) / float(PETAL_COUNT)
		var petal_position: Vector3 = Vector3(cos(angle) * 0.37, 1.02 + sin(angle) * 0.06, sin(angle) * 0.37)
		var petal: MeshInstance3D = _add_mesh("Petal%d" % index, petal_mesh, petal_position, Vector3(0.34, 0.16, 0.23), _petal_material)
		petal.rotation.y = -angle
		petal.rotation.z = cos(angle) * -0.18
		_petals.append(petal)

	var center_mesh: SphereMesh = SphereMesh.new()
	center_mesh.radial_segments = 10
	center_mesh.rings = 6
	_add_mesh("FlowerHeart", center_mesh, Vector3(0.0, 1.04, 0.0), Vector3(0.25, 0.23, 0.25), _center_material)

	var bloom_light: OmniLight3D = OmniLight3D.new()
	bloom_light.name = "FlowerGlow"
	bloom_light.light_color = Color("ffe39b")
	bloom_light.light_energy = 0.8
	bloom_light.omni_range = 4.0
	bloom_light.position = Vector3(0.0, 1.0, 0.0)
	add_child(bloom_light)


func _add_mesh(mesh_name: String, mesh: Mesh, mesh_position: Vector3, mesh_scale: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = mesh
	instance.position = mesh_position
	instance.scale = mesh_scale
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance


func _make_material(albedo: Color, glow: Color = Color.BLACK, glow_strength: float = 0.0) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.75
	if glow_strength > 0.0:
		material.emission_enabled = true
		material.emission = glow
		material.emission_energy_multiplier = glow_strength
	return material
