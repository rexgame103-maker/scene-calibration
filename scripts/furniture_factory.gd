@tool
class_name FurnitureFactory
extends RefCounted

const PLANT_FOLIAGE := preload("res://scenes/props/indoor_plant_foliage.tscn")


const DESK_MODEL: PackedScene = preload("res://assets/models/furniture/desk/desk.glb")
const DESK_FURNITURE_SCENE: PackedScene = preload("res://scenes/furniture/desk_furniture.tscn")
const SHELF_FURNITURE_SCENE: PackedScene = preload("res://scenes/furniture/shelf_furniture.tscn")
const COMPUTER_MODEL: PackedScene = preload("res://assets/models/furniture/computer/computer.glb")
const CHAIR_MODEL: PackedScene = preload("res://assets/models/furniture/chair/chair.glb")
const LAMP_MODEL: PackedScene = preload("res://assets/models/furniture/lamp/lamp.glb")
const WATER_DISPENSER_MODEL: PackedScene = preload("res://assets/models/furniture/waterDispenser/waterDispenser.glb")
const SMALL_SHELF_MODEL: PackedScene = preload("res://assets/models/furniture/smallShelf/smallShelf.glb")
const PRINTER_MODEL: PackedScene = preload("res://assets/models/furniture/printer/printer.glb")
const SHELF_MODEL: PackedScene = preload("res://assets/models/furniture/shelf/shelf.glb")
const BLUE_FILE_MODEL: PackedScene = preload("res://assets/models/furniture/blue_file/blue_file.glb")
const RED_FILE_MODEL: PackedScene = preload("res://assets/models/furniture/red_file/red_file.glb")
const PAPER_MODEL: PackedScene = preload("res://assets/models/furniture/paper/paper.glb")


