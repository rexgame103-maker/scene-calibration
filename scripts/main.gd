@tool
extends Node3D

const CASE_SCENE_UI := preload("res://scripts/case_scene_ui_theme.gd")
const PAPER_UI := preload("res://scripts/investigation_ui_theme.gd")
const PAPER_INK := Color("30251f")


const ROOM_WIDTH := 6.688969
const ROOM_DEPTH := 6.688969
const ROOM_MIN_X := -ROOM_WIDTH * 0.5
const ROOM_MIN_Z := -ROOM_DEPTH * 0.5
const CELL_SIZE := 1.0
const OVERVIEW_CAMERA_FOV := 28.0
const FOCUS_CAMERA_FOV := 12.5
const CAMERA_VIEW_OFFSET := Vector3(14.436, 14.076, 16.992)
const OVERVIEW_TARGET := Vector3(0.25, 0.90, 0.0)
const CAMERA_MOVE_DURATION := 0.72
const FOCUS_YAW_LIMIT := 45.0
const FOCUS_PITCH_LIMIT := 22.0
const FOCUS_FOV_MIN := 8.5
const FOCUS_FOV_MAX := 18.5
const FOCUS_FOV_STEP := 0.75
const FOCUS_ORBIT_SENSITIVITY := 0.20
const FOCUS_PAN_SENSITIVITY := 0.007
const FOCUS_PAN_HORIZONTAL_LIMIT := 2.2
const FOCUS_PAN_VERTICAL_LIMIT := 1.35
const MAX_SHADOW_LIGHTS := 2
const LIGHT_TRANSFORM_UPDATE_INTERVAL := 1.0 / 30.0
const DEFAULT_GLOBAL_LIGHT_ENERGY := 0.16
const DEFAULT_GLOBAL_SATURATION := 1.0
const DEFAULT_LIGHT_ENERGIES := [0.42, 0.20, 0.30]
const DEFAULT_LIGHT_TEMPERATURES := [4200.0, 7800.0, 2800.0]
const DEFAULT_LIGHT_RANGES := [0.0, 8.0, 7.0]
const DEFAULT_LIGHT_SHADOWS := [true, false, false]
const PHYSICS_DROP_HEIGHT := 0.32
const SURFACE_SNAP_CLEARANCE := 0.008
const ROOM_PHYSICS_LAYER := 1
const FURNITURE_PHYSICS_LAYER := 4
const ROTATION_GIZMO_LAYER := 8
const SCENE_CLUE_PHYSICS_LAYER := 16
const ROTATION_GIZMO_SENSITIVITY := 0.42
const UI_Z_CONTEXT := 15
const UI_Z_ROTATION_MODAL := 30
const UI_Z_CASE_FLOW := 40
const UI_Z_CASE_FILES := 50
const UI_Z_SCENE_CLUE := 60
const RECONSTRUCTION_ZONE_SCENE: PackedScene = preload("res://scenes/reconstruction/reconstruction_zone.tscn")
const SCENE_CLUE_POINT_SCENE: PackedScene = preload("res://scenes/clues/scene_clue_point.tscn")
const OFFICE_CONCEPT_FACTORY = preload("res://scripts/office_concept_furniture.gd")
const GALLERY_CONCEPT_FACTORY = preload("res://scripts/gallery_concept_furniture.gd")

var camera: Camera3D
var furniture_root: Node3D
var preview_root: Node3D
var ui_root: Control
var catalog_panel: Control
var catalog_item_list: VBoxContainer
var status_panel: PanelContainer
var status_label: Label
var overview_button: Button
var case_files_button: Button
var debug_hint_button: Button
var case_file_ui: CaseFileUI
var scene_clue_popup: SceneCluePopup
var first_case_flow_ui: FirstCaseFlowUI
var undo_button: Button
var clear_button: Button
var lighting_toolbar: PanelContainer
var lighting_editor_panel: PanelContainer
var lighting_toggle_button: Button
var case_light_toolbar: PanelContainer
var case_light_editor_panel: PanelContainer
var case_light_toggle_button: Button
var case_light_device_selector: OptionButton
var case_light_energy_slider: HSlider
var case_light_temperature_slider: HSlider
var case_light_yaw_slider: HSlider
var case_light_pitch_slider: HSlider
var case_light_energy_value_label: Label
var case_light_temperature_value_label: Label
var case_light_yaw_value_label: Label
var case_light_pitch_value_label: Label
var case_light_availability_label: Label
var light_selector: OptionButton
var global_light_slider: HSlider
var global_light_value_label: Label
var saturation_slider: HSlider
var saturation_value_label: Label
var light_energy_slider: HSlider
var light_energy_value_label: Label
var light_temperature_slider: HSlider
var light_temperature_value_label: Label
var light_color_mode_selector: OptionButton
var light_color_picker: ColorPickerButton
var light_range_slider: HSlider
var light_range_value_label: Label
var light_range_row: Control
var light_shadow_toggle: CheckButton
var light_position_x_slider: HSlider
var light_position_y_slider: HSlider
var light_position_z_slider: HSlider
var light_position_x_value_label: Label
var light_position_y_value_label: Label
var light_position_z_value_label: Label
var light_position_rows: Array[Control] = []
var key_direction_yaw_slider: HSlider
var key_direction_pitch_slider: HSlider
var key_direction_yaw_value_label: Label
var key_direction_pitch_value_label: Label
var key_direction_rows: Array[Control] = []
var furniture_menu: PanelContainer
var furniture_menu_title: Label
var rotate_action_button: Button
var rotation_mode_overlay: ColorRect
var rotation_mode_panel: PanelContainer
var scene_environment: Environment
var stylized_material_controller: StylizedMaterialController
var key_light: DirectionalLight3D
var fill_light: OmniLight3D
var accent_light: OmniLight3D

var occupied: Dictionary = {}
var placed_items: Array[Dictionary] = []
var active_kind := ""
var active_preview: Node3D
var preview_bounds_size := Vector2.ONE
var preview_bounds_offset := Vector2.ZERO
var preview_rotation_degrees := Vector3.ZERO
var preview_surface_height := 0.0
var preview_support_node: Node3D
var preview_support_surface_id := ""
var preview_bounds_marker: MeshInstance3D
var placement_valid := false
var _last_valid_state := false
var _has_preview_tint := false
var _last_status := ""
var selected_item: Dictionary = {}
var editing_item: Dictionary = {}
var selection_marker: Node3D
var rotation_gizmo: Node3D
var rotation_mode := false
var gizmo_dragging := false
var gizmo_axis_index := -1
var gizmo_last_mouse_position := Vector2.ZERO
var pending_world_drag := false
var world_press_position := Vector2.ZERO
var moving_existing := false
var moving_supported_items: Array[Dictionary] = []
var placing_from_inventory := false
var inventory_counts: Dictionary = {}
var furniture_collision_profiles: Dictionary = {}
var camera_focused := false
var camera_tween: Tween
var camera_transitioning := false
var camera_transition_id := 0
var focus_target_position := Vector3.ZERO
var focus_yaw := 0.0
var focus_target_yaw := 0.0
var focus_pitch := 0.0
var focus_target_pitch := 0.0
var focus_fov := FOCUS_CAMERA_FOV
var focus_target_fov := FOCUS_CAMERA_FOV
var orbit_dragging := false
var focus_pan := Vector2.ZERO
var focus_target_pan := Vector2.ZERO
var focus_pan_dragging := false
var selected_light_index := 0
var light_temperatures: Array[float] = [4200.0, 7800.0, 2800.0]
var light_color_modes: Array[int] = [0, 0, 0]
var light_custom_colors: Array[Color] = [Color.WHITE, Color.WHITE, Color.WHITE]
var updating_lighting_controls := false
var updating_case_light_controls := false
var selected_case_light_furniture_id := ""
var case_light_reflection_update_elapsed := 0.0
var last_case_reflection_strength := -1.0
var default_light_positions: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
var desired_light_positions: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
var pending_light_position_updates: Array[bool] = [false, false, false]
var default_key_rotation_degrees := Vector3.ZERO
var key_direction_degrees := Vector2.ZERO
var pending_key_direction_update := false
var lighting_transform_update_elapsed := 0.0
var runtime_room_width := ROOM_WIDTH
var runtime_room_depth := ROOM_DEPTH
var runtime_room_min_x := ROOM_MIN_X
var runtime_room_min_z := ROOM_MIN_Z
var runtime_overview_target := OVERVIEW_TARGET
var runtime_layout: Dictionary = {}
var overview_pan_offset := 0.0
var photo_reference_tray: ReferencePhotoTray
var captured_case_photo_path := ""


func _ready() -> void:
	_bind_persistent_scene()
	if Engine.is_editor_hint():
		return
	var editor_preview := get_node_or_null("EditorOfficePreview")
	if editor_preview != null:
		remove_child(editor_preview)
		editor_preview.queue_free()
	_configure_case_scene()
	_ensure_room_physics()
	_register_initial_scene_furniture()
	_connect_case_manager()
	_initialize_starter_inventory()
	_initialize_lighting_state()
	_build_ui()
	_set_status("先打开案件资料查看警方照片，获得线索后会解锁家具", Color("cbbce5"))


func _bind_persistent_scene() -> void:
	var world_environment := get_node_or_null("SceneEnvironment") as WorldEnvironment
	camera = get_node_or_null("IsometricCamera") as Camera3D
	key_light = get_node_or_null("KeyLight") as DirectionalLight3D
	fill_light = get_node_or_null("FillLight") as OmniLight3D
	accent_light = get_node_or_null("AccentLight") as OmniLight3D
	stylized_material_controller = get_node_or_null("StylizedMaterialController") as StylizedMaterialController
	furniture_root = get_node_or_null("PlacedFurniture") as Node3D
	preview_root = get_node_or_null("PlacementPreview") as Node3D
	var room := get_node_or_null("PrimitiveRoom") as Node3D
	if not is_instance_valid(world_environment) or not is_instance_valid(room):
		push_error("Persistent room nodes are missing from main.tscn")
		return
	scene_environment = world_environment.environment


func _configure_case_scene() -> void:
	var manager := _get_case_manager()
	if not is_instance_valid(manager):
		return
	runtime_layout = manager.call("get_scene_layout") as Dictionary
	runtime_room_width = float(runtime_layout.get("room_width", ROOM_WIDTH))
	runtime_room_depth = float(runtime_layout.get("room_depth", ROOM_DEPTH))
	runtime_room_min_x = -runtime_room_width * 0.5
	runtime_room_min_z = -runtime_room_depth * 0.5
	var target_values: Array = runtime_layout.get("overview_target", [0.25, 0.9, 0.0])
	if target_values.size() >= 3:
		runtime_overview_target = Vector3(float(target_values[0]), float(target_values[1]), float(target_values[2]))
	_rebuild_reconstruction_zones(manager.call("get_reconstruction_zones") as Array)
	if String(runtime_layout.get("mode", "office_assets")) == "primitive":
		_build_primitive_case_room()
	if _is_concept_gallery():
		_build_gallery_case_room()
	camera.transform = Transform3D(Basis.IDENTITY, runtime_overview_target + _camera_view_offset()).looking_at(runtime_overview_target)
	if _is_concept_office() or _is_concept_gallery():
		get_viewport().msaa_3d = Viewport.MSAA_4X
	else:
		var post := get_node_or_null("HandDrawnPostProcess") as HandDrawnPostProcess
		if is_instance_valid(post): post.set_effect_enabled(true)


func _is_concept_office() -> bool:
	return String(runtime_layout.get("mode", "")) == "noir_office"


func _furniture_info(kind: String) -> Dictionary:
	if _is_concept_gallery(): return GALLERY_CONCEPT_FACTORY.get_info(kind)
	return OFFICE_CONCEPT_FACTORY.get_info(kind) if _is_concept_office() else FurnitureFactory.get_info(kind)


func _camera_view_offset() -> Vector3:
	if _is_concept_gallery(): return Vector3(13.5,13,20)
	return Vector3(-7.8,16.0,19.5) if _is_concept_office() else CAMERA_VIEW_OFFSET

func _is_concept_gallery() -> bool:
	return String(runtime_layout.get("mode","")) == "noir_gallery"

func _build_gallery_case_room() -> void:
	var room := get_node("PrimitiveRoom")
	for child in room.get_children():
		if child is VisualInstance3D or child is Node3D: child.hide()
	var shell := (load("res://scenes/cases/gallery_parts/room.tscn") as PackedScene).instantiate()
	room.add_child(shell)
	key_light.light_energy = 0
	fill_light.light_energy = 0
	accent_light.light_energy = 0
	key_light = shell.get_node("WarmKey")
	scene_environment = shell.get_node("WorldEnvironment").environment.duplicate()
	(get_node("SceneEnvironment") as WorldEnvironment).environment = scene_environment
	shell.get_node("WorldEnvironment").free()
	var post := get_node_or_null("HandDrawnPostProcess") as HandDrawnPostProcess
	if post != null: post.set_effect_enabled(false)


func _rebuild_reconstruction_zones(configurations: Array) -> void:
	var root := get_node_or_null("ReconstructionZones") as Node3D
	if not is_instance_valid(root) or configurations.is_empty():
		return
	# The office's saved zones are authored in the editor. Preserve their
	# transforms and bounds instead of replacing them with JSON defaults.
	if _is_concept_office():
		var authored_ids: Array[String] = []
		for child in root.get_children():
			if child is ReconstructionZone:
				authored_ids.append(child.zone_id)
		var complete := authored_ids.size() == configurations.size()
		for config: Dictionary in configurations:
			complete = complete and authored_ids.has(String(config.get("zone_id", "")))
		if complete:
			return
	for child: Node in root.get_children():
		root.remove_child(child)
		child.queue_free()
	for value: Variant in configurations:
		if not value is Dictionary:
			continue
		var config := value as Dictionary
		var zone := RECONSTRUCTION_ZONE_SCENE.instantiate() as ReconstructionZone
		zone.name = "%sZone" % String(config.get("zone_id", "Zone")).trim_prefix("zone_").to_pascal_case()
		zone.zone_id = String(config.get("zone_id", ""))
		zone.required_furniture_id = String(config.get("required_furniture_id", ""))
		zone.require_orientation = bool(config.get("require_orientation", false))
		zone.orientation_tolerance_degrees = float(config.get("orientation_tolerance", 15.0))
		zone.target_yaw_degrees = float(config.get("target_yaw", 0.0))
		var position_values: Array = config.get("position", [0.0, 1.5, 0.0])
		var size_values: Array = config.get("size", [1.0, 3.0, 1.0])
		if position_values.size() >= 3:
			zone.position = Vector3(float(position_values[0]), float(position_values[1]), float(position_values[2]))
		if size_values.size() >= 3:
			zone.zone_size = Vector3(float(size_values[0]), float(size_values[1]), float(size_values[2]))
		root.add_child(zone)


func _build_primitive_case_room() -> void:
	var room := get_node_or_null("PrimitiveRoom") as Node3D
	if not is_instance_valid(room):
		return
	for visual_name: String in ["ImportedArchitecture", "FixedSceneDetails", "Floor", "Walls", "WallPanels", "Trim", "Exterior", "ConceptOfficeShell"]:
		var visual := room.get_node_or_null(visual_name) as Node3D
		if is_instance_valid(visual):
			visual.visible = false
	var runtime_shell := room.get_node_or_null("RuntimeCaseShell") as Node3D
	if is_instance_valid(runtime_shell):
		runtime_shell.queue_free()
	runtime_shell = Node3D.new()
	runtime_shell.name = "RuntimeCaseShell"
	room.add_child(runtime_shell)
	_add_primitive_room_box(runtime_shell, "Floor", Vector3(runtime_room_width, 0.18, runtime_room_depth), Vector3(0, -0.09, 0), Color("706a63"))
	_add_primitive_room_box(runtime_shell, "BackWall", Vector3(runtime_room_width, 3.5, 0.18), Vector3(0, 1.75, runtime_room_min_z), Color("a8a096"))
	_add_primitive_room_box(runtime_shell, "LeftWall", Vector3(0.18, 3.5, runtime_room_depth), Vector3(runtime_room_min_x, 1.75, 0), Color("929ca5"))
	var divider_x := float(runtime_layout.get("room_divider_x", 1000.0))
	if absf(divider_x) < runtime_room_width:
		_add_primitive_room_box(runtime_shell, "Divider", Vector3(0.18, 2.7, runtime_room_depth * 0.62), Vector3(divider_x, 1.35, runtime_room_min_z + runtime_room_depth * 0.31), Color("878f96"))
		_add_primitive_room_box(runtime_shell, "DoorHeader", Vector3(0.18, 0.55, runtime_room_depth * 0.25), Vector3(divider_x, 2.45, runtime_room_min_z + runtime_room_depth * 0.82), Color("878f96"))
	for fixture_value: Variant in runtime_layout.get("fixtures", []):
		if not fixture_value is Dictionary:
			continue
		var fixture := fixture_value as Dictionary
		if String(fixture.get("type", "box")) != "box":
			continue
		var size_values: Array = fixture.get("size", [1.0, 1.0, 1.0])
		var position_values: Array = fixture.get("position", [0.0, 0.5, 0.0])
		if size_values.size() < 3 or position_values.size() < 3:
			continue
		_add_primitive_room_box(
			runtime_shell,
			String(fixture.get("name", "Fixture")),
			Vector3(float(size_values[0]), float(size_values[1]), float(size_values[2])),
			Vector3(float(position_values[0]), float(position_values[1]), float(position_values[2])),
			Color.from_string(String(fixture.get("color", "#8B8B8B")), Color("8b8b8b")),
			bool(fixture.get("emission", false))
		)


func _add_primitive_room_box(
	parent: Node3D,
	node_name: String,
	size: Vector3,
	position: Vector3,
	color: Color,
	emission := false
) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	if emission:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.35
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)


func _attach_configured_scene_clues(furniture: Node3D) -> void:
	var manager := _get_case_manager()
	if not is_instance_valid(manager):
		return
	var furniture_id := String(furniture.get_meta("furniture_id", ""))
	for value: Variant in manager.call("get_scene_clue_points"):
		if not value is Dictionary:
			continue
		var config := value as Dictionary
		if String(config.get("parent_furniture_id", "")) != furniture_id:
			continue
		var point := SCENE_CLUE_POINT_SCENE.instantiate() as SceneCluePoint
		point.name = String(config.get("clue_point_id", "SceneClue")).to_pascal_case()
		point.clue_point_id = String(config.get("clue_point_id", ""))
		point.clue_id = String(config.get("clue_id", ""))
		point.title = String(config.get("title", "场景线索"))
		point.description = String(config.get("description", ""))
		point.required_reconstruction_step_id = String(config.get("required_reconstruction_step_id", ""))
		point.is_unlocked = point.required_reconstruction_step_id.is_empty()
		point.inspection_furniture_id = furniture_id
		var position_values: Array = config.get("position", [0.0, 1.0, 0.0])
		if position_values.size() >= 3:
			point.position = Vector3(float(position_values[0]), float(position_values[1]), float(position_values[2]))
		furniture.add_child(point)


func _ensure_room_physics() -> void:
	var room := get_node_or_null("PrimitiveRoom") as Node3D
	if not is_instance_valid(room) or room.has_node("RuntimeRoomPhysics"):
		return
	var static_body := StaticBody3D.new()
	static_body.name = "RuntimeRoomPhysics"
	static_body.collision_layer = ROOM_PHYSICS_LAYER
	static_body.collision_mask = FURNITURE_PHYSICS_LAYER
	room.add_child(static_body)
	_add_room_collision_box(static_body, "FloorCollision", Vector3(runtime_room_width, 0.20, runtime_room_depth), Vector3(0.0, -0.10, 0.0))
	_add_room_collision_box(static_body, "BackWallCollision", Vector3(runtime_room_width, 5.70, 0.285), Vector3(0.0, 2.85, runtime_room_min_z))
	_add_room_collision_box(static_body, "LeftWallCollision", Vector3(0.285, 5.70, runtime_room_depth), Vector3(runtime_room_min_x, 2.85, 0.0))
	if _is_concept_office():
		_add_room_collision_box(static_body, "RightWallCollision", Vector3(0.16,3.3,runtime_room_depth),Vector3(-runtime_room_min_x,1.65,0))


