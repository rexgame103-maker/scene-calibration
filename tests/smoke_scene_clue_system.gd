extends SceneTree


var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var case_manager := root.get_node_or_null("CaseManager")
	var reconstruction_manager := root.get_node_or_null("ReconstructionManager")
	_expect(is_instance_valid(case_manager), "CaseManager autoload should exist")
	_expect(is_instance_valid(reconstruction_manager), "ReconstructionManager autoload should exist")
	if not is_instance_valid(case_manager) or not is_instance_valid(reconstruction_manager):
		_finish()
		return

	case_manager.call("reset_current_case")
	await process_frame

	var main_scene := load("res://scenes/main.tscn") as PackedScene
	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame

	var desk_scene := load("res://scenes/furniture/desk_furniture.tscn") as PackedScene
	var desk := desk_scene.instantiate() as RigidBody3D
	desk.freeze = true
	main.get_node("PlacedFurniture").add_child(desk)
	var desk_zone := main.get_node("ReconstructionZones/DeskOriginalZone") as ReconstructionZone
	desk.global_position = Vector3(desk_zone.global_position.x, 0.0, desk_zone.global_position.z)
	desk.set_meta("furniture_id", "desk")

	var chair := Node3D.new()
	chair.name = "SmokeOfficeChair"
	chair.set_meta("furniture_id", "office_chair")
	main.get_node("PlacedFurniture").add_child(chair)
	var chair_zone := desk.get_node("ChairRelationZone") as ReconstructionZone
	chair.global_position = Vector3(chair_zone.global_position.x, 0.0, chair_zone.global_position.z)
	var computer := Node3D.new()
	computer.name = "SmokeOfficeComputer"
	computer.set_meta("furniture_id", "office_computer")
	main.get_node("PlacedFurniture").add_child(computer)
	var computer_zone := desk.get_node("ComputerRelationZone") as ReconstructionZone
	computer.global_position = computer_zone.global_position
	await process_frame
	await physics_frame

	var clue_point := desk.get_node("DeskSideWearClue") as SceneCluePoint
	_expect(is_instance_valid(clue_point), "Desk should contain the reusable scene clue point")
	_expect(not clue_point.is_unlocked, "Scene clue point should start locked")
	_expect(not clue_point.visible, "Locked scene clue point should be hidden at runtime")
	_expect(not case_manager.call("has_clue", "clue_desk_side_wear"), "Scene clue should not start discovered")
	_expect(not case_manager.call("is_furniture_unlocked", "small_cabinet"), "Cabinet should start locked")

	reconstruction_manager.call("register_furniture", desk)
	reconstruction_manager.call("register_furniture", chair)
	reconstruction_manager.call("register_furniture", computer)
	reconstruction_manager.call("notify_furniture_placement_completed", chair)
	await process_frame
	await physics_frame
	_expect(reconstruction_manager.call("has_step_completed", "office_workstation"), "Desk and chair relation should complete the configured reconstruction step")
	_expect(clue_point.is_unlocked, "Matching reconstruction step should unlock the scene clue point")
	_expect(not clue_point.visible, "Unlocked scene clue point should stay hidden in overview")

	main.call("_set_scene_clue_inspection_context", desk)
	await process_frame
	await physics_frame
	_expect(clue_point.visible, "Unlocked scene clue point should appear while inspecting its furniture")
	main.call("_focus_overview")
	await process_frame
	await physics_frame
	_expect(not clue_point.visible, "Returning to overview should hide the scene clue point immediately")
	main.call("_set_scene_clue_inspection_context", desk)
	await process_frame
	await physics_frame

	desk.position = Vector3.ZERO
	reconstruction_manager.call("notify_furniture_placement_completed", desk)
	await process_frame
	_expect(clue_point.is_unlocked and clue_point.visible, "Once unlocked, moving furniture away must not relock the clue point")

	var smoke_camera := main.get("camera") as Camera3D
	var clue_screen_position: Vector2 = smoke_camera.unproject_position(clue_point.global_position)
	_expect(bool(main.call("_try_investigate_scene_clue", clue_screen_position)), "Main scene click ray should prioritize the scene clue point")
	await process_frame
	var popup := main.get("scene_clue_popup") as SceneCluePopup
	_expect(popup.visible, "Investigating opens inspection")
	_expect(not case_manager.call("has_clue", "clue_desk_side_wear"), "Opening must not collect automatically")
	popup.elapsed = 100.0
	popup.call("_apply_intro")
	popup.collect_button.pressed.emit()
	_expect(case_manager.call("has_clue", "clue_desk_side_wear"), "Collecting should add the configured clue")
	_expect(case_manager.call("is_furniture_unlocked", "small_cabinet"), "Configured clue should unlock the cabinet")
	_expect(int((main.get("inventory_counts") as Dictionary).get("small_shelf", 0)) == 1, "Unlocked cabinet should enter the existing inventory")
	_expect(not clue_point.visible, "Discovered point should hide when hide_after_discovered is enabled")
	_expect(not case_manager.call("discover_clue", "clue_desk_side_wear"), "Duplicate clue discovery should be rejected")

	_expect(is_instance_valid(popup) and popup.visible, "Investigating should open the scene clue popup")
	if is_instance_valid(popup):
		_expect(popup.title_label.text == "桌侧磨损", "Popup should display the configured title")

	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("SMOKE TEST: %s" % message)


func _finish() -> void:
	if failures.is_empty():
		print("SCENE_CLUE_SMOKE_OK")
		quit(0)
	else:
		print("SCENE_CLUE_SMOKE_FAILED: %s" % [failures])
		quit(1)
