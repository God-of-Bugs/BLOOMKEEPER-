class_name BloomkeeperForestArena
extends Node3D

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _tree_root: Node3D
var _canopy_material: StandardMaterial3D
var _canopy_highlight_material: StandardMaterial3D
var _groundcover_material: StandardMaterial3D
var _firefly_material: StandardMaterial3D
var _floor_material: StandardMaterial3D
var _firefly_mesh_instance: MultiMeshInstance3D = null
var _firefly_base_transforms: Array[Transform3D] = []
var _firefly_clock: float = 0.0
const BloomkeeperFlower = preload("res://scripts/restored_flower.gd")

var _restored: bool = false
var _restoration_blooms: Array[Node3D] = []


func _process(delta: float) -> void:
	_firefly_clock += delta
	if not is_instance_valid(_firefly_mesh_instance) or _firefly_base_transforms.is_empty():
		return
	for index: int in range(_firefly_base_transforms.size()):
		var base_transform: Transform3D = _firefly_base_transforms[index]
		var bob: float = sin(_firefly_clock * 1.3 + float(index) * 0.71) * 0.19
		var sway: float = sin(_firefly_clock * 0.8 + float(index) * 0.39) * 0.14
		var animated_transform: Transform3D = base_transform
		animated_transform.origin += Vector3(sway, bob, cos(_firefly_clock + float(index)) * 0.1)
		_firefly_mesh_instance.multimesh.set_instance_transform(index, animated_transform)


func _ready() -> void:
	_rng.seed = 4107
	_tree_root = Node3D.new()
	_tree_root.name = "ProceduralForest"
	add_child(_tree_root)
	_create_materials()
	_build_forest_ring()
	_build_inner_groves()
	_build_groundcover()
	_build_fireflies()


func _create_materials() -> void:
	_canopy_material = _make_material(Color("193a32"))
	_canopy_highlight_material = _make_material(Color("244b3b"))
	_groundcover_material = _make_material(Color("294633"))
	_floor_material = _make_material(Color("19291f"))
	_firefly_material = _make_material(Color("b5e99a"), Color("a9ff8a"), 2.5)

	var ground: MeshInstance3D = get_node_or_null("../Ground/MeshInstance3D") as MeshInstance3D
	if ground:
		ground.material_override = _floor_material


func _build_forest_ring() -> void:
	var placements: Array[Vector3] = []
	for index: int in range(17):
		var along_edge: float = lerpf(-27.0, 27.0, float(index) / 16.0)
		placements.append(Vector3(along_edge + _rng.randf_range(-1.4, 1.4), 0.0, -28.0 + _rng.randf_range(-1.4, 1.4)))
		placements.append(Vector3(along_edge + _rng.randf_range(-1.4, 1.4), 0.0, 28.0 + _rng.randf_range(-1.4, 1.4)))
		placements.append(Vector3(-28.0 + _rng.randf_range(-1.4, 1.4), 0.0, along_edge + _rng.randf_range(-1.4, 1.4)))
		placements.append(Vector3(28.0 + _rng.randf_range(-1.4, 1.4), 0.0, along_edge + _rng.randf_range(-1.4, 1.4)))

	var inner_positions: Array[Vector3] = [
		Vector3(-23.0, 0.0, -12.0), Vector3(-12.0, 0.0, -23.0),
		Vector3(12.0, 0.0, -23.0), Vector3(23.0, 0.0, -12.0),
		Vector3(23.0, 0.0, 12.0), Vector3(12.0, 0.0, 23.0),
		Vector3(-12.0, 0.0, 23.0), Vector3(-23.0, 0.0, 12.0)
	]
	placements.append_array(inner_positions)
	_add_trees(placements)


func _build_inner_groves() -> void:
	var grove_centers: Array[Vector3] = [
		Vector3(-13.0, 0.0, -13.0), Vector3(13.0, 0.0, -13.0),
		Vector3(-13.0, 0.0, 13.0), Vector3(13.0, 0.0, 13.0)
	]
	var positions: Array[Vector3] = []
	for center: Vector3 in grove_centers:
		for index: int in range(3):
			var angle: float = _rng.randf_range(0.0, TAU)
			var distance: float = _rng.randf_range(3.2, 5.4)
			positions.append(center + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance))
	_add_trees(positions)


