@tool
class_name ShelfFurniture
extends RigidBody3D


const INTERACTION_SIZE := Vector3(2.003942, 3.825615, 0.858264)
const PREVIEW_THICKNESS := 0.025
const SHARED_PROFILE_PATH := "res://scenes/furniture/shelf_collision_profile.cfg"
const PROFILE_KEYS: Array[String] = [
	"size",
	"offset",
	"panel_thickness",
	"shelf_surface_size",
	"shelf_surface_offset",
	"layer_1_height",
	"layer_2_height",
	"layer_3_height",
	"shelf_board_thickness"
]


@export_group("Cabinet Collision")
@export var use_shared_profile := true
@export var collision_size := INTERACTION_SIZE:
	set(value):
		collision_size = Vector3(
			maxf(0.30, value.x),
			maxf(0.50, value.y),
			maxf(0.20, value.z)
		)
		_request_sync()
@export var collision_offset := Vector3.ZERO:
	set(value):
		collision_offset = value
		_request_sync()
@export_range(0.02, 0.25, 0.005) var panel_thickness := 0.07:
	set(value):
		panel_thickness = maxf(0.02, value)
		_request_sync()
@export var show_collision_preview := true:
	set(value):
		show_collision_preview = value
		_request_sync()

@export_group("Folder Shelves")
@export var shelf_surface_size := Vector2(1.68, 0.66):
	set(value):
		shelf_surface_size = Vector2(maxf(0.10, value.x), maxf(0.10, value.y))
		_request_sync()
@export var shelf_surface_offset := Vector2(0.0, 0.035):
	set(value):
		shelf_surface_offset = value
		_request_sync()
@export_range(0.10, 5.00, 0.005) var layer_1_height := 3.08:
	set(value):
		layer_1_height = maxf(0.10, value)
		_request_sync()
@export_range(0.10, 5.00, 0.005) var layer_2_height := 2.36:
	set(value):
		layer_2_height = maxf(0.10, value)
		_request_sync()
@export_range(0.10, 5.00, 0.005) var layer_3_height := 1.64:
	set(value):
		layer_3_height = maxf(0.10, value)
		_request_sync()
@export_range(0.02, 0.20, 0.005) var shelf_board_thickness := 0.06:
	set(value):
		shelf_board_thickness = maxf(0.02, value)
		_request_sync()
@export var show_shelf_previews := true:
	set(value):
		show_shelf_previews = value
		_request_sync()


func _ready() -> void:
	name = "ShelfFurniture" if name.is_empty() else name
	set_meta("furniture_kind", "shelf")
	if Engine.is_editor_hint() and use_shared_profile:
		var shared_profile := load_shared_profile()
		if not shared_profile.is_empty():
			apply_collision_profile(shared_profile)
	_configure_physics()
	_sync_collision_and_previews()
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_sync_collision_and_previews()


func get_collision_profile() -> Dictionary:
	return {
		"size": collision_size,
		"offset": collision_offset,
		"panel_thickness": panel_thickness,
		"shelf_surface_size": shelf_surface_size,
		"shelf_surface_offset": shelf_surface_offset,
		"layer_1_height": layer_1_height,
		"layer_2_height": layer_2_height,
		"layer_3_height": layer_3_height,
		"shelf_board_thickness": shelf_board_thickness
	}


static func load_shared_profile() -> Dictionary:
	var config := ConfigFile.new()
	if config.load(SHARED_PROFILE_PATH) != OK:
		return {}
	var profile: Dictionary = {}
	for key: String in PROFILE_KEYS:
		if config.has_section_key("shelf", key):
			profile[key] = config.get_value("shelf", key)
	return profile


func apply_collision_profile(profile: Dictionary) -> void:
	if profile.has("size"):
		collision_size = profile["size"] as Vector3
	if profile.has("offset"):
		collision_offset = profile["offset"] as Vector3
	if profile.has("panel_thickness"):
		panel_thickness = float(profile["panel_thickness"])
	if profile.has("shelf_surface_size"):
		shelf_surface_size = profile["shelf_surface_size"] as Vector2
	if profile.has("shelf_surface_offset"):
		shelf_surface_offset = profile["shelf_surface_offset"] as Vector2
	if profile.has("layer_1_height"):
		layer_1_height = float(profile["layer_1_height"])
	if profile.has("layer_2_height"):
		layer_2_height = float(profile["layer_2_height"])
	if profile.has("layer_3_height"):
		layer_3_height = float(profile["layer_3_height"])
	if profile.has("shelf_board_thickness"):
		shelf_board_thickness = float(profile["shelf_board_thickness"])
	_request_sync()


