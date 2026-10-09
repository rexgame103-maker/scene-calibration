@tool
extends Node
class_name StylizedMaterialController


const STYLIZED_SHADER := preload("res://shaders/stylized_surface.gdshader")
const OUTLINE_SHADER := preload("res://shaders/stylized_outline.gdshader")

@export_category("Stylized Material Library / 手绘材质库")
@export var style_enabled := true
@export var apply_in_editor := true
@export var profiles: Array[StylizedMaterialProfile] = []: set = _set_profiles
@export var fallback_profile: StylizedMaterialProfile: set = _set_fallback_profile
@export_range(0.05, 1.0, 0.05) var editor_refresh_interval := 0.15

var _original_material_states: Dictionary = {}
var _refresh_queued := false
var _editor_refresh_elapsed := 0.0
var _editor_last_signature := 0
var _editor_last_mesh_count := -1
var _editor_style_was_active := false


func _ready() -> void:
	_connect_profiles()
	set_process(Engine.is_editor_hint())
	if Engine.is_editor_hint() and not apply_in_editor:
		return
	call_deferred("_initialize_style")


func _process(delta: float) -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	_editor_refresh_elapsed += delta
	if _editor_refresh_elapsed < editor_refresh_interval:
		return
	_editor_refresh_elapsed = 0.0
	var editor_style_active := apply_in_editor and style_enabled
	var signature := _editor_profile_signature()
	var mesh_count := _scene_mesh_count()
	if not editor_style_active:
		if _editor_style_was_active:
			_restore_original_materials()
		_editor_style_was_active = false
		_editor_last_signature = signature
		_editor_last_mesh_count = mesh_count
		return
	if not _editor_style_was_active or signature != _editor_last_signature or mesh_count != _editor_last_mesh_count:
		_apply_to_scene()
	_editor_style_was_active = true
	_editor_last_signature = signature
	_editor_last_mesh_count = mesh_count


func register_stylized_root(root: Node, role := "") -> void:
	if not style_enabled or not is_instance_valid(root):
		return
	_apply_to_root(root, role)


func set_style_enabled(value: bool) -> void:
	if style_enabled == value and is_inside_tree():
		return
	style_enabled = value
	if not is_inside_tree():
		return
	if value:
		_apply_to_scene()
	else:
		_restore_original_materials()


func refresh_material_parameters() -> void:
	_refresh_all_materials()


func get_profile_for_role(role: String) -> StylizedMaterialProfile:
	return _find_profile(role, "")


func _set_profiles(value: Array[StylizedMaterialProfile]) -> void:
	_disconnect_profiles()
	profiles = value
	_connect_profiles()
	_queue_refresh()


func _set_fallback_profile(value: StylizedMaterialProfile) -> void:
	if is_instance_valid(fallback_profile) and fallback_profile.changed.is_connected(_on_profile_changed):
		fallback_profile.changed.disconnect(_on_profile_changed)
	fallback_profile = value
	if is_instance_valid(fallback_profile) and not fallback_profile.changed.is_connected(_on_profile_changed):
		fallback_profile.changed.connect(_on_profile_changed)
	_queue_refresh()


func _connect_profiles() -> void:
	for profile: StylizedMaterialProfile in profiles:
		if is_instance_valid(profile) and not profile.changed.is_connected(_on_profile_changed):
			profile.changed.connect(_on_profile_changed)
	if is_instance_valid(fallback_profile) and not fallback_profile.changed.is_connected(_on_profile_changed):
		fallback_profile.changed.connect(_on_profile_changed)


func _disconnect_profiles() -> void:
	for profile: StylizedMaterialProfile in profiles:
		if is_instance_valid(profile) and profile.changed.is_connected(_on_profile_changed):
			profile.changed.disconnect(_on_profile_changed)


func _on_profile_changed() -> void:
	_queue_refresh()


func _queue_refresh() -> void:
	if not is_inside_tree() or _refresh_queued:
		return
	_refresh_queued = true
	call_deferred("_refresh_all_materials")


