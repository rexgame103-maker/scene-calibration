extends SceneTree


var _failures: Array[String] = []
var _had_save := false
var _saved_profile_text := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_had_save = FileAccess.file_exists("user://calibrator_profile.json")
	if _had_save:
		_saved_profile_text = FileAccess.get_file_as_string("user://calibrator_profile.json")
	var profile := root.get_node_or_null("PlayerProfile")
	_expect(is_instance_valid(profile), "PlayerProfile should be available")
	if not is_instance_valid(profile):
		_finish()
		return

	# Keep the real save file untouched: this reset only changes this test process.
	profile.call("reset_profile", false)
	_expect((profile.get("placed_studio_layout") as Array).is_empty(), "A new game should start with no placed studio furniture")
	_expect(not bool(profile.call("has_studio_workstation")), "An empty studio should not have an active workstation")
	var inventory := profile.call("get_available_studio_inventory") as Dictionary
	for starter_kind: String in ["studio_desk", "studio_chair", "studio_computer", "studio_bookshelf", "studio_lamp"]:
		_expect(int(inventory.get(starter_kind, 0)) == 1, "Starter inventory should contain %s" % starter_kind)

	var menu := (load("res://scenes/start_menu/start_menu_office.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(menu)
	await process_frame
	_expect(menu.has_node("StudioBackground/InvestigationDesk"), "Start menu should keep the complete authored desk")
	_expect(menu.has_node("StudioBackground/EvidenceBoard"), "Start menu should keep the complete clue wall")
	_expect(menu.has_node("StudioBackground/LeatherSofa"), "Start menu should keep the complete lounge furniture")
	menu.queue_free()
	await process_frame

	var studio := (load("res://scenes/studio/calibrator_studio.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(studio)
	current_scene = studio
	await process_frame
	await process_frame
	var furniture_root := studio.get_node_or_null("StudioFurniture")
	_expect(is_instance_valid(furniture_root), "Playable studio should have a dynamic furniture root")
	if is_instance_valid(furniture_root):
		_expect(furniture_root.get_child_count() == 0, "New playable studio should render as an empty room")
	_expect(is_instance_valid(studio.get("catalog_panel") as PanelContainer), "Empty studio should expose the furniture catalog")
	await create_timer(0.75).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/empty_studio_start_preview.png")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error("EMPTY STUDIO START: %s" % message)


func _finish() -> void:
	_restore_save_file()
	if _failures.is_empty():
		print("EMPTY_STUDIO_START_OK")
		quit(0)
	else:
		print("EMPTY_STUDIO_START_FAILED: %s" % [_failures])
		quit(1)


func _restore_save_file() -> void:
	if _had_save:
		var file := FileAccess.open("user://calibrator_profile.json", FileAccess.WRITE)
		if file != null:
			file.store_string(_saved_profile_text)
	elif FileAccess.file_exists("user://calibrator_profile.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://calibrator_profile.json"))
