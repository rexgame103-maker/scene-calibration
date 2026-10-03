extends SceneTree


var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var packed_menu := load("res://scenes/start_menu/start_menu_office.tscn") as PackedScene
	_expect(is_instance_valid(packed_menu), "Start menu scene should load")
	if not is_instance_valid(packed_menu):
		_finish()
		return

	var menu := packed_menu.instantiate() as Node3D
	root.add_child(menu)
	current_scene = menu
	await process_frame

	menu.set("fade_out_duration", 0.25)
	menu.set("fade_in_duration", 0.1)
	menu.set("camera_push_in_distance", 3.0)
	var camera := menu.get_node("StartCamera") as Camera3D
	var original_camera_position := camera.global_position
	var original_camera_backward := camera.global_basis.z.normalized()
	var start_button := menu.get_node("StartMenuUI/UIRoot/MenuLayout/MenuColumn/StartButton") as Button
	var exit_button := menu.get_node("StartMenuUI/UIRoot/MenuLayout/MenuColumn/ExitButton") as Button
	# Exercise the transition after selection/confirmation, without resetting a real save.
	menu.call("_enter_studio")
	await process_frame
	await create_timer(0.08).timeout

	_expect(start_button.disabled and exit_button.disabled, "Both menu buttons should lock during transition")
	var camera_displacement := camera.global_position - original_camera_position
	_expect(camera_displacement.distance_to(Vector3.ZERO) > 0.01, "Camera should begin moving before scene change")
	_expect(camera_displacement.dot(original_camera_backward) < 0.0, "Start transition should push the camera toward the studio instead of pulling away")

	await create_timer(0.9).timeout
	_expect(is_instance_valid(current_scene), "A current scene should exist after transition")
	if is_instance_valid(current_scene):
		_expect(current_scene.scene_file_path == "res://scenes/studio/calibrator_studio.tscn", "Start game should enter the empty, player-built studio")
	var transition := root.get_node_or_null("SceneTransition")
	_expect(is_instance_valid(transition), "SceneTransition autoload should exist")
	if is_instance_valid(transition):
		_expect(not bool(transition.get("is_transitioning")), "Transition should finish after the first level fades in")
		var overlay := transition.get("fade_overlay") as ColorRect
		_expect(is_instance_valid(overlay) and overlay.color.a < 0.05, "Black overlay should be transparent after fade-in")

	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("START TRANSITION SMOKE: %s" % message)


func _finish() -> void:
	if failures.is_empty():
		print("START_GAME_TRANSITION_SMOKE_OK")
		quit(0)
	else:
		print("START_GAME_TRANSITION_SMOKE_FAILED: %s" % [failures])
		quit(1)