func _add_trees(positions: Array[Vector3]) -> void:
	var trunks: Array[Transform3D] = []
	var branches: Array[Transform3D] = []
	var canopies: Array[Transform3D] = []
	var high_canopies: Array[Transform3D] = []
	var leaves: Array[Transform3D] = []
	for tree_position: Vector3 in positions:
		var tree_scale: float = _rng.randf_range(0.82, 1.28)
		var tree_height: float = _rng.randf_range(6.2, 9.1) * tree_scale
		var yaw: float = _rng.randf_range(0.0, TAU)
		var tree_basis: Basis = Basis(Vector3.UP, yaw)
		trunks.append(Transform3D(tree_basis.scaled(Vector3(1.0 * tree_scale, tree_height, 1.0 * tree_scale)), Vector3(tree_position.x, tree_height * 0.5, tree_position.z)))

		for branch_index: int in range(3):
			var branch_yaw: float = yaw + float(branch_index) * TAU / 3.0
			var branch_basis: Basis = Basis(Vector3.UP, branch_yaw).rotated(Vector3.FORWARD, -0.78)
			var branch_height: float = tree_height * (0.49 + float(branch_index % 2) * 0.11)
			var branch_transform: Transform3D = Transform3D(
				branch_basis.scaled(Vector3(0.66 * tree_scale, 2.25 * tree_scale, 0.66 * tree_scale)),
				Vector3(tree_position.x, branch_height, tree_position.z)
			)
			branches.append(branch_transform)

		for canopy_index: int in range(3):
			var canopy_angle: float = yaw + float(canopy_index) * TAU / 3.0
			var canopy_offset: Vector3 = Vector3(cos(canopy_angle) * 1.05, 0.0, sin(canopy_angle) * 1.05) * tree_scale
			var canopy_scale: Vector3 = Vector3(1.7, 1.42, 1.75) * tree_scale
			var canopy_origin: Vector3 = Vector3(tree_position.x, tree_height * 0.82, tree_position.z) + canopy_offset
			canopies.append(Transform3D(Basis(Vector3.UP, canopy_angle).scaled(canopy_scale), canopy_origin))

		var upper_scale: Vector3 = Vector3(1.62, 1.42, 1.62) * tree_scale
		var upper_origin: Vector3 = Vector3(tree_position.x, tree_height * 1.02, tree_position.z)
		high_canopies.append(Transform3D(tree_basis.scaled(upper_scale), upper_origin))
		for leaf_index: int in range(5):
			var leaf_angle: float = yaw + float(leaf_index) * TAU / 5.0
			var leaf_position: Vector3 = Vector3(tree_position.x, tree_height * 0.76, tree_position.z) + Vector3(cos(leaf_angle) * tree_scale, 0.0, sin(leaf_angle) * tree_scale)
			var leaf_basis: Basis = Basis(Vector3.UP, leaf_angle).scaled(Vector3(0.34, 0.09, 0.15) * tree_scale)
			leaves.append(Transform3D(leaf_basis, leaf_position))

	var trunk_mesh: CylinderMesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.24
	trunk_mesh.bottom_radius = 0.48
	trunk_mesh.height = 1.0
	trunk_mesh.radial_segments = 7
	trunk_mesh.rings = 1
	_add_multimesh("TreeTrunks", trunk_mesh, trunks, _make_material(Color("493628")))

	var branch_mesh: CapsuleMesh = CapsuleMesh.new()
	branch_mesh.radius = 0.19
	branch_mesh.height = 1.0
	branch_mesh.radial_segments = 7
	branch_mesh.rings = 3
	_add_multimesh("TreeBranches", branch_mesh, branches, _make_material(Color("493628")))

	var canopy_mesh: SphereMesh = SphereMesh.new()
	canopy_mesh.radius = 1.0
	canopy_mesh.height = 2.0
	canopy_mesh.radial_segments = 8
	canopy_mesh.rings = 4
	_add_multimesh("CanopyClusters", canopy_mesh, canopies, _canopy_material)
	_add_multimesh("HighCanopies", canopy_mesh, high_canopies, _canopy_highlight_material)
	var leaf_mesh: SphereMesh = SphereMesh.new()
	leaf_mesh.radius = 1.0
	leaf_mesh.height = 2.0
	leaf_mesh.radial_segments = 7
	leaf_mesh.rings = 3
	_add_multimesh("CanopyLeafClusters", leaf_mesh, leaves, _canopy_highlight_material)