func _add_room_collision_box(parent: StaticBody3D, node_name: String, size: Vector3, position: Vector3) -> void:
	var collision := CollisionShape3D.new()
	collision.name = node_name
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	collision.position = position
	parent.add_child(collision)


func _register_initial_scene_furniture() -> void:
	if not is_instance_valid(furniture_root):
		return
	var preplaced_nodes: Array[Node] = furniture_root.get_children()
	for child: Node in preplaced_nodes:
		if not child is Node3D:
			continue
		var model := child as Node3D
		if bool(model.get_meta("runtime_registered", false)):
			continue
		var kind := String(model.get_meta("scene_furniture_kind", ""))
		if kind.is_empty():
			var lowered_name := model.name.to_lower()
			for catalog_entry: Dictionary in FurnitureFactory.CATALOG:
				var candidate_kind := String(catalog_entry.kind)
				if lowered_name.contains(candidate_kind):
					kind = candidate_kind
					break
		if kind.is_empty():
			continue
		_assign_furniture_identity(model, kind)
		var info := _furniture_info(kind)
		var footprint: Vector2i = info.footprint
		var object_size: Vector3 = info.size
		var requires_collection := bool(model.get_meta("requires_collection", true))
		if not furniture_collision_profiles.has(kind) and model.has_method("get_collision_profile"):
			var profile_value: Variant = model.call("get_collision_profile")
			if typeof(profile_value) == TYPE_DICTIONARY:
				furniture_collision_profiles[kind] = (profile_value as Dictionary).duplicate(true)
		if model is RigidBody3D and model.has_method("get_collision_profile"):
			var entity_body := model as RigidBody3D
			entity_body.set_meta("runtime_registered", true)
			entity_body.freeze = requires_collection
			var entity_rotation := entity_body.rotation_degrees
			placed_items.append({
				"node": entity_body,
				"cells": [],
				"kind": kind,
				"furniture_id": _furniture_id_for_kind(kind),
				"footprint": footprint,
				"object_size": object_size,
				"bounds_size": _projected_bounds_size(object_size, entity_rotation),
				"bounds_offset": _projected_bounds_offset(object_size, entity_rotation),
				"rotation_degrees": entity_rotation,
				"requires_collection": requires_collection
			})
			_register_reconstruction_furniture(entity_body)
			continue

		# The wrapper owns the interaction collision while the imported model keeps
		# its authored editor pose (including a knocked-over rotation).
		var initial_global_transform := model.global_transform
		var furniture := Node3D.new()
		furniture.name = "Initial%sFurniture" % kind.capitalize()
		furniture.set_meta("furniture_kind", kind)
		furniture.set_meta("runtime_registered", true)
		_assign_furniture_identity(furniture, kind)
		furniture_root.add_child(furniture)
		furniture.position = Vector3(model.position.x, 0.0, model.position.z)
		model.reparent(furniture, true)
		model.global_transform = initial_global_transform
		FurnitureFactory.add_interaction_collision(furniture, kind)

		placed_items.append({
			"node": furniture,
			"cells": [],
			"kind": kind,
			"furniture_id": _furniture_id_for_kind(kind),
			"footprint": footprint,
			"object_size": object_size,
			"bounds_size": Vector2(object_size.x, object_size.z),
			"bounds_offset": Vector2.ZERO,
			"rotation_degrees": Vector3.ZERO,
			"requires_collection": requires_collection
		})
		_register_reconstruction_furniture(furniture)


func _initialize_starter_inventory() -> void:
	# The case data owns unlock state.  The existing inventory remains responsible
	# only for counts, drag cards and placement consumption.
	inventory_counts.clear()
	for item: Dictionary in FurnitureFactory.CATALOG:
		var kind := String(item.kind)
		inventory_counts[kind] = 0
	var manager := _get_case_manager()
	if not is_instance_valid(manager):
		return
	var unlocked_items: Array = manager.call("get_unlocked_furniture")
	for furniture_value: Variant in unlocked_items:
		if typeof(furniture_value) != TYPE_DICTIONARY:
			continue
		var furniture_data := furniture_value as Dictionary
		var kind := String(furniture_data.get("catalog_kind", ""))
		if not _catalog_contains_kind(kind):
			continue
		inventory_counts[kind] = int(inventory_counts.get(kind, 0)) + maxi(
			1,
			int(furniture_data.get("inventory_amount", 1))
		)


func _get_case_manager() -> Node:
	return get_node_or_null("/root/CaseManager")


func _get_reconstruction_manager() -> Node:
	return get_node_or_null("/root/ReconstructionManager")


func _furniture_id_for_kind(kind: String) -> String:
	var manager := _get_case_manager()
	if is_instance_valid(manager):
		var furniture_data: Dictionary = manager.call("get_furniture_by_catalog_kind", kind)
		var configured_id := String(furniture_data.get("furniture_id", ""))
		if not configured_id.is_empty():
			return configured_id
	return kind


func _assign_furniture_identity(furniture_node: Node3D, kind: String) -> void:
	if not is_instance_valid(furniture_node):
		return
	furniture_node.set_meta("furniture_kind", kind)
	furniture_node.set_meta("furniture_id", _furniture_id_for_kind(kind))


func _register_reconstruction_furniture(furniture_node: Node3D) -> void:
	var manager := _get_reconstruction_manager()
	if is_instance_valid(manager) and is_instance_valid(furniture_node):
		manager.call("register_furniture", furniture_node)
	_connect_case_light_device(furniture_node)
	_refresh_case_light_device_list()


func _notify_reconstruction_placement_completed(furniture_node: Node3D) -> void:
	var manager := _get_reconstruction_manager()
	if is_instance_valid(manager) and is_instance_valid(furniture_node):
		_connect_case_light_device(furniture_node)
		_update_case_light_visuals(0.0, true)
		manager.call("notify_furniture_placement_completed", furniture_node)
	_refresh_case_light_device_list()


func _unregister_reconstruction_furniture(furniture_node: Node3D) -> void:
	var manager := _get_reconstruction_manager()
	if is_instance_valid(manager) and is_instance_valid(furniture_node):
		manager.call("unregister_furniture", furniture_node)


func _connect_case_manager() -> void:
	var manager := _get_case_manager()
	if not is_instance_valid(manager):
		push_error("CaseManager Autoload is missing")
		return
	var unlock_callback := Callable(self, "_on_case_furniture_unlocked")
	if not manager.is_connected("furniture_unlocked", unlock_callback):
		manager.connect("furniture_unlocked", unlock_callback)
	var clue_callback := Callable(self, "_on_case_clue_discovered")
	if not manager.is_connected("clue_discovered", clue_callback):
		manager.connect("clue_discovered", clue_callback)


func _on_case_clue_discovered(clue: Dictionary) -> void:
	var status_message := String(clue.get("status_message", ""))
	if not status_message.is_empty():
		_set_status(status_message, Color("9dcff2"))
	_refresh_case_light_ui_availability()
	if not is_instance_valid(first_case_flow_ui):
		return
	var manager := _get_case_manager()
	var completion: Dictionary = manager.call("get_completion_data")
	var required_clues: Array = completion.get("required_clue_ids", [])
	first_case_flow_ui.set_submit_available(bool(manager.call("are_clues_discovered", required_clues)))


func _on_case_furniture_unlocked(furniture_data: Dictionary) -> void:
	var kind := String(furniture_data.get("catalog_kind", ""))
	if not _catalog_contains_kind(kind):
		push_warning("Unlocked furniture has no catalog entry: %s" % kind)
		return
	var amount := maxi(1, int(furniture_data.get("inventory_amount", 1)))
	inventory_counts[kind] = int(inventory_counts.get(kind, 0)) + amount
	_refresh_inventory_ui()
	_set_status(
		"已解锁「%s」，家具已加入右侧物品栏" % String(furniture_data.get("display_name", kind)),
		Color("9de2b6")
	)


func _catalog_contains_kind(kind: String) -> bool:
	for item: Dictionary in FurnitureFactory.CATALOG:
		if String(item.get("kind", "")) == kind:
			return true
	return false


func _debug_advance_next_step() -> void:
	if is_instance_valid(scene_clue_popup) and scene_clue_popup.visible:
		return
	if (
		camera_transitioning
		or rotation_mode
		or (is_instance_valid(first_case_flow_ui) and first_case_flow_ui.is_modal_active())
	):
		return
	if _debug_case_flow_finished():
		return
	if not active_kind.is_empty():
		_cancel_placement(false)
	if is_instance_valid(debug_hint_button):
		debug_hint_button.disabled = true

	if camera_focused:
		_focus_overview()
		await get_tree().create_timer(CAMERA_MOVE_DURATION + 0.05).timeout

	var clue_point := _debug_find_next_scene_clue()
	if is_instance_valid(clue_point):
		var clue_furniture := _debug_find_clue_furniture(clue_point)
		if is_instance_valid(clue_furniture) and clue_point.show_only_during_inspection:
			var clue_entry := _find_entry_by_node(clue_furniture)
			if not clue_entry.is_empty():
				_select_item(clue_entry)
				_focus_selected_furniture()
				await get_tree().create_timer(CAMERA_MOVE_DURATION + 0.05).timeout
		clue_point.set_inspection_context(clue_furniture)
		# Debug follows the same visibility gate, rotating within the player's orbit limits.
		if not clue_point.is_visible_from_camera():
			for yaw: float in [-FOCUS_YAW_LIMIT, FOCUS_YAW_LIMIT, 0.0]:
				for pitch: float in [-FOCUS_PITCH_LIMIT, 0.0, FOCUS_PITCH_LIMIT]:
					focus_target_yaw = yaw
					focus_target_pitch = pitch
					_update_focus_camera(10.0)
					if clue_point.is_visible_from_camera():
						break
				if clue_point.is_visible_from_camera():
					break
		if clue_point.investigate():
			_set_status("DEBUG · 已调查场景线索「%s」" % clue_point.title, Color("75c8ff"))
		else:
			_set_status("请旋转视角，露出线索所在表面后再调查", Color("75c8ff"))
		_debug_release_button()
		return

	var evidence := _debug_find_next_evidence()
	if not evidence.is_empty():
		case_file_ui.debug_open_evidence(String(evidence.get("id", "")))
		_set_status("DEBUG · 已打开案件资料「%s」" % String(evidence.get("title", "")), Color("75c8ff"))
		_debug_release_button()
		return

	var zone := _debug_find_next_placeable_zone()
	if is_instance_valid(zone) and _debug_place_furniture_in_zone(zone):
		_set_status("DEBUG · 已自动摆放「%s」" % _debug_furniture_display_name(zone.required_furniture_id), Color("75c8ff"))
		_debug_release_button()
		return

	if _debug_apply_pending_light_calibration():
		_set_status("DEBUG · 已按过程照片完成灯位、投影、色温与反射校准", Color("75c8ff"))
		_debug_release_button()
		return

	_debug_release_button()


func _debug_release_button() -> void:
	if is_instance_valid(debug_hint_button):
		debug_hint_button.disabled = false


func _debug_case_flow_finished() -> bool:
	var manager := _get_case_manager()
	var reconstruction_manager := _get_reconstruction_manager()
	if not is_instance_valid(manager) or not is_instance_valid(reconstruction_manager):
		return true
	var completion := manager.call("get_completion_data") as Dictionary
	var required_step := String(completion.get("required_reconstruction_step_id", ""))
	var required_clues: Array = completion.get("required_clue_ids", [])
	return (
		(required_step.is_empty() or bool(reconstruction_manager.call("is_step_satisfied", required_step)))
		and bool(manager.call("are_clues_discovered", required_clues))
	)


func _debug_find_next_evidence() -> Dictionary:
	var manager := _get_case_manager()
	if not is_instance_valid(manager):
		return {}
	for evidence_value: Variant in manager.call("get_available_evidence"):
		if not evidence_value is Dictionary:
			continue
		var evidence := evidence_value as Dictionary
		if bool(evidence.get("is_viewed", false)):
			continue
		return evidence
	return {}


func _debug_find_next_scene_clue() -> SceneCluePoint:
	for point_node: Node in get_tree().get_nodes_in_group("scene_clue_points"):
		var point := point_node as SceneCluePoint
		if (
			is_instance_valid(point)
			and is_ancestor_of(point)
			and point.is_unlocked
			and not point.is_discovered
		):
			return point
	return null


func _debug_apply_pending_light_calibration() -> bool:
	var reconstruction_manager := _get_reconstruction_manager()
	if not is_instance_valid(reconstruction_manager):
		return false
	var conditions := reconstruction_manager.call("get_pending_lighting_conditions") as Array
	if conditions.is_empty():
		return false
	var changed := false
	for condition_value: Variant in conditions:
		if not condition_value is Dictionary:
			continue
		var condition := condition_value as Dictionary
		if String(condition.get("type", "")) != "device_parameters":
			continue
		var device := _find_case_light_device(String(condition.get("furniture_id", "")))
		var debug_values: Dictionary = condition.get("debug_values", {})
		if not is_instance_valid(device) or debug_values.is_empty():
			continue
		device.apply_debug_values(debug_values)
		changed = true
	if not changed:
		return false
	_update_case_light_visuals(0.0, true)
	reconstruction_manager.call("evaluate_all")
	_sync_case_light_controls()
	return true


func _debug_find_clue_furniture(point: SceneCluePoint) -> Node3D:
	if not is_instance_valid(point):
		return null
	var current: Node = point.get_parent()
	while is_instance_valid(current) and current != self:
		if current is Node3D and (current.has_meta("furniture_id") or current.has_meta("furniture_kind")):
			return current as Node3D
		current = current.get_parent()
	return null


func _debug_find_next_placeable_zone() -> ReconstructionZone:
	var case_manager := _get_case_manager()
	var reconstruction_manager := _get_reconstruction_manager()
	if not is_instance_valid(case_manager) or not is_instance_valid(reconstruction_manager):
		return null
	reconstruction_manager.call("evaluate_all")
	var zones := reconstruction_manager.get("zones") as Dictionary
	for step_value: Variant in case_manager.call("get_reconstruction_steps"):
		if not step_value is Dictionary:
			continue
		var step := step_value as Dictionary
		var step_id := String(step.get("step_id", ""))
		# A completed phase remains historical even after the same furniture is
		# moved into a later answer layout. Never send Debug back to an old phase.
		if not step_id.is_empty() and bool(reconstruction_manager.call("has_step_completed", step_id)):
			continue
		if not bool(case_manager.call("are_clues_discovered", step.get("required_clue_ids", []))):
			continue
		for zone_id_value: Variant in step.get("zone_ids", []):
			var zone := zones.get(String(zone_id_value), null) as ReconstructionZone
			if not is_instance_valid(zone) or zone.is_satisfied:
				continue
			var furniture_data := case_manager.call("get_furniture_data", zone.required_furniture_id) as Dictionary
			var kind := String(furniture_data.get("catalog_kind", ""))
			var existing := _debug_find_placed_furniture_by_id(zone.required_furniture_id)
			if (
				bool(furniture_data.get("is_unlocked", false))
				and (int(inventory_counts.get(kind, 0)) > 0 or is_instance_valid(existing))
			):
				return zone
	return null


func _debug_find_placed_furniture_by_id(furniture_id: String) -> Node3D:
	for entry: Dictionary in placed_items:
		var furniture := entry.get("node", null) as Node3D
		if not is_instance_valid(furniture):
			continue
		var entry_id := String(entry.get("furniture_id", ""))
		if entry_id.is_empty():
			entry_id = String(furniture.get_meta("furniture_id", ""))
		if entry_id == furniture_id:
			return furniture
	return null


func _debug_place_furniture_in_zone(zone: ReconstructionZone) -> bool:
	if not is_instance_valid(zone):
		return false
	var manager := _get_case_manager()
	var furniture_data := manager.call("get_furniture_data", zone.required_furniture_id) as Dictionary
	var kind := String(furniture_data.get("catalog_kind", ""))
	if kind.is_empty():
		return false
	var furniture := _debug_find_placed_furniture_by_id(zone.required_furniture_id)
	var is_new_furniture := not is_instance_valid(furniture)
	if is_new_furniture:
		if int(inventory_counts.get(kind, 0)) <= 0:
			return false
		furniture = _build_furniture(kind)
		furniture_root.add_child(furniture)
	var info := _furniture_info(kind)
	var object_size: Vector3 = info.size
	var rotation_value := Vector3.ZERO
	if zone.require_orientation or not is_zero_approx(zone.target_yaw_degrees):
		rotation_value.y = zone.global_rotation_degrees.y + zone.target_yaw_degrees
	furniture.rotation_degrees = rotation_value
	var support_node := _debug_zone_support_furniture(zone)
	var support_surface_id := ""
	var target_position := zone.global_position
	if zone.zone_type == ReconstructionZone.ZoneType.FIXED_POSITION:
		target_position.y = _ground_offset_for_rotation(object_size, rotation_value) + 0.025
	elif is_instance_valid(support_node):
		# Relation zones can describe either a floor relationship (chair in front
		# of desk) or a support relationship (computer on desk / files on shelf).
		# Start on the floor, then lift only furniture whose catalog explicitly
		# allows snapping to this support role.
		target_position.y = _ground_offset_for_rotation(object_size, rotation_value) + 0.025
		var support_info := _furniture_info(String(support_node.get_meta("furniture_kind", "")))
		var target_roles := _get_surface_snap_target_roles(info)
		if target_roles.has(String(support_info.get("surface_role", ""))):
			var nearest_surface := _debug_nearest_support_surface(zone, support_node, support_info)
			if not nearest_surface.is_empty():
				support_surface_id = String(nearest_surface.get("id", "surface"))
				var surface_world := support_node.to_global(nearest_surface.get("offset", Vector3.ZERO))
				target_position.y = surface_world.y + _ground_offset_for_rotation(object_size, rotation_value) + SURFACE_SNAP_CLEARANCE
		# Authored relation zones and support surfaces can differ by a few
		# centimetres. Keep the natural support height while nudging the origin
		# just inside the answer volume so boundary precision cannot reject it.
		var local_target := zone.to_local(target_position)
		var half_zone_height := zone.zone_size.y * 0.5
		var inner_margin := minf(0.02, half_zone_height * 0.25)
		local_target.y = clampf(local_target.y, -half_zone_height + inner_margin, half_zone_height - inner_margin)
		target_position = zone.to_global(local_target)
	furniture.global_position = target_position
	var body := furniture as RigidBody3D
	if is_instance_valid(body):
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
		# Debug placement stays exact so physics cannot move it out of the answer zone.
		body.freeze = true
		body.sleeping = true
	var bounds_size := _projected_bounds_size(object_size, rotation_value)
	var bounds_offset := _projected_bounds_offset(object_size, rotation_value)
	var updated_entry := {
		"node": furniture,
		"cells": [],
		"kind": kind,
		"furniture_id": zone.required_furniture_id,
		"footprint": info.footprint,
		"object_size": object_size,
		"bounds_size": bounds_size,
		"bounds_offset": bounds_offset,
		"rotation_degrees": rotation_value,
		"support_node": support_node,
		"support_surface_id": support_surface_id,
		"requires_collection": false
	}
	if is_new_furniture:
		placed_items.append(updated_entry)
		inventory_counts[kind] = maxi(0, int(inventory_counts.get(kind, 0)) - 1)
		_refresh_inventory_ui()
	else:
		var existing_index := _find_entry_index(furniture)
		if existing_index >= 0:
			placed_items[existing_index] = updated_entry
	_notify_reconstruction_placement_completed(furniture)
	return true


func _debug_zone_support_furniture(zone: ReconstructionZone) -> Node3D:
	if zone.zone_type != ReconstructionZone.ZoneType.FURNITURE_RELATION:
		return null
	var current: Node = zone.get_parent()
	while is_instance_valid(current) and current != self:
		if current is Node3D and (current.has_meta("furniture_id") or current.has_meta("furniture_kind")):
			return current as Node3D
		current = current.get_parent()
	return null


