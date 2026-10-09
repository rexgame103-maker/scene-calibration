class_name StudioFurnitureFactory
extends RefCounted


const AUTHORED_PART_DIRECTORY := "res://scenes/studio/player_parts"
const PLANT_FOLIAGE := preload("res://scenes/props/indoor_plant_foliage.tscn")
const AUTHORED_PARTS := {
	"studio_desk": "studio_desk",
	"studio_chair": "studio_chair",
	"studio_computer": "studio_computer",
	"studio_bookshelf": "studio_bookshelf",
	"studio_lamp": "studio_lamp",
	"studio_rug": "studio_rug",
	"studio_plant": "studio_plant",
	"analysis_board": "analysis_board",
	"archive_terminal": "archive_terminal",
	"case_projector": "case_projector",
	"studio_sofa": "studio_sofa",
	"studio_coffee_table": "studio_coffee_table",
	"studio_window_bookcase": "studio_window_bookcase",
}

const ITEMS := {
	"studio_desk": {"label":"校准工作桌", "size":Vector3(3.45, 2.05, 1.61), "color":Color("a87452")},
	"studio_chair": {"label":"工作椅", "size":Vector3(1.13, 1.35, 1.13), "color":Color("66758f")},
	"studio_computer": {"label":"校准终端", "size":Vector3(1.56, 1.10, 0.99), "color":Color("709aaa"), "desk_item":true},
	"studio_bookshelf": {"label":"资料书架", "size":Vector3(2.40, 2.90, 0.70), "color":Color("8f735b")},
	"studio_lamp": {"label":"落地灯", "size":Vector3(0.70, 2.00, 0.70), "color":Color("d8b35f")},
	"studio_rug": {"label":"灰蓝地毯", "size":Vector3(3.70, 0.04, 2.85), "color":Color("63748c")},
	"studio_plant": {"label":"耐阴绿植", "size":Vector3(1.10, 1.29, 1.12), "color":Color("67916b")},
	"analysis_board": {"label":"痕迹分析板", "size":Vector3(3.70, 1.82, 0.17), "color":Color("a76352"), "wall_item":true},
	"reference_lightbox": {"label":"照片灯箱", "size":Vector3(1.35, 1.2, 0.32), "color":Color("c8b66e")},
	"archive_terminal": {"label":"档案索引机", "size":Vector3(0.94, 1.93, 0.81), "color":Color("657f9e")},
	"coffee_machine": {"label":"脾气古怪的咖啡机", "size":Vector3(0.62, 0.86, 0.56), "color":Color("765044")}
	,"case_projector": {"label":"案件回放投影仪", "size":Vector3(1.90, 1.65, 1.54), "color":Color("897bb0")}
	,"studio_sofa": {"label":"皮质沙发", "size":Vector3(2.80, 1.18, 1.10), "color":Color("5c5946")}
	,"studio_coffee_table": {"label":"工作室茶几", "size":Vector3(0.90, 0.83, 1.92), "color":Color("71503b")}
	,"studio_window_bookcase": {"label":"窗边矮柜", "size":Vector3(1.52, 0.90, 0.68), "color":Color("765d46")}
	,"case_frame_office": {"label":"蓝色文档案·复原照", "size":Vector3(1.36, 0.92, 0.10), "color":Color("795a45"), "wall_item":true, "case_id":"office_case_001", "fallback_image":"res://assets/case_photos/office/mail_photo_01.png"}
	,"case_frame_gallery": {"label":"失准修复室·复原照", "size":Vector3(1.36, 0.92, 0.10), "color":Color("596c78"), "wall_item":true, "case_id":"gallery_case_002", "fallback_image":"res://assets/case_photos/gallery/standard_layout_photo.png"}
	,"case_frame_apartment": {"label":"双室样板间·复原照", "size":Vector3(1.36, 0.92, 0.10), "color":Color("6d5b7d"), "wall_item":true, "case_id":"apartment_case_003", "fallback_image":"res://assets/case_photos/apartment/guest_room_photo.png"}
}


static func get_info(kind: String) -> Dictionary:
	return (ITEMS.get(kind, ITEMS["studio_desk"]) as Dictionary).duplicate(true)


