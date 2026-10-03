extends SceneTree


const GALLERY_CASE_PATH := "res://data/cases/gallery_case_002.json"
const APARTMENT_CASE_PATH := "res://data/cases/apartment_case_003.json"
const GALLERY_OUTPUT := "res://assets/case_photos/gallery/standard_layout_photo.png"
const GUEST_OUTPUT := "res://assets/case_photos/apartment/guest_room_photo.png"
const ARCHIVE_OUTPUT := "res://assets/case_photos/apartment/archive_shift_photo.png"

var world_root: Node3D
var camera: Camera3D
var placed_by_id: Dictionary = {}


func _init() -> void:
	call_deferred("_render_all")


func _render_all() -> void:
	root.size = Vector2i(960, 600)
	var gallery_data := _load_case_data(GALLERY_CASE_PATH)
	if gallery_data.is_empty():
		quit(1)
		return
	_build_case_world(gallery_data, "standard_restoration_layout", "GalleryStandardLayout")
	_configure_gallery_standard_lights()
	_set_camera(Vector3(8.7, 6.2, 8.7), Vector3(0.0, 1.0, -0.25), 39.0)
	if not await _capture(GALLERY_OUTPUT):
		quit(1)
		return
	await _clear_world()

	var apartment_data := _load_case_data(APARTMENT_CASE_PATH)
	if apartment_data.is_empty():
		quit(1)
		return
	_build_case_world(apartment_data, "apartment_complete", "ApartmentSolvedLayout")
	_set_camera(Vector3(-0.35, 4.75, 6.65), Vector3(-3.55, 0.9, -0.35), 38.0)
	if not await _capture(GUEST_OUTPUT):
		quit(1)
		return
	_set_camera(Vector3(7.4, 4.55, 3.8), Vector3(3.15, 0.95, -1.15), 36.0)
	if not await _capture(ARCHIVE_OUTPUT):
		quit(1)
		return
	await _clear_world()
	quit(0)


func _build_case_world(case_data: Dictionary, step_id: String, world_name: String) -> void:
	placed_by_id.clear()
	world_root = Node3D.new()
	world_root.name = world_name
	root.add_child(world_root)
	current_scene = world_root
	_build_environment(case_data)
	_build_room(case_data)
	_build_step_furniture(case_data, step_id)
	camera = Camera3D.new()
	camera.name = "EvidenceCamera"
	camera.current = true
	camera.near = 0.05
	camera.far = 80.0
	world_root.add_child(camera)


func _build_environment(case_data: Dictionary) -> void:
	var layout := case_data.get("scene_layout", {}) as Dictionary
	var base := layout.get("base_lighting", {}) as Dictionary
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("1c2229")
	environment.background_energy_multiplier = 0.42
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.from_string(String(base.get("ambient_color", "#BFC8D2")), Color("bfc8d2"))
	environment.ambient_light_energy = float(base.get("ambient_energy", 0.34))
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.adjustment_enabled = true
	environment.adjustment_saturation = float(base.get("saturation", 0.96))
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	world_root.add_child(world_environment)

	var key_settings := base.get("key", {}) as Dictionary
	var key := DirectionalLight3D.new()
	key.name = "EvidenceKey"
	key.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	key.light_color = CaseLightDevice._temperature_to_color(float(key_settings.get("temperature", 5200.0)))
	key.light_energy = float(key_settings.get("energy", 0.95))
	key.shadow_enabled = bool(key_settings.get("shadow", true)) if not key_settings.is_empty() else true
	world_root.add_child(key)

	var fill_settings := base.get("fill", {}) as Dictionary
	var fill := OmniLight3D.new()
	fill.name = "EvidenceFill"
	fill.position = Vector3(-3.8, 3.5, 2.8)
	fill.light_color = CaseLightDevice._temperature_to_color(float(fill_settings.get("temperature", 6500.0)))
	fill.light_energy = float(fill_settings.get("energy", 0.85))
	fill.omni_range = float(fill_settings.get("range", 10.0))
	fill.shadow_enabled = bool(fill_settings.get("shadow", false))
	world_root.add_child(fill)


func _build_room(case_data: Dictionary) -> void:
	var layout := case_data.get("scene_layout", {}) as Dictionary
	var width := float(layout.get("room_width", 10.0))
	var depth := float(layout.get("room_depth", 7.0))
	var min_x := -width * 0.5
	var min_z := -depth * 0.5
	_add_box(Vector3(width, 0.18, depth), Vector3(0, -0.09, 0), Color("706a63"), "Floor")
	_add_box(Vector3(width, 3.5, 0.18), Vector3(0, 1.75, min_z), Color("a8a096"), "BackWall")
	_add_box(Vector3(0.18, 3.5, depth), Vector3(min_x, 1.75, 0), Color("929ca5"), "LeftWall")
	var divider_x := float(layout.get("room_divider_x", 1000.0))
	if absf(divider_x) < width:
		_add_box(Vector3(0.18, 2.7, depth * 0.62), Vector3(divider_x, 1.35, min_z + depth * 0.31), Color("878f96"), "Divider")
		_add_box(Vector3(0.18, 0.55, depth * 0.25), Vector3(divider_x, 2.45, min_z + depth * 0.82), Color("878f96"), "DoorHeader")
	for fixture_value: Variant in layout.get("fixtures", []):
		if not fixture_value is Dictionary:
			continue
		var fixture := fixture_value as Dictionary
		if String(fixture.get("type", "box")) != "box":
			continue
		var size := _array_to_vector3(fixture.get("size", []), Vector3.ONE)
		var position := _array_to_vector3(fixture.get("position", []), Vector3(0, 0.5, 0))
		_add_box(
			size,
			position,
			Color.from_string(String(fixture.get("color", "#8B8B8B")), Color("8b8b8b")),
			String(fixture.get("name", "Fixture")),
			bool(fixture.get("emission", false))
		)