const CATALOG: Array[Dictionary] = [
	{
		"kind": "desk",
		"label": "工作桌",
		"description": "宽敞的三格桌面",
		"footprint": Vector2i(3, 2),
		"size": Vector3(3.166877, 1.704236, 1.733879),
		"model_scale": 1.0,
		"model_origin_offset": Vector3(0.006963, 0.0, -0.077374),
		"surface_role": "desk",
		"surface_inset": Vector2(0.10, 0.10),
		"color": Color("d99972")
	},
	{
		"kind": "chair",
		"label": "办公椅",
		"description": "带滚轮的办公座椅",
		"footprint": Vector2i(1, 1),
		"size": Vector3(1.259852, 2.162656, 1.385503),
		"model_scale": 1.0,
		"model_origin_offset": Vector3(0.003747, 0.0, 0.117899),
		"color": Color("e66d79")
	},
	{
		"kind": "computer",
		"label": "老式电脑",
		"description": "案发现场的电脑设备",
		"short_description": "案发现场电脑",
		"footprint": Vector2i(2, 2),
		"size": Vector3(1.341696, 0.715336, 1.395977),
		"model_scale": 0.72,
		"model_origin_offset": Vector3(0.186941, 0.007845, 0.040361),
		"surface_snap_target": "desk",
		"color": Color("65b8c4")
	},
	{
		"kind": "restoration_table",
		"label": "修复桌",
		"description": "带作品托板的标准修复工作台",
		"short_description": "配作品托板",
		"footprint": Vector2i(3, 2),
		"size": Vector3(2.80, 1.12, 1.62),
		"color": Color("b8a27d")
	},
	{
		"kind": "restoration_stool",
		"label": "修复凳",
		"description": "修复室使用的可调高脚凳",
		"short_description": "高度可调",
		"footprint": Vector2i(1, 1),
		"size": Vector3(0.72, 1.18, 0.72),
		"color": Color("63798a")
	},
	{
		"kind": "cold_light_panel",
		"label": "标准冷光灯",
		"description": "经过校准的宽幅低温照明设备",
		"short_description": "宽幅冷光照明",
		"footprint": Vector2i(2, 1),
		"size": Vector3(1.72, 2.18, 0.62),
		"color": Color("9fd3dc")
	},
	{
		"kind": "halogen_inspection_lamp",
		"label": "卤素检查灯",
		"description": "会明显发热的移动式点光检查灯",
		"short_description": "移动点光，发热明显",
		"footprint": Vector2i(1, 1),
		"size": Vector3(0.72, 1.78, 0.72),
		"color": Color("e09a52")
	},
	{
		"kind": "metal_reflector",
		"label": "金属反光屏",
		"description": "能够改变补光方向的移动反射板",
		"short_description": "可调补光方向",
		"footprint": Vector2i(1, 1),
		"size": Vector3(1.18, 1.92, 0.58),
		"color": Color("b7bdc3")
	},
	{
		"kind": "camera_tripod",
		"label": "摄影支架",
		"description": "用于拍摄连续修复记录的固定相机",
		"short_description": "固定机位连续记录",
		"footprint": Vector2i(1, 1),
		"size": Vector3(0.92, 1.72, 0.92),
		"color": Color("4d5865")
	},
	{
		"kind": "sofa",
		"label": "三人沙发",
		"description": "占用横向三格",
		"footprint": Vector2i(3, 1),
		"size": Vector3(2.82, 1.23, 0.96),
		"color": Color("9d75d6")
	},
	{
		"kind": "shelf",
		"label": "高文件柜",
		"description": "贴墙摆放的高柜",
		"footprint": Vector2i(2, 1),
		"size": Vector3(2.003942, 3.825615, 0.858264),
		"model_scale": 1.0,
		"model_origin_offset": Vector3.ZERO,
		"surface_role": "file_shelf",
		"color": Color("6d8fc9")
	},
	{
		"kind": "lamp",
		"label": "办公台灯",
		"description": "小型桌面照明",
		"footprint": Vector2i(1, 1),
		"size": Vector3(0.340634, 0.799824, 0.343164),
		"model_scale": 1.0,
		"model_origin_offset": Vector3(0.024850, 0.0, -0.026530),
		"surface_snap_target": "desk",
		"color": Color("f0bf61")
	},
	{
		"kind": "water_dispenser",
		"label": "饮水机",
		"description": "窄型立式饮水设备",
		"footprint": Vector2i(1, 1),
		"size": Vector3(0.611267, 1.998972, 0.488796),
		"model_scale": 1.0,
		"model_origin_offset": Vector3(0.062986, 0.0, -0.031701),
		"color": Color("73a9d2")
	},
	{
		"kind": "small_shelf",
		"label": "矮文件柜",
		"description": "可放在桌边的矮柜",
		"footprint": Vector2i(1, 1),
		"size": Vector3(0.968751, 1.487922, 0.642006),
		"model_scale": 1.0,
		"model_origin_offset": Vector3(0.005325, 0.0, -0.012152),
		"color": Color("7f91bb")
	},
	{
		"kind": "printer",
		"label": "打印机",
		"description": "立式办公打印设备",
		"footprint": Vector2i(1, 1),
		"size": Vector3(1.276060, 2.086591, 1.283397),
		"model_scale": 1.0,
		"model_origin_offset": Vector3(0.0, 0.0, 0.000659),
		"color": Color("a8a7ad")
	},
	{
		"kind": "blue_file",
		"label": "蓝色文件夹",
		"description": "可作为案件文件线索",
		"footprint": Vector2i(1, 1),
		"size": Vector3(0.356618, 0.560571, 0.167944),
		"model_scale": 1.0,
		"model_origin_offset": Vector3(-0.005749, 0.0, -0.012142),
		"surface_snap_targets": ["desk", "file_shelf"],
		"color": Color("578fd1")
	},
	{
		"kind": "red_file",
		"label": "红色文件夹",
		"description": "醒目的案件文件线索",
		"footprint": Vector2i(1, 1),
		"size": Vector3(0.356618, 0.560571, 0.167945),
		"model_scale": 1.0,
		"model_origin_offset": Vector3(-0.005749, 0.0, -0.012142),
		"surface_snap_targets": ["desk", "file_shelf"],
		"color": Color("cf5f67")
	},
	{
		"kind": "gray_file",
		"label": "灰色报表夹",
		"description": "编号 G-04 的报表夹",
		"footprint": Vector2i(1, 1),
		"size": Vector3(0.356618, 0.560571, 0.167945),
		"model_scale": 1.0,
		"model_origin_offset": Vector3.ZERO,
		"surface_snap_target": "file_shelf",
		"color": Color("858895")
	},
	{
		"kind": "ordinary_file_01",
		"label": "普通项目文件 01",
		"description": "编号 P-11 的米色文件",
		"footprint": Vector2i(1, 1),
		"size": Vector3(0.356618, 0.560571, 0.167945),
		"model_scale": 1.0,
		"model_origin_offset": Vector3.ZERO,
		"surface_snap_target": "file_shelf",
		"color": Color("c3a982")
	},
	{
		"kind": "ordinary_file_02",
		"label": "普通项目文件 02",
		"description": "编号 P-12 的绿色文件",
		"footprint": Vector2i(1, 1),
		"size": Vector3(0.356618, 0.560571, 0.167945),
		"model_scale": 1.0,
		"model_origin_offset": Vector3.ZERO,
		"surface_snap_target": "file_shelf",
		"color": Color("718b72")
	},
	{
		"kind": "paper",
		"label": "散落纸张",
		"description": "带透明贴图的散落纸张",
		"footprint": Vector2i(1, 1),
		"size": Vector3(1.841318, 0.097459, 1.842403),
		"model_scale": 1.0,
		"model_origin_offset": Vector3(-0.042220, -0.052172, -0.054231),
		"color": Color("e6dfcb")
	},
	{
		"kind": "plant",
		"label": "绿植",
		"description": "给房间一点生气",
		"footprint": Vector2i(1, 1),
		"size": Vector3(0.82, 1.42, 0.82),
		"color": Color("70bd8b")
	}
]


