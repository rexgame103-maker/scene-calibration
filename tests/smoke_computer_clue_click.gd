extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280,720)
	var manager := root.get_node("CaseManager")
	manager.call("load_case","res://data/cases/office_case_001.json")
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	main.get("first_case_flow_ui").call("_on_accept_pressed")
	var point: SceneCluePoint
	for step in 24:
		for node in get_nodes_in_group("scene_clue_points"):
			if node.clue_point_id == "computer_work_log": point = node
		if is_instance_valid(point) and point.is_unlocked: break
		main.get("case_file_ui").close_files()
		main.get("scene_clue_popup").close()
		main.call("_debug_advance_next_step")
		for frame in 240:
			await process_frame
			if not main.get("debug_hint_button").disabled and not main.get("camera_transitioning"): break
	main.get("case_file_ui").close_files()
	main.get("scene_clue_popup").close()
	check(is_instance_valid(point) and point.is_unlocked,"Computer marker unlocked through reconstruction")
	if point == null:
		quit(1)
		return
	var computer := main.call("_debug_find_placed_furniture_by_id","office_computer") as Node3D
	main.call("_select_item",main.call("_find_entry_by_node",computer))
	main.call("_focus_selected_furniture")
	await create_timer(1.0).timeout
	check(point.visible and not point.is_discovered,"Visible computer marker is uncollected")
	var camera := main.get("camera") as Camera3D
	var screen := camera.unproject_position(point.global_position)
	var popup := main.get("scene_clue_popup") as SceneCluePopup
	# A genuine GUI button over the marker must win over scene investigation.
	var blocker := Button.new()
	blocker.text = "UI click guard"
	main.get("ui_root").add_child(blocker)
	blocker.z_index = 100
	blocker.position = screen-Vector2(70,25)
	blocker.size = Vector2(140,50)
	await process_frame
	await click(screen)
	check(not popup.visible,"GUI clicks cannot investigate the marker behind them")
	blocker.queue_free()
	await process_frame
	# Empty-space dragging remains available in the inspection camera.
	var drag := InputEventMouseButton.new()
	drag.position = Vector2(760,510)
	drag.button_index = MOUSE_BUTTON_LEFT
	drag.pressed = true
	root.push_input(drag,true)
	check(main.get("orbit_dragging"),"Blank inspection area still starts camera orbit")
	drag.pressed = false
	root.push_input(drag,true)
	await click(screen)
	check(popup.visible and popup.point == point,"Real mouse click opens computer clue")
	check(not main.get("orbit_dragging"),"Clicking a clue does not begin camera orbit")
	check(not manager.call("has_clue","clue_renovation_log"),"Opening clue does not skip collection")
	if popup.visible:
		popup.call("_process",10.0)
		await process_frame
		await click(popup.collect_button.get_global_rect().get_center())
		check(manager.call("has_clue","clue_renovation_log"),"Collect click awards computer clue")
		check(manager.call("is_furniture_unlocked","printer"),"Collected computer clue unlocks the printer")
	print("COMPUTER_CLUE_CLICK_OK" if failures.is_empty() else "COMPUTER_CLUE_CLICK_FAILED: " + str(failures))
	quit(0 if failures.is_empty() else 1)

func click(position: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.position = position
	root.push_input(move,true)
	await process_frame
	var hovered := root.gui_get_hovered_control()
	print("CLICK at=",position," UI=",hovered.get_path() if hovered else "none")
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		root.push_input(event,true)
		await process_frame
		await physics_frame
	await process_frame

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