func _build_step_furniture(case_data: Dictionary, step_id: String) -> void:
	var zone_ids: Array = []
	for step_value: Variant in case_data.get("reconstruction_steps", []):
		if step_value is Dictionary and String((step_value as Dictionary).get("step_id", "")) == step_id:
			zone_ids = (step_value as Dictionary).get("zone_ids", []) as Array
			break
	var furniture_by_id: Dictionary = {}
	for furniture_value: Variant in case_data.get("furniture_unlocks", []):
		if furniture_value is Dictionary:
			var furniture_data := furniture_value as Dictionary
			furniture_by_id[String(furniture_data.get("furniture_id", ""))] = furniture_data
	var zones_by_id: Dictionary = {}
	for zone_value: Variant in case_data.get("reconstruction_zones", []):
		if zone_value is Dictionary:
			var zone_data := zone_value as Dictionary
			zones_by_id[String(zone_data.get("zone_id", ""))] = zone_data
	for zone_id_value: Variant in zone_ids:
		var zone := zones_by_id.get(String(zone_id_value), {}) as Dictionary
		var furniture_id := String(zone.get("required_furniture_id", ""))
		var furniture_data := furniture_by_id.get(furniture_id, {}) as Dictionary
		var kind := String(furniture_data.get("catalog_kind", ""))
		if furniture_id.is_empty() or kind.is_empty():
			continue
		var position := _array_to_vector3(zone.get("position", []), Vector3.ZERO)
		# Furniture geometry is authored above a ground-level root. This mirrors
		# the live placement system's ground offset for yaw-only rotations.
		position.y = 0.025
		var furniture := FurnitureFactory.build(kind, false)
		furniture.name = "Evidence%s" % furniture_id.to_pascal_case()
		furniture.position = position
		furniture.rotation_degrees.y = float(zone.get("target_yaw", 0.0))
		var body := furniture as RigidBody3D
		if is_instance_valid(body):
			body.freeze = true
			body.sleeping = true
		world_root.add_child(furniture)
		placed_by_id[furniture_id] = furniture


func _configure_gallery_standard_lights() -> void:
	# The live puzzle deliberately starts dim so that lamp calibration remains
	# meaningful.  The police reference photo, however, must expose the whole
	# standard layout clearly enough to be useful as evidence.
	var world_environment := world_root.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if is_instance_valid(world_environment) and is_instance_valid(world_environment.environment):
		world_environment.environment.background_energy_multiplier = 0.62
		world_environment.environment.ambient_light_energy = 0.62
		world_environment.environment.adjustment_brightness = 1.85
	var key := world_root.find_child("EvidenceKey", true, false) as DirectionalLight3D
	if is_instance_valid(key):
		key.light_energy = 1.15
	var fill := world_root.find_child("EvidenceFill", true, false) as OmniLight3D
	if is_instance_valid(fill):
		fill.light_energy = 1.40
		fill.omni_range = 13.0
	var cold_root := placed_by_id.get("standard_cold_light", null) as Node3D
	var halogen_root := placed_by_id.get("halogen_lamp", null) as Node3D
	var cold := cold_root.find_child("CaseLightDevice", true, false) as CaseLightDevice if is_instance_valid(cold_root) else null
	var halogen := halogen_root.find_child("CaseLightDevice", true, false) as CaseLightDevice if is_instance_valid(halogen_root) else null
	if is_instance_valid(cold):
		cold.apply_debug_values({"energy":0.70, "temperature":6800.0, "yaw":180.0, "pitch":-28.0})
	if is_instance_valid(halogen):
		halogen.apply_debug_values({"energy":0.0, "temperature":3100.0, "yaw":0.0, "pitch":-24.0})


func _set_camera(camera_position: Vector3, target: Vector3, fov: float) -> void:
	camera.global_position = camera_position
	camera.fov = fov
	camera.look_at(target, Vector3.UP)


func _capture(output_path: String) -> bool:
	for _frame: int in range(10):
		await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Initial evidence render returned an empty image: %s" % output_path)
		return false
	if output_path == GALLERY_OUTPUT:
		_apply_reference_exposure(image)
	var result := image.save_png(output_path)
	if result != OK:
		push_error("Could not save initial evidence image: %s" % output_path)
		return false
	print("RENDERED_FOLLOWUP_INITIAL_PHOTO ", output_path)
	return true


func _apply_reference_exposure(image: Image) -> void:
	# The restoration room intentionally uses a very low-key live lighting rig.
	# Lift midtones in the police reference print without flattening the lamp and
	# cast-shadow information that the player must compare later.
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var source := image.get_pixel(x, y)
			var lifted := Color(
				pow(source.r, 0.42),
				pow(source.g, 0.42),
				pow(source.b, 0.42),
				source.a
			)
			image.set_pixel(x, y, lifted)


func _clear_world() -> void:
	current_scene = null
	if is_instance_valid(world_root):
		root.remove_child(world_root)
		world_root.free()
	world_root = null
	camera = null
	placed_by_id.clear()
	await process_frame


func _add_box(size: Vector3, world_position: Vector3, color: Color, node_name: String, emission := false) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = world_position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.90
	if emission:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.35
	mesh_instance.material_override = material
	world_root.add_child(mesh_instance)


func _array_to_vector3(value: Variant, fallback: Vector3) -> Vector3:
	if not value is Array:
		return fallback
	var values := value as Array
	if values.size() < 3:
		return fallback
	return Vector3(float(values[0]), float(values[1]), float(values[2]))


func _load_case_data(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open case data for evidence rendering: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Invalid case data JSON: %s" % path)
		return {}
	return parsed as Dictionary
