extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func click(position: Vector2) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
		await process_frame
		await physics_frame

func _run() -> void:
	root.size = Vector2i(1280, 800)
	var manager := root.get_node("CaseManager")
	manager.call("load_case", "res://data/cases/office_case_001.json")
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	main.get("first_case_flow_ui").call("_on_accept_pressed")
	manager.call("view_evidence", "mail_photo_01")
	var reconstruction := root.get_node("ReconstructionManager")
	for id: String in ["zone_desk_original", "zone_chair_at_desk", "zone_computer_on_desk"]:
		main.call("_debug_place_furniture_in_zone", reconstruction.get("zones")[id])
	var desk := main.call("_debug_find_placed_furniture_by_id", "desk") as Node3D
	main.call("_select_item", main.call("_find_entry_by_node", desk))
	main.call("_focus_selected_furniture")
	await create_timer(0.8).timeout
	var point := desk.get_node("DeskSideWearClue") as SceneCluePoint
	var camera := main.get("camera") as Camera3D
	var popup := main.get("scene_clue_popup") as SceneCluePopup
	check(point.is_unlocked, "Desk clue is unlocked")
	check(not point.visible and not point.input_ray_pickable, "Hidden desk side has no visible or pickable marker")
	check(not point.investigate(), "Direct investigation cannot bypass the hidden-side gate")
	await click(camera.unproject_position(point.global_position))
	check(not popup.visible and not point.is_discovered, "Blind click through desk cannot open or collect clue")
	var found := false
	for yaw: float in [-45.0, 45.0]:
		for pitch: float in [-22.0, 0.0, 22.0]:
			main.set("focus_target_yaw", yaw)
			main.set("focus_target_pitch", pitch)
			main.call("_update_focus_camera", 10.0)
			if point.is_visible_from_camera():
				found = true
				print("REACHABLE_CLUE_VIEW yaw=", yaw, " pitch=", pitch)
				break
		if found: break
	check(found, "Clue is reachable within normal camera orbit limits")
	if not found:
		quit(1)
		return
	main.set_process(false)
	await process_frame
	await physics_frame
	check(point.visible and point.input_ray_pickable, "Rotating to visible surface enables marker")
	var visible_transform := camera.global_transform
	# Actual rendered geometry without any collision shape must occlude the clue.
	var blocker := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 0.5
	blocker.mesh = box
	main.add_child(blocker)
	blocker.global_position = point.global_position.lerp(camera.global_position, 0.15)
	await process_frame
	await process_frame
	check(not point.visible and not point.investigate(), "Visual geometry occludes marker without broad physics boxes")
	await click(camera.unproject_position(point.global_position))
	check(not popup.visible, "Occluded marker ignores real clicks")
	blocker.queue_free()
	await process_frame
	await process_frame
	check(point.visible, "Removing obstruction restores marker")
	# A camera move in the same frame must invalidate a previously visible marker.
	camera.global_position = point.global_position - (point.global_basis * Vector3.RIGHT) * 3.0
	camera.look_at(point.global_position)
	check(not point.investigate(), "Click rechecks view immediately before the next visual refresh")
	camera.global_transform = visible_transform
	await process_frame
	await click(camera.unproject_position(point.global_position))
	check(popup.visible and popup.point == point, "Visible marker opens on actual mouse click")
	check(not point.is_discovered, "Opening still requires manual clue collection")
	print("CLUE_VISIBILITY_OK" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
