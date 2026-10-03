extends SceneTree

var failures: Array[String] = []
var photo_requests := 0
var return_requests := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func click(button: Button) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	root.push_input(motion, true)
	await process_frame
	print("CLICK ", button.name, " at=", motion.position, " hover=", root.gui_get_hovered_control())
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = button.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
		await process_frame

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var manager := root.get_node("CaseManager")
	manager.call("load_case", "res://data/cases/office_case_001.json")
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	var flow := main.get("first_case_flow_ui") as FirstCaseFlowUI
	# Exercise UI signals without modifying the player's album or saved progress.
	for connection in flow.photo_requested.get_connections():
		flow.photo_requested.disconnect(connection.callable)
	for connection in flow.settlement_closed.get_connections():
		flow.settlement_closed.disconnect(connection.callable)
	flow.photo_requested.connect(func(): photo_requests += 1)
	flow.settlement_closed.connect(func(): return_requests += 1)
	flow.show_settlement()
	await create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/settlement_newspaper_preview.png")
	check(not flow.briefing_panel.visible and flow.is_modal_active(), "Settlement replaces briefing and blocks scene input")
	check(not flow.return_button.visible, "Photo capture precedes return")
	await click(flow.photo_button)
	check(photo_requests == 1, "Photo button emits request on actual click")
	flow.begin_photo_capture()
	check(not flow.settlement_panel.visible and not flow.modal_backdrop.visible, "Capture hides the newspaper")
	flow.finish_photo_capture(true)
	await process_frame
	check(flow.photo_button.disabled and flow.return_button.visible, "Saved photo enables return and disables duplicate capture")
	await click(flow.return_button)
	check(return_requests == 1, "Return button emits on actual click")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/settlement_newspaper_saved_preview.png")
	flow.finish_photo_capture(false)
	check(flow.return_button.visible and flow.photo_button.text.contains("失败"), "Capture failure retains return and explains outcome")
	for case_path in ["res://data/cases/office_case_001.json", "res://data/cases/gallery_case_002.json"]:
		manager.call("load_case", case_path)
		flow.show_settlement()
		await process_frame
		for path in ["Margin/Column/Description", "Margin/Column/DeductionPanel/Deduction"]:
			var copy := flow.settlement_panel.get_node(path) as RichTextLabel
			check(copy.get_content_height() <= copy.size.y, "Report text fits: " + case_path + " " + path)
	for window_size in [Vector2i(1024, 768), Vector2i(1920, 1080)]:
		root.size = window_size
		await create_timer(0.2).timeout
		var viewport_rect := flow.get_global_rect()
		check(viewport_rect.encloses(flow.settlement_panel.get_global_rect()), "Newspaper fits resized viewport")
	print("SETTLEMENT_NEWSPAPER_OK" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