func _build_groundcover() -> void:
	var leaves: Array[Transform3D] = []
	var mushrooms: Array[Transform3D] = []
	var mushroom_stems: Array[Transform3D] = []
	for index: int in range(170):
		var x_position: float = _rng.randf_range(-26.0, 26.0)
		var z_position: float = _rng.randf_range(-26.0, 26.0)
		if absf(x_position) < 10.0 or absf(z_position) < 10.0:
			continue
		var leaf_yaw: float = _rng.randf_range(0.0, TAU)
		var leaf_scale: Vector3 = Vector3(_rng.randf_range(0.22, 0.45), 0.055, _rng.randf_range(0.12, 0.24))
		leaves.append(Transform3D(Basis(Vector3.UP, leaf_yaw).scaled(leaf_scale), Vector3(x_position, 0.13, z_position)))

		if index % 8 == 0:
			var mushroom_position: Vector3 = Vector3(x_position + 0.35, 0.20, z_position - 0.25)
			mushrooms.append(Transform3D(Basis().scaled(Vector3(0.2, 0.13, 0.2)), mushroom_position + Vector3(0.0, 0.15, 0.0)))
			mushroom_stems.append(Transform3D(Basis().scaled(Vector3(0.075, 0.19, 0.075)), mushroom_position))

	var leaf_mesh: SphereMesh = SphereMesh.new()
	leaf_mesh.radius = 1.0
	leaf_mesh.height = 2.0
	leaf_mesh.radial_segments = 7
	leaf_mesh.rings = 3
	_add_multimesh("MossTufts", leaf_mesh, leaves, _groundcover_material)

	var mushroom_mesh: SphereMesh = SphereMesh.new()
	mushroom_mesh.radius = 1.0
	mushroom_mesh.height = 2.0
	mushroom_mesh.radial_segments = 7
	mushroom_mesh.rings = 3
	_add_multimesh("MushroomCaps", mushroom_mesh, mushrooms, _make_material(Color("9e5960")))
	_add_multimesh("MushroomStems", mushroom_mesh, mushroom_stems, _make_material(Color("c5b691")))


func _build_fireflies() -> void:
	var fireflies: Array[Transform3D] = []
	for index: int in range(68):
		var firefly_position: Vector3 = Vector3(
			_rng.randf_range(-25.0, 25.0),
			_rng.randf_range(0.75, 3.1),
			_rng.randf_range(-25.0, 25.0)
		)
		var firefly_scale: float = _rng.randf_range(0.045, 0.11)
		fireflies.append(Transform3D(Basis().scaled(Vector3.ONE * firefly_scale), firefly_position))
	var firefly_mesh: SphereMesh = SphereMesh.new()
	firefly_mesh.radius = 1.0
	firefly_mesh.height = 2.0
	firefly_mesh.radial_segments = 6
	firefly_mesh.rings = 3
	_firefly_base_transforms = fireflies.duplicate()
	_firefly_mesh_instance = _add_multimesh("Fireflies", firefly_mesh, fireflies, _firefly_material)


func _add_multimesh(node_name: String, mesh: Mesh, transforms: Array[Transform3D], material: StandardMaterial3D) -> MultiMeshInstance3D:
	if transforms.is_empty():
		return null
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index: int in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.material_override = material
	_tree_root.add_child(instance)
	return instance


func _make_material(albedo: Color, glow: Color = Color.BLACK, glow_energy: float = 0.0) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.94
	if glow_energy > 0.0:
		material.emission_enabled = true
		material.emission = glow
		material.emission_energy_multiplier = glow_energy
	return material


func restore_forest() -> void:
	if _restored:
		return
	_restored = true
	var restoration_tween: Tween = create_tween()
	restoration_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	restoration_tween.set_parallel(true)
	restoration_tween.tween_property(_canopy_material, "albedo_color", Color("47774d"), 2.2)
	restoration_tween.tween_property(_canopy_highlight_material, "albedo_color", Color("6b9856"), 2.2)
	restoration_tween.tween_property(_groundcover_material, "albedo_color", Color("61804b"), 2.2)
	restoration_tween.tween_property(_floor_material, "albedo_color", Color("40513b"), 2.2)
	restoration_tween.tween_property(_firefly_material, "emission_energy_multiplier", 3.8, 2.2)
	var bloom_positions: Array[Vector3] = [
		Vector3(-5.2, 0.0, -11.5), Vector3(5.2, 0.0, -11.5),
		Vector3(-11.5, 0.0, -5.2), Vector3(11.5, 0.0, 5.2),
		Vector3(-11.5, 0.0, 5.2), Vector3(11.5, 0.0, -5.2),
		Vector3(-5.2, 0.0, 11.5), Vector3(5.2, 0.0, 11.5)
	]
	for bloom_position: Vector3 in bloom_positions:
		var bloom: Node3D = BloomkeeperFlower.new() as Node3D
		bloom.name = "ForestRestorationBloom"
		_tree_root.add_child(bloom)
		bloom.position = bloom_position
		_restoration_blooms.append(bloom)
	print("The forest canopy warms as the last Prowler blooms; new flowers emerge across the sanctuary.")