func _debug_nearest_support_surface(zone: ReconstructionZone, support_node: Node3D, support_info: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := INF
	for surface: Dictionary in _get_support_snap_surfaces(support_node, support_info):
		var world_position := support_node.to_global(surface.get("offset", Vector3.ZERO))
		var distance := absf(world_position.y - zone.global_position.y)
		if distance < best_distance:
			best_distance = distance
			best = surface
	return best


func _debug_furniture_display_name(furniture_id: String) -> String:
	var manager := _get_case_manager()
	if not is_instance_valid(manager):
		return furniture_id
	var data := manager.call("get_furniture_data", furniture_id) as Dictionary
	return String(data.get("display_name", furniture_id))


func _build_furniture(kind: String, preview: bool = false) -> Node3D:
	var physics_overrides: Dictionary = {}
	if not preview and furniture_collision_profiles.has(kind):
		physics_overrides = furniture_collision_profiles[kind] as Dictionary
	var furniture: Node3D
	if _is_concept_gallery():
		furniture = GALLERY_CONCEPT_FACTORY.build(kind,preview,physics_overrides)
	elif _is_concept_office():
		furniture = OFFICE_CONCEPT_FACTORY.build(kind,preview)
	else:
		furniture = FurnitureFactory.build(kind,preview,physics_overrides)
	_assign_furniture_identity(furniture, kind)
	if not preview:
		_attach_configured_scene_clues(furniture)
	if is_instance_valid(stylized_material_controller) and not _is_concept_office() and not _is_concept_gallery():
		stylized_material_controller.register_stylized_root(furniture, kind)
	return furniture


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not active_kind.is_empty():
		_update_active_preview()
	elif rotation_mode and not moving_supported_items.is_empty():
		var rotating_support := selected_item.get("node", null) as Node3D
		if is_instance_valid(rotating_support):
			_sync_moving_supported_items(rotating_support.global_transform, true)
	_sync_dynamic_furniture()
	if camera_focused and not camera_transitioning and not (is_instance_valid(scene_clue_popup) and scene_clue_popup.visible):
		_update_focus_camera(delta)
	_update_pending_light_transforms(delta)
	_update_case_light_visuals(delta)


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if is_instance_valid(first_case_flow_ui):
		if first_case_flow_ui.is_modal_active():
			return
		if event is InputEventMouse and first_case_flow_ui.is_pointer_over_ui((event as InputEventMouse).position):
			return
	if is_instance_valid(scene_clue_popup) and scene_clue_popup.visible:
		return
	if is_instance_valid(case_file_ui) and case_file_ui.visible:
		return
	if event is InputEventMouse and is_instance_valid(case_files_button):
		if case_files_button.get_global_rect().has_point((event as InputEventMouse).position):
			return
	if event is InputEventMouse and is_instance_valid(debug_hint_button):
		if debug_hint_button.get_global_rect().has_point((event as InputEventMouse).position):
			return
	if gizmo_dragging:
		if event is InputEventMouseMotion:
			_update_rotation_gizmo_drag(event)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_end_rotation_gizmo_drag()
		return
	if rotation_mode:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_instance_valid(rotation_mode_panel) and rotation_mode_panel.get_global_rect().has_point(event.position):
				return
			_try_begin_rotation_gizmo_drag(event.position)
		return
	if event is InputEventMouse:
		var mouse_event := event as InputEventMouse
		if _is_pointer_over_lighting_ui(mouse_event.position):
			return
	if not active_kind.is_empty():
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
				_finish_placement()
			elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				_cancel_placement()
		elif event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				_cancel_placement()
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_Q:
				_rotate_active_preview(-90.0)
			elif event.keycode == KEY_E:
				_rotate_active_preview(90.0)
		return
	if camera_focused:
		_handle_focus_camera_input(event)
		return
	if camera_transitioning:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_pointer_over_furniture_menu(event.position):
			return
		if event.pressed:
			_handle_world_press(event.position)
		else:
			if pending_world_drag:
				pending_world_drag = false
				_show_furniture_menu(event.position)
	elif event is InputEventMouseMotion and pending_world_drag:
		if event.position.distance_to(world_press_position) > 5.0:
			_begin_move_selected()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_Z and event.ctrl_pressed and not event.echo:
			_undo_last()
		elif event.keycode in [KEY_DELETE, KEY_BACKSPACE] and not selected_item.is_empty() and not event.echo:
			_collect_selected()
		elif event.keycode == KEY_ESCAPE and not event.echo and not selected_item.is_empty():
			_clear_selection(true)
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	# Let GUI controls consume the event first. In inspection mode the default
	# physics picker can hit the furniture's broad body before its visible clue.
	# Use the clue-only ray, as overview selection already does.
	if Engine.is_editor_hint() or not camera_focused or camera_transitioning:
		return
	if rotation_mode or not active_kind.is_empty():
		return
	if is_instance_valid(first_case_flow_ui) and first_case_flow_ui.is_modal_active():
		return
	if is_instance_valid(case_file_ui) and case_file_ui.visible:
		return
	if is_instance_valid(scene_clue_popup) and scene_clue_popup.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _is_camera_control_position(event.position) and _try_investigate_scene_clue(event.position):
			orbit_dragging = false
			focus_pan_dragging = false
			get_viewport().set_input_as_handled()


func _handle_focus_camera_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_focus_overview()
		get_viewport().set_input_as_handled()
		return
	if camera_transitioning:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _is_camera_control_position(event.position):
				orbit_dragging = true
			else:
				orbit_dragging = false
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed and _is_camera_control_position(event.position):
				focus_pan_dragging = true
			else:
				focus_pan_dragging = false
		elif event.pressed and _is_camera_control_position(event.position):
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				focus_target_fov = clampf(focus_target_fov - FOCUS_FOV_STEP, FOCUS_FOV_MIN, FOCUS_FOV_MAX)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				focus_target_fov = clampf(focus_target_fov + FOCUS_FOV_STEP, FOCUS_FOV_MIN, FOCUS_FOV_MAX)
	elif event is InputEventMouseMotion:
		if focus_pan_dragging:
			var zoom_scale := focus_target_fov / FOCUS_CAMERA_FOV
			focus_target_pan.x = clampf(
				focus_target_pan.x - event.relative.x * FOCUS_PAN_SENSITIVITY * zoom_scale,
				-FOCUS_PAN_HORIZONTAL_LIMIT,
				FOCUS_PAN_HORIZONTAL_LIMIT
			)
			focus_target_pan.y = clampf(
				focus_target_pan.y + event.relative.y * FOCUS_PAN_SENSITIVITY * zoom_scale,
				-FOCUS_PAN_VERTICAL_LIMIT,
				FOCUS_PAN_VERTICAL_LIMIT
			)
		elif orbit_dragging:
			focus_target_yaw = clampf(
				focus_target_yaw - event.relative.x * FOCUS_ORBIT_SENSITIVITY,
				-FOCUS_YAW_LIMIT,
				FOCUS_YAW_LIMIT
			)
			focus_target_pitch = clampf(
				focus_target_pitch + event.relative.y * FOCUS_ORBIT_SENSITIVITY,
				-FOCUS_PITCH_LIMIT,
				FOCUS_PITCH_LIMIT
			)


func _is_camera_control_position(screen_position: Vector2) -> bool:
	var panel_left := get_viewport().get_visible_rect().size.x - 306.0
	if screen_position.x >= panel_left:
		return false
	if _is_pointer_over_lighting_ui(screen_position):
		return false
	if is_instance_valid(overview_button) and overview_button.visible:
		if overview_button.get_global_rect().has_point(screen_position):
			return false
	return true


func _is_pointer_over_lighting_ui(screen_position: Vector2) -> bool:
	if is_instance_valid(lighting_toolbar) and lighting_toolbar.get_global_rect().has_point(screen_position):
		return true
	if is_instance_valid(lighting_editor_panel) and lighting_editor_panel.visible:
		if lighting_editor_panel.get_global_rect().has_point(screen_position):
			return true
	if is_instance_valid(case_light_toolbar) and case_light_toolbar.visible:
		if case_light_toolbar.get_global_rect().has_point(screen_position):
			return true
	if is_instance_valid(case_light_editor_panel) and case_light_editor_panel.visible:
		return case_light_editor_panel.get_global_rect().has_point(screen_position)
	return false


func _update_focus_camera(delta: float) -> void:
	var smoothing := 1.0 - exp(-12.0 * delta)
	focus_yaw = lerpf(focus_yaw, focus_target_yaw, smoothing)
	focus_pitch = lerpf(focus_pitch, focus_target_pitch, smoothing)
	focus_fov = lerpf(focus_fov, focus_target_fov, smoothing)
	focus_pan = focus_pan.lerp(focus_target_pan, smoothing)
	var yawed_offset := _camera_view_offset().rotated(Vector3.UP, deg_to_rad(focus_yaw))
	var yawed_forward := (-yawed_offset).normalized()
	var pitch_axis := yawed_forward.cross(Vector3.UP).normalized()
	var orbit_offset := yawed_offset.rotated(pitch_axis, deg_to_rad(-focus_pitch))
	var view_forward := (-orbit_offset).normalized()
	var view_right := view_forward.cross(Vector3.UP).normalized()
	var view_up := view_right.cross(view_forward).normalized()
	var panned_target := focus_target_position + view_right * focus_pan.x + view_up * focus_pan.y
	var desired_position := panned_target + orbit_offset
	camera.position = camera.position.lerp(desired_position, smoothing)
	camera.fov = lerpf(camera.fov, focus_fov, smoothing)
	camera.look_at(panned_target, Vector3.UP)


func _initialize_lighting_state() -> void:
	scene_environment.adjustment_enabled = true
	_apply_case_base_lighting()
	for index: int in range(3):
		var light := _light_for_index(index)
		if is_instance_valid(light):
			light_custom_colors[index] = light.light_color
			default_light_positions[index] = light.position
			desired_light_positions[index] = light.position
	default_key_rotation_degrees = key_light.rotation_degrees
	key_direction_degrees = Vector2(default_key_rotation_degrees.x, default_key_rotation_degrees.y)


func _apply_case_base_lighting() -> bool:
	if _is_concept_gallery(): return true
	var base_value: Variant = runtime_layout.get("base_lighting", {})
	if not base_value is Dictionary:
		return false
	var base := base_value as Dictionary
	if base.is_empty() or not is_instance_valid(scene_environment):
		return false
	scene_environment.ambient_light_energy = float(base.get("ambient_energy", DEFAULT_GLOBAL_LIGHT_ENERGY))
	scene_environment.ambient_light_color = Color.from_string(
		String(base.get("ambient_color", "#FFFFFF")),
		Color.WHITE
	)
	scene_environment.adjustment_enabled = true
	scene_environment.adjustment_saturation = float(base.get("saturation", DEFAULT_GLOBAL_SATURATION))
	var keys: Array[String] = ["key", "fill", "accent"]
	for index: int in range(3):
		var light := _light_for_index(index)
		var settings_value: Variant = base.get(keys[index], {})
		if not is_instance_valid(light) or not settings_value is Dictionary:
			continue
		var settings := settings_value as Dictionary
		light.light_energy = float(settings.get("energy", light.light_energy))
		light_temperatures[index] = float(settings.get("temperature", DEFAULT_LIGHT_TEMPERATURES[index]))
		light.light_color = _kelvin_to_color(light_temperatures[index])
		light.shadow_enabled = bool(settings.get("shadow", false))
		var omni := light as OmniLight3D
		if is_instance_valid(omni):
			omni.omni_range = float(settings.get("range", omni.omni_range))
	return true


func _toggle_lighting_editor() -> void:
	if not is_instance_valid(lighting_editor_panel):
		return
	lighting_editor_panel.visible = not lighting_editor_panel.visible
	lighting_toggle_button.text = "收起调光" if lighting_editor_panel.visible else "展开调光"
	if lighting_editor_panel.visible:
		_hide_furniture_menu()
		_sync_lighting_controls()


func _light_for_index(index: int) -> Light3D:
	match clampi(index, 0, 2):
		1:
			return fill_light
		2:
			return accent_light
		_:
			return key_light


func _on_light_selected(index: int) -> void:
	_apply_pending_light_transforms()
	selected_light_index = clampi(index, 0, 2)
	_sync_lighting_controls()


func _sync_lighting_controls() -> void:
	if not is_instance_valid(global_light_slider):
		return
	var light := _light_for_index(selected_light_index)
	if not is_instance_valid(light):
		return
	updating_lighting_controls = true
	global_light_slider.value = scene_environment.ambient_light_energy
	global_light_value_label.text = "%.2f" % scene_environment.ambient_light_energy
	saturation_slider.value = scene_environment.adjustment_saturation
	saturation_value_label.text = "%.2f" % scene_environment.adjustment_saturation
	light_selector.select(selected_light_index)
	light_energy_slider.value = light.light_energy
	light_energy_value_label.text = "%.2f" % light.light_energy
	light_temperature_slider.value = light_temperatures[selected_light_index]
	light_temperature_value_label.text = "%d K" % roundi(light_temperatures[selected_light_index])
	var color_mode := light_color_modes[selected_light_index]
	light_color_mode_selector.select(color_mode)
	light_color_picker.disabled = color_mode == 0
	light_color_picker.color = light.light_color if color_mode == 0 else light_custom_colors[selected_light_index]
	var omni_light := light as OmniLight3D
	var is_local_light := is_instance_valid(omni_light)
	light_range_row.visible = is_local_light
	light_range_slider.editable = is_local_light
	if is_local_light:
		light_range_slider.value = omni_light.omni_range
		light_range_value_label.text = "%.1f m" % omni_light.omni_range
	for row: Control in light_position_rows:
		row.visible = is_local_light
	for row: Control in key_direction_rows:
		row.visible = not is_local_light
	if is_local_light:
		var desired_position := desired_light_positions[selected_light_index]
		light_position_x_slider.value = desired_position.x
		light_position_y_slider.value = desired_position.y
		light_position_z_slider.value = desired_position.z
		light_position_x_value_label.text = "%.1f m" % desired_position.x
		light_position_y_value_label.text = "%.1f m" % desired_position.y
		light_position_z_value_label.text = "%.1f m" % desired_position.z
	else:
		key_direction_yaw_slider.value = key_direction_degrees.y
		key_direction_pitch_slider.value = key_direction_degrees.x
		key_direction_yaw_value_label.text = "%d°" % roundi(key_direction_degrees.y)
		key_direction_pitch_value_label.text = "%d°" % roundi(key_direction_degrees.x)
	light_shadow_toggle.button_pressed = light.shadow_enabled
	updating_lighting_controls = false


func _on_global_light_changed(value: float) -> void:
	if updating_lighting_controls or not is_instance_valid(scene_environment):
		return
	scene_environment.ambient_light_energy = clampf(value, 0.02, 1.0)
	global_light_value_label.text = "%.2f" % scene_environment.ambient_light_energy


func _on_saturation_changed(value: float) -> void:
	if updating_lighting_controls or not is_instance_valid(scene_environment):
		return
	scene_environment.adjustment_enabled = true
	scene_environment.adjustment_saturation = clampf(value, 0.0, 2.0)
	saturation_value_label.text = "%.2f" % scene_environment.adjustment_saturation


func _on_light_energy_changed(value: float) -> void:
	if updating_lighting_controls:
		return
	var light := _light_for_index(selected_light_index)
	if not is_instance_valid(light):
		return
	light.light_energy = clampf(value, 0.0, 4.0)
	light_energy_value_label.text = "%.2f" % light.light_energy


func _on_light_temperature_changed(value: float) -> void:
	if updating_lighting_controls:
		return
	light_temperatures[selected_light_index] = clampf(value, 1800.0, 12000.0)
	light_temperature_value_label.text = "%d K" % roundi(light_temperatures[selected_light_index])
	if light_color_modes[selected_light_index] == 0:
		var light := _light_for_index(selected_light_index)
		light.light_color = _kelvin_to_color(light_temperatures[selected_light_index])
		updating_lighting_controls = true
		light_color_picker.color = light.light_color
		updating_lighting_controls = false


func _on_light_color_mode_selected(index: int) -> void:
	if updating_lighting_controls:
		return
	var color_mode := clampi(index, 0, 1)
	light_color_modes[selected_light_index] = color_mode
	var light := _light_for_index(selected_light_index)
	light_color_picker.disabled = color_mode == 0
	if color_mode == 0:
		light.light_color = _kelvin_to_color(light_temperatures[selected_light_index])
	else:
		light.light_color = light_custom_colors[selected_light_index]
	updating_lighting_controls = true
	light_color_picker.color = light.light_color
	updating_lighting_controls = false


func _on_light_custom_color_changed(color: Color) -> void:
	if updating_lighting_controls or light_color_modes[selected_light_index] != 1:
		return
	light_custom_colors[selected_light_index] = color
	var light := _light_for_index(selected_light_index)
	light.light_color = color


func _on_light_range_changed(value: float) -> void:
	if updating_lighting_controls:
		return
	var omni_light := _light_for_index(selected_light_index) as OmniLight3D
	if not is_instance_valid(omni_light):
		return
	omni_light.omni_range = clampf(value, 1.0, 12.0)
	light_range_value_label.text = "%.1f m" % omni_light.omni_range


func _on_light_position_changed(value: float, axis: int) -> void:
	if updating_lighting_controls or selected_light_index == 0:
		return
	var desired_position := desired_light_positions[selected_light_index]
	match axis:
		0:
			desired_position.x = clampf(value, -6.0, 6.0)
			light_position_x_value_label.text = "%.1f m" % desired_position.x
		1:
			desired_position.y = clampf(value, 0.5, 8.0)
			light_position_y_value_label.text = "%.1f m" % desired_position.y
		2:
			desired_position.z = clampf(value, -6.0, 6.0)
			light_position_z_value_label.text = "%.1f m" % desired_position.z
	desired_light_positions[selected_light_index] = desired_position
	pending_light_position_updates[selected_light_index] = true


func _on_key_direction_changed(value: float, axis: int) -> void:
	if updating_lighting_controls or selected_light_index != 0:
		return
	if axis == 0:
		key_direction_degrees.y = clampf(value, -180.0, 180.0)
		key_direction_yaw_value_label.text = "%d°" % roundi(key_direction_degrees.y)
	else:
		key_direction_degrees.x = clampf(value, -85.0, -10.0)
		key_direction_pitch_value_label.text = "%d°" % roundi(key_direction_degrees.x)
	pending_key_direction_update = true


func _update_pending_light_transforms(delta: float) -> void:
	if not pending_key_direction_update and not pending_light_position_updates.has(true):
		lighting_transform_update_elapsed = 0.0
		return
	lighting_transform_update_elapsed += delta
	if lighting_transform_update_elapsed < LIGHT_TRANSFORM_UPDATE_INTERVAL:
		return
	_apply_pending_light_transforms()


func _apply_pending_light_transforms() -> void:
	for index: int in range(1, 3):
		if pending_light_position_updates[index]:
			var light := _light_for_index(index)
			light.position = desired_light_positions[index]
			pending_light_position_updates[index] = false
	if pending_key_direction_update:
		key_light.rotation_degrees = Vector3(
			key_direction_degrees.x,
			key_direction_degrees.y,
			default_key_rotation_degrees.z
		)
		pending_key_direction_update = false
	lighting_transform_update_elapsed = 0.0


func _on_light_shadow_toggled(enabled: bool) -> void:
	if updating_lighting_controls:
		return
	var light := _light_for_index(selected_light_index)
	if enabled and not light.shadow_enabled and _shadow_light_count() >= MAX_SHADOW_LIGHTS:
		updating_lighting_controls = true
		light_shadow_toggle.button_pressed = false
		updating_lighting_controls = false
		_set_status("为保证性能，最多只能同时开启两盏阴影灯", Color("f0bd7a"))
		return
	light.shadow_enabled = enabled


func _shadow_light_count() -> int:
	var count := 0
	for index: int in range(3):
		var light := _light_for_index(index)
		if is_instance_valid(light) and light.shadow_enabled:
			count += 1
	return count


func _reset_lighting() -> void:
	if _apply_case_base_lighting():
		for index: int in range(3):
			var case_light := _light_for_index(index)
			case_light.position = default_light_positions[index]
			desired_light_positions[index] = default_light_positions[index]
			pending_light_position_updates[index] = false
		key_light.rotation_degrees = default_key_rotation_degrees
		key_direction_degrees = Vector2(default_key_rotation_degrees.x, default_key_rotation_degrees.y)
		pending_key_direction_update = false
		lighting_transform_update_elapsed = 0.0
		_sync_lighting_controls()
		_set_status("已恢复当前案件的中性基础光照", Color("d9c98f"))
		return
	scene_environment.ambient_light_energy = DEFAULT_GLOBAL_LIGHT_ENERGY
	scene_environment.adjustment_enabled = true
	scene_environment.adjustment_saturation = DEFAULT_GLOBAL_SATURATION
	for index: int in range(3):
		var light := _light_for_index(index)
		light.light_energy = DEFAULT_LIGHT_ENERGIES[index]
		light_temperatures[index] = DEFAULT_LIGHT_TEMPERATURES[index]
		light_color_modes[index] = 0
		light.light_color = _kelvin_to_color(light_temperatures[index])
		light_custom_colors[index] = light.light_color
		light.shadow_enabled = DEFAULT_LIGHT_SHADOWS[index]
		light.position = default_light_positions[index]
		desired_light_positions[index] = default_light_positions[index]
		pending_light_position_updates[index] = false
		var omni_light := light as OmniLight3D
		if is_instance_valid(omni_light):
			omni_light.omni_range = DEFAULT_LIGHT_RANGES[index]
	key_light.rotation_degrees = default_key_rotation_degrees
	key_direction_degrees = Vector2(default_key_rotation_degrees.x, default_key_rotation_degrees.y)
	pending_key_direction_update = false
	lighting_transform_update_elapsed = 0.0
	_sync_lighting_controls()
	_set_status("已恢复低亮度默认灯光", Color("d9c98f"))


func _case_light_config() -> Dictionary:
	var config_value: Variant = runtime_layout.get("light_calibration", {})
	return config_value as Dictionary if config_value is Dictionary else {}


func _has_case_light_calibration() -> bool:
	return bool(_case_light_config().get("enabled", false))


func _connect_case_light_device(furniture: Node3D) -> void:
	if not is_instance_valid(furniture):
		return
	var device := furniture.find_child("CaseLightDevice", true, false) as CaseLightDevice
	if not is_instance_valid(device):
		return
	var callback := Callable(self, "_on_case_light_device_settings_changed")
	if not device.is_connected("settings_changed", callback):
		device.connect("settings_changed", callback)


func _find_case_light_device(furniture_id: String) -> CaseLightDevice:
	var furniture := _debug_find_placed_furniture_by_id(furniture_id)
	if not is_instance_valid(furniture):
		return null
	return furniture.find_child("CaseLightDevice", true, false) as CaseLightDevice


func _on_case_light_device_settings_changed(device: CaseLightDevice) -> void:
	_update_case_light_visuals(0.0, true)
	var reconstruction_manager := _get_reconstruction_manager()
	if is_instance_valid(reconstruction_manager):
		reconstruction_manager.call("request_evaluation")
	if is_instance_valid(device) and selected_case_light_furniture_id == _case_light_furniture_id_for_device(device):
		_sync_case_light_controls()


func _case_light_furniture_id_for_device(device: CaseLightDevice) -> String:
	if not is_instance_valid(device):
		return ""
	var current: Node = device.get_parent()
	while is_instance_valid(current) and current != self:
		if current.has_meta("furniture_id"):
			return String(current.get_meta("furniture_id", ""))
		current = current.get_parent()
	return ""


func _update_case_light_visuals(delta: float, force_evaluation := false) -> void:
	if not _has_case_light_calibration():
		return
	case_light_reflection_update_elapsed += delta
	var reflector := _debug_find_placed_furniture_by_id("metal_reflector")
	var table := _debug_find_placed_furniture_by_id("restoration_table")
	var halogen_device := _find_case_light_device("halogen_lamp")
	var reflector_device := _find_case_light_device("metal_reflector")
	if (
		not is_instance_valid(reflector)
		or not is_instance_valid(table)
		or not is_instance_valid(halogen_device)
		or not is_instance_valid(reflector_device)
	):
		return
	var target_node := table.find_child("ArtworkSurface", true, false) as Node3D
	var target_position := target_node.global_position if is_instance_valid(target_node) else table.global_position + Vector3.UP
	var reflector_origin := reflector_device.get_light_origin()
	var reflector_forward := -reflector.global_basis.z.normalized()
	var to_target := (target_position - reflector_origin).normalized()
	var to_source := (halogen_device.get_light_origin() - reflector_origin).normalized()
	var facing_factor := maxf(0.0, reflector_forward.dot(to_target))
	var source_factor := maxf(0.0, reflector_forward.dot(to_source))
	var distance_factor := clampf(1.0 - reflector_origin.distance_to(target_position) / 7.5, 0.20, 1.0)
	var strength := halogen_device.light_energy * 0.42 * minf(facing_factor, source_factor) * distance_factor
	reflector_device.set_reflected_light(target_position, strength, halogen_device.temperature_kelvin)
	var strength_changed := absf(strength - last_case_reflection_strength) >= 0.012
	if force_evaluation or (strength_changed and case_light_reflection_update_elapsed >= 0.10):
		last_case_reflection_strength = strength
		case_light_reflection_update_elapsed = 0.0
		var reconstruction_manager := _get_reconstruction_manager()
		if is_instance_valid(reconstruction_manager):
			reconstruction_manager.call("request_evaluation")


func _case_light_calibration_available() -> bool:
	if not _has_case_light_calibration():
		return false
	var manager := _get_case_manager()
	return is_instance_valid(manager) and bool(manager.call(
		"are_clues_discovered",
		_case_light_config().get("required_clue_ids", [])
	))


func _toggle_case_light_editor() -> void:
	if not is_instance_valid(case_light_editor_panel) or not _case_light_calibration_available():
		return
	case_light_editor_panel.visible = not case_light_editor_panel.visible
	case_light_toggle_button.text = "收起校准" if case_light_editor_panel.visible else "展开校准"
	if case_light_editor_panel.visible:
		if is_instance_valid(lighting_editor_panel):
			lighting_editor_panel.visible = false
		_refresh_case_light_device_list()
		_sync_case_light_controls()


func _refresh_case_light_ui_availability() -> void:
	if not is_instance_valid(case_light_toolbar):
		return
	var available := _case_light_calibration_available()
	case_light_toggle_button.disabled = not available
	case_light_availability_label.text = "对照三张过程照片" if available else "查看三张过程照片后开放"
	if not available and is_instance_valid(case_light_editor_panel):
		case_light_editor_panel.visible = false
		case_light_toggle_button.text = "展开校准"


func _refresh_case_light_device_list() -> void:
	if not is_instance_valid(case_light_device_selector):
		return
	var previous_id := selected_case_light_furniture_id
	case_light_device_selector.clear()
	for device_value: Variant in _case_light_config().get("devices", []):
		if not device_value is Dictionary:
			continue
		var device_data := device_value as Dictionary
		var furniture_id := String(device_data.get("furniture_id", ""))
		if not is_instance_valid(_find_case_light_device(furniture_id)):
			continue
		var item_index := case_light_device_selector.item_count
		case_light_device_selector.add_item(String(device_data.get("label", furniture_id)))
		case_light_device_selector.set_item_metadata(item_index, furniture_id)
		if furniture_id == previous_id:
			case_light_device_selector.select(item_index)
	if case_light_device_selector.item_count == 0:
		case_light_device_selector.add_item("先摆放案件灯具")
		case_light_device_selector.disabled = true
		selected_case_light_furniture_id = ""
	else:
		case_light_device_selector.disabled = false
		var selected_index := case_light_device_selector.selected
		selected_case_light_furniture_id = String(case_light_device_selector.get_item_metadata(selected_index))
	_sync_case_light_controls()


func _on_case_light_selected(index: int) -> void:
	if updating_case_light_controls or index < 0 or index >= case_light_device_selector.item_count:
		return
	selected_case_light_furniture_id = String(case_light_device_selector.get_item_metadata(index))
	_sync_case_light_controls()


func _sync_case_light_controls() -> void:
	if not is_instance_valid(case_light_energy_slider):
		return
	var device := _find_case_light_device(selected_case_light_furniture_id)
	var enabled := is_instance_valid(device)
	for slider: HSlider in [case_light_energy_slider, case_light_temperature_slider, case_light_yaw_slider, case_light_pitch_slider]:
		slider.editable = enabled
	if not enabled:
		return
	updating_case_light_controls = true
	if device.device_role == "halogen":
		case_light_energy_slider.max_value = 1.5
		case_light_temperature_slider.min_value = 2200.0
		case_light_temperature_slider.max_value = 6200.0
		case_light_yaw_slider.min_value = -70.0
		case_light_yaw_slider.max_value = 70.0
		case_light_pitch_slider.min_value = -65.0
		case_light_pitch_slider.max_value = 5.0
	else:
		case_light_energy_slider.max_value = 1.0
		case_light_temperature_slider.min_value = 4000.0
		case_light_temperature_slider.max_value = 9000.0
		case_light_yaw_slider.min_value = -180.0
		case_light_yaw_slider.max_value = 180.0
		case_light_pitch_slider.min_value = -60.0
		case_light_pitch_slider.max_value = 10.0
	case_light_energy_slider.value = device.light_energy
	case_light_temperature_slider.value = device.temperature_kelvin
	case_light_yaw_slider.value = device.head_yaw_degrees
	case_light_pitch_slider.value = device.head_pitch_degrees
	case_light_energy_value_label.text = "%.2f" % device.light_energy
	case_light_temperature_value_label.text = "%d K" % int(device.temperature_kelvin)
	case_light_yaw_value_label.text = "%d°" % int(device.head_yaw_degrees)
	case_light_pitch_value_label.text = "%d°" % int(device.head_pitch_degrees)
	updating_case_light_controls = false


func _on_case_light_energy_changed(value: float) -> void:
	if updating_case_light_controls:
		return
	var device := _find_case_light_device(selected_case_light_furniture_id)
	if is_instance_valid(device):
		device.set_energy(value)


func _on_case_light_temperature_changed(value: float) -> void:
	if updating_case_light_controls:
		return
	var device := _find_case_light_device(selected_case_light_furniture_id)
	if is_instance_valid(device):
		device.set_temperature(value)


func _on_case_light_yaw_changed(value: float) -> void:
	if updating_case_light_controls:
		return
	var device := _find_case_light_device(selected_case_light_furniture_id)
	if is_instance_valid(device):
		device.set_head_yaw(value)


func _on_case_light_pitch_changed(value: float) -> void:
	if updating_case_light_controls:
		return
	var device := _find_case_light_device(selected_case_light_furniture_id)
	if is_instance_valid(device):
		device.set_head_pitch(value)


func _focus_restoration_table_for_calibration() -> void:
	var table := _debug_find_placed_furniture_by_id("restoration_table")
	if not is_instance_valid(table):
		_set_status("请先把修复桌摆入场景", Color("e6b486"))
		return
	var entry := _find_entry_by_node(table)
	if entry.is_empty():
		return
	_select_item(entry)
	_focus_selected_furniture()


func _kelvin_to_color(kelvin: float) -> Color:
	var temperature := clampf(kelvin, 1000.0, 40000.0) / 100.0
	var red: float
	var green: float
	var blue: float
	if temperature <= 66.0:
		red = 255.0
		green = 99.4708025861 * log(temperature) - 161.1195681661
		blue = 0.0 if temperature <= 19.0 else 138.5177312231 * log(temperature - 10.0) - 305.0447927307
	else:
		red = 329.698727446 * pow(temperature - 60.0, -0.1332047592)
		green = 288.1221695283 * pow(temperature - 60.0, -0.0755148492)
		blue = 255.0
	return Color(clampf(red, 0.0, 255.0) / 255.0, clampf(green, 0.0, 255.0) / 255.0, clampf(blue, 0.0, 255.0) / 255.0)


func _add_lighting_slider_row(parent: VBoxContainer, title: String, minimum: float, maximum: float, step: float) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var title_label := _label(title, 13, Color("c8bdd5"))
	title_label.custom_minimum_size = Vector2(104, 30)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title_label)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 30)
	slider.focus_mode = Control.FOCUS_NONE
	row.add_child(slider)
	var value_label := _label("", 12, Color("e6dcef"))
	value_label.custom_minimum_size = Vector2(62, 30)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(value_label)
	return {"row": row, "slider": slider, "value_label": value_label}


