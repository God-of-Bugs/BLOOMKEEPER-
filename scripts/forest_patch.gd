class_name BloomkeeperForestPatch
extends Node3D

@export var patch_radius: float = 5.0

var _restored_material: StandardMaterial3D
var _clearing_material: StandardMaterial3D
var _clearing_mesh_instance: MeshInstance3D
var _bloom_light: OmniLight3D
var _restored: bool = false


func _ready() -> void:
	_clearing_mesh_instance = MeshInstance3D.new()
	_clearing_mesh_instance.name = "RestoredClearing"
	var clearing_mesh: CylinderMesh = CylinderMesh.new()
	clearing_mesh.top_radius = patch_radius
	clearing_mesh.bottom_radius = patch_radius
	clearing_mesh.height = 0.035
	clearing_mesh.radial_segments = 24
	_clearing_mesh_instance.mesh = clearing_mesh
	_clearing_mesh_instance.position.y = 0.035
	_clearing_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_clearing_material = StandardMaterial3D.new()
	_clearing_material.albedo_color = Color("27392e")
	_clearing_material.roughness = 1.0
	_clearing_mesh_instance.material_override = _clearing_material
	add_child(_clearing_mesh_instance)

	_restored_material = StandardMaterial3D.new()
	_restored_material.albedo_color = Color("688c50")
	_restored_material.roughness = 0.9
	_bloom_light = OmniLight3D.new()
	_bloom_light.name = "BloomLight"
	_bloom_light.light_color = Color("a6df83")
	_bloom_light.light_energy = 0.0
	_bloom_light.omni_range = patch_radius * 1.8
	_bloom_light.position.y = 0.8
	add_child(_bloom_light)


func restore() -> void:
	if _restored:
		return
	_restored = true
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(_clearing_material, "albedo_color", _restored_material.albedo_color, 1.3)
	tween.tween_property(_bloom_light, "light_energy", 1.8, 1.3)