static func build(kind: String, preview := false) -> Node3D:
	var root := Node3D.new()
	root.name = "%sModel" % kind.to_pascal_case()
	root.set_meta("studio_kind", kind)
	root.set_meta("furniture_kind", kind)
	var info := get_info(kind)
	if _authored_part(root, kind, preview):
		pass
	else:
		match kind:
			"studio_desk": _desk(root, info.color, preview)
			"studio_chair": _chair(root, info.color, preview)
			"studio_computer": _computer(root, info.color, preview)
			"studio_bookshelf": _bookshelf(root, info.color, preview)
			"studio_lamp": _lamp(root, info.color, preview)
			"studio_rug": _box(root, "Rug", Vector3(2.2, 0.04, 1.6), Vector3(0, 0.02, 0), info.color, preview)
			"studio_plant": _plant(root, info.color, preview)
			"analysis_board": _analysis_board(root, info.color, preview)
			"reference_lightbox": _lightbox(root, info.color, preview)
			"archive_terminal": _archive_terminal(root, info.color, preview)
			"coffee_machine": _coffee_machine(root, info.color, preview)
			"case_projector": _case_projector(root, info.color, preview)
			"case_frame_office", "case_frame_gallery", "case_frame_apartment": _case_frame(root, info, preview)
			_: _box(root, "Object", info.size, Vector3(0, info.size.y * 0.5, 0), info.color, preview)
	if not preview:
		_add_interaction_body(root, info.size)
	return root


static func _authored_part(root: Node3D, kind: String, preview: bool) -> bool:
	if not AUTHORED_PARTS.has(kind):
		return false
	var scene_path := "%s/%s.scn" % [AUTHORED_PART_DIRECTORY, String(AUTHORED_PARTS[kind])]
	var packed := load(scene_path) as PackedScene
	if not is_instance_valid(packed):
		return false
	var visual := packed.instantiate() as Node3D
	visual.name = "Visual"
	# The evidence board source is authored around its centre. Wall placement uses
	# a bottom-centred origin, like all other wall items in this system.
	if kind == "analysis_board":
		visual.position.y = 0.91
		visual.rotation_degrees.y = 180.0
	root.add_child(visual)
	if preview:
		for descendant: Node in visual.find_children("*", "GeometryInstance3D", true, false):
			var geometry := descendant as GeometryInstance3D
			geometry.transparency = 0.48
			geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for descendant: Node in visual.find_children("*", "Light3D", true, false):
			(descendant as Light3D).visible = false
	return true


static func _desk(root: Node3D, color: Color, preview: bool) -> void:
	_box(root, "Top", Vector3(2.4, 0.14, 1.15), Vector3(0, 0.98, 0), color, preview)
	for x: float in [-1.02, 1.02]:
		for z: float in [-0.43, 0.43]:
			_box(root, "Leg", Vector3(0.13, 0.94, 0.13), Vector3(x, 0.47, z), color.darkened(0.25), preview)
	_box(root, "Drawer", Vector3(0.62, 0.28, 0.86), Vector3(0.75, 0.78, 0), color.darkened(0.12), preview)


static func _chair(root: Node3D, color: Color, preview: bool) -> void:
	_box(root, "Seat", Vector3(0.72, 0.16, 0.72), Vector3(0, 0.63, 0), color, preview)
	_box(root, "Back", Vector3(0.72, 0.72, 0.13), Vector3(0, 1.02, 0.30), color.lightened(0.05), preview)
	_box(root, "Stem", Vector3(0.12, 0.52, 0.12), Vector3(0, 0.32, 0), Color("333a45"), preview)
	for angle: float in [0.0, 72.0, 144.0, 216.0, 288.0]:
		var arm := _box(root, "WheelArm", Vector3(0.52, 0.07, 0.08), Vector3(0.21, 0.08, 0), Color("333a45"), preview)
		arm.rotation_degrees.y = angle


static func _computer(root: Node3D, color: Color, preview: bool) -> void:
	_box(root, "Monitor", Vector3(0.78, 0.48, 0.10), Vector3(0, 0.48, 0), Color("222a34"), preview)
	_box(root, "Screen", Vector3(0.68, 0.38, 0.012), Vector3(0, 0.49, -0.056), color.lightened(0.28), preview, true)
	_box(root, "Stand", Vector3(0.10, 0.25, 0.10), Vector3(0, 0.18, 0), Color("303845"), preview)
	_box(root, "Base", Vector3(0.42, 0.06, 0.30), Vector3(0, 0.04, 0), Color("303845"), preview)


