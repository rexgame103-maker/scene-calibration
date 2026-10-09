extends SceneTree
## Real key events, both formal cases, and a measured arrival animation.

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.get_node("GameLanguage").set_language("en")
	var manager := root.get_node("CaseManager")
	var reconstruction := root.get_node("ReconstructionManager")
	for case_id: String in ["office_case_001", "gallery_case_002"]:
		check(manager.load_case("res://data/cases/" + case_id + ".json"), "Load formal case " + case_id)
		var scene := load("res://scenes/main.tscn").instantiate() as Node3D
		root.add_child(scene)
		current_scene = scene
		await process_frame
		await physics_frame
		check(not scene.get("debug_hint_button").is_visible_in_tree(), "Debug button is hidden in " + case_id)
		check(scene.get("debug_hint_button").mouse_filter == Control.MOUSE_FILTER_IGNORE, "Hidden button cannot capture pointer input")
		press_p()
		check(not scene.get("case_file_ui").visible and (scene.get("placed_items") as Array).is_empty(), "P does not skip the briefing")
		scene.get("first_case_flow_ui").call("_on_accept_pressed")
		await process_frame

		if case_id == "office_case_001":
			var editor := LineEdit.new()
			scene.get("ui_root").add_child(editor)
			editor.grab_focus()
			press_p()
			check(not scene.get("case_file_ui").visible, "Typing P in a text field cannot advance the case")
			editor.release_focus()
			editor.queue_free()
			press_p(true)
			check(not scene.get("case_file_ui").visible, "Repeated key event cannot advance")
			paused = true
			press_p()
			check(not scene.get("case_file_ui").visible, "P cannot advance while paused")
			paused = false
			press_p()
			check(scene.get("case_file_ui").visible, "P opens the evidence through real input routing")
			# Both the photo and the assignment text precede furniture in the flow.
			for evidence_index: int in range(4):
				if (scene.call("_debug_find_next_evidence") as Dictionary).is_empty():
					break
				press_p()
			# Leave the archive open: the next key must expose the placement animation.
			press_p()
			var desk := scene.call("_debug_find_placed_furniture_by_id", "desk") as Node3D
			check(is_instance_valid(desk), "P places the unlocked desk")
			if is_instance_valid(desk):
				var start := desk.global_position
				check(scene.get("_debug_step_running"), "Animation keeps the shortcut busy")
				check(not scene.get("case_file_ui").visible, "P closes the archive before showing the furniture")
				check(not reconstruction.is_zone_satisfied("zone_desk_original"), "Placement is not credited before landing")
				var items_before := (scene.get("placed_items") as Array).size()
				press_p()
				press_p(true)
				scene.call("_undo_last")
				scene.call("_clear_room")
				check((scene.get("placed_items") as Array).size() == items_before, "Rapid P, undo and clear cannot alter the active drop")
				await create_timer(0.10).timeout
				await process_frame
				print("DEBUG_DROP_SAMPLE start=%s middle=%s" % [start, desk.global_position])
				check(desk.global_position.y < start.y and desk.global_position.y > start.y - 1.0, "Furniture moves downward over time")
				# Both the animation and its completion timer must stop during pause.
				paused = true
				var paused_position := desk.global_position
				await create_timer(0.12).timeout
				check(desk.global_position.is_equal_approx(paused_position) and scene.get("_debug_step_running"), "Drop pauses without snapping to the floor")
				paused = false
				await wait_for_step(scene)
				check(desk.global_position.is_equal_approx(start - Vector3.UP), "Drop lands exactly one metre below its starting position")
				check(reconstruction.is_zone_satisfied("zone_desk_original"), "Landing credits the actual reconstruction zone")
				check((desk as RigidBody3D).freeze, "Animated debug placement remains stable after landing")

		for step: int in range(60):
			var popup: SceneCluePopup = scene.get("scene_clue_popup")
			if popup.visible:
				if is_instance_valid(popup.point):
					popup.point.collect_clue()
				popup.close()
				await create_timer(0.5).timeout
			if bool(scene.call("_debug_case_flow_finished")):
				break
			press_p()
			await wait_for_step(scene)
		check(bool(scene.call("_debug_case_flow_finished")), "P completes the real final conditions in " + case_id)
		var ids: Dictionary = {}
		for entry: Dictionary in scene.get("placed_items"):
			var id := String(entry.furniture_id)
			check(not ids.has(id), "Moving later-phase furniture does not duplicate " + id)
			ids[id] = true
		var count_before := (scene.get("placed_items") as Array).size()
		press_p()
		check((scene.get("placed_items") as Array).size() == count_before and not scene.get("_debug_step_running"), "P does nothing after case completion")
		scene.get("case_file_ui").close_files()
		scene.call("_submit_first_case_reconstruction")
		check(scene.get("first_case_flow_ui").settlement_panel.visible, "Animated placements preserve submission in " + case_id)
		print("DEBUG_HOTKEY_CASE_OK: " + case_id)
		scene.queue_free()
		current_scene = null
		await process_frame
		await process_frame
	root.get_node("GameAudio").stop_all()
	await create_timer(0.3).timeout
	print("DEBUG_HOTKEY_SMOKE_OK" if failures.is_empty() else "DEBUG_HOTKEY_SMOKE_FAILED: %s" % [failures])
	quit(0 if failures.is_empty() else 1)

func press_p(echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_P
	event.keycode = KEY_P
	event.pressed = true
	event.echo = echo
	root.push_input(event, true)

func wait_for_step(scene: Node) -> void:
	var deadline := Time.get_ticks_msec() + 4000
	while bool(scene.get("_debug_step_running")) or bool(scene.get("camera_transitioning")):
		if Time.get_ticks_msec() > deadline:
			check(false, "P action did not release its busy state")
			return
		await create_timer(0.01).timeout

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("DEBUG HOTKEY SMOKE: " + message)