static func get_info(kind: String) -> Dictionary:
	for item: Dictionary in CATALOG:
		if item.kind == kind:
			return item
	return CATALOG[0]


static func build(kind: String, preview: bool = false, physics_overrides: Dictionary = {}) -> Node3D:
	if kind == "desk" and not preview:
		var desk := DESK_FURNITURE_SCENE.instantiate() as DeskFurniture
		if physics_overrides.has("size"):
			var requested_size: Vector3 = physics_overrides["size"]
			desk.collision_size = requested_size
		if physics_overrides.has("offset"):
			var requested_offset: Vector3 = physics_overrides["offset"]
			desk.collision_offset = requested_offset
		desk.name = "DeskFurniture"
		desk.set_meta("furniture_kind", "desk")
		desk.set_meta("furniture_id", "desk")
		return desk
	if kind == "shelf" and not preview:
		var shelf := SHELF_FURNITURE_SCENE.instantiate() as ShelfFurniture
		var shelf_profile := physics_overrides
		if shelf_profile.is_empty():
			shelf_profile = ShelfFurniture.load_shared_profile()
		if not shelf_profile.is_empty():
			shelf.apply_collision_profile(shelf_profile)
		shelf.name = "ShelfFurniture"
		shelf.set_meta("furniture_kind", "shelf")
		shelf.set_meta("furniture_id", "shelf")
		return shelf
	var root: Node3D
	if preview:
		root = Node3D.new()
	else:
		var body := RigidBody3D.new()
		var item_size: Vector3 = get_info(kind).size
		body.mass = clampf(item_size.x * item_size.y * item_size.z * 0.85, 0.15, 15.0)
		body.collision_layer = 4
		body.collision_mask = 1 | 4
		body.linear_damp = 1.1
		body.angular_damp = 1.8
		body.can_sleep = true
		body.continuous_cd = false
		var physics_material := PhysicsMaterial.new()
		physics_material.friction = 0.86
		physics_material.bounce = 0.04
		body.physics_material_override = physics_material
		root = body
	root.name = "%sFurniture" % kind.capitalize()
	root.set_meta("furniture_kind", kind)
	root.set_meta("furniture_id", kind)

	match kind:
		"desk":
			if not _add_imported_model(root, DESK_MODEL, kind):
				_build_desk(root)
		"chair":
			if not _add_imported_model(root, CHAIR_MODEL, kind):
				_build_chair(root)
		"computer":
			if not _add_imported_model(root, COMPUTER_MODEL, kind):
				_build_import_fallback(root, kind)
		"restoration_table":
			_build_restoration_table(root)
		"restoration_stool":
			_build_restoration_stool(root)
		"cold_light_panel":
			_build_cold_light_panel(root, not preview)
		"halogen_inspection_lamp":
			_build_halogen_inspection_lamp(root, not preview)
		"metal_reflector":
			_build_metal_reflector(root, not preview)
		"camera_tripod":
			_build_camera_tripod(root)
		"sofa":
			_build_sofa(root)
		"shelf":
			if not _add_imported_model(root, SHELF_MODEL, kind):
				_build_shelf(root)
		"lamp":
			if not _add_imported_model(root, LAMP_MODEL, kind):
				_build_lamp(root)
		"water_dispenser":
			if not _add_imported_model(root, WATER_DISPENSER_MODEL, kind):
				_build_import_fallback(root, kind)
		"small_shelf":
			if not _add_imported_model(root, SMALL_SHELF_MODEL, kind):
				_build_import_fallback(root, kind)
		"printer":
			if not _add_imported_model(root, PRINTER_MODEL, kind):
				_build_import_fallback(root, kind)
		"blue_file":
			if not _add_imported_model(root, BLUE_FILE_MODEL, kind):
				_build_import_fallback(root, kind)
		"red_file":
			if not _add_imported_model(root, RED_FILE_MODEL, kind):
				_build_import_fallback(root, kind)
		"gray_file", "ordinary_file_01", "ordinary_file_02":
			_build_case_file(root, kind)
		"paper":
			if not _add_imported_model(root, PAPER_MODEL, kind):
				_build_import_fallback(root, kind)
		"plant":
			_build_plant(root)

	if not preview:
		_add_collision(root, kind)
		_add_physics_collision(root, kind, physics_overrides)
	return root