static func _bookshelf(root: Node3D, color: Color, preview: bool) -> void:
	_box(root, "Back", Vector3(1.55, 2.15, 0.12), Vector3(0, 1.075, 0.18), color.darkened(0.28), preview)
	for x: float in [-0.72, 0.72]:
		_box(root, "Side", Vector3(0.12, 2.15, 0.48), Vector3(x, 1.075, 0), color, preview)
	for y: float in [0.08, 0.55, 1.03, 1.51, 2.08]:
		_box(root, "Shelf", Vector3(1.55, 0.10, 0.48), Vector3(0, y, 0), color.lightened(0.05), preview)


static func _lamp(root: Node3D, color: Color, preview: bool) -> void:
	_cylinder(root, "Base", 0.26, 0.08, Vector3(0, 0.04, 0), color.darkened(0.35), preview)
	_cylinder(root, "Pole", 0.045, 1.42, Vector3(0, 0.75, 0), color.darkened(0.35), preview)
	_cylinder(root, "Shade", 0.30, 0.34, Vector3(0, 1.52, 0), color, preview)


static func _plant(root: Node3D, color: Color, preview: bool) -> void:
	_cylinder(root, "Pot", 0.28, 0.42, Vector3(0, 0.21, 0), Color("7a5140"), preview)
	var foliage := PLANT_FOLIAGE.instantiate() as Node3D
	foliage.position.y = 0.42
	root.add_child(foliage)
	if preview:
		for leaf: GeometryInstance3D in foliage.get_children():
			leaf.transparency = 0.48
			leaf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func _analysis_board(root: Node3D, color: Color, preview: bool) -> void:
	_box(root, "Stand", Vector3(1.48, 1.05, 0.12), Vector3(0, 0.96, 0), color.darkened(0.32), preview)
	_box(root, "Board", Vector3(1.36, 0.92, 0.06), Vector3(0, 1.0, -0.09), Color("d7c9aa"), preview)
	for point: Vector3 in [Vector3(-0.35,1.12,-0.13),Vector3(0.28,1.25,-0.13),Vector3(0.12,0.78,-0.13)]:
		_sphere(root, "Pin", 0.045, point, color, preview)
	_box(root, "StandFoot", Vector3(1.60, 0.08, 0.42), Vector3(0, 0.04, 0), color.darkened(0.28), preview)


static func _lightbox(root: Node3D, color: Color, preview: bool) -> void:
	_box(root, "Cabinet", Vector3(1.35, 0.82, 0.32), Vector3(0, 0.48, 0), color.darkened(0.32), preview)
	_box(root, "GlowPanel", Vector3(1.18, 0.68, 0.025), Vector3(0, 0.51, -0.18), Color("fff2bf"), preview, true)
	_box(root, "Foot", Vector3(1.45, 0.08, 0.48), Vector3(0, 0.04, 0), color, preview)


static func _archive_terminal(root: Node3D, color: Color, preview: bool) -> void:
	_box(root, "Body", Vector3(1.05, 1.15, 0.72), Vector3(0, 0.575, 0), color.darkened(0.18), preview)
	_box(root, "Screen", Vector3(0.77, 0.48, 0.025), Vector3(0, 1.12, -0.375), color.lightened(0.30), preview, true)
	_box(root, "Keyboard", Vector3(0.82, 0.08, 0.30), Vector3(0, 0.72, -0.46), Color("343a47"), preview)


static func _coffee_machine(root: Node3D, color: Color, preview: bool) -> void:
	_box(root, "Body", Vector3(0.62, 0.78, 0.56), Vector3(0, 0.39, 0), color, preview)
	_box(root, "Panel", Vector3(0.43, 0.25, 0.025), Vector3(0, 0.56, -0.295), Color("222730"), preview)
	_cylinder(root, "Cup", 0.11, 0.22, Vector3(0, 0.12, -0.32), Color("e8ddd0"), preview)


static func _case_projector(root: Node3D, color: Color, preview: bool) -> void:
	_box(root, "Pedestal", Vector3(0.92, 0.82, 0.68), Vector3(0, 0.41, 0), color.darkened(0.22), preview)
	_box(root, "Projector", Vector3(1.10, 0.34, 0.62), Vector3(0, 0.94, 0), color, preview)
	_cylinder(root, "Lens", 0.16, 0.10, Vector3(0, 0.95, -0.36), Color("8fd0de"), preview)
	_box(root, "Indicator", Vector3(0.12, 0.04, 0.04), Vector3(0.36, 1.07, -0.32), Color("9be7b3"), preview, true)


