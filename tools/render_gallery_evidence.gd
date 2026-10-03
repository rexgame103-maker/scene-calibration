extends SceneTree


const OUTPUTS: Array[String] = [
	"res://assets/case_photos/gallery/process_photo_01_shadow.png",
	"res://assets/case_photos/gallery/process_photo_02_reflection.png",
	"res://assets/case_photos/gallery/process_photo_03_orientation.png"
]

var world_root: Node3D
var camera: Camera3D
var table: Node3D
var halogen_device: CaseLightDevice
var reflector_device: CaseLightDevice
var case_data: Dictionary = {}


func _init() -> void:
	call_deferred("_render_all")


func _render_all() -> void:
	root.size = Vector2i(768, 512)
	_build_correct_layout()
	await process_frame
	await process_frame
	for index: int in range(OUTPUTS.size()):
		_configure_shot(index)
		for _frame: int in range(10):
			await process_frame
		var image := root.get_texture().get_image()
		if image == null or image.is_empty():
			push_error("Gallery evidence render returned an empty image")
			quit(1)
			return
		var result := image.save_png(OUTPUTS[index])
		if result != OK:
			push_error("Could not save gallery evidence image: %s" % OUTPUTS[index])
			quit(1)
			return
		print("RENDERED_GALLERY_EVIDENCE ", OUTPUTS[index])
	quit(0)


func _build_correct_layout() -> void:
	case_data = _load_case_data()
	var scene_layout := case_data.get("scene_layout", {}) as Dictionary
	var base_lighting := scene_layout.get("base_lighting", {}) as Dictionary
	world_root = Node3D.new()
	world_root.name = "GalleryEvidenceRenderWorld"
	root.add_child(world_root)
	current_scene = world_root

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("202329")
	environment.background_energy_multiplier = 0.30
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.from_string(String(base_lighting.get("ambient_color", "#C4CBD0")), Color("c4cbd0"))
	environment.ambient_light_energy = float(base_lighting.get("ambient_energy", 0.12))
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.adjustment_enabled = true
	environment.adjustment_saturation = float(base_lighting.get("saturation", 0.96))
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	world_root.add_child(world_environment)

	_add_box(Vector3(10.0, 0.18, 7.0), Vector3(0, -0.09, 0), Color("6f6b65"), "Floor")
	_add_box(Vector3(10.0, 3.5, 0.18), Vector3(0, 1.75, -3.5), Color("aaa49c"), "BackWall")
	_add_box(Vector3(0.18, 3.5, 7.0), Vector3(-5.0, 1.75, 0), Color("949da4"), "LeftWall")

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	var key_settings := base_lighting.get("key", {}) as Dictionary
	key.light_color = CaseLightDevice._temperature_to_color(float(key_settings.get("temperature", 5400.0)))
	key.light_energy = float(key_settings.get("energy", 0.20))
	key.shadow_enabled = bool(key_settings.get("shadow", false))
	world_root.add_child(key)
	_add_case_omni(base_lighting.get("fill", {}) as Dictionary, Vector3(-3.8, 3.2, 2.6), "FillLight")
	_add_case_omni(base_lighting.get("accent", {}) as Dictionary, Vector3(3.4, 3.1, -2.8), "AccentLight")

	table = _add_answer_furniture("restoration_table", "restoration_table")
	var cold := _add_answer_furniture("standard_cold_light", "cold_light_panel")
	var halogen := _add_answer_furniture("halogen_lamp", "halogen_inspection_lamp")
	var reflector := _add_answer_furniture("metal_reflector", "metal_reflector")
	var cold_device := cold.find_child("CaseLightDevice", true, false) as CaseLightDevice
	halogen_device = halogen.find_child("CaseLightDevice", true, false) as CaseLightDevice
	reflector_device = reflector.find_child("CaseLightDevice", true, false) as CaseLightDevice
	cold_device.apply_debug_values(_light_debug_values("standard_cold_light"))
	halogen_device.apply_debug_values(_light_debug_values("halogen_lamp"))

	camera = Camera3D.new()
	camera.current = true
	camera.near = 0.05
	camera.fov = 31.0
	world_root.add_child(camera)