static func add_interaction_collision(root: Node3D, kind: String) -> void:
	_add_collision(root, kind)


static func _add_imported_model(root: Node3D, packed_scene: PackedScene, kind: String) -> bool:
	if packed_scene == null:
		return false
	var model := packed_scene.instantiate() as Node3D
	if model == null:
		return false
	model.name = "Model"
	var info := get_info(kind)
	var model_scale := float(info.get("model_scale", 1.0))
	var source_offset: Vector3 = info.get("model_origin_offset", Vector3.ZERO)
	model.scale = Vector3.ONE * model_scale
	model.position = source_offset * model_scale
	root.add_child(model)
	return true


static func _build_import_fallback(root: Node3D, kind: String) -> void:
	var info := get_info(kind)
	var size: Vector3 = info.size
	var color: Color = info.color
	_add_box(root, size, Vector3(0.0, size.y * 0.5, 0.0), color)


static func _build_case_file(root: Node3D, kind: String) -> void:
	var info := get_info(kind)
	var size: Vector3 = info.size
	var color: Color = info.color
	_add_box(root, size, Vector3(0.0, size.y * 0.5, 0.0), color)
	_add_box(
		root,
		Vector3(size.x * 0.68, size.y * 0.12, size.z + 0.006),
		Vector3(0.0, size.y * 0.67, -0.003),
		Color("e7dfcf")
	)
	_add_box(
		root,
		Vector3(size.x * 0.46, size.y * 0.035, size.z + 0.009),
		Vector3(0.0, size.y * 0.67, -0.006),
		color.darkened(0.35)
	)


static func _build_desk(root: Node3D) -> void:
	var wood := Color("c98258")
	var dark_wood := Color("78516a")
	_add_box(root, Vector3(2.82, 0.18, 1.62), Vector3(0, 0.92, 0), wood)
	for x: float in [-1.24, 1.24]:
		for z: float in [-0.64, 0.64]:
			_add_box(root, Vector3(0.13, 0.86, 0.13), Vector3(x, 0.43, z), dark_wood)
	# A small monitor makes the primitive immediately readable as a desk.
	_add_box(root, Vector3(0.88, 0.55, 0.08), Vector3(0.45, 1.36, -0.27), Color("283451"))
	_add_box(root, Vector3(0.69, 0.37, 0.02), Vector3(0.45, 1.36, -0.22), Color("73d1db"), true)
	_add_box(root, Vector3(0.08, 0.30, 0.08), Vector3(0.45, 1.05, -0.27), dark_wood)
	_add_box(root, Vector3(0.55, 0.06, 0.34), Vector3(-0.50, 1.04, 0.26), Color("e8d7be"))


static func _build_chair(root: Node3D) -> void:
	var fabric := Color("d85e70")
	var frame := Color("5a4964")
	_add_box(root, Vector3(0.78, 0.16, 0.78), Vector3(0, 0.56, 0), fabric)
	_add_box(root, Vector3(0.78, 0.78, 0.14), Vector3(0, 0.98, 0.32), fabric)
	for x: float in [-0.30, 0.30]:
		for z: float in [-0.29, 0.29]:
			_add_box(root, Vector3(0.09, 0.52, 0.09), Vector3(x, 0.26, z), frame)