func _build_case_light_calibration_ui() -> void:
	if not _has_case_light_calibration():
		return
	# The case-specific console replaces the unrestricted atmosphere editor in a
	# light-calibration puzzle. Moving the lamps still uses normal furniture input.
	lighting_toolbar.visible = false
	lighting_editor_panel.visible = false
	var config := _case_light_config()
	case_light_toolbar = PanelContainer.new()
	case_light_toolbar.name = "CaseLightCalibrationToolbar"
	case_light_toolbar.position = Vector2(24, 174)
	case_light_toolbar.size = Vector2(350, 54)
	case_light_toolbar.mouse_filter = Control.MOUSE_FILTER_STOP
	case_light_toolbar.add_theme_stylebox_override("panel", _style(Color("1c2b38ed"), 16, Color("5e91a5a0"), 1))
	ui_root.add_child(case_light_toolbar)
	var toolbar_margin := MarginContainer.new()
	toolbar_margin.add_theme_constant_override("margin_left", 15)
	toolbar_margin.add_theme_constant_override("margin_right", 9)
	toolbar_margin.add_theme_constant_override("margin_top", 8)
	toolbar_margin.add_theme_constant_override("margin_bottom", 8)
	case_light_toolbar.add_child(toolbar_margin)
	var toolbar_row := HBoxContainer.new()
	toolbar_row.add_theme_constant_override("separation", 8)
	toolbar_margin.add_child(toolbar_row)
	var title := _label("光影校准", 15, Color("eef8ff"))
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toolbar_row.add_child(title)
	case_light_availability_label = _label("查看三张过程照片后开放", 10, Color("9eb5c1"))
	case_light_availability_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	case_light_availability_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toolbar_row.add_child(case_light_availability_label)
	case_light_toggle_button = _button("展开校准", Color("38556a"))
	case_light_toggle_button.custom_minimum_size = Vector2(92, 38)
	case_light_toggle_button.pressed.connect(_toggle_case_light_editor)
	toolbar_row.add_child(case_light_toggle_button)

	case_light_editor_panel = PanelContainer.new()
	case_light_editor_panel.name = "CaseLightCalibrationPanel"
	case_light_editor_panel.position = Vector2(24, 238)
	case_light_editor_panel.size = Vector2(350, 366)
	case_light_editor_panel.visible = false
	case_light_editor_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	case_light_editor_panel.z_index = 10
	case_light_editor_panel.add_theme_stylebox_override("panel", _style(Color("182632f5"), 18, Color("65a2b7b8"), 1))
	ui_root.add_child(case_light_editor_panel)
	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 15)
	panel_margin.add_theme_constant_override("margin_right", 15)
	panel_margin.add_theme_constant_override("margin_top", 13)
	panel_margin.add_theme_constant_override("margin_bottom", 13)
	case_light_editor_panel.add_child(panel_margin)
	var panel_vbox := VBoxContainer.new()
	panel_vbox.add_theme_constant_override("separation", 7)
	panel_margin.add_child(panel_vbox)
	panel_vbox.add_child(_label(String(config.get("title", "过程照片光影校准")), 16, Color("eef8ff")))
	var guidance := _label("移动灯具决定投影位置；这里调节灯头、强度与色温。系统不会提示单项是否正确。", 11, Color("a9bdc7"))
	guidance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guidance.custom_minimum_size = Vector2(0, 42)
	panel_vbox.add_child(guidance)
	var selector_row := HBoxContainer.new()
	selector_row.add_theme_constant_override("separation", 10)
	panel_vbox.add_child(selector_row)
	var selector_label := _label("案件灯具", 13, Color("c4d5dd"))
	selector_label.custom_minimum_size = Vector2(92, 34)
	selector_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	selector_row.add_child(selector_label)
	case_light_device_selector = OptionButton.new()
	case_light_device_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	case_light_device_selector.focus_mode = Control.FOCUS_NONE
	case_light_device_selector.item_selected.connect(_on_case_light_selected)
	selector_row.add_child(case_light_device_selector)
	var energy_row := _add_lighting_slider_row(panel_vbox, "灯光强度", 0.0, 1.5, 0.01)
	case_light_energy_slider = energy_row.slider as HSlider
	case_light_energy_value_label = energy_row.value_label as Label
	case_light_energy_slider.value_changed.connect(_on_case_light_energy_changed)
	var temperature_row := _add_lighting_slider_row(panel_vbox, "色温", 2200.0, 7600.0, 100.0)
	case_light_temperature_slider = temperature_row.slider as HSlider
	case_light_temperature_value_label = temperature_row.value_label as Label
	case_light_temperature_slider.value_changed.connect(_on_case_light_temperature_changed)
	var yaw_row := _add_lighting_slider_row(panel_vbox, "灯头水平", -180.0, 180.0, 1.0)
	case_light_yaw_slider = yaw_row.slider as HSlider
	case_light_yaw_value_label = yaw_row.value_label as Label
	case_light_yaw_slider.value_changed.connect(_on_case_light_yaw_changed)
	var pitch_row := _add_lighting_slider_row(panel_vbox, "灯头俯仰", -70.0, 5.0, 1.0)
	case_light_pitch_slider = pitch_row.slider as HSlider
	case_light_pitch_value_label = pitch_row.value_label as Label
	case_light_pitch_slider.value_changed.connect(_on_case_light_pitch_changed)
	var focus_table_button := _button("拉近检视修复桌", Color("3a6273"))
	focus_table_button.custom_minimum_size = Vector2(0, 38)
	focus_table_button.pressed.connect(_focus_restoration_table_for_calibration)
	panel_vbox.add_child(focus_table_button)
	_refresh_case_light_ui_availability()
	_refresh_case_light_device_list()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "RuntimeUI"
	layer.layer = 10
	add_child(layer)

	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = CASE_SCENE_UI.theme()
	layer.add_child(ui_root)

	var title_panel := PanelContainer.new()
	title_panel.name = "CaseTitlePanel"
	title_panel.position = Vector2(24, 22)
	title_panel.size = Vector2(320, 132)
	title_panel.add_theme_stylebox_override("panel", PAPER_UI.paper("title"))
	ui_root.add_child(title_panel)
	var title_margin := MarginContainer.new()
	title_margin.add_theme_constant_override("margin_left", 27)
	title_margin.add_theme_constant_override("margin_right", 86)
	title_margin.add_theme_constant_override("margin_top", 31)
	title_margin.add_theme_constant_override("margin_bottom", 14)
	title_panel.add_child(title_margin)
	var title_vbox := VBoxContainer.new()
	title_vbox.add_theme_constant_override("separation", 3)
	title_margin.add_child(title_vbox)
	var summary := _get_case_manager().call("get_case_summary") as Dictionary
	var eyebrow := _label(String(summary.get("subtitle", "现场重构委托")), 10, Color("b69bdb"))
	eyebrow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_vbox.add_child(eyebrow)
	var title := _label(String(summary.get("title", "现场重构")), 24, Color("fff8ff"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 20)
	title_vbox.add_child(title)
	case_files_button = _button("▣  案件资料", Color("59417b"))
	case_files_button.position = Vector2(356, 22)
	case_files_button.size = Vector2(138, 44)
	case_files_button.pressed.connect(_open_case_files)
	ui_root.add_child(case_files_button)
	debug_hint_button = _button("DEBUG 下一步", Color("315f8b"))
	debug_hint_button.name = "DebugHintButton"
	debug_hint_button.position = Vector2(502, 22)
	debug_hint_button.size = Vector2(126, 44)
	debug_hint_button.tooltip_text = "自动执行当前案件的下一个资料、检视或摆放步骤"
	debug_hint_button.pressed.connect(_debug_advance_next_step)
	ui_root.add_child(debug_hint_button)
	lighting_toolbar = PanelContainer.new()
	lighting_toolbar.position = Vector2(24, 166)
	lighting_toolbar.size = Vector2(320, 54)
	lighting_toolbar.mouse_filter = Control.MOUSE_FILTER_STOP
	lighting_toolbar.add_theme_stylebox_override("panel", _style(Color("211b33e8"), 16, Color("6f608d80"), 1))
	ui_root.add_child(lighting_toolbar)
	var lighting_toolbar_margin := MarginContainer.new()
	lighting_toolbar_margin.add_theme_constant_override("margin_left", 16)
	lighting_toolbar_margin.add_theme_constant_override("margin_right", 10)
	lighting_toolbar_margin.add_theme_constant_override("margin_top", 8)
	lighting_toolbar_margin.add_theme_constant_override("margin_bottom", 8)
	lighting_toolbar.add_child(lighting_toolbar_margin)
	var lighting_toolbar_row := HBoxContainer.new()
	lighting_toolbar_row.add_theme_constant_override("separation", 10)
	lighting_toolbar_margin.add_child(lighting_toolbar_row)
	var lighting_title := _label("灯光工作台", 15, Color("f3edf8"))
	lighting_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lighting_toolbar_row.add_child(lighting_title)
	var lighting_subtitle := _label("低亮度 · 三盏灯", 11, Color("a99db9"))
	lighting_subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lighting_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lighting_toolbar_row.add_child(lighting_subtitle)
	lighting_toggle_button = _button("展开调光", Color("493762"))
	lighting_toggle_button.custom_minimum_size = Vector2(96, 38)
	lighting_toggle_button.pressed.connect(_toggle_lighting_editor)
	lighting_toolbar_row.add_child(lighting_toggle_button)

	lighting_editor_panel = PanelContainer.new()
	lighting_editor_panel.position = Vector2(24, 228)
	lighting_editor_panel.size = Vector2(320, 446)
	lighting_editor_panel.visible = false
	lighting_editor_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	lighting_editor_panel.z_index = 10
	lighting_editor_panel.add_theme_stylebox_override("panel", _style(Color("211b33f5"), 18, Color("8169a6a8"), 1))
	ui_root.add_child(lighting_editor_panel)
	var lighting_margin := MarginContainer.new()
	lighting_margin.add_theme_constant_override("margin_left", 15)
	lighting_margin.add_theme_constant_override("margin_right", 15)
	lighting_margin.add_theme_constant_override("margin_top", 14)
	lighting_margin.add_theme_constant_override("margin_bottom", 14)
	lighting_editor_panel.add_child(lighting_margin)
	var lighting_scroll := ScrollContainer.new()
	lighting_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lighting_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lighting_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lighting_scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	lighting_margin.add_child(lighting_scroll)
	var lighting_vbox := VBoxContainer.new()
	lighting_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lighting_vbox.add_theme_constant_override("separation", 7)
	lighting_scroll.add_child(lighting_vbox)
	var selector_row := HBoxContainer.new()
	selector_row.add_theme_constant_override("separation", 10)
	lighting_vbox.add_child(selector_row)
	var selector_label := _label("正在编辑", 13, Color("c8bdd5"))
	selector_label.custom_minimum_size = Vector2(104, 34)
	selector_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	selector_row.add_child(selector_label)
	light_selector = OptionButton.new()
	light_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	light_selector.focus_mode = Control.FOCUS_NONE
	light_selector.add_item("主光 · Key", 0)
	light_selector.add_item("补光 · Fill", 1)
	light_selector.add_item("强调光 · Accent", 2)
	light_selector.add_theme_font_size_override("font_size", 13)
	light_selector.add_theme_color_override("font_color", Color("f3edf8"))
	light_selector.add_theme_stylebox_override("normal", _style(Color("39304e"), 10))
	light_selector.item_selected.connect(_on_light_selected)
	selector_row.add_child(light_selector)

	var global_row := _add_lighting_slider_row(lighting_vbox, "全局亮度", 0.02, 1.0, 0.01)
	global_light_slider = global_row.slider as HSlider
	global_light_value_label = global_row.value_label as Label
	global_light_slider.value_changed.connect(_on_global_light_changed)
	var saturation_row := _add_lighting_slider_row(lighting_vbox, "整体饱和度", 0.0, 2.0, 0.01)
	saturation_slider = saturation_row.slider as HSlider
	saturation_value_label = saturation_row.value_label as Label
	saturation_slider.value_changed.connect(_on_saturation_changed)
	var energy_row := _add_lighting_slider_row(lighting_vbox, "灯光强度", 0.0, 4.0, 0.01)
	light_energy_slider = energy_row.slider as HSlider
	light_energy_value_label = energy_row.value_label as Label
	light_energy_slider.value_changed.connect(_on_light_energy_changed)
	var temperature_row := _add_lighting_slider_row(lighting_vbox, "色温", 1800.0, 12000.0, 100.0)
	light_temperature_slider = temperature_row.slider as HSlider
	light_temperature_value_label = temperature_row.value_label as Label
	light_temperature_slider.value_changed.connect(_on_light_temperature_changed)

	var color_row := HBoxContainer.new()
	color_row.add_theme_constant_override("separation", 10)
	lighting_vbox.add_child(color_row)
	var color_label := _label("颜色方式", 13, Color("c8bdd5"))
	color_label.custom_minimum_size = Vector2(104, 34)
	color_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	color_row.add_child(color_label)
	light_color_mode_selector = OptionButton.new()
	light_color_mode_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	light_color_mode_selector.custom_minimum_size = Vector2(0, 34)
	light_color_mode_selector.focus_mode = Control.FOCUS_NONE
	light_color_mode_selector.add_item("色温模式", 0)
	light_color_mode_selector.add_item("自定义颜色", 1)
	light_color_mode_selector.item_selected.connect(_on_light_color_mode_selected)
	color_row.add_child(light_color_mode_selector)
	var color_picker_row := HBoxContainer.new()
	color_picker_row.add_theme_constant_override("separation", 10)
	lighting_vbox.add_child(color_picker_row)
	var color_picker_label := _label("自定义颜色", 13, Color("c8bdd5"))
	color_picker_label.custom_minimum_size = Vector2(104, 34)
	color_picker_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	color_picker_row.add_child(color_picker_label)
	light_color_picker = ColorPickerButton.new()
	light_color_picker.text = "选择颜色"
	light_color_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	light_color_picker.custom_minimum_size = Vector2(0, 34)
	light_color_picker.focus_mode = Control.FOCUS_NONE
	light_color_picker.color_changed.connect(_on_light_custom_color_changed)
	color_picker_row.add_child(light_color_picker)

	var range_row := _add_lighting_slider_row(lighting_vbox, "局部灯范围", 1.0, 12.0, 0.1)
	light_range_row = range_row.row as Control
	light_range_slider = range_row.slider as HSlider
	light_range_value_label = range_row.value_label as Label
	light_range_slider.value_changed.connect(_on_light_range_changed)
	var position_x_row := _add_lighting_slider_row(lighting_vbox, "位置 X", -6.0, 6.0, 0.1)
	light_position_rows.append(position_x_row.row as Control)
	light_position_x_slider = position_x_row.slider as HSlider
	light_position_x_value_label = position_x_row.value_label as Label
	light_position_x_slider.value_changed.connect(_on_light_position_changed.bind(0))
	var position_y_row := _add_lighting_slider_row(lighting_vbox, "位置 Y", 0.5, 8.0, 0.1)
	light_position_rows.append(position_y_row.row as Control)
	light_position_y_slider = position_y_row.slider as HSlider
	light_position_y_value_label = position_y_row.value_label as Label
	light_position_y_slider.value_changed.connect(_on_light_position_changed.bind(1))
	var position_z_row := _add_lighting_slider_row(lighting_vbox, "位置 Z", -6.0, 6.0, 0.1)
	light_position_rows.append(position_z_row.row as Control)
	light_position_z_slider = position_z_row.slider as HSlider
	light_position_z_value_label = position_z_row.value_label as Label
	light_position_z_slider.value_changed.connect(_on_light_position_changed.bind(2))
	var direction_yaw_row := _add_lighting_slider_row(lighting_vbox, "主光水平", -180.0, 180.0, 1.0)
	key_direction_rows.append(direction_yaw_row.row as Control)
	key_direction_yaw_slider = direction_yaw_row.slider as HSlider
	key_direction_yaw_value_label = direction_yaw_row.value_label as Label
	key_direction_yaw_slider.value_changed.connect(_on_key_direction_changed.bind(0))
	var direction_pitch_row := _add_lighting_slider_row(lighting_vbox, "主光俯仰", -85.0, -10.0, 1.0)
	key_direction_rows.append(direction_pitch_row.row as Control)
	key_direction_pitch_slider = direction_pitch_row.slider as HSlider
	key_direction_pitch_value_label = direction_pitch_row.value_label as Label
	key_direction_pitch_slider.value_changed.connect(_on_key_direction_changed.bind(1))
	light_shadow_toggle = CheckButton.new()
	light_shadow_toggle.text = "启用阴影（最多 2 盏）"
	light_shadow_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	light_shadow_toggle.custom_minimum_size = Vector2(0, 38)
	light_shadow_toggle.focus_mode = Control.FOCUS_NONE
	light_shadow_toggle.add_theme_font_size_override("font_size", 12)
	light_shadow_toggle.toggled.connect(_on_light_shadow_toggled)
	lighting_vbox.add_child(light_shadow_toggle)
	var reset_lighting_button := _button("恢复低亮度默认", Color("50384c"))
	reset_lighting_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_lighting_button.pressed.connect(_reset_lighting)
	lighting_vbox.add_child(reset_lighting_button)
	_sync_lighting_controls()
	_build_case_light_calibration_ui()

	overview_button = _button("⌂  返回全景", Color("3b3152"))
	overview_button.set_anchors_preset(Control.PRESET_CENTER_TOP)
	overview_button.offset_left = -71
	overview_button.offset_right = 71
	overview_button.offset_top = 22
	overview_button.offset_bottom = 60
	overview_button.visible = false
	overview_button.z_index = UI_Z_CONTEXT
	overview_button.pressed.connect(_focus_overview)
	ui_root.add_child(overview_button)

	furniture_menu = PanelContainer.new()
	furniture_menu.name = "FurnitureActionMenu"
	furniture_menu.size = Vector2(286, 94)
	furniture_menu.visible = false
	furniture_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	furniture_menu.z_index = UI_Z_CONTEXT
	furniture_menu.add_theme_stylebox_override("panel", _style(Color("241d38f7"), 16, Color("9a7cc5c0"), 1))
	ui_root.add_child(furniture_menu)
	var furniture_menu_margin := MarginContainer.new()
	furniture_menu_margin.add_theme_constant_override("margin_left", 12)
	furniture_menu_margin.add_theme_constant_override("margin_right", 12)
	furniture_menu_margin.add_theme_constant_override("margin_top", 10)
	furniture_menu_margin.add_theme_constant_override("margin_bottom", 10)
	furniture_menu.add_child(furniture_menu_margin)
	var furniture_menu_vbox := VBoxContainer.new()
	furniture_menu_vbox.add_theme_constant_override("separation", 7)
	furniture_menu_margin.add_child(furniture_menu_vbox)
	furniture_menu_title = _label("已选择家具", 13, Color("eadff5"))
	furniture_menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	furniture_menu_vbox.add_child(furniture_menu_title)
	var furniture_menu_actions := HBoxContainer.new()
	furniture_menu_actions.add_theme_constant_override("separation", 8)
	furniture_menu_vbox.add_child(furniture_menu_actions)
	var inspect_button := _button("检视", Color("59417b"))
	inspect_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspect_button.custom_minimum_size = Vector2(0, 38)
	inspect_button.pressed.connect(_inspect_selected_from_menu)
	furniture_menu_actions.add_child(inspect_button)
	rotate_action_button = _button("旋转", Color("435a72"))
	rotate_action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rotate_action_button.custom_minimum_size = Vector2(0, 38)
	rotate_action_button.pressed.connect(_enter_rotation_mode)
	furniture_menu_actions.add_child(rotate_action_button)
	var collect_button := _button("收纳", Color("3f6354"))
	collect_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collect_button.custom_minimum_size = Vector2(0, 38)
	collect_button.pressed.connect(_collect_selected_from_menu)
	furniture_menu_actions.add_child(collect_button)

	catalog_panel = PanelContainer.new()
	catalog_panel.name = "ArchiveInventoryPanel"
	catalog_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	catalog_panel.offset_left = -286
	catalog_panel.offset_right = -20
	catalog_panel.offset_top = 20
	catalog_panel.offset_bottom = -82
	catalog_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	catalog_panel.add_theme_stylebox_override("panel", PAPER_UI.paper("inventory"))
	ui_root.add_child(catalog_panel)

	var catalog_margin := MarginContainer.new()
	catalog_margin.add_theme_constant_override("margin_left", 18)
	catalog_margin.add_theme_constant_override("margin_right", 18)
	catalog_margin.add_theme_constant_override("margin_top", 35)
	catalog_margin.add_theme_constant_override("margin_bottom", 16)
	catalog_panel.add_child(catalog_margin)
	var catalog_vbox := VBoxContainer.new()
	catalog_vbox.add_theme_constant_override("separation", 7)
	catalog_margin.add_child(catalog_vbox)
	var catalog_title := _label("家具栏", 22, Color("fff8ff"))
	catalog_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	catalog_vbox.add_child(catalog_title)
	var header_gap := Control.new()
	header_gap.custom_minimum_size.y = 25
	catalog_vbox.add_child(header_gap)
	var catalog_subtitle := _label("查看资料获得线索 · 解锁后拖出摆放", 12, Color("a9a0b8"))
	catalog_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	catalog_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	catalog_vbox.add_child(catalog_subtitle)
	var divider := HSeparator.new()
	divider.add_theme_constant_override("separation", 5)
	divider.add_theme_stylebox_override("separator", _style(Color("73678355"), 1))
	catalog_vbox.add_child(divider)

	var scroll := ScrollContainer.new()
	scroll.name = "FurnitureScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	catalog_vbox.add_child(scroll)
	catalog_item_list = VBoxContainer.new()
	catalog_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	catalog_item_list.add_theme_constant_override("separation", 8)
	scroll.add_child(catalog_item_list)
	_refresh_inventory_ui()

	var actions := HBoxContainer.new()
	actions.name = "ArchiveInventoryActions"
	actions.add_theme_constant_override("separation", 8)
	ui_root.add_child(actions)
	actions.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	actions.offset_left = -286
	actions.offset_right = -20
	actions.offset_top = -70
	actions.offset_bottom = -20
	undo_button = _button("↶  撤销", Color("3a3150"))
	undo_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	undo_button.pressed.connect(_undo_last)
	actions.add_child(undo_button)
	clear_button = _button("全部收纳", Color("503042"))
	clear_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_button.pressed.connect(_clear_room)
	actions.add_child(clear_button)

	status_panel = PanelContainer.new()
	status_panel.name = "ArchiveStatusPanel"
	status_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	status_panel.offset_left = -300
	status_panel.offset_right = 190
	status_panel.offset_top = -66
	status_panel.offset_bottom = -22
	status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_panel.add_theme_stylebox_override("panel", PAPER_UI.paper("strip"))
	ui_root.add_child(status_panel)
	status_label = _label("", 13, Color.WHITE)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_panel.add_child(status_label)

	rotation_mode_overlay = ColorRect.new()
	rotation_mode_overlay.name = "RotationModeOverlay"
	rotation_mode_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rotation_mode_overlay.color = Color(0.02, 0.015, 0.04, 0.14)
	rotation_mode_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	rotation_mode_overlay.visible = false
	rotation_mode_overlay.z_index = UI_Z_ROTATION_MODAL
	ui_root.add_child(rotation_mode_overlay)
	rotation_mode_panel = PanelContainer.new()
	rotation_mode_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	rotation_mode_panel.offset_left = -220
	rotation_mode_panel.offset_right = 220
	rotation_mode_panel.offset_top = 20
	rotation_mode_panel.offset_bottom = 80
	rotation_mode_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	rotation_mode_panel.add_theme_stylebox_override("panel", _style(Color("241d38fa"), 16, Color("9a7cc5d8"), 1))
	rotation_mode_overlay.add_child(rotation_mode_panel)
	var rotation_margin := MarginContainer.new()
	rotation_margin.add_theme_constant_override("margin_left", 14)
	rotation_margin.add_theme_constant_override("margin_right", 10)
	rotation_margin.add_theme_constant_override("margin_top", 8)
	rotation_margin.add_theme_constant_override("margin_bottom", 8)
	rotation_mode_panel.add_child(rotation_margin)
	var rotation_row := HBoxContainer.new()
	rotation_row.add_theme_constant_override("separation", 12)
	rotation_margin.add_child(rotation_row)
	var rotation_title := _label("旋转模式 · 拖动红绿蓝 XYZ 环", 14, Color("f4ebff"))
	rotation_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rotation_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rotation_row.add_child(rotation_title)
	var rotation_confirm_button := _button("确定", Color("476a59"))
	rotation_confirm_button.custom_minimum_size = Vector2(92, 40)
	rotation_confirm_button.pressed.connect(_confirm_rotation_mode)
	rotation_row.add_child(rotation_confirm_button)

	_apply_case_scene_controls(ui_root)
	case_file_ui = CaseFileUI.new()
	case_file_ui.setup(_get_case_manager())
	case_file_ui.z_index = UI_Z_CASE_FILES
	case_file_ui.closed.connect(_on_case_files_closed)
	case_file_ui.evidence_opened.connect(_on_evidence_opened_for_reference)
	ui_root.add_child(case_file_ui)

	photo_reference_tray = ReferencePhotoTray.new()
	photo_reference_tray.setup(_get_case_manager())
	photo_reference_tray.z_index = 10
	ui_root.add_child(photo_reference_tray)

	scene_clue_popup = SceneCluePopup.new()
	scene_clue_popup.z_index = UI_Z_SCENE_CLUE
	ui_root.add_child(scene_clue_popup)

	first_case_flow_ui = FirstCaseFlowUI.new()
	first_case_flow_ui.setup(_get_case_manager())
	first_case_flow_ui.z_index = UI_Z_CASE_FLOW
	first_case_flow_ui.briefing_accepted.connect(_on_first_case_briefing_accepted)
	first_case_flow_ui.submit_requested.connect(_submit_first_case_reconstruction)
	first_case_flow_ui.photo_requested.connect(_capture_and_archive_case)
	first_case_flow_ui.settlement_closed.connect(_return_to_workbench)
	ui_root.add_child(first_case_flow_ui)
	_build_overview_pan_controls()


func _open_case_files() -> void:
	if not is_instance_valid(case_file_ui):
		return
	if not active_kind.is_empty():
		_cancel_placement()
	if rotation_mode:
		return
	_hide_furniture_menu()
	if is_instance_valid(lighting_editor_panel):
		lighting_editor_panel.visible = false
	if is_instance_valid(lighting_toggle_button):
		lighting_toggle_button.text = "展开调光"
	if is_instance_valid(case_light_editor_panel):
		case_light_editor_panel.visible = false
	if is_instance_valid(case_light_toggle_button):
		case_light_toggle_button.text = "展开校准"
	_set_furniture_editing_enabled(false)
	case_file_ui.open_files()


func _on_case_files_closed() -> void:
	if not camera_focused and not camera_transitioning and not rotation_mode:
		_set_furniture_editing_enabled(true)


func _on_first_case_briefing_accepted() -> void:
	var manager := _get_case_manager()
	var briefing := manager.call("get_briefing_data") as Dictionary if is_instance_valid(manager) else {}
	_set_status(
		String(briefing.get("accepted_status", "现场已载入 · 打开案件资料开始校准")),
		Color("cbbce5")
	)


func _submit_first_case_reconstruction() -> void:
	if not is_instance_valid(first_case_flow_ui):
		return
	var case_manager := _get_case_manager()
	var reconstruction_manager := _get_reconstruction_manager()
	if not is_instance_valid(case_manager) or not is_instance_valid(reconstruction_manager):
		return
	var completion: Dictionary = case_manager.call("get_completion_data")
	var required_step := String(completion.get("required_reconstruction_step_id", ""))
	var required_clues: Array = completion.get("required_clue_ids", [])
	var step_completed := (
		required_step.is_empty()
		or bool(reconstruction_manager.call("is_step_satisfied", required_step))
	)
	var clues_completed := bool(case_manager.call("are_clues_discovered", required_clues))
	if not step_completed or not clues_completed:
		first_case_flow_ui.show_submit_failure(String(completion.get(
			"failure_message",
			"当前现场还没有完成，请继续核对资料和家具位置。"
		)))
		return
	_hide_furniture_menu()
	_set_furniture_editing_enabled(false)
	first_case_flow_ui.show_settlement()


func _return_to_workbench() -> void:
	var profile := get_node_or_null("/root/PlayerProfile")
	var case_manager := _get_case_manager()
	if is_instance_valid(profile) and is_instance_valid(case_manager):
		var case_id := String((case_manager.call("get_case_summary") as Dictionary).get("case_id", ""))
		if not bool((profile.get("completed_cases") as Dictionary).get(case_id, false)):
			profile.call("complete_case", case_id, captured_case_photo_path)
	var flow := get_node_or_null("/root/GameFlow")
	if is_instance_valid(flow):
		await flow.call("return_to_studio")


func _capture_and_archive_case() -> void:
	if not is_instance_valid(first_case_flow_ui):
		return
	first_case_flow_ui.begin_photo_capture()
	ui_root.visible = false
	await get_tree().process_frame
	await get_tree().process_frame
	var case_manager := _get_case_manager()
	var profile := get_node_or_null("/root/PlayerProfile")
	var case_id := String((case_manager.call("get_case_summary") as Dictionary).get("case_id", "")) if is_instance_valid(case_manager) else ""
	captured_case_photo_path = _capture_case_photo(case_id)
	ui_root.visible = true
	if is_instance_valid(profile) and not case_id.is_empty():
		profile.call("complete_case", case_id, captured_case_photo_path)
	first_case_flow_ui.finish_photo_capture(not captured_case_photo_path.is_empty())


func _capture_case_photo(case_id: String) -> String:
	if case_id.is_empty():
		return ""
	var directory := "user://case_album"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var path := "%s/%s.png" % [directory, case_id]
	var image := get_viewport().get_texture().get_image()
	if image.is_empty() or image.save_png(path) != OK:
		return ""
	return path


func _on_evidence_opened_for_reference(evidence_id: String) -> void:
	if is_instance_valid(photo_reference_tray):
		photo_reference_tray.add_reference(evidence_id)


func _build_overview_pan_controls() -> void:
	if not bool(runtime_layout.get("overview_pan", false)):
		return
	var row := HBoxContainer.new()
	row.name = "OverviewPanControls"
	row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	row.offset_left = -185
	row.offset_right = 185
	row.offset_top = -142
	row.offset_bottom = -96
	row.z_index = 5
	row.add_theme_constant_override("separation", 10)
	ui_root.add_child(row)
	var left := _button("◀  查看左侧房间", Color("3f3855"))
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.pressed.connect(func() -> void: _pan_overview(-1.0))
	row.add_child(left)
	var center := _button("居中", Color("4c435f"))
	center.pressed.connect(func() -> void: _pan_overview(0.0))
	row.add_child(center)
	var right := _button("查看右侧房间  ▶", Color("3f3855"))
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.pressed.connect(func() -> void: _pan_overview(1.0))
	row.add_child(right)


func _pan_overview(direction: float) -> void:
	if camera_focused or camera_transitioning:
		return
	overview_pan_offset = direction * minf(3.0, runtime_room_width * 0.23)
	_animate_camera(runtime_overview_target + Vector3(overview_pan_offset, 0, 0), OVERVIEW_CAMERA_FOV)


func _refresh_inventory_ui() -> void:
	if not is_instance_valid(catalog_item_list):
		return
	for child: Node in catalog_item_list.get_children():
		child.queue_free()
	var has_items := false
	for item: Dictionary in FurnitureFactory.CATALOG:
		var kind := String(item.kind)
		var item_count := int(inventory_counts.get(kind, 0))
		for index: int in range(item_count):
			var card := CatalogItem.new()
			var card_data := _furniture_info(kind).duplicate(true)
			card_data["visual_style"] = "case_dossier"
			card.setup(card_data)
			card.drag_started.connect(_begin_placement)
			catalog_item_list.add_child(card)
			has_items = true
	if not has_items:
		var empty := VBoxContainer.new()
		empty.name = "EmptyArchiveState"
		empty.custom_minimum_size = Vector2(0,300)
		empty.alignment = BoxContainer.ALIGNMENT_CENTER
		empty.add_theme_constant_override("separation",16)
		catalog_item_list.add_child(empty)
		var empty_label := _label("—  家具栏为空  —\n\n查看案件资料以解锁家具", 13, Color("958aa6"))
		empty_label.custom_minimum_size = Vector2(0, 92)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_child(empty_label)


func _add_to_inventory(kind: String) -> void:
	inventory_counts[kind] = int(inventory_counts.get(kind, 0)) + 1
	_refresh_inventory_ui()


func _take_from_inventory(kind: String) -> bool:
	var count := int(inventory_counts.get(kind, 0))
	if count <= 0:
		return false
	inventory_counts[kind] = count - 1
	_refresh_inventory_ui()
	return true


func _begin_placement(kind: String) -> void:
	if camera_focused or camera_transitioning:
		_set_status("近景查看中不可摆放家具，请先返回全景", Color("f0bd7a"))
		return
	_cancel_placement(false)
	if not _take_from_inventory(kind):
		_set_status("背包中没有这件家具", Color("e9b2bd"))
		return
	_clear_selection(true)
	moving_existing = false
	placing_from_inventory = true
	editing_item = {}
	active_kind = kind
	preview_rotation_degrees = Vector3.ZERO
	preview_surface_height = 0.0
	preview_support_node = null
	preview_support_surface_id = ""
	active_preview = _build_furniture(kind, true)
	preview_root.add_child(active_preview)
	_add_preview_base()
	active_preview.visible = false
	placement_valid = false
	_last_valid_state = false
	_has_preview_tint = false
	_set_status("自由拖动中 · Q/E 每次旋转 90° · 松开确认放置", Color("d6c4ed"))


func _rotate_active_preview(angle_step: float) -> void:
	if active_kind.is_empty() or not is_instance_valid(active_preview):
		return
	preview_rotation_degrees.y = fposmod(preview_rotation_degrees.y + angle_step, 360.0)
	active_preview.rotation_degrees = preview_rotation_degrees
	_has_preview_tint = false
	_update_active_preview()


func _update_active_preview() -> void:
	if not is_instance_valid(active_preview):
		return
	var mouse_position := get_viewport().get_mouse_position()
	var panel_left := get_viewport().get_visible_rect().size.x - 306.0
	if mouse_position.x >= panel_left:
		active_preview.visible = false
		_sync_moving_supported_items(active_preview.global_transform, false)
		if is_instance_valid(preview_bounds_marker):
			preview_bounds_marker.visible = false
		placement_valid = false
		_set_drag_status("把家具拖进左侧房间", Color("bcb1c9"))
		return

	var origin := camera.project_ray_origin(mouse_position)
	var direction := camera.project_ray_normal(mouse_position)
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)
	if hit == null:
		active_preview.visible = false
		_sync_moving_supported_items(active_preview.global_transform, false)
		if is_instance_valid(preview_bounds_marker):
			preview_bounds_marker.visible = false
		placement_valid = false
		return

	var info := _furniture_info(active_kind)
	var object_size: Vector3 = info.size
	preview_bounds_size = _projected_bounds_size(object_size, preview_rotation_degrees)
	preview_bounds_offset = _projected_bounds_offset(object_size, preview_rotation_degrees)
	var hit_position: Vector3 = hit
	var placement_origin := hit_position
	preview_surface_height = 0.0
	preview_support_node = null
	preview_support_surface_id = ""
	var snap_data := _find_surface_snap(
		active_kind,
		hit_position,
		object_size,
		preview_rotation_degrees,
		mouse_position,
		origin,
		direction
	)
	if not snap_data.is_empty():
		placement_origin = snap_data.get("origin", hit_position)
		preview_surface_height = float(snap_data.get("surface_height", 0.0))
		preview_support_node = snap_data.get("support", null) as Node3D
		preview_support_surface_id = String(snap_data.get("surface_id", ""))
	active_preview.position = Vector3(
		placement_origin.x,
		preview_surface_height + _ground_offset_for_rotation(object_size, preview_rotation_degrees) + 0.045,
		placement_origin.z
	)
	active_preview.rotation_degrees = preview_rotation_degrees
	active_preview.visible = true
	_sync_moving_supported_items(active_preview.global_transform, true)
	_update_preview_bounds_marker(placement_origin)

	var ignored_node := editing_item.get("node", null) as Node3D if moving_existing else null
	placement_valid = _can_place_at(
		placement_origin,
		preview_bounds_size,
		preview_bounds_offset,
		ignored_node,
		preview_support_node,
		preview_support_surface_id
	)
	_update_preview_tint(placement_valid)
	if placement_valid:
		if is_instance_valid(preview_support_node):
			if preview_support_surface_id.begins_with("shelf_layer_"):
				var layer_label := preview_support_surface_id.trim_prefix("shelf_layer_")
				_set_drag_status(
					"已吸附文件柜第 %s 层 · Q/E 每次旋转 90° · 松开确认" % layer_label,
					Color("8fe2c0")
				)
			else:
				_set_drag_status("已吸附桌面 · Q/E 每次旋转 90° · 松开确认", Color("8fe2c0"))
		else:
			_set_drag_status("Q/E 每次旋转 90° · 松开放置并启用重力", Color("98e3b4"))
	else:
		_set_drag_status("这里放不下，请换一个位置", Color("ff9da6"))


