extends RefCounted
## Static, editable art preview. Removed before gameplay registers furniture.

static func populate(main: Node3D) -> void:
	sync_zones(main)
	var previous := main.get_node_or_null("EditorOfficePreview")
	if previous != null: previous.free()
	var preview := Node3D.new()
	preview.name = "EditorOfficePreview"
	preview.set_meta("purpose", "编辑器中的完整办公室预览；运行时由案件流程生成可交互家具")
	main.add_child(preview)
	var positions := {
		"desk":Vector3(0.1,0.04,-2.26),
		"chair":Vector3(0.15,0.04,-0.62),
		"computer":Vector3(0.1,1.258,-2.26),
		"small_shelf":Vector3(2.30,0.04,-2.26),
		"shelf":Vector3(-3.37,0.04,-2.55),
		"printer":Vector3(3.14,0.04,1.0),
		"water_dispenser":Vector3(-2.21,0.04,-2.49),
		"red_file":Vector3(-3.78,1.303,-2.43),
		"gray_file":Vector3(-3.39,1.303,-2.43),
		"ordinary_file_01":Vector3(-3.0,1.303,-2.43)
	}
	for kind: String in positions:
		var art := (load("res://scenes/cases/office_parts/"+kind+".tscn") as PackedScene).instantiate() as Node3D
		art.name = kind.to_pascal_case()
		art.position = positions[kind]
		preview.add_child(art)
		_localize(art,main)
	preview.owner=main

static func sync_zones(main: Node3D) -> void:
	var case_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cases/office_case_001.json"))
	var zones := main.get_node("ReconstructionZones")
	for config: Dictionary in case_data["reconstruction_zones"]:
		for zone in zones.get_children():
			if zone.get("zone_id") != config["zone_id"]:
				continue
			var p: Array = config["position"]
			var s: Array = config["size"]
			zone.position = Vector3(p[0], p[1], p[2])
			zone.rotation = Vector3.ZERO
			zone.zone_size = Vector3(s[0], s[1], s[2])
			zone.required_furniture_id = config["required_furniture_id"]
			zone.require_orientation = config.get("require_orientation", false)
			zone.target_yaw_degrees = config.get("target_yaw", 0.0)
			zone.orientation_tolerance_degrees = config.get("orientation_tolerance", 15.0)

static func _localize(node: Node, scene: Node) -> void:
	node.scene_file_path=""
	node.owner=scene
	for child in node.get_children(): _localize(child,scene)