static func _build_restoration_table(root: Node3D) -> void:
	var frame := Color("53616a")
	var surface := Color("c7b892")
	_add_box(root, Vector3(2.72, 0.16, 1.54), Vector3(0, 0.92, 0), surface)
	for x: float in [-1.20, 1.20]:
		for z: float in [-0.60, 0.60]:
			_add_box(root, Vector3(0.12, 0.88, 0.12), Vector3(x, 0.44, z), frame)
	# The heat-sensitive painting stays on the table so inspection clues follow it.
	var painting_board := _add_box(root, Vector3(1.72, 0.045, 1.02), Vector3(0.18, 1.025, 0.02), Color("8d6e58"))
	painting_board.name = "PaintingBoard"
	var artwork_surface := _add_box(root, Vector3(1.52, 0.028, 0.82), Vector3(0.18, 1.064, 0.02), Color("596f68"))
	artwork_surface.name = "ArtworkSurface"
	_add_box(root, Vector3(0.46, 0.014, 0.30), Vector3(0.68, 1.086, 0.24), Color("d7d0b8"))
	var wet_patch := _add_sphere(root, Vector3(0.38, 0.018, 0.22), Vector3(0.52, 1.107, 0.10), Color("756b59"))
	wet_patch.name = "EvidenceGlossPatch"
	wet_patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var wet_material := StandardMaterial3D.new()
	wet_material.albedo_color = Color("756b59")
	wet_material.metallic = 0.08
	wet_material.roughness = 0.06
	wet_material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	wet_patch.material_override = wet_material
	# Raised tabletop tools are real shadow casters used by the light-calibration case.
	var ruler := _add_box(root, Vector3(1.12, 0.035, 0.10), Vector3(-0.12, 1.112, 0.37), Color("d8c995"))
	ruler.name = "CalibrationRuler"
	for tick_index: int in range(11):
		var tick_height := 0.055 if tick_index % 5 == 0 else 0.035
		_add_box(
			ruler,
			Vector3(0.012, tick_height, 0.012),
			Vector3(-0.50 + tick_index * 0.10, 0.035, -0.045),
			Color("4b5356")
		)
	var scalpel := _add_box(root, Vector3(0.72, 0.055, 0.075), Vector3(0.10, 1.145, -0.30), Color("c2c9ca"))
	scalpel.name = "ScalpelTool"
	scalpel.rotation.y = deg_to_rad(18.0)
	var scalpel_handle := _add_box(scalpel, Vector3(0.24, 0.075, 0.11), Vector3(-0.26, 0.0, 0.0), Color("555e62"))
	scalpel_handle.name = "ScalpelHandle"
	for edge_data: Dictionary in [
		{"size": Vector3(1.70, 0.08, 0.055), "position": Vector3(0.18, 1.11, -0.47)},
		{"size": Vector3(1.70, 0.08, 0.055), "position": Vector3(0.18, 1.11, 0.51)},
		{"size": Vector3(0.055, 0.08, 1.02), "position": Vector3(-0.66, 1.11, 0.02)},
		{"size": Vector3(0.055, 0.08, 1.02), "position": Vector3(1.02, 1.11, 0.02)}
	]:
		var frame_edge := _add_box(root, edge_data.size, edge_data.position, Color("775445"))
		frame_edge.name = "ArtworkFrameEdge"


static func _build_restoration_stool(root: Node3D) -> void:
	var frame := Color("46545e")
	_add_cylinder(root, 0.34, 0.34, 0.14, Vector3(0, 0.92, 0), Color("668297"))
	_add_cylinder(root, 0.055, 0.055, 0.82, Vector3(0, 0.45, 0), frame)
	_add_cylinder(root, 0.28, 0.28, 0.07, Vector3(0, 0.07, 0), frame)
	for direction: Vector3 in [Vector3(0.30, 0, 0), Vector3(-0.30, 0, 0), Vector3(0, 0, 0.30), Vector3(0, 0, -0.30)]:
		var foot := _add_box(root, Vector3(0.38, 0.055, 0.08), Vector3(direction.x * 0.52, 0.055, direction.z * 0.52), frame)
		foot.rotation.y = atan2(direction.x, direction.z)