func _finish_placement() -> void:
	if not placement_valid or not is_instance_valid(active_preview) or not active_preview.visible:
		_cancel_placement()
		return
	if moving_existing:
		_commit_existing_move()
		return

	var placed := _build_furniture(active_kind)
	placed.position = active_preview.position
	var placed_info := _furniture_info(active_kind)
	var object_size: Vector3 = placed_info.size
	placed.position.y = (
		preview_surface_height
		+ _ground_offset_for_rotation(object_size, preview_rotation_degrees)
		+ _placement_clearance(preview_support_node)
	)
	placed.rotation_degrees = preview_rotation_degrees
	furniture_root.add_child(placed)
	var placed_body := placed as RigidBody3D
	if is_instance_valid(placed_body):
		placed_body.linear_velocity = Vector3.ZERO
		placed_body.angular_velocity = Vector3.ZERO
		_set_placed_body_support_state(placed_body, preview_support_node)
	var base_footprint: Vector2i = placed_info.footprint
	placed_items.append({
		"node": placed,
		"cells": [],
		"kind": active_kind,
		"furniture_id": _furniture_id_for_kind(active_kind),
		"footprint": base_footprint,
		"object_size": object_size,
		"bounds_size": preview_bounds_size,
		"bounds_offset": preview_bounds_offset,
		"rotation_degrees": preview_rotation_degrees,
		"support_node": preview_support_node,
		"support_surface_id": preview_support_surface_id,
		"requires_collection": false
	})
	_notify_reconstruction_placement_completed(placed)
	var item_name: String = _furniture_info(active_kind).label
	placing_from_inventory = false
	_cancel_placement(false)
	_set_status("已放置「%s」· 正在受重力落地 · 选中后可拖动 XYZ 旋转环" % item_name, Color("a7e5bb"))