func get_snap_surfaces() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var heights: Array[float] = [layer_1_height, layer_2_height, layer_3_height]
	for index: int in range(heights.size()):
		result.append({
			"id": "shelf_layer_%d" % (index + 1),
			"size": shelf_surface_size,
			"offset": Vector3(
				collision_offset.x + shelf_surface_offset.x,
				collision_offset.y + heights[index],
				collision_offset.z + shelf_surface_offset.y
			)
		})
	return result


func _request_sync() -> void:
	if is_inside_tree():
		_sync_collision_and_previews()
		if Engine.is_editor_hint() and use_shared_profile:
			_save_shared_profile()


func _save_shared_profile() -> void:
	var config := ConfigFile.new()
	var profile := get_collision_profile()
	for key: String in PROFILE_KEYS:
		if profile.has(key):
			config.set_value("shelf", key, profile[key])
	var save_error := config.save(SHARED_PROFILE_PATH)
	if save_error != OK:
		push_warning("Could not save shared shelf collision profile: %s" % error_string(save_error))


func _configure_physics() -> void:
	collision_layer = 4
	collision_mask = 1 | 4
	mass = 12.0
	linear_damp = 1.1
	angular_damp = 1.9
	can_sleep = true
	continuous_cd = false
	if physics_material_override == null:
		var physics_material := PhysicsMaterial.new()
		physics_material.friction = 0.88
		physics_material.bounce = 0.02
		physics_material_override = physics_material


func _sync_collision_and_previews() -> void:
	var side_thickness := minf(panel_thickness, collision_size.x * 0.20)
	var depth_thickness := minf(panel_thickness, collision_size.z * 0.30)
	var horizontal_thickness := minf(panel_thickness, collision_size.y * 0.10)
	var body_center_y := collision_offset.y + collision_size.y * 0.5
	var side_x := (collision_size.x - side_thickness) * 0.5
	var back_z := -(collision_size.z - depth_thickness) * 0.5

	_sync_collision_piece(
		"LeftPanel",
		Vector3(side_thickness, collision_size.y, collision_size.z),
		collision_offset + Vector3(-side_x, collision_size.y * 0.5, 0.0)
	)
	_sync_collision_piece(
		"RightPanel",
		Vector3(side_thickness, collision_size.y, collision_size.z),
		collision_offset + Vector3(side_x, collision_size.y * 0.5, 0.0)
	)
	_sync_collision_piece(
		"BackPanel",
		Vector3(collision_size.x, collision_size.y, depth_thickness),
		Vector3(collision_offset.x, body_center_y, collision_offset.z + back_z)
	)
	_sync_collision_piece(
		"BottomPanel",
		Vector3(collision_size.x, horizontal_thickness, collision_size.z),
		collision_offset + Vector3(0.0, horizontal_thickness * 0.5, 0.0)
	)
	_sync_collision_piece(
		"TopPanel",
		Vector3(collision_size.x, horizontal_thickness, collision_size.z),
		collision_offset + Vector3(0.0, collision_size.y - horizontal_thickness * 0.5, 0.0)
	)

	var snap_surfaces := get_snap_surfaces()
	for index: int in range(snap_surfaces.size()):
		var surface: Dictionary = snap_surfaces[index]
		var surface_size: Vector2 = surface["size"]
		var surface_offset: Vector3 = surface["offset"]
		_sync_collision_piece(
			"ShelfLayer%d" % (index + 1),
			Vector3(surface_size.x, shelf_board_thickness, surface_size.y),
			surface_offset - Vector3(0.0, shelf_board_thickness * 0.5, 0.0)
		)
		_sync_snap_preview(index + 1, surface_size, surface_offset)

	_sync_interaction_shape()
	_set_collision_previews_visible(show_collision_preview)


