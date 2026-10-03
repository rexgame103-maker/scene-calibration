@tool
class_name ReconstructionZone
extends Area3D


signal satisfaction_changed(zone_id: String, is_satisfied: bool)

enum ZoneType {
	FIXED_POSITION,
	FURNITURE_RELATION
}

@export_group("Condition")
@export var zone_id := "zone_new":
	set(value):
		zone_id = value.strip_edges()
@export var required_furniture_id := "":
	set(value):
		required_furniture_id = value.strip_edges()
@export var zone_type := ZoneType.FIXED_POSITION

@export_group("Bounds")
@export var zone_size := Vector3(1.0, 2.5, 1.0):
	set(value):
		zone_size = Vector3(maxf(0.05, value.x), maxf(0.05, value.y), maxf(0.05, value.z))
		_sync_zone_geometry()

@export_group("Orientation")
@export var require_orientation := false
@export_range(0.0, 180.0, 1.0) var orientation_tolerance_degrees := 15.0
@export_range(-180.0, 180.0, 1.0) var target_yaw_degrees := 0.0

@export_group("Editor Preview")
@export var show_editor_preview := true:
	set(value):
		show_editor_preview = value
		_sync_zone_geometry()
@export var preview_color := Color(0.20, 0.62, 1.0, 0.18):
	set(value):
		preview_color = value
		_sync_zone_geometry()

@export_group("Runtime State")
@export var is_satisfied := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	monitoring = true
	monitorable = false
	add_to_group("reconstruction_zones")
	_sync_zone_geometry()
	set_process(Engine.is_editor_hint())
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_overlap_changed)
	body_exited.connect(_on_overlap_changed)
	var manager := get_node_or_null("/root/ReconstructionManager")
	if is_instance_valid(manager):
		manager.call("register_zone", self)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	var manager := get_node_or_null("/root/ReconstructionManager")
	if is_instance_valid(manager):
		manager.call("unregister_zone", self)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_sync_zone_geometry()


func evaluate_candidates(candidates: Array[Node3D]) -> bool:
	var next_satisfied := false
	for candidate: Node3D in candidates:
		if not is_instance_valid(candidate):
			continue
		if _get_furniture_id(candidate) != required_furniture_id:
			continue
		if not contains_furniture(candidate):
			continue
		if require_orientation and not _orientation_matches(candidate):
			continue
		next_satisfied = true
		break
	_set_satisfied(next_satisfied)
	return next_satisfied


func contains_furniture(furniture_node: Node3D) -> bool:
	if not is_instance_valid(furniture_node):
		return false
	var local_position := to_local(furniture_node.global_position)
	var half_size := zone_size * 0.5
	return (
		absf(local_position.x) <= half_size.x
		and absf(local_position.y) <= half_size.y
		and absf(local_position.z) <= half_size.z
	)


func _orientation_matches(furniture_node: Node3D) -> bool:
	var furniture_forward := -furniture_node.global_basis.orthonormalized().z
	var expected_basis := global_basis.orthonormalized() * Basis(Vector3.UP, deg_to_rad(target_yaw_degrees))
	var expected_forward := -expected_basis.z
	furniture_forward.y = 0.0
	expected_forward.y = 0.0
	if furniture_forward.length_squared() < 0.001 or expected_forward.length_squared() < 0.001:
		return false
	furniture_forward = furniture_forward.normalized()
	expected_forward = expected_forward.normalized()
	var angle := rad_to_deg(acos(clampf(furniture_forward.dot(expected_forward), -1.0, 1.0)))
	return angle <= orientation_tolerance_degrees


func _get_furniture_id(furniture_node: Node3D) -> String:
	var furniture_id := String(furniture_node.get_meta("furniture_id", ""))
	if furniture_id.is_empty():
		furniture_id = String(furniture_node.get_meta("furniture_kind", ""))
	return furniture_id


func _set_satisfied(value: bool) -> void:
	if is_satisfied == value:
		return
	is_satisfied = value
	satisfaction_changed.emit(zone_id, is_satisfied)


func _on_overlap_changed(_body: Node3D) -> void:
	var manager := get_node_or_null("/root/ReconstructionManager")
	if is_instance_valid(manager):
		manager.call("request_evaluation")


func _sync_zone_geometry() -> void:
	if not is_inside_tree():
		return
	var collision := get_node_or_null("ZoneCollision") as CollisionShape3D
	if not is_instance_valid(collision):
		collision = CollisionShape3D.new()
		collision.name = "ZoneCollision"
		add_child(collision)
	var shape := collision.shape as BoxShape3D
	if shape == null:
		shape = BoxShape3D.new()
		collision.shape = shape
	shape.size = zone_size

	var preview := get_node_or_null("ZoneEditorPreview") as MeshInstance3D
	if not is_instance_valid(preview):
		preview = MeshInstance3D.new()
		preview.name = "ZoneEditorPreview"
		preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(preview)
	var box := preview.mesh as BoxMesh
	if box == null:
		box = BoxMesh.new()
		preview.mesh = box
	box.size = zone_size
	preview.material_override = _make_preview_material(preview_color)
	preview.visible = Engine.is_editor_hint() and show_editor_preview


func _make_preview_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b)
	material.emission_energy_multiplier = 0.45
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test = true
	return material