func _cancel_placement(show_message: bool = true) -> void:
	if moving_existing and not editing_item.is_empty():
		_restore_moving_supported_items()
		var original_node: Node3D = editing_item.node
		if is_instance_valid(original_node):
			original_node.visible = true
			var original_body := original_node as RigidBody3D
			if is_instance_valid(original_body):
				original_body.freeze = false
				original_body.sleeping = true
			for cell: Vector2i in editing_item.cells:
				occupied[cell] = original_node
		selected_item = editing_item
		_update_selection_marker()
	if placing_from_inventory and not active_kind.is_empty():
		_add_to_inventory(active_kind)
	if is_instance_valid(active_preview):
		active_preview.queue_free()
	if is_instance_valid(preview_bounds_marker):
		preview_bounds_marker.queue_free()
	active_preview = null
	preview_bounds_marker = null
	active_kind = ""
	preview_surface_height = 0.0
	preview_support_node = null
	preview_support_surface_id = ""
	placement_valid = false
	_has_preview_tint = false
	_last_status = ""
	moving_existing = false
	moving_supported_items.clear()
	placing_from_inventory = false
	editing_item = {}
	pending_world_drag = false
	if show_message:
		if selected_item.is_empty():
			_set_status("已取消放置", Color("bdb2ca"))
		else:
			_set_selection_status("已恢复原位置")


func _handle_world_press(screen_position: Vector2) -> void:
	var panel_left := get_viewport().get_visible_rect().size.x - 306.0
	if screen_position.x >= panel_left:
		return
	_hide_furniture_menu()
	if _try_investigate_scene_clue(screen_position):
		pending_world_drag = false
		return

	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 100.0, 2)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		_clear_selection(true)
		return

	var collider := result.collider as Area3D
	if not is_instance_valid(collider):
		_clear_selection(true)
		return
	var furniture_node := collider.get_meta("furniture_root", null) as Node3D
	var entry := _find_entry_by_node(furniture_node)
	if entry.is_empty():
		_clear_selection(true)
		return

	_select_item(entry)
	pending_world_drag = true
	world_press_position = screen_position


func _try_investigate_scene_clue(screen_position: Vector2) -> bool:
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(
		origin,
		origin + direction * 100.0,
		SCENE_CLUE_PHYSICS_LAYER
	)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return false
	var clue_point := result.collider as SceneCluePoint
	if not is_instance_valid(clue_point):
		return false
	return clue_point.investigate()


func _select_item(entry: Dictionary) -> void:
	selected_item = entry
	_update_selection_marker()
	_set_selection_status()


func _show_furniture_menu(screen_position: Vector2) -> void:
	if selected_item.is_empty() or camera_focused or camera_transitioning:
		return
	var furniture_node: Node3D = selected_item.node
	if not is_instance_valid(furniture_node) or not is_instance_valid(furniture_menu):
		return
	var item_name: String = _furniture_info(selected_item.kind).label
	furniture_menu_title.text = "已选择「%s」" % item_name
	var can_rotate := furniture_node is RigidBody3D and not bool(selected_item.get("requires_collection", false))
	if is_instance_valid(rotate_action_button):
		rotate_action_button.disabled = not can_rotate
		rotate_action_button.tooltip_text = "" if can_rotate else "请先将现场家具收纳并重新放置"
	var viewport_size := get_viewport().get_visible_rect().size
	var menu_size := Vector2(286, 94)
	var catalog_left := viewport_size.x - 306.0
	var menu_x := screen_position.x + 16.0
	if menu_x + menu_size.x > catalog_left - 8.0:
		menu_x = screen_position.x - menu_size.x - 16.0
	menu_x = clampf(menu_x, 12.0, catalog_left - menu_size.x - 8.0)
	var menu_y := clampf(screen_position.y - menu_size.y * 0.5, 88.0, viewport_size.y - menu_size.y - 78.0)
	furniture_menu.position = Vector2(menu_x, menu_y)
	furniture_menu.size = menu_size
	furniture_menu.visible = true


func _hide_furniture_menu() -> void:
	if is_instance_valid(furniture_menu):
		furniture_menu.visible = false


func _is_pointer_over_furniture_menu(screen_position: Vector2) -> bool:
	return is_instance_valid(furniture_menu) and furniture_menu.visible and furniture_menu.get_global_rect().has_point(screen_position)


func _inspect_selected_from_menu() -> void:
	_hide_furniture_menu()
	_focus_selected_furniture()


func _collect_selected_from_menu() -> void:
	_hide_furniture_menu()
	_collect_selected()


func _enter_rotation_mode() -> void:
	if selected_item.is_empty() or camera_focused or camera_transitioning:
		return
	if bool(selected_item.get("requires_collection", false)):
		_set_status("请先收纳现场家具并重新放置，再进行旋转", Color("f0bd7a"))
		return
	var furniture_body := selected_item.get("node", null) as RigidBody3D
	if not is_instance_valid(furniture_body):
		_set_status("这件家具暂不支持物理旋转", Color("e9b2bd"))
		return
	_hide_furniture_menu()
	pending_world_drag = false
	rotation_mode = true
	furniture_body.freeze = true
	furniture_body.linear_velocity = Vector3.ZERO
	furniture_body.angular_velocity = Vector3.ZERO
	_prepare_moving_supported_items(furniture_body, false)
	_sync_moving_supported_items(furniture_body.global_transform, true)
	if is_instance_valid(selection_marker):
		selection_marker.visible = false
	_destroy_rotation_gizmo()
	_create_rotation_gizmo()
	if is_instance_valid(rotation_mode_overlay):
		rotation_mode_overlay.visible = true
	if is_instance_valid(lighting_editor_panel):
		lighting_editor_panel.visible = false
	if is_instance_valid(lighting_toggle_button):
		lighting_toggle_button.text = "展开调光"
	if is_instance_valid(case_light_editor_panel):
		case_light_editor_panel.visible = false
	if is_instance_valid(case_light_toggle_button):
		case_light_toggle_button.text = "展开校准"
	_set_furniture_editing_enabled(false)
	_set_status("独占旋转模式 · 只能拖动 XYZ 环 · 完成后点击上方“确定”", Color("ffd47e"))


func _confirm_rotation_mode() -> void:
	if not rotation_mode:
		return
	var furniture_body := selected_item.get("node", null) as RigidBody3D
	gizmo_dragging = false
	gizmo_axis_index = -1
	if is_instance_valid(furniture_body):
		furniture_body.position.y += 0.14
		_commit_moving_supported_items(furniture_body)
		furniture_body.linear_velocity = Vector3.ZERO
		furniture_body.angular_velocity = Vector3.ZERO
		furniture_body.freeze = false
		furniture_body.sleeping = false
		_notify_reconstruction_placement_completed(furniture_body)
	rotation_mode = false
	if is_instance_valid(rotation_mode_overlay):
		rotation_mode_overlay.visible = false
	_clear_selection(false)
	_set_furniture_editing_enabled(true)
	_focus_overview()
	_set_status("旋转已确认 · 重力已开启 · 已返回场景全景", Color("a7e5bb"))


func _clear_selection(restore_camera: bool = false) -> void:
	pending_world_drag = false
	_hide_furniture_menu()
	selected_item = {}
	if is_instance_valid(selection_marker):
		selection_marker.queue_free()
	selection_marker = null
	_destroy_rotation_gizmo()
	if restore_camera:
		_focus_overview()


func _focus_selected_furniture() -> void:
	if selected_item.is_empty():
		return
	_hide_furniture_menu()
	var furniture_node: Node3D = selected_item.node
	if not is_instance_valid(furniture_node):
		_clear_selection(true)
		return
	focus_target_position = furniture_node.global_position + Vector3(0, 0.72, 0)
	focus_yaw = 0.0
	focus_target_yaw = 0.0
	focus_pitch = 0.0
	focus_target_pitch = 0.0
	focus_fov = FOCUS_CAMERA_FOV
	focus_target_fov = FOCUS_CAMERA_FOV
	orbit_dragging = false
	focus_pan = Vector2.ZERO
	focus_target_pan = Vector2.ZERO
	focus_pan_dragging = false
	camera_focused = true
	_set_furniture_editing_enabled(false)
	if is_instance_valid(selection_marker):
		selection_marker.visible = false
	if is_instance_valid(rotation_gizmo):
		rotation_gizmo.visible = false
	if is_instance_valid(overview_button):
		overview_button.visible = true
	_set_status("正在进入近景查看……", Color("cbbce5"))
	_animate_camera(focus_target_position, FOCUS_CAMERA_FOV)


