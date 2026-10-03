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
	var ui := main.get("case_file_ui") as CaseFileUI
	# Follow the existing debug progression to the user's equipment-placement stage.
	for step in 32:
		if is_instance_valid(main.call("_debug_find_placed_furniture_by_id","printer")) and is_instance_valid(main.call("_debug_find_placed_furniture_by_id","water_dispenser")):
			break
		ui.close_files()
		main.get("scene_clue_popup").close()
		main.call("_debug_advance_next_step")
		for frame in 240:
			await process_frame
			if not main.get("debug_hint_button").disabled and not main.get("camera_transitioning"):
				break
	ui.close_files()
	main.get("scene_clue_popup").close()
	check(is_instance_valid(main.call("_debug_find_placed_furniture_by_id","printer")),"Printer placed")
	check(is_instance_valid(main.call("_debug_find_placed_furniture_by_id","water_dispenser")),"Water dispenser placed")
	var tray := main.get("photo_reference_tray") as ReferencePhotoTray
	tray.add_reference("mail_photo_01")
	tray._toggle_photo("mail_photo_01")
	var pinned := tray._floating_cards.get("mail_photo_01") as Control
	check(is_instance_valid(pinned),"Reference photograph pinned")
	main.call("_open_case_files")
	ui._select_evidence("mail_photo_01")
	await process_frame
	await process_frame
	for title in ["警局委托说明","打印纸上的旧照片"]:
		var target: Button
		for child in ui._evidence_list.get_children():
			if child is Button and child.text.contains(title):
				target = child
		check(target != null,"Evidence button present: " + title)
		if target == null: continue
		await click(target)
		check(ui._detail_title.text == title,"Mouse click opens " + title + "; actual=" + ui._detail_title.text)
	# Return also has to work through real GUI hit testing, and restore references.
	await click(ui._archive_view.return_button)
	check(not ui.visible,"Mouse click returns to scene")
	check(pinned.is_visible_in_tree() and pinned.modulate.a > 0.0,"Pinned photo restored after closing")
	# A new reference is appended after the previous modal ordering. Reopening
	# must raise the reader again, including in the user's wider window shape.
	tray.add_reference("printer_layout_photo")
	tray._toggle_photo("printer_layout_photo")
	root.size = Vector2i(1600,824)
	await process_frame
	main.call("_open_case_files")
	await process_frame
	await process_frame
	for title in ["警局委托说明","打印纸上的旧照片"]:
		var button: Button
		for child in ui._evidence_list.get_children():
			if child is Button and child.text.contains(title): button = child
		if button == null:
			check(false,"Reopened evidence button present: " + title)
			continue
		await click(button)
		check(ui._detail_title.text == title,"Reopened archive click: " + title)
	await click(ui._archive_view.return_button)
	check(not ui.visible,"Reopened archive returns to scene")
	print("ARCHIVE_MOUSE_INPUT_OK" if failures.is_empty() else "ARCHIVE_MOUSE_INPUT_FAILED: " + str(failures))
	quit(0 if failures.is_empty() else 1)

func click(button: Button) -> void:
	var center := button.get_global_rect().get_center()
	var move := InputEventMouseMotion.new()
	move.position = center
	root.push_input(move,true)
	await process_frame
	var hovered := root.gui_get_hovered_control()
	print("CLICK ",button.text.replace("\n"," / ")," hit=",hovered.get_path() if hovered != null else "none")
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = center
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		root.push_input(event,true)
		await process_frame
	await process_frame

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
