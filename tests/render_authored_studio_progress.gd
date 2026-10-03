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
	profile.call("reset_profile", false)
	for kind: String in StudioFurnitureFactory.AUTHORED_PARTS:
		var built := StudioFurnitureFactory.build(kind)
		_expect(built.has_node("Visual"), "%s should instantiate its authored model" % kind)
		built.free()
		var preview := StudioFurnitureFactory.build(kind, true)
		_expect(preview.has_node("Visual"), "%s should instantiate an authored placement preview" % kind)
		preview.free()
	profile.call("set_studio_layout", [
		{"kind":"studio_desk", "uid":"desk-1", "position":[-2.0, 0.0, -1.65], "rotation":[0.0, 0.0, 0.0], "floor":0},
		{"kind":"studio_chair", "uid":"chair-1", "position":[-2.0, 0.0, 0.05], "rotation":[0.0, 180.0, 0.0], "floor":0},
		{"kind":"studio_computer", "uid":"computer-1", "support_uid":"desk-1", "position":[-2.0, 1.21, -1.65], "rotation":[0.0, 0.0, 0.0], "floor":0},
		{"kind":"studio_bookshelf", "uid":"shelf-1", "position":[3.4, 0.0, -4.42], "rotation":[0.0, 0.0, 0.0], "floor":0},
		{"kind":"studio_lamp", "uid":"lamp-1", "position":[4.5, 0.0, 0.78], "rotation":[0.0, 0.0, 0.0], "floor":0},
	])
	print("AUTHORED_STUDIO_LAYOUT: %d" % (profile.get("placed_studio_layout") as Array).size())

	var studio := (load("res://scenes/studio/calibrator_studio.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(studio)
	current_scene = studio
	await process_frame
	await process_frame
	var furniture_root := studio.get_node_or_null("StudioFurniture")
	_expect(is_instance_valid(furniture_root), "Dynamic furniture root should exist")
	if is_instance_valid(furniture_root):
		print("AUTHORED_STUDIO_CHILDREN: %d %s" % [furniture_root.get_child_count(), furniture_root.get_children().map(func(node: Node) -> String: return node.name)])
		_expect(furniture_root.get_child_count() == 5, "Starter layout should restore five furniture groups")
		for child: Node in furniture_root.get_children():
			_expect(child.has_node("Visual"), "%s should use an authored visual" % child.name)
	var shell := studio.get_node_or_null("StudioShell")
	_expect(is_instance_valid(shell) and shell.has_node("AuthoredEmptyStudio/Architecture"), "Playable studio should use the exact authored room architecture")
	_expect(is_instance_valid(shell) and shell.has_node("AuthoredEmptyStudio/WoodFloor"), "Playable studio should use the exact authored wood floor")
	_expect(is_instance_valid(shell) and shell.has_node("AuthoredEmptyStudio/WorkspaceLighting"), "Playable studio should retain the authored lighting hierarchy")
	await create_timer(0.75).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/authored_studio_progress_preview.png")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error("AUTHORED STUDIO PROGRESS: %s" % message)


func _finish() -> void:
	_restore_save_file()
	if _failures.is_empty():
		print("AUTHORED_STUDIO_PROGRESS_OK")
		quit(0)
	else:
		print("AUTHORED_STUDIO_PROGRESS_FAILED: %s" % [_failures])
		quit(1)


func _restore_save_file() -> void:
	if _had_save:
		var file := FileAccess.open("user://calibrator_profile.json", FileAccess.WRITE)
		if file != null:
			file.store_string(_saved_profile_text)
	elif FileAccess.file_exists("user://calibrator_profile.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://calibrator_profile.json"))
