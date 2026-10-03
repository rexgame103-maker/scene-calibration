@tool
class_name SceneCluePoint
extends Area3D


@export_category("Scene Clue")
@export var clue_point_id := ""
@export var clue_id := ""
@export var title := "场景线索"
@export_multiline var description := ""

@export_category("Unlock")
@export var required_reconstruction_step_id := ""
@export var is_unlocked := false
@export var is_discovered := false
@export var hide_after_discovered := true

@export_category("Inspection")
@export var show_only_during_inspection := true
@export var inspection_furniture_id := ""
@export_range(0.5, 5.0, 0.05) var detail_view_distance := 1.8
@export var detail_view_offset := Vector3.ZERO
## Outward normal of the clue surface, in this point's local coordinates.
## Zero allows any direction, but still requires an unobstructed view.
@export var surface_normal := Vector3.ZERO
@export_range(0.0, 0.9, 0.05) var minimum_view_dot := 0.2

@export_category("Editor Preview")
@export var show_preview_in_editor := true:
	set(value):
		show_preview_in_editor = value
		if is_inside_tree():
			_refresh_visual_state()

@onready var hit_shape: CollisionShape3D = $HitShape
@onready var glow_mesh: MeshInstance3D = $GlowMesh
@onready var core_mesh: MeshInstance3D = $CoreMesh
@onready var point_light: OmniLight3D = $PointLight

var _hovered := false
var _inspection_active := false
var _triangle_meshes: Dictionary = {}


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and visible != _is_runtime_visible():
		_refresh_visual_state()


func _ready() -> void:
	if Engine.is_editor_hint():
		_refresh_visual_state()
		return

	add_to_group("scene_clue_points")
	# Layer 20 keeps the luminous marker out of detail cameras.
	glow_mesh.layers = 1 << 19
	core_mesh.layers = 1 << 19
	point_light.light_cull_mask = 1 << 19
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	var reconstruction_manager := _get_reconstruction_manager()
	if is_instance_valid(reconstruction_manager):
		var step_callback := Callable(self, "_on_reconstruction_step_completed")
		if not reconstruction_manager.is_connected("reconstruction_step_completed", step_callback):
			reconstruction_manager.connect("reconstruction_step_completed", step_callback)
		if not required_reconstruction_step_id.is_empty() and reconstruction_manager.call(
			"has_step_completed", required_reconstruction_step_id
		):
			unlock()

	var case_manager := _get_case_manager()
	if is_instance_valid(case_manager) and not clue_id.is_empty() and case_manager.call("has_clue", clue_id):
		is_discovered = true
	_refresh_visual_state()


func unlock() -> void:
	if is_unlocked:
		return
	is_unlocked = true
	_refresh_visual_state()


func investigate() -> bool:
	if Engine.is_editor_hint() or not _is_runtime_visible():
		return false
	if is_discovered and hide_after_discovered:
		return false

	var popup := get_tree().get_first_node_in_group("scene_clue_ui")
	if is_instance_valid(popup):
		return bool(popup.call("show_point", self))
	return false

func collect_clue() -> bool:
	if Engine.is_editor_hint() or not is_unlocked or is_discovered:
		return false

	var newly_discovered := false
	var case_manager := _get_case_manager()
	if is_instance_valid(case_manager) and not clue_id.is_empty():
		newly_discovered = bool(case_manager.call("discover_clue", clue_id))
		is_discovered = bool(case_manager.call("has_clue", clue_id))
	else:
		push_warning("SceneCluePoint '%s' has no valid clue_id or CaseManager." % clue_point_id)

	_refresh_visual_state()
	return newly_discovered


func set_inspection_context(furniture_node: Node3D) -> void:
	if not show_only_during_inspection:
		_inspection_active = true
	elif not is_instance_valid(furniture_node):
		_inspection_active = false
	elif not inspection_furniture_id.is_empty():
		var target_id := String(furniture_node.get_meta("furniture_id", ""))
		if target_id.is_empty():
			target_id = String(furniture_node.get_meta("furniture_kind", ""))
		_inspection_active = target_id == inspection_furniture_id
	else:
		_inspection_active = furniture_node == self or furniture_node.is_ancestor_of(self)
	_refresh_visual_state()


func _on_reconstruction_step_completed(step_id: String) -> void:
	if step_id == required_reconstruction_step_id:
		unlock()


func _on_input_event(
	_camera: Node,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if investigate():
			get_viewport().set_input_as_handled()


func _on_mouse_entered() -> void:
	if not _is_runtime_visible():
		return
	_hovered = true
	_refresh_hover_feedback()
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_mouse_exited() -> void:
	_hovered = false
	_refresh_hover_feedback()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _refresh_visual_state() -> void:
	if not is_node_ready():
		return
	var should_show := show_preview_in_editor if Engine.is_editor_hint() else _is_runtime_visible()
	visible = should_show
	input_ray_pickable = should_show and not Engine.is_editor_hint()
	if is_instance_valid(hit_shape):
		hit_shape.set_deferred("disabled", not should_show or Engine.is_editor_hint())
	if not should_show:
		if _hovered:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		_hovered = false
	_refresh_hover_feedback()


func _is_runtime_visible() -> bool:
	return (
		is_unlocked
		and not (is_discovered and hide_after_discovered)
		and (not show_only_during_inspection or _inspection_active)
		and is_visible_from_camera()
	)


func is_visible_from_camera() -> bool:
	var camera := get_viewport().get_camera_3d()
	if not is_instance_valid(camera) or not camera.is_position_in_frustum(global_position):
		return false
	var screen_position := camera.unproject_position(global_position)
	var origin := camera.project_ray_origin(screen_position)
	var toward_camera := (origin - global_position).normalized()
	if not surface_normal.is_zero_approx():
		var normal := (global_basis.inverse().transposed() * surface_normal).normalized()
		if normal.dot(toward_camera) < minimum_view_dot:
			return false
	# Test visible geometry, not the oversized furniture physics/selection boxes.
	# Stop just outside the surface so its own coplanar face does not hide the clue.
	var endpoint := global_position + toward_camera * 0.015
	for instance_id in RenderingServer.instances_cull_ray(origin, endpoint, get_world_3d().scenario):
		var mesh_node := instance_from_id(instance_id) as MeshInstance3D
		if not is_instance_valid(mesh_node) or mesh_node.mesh == null:
			continue
		if is_ancestor_of(mesh_node) or not mesh_node.is_visible_in_tree():
			continue
		if (mesh_node.layers & camera.cull_mask) == 0:
			continue
		var mesh := mesh_node.mesh
		if not _triangle_meshes.has(mesh):
			_triangle_meshes[mesh] = mesh.generate_triangle_mesh()
		var triangles := _triangle_meshes[mesh] as TriangleMesh
		if triangles == null:
			continue
		var local_from := mesh_node.to_local(origin)
		var local_to := mesh_node.to_local(endpoint)
		if not triangles.intersect_segment(local_from, local_to).is_empty():
			return false
	return true


func _refresh_hover_feedback() -> void:
	if not is_node_ready():
		return
	var scale_factor := 1.25 if _hovered else 1.0
	if is_instance_valid(glow_mesh):
		glow_mesh.scale = Vector3.ONE * scale_factor
	if is_instance_valid(core_mesh):
		core_mesh.scale = Vector3.ONE * (1.12 if _hovered else 1.0)
	if is_instance_valid(point_light):
		point_light.light_energy = 1.35 if _hovered else 0.85


func _get_reconstruction_manager() -> Node:
	return get_node_or_null("/root/ReconstructionManager")


func _get_case_manager() -> Node:
	return get_node_or_null("/root/CaseManager")