func _refresh_all_materials() -> void:
	_refresh_queued = false
	if not style_enabled or not is_inside_tree():
		return
	_apply_to_scene()


func _initialize_style() -> void:
	if Engine.is_editor_hint():
		if apply_in_editor and style_enabled:
			_apply_to_scene()
			_editor_style_was_active = true
			_editor_last_signature = _editor_profile_signature()
			_editor_last_mesh_count = _scene_mesh_count()
		return
	var post_process := get_parent().get_node_or_null("HandDrawnPostProcess") as HandDrawnPostProcess
	var can_use_screen_effect := DisplayServer.get_name() != "headless"
	if can_use_screen_effect and is_instance_valid(post_process) and not post_process.is_connected("effect_toggled", _on_effect_toggled):
		post_process.connect("effect_toggled", _on_effect_toggled)
	if can_use_screen_effect:
		style_enabled = not is_instance_valid(post_process) or post_process.is_effect_enabled()
	if style_enabled:
		_apply_to_scene()


func _on_effect_toggled(enabled: bool) -> void:
	set_style_enabled(enabled)


func _apply_to_scene() -> void:
	if not style_enabled or not is_inside_tree():
		return
	var root := get_parent()
	if not is_instance_valid(root):
		return
	for candidate: Node in root.find_children("*", "MeshInstance3D", true, false):
		_apply_to_mesh(candidate as MeshInstance3D, _infer_role(candidate))


func _apply_to_root(root: Node, role: String) -> void:
	if root is MeshInstance3D:
		_apply_to_mesh(root as MeshInstance3D, role if not role.is_empty() else _infer_role(root))
	for candidate: Node in root.find_children("*", "MeshInstance3D", true, false):
		_apply_to_mesh(candidate as MeshInstance3D, role if not role.is_empty() else _infer_role(candidate))


func _apply_to_mesh(mesh_instance: MeshInstance3D, role: String) -> void:
	if not is_instance_valid(mesh_instance) or mesh_instance.mesh == null or _should_ignore(mesh_instance):
		return
	# Authored comic materials already provide their own lighting and outlines.
	var authored := mesh_instance.material_override as ShaderMaterial
	if authored != null and authored.shader != null and authored.shader.resource_path == "res://shaders/noir_toon.gdshader":
		return
	_store_original_materials(mesh_instance)
	mesh_instance.material_override = null
	for surface_index: int in range(mesh_instance.mesh.get_surface_count()):
		var source_material := _source_material_for_surface(mesh_instance, surface_index)
		var material_name := source_material.resource_name if is_instance_valid(source_material) else ""
		var profile := _find_profile(role, material_name)
		if not is_instance_valid(profile):
			continue
		var source_color := _read_material_color(source_material)
		mesh_instance.set_surface_override_material(surface_index, _make_stylized_material(profile, source_color))
	mesh_instance.set_meta("stylized_material_applied", true)


func _find_profile(role: String, material_name: String) -> StylizedMaterialProfile:
	var best_profile: StylizedMaterialProfile
	var best_priority := -2147483648
	for profile: StylizedMaterialProfile in profiles:
		if not is_instance_valid(profile) or not profile.matches(role, material_name):
			continue
		var material_match := false
		for pattern: String in profile.material_name_contains:
			if not pattern.is_empty() and material_name.to_lower().contains(pattern.to_lower()):
				material_match = true
				break
		var effective_priority := profile.priority + (10000 if material_match else 0)
		if effective_priority > best_priority:
			best_profile = profile
			best_priority = effective_priority
	return best_profile if is_instance_valid(best_profile) else fallback_profile