static func _case_frame(root: Node3D, info: Dictionary, preview: bool) -> void:
	var color := info.get("color", Color("765f50")) as Color
	var size := info.get("size", Vector3(1.36, 0.92, 0.10)) as Vector3
	_box(root, "FrameBacking", size, Vector3(0, size.y * 0.5, 0), color.darkened(0.32), preview)
	var border_width := 0.075
	_box(root, "FrameTop", Vector3(size.x, border_width, size.z + 0.025), Vector3(0, size.y - border_width * 0.5, -0.008), color, preview)
	_box(root, "FrameBottom", Vector3(size.x, border_width, size.z + 0.025), Vector3(0, border_width * 0.5, -0.008), color, preview)
	_box(root, "FrameLeft", Vector3(border_width, size.y - border_width * 2.0, size.z + 0.025), Vector3(-size.x * 0.5 + border_width * 0.5, size.y * 0.5, -0.008), color, preview)
	_box(root, "FrameRight", Vector3(border_width, size.y - border_width * 2.0, size.z + 0.025), Vector3(size.x * 0.5 - border_width * 0.5, size.y * 0.5, -0.008), color, preview)
	var photo := MeshInstance3D.new()
	photo.name = "CasePhoto"
	var photo_texture := _case_frame_texture(info)
	var photo_size := Vector2(size.x - border_width * 2.25, size.y - border_width * 2.25)
	if is_instance_valid(photo_texture) and photo_texture.get_width() > 0 and photo_texture.get_height() > 0:
		var texture_aspect := float(photo_texture.get_width()) / float(photo_texture.get_height())
		var opening_aspect := photo_size.x / photo_size.y
		if opening_aspect > texture_aspect:
			photo_size.x = photo_size.y * texture_aspect
		else:
			photo_size.y = photo_size.x / texture_aspect
	# A QuadMesh owns one full 0-1 UV island. A thin BoxMesh splits the texture
	# between six faces, which made the visible face show only one photo fragment.
	var photo_mesh := QuadMesh.new()
	photo_mesh.size = photo_size
	photo.mesh = photo_mesh
	photo.position = Vector3(0, size.y * 0.5, -size.z * 0.5 - 0.014)
	photo.material_override = _photo_material(photo_texture, preview)
	root.add_child(photo)


static func _case_frame_texture(info: Dictionary) -> Texture2D:
	var case_id := String(info.get("case_id", ""))
	if not case_id.is_empty():
		var album_path := "user://case_album/%s.png" % case_id
		if FileAccess.file_exists(album_path):
			var image := Image.load_from_file(ProjectSettings.globalize_path(album_path))
			if image != null and not image.is_empty():
				return ImageTexture.create_from_image(image)
	var fallback_path := String(info.get("fallback_image", ""))
	if not fallback_path.is_empty() and ResourceLoader.exists(fallback_path):
		return load(fallback_path) as Texture2D
	return null


static func _photo_material(texture: Texture2D, preview: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1, 1, 1, 0.58 if preview else 1.0)
	material.albedo_texture = texture
	material.roughness = 0.72
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if is_instance_valid(texture):
		material.emission_enabled = true
		material.emission = Color.WHITE
		material.emission_texture = texture
		material.emission_energy_multiplier = 0.32
	if preview:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


static func _box(root: Node3D, node_name: String, size: Vector3, position: Vector3, color: Color, preview: bool, emission := false) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.material_override = _material(color, preview, emission)
	root.add_child(mesh_instance)
	return mesh_instance


static func _cylinder(root: Node3D, node_name: String, radius: float, height: float, position: Vector3, color: Color, preview: bool) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.material_override = _material(color, preview)
	root.add_child(mesh_instance)
	return mesh_instance


static func _sphere(root: Node3D, node_name: String, radius: float, position: Vector3, color: Color, preview: bool) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.material_override = _material(color, preview)
	root.add_child(mesh_instance)
	return mesh_instance


static func _material(color: Color, preview: bool, emission := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color, 0.52 if preview else 1.0)
	material.roughness = 0.82
	if preview:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if emission:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.65
	return material


static func _add_interaction_body(root: Node3D, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "InteractionBody"
	body.collision_layer = 4
	body.collision_mask = 1
	body.set_meta("studio_furniture_root", root)
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	shape_node.shape = shape
	shape_node.position.y = size.y * 0.5
	body.add_child(shape_node)
	root.add_child(body)
