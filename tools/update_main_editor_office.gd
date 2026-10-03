extends SceneTree

func _initialize() -> void:
	call_deferred("_update")

func _update() -> void:
	var path := "res://scenes/main.tscn"
	var main := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Node3D
	if main.has_node("EditorOfficePreview"):
		preload("res://scripts/office_editor_preview.gd").sync_zones(main)
	else:
		preload("res://scripts/office_editor_preview.gd").populate(main)
	var packed := PackedScene.new()
	assert(packed.pack(main)==OK)
	assert(ResourceSaver.save(packed,path)==OK)
	main.free()
	var saved := ResourceLoader.load(path,"PackedScene",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var check := saved.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	assert(check.get_node("EditorOfficePreview").get_child_count()==10)
	assert(check.has_node("EditorOfficePreview/Computer/Keyboard/Key"))
	assert(check.has_node("EditorOfficePreview/Desk/WritingDesk/CaseNotes"))
	var case_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cases/office_case_001.json"))
	var furniture_names := {"desk":"Desk", "small_cabinet":"SmallShelf", "file_shelf":"Shelf", "printer":"Printer", "water_dispenser":"WaterDispenser"}
	for config: Dictionary in case_data["reconstruction_zones"]:
		var matched := false
		for zone in check.get_node("ReconstructionZones").get_children():
			if zone.get("zone_id") != config["zone_id"]: continue
			matched = true
			var p: Array = config["position"]
			var s: Array = config["size"]
			assert(zone.position.is_equal_approx(Vector3(p[0],p[1],p[2])))
			assert(zone.zone_size.is_equal_approx(Vector3(s[0],s[1],s[2])))
			var art := check.get_node("EditorOfficePreview/" + furniture_names[config["required_furniture_id"]]) as Node3D
			var delta: Vector3 = art.position - zone.position
			var half: Vector3 = zone.zone_size * 0.5
			assert(absf(delta.x)<=half.x and absf(delta.y)<=half.y and absf(delta.z)<=half.z)
		assert(matched)
	print("EDITOR_ZONES_OK: all five saved zones match case data and contain their furniture origins")
	check.free()
	print("MAIN_EDITOR_PREVIEW_OK: complete office persisted, keyboard and desk paper groups intact")
	quit()