func _make_stylized_material(profile: StylizedMaterialProfile, source_color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = STYLIZED_SHADER
	var final_color := profile.base_color.lerp(source_color, profile.source_color_influence)
	material.set_shader_parameter("base_color", final_color)
	material.set_shader_parameter("secondary_color", profile.secondary_color)
	material.set_shader_parameter("paint_highlight_color", profile.paint_highlight_color)
	material.set_shader_parameter("stain_color", profile.stain_color)
	material.set_shader_parameter("wear_color", profile.wear_color)
	material.set_shader_parameter("color_variation", profile.color_variation)
	material.set_shader_parameter("brush_scale", profile.brush_scale)
	material.set_shader_parameter("brush_strength", profile.brush_strength)
	material.set_shader_parameter("patina_strength", profile.patina_strength)
	material.set_shader_parameter("stain_strength", profile.stain_strength)
	material.set_shader_parameter("roughness_value", profile.roughness)
	material.set_shader_parameter("specular_value", profile.specular)
	material.set_shader_parameter("wear_strength", profile.wear_strength)
	material.set_shader_parameter("wear_scale", profile.wear_scale)
	material.set_shader_parameter("desk_wear", profile.authored_desk_wear)
	material.set_shader_parameter("grid_enabled", profile.grid_enabled)
	material.set_shader_parameter("grid_color", profile.grid_color)
	material.set_shader_parameter("grid_cell_size", profile.grid_cell_size)
	material.set_shader_parameter("grid_line_width", profile.grid_line_width)
	material.set_shader_parameter("grid_strength", profile.grid_strength)
	material.set_shader_parameter("grid_tile_variation", profile.grid_tile_variation)
	material.set_shader_parameter("grid_offset", profile.grid_offset)
	if profile.outline_enabled and profile.outline_width > 0.0:
		var outline := ShaderMaterial.new()
		outline.shader = OUTLINE_SHADER
		outline.set_shader_parameter("outline_color", profile.outline_color)
		outline.set_shader_parameter("outline_width", profile.outline_width)
		material.next_pass = outline
	return material


func _source_material_for_surface(mesh_instance: MeshInstance3D, surface_index: int) -> Material:
	var state: Dictionary = _original_material_states.get(mesh_instance.get_instance_id(), {})
	var original_override := state.get("material_override", null) as Material
	if original_override != null:
		return original_override
	var surface_overrides: Array = state.get("surface_overrides", [])
	if surface_index < surface_overrides.size() and surface_overrides[surface_index] is Material:
		return surface_overrides[surface_index] as Material
	return mesh_instance.mesh.surface_get_material(surface_index)


func _read_material_color(source_material: Material) -> Color:
	if source_material is StandardMaterial3D:
		return (source_material as StandardMaterial3D).albedo_color
	if source_material is ORMMaterial3D:
		return (source_material as ORMMaterial3D).albedo_color
	return Color.WHITE


func _store_original_materials(mesh_instance: MeshInstance3D) -> void:
	var instance_id := mesh_instance.get_instance_id()
	if _original_material_states.has(instance_id):
		return
	var overrides: Array[Material] = []
	for surface_index: int in range(mesh_instance.mesh.get_surface_count()):
		overrides.append(mesh_instance.get_surface_override_material(surface_index))
	_original_material_states[instance_id] = {
		"node": mesh_instance,
		"material_override": mesh_instance.material_override,
		"surface_overrides": overrides,
	}


func _restore_original_materials() -> void:
	for state_value: Variant in _original_material_states.values():
		var state := state_value as Dictionary
		var node_value: Variant = state.get("node", null)
		if not is_instance_valid(node_value):
			continue
		var mesh_instance := node_value as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		mesh_instance.material_override = state.get("material_override", null) as Material
		var overrides: Array = state.get("surface_overrides", [])
		for surface_index: int in range(mini(overrides.size(), mesh_instance.mesh.get_surface_count())):
			mesh_instance.set_surface_override_material(surface_index, overrides[surface_index] as Material)
		mesh_instance.set_meta("stylized_material_applied", false)


func _infer_role(node: Node) -> String:
	var cursor: Node = node
	while is_instance_valid(cursor):
		var furniture_kind := String(cursor.get_meta("furniture_kind", ""))
		if not furniture_kind.is_empty():
			return _normalize_role(furniture_kind)
		var name_key := cursor.name.to_lower()
		if name_key.contains("floor") or name_key.contains("stage"): return "floor"
		if name_key.contains("backwall") or name_key.contains("back_wall"): return "back_wall"
		if name_key.contains("leftwall") or name_key.contains("left_wall"): return "left_wall"
		if name_key.contains("desk") and not name_key.contains("desktop"): return "desk"
		if name_key.contains("chair"): return "chair"
		if name_key.contains("computer") or name_key.contains("oldpc") or name_key.contains("monitor"): return "computer"
		if name_key.contains("lamp"): return "lamp"
		if name_key.contains("filecabinet") or name_key.contains("file_cabinet") or name_key.contains("tallfile"): return "shelf"
		if name_key.contains("smallcabinet") or name_key.contains("small_cabinet"): return "small_shelf"
		if name_key.contains("waterdispenser"): return "water_dispenser"
		if name_key.contains("printer"): return "printer"
		if name_key.contains("bluefile") or name_key.contains("blue_file"): return "blue_file"
		if name_key.contains("redfile") or name_key.contains("red_file"): return "red_file"
		if name_key.contains("paper"): return "paper"
		if name_key.contains("sofa"): return "sofa"
		if name_key.contains("plant"): return "plant"
		cursor = cursor.get_parent()
	return "architecture" if _is_under_named_parent(node, "Architecture") or _is_under_named_parent(node, "PrimitiveRoom") else "furniture"


func _normalize_role(role: String) -> String:
	match role:
		"file_shelf": return "shelf"
		"office_chair": return "chair"
		"small_cabinet": return "small_shelf"
		"red_case_file": return "red_file"
		"gray_case_file": return "gray_file"
	return role


func _is_under_named_parent(node: Node, target_name: String) -> bool:
	var cursor := node.get_parent()
	while is_instance_valid(cursor):
		if cursor.name == target_name:
			return true
		cursor = cursor.get_parent()
	return false


func _should_ignore(mesh_instance: MeshInstance3D) -> bool:
	# Thin leaves retain their two-sided shading and UV veins under the scene style.
	if bool(mesh_instance.get_meta("stylized_material_locked", false)):
		return true
	var lowered := mesh_instance.name.to_lower()
	if lowered.contains("preview") or lowered.contains("marker") or lowered.contains("gizmo") or lowered.contains("evidencegloss"):
		return true
	var cursor: Node = mesh_instance
	while is_instance_valid(cursor):
		if cursor is SceneCluePoint or cursor is ReconstructionZone:
			return true
		cursor = cursor.get_parent()
	return false


func _scene_mesh_count() -> int:
	var root := get_parent()
	return root.find_children("*", "MeshInstance3D", true, false).size() if is_instance_valid(root) else 0


func _editor_profile_signature() -> int:
	var values: Array = [style_enabled, apply_in_editor, profiles.size()]
	for profile: StylizedMaterialProfile in profiles:
		values.append(_single_profile_signature(profile))
	values.append(_single_profile_signature(fallback_profile))
	return hash(values)


func _single_profile_signature(profile: StylizedMaterialProfile) -> int:
	if not is_instance_valid(profile):
		return 0
	return hash([
		profile.profile_id,
		profile.role_ids,
		profile.material_name_contains,
		profile.priority,
		profile.base_color,
		profile.secondary_color,
		profile.paint_highlight_color,
		profile.stain_color,
		profile.wear_color,
		profile.source_color_influence,
		profile.color_variation,
		profile.brush_scale,
		profile.brush_strength,
		profile.patina_strength,
		profile.stain_strength,
		profile.wear_strength,
		profile.wear_scale,
		profile.authored_desk_wear,
		profile.grid_enabled,
		profile.grid_color,
		profile.grid_cell_size,
		profile.grid_line_width,
		profile.grid_strength,
		profile.grid_tile_variation,
		profile.grid_offset,
		profile.roughness,
		profile.specular,
		profile.outline_enabled,
		profile.outline_color,
		profile.outline_width,
	])