func _sync_collision_piece(piece_name: String, size: Vector3, center: Vector3) -> void:
	var shape_node := get_node_or_null("%sShape" % piece_name) as CollisionShape3D
	if not is_instance_valid(shape_node):
		shape_node = CollisionShape3D.new()
		shape_node.name = "%sShape" % piece_name
		add_child(shape_node)
	var box := shape_node.shape as BoxShape3D
	if box == null:
		box = BoxShape3D.new()
		shape_node.shape = box
	box.size = size
	shape_node.position = center

	var preview := get_node_or_null("%sCollisionPreview" % piece_name) as MeshInstance3D
	if not is_instance_valid(preview):
		preview = MeshInstance3D.new()
		preview.name = "%sCollisionPreview" % piece_name
		preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		preview.material_override = _make_preview_material(Color(0.18, 0.82, 1.0, 0.18))
		add_child(preview)
	var preview_box := preview.mesh as BoxMesh
	if preview_box == null:
		preview_box = BoxMesh.new()
		preview.mesh = preview_box
	preview_box.size = size
	preview.position = center
	preview.visible = Engine.is_editor_hint() and show_collision_preview


func _sync_snap_preview(layer_index: int, size: Vector2, center: Vector3) -> void:
	var preview := get_node_or_null("Layer%dSnapPreview" % layer_index) as MeshInstance3D
	if not is_instance_valid(preview):
		preview = MeshInstance3D.new()
		preview.name = "Layer%dSnapPreview" % layer_index
		preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		preview.material_override = _make_preview_material(Color(0.25, 1.0, 0.72, 0.38))
		add_child(preview)
	var box := preview.mesh as BoxMesh
	if box == null:
		box = BoxMesh.new()
		preview.mesh = box
	box.size = Vector3(size.x, PREVIEW_THICKNESS, size.y)
	preview.position = center
	preview.visible = Engine.is_editor_hint() and show_shelf_previews


func _sync_interaction_shape() -> void:
	var hit_area := get_node_or_null("FurnitureHitArea") as Area3D
	if not is_instance_valid(hit_area):
		hit_area = Area3D.new()
		hit_area.name = "FurnitureHitArea"
		hit_area.collision_layer = 2
		hit_area.collision_mask = 0
		add_child(hit_area)
	hit_area.set_meta("furniture_root", self)
	var legacy_shape := hit_area.get_node_or_null("InteractionShape") as CollisionShape3D
	if is_instance_valid(legacy_shape):
		legacy_shape.disabled = true
		legacy_shape.queue_free()
	for piece_name: String in [
		"LeftPanel",
		"RightPanel",
		"BackPanel",
		"BottomPanel",
		"TopPanel",
		"ShelfLayer1",
		"ShelfLayer2",
		"ShelfLayer3"
	]:
		var physics_shape := get_node_or_null("%sShape" % piece_name) as CollisionShape3D
		if not is_instance_valid(physics_shape):
			continue
		var physics_box := physics_shape.shape as BoxShape3D
		if physics_box == null:
			continue
		_sync_interaction_piece(hit_area, piece_name, physics_box.size, physics_shape.position)


func _sync_interaction_piece(area: Area3D, piece_name: String, size: Vector3, center: Vector3) -> void:
	var hit_shape := area.get_node_or_null("%sHitShape" % piece_name) as CollisionShape3D
	if not is_instance_valid(hit_shape):
		hit_shape = CollisionShape3D.new()
		hit_shape.name = "%sHitShape" % piece_name
		area.add_child(hit_shape)
	var hit_box := hit_shape.shape as BoxShape3D
	if hit_box == null:
		hit_box = BoxShape3D.new()
		hit_shape.shape = hit_box
	hit_box.size = size
	hit_shape.position = center


func _set_collision_previews_visible(visible_value: bool) -> void:
	for child: Node in get_children():
		if child is MeshInstance3D and child.name.ends_with("CollisionPreview"):
			(child as MeshInstance3D).visible = Engine.is_editor_hint() and visible_value


func _make_preview_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b)
	material.emission_energy_multiplier = 0.65
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test = true
	return material