func _configure_shot(index: int) -> void:
	var artwork := table.find_child("ArtworkSurface", true, false) as Node3D
	var target := artwork.global_position if is_instance_valid(artwork) else table.global_position + Vector3.UP
	match index:
		0:
			camera.global_position = Vector3(3.55, 4.25, 3.15)
			camera.fov = 27.0
			halogen_device.set_energy(1.05, false)
			reflector_device.set_reflected_light(target, 0.08, 3100.0)
		1:
			camera.global_position = Vector3(-2.45, 4.15, 2.75)
			camera.fov = 28.0
			halogen_device.set_energy(1.05, false)
			reflector_device.set_reflected_light(target, 0.30, 3100.0)
		2:
			camera.global_position = Vector3(0.35, 5.55, 4.20)
			camera.fov = 32.0
			halogen_device.set_energy(0.92, false)
			reflector_device.set_reflected_light(target, 0.24, 3100.0)
	camera.look_at(target, Vector3.UP)


func _add_furniture(kind: String, world_position: Vector3, yaw_degrees: float) -> Node3D:
	var furniture := FurnitureFactory.build(kind, false)
	furniture.position = world_position
	furniture.rotation_degrees.y = yaw_degrees
	var body := furniture as RigidBody3D
	if is_instance_valid(body):
		body.freeze = true
		body.sleeping = true
	world_root.add_child(furniture)
	return furniture


func _add_answer_furniture(furniture_id: String, kind: String) -> Node3D:
	var zone := _actual_zone_for(furniture_id)
	var position_values: Array = zone.get("position", [0.0, 0.0, 0.0])
	var info := FurnitureFactory.get_info(kind)
	var object_size: Vector3 = info.get("size", Vector3.ONE)
	var position_value := Vector3(
		float(position_values[0]),
		object_size.y * 0.5 + 0.025,
		float(position_values[2])
	)
	return _add_furniture(kind, position_value, float(zone.get("target_yaw", 0.0)))


func _actual_zone_for(furniture_id: String) -> Dictionary:
	for zone_value: Variant in case_data.get("reconstruction_zones", []):
		if not zone_value is Dictionary:
			continue
		var zone := zone_value as Dictionary
		if (
			String(zone.get("required_furniture_id", "")) == furniture_id
			and String(zone.get("zone_id", "")).begins_with("actual_")
		):
			return zone
	push_error("No actual answer zone for gallery furniture: %s" % furniture_id)
	return {}


func _light_debug_values(furniture_id: String) -> Dictionary:
	for step_value: Variant in case_data.get("reconstruction_steps", []):
		if not step_value is Dictionary:
			continue
		for condition_value: Variant in (step_value as Dictionary).get("lighting_conditions", []):
			if not condition_value is Dictionary:
				continue
			var condition := condition_value as Dictionary
			if String(condition.get("furniture_id", "")) == furniture_id and condition.has("debug_values"):
				return (condition.get("debug_values", {}) as Dictionary).duplicate(true)
	return {}


func _load_case_data() -> Dictionary:
	var file := FileAccess.open("res://data/cases/gallery_case_002.json", FileAccess.READ)
	if file == null:
		push_error("Could not open gallery case data for evidence rendering")
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _add_box(size: Vector3, world_position: Vector3, color: Color, node_name: String) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = world_position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	mesh_instance.material_override = material
	world_root.add_child(mesh_instance)


func _add_case_omni(settings: Dictionary, world_position: Vector3, node_name: String) -> void:
	var light := OmniLight3D.new()
	light.name = node_name
	light.position = world_position
	light.light_energy = float(settings.get("energy", 0.0))
	light.light_color = CaseLightDevice._temperature_to_color(float(settings.get("temperature", 5200.0)))
	light.omni_range = float(settings.get("range", 8.0))
	light.shadow_enabled = bool(settings.get("shadow", false))
	world_root.add_child(light)