func _focus_overview() -> void:
	_hide_furniture_menu()
	_set_scene_clue_inspection_context(null)
	if not camera_focused and not camera_transitioning:
		_set_furniture_editing_enabled(true)
		if is_instance_valid(overview_button):
			overview_button.visible = false
		if is_instance_valid(rotation_gizmo) and not selected_item.is_empty():
			rotation_gizmo.visible = true
		if selected_item.is_empty():
			_set_status("全景编辑模式 · 拖动家具移动，单击家具打开菜单", Color("cbbce5"))
		else:
			_set_selection_status("全景编辑模式")
		return
	camera_focused = false
	orbit_dragging = false
	focus_pitch = 0.0
	focus_target_pitch = 0.0
	focus_pan = Vector2.ZERO
	focus_target_pan = Vector2.ZERO
	focus_pan_dragging = false
	if is_instance_valid(overview_button):
		overview_button.visible = false
	_set_status("正在返回房间全景……", Color("cbbce5"))
	_animate_camera(runtime_overview_target + Vector3(overview_pan_offset, 0.0, 0.0), OVERVIEW_CAMERA_FOV)


func _animate_camera(target: Vector3, target_fov: float) -> void:
	if not is_instance_valid(camera):
		return
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()
	camera_transition_id += 1
	var this_transition := camera_transition_id
	camera_transitioning = true
	var target_transform := camera.transform
	target_transform.origin = target + _camera_view_offset()
	target_transform = target_transform.looking_at(target, Vector3.UP)
	camera_tween = create_tween()
	camera_tween.set_parallel(true)
	camera_tween.set_trans(Tween.TRANS_CUBIC)
	camera_tween.set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(camera, "transform", target_transform, CAMERA_MOVE_DURATION)
	camera_tween.tween_property(camera, "fov", target_fov, CAMERA_MOVE_DURATION)
	camera_tween.finished.connect(_on_camera_transition_finished.bind(this_transition))


func _on_camera_transition_finished(transition_id: int) -> void:
	if transition_id != camera_transition_id:
		return
	camera_transitioning = false
	if camera_focused:
		var inspected_furniture := selected_item.get("node", null) as Node3D
		_set_scene_clue_inspection_context(inspected_furniture)
		_show_trace_counter_hint(inspected_furniture)
		focus_yaw = 0.0
		focus_target_yaw = 0.0
		focus_pitch = 0.0
		focus_target_pitch = 0.0
		focus_fov = camera.fov
		focus_target_fov = camera.fov
		_set_status("近景查看 · 左键上下/左右环绕（水平±45°、垂直±22°）· 中键平移 · 滚轮缩放", Color("9fd9f1"))
	else:
		_set_furniture_editing_enabled(true)
		if is_instance_valid(selection_marker) and not selected_item.is_empty():
			selection_marker.visible = true
		if is_instance_valid(rotation_gizmo) and not selected_item.is_empty():
			rotation_gizmo.visible = true
		if selected_item.is_empty():
			_set_status("全景编辑模式 · 拖动家具移动，单击家具打开菜单", Color("cbbce5"))
		else:
			_set_selection_status("已返回全景，可继续编辑")


func _set_scene_clue_inspection_context(furniture_node: Node3D) -> void:
	for point_node: Node in get_tree().get_nodes_in_group("scene_clue_points"):
		var clue_point := point_node as SceneCluePoint
		if is_instance_valid(clue_point):
			clue_point.set_inspection_context(furniture_node)


func _show_trace_counter_hint(furniture_node: Node3D) -> void:
	var profile := get_node_or_null("/root/PlayerProfile")
	if not is_instance_valid(profile) or not bool(profile.call("has_skill", "trace_counter")):
		return
	var count := 0
	if is_instance_valid(furniture_node):
		for point_node: Node in get_tree().get_nodes_in_group("scene_clue_points"):
			var point := point_node as SceneCluePoint
			if is_instance_valid(point) and furniture_node.is_ancestor_of(point) and point.is_unlocked and not point.is_discovered:
				count += 1
	if count > 0:
		_set_status("痕迹分析板：这个物体上仍有 %d 处可调查痕迹 · 不提供正确位置提示" % count, Color("efc986"))


func _set_furniture_editing_enabled(enabled: bool) -> void:
	if is_instance_valid(catalog_panel):
		catalog_panel.modulate = Color.WHITE if enabled else Color(0.58, 0.58, 0.66, 0.82)
	if is_instance_valid(undo_button):
		undo_button.disabled = not enabled
	if is_instance_valid(clear_button):
		clear_button.disabled = not enabled


func _begin_move_selected() -> void:
	if camera_focused or camera_transitioning or selected_item.is_empty() or not active_kind.is_empty():
		pending_world_drag = false
		return
	pending_world_drag = false
	if bool(selected_item.get("requires_collection", false)):
		_set_status("这件案发现场家具需先通过菜单收纳，再从背包拖出摆放", Color("f0bd7a"))
		_show_furniture_menu(world_press_position)
		return
	_hide_furniture_menu()
	editing_item = selected_item
	var original_node: Node3D = editing_item.node
	if not is_instance_valid(original_node):
		_clear_selection(true)
		return
	var original_body := original_node as RigidBody3D
	if is_instance_valid(original_body):
		original_body.freeze = true
		original_body.linear_velocity = Vector3.ZERO
		original_body.angular_velocity = Vector3.ZERO
	_prepare_moving_supported_items(original_node, true)
	for cell: Vector2i in editing_item.cells:
		occupied.erase(cell)
	original_node.visible = false
	if is_instance_valid(selection_marker):
		selection_marker.visible = false
	if is_instance_valid(rotation_gizmo):
		rotation_gizmo.visible = false

	moving_existing = true
	placing_from_inventory = false
	active_kind = editing_item.kind
	preview_rotation_degrees = _rotation_for_placement(editing_item)
	preview_surface_height = 0.0
	preview_support_node = null
	preview_support_surface_id = ""
	active_preview = _build_furniture(active_kind, true)
	preview_root.add_child(active_preview)
	_add_preview_base()
	active_preview.visible = false
	placement_valid = false
	_last_valid_state = false
	_has_preview_tint = false
	_set_status("自由移动中 · Q/E 每次旋转 90° · 松开后重新启用重力", Color("d9c4f1"))


func _commit_existing_move() -> void:
	var furniture_node: Node3D = editing_item.node
	var updated_entry := editing_item.duplicate()
	var item_info := _furniture_info(active_kind)
	var base_footprint: Vector2i = item_info.footprint
	var object_size: Vector3 = item_info.size
	furniture_node.position = active_preview.position
	furniture_node.position.y = (
		preview_surface_height
		+ _ground_offset_for_rotation(object_size, preview_rotation_degrees)
		+ _placement_clearance(preview_support_node)
	)
	furniture_node.rotation_degrees = preview_rotation_degrees
	furniture_node.visible = true
	var furniture_body := furniture_node as RigidBody3D
	if is_instance_valid(furniture_body):
		furniture_body.linear_velocity = Vector3.ZERO
		furniture_body.angular_velocity = Vector3.ZERO
	updated_entry.cells = []
	updated_entry.footprint = base_footprint
	updated_entry.object_size = object_size
	updated_entry.bounds_size = preview_bounds_size
	updated_entry.bounds_offset = preview_bounds_offset
	updated_entry.rotation_degrees = preview_rotation_degrees
	updated_entry.support_node = preview_support_node
	updated_entry.support_surface_id = preview_support_surface_id
	updated_entry.requires_collection = false
	var item_index := _find_entry_index(furniture_node)
	if item_index >= 0:
		placed_items[item_index] = updated_entry
	_commit_moving_supported_items(furniture_node)
	if is_instance_valid(furniture_body):
		_set_placed_body_support_state(furniture_body, preview_support_node)
	_notify_reconstruction_placement_completed(furniture_node)
	moving_existing = false
	editing_item = {}
	selected_item = updated_entry
	_cancel_placement(false)
	_update_selection_marker()
	_set_selection_status("位置已更新，正在受重力落地")


func _prepare_moving_supported_items(support_node: Node3D, hide_during_setup: bool) -> void:
	if not moving_supported_items.is_empty():
		_restore_moving_supported_items()
	if not is_instance_valid(support_node):
		return
	var support_inverse := support_node.global_transform.affine_inverse()
	for entry: Dictionary in placed_items:
		if entry.get("support_node", null) != support_node:
			continue
		var item_node := entry.get("node", null) as Node3D
		if not is_instance_valid(item_node) or item_node == support_node:
			continue
		var record := {
			"node": item_node,
			"relative_transform": support_inverse * item_node.global_transform,
			"original_global_transform": item_node.global_transform,
			"original_visible": item_node.visible,
			"was_frozen": false,
			"was_sleeping": false,
			"linear_velocity": Vector3.ZERO,
			"angular_velocity": Vector3.ZERO
		}
		var item_body := item_node as RigidBody3D
		if is_instance_valid(item_body):
			record.was_frozen = item_body.freeze
			record.was_sleeping = item_body.sleeping
			record.linear_velocity = item_body.linear_velocity
			record.angular_velocity = item_body.angular_velocity
			item_body.freeze = true
			item_body.linear_velocity = Vector3.ZERO
			item_body.angular_velocity = Vector3.ZERO
		if hide_during_setup:
			item_node.visible = false
		moving_supported_items.append(record)


func _sync_moving_supported_items(target_transform: Transform3D, target_visible: bool) -> void:
	for record: Dictionary in moving_supported_items:
		var item_node := record.get("node", null) as Node3D
		if not is_instance_valid(item_node):
			continue
		var relative_transform: Transform3D = record.get("relative_transform", Transform3D.IDENTITY)
		if target_visible:
			item_node.global_transform = target_transform * relative_transform
		item_node.visible = bool(record.get("original_visible", true)) and target_visible


func _restore_moving_supported_items() -> void:
	for record: Dictionary in moving_supported_items:
		var item_node := record.get("node", null) as Node3D
		if not is_instance_valid(item_node):
			continue
		var item_body := item_node as RigidBody3D
		if is_instance_valid(item_body):
			item_body.freeze = true
		item_node.global_transform = record.get("original_global_transform", item_node.global_transform)
		item_node.visible = bool(record.get("original_visible", true))
		if is_instance_valid(item_body):
			item_body.linear_velocity = record.get("linear_velocity", Vector3.ZERO)
			item_body.angular_velocity = record.get("angular_velocity", Vector3.ZERO)
			item_body.freeze = bool(record.get("was_frozen", false))
			item_body.sleeping = bool(record.get("was_sleeping", false))
	moving_supported_items.clear()


func _commit_moving_supported_items(support_node: Node3D) -> void:
	if not is_instance_valid(support_node):
		_restore_moving_supported_items()
		return
	for record: Dictionary in moving_supported_items:
		var item_node := record.get("node", null) as Node3D
		if not is_instance_valid(item_node):
			continue
		var relative_transform: Transform3D = record.get("relative_transform", Transform3D.IDENTITY)
		item_node.global_transform = support_node.global_transform * relative_transform
		item_node.visible = bool(record.get("original_visible", true))
		var item_index := _find_entry_index(item_node)
		if item_index >= 0:
			var updated_entry: Dictionary = placed_items[item_index].duplicate()
			var item_footprint: Vector2i = updated_entry.get("footprint", Vector2i.ONE)
			var item_size: Vector3 = updated_entry.get(
				"object_size",
				Vector3(item_footprint.x, 1.6, item_footprint.y)
			)
			var item_rotation := item_node.rotation_degrees
			updated_entry.rotation_degrees = item_rotation
			updated_entry.bounds_size = _projected_bounds_size(item_size, item_rotation)
			updated_entry.bounds_offset = _projected_bounds_offset(item_size, item_rotation)
			placed_items[item_index] = updated_entry
	for record: Dictionary in moving_supported_items:
		var item_body := record.get("node", null) as RigidBody3D
		if not is_instance_valid(item_body):
			continue
		item_body.linear_velocity = Vector3.ZERO
		item_body.angular_velocity = Vector3.ZERO
		item_body.freeze = false
		item_body.sleeping = false
	moving_supported_items.clear()


func _is_moving_supported_node(candidate: Node3D) -> bool:
	for record: Dictionary in moving_supported_items:
		if record.get("node", null) == candidate:
			return true
	return false


func _delete_selected() -> void:
	if camera_focused or camera_transitioning or selected_item.is_empty():
		return
	var furniture_node: Node3D = selected_item.node
	var item_name: String = _furniture_info(selected_item.kind).label
	for cell: Vector2i in selected_item.cells:
		occupied.erase(cell)
	var item_index := _find_entry_index(furniture_node)
	if item_index >= 0:
		placed_items.remove_at(item_index)
	if is_instance_valid(furniture_node):
		_unregister_reconstruction_furniture(furniture_node)
		furniture_node.queue_free()
	_clear_selection(true)
	_set_status("已删除「%s」" % item_name, Color("e9b2bd"))


func _collect_selected() -> void:
	if camera_focused or camera_transitioning or selected_item.is_empty():
		return
	var furniture_node: Node3D = selected_item.node
	var kind := String(selected_item.kind)
	var item_name: String = _furniture_info(kind).label
	for cell: Vector2i in selected_item.cells:
		occupied.erase(cell)
	var item_index := _find_entry_index(furniture_node)
	if item_index >= 0:
		placed_items.remove_at(item_index)
	if is_instance_valid(furniture_node):
		_unregister_reconstruction_furniture(furniture_node)
		furniture_node.queue_free()
	_clear_selection(false)
	_add_to_inventory(kind)
	_set_status("已将「%s」摆正收纳进背包，可从右侧拖出" % item_name, Color("9fe0bd"))


func _find_entry_by_node(furniture_node: Node3D) -> Dictionary:
	if not is_instance_valid(furniture_node):
		return {}
	for entry: Dictionary in placed_items:
		if entry.node == furniture_node:
			return entry
	return {}


func _find_entry_index(furniture_node: Node3D) -> int:
	for index: int in range(placed_items.size()):
		if placed_items[index].node == furniture_node:
			return index
	return -1


func _update_selection_marker() -> void:
	if is_instance_valid(selection_marker):
		selection_marker.queue_free()
	selection_marker = null
	_destroy_rotation_gizmo()
	if selected_item.is_empty():
		return
	var furniture_node: Node3D = selected_item.node
	if not is_instance_valid(furniture_node):
		return
	selection_marker = Node3D.new()
	selection_marker.name = "SelectedFurnitureMarker"
	var marker_offset: Vector2 = selected_item.get("bounds_offset", Vector2.ZERO)
	selection_marker.position = furniture_node.position + Vector3(marker_offset.x, 0.0, marker_offset.y)
	selection_marker.position.y = 0.035
	var marker_mesh := MeshInstance3D.new()
	var marker_box := BoxMesh.new()
	var footprint: Vector2i = selected_item.footprint
	var object_size: Vector3 = selected_item.get("object_size", Vector3(footprint.x, 1.6, footprint.y))
	var bounds_size: Vector2 = selected_item.get("bounds_size", Vector2(object_size.x, object_size.z))
	marker_box.size = Vector3(maxf(0.05, bounds_size.x - 0.06), 0.055, maxf(0.05, bounds_size.y - 0.06))
	marker_mesh.mesh = marker_box
	var marker_material := StandardMaterial3D.new()
	marker_material.albedo_color = Color(1.0, 0.74, 0.26, 0.28)
	marker_material.emission_enabled = true
	marker_material.emission = Color("f3bd58")
	marker_material.emission_energy_multiplier = 0.55
	marker_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marker_mesh.material_override = marker_material
	marker_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	selection_marker.add_child(marker_mesh)
	preview_root.add_child(selection_marker)


func _create_rotation_gizmo() -> void:
	if selected_item.is_empty() or camera_focused:
		return
	var furniture_node := selected_item.get("node", null) as Node3D
	if not is_instance_valid(furniture_node):
		return
	rotation_gizmo = Node3D.new()
	rotation_gizmo.name = "FurnitureRotationGizmo"
	preview_root.add_child(rotation_gizmo)
	var footprint: Vector2i = selected_item.get("footprint", Vector2i.ONE)
	var object_size: Vector3 = selected_item.get("object_size", Vector3(footprint.x, 1.6, footprint.y))
	var radius := clampf(maxf(object_size.x, object_size.z) * 0.58 + 0.30, 0.62, 2.15)
	_add_rotation_gizmo_ring(0, radius, Color("f05d68"))
	_add_rotation_gizmo_ring(1, radius, Color("62d487"))
	_add_rotation_gizmo_ring(2, radius, Color("5f9ff3"))
	_sync_selected_visuals()


func _add_rotation_gizmo_ring(axis_index: int, radius: float, color: Color) -> void:
	var ring_root := Node3D.new()
	ring_root.name = ["RotateX", "RotateY", "RotateZ"][axis_index]
	match axis_index:
		0:
			ring_root.rotation_degrees.z = 90.0
		1:
			pass
		2:
			ring_root.rotation_degrees.x = 90.0
	rotation_gizmo.add_child(ring_root)

	var mesh_instance := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = maxf(0.05, radius - 0.028)
	torus.outer_radius = radius + 0.028
	torus.rings = 40
	torus.ring_segments = 10
	mesh_instance.mesh = torus
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color, 0.92)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.15
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	mesh_instance.material_override = material
	ring_root.add_child(mesh_instance)

	var hit_area := Area3D.new()
	hit_area.name = "RotateAxisHitArea"
	hit_area.collision_layer = ROTATION_GIZMO_LAYER
	hit_area.collision_mask = 0
	hit_area.set_meta("rotation_axis", axis_index)
	ring_root.add_child(hit_area)
	var segment_radius := (torus.inner_radius + torus.outer_radius) * 0.5
	for segment: int in range(28):
		var angle := TAU * float(segment) / 28.0
		var collision := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 0.19
		collision.shape = sphere
		collision.position = Vector3(cos(angle) * segment_radius, 0.0, sin(angle) * segment_radius)
		hit_area.add_child(collision)


func _destroy_rotation_gizmo() -> void:
	if gizmo_dragging and not rotation_mode and not selected_item.is_empty():
		var furniture_node := selected_item.get("node", null) as RigidBody3D
		if is_instance_valid(furniture_node):
			furniture_node.freeze = false
			furniture_node.sleeping = false
	gizmo_dragging = false
	gizmo_axis_index = -1
	if is_instance_valid(rotation_gizmo):
		rotation_gizmo.queue_free()
	rotation_gizmo = null


func _try_begin_rotation_gizmo_drag(screen_position: Vector2) -> bool:
	if (
		selected_item.is_empty()
		or not rotation_mode
		or camera_focused
		or camera_transitioning
		or not active_kind.is_empty()
		or not is_instance_valid(rotation_gizmo)
		or not rotation_gizmo.visible
	):
		return false
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 100.0, ROTATION_GIZMO_LAYER)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return false
	var hit_area := result.collider as Area3D
	if not is_instance_valid(hit_area) or not hit_area.has_meta("rotation_axis"):
		return false
	var furniture_body := selected_item.get("node", null) as RigidBody3D
	if not is_instance_valid(furniture_body):
		return false
	furniture_body.freeze = true
	furniture_body.linear_velocity = Vector3.ZERO
	furniture_body.angular_velocity = Vector3.ZERO
	gizmo_dragging = true
	gizmo_axis_index = int(hit_area.get_meta("rotation_axis"))
	gizmo_last_mouse_position = screen_position
	pending_world_drag = false
	_hide_furniture_menu()
	var axis_name: String = ["X", "Y", "Z"][gizmo_axis_index]
	_set_status("正在绕 %s 轴旋转 · 松开鼠标后可继续选择其他轴" % axis_name, Color("ffd47e"))
	return true