static func _build_cold_light_panel(root: Node3D, active_light: bool) -> void:
	var frame := Color("596b74")
	_add_box(root, Vector3(1.48, 0.10, 0.46), Vector3(0, 0.07, 0), frame)
	for x: float in [-0.58, 0.58]:
		_add_box(root, Vector3(0.08, 1.76, 0.08), Vector3(x, 0.92, 0), frame)
	_add_box(root, Vector3(1.62, 0.18, 0.54), Vector3(0, 1.83, 0), frame)
	_add_box(root, Vector3(1.40, 0.04, 0.40), Vector3(0, 1.72, 0.02), Color("c7f2f4"), true)
	var device := CaseLightDevice.new()
	device.name = "CaseLightDevice"
	root.add_child(device)
	# The cold panel is a broad fill. The halogen is the only case lamp that casts
	# a sharp shadow, keeping the total shadow-light budget at two with the room key.
	device.configure("cold_panel", 0.62, 6800.0, 180.0, -28.0, 5.8, 68.0, false, Vector3(0, 1.70, 0.02))
	device.set_enabled(active_light)


static func _build_halogen_inspection_lamp(root: Node3D, active_light: bool) -> void:
	var metal := Color("4e5358")
	_add_cylinder(root, 0.28, 0.34, 0.10, Vector3(0, 0.05, 0), metal)
	_add_cylinder(root, 0.045, 0.045, 1.28, Vector3(0, 0.69, 0), metal)
	_add_box(root, Vector3(0.52, 0.34, 0.30), Vector3(0, 1.42, -0.05), Color("a9653d"))
	_add_box(root, Vector3(0.38, 0.22, 0.025), Vector3(0, 1.42, -0.215), Color("ffd18a"), true)
	var device := CaseLightDevice.new()
	device.name = "CaseLightDevice"
	root.add_child(device)
	device.configure("halogen", 0.22, 3200.0, 0.0, -24.0, 5.2, 48.0, true, Vector3(0, 1.42, -0.22))
	device.set_enabled(active_light)


static func _build_metal_reflector(root: Node3D, active_light: bool) -> void:
	var frame := Color("535d64")
	_add_box(root, Vector3(0.78, 0.09, 0.48), Vector3(0, 0.06, 0), frame)
	_add_box(root, Vector3(0.07, 1.45, 0.07), Vector3(0, 0.77, 0), frame)
	_add_box(root, Vector3(1.08, 1.18, 0.08), Vector3(0, 1.30, 0), Color("aeb7bd"))
	_add_box(root, Vector3(0.92, 1.02, 0.025), Vector3(0, 1.30, -0.055), Color("dbe1df"), true)
	var device := CaseLightDevice.new()
	device.name = "CaseLightDevice"
	root.add_child(device)
	device.configure("reflector", 0.0, 4200.0, 0.0, 0.0, 4.5, 62.0, false, Vector3(0, 1.30, -0.09))
	device.set_enabled(active_light)


static func _build_camera_tripod(root: Node3D) -> void:
	var metal := Color("3f4a53")
	_add_box(root, Vector3(0.10, 1.15, 0.10), Vector3(0, 0.74, 0), metal)
	for angle: float in [0.0, TAU / 3.0, TAU * 2.0 / 3.0]:
		var leg := _add_box(root, Vector3(0.07, 0.86, 0.07), Vector3(sin(angle) * 0.30, 0.39, cos(angle) * 0.30), metal)
		leg.rotation = Vector3(cos(angle) * 0.28, 0.0, -sin(angle) * 0.28)
	_add_box(root, Vector3(0.54, 0.34, 0.32), Vector3(0, 1.43, 0), Color("303842"))
	_add_cylinder(root, 0.11, 0.11, 0.16, Vector3(0, 1.43, -0.23), Color("68869a"))


static func _build_sofa(root: Node3D) -> void:
	var fabric := Color("8b68bd")
	var cushion := Color("a986d5")
	var dark := Color("55466f")
	_add_box(root, Vector3(2.82, 0.48, 0.86), Vector3(0, 0.34, 0), fabric)
	_add_box(root, Vector3(2.82, 0.90, 0.20), Vector3(0, 0.78, 0.37), dark)
	_add_box(root, Vector3(0.22, 0.74, 0.88), Vector3(-1.30, 0.57, 0), dark)
	_add_box(root, Vector3(0.22, 0.74, 0.88), Vector3(1.30, 0.57, 0), dark)
	for x: float in [-0.88, 0.0, 0.88]:
		_add_box(root, Vector3(0.78, 0.18, 0.72), Vector3(x, 0.67, -0.02), cushion)