func _update_rotation_gizmo_drag(event: InputEventMouseMotion) -> void:
	if not gizmo_dragging or selected_item.is_empty():
		return
	var furniture_node := selected_item.get("node", null) as RigidBody3D
	if not is_instance_valid(furniture_node):
		_destroy_rotation_gizmo()
		return
	var mouse_delta := event.position - gizmo_last_mouse_position
	gizmo_last_mouse_position = event.position
	var angle_delta := (mouse_delta.x - mouse_delta.y) * ROTATION_GIZMO_SENSITIVITY
	if absf(angle_delta) < 0.001:
		return
	var next_rotation := furniture_node.rotation_degrees
	match gizmo_axis_index:
		0:
			next_rotation.x = fposmod(next_rotation.x + angle_delta, 360.0)
		1:
			next_rotation.y = fposmod(next_rotation.y + angle_delta, 360.0)
		2:
			next_rotation.z = fposmod(next_rotation.z + angle_delta, 360.0)
	var footprint: Vector2i = selected_item.get("footprint", Vector2i.ONE)
	var object_size: Vector3 = selected_item.get("object_size", Vector3(footprint.x, 1.6, footprint.y))
	var next_bounds := _projected_bounds_size(object_size, next_rotation)
	var next_offset := _projected_bounds_offset(object_size, next_rotation)
	var support_node := selected_item.get("support_node", null) as Node3D
	var support_surface_id := String(selected_item.get("support_surface_id", ""))
	if not _can_place_at(
		furniture_node.position,
		next_bounds,
		next_offset,
		furniture_node,
		support_node,
		support_surface_id
	):
		_set_status("该旋转角度会越界或碰到其他家具", Color("ff9da6"))
		return
	furniture_node.rotation_degrees = next_rotation
	furniture_node.position.y = _ground_offset_for_rotation(object_size, next_rotation) + 0.025
	_sync_moving_supported_items(furniture_node.global_transform, true)
	var updated_entry := selected_item.duplicate()
	updated_entry.rotation_degrees = next_rotation
	updated_entry.bounds_size = next_bounds
	updated_entry.bounds_offset = next_offset
	var item_index := _find_entry_index(furniture_node)
	if item_index >= 0:
		placed_items[item_index] = updated_entry
	selected_item = updated_entry
	_sync_selected_visuals()


func _end_rotation_gizmo_drag() -> void:
	if not gizmo_dragging:
		return
	gizmo_dragging = false
	gizmo_axis_index = -1
	_set_status("旋转角度已暂存 · 可继续拖动其他轴 · 完成后点击“确定”", Color("ffd47e"))


func _sync_dynamic_furniture() -> void:
	for index: int in range(placed_items.size()):
		var entry: Dictionary = placed_items[index]
		var body := entry.get("node", null) as RigidBody3D
		if not is_instance_valid(body):
			continue
		var footprint: Vector2i = entry.get("footprint", Vector2i.ONE)
		var object_size: Vector3 = entry.get("object_size", Vector3(footprint.x, 1.6, footprint.y))
		var rotation_value := body.rotation_degrees
		entry.rotation_degrees = rotation_value
		entry.bounds_size = _projected_bounds_size(object_size, rotation_value)
		entry.bounds_offset = _projected_bounds_offset(object_size, rotation_value)
		placed_items[index] = entry
		if not selected_item.is_empty() and selected_item.get("node", null) == body:
			selected_item = entry
	_sync_selected_visuals()


func _sync_selected_visuals() -> void:
	if selected_item.is_empty():
		return
	var furniture_node := selected_item.get("node", null) as Node3D
	if not is_instance_valid(furniture_node):
		return
	var marker_offset: Vector2 = selected_item.get("bounds_offset", Vector2.ZERO)
	if is_instance_valid(selection_marker):
		selection_marker.position = Vector3(
			furniture_node.position.x + marker_offset.x,
			0.035,
			furniture_node.position.z + marker_offset.y
		)
		if selection_marker.get_child_count() > 0:
			var marker_mesh := selection_marker.get_child(0) as MeshInstance3D
			if is_instance_valid(marker_mesh):
				var marker_box := marker_mesh.mesh as BoxMesh
				var footprint: Vector2i = selected_item.get("footprint", Vector2i.ONE)
				var object_size: Vector3 = selected_item.get("object_size", Vector3(footprint.x, 1.6, footprint.y))
				var bounds_size: Vector2 = selected_item.get("bounds_size", Vector2(object_size.x, object_size.z))
				if marker_box != null:
					marker_box.size = Vector3(maxf(0.05, bounds_size.x - 0.06), 0.055, maxf(0.05, bounds_size.y - 0.06))
	if is_instance_valid(rotation_gizmo):
		rotation_gizmo.global_transform = Transform3D(
			furniture_node.global_basis.orthonormalized(),
			furniture_node.to_global(Vector3(0.0, 0.8, 0.0))
		)


func _set_selection_status(prefix: String = "") -> void:
	if selected_item.is_empty():
		return
	var item_name: String = _furniture_info(selected_item.kind).label
	var leading := "%s · " % prefix if not prefix.is_empty() else ""
	var action_hint := "请选择检视或收纳"
	if not bool(selected_item.get("requires_collection", false)):
		action_hint = "请选择检视、旋转或收纳 · 也可拖动家具移动"
	_set_status("%s已选中「%s」· %s" % [leading, item_name, action_hint], Color("ffd47e"))


func _rotation_for_entry(entry: Dictionary) -> Vector3:
	var stored: Variant = entry.get("rotation_degrees", null)
	if typeof(stored) == TYPE_VECTOR3:
		return stored as Vector3
	if typeof(stored) in [TYPE_FLOAT, TYPE_INT]:
		return Vector3(0.0, float(stored), 0.0)
	return Vector3(0.0, float(entry.get("rotation", 0)) * 90.0, 0.0)


func _rotation_for_placement(entry: Dictionary) -> Vector3:
	var result := _rotation_for_entry(entry)
	var item_info := _furniture_info(String(entry.get("kind", "")))
	if not _get_surface_snap_target_roles(item_info).is_empty():
		# A physics-simulated desk item may be lying on its side.  Drag placement
		# should present it upright again so shelf/desk snap tests can succeed.
		result.x = 0.0
		result.z = 0.0
	return result


func _placement_clearance(support_node: Node3D) -> float:
	return SURFACE_SNAP_CLEARANCE if is_instance_valid(support_node) else PHYSICS_DROP_HEIGHT


func _set_placed_body_support_state(body: RigidBody3D, support_node: Node3D) -> void:
	var is_surface_attached := is_instance_valid(support_node)
	body.freeze = is_surface_attached
	body.sleeping = is_surface_attached


func _rotation_basis(rotation_value: Vector3) -> Basis:
	return Basis.from_euler(Vector3(
		deg_to_rad(rotation_value.x),
		deg_to_rad(rotation_value.y),
		deg_to_rad(rotation_value.z)
	))


func _projected_bounds_size(object_size: Vector3, rotation_value: Vector3) -> Vector2:
	var half_size := object_size * 0.5
	var basis := _rotation_basis(rotation_value)
	var local_x := basis * Vector3.RIGHT
	var local_y := basis * Vector3.UP
	var local_z := basis * Vector3.BACK
	var half_width := absf(local_x.x) * half_size.x + absf(local_y.x) * half_size.y + absf(local_z.x) * half_size.z
	var half_depth := absf(local_x.z) * half_size.x + absf(local_y.z) * half_size.y + absf(local_z.z) * half_size.z
	return Vector2(maxf(0.1, half_width * 2.0), maxf(0.1, half_depth * 2.0))


func _projected_bounds_offset(object_size: Vector3, rotation_value: Vector3) -> Vector2:
	var rotated_center := _rotation_basis(rotation_value) * Vector3(0.0, object_size.y * 0.5, 0.0)
	return Vector2(rotated_center.x, rotated_center.z)


func _ground_offset_for_rotation(object_size: Vector3, rotation_value: Vector3) -> float:
	var basis := _rotation_basis(rotation_value)
	var half_width := object_size.x * 0.5
	var half_depth := object_size.z * 0.5
	var minimum_y := INF
	for x: float in [-half_width, half_width]:
		for y: float in [0.0, object_size.y]:
			for z: float in [-half_depth, half_depth]:
				minimum_y = minf(minimum_y, (basis * Vector3(x, y, z)).y)
	return maxf(0.0, -minimum_y)


func _find_surface_snap(
	kind: String,
	candidate_origin: Vector3,
	object_size: Vector3,
	rotation_value: Vector3,
	screen_position: Vector2 = Vector2(-1.0, -1.0),
	ray_origin: Vector3 = Vector3.ZERO,
	ray_direction: Vector3 = Vector3.ZERO
) -> Dictionary:
	var item_info := _furniture_info(kind)
	var target_roles := _get_surface_snap_target_roles(item_info)
	if target_roles.is_empty():
		return {}
	var item_basis := _rotation_basis(rotation_value).orthonormalized()
	if (item_basis * Vector3.UP).dot(Vector3.UP) < 0.92:
		return {}
	var best_snap: Dictionary = {}
	var best_score := INF

	for entry: Dictionary in placed_items:
		var support_node := entry.get("node", null) as Node3D
		if not is_instance_valid(support_node):
			continue
		var support_info := _furniture_info(String(entry.get("kind", "")))
		var support_role := String(support_info.get("surface_role", ""))
		if not target_roles.has(support_role):
			continue
		var support_basis := support_node.global_transform.basis.orthonormalized()
		if (support_basis * Vector3.UP).dot(Vector3.UP) < 0.92:
			continue

		var relative_basis := support_basis.inverse() * item_basis
		var local_x_axis := relative_basis * Vector3.RIGHT
		var local_y_axis := relative_basis * Vector3.UP
		var local_z_axis := relative_basis * Vector3.BACK
		var half_item := object_size * 0.5
		var required_x := (
			absf(local_x_axis.x) * half_item.x
			+ absf(local_y_axis.x) * half_item.y
			+ absf(local_z_axis.x) * half_item.z
		)
		var required_z := (
			absf(local_x_axis.z) * half_item.x
			+ absf(local_y_axis.z) * half_item.y
			+ absf(local_z_axis.z) * half_item.z
		)
		var surfaces := _get_support_snap_surfaces(support_node, support_info)
		for surface: Dictionary in surfaces:
			var surface_size: Vector2 = surface.get("size", Vector2.ZERO)
			var surface_offset: Vector3 = surface.get("offset", Vector3.ZERO)
			var half_surface := surface_size * 0.5
			if required_x > half_surface.x or required_z > half_surface.y:
				continue

			var world_surface_center := support_node.to_global(surface_offset)
			var local_candidate: Vector3
			if ray_direction.length_squared() > 0.001:
				var surface_plane := Plane(support_basis * Vector3.UP, world_surface_center)
				var plane_hit: Variant = surface_plane.intersects_ray(ray_origin, ray_direction)
				if plane_hit == null:
					continue
				local_candidate = support_node.to_local(plane_hit as Vector3)
			else:
				local_candidate = support_node.to_local(Vector3(
					candidate_origin.x,
					world_surface_center.y,
					candidate_origin.z
				))
			var surface_center := Vector2(surface_offset.x, surface_offset.z)
			if (
				absf(local_candidate.x - surface_center.x) > half_surface.x + required_x
				or absf(local_candidate.z - surface_center.y) > half_surface.y + required_z
			):
				continue
			local_candidate.x = clampf(
				local_candidate.x,
				surface_center.x - half_surface.x + required_x,
				surface_center.x + half_surface.x - required_x
			)
			local_candidate.y = surface_offset.y
			local_candidate.z = clampf(
				local_candidate.z,
				surface_center.y - half_surface.y + required_z,
				surface_center.y + half_surface.y - required_z
			)
			var surface_world := support_node.to_global(local_candidate)
			var score := world_surface_center.distance_to(surface_world) * 0.01
			if screen_position.x >= 0.0 and is_instance_valid(camera):
				var surface_screen := camera.unproject_position(world_surface_center)
				score += absf(screen_position.y - surface_screen.y)
			else:
				score += absf(candidate_origin.y - surface_world.y)
			if score >= best_score:
				continue
			best_score = score
			best_snap = {
				"origin": Vector3(surface_world.x, candidate_origin.y, surface_world.z),
				"surface_height": surface_world.y,
				"support": support_node,
				"surface_id": String(surface.get("id", "surface"))
			}
	return best_snap


func _get_surface_snap_target_roles(item_info: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var role_values: Variant = item_info.get("surface_snap_targets", [])
	if role_values is Array:
		for role_value: Variant in role_values as Array:
			var role := String(role_value)
			if not role.is_empty() and not result.has(role):
				result.append(role)
	var legacy_role := String(item_info.get("surface_snap_target", ""))
	if not legacy_role.is_empty() and not result.has(legacy_role):
		result.append(legacy_role)
	return result


func _get_support_snap_surfaces(support_node: Node3D, support_info: Dictionary) -> Array[Dictionary]:
	if support_node.has_method("get_snap_surfaces"):
		var entity_surfaces: Variant = support_node.call("get_snap_surfaces")
		if entity_surfaces is Array:
			var typed_surfaces: Array[Dictionary] = []
			for surface_value: Variant in entity_surfaces as Array:
				if surface_value is Dictionary:
					typed_surfaces.append((surface_value as Dictionary).duplicate())
			if not typed_surfaces.is_empty():
				return typed_surfaces

	var support_size: Vector3 = support_info.size
	var base_offset := Vector3.ZERO
	var surface_inset: Vector2 = support_info.get("surface_inset", Vector2.ZERO)
	var surface_height := float(support_info.get("surface_height", support_size.y))
	if support_node.has_method("get_surface_size"):
		var entity_surface_size: Variant = support_node.call("get_surface_size")
		if typeof(entity_surface_size) == TYPE_VECTOR3:
			support_size = entity_surface_size as Vector3
			surface_height = support_size.y
			surface_inset = Vector2.ZERO
	if support_node.has_method("get_surface_offset"):
		var entity_surface_offset: Variant = support_node.call("get_surface_offset")
		if typeof(entity_surface_offset) == TYPE_VECTOR3:
			base_offset = entity_surface_offset as Vector3
			surface_height = base_offset.y + support_size.y
	var usable_size := Vector2(support_size.x, support_size.z) - surface_inset * 2.0
	return [{
		"id": "surface",
		"size": Vector2(maxf(0.05, usable_size.x), maxf(0.05, usable_size.y)),
		"offset": Vector3(base_offset.x, surface_height, base_offset.z)
	}]


func _can_place_at(
	origin: Vector3,
	bounds_size: Vector2,
	bounds_offset: Vector2,
	ignored_node: Node3D = null,
	support_node: Node3D = null,
	support_surface_id: String = ""
) -> bool:
	var bounds_center := Vector2(origin.x, origin.z) + bounds_offset
	var half_size := bounds_size * 0.5
	var room_max_x := runtime_room_min_x + runtime_room_width * CELL_SIZE
	var room_max_z := runtime_room_min_z + runtime_room_depth * CELL_SIZE
	if bounds_center.x - half_size.x < runtime_room_min_x or bounds_center.x + half_size.x > room_max_x:
		return false
	if bounds_center.y - half_size.y < runtime_room_min_z or bounds_center.y + half_size.y > room_max_z:
		return false

	for entry: Dictionary in placed_items:
		var other_node := entry.get("node", null) as Node3D
		if (
			not is_instance_valid(other_node)
			or other_node == ignored_node
			or other_node == support_node
			or _is_moving_supported_node(other_node)
		):
			continue
		if is_instance_valid(support_node) and entry.get("support_node", null) == support_node:
			var other_surface_id := String(entry.get("support_surface_id", ""))
			if not support_surface_id.is_empty() and not other_surface_id.is_empty() and other_surface_id != support_surface_id:
				continue
		var other_footprint: Vector2i = entry.get("footprint", Vector2i.ONE)
		var other_object_size: Vector3 = entry.get("object_size", Vector3(other_footprint.x, 1.6, other_footprint.y))
		var other_size: Vector2 = entry.get("bounds_size", Vector2(other_object_size.x, other_object_size.z))
		var other_offset: Vector2 = entry.get("bounds_offset", Vector2.ZERO)
		var other_center := Vector2(other_node.position.x, other_node.position.z) + other_offset
		var combined_half_size := (bounds_size + other_size) * 0.5
		if (
			absf(bounds_center.x - other_center.x) < combined_half_size.x - 0.03
			and absf(bounds_center.y - other_center.y) < combined_half_size.y - 0.03
		):
			return false
	return true


func _undo_last() -> void:
	if camera_focused or camera_transitioning:
		_set_status("近景查看中不可编辑，请先返回全景", Color("f0bd7a"))
		return
	if not active_kind.is_empty():
		_cancel_placement(false)
	_clear_selection(true)
	if placed_items.is_empty():
		_set_status("房间里还没有可撤销的家具", Color("bdb2ca"))
		return
	if bool(placed_items.back().get("requires_collection", false)):
		_set_status("案发现场初始家具不能直接撤销，请点击家具后选择收纳", Color("f0bd7a"))
		return
	var entry: Dictionary = placed_items.pop_back()
	for cell: Vector2i in entry.cells:
		occupied.erase(cell)
	var node: Node3D = entry.node
	if is_instance_valid(node):
		_unregister_reconstruction_furniture(node)
		node.queue_free()
	_add_to_inventory(String(entry.kind))
	_set_status("已撤销上一件家具，并退回背包", Color("d1c1e5"))


func _clear_room() -> void:
	if camera_focused or camera_transitioning:
		_set_status("近景查看中不可编辑，请先返回全景", Color("f0bd7a"))
		return
	_cancel_placement(false)
	_clear_selection(true)
	for entry: Dictionary in placed_items:
		var node: Node3D = entry.node
		if is_instance_valid(node):
			_unregister_reconstruction_furniture(node)
			node.queue_free()
		var kind := String(entry.kind)
		inventory_counts[kind] = int(inventory_counts.get(kind, 0)) + 1
	placed_items.clear()
	occupied.clear()
	_refresh_inventory_ui()
	_set_status("场景家具已全部收纳进背包", Color("d1c1e5"))


func _add_preview_base() -> void:
	preview_bounds_marker = MeshInstance3D.new()
	preview_bounds_marker.name = "ContinuousPlacementBounds"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.92, 0.04, 0.92)
	preview_bounds_marker.mesh = mesh
	preview_bounds_marker.visible = false
	preview_bounds_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	preview_root.add_child(preview_bounds_marker)


func _update_preview_bounds_marker(origin: Vector3) -> void:
	if not is_instance_valid(preview_bounds_marker):
		return
	preview_bounds_marker.position = Vector3(
		origin.x + preview_bounds_offset.x,
		preview_surface_height + 0.025,
		origin.z + preview_bounds_offset.y
	)
	var box := preview_bounds_marker.mesh as BoxMesh
	if box != null:
		box.size = Vector3(
			maxf(0.05, preview_bounds_size.x - 0.06),
			0.04,
			maxf(0.05, preview_bounds_size.y - 0.06)
		)
	preview_bounds_marker.visible = true


func _update_preview_tint(valid: bool) -> void:
	if _has_preview_tint and valid == _last_valid_state:
		return
	_has_preview_tint = true
	_last_valid_state = valid
	var tint := Color(0.28, 0.95, 0.57, 0.52) if valid else Color(1.0, 0.30, 0.36, 0.50)
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test = false
	for child: Node in active_preview.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		mesh_instance.material_override = material
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if is_instance_valid(preview_bounds_marker):
		preview_bounds_marker.material_override = material


func _set_drag_status(message: String, color: Color) -> void:
	if message == _last_status:
		return
	_last_status = message
	_set_status(message, color)


func _set_status(message: String, color: Color) -> void:
	if not is_instance_valid(status_label):
		return
	status_label.text = message
	status_label.add_theme_color_override("font_color", Color("963e30") if color.r > color.g * 1.4 else PAPER_INK)


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", PAPER_INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(text_value: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 38)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 13)
	PAPER_UI.button(button, "button")
	return button


func _style(color: Color, radius: int, border_color: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBox:
	if radius > 1:
		var style := PAPER_UI.paper("wide")
		for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			style.set_texture_margin(side, 12)
		return style
	return CASE_SCENE_UI.divider()

func _apply_case_scene_controls(node: Node) -> void:
	if node is CheckButton or node is ColorPickerButton:
		node.add_theme_color_override("font_color", PAPER_INK)
	elif node is Button:
		PAPER_UI.button(node, "button")
	elif node is Label:
		node.add_theme_color_override("font_color", PAPER_INK)
	for child in node.get_children():
		_apply_case_scene_controls(child)