static func _build_shelf(root: Node3D) -> void:
	var frame := Color("5575aa")
	var inset := Color("34476d")
	_add_box(root, Vector3(1.82, 2.18, 0.52), Vector3(0, 1.09, 0.20), frame)
	_add_box(root, Vector3(1.54, 1.86, 0.10), Vector3(0, 1.09, -0.11), inset)
	for y: float in [0.42, 1.02, 1.62]:
		_add_box(root, Vector3(1.62, 0.10, 0.56), Vector3(0, y, 0), Color("7d98c4"))
	var book_colors: Array[Color] = [Color("e47772"), Color("e7b75f"), Color("74b995"), Color("b48bd2")]
	for i: int in range(4):
		_add_box(root, Vector3(0.18, 0.42 + 0.05 * (i % 2), 0.30), Vector3(-0.55 + i * 0.30, 0.68, -0.02), book_colors[i])


static func _build_lamp(root: Node3D) -> void:
	var metal := Color("6b5771")
	var shade := Color("efb95b")
	_add_cylinder(root, 0.32, 0.32, 0.10, Vector3(0, 0.05, 0), metal)
	_add_cylinder(root, 0.045, 0.045, 1.36, Vector3(0, 0.75, 0), metal)
	_add_cylinder(root, 0.18, 0.42, 0.55, Vector3(0, 1.62, 0), shade)
	var light := OmniLight3D.new()
	light.position = Vector3(0, 1.48, 0)
	light.light_color = Color("ffd79a")
	light.light_energy = 0.55
	light.omni_range = 3.2
	light.shadow_enabled = false
	root.add_child(light)


static func _build_plant(root: Node3D) -> void:
	_add_cylinder(root, 0.30, 0.38, 0.48, Vector3(0, 0.24, 0), Color("b66f58"))
	var foliage := PLANT_FOLIAGE.instantiate() as Node3D
	foliage.position.y = 0.48
	foliage.scale = Vector3(0.72, 1.0, 0.72)
	root.add_child(foliage)


static func _add_collision(root: Node3D, kind: String) -> void:
	var info := get_info(kind)
	var item_size: Vector3 = info.size
	var area := Area3D.new()
	area.name = "FurnitureHitArea"
	area.collision_layer = 2
	area.collision_mask = 0
	area.set_meta("furniture_root", root)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var interaction_height := maxf(0.35, item_size.y)
	box.size = Vector3(maxf(0.08, item_size.x * 0.96), interaction_height, maxf(0.08, item_size.z * 0.96))
	shape.shape = box
	shape.position.y = interaction_height * 0.5
	area.add_child(shape)
	root.add_child(area)


static func _add_physics_collision(root: Node3D, kind: String, physics_overrides: Dictionary = {}) -> void:
	if not root is CollisionObject3D:
		return
	var info := get_info(kind)
	var item_size: Vector3 = info.size
	var shape := CollisionShape3D.new()
	shape.name = "FurniturePhysicsShape"
	var box := BoxShape3D.new()
	var physics_height := maxf(0.04, float(info.get("physics_height", item_size.y)))
	var default_size := Vector3(maxf(0.06, item_size.x * 0.94), physics_height, maxf(0.06, item_size.z * 0.94))
	var requested_size: Vector3 = physics_overrides.get("size", default_size)
	box.size = Vector3(maxf(0.06, requested_size.x), maxf(0.04, requested_size.y), maxf(0.06, requested_size.z))
	shape.shape = box
	shape.position.y = box.size.y * 0.5
	root.add_child(shape)


static func _material(color: Color, emission: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	if emission:
		material.emission_enabled = true
		material.emission = color * 0.45
		material.emission_energy_multiplier = 0.7
	return material


static func _add_box(parent: Node3D, size: Vector3, position: Vector3, color: Color, emission: bool = false) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.material_override = _material(color, emission)
	parent.add_child(mesh_instance)
	return mesh_instance


static func _add_cylinder(parent: Node3D, top_radius: float, bottom_radius: float, height: float, position: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.material_override = _material(color)
	parent.add_child(mesh_instance)
	return mesh_instance


static func _add_sphere(parent: Node3D, scale_value: Vector3, position: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 6
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.scale = scale_value
	mesh_instance.material_override = _material(color)
	parent.add_child(mesh_instance)
	return mesh_instance
