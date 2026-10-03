extends SceneTree
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1280,800)
	var cm := root.get_node("CaseManager")
	cm.call("load_case","res://data/cases/office_case_001.json")
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	(main.get("first_case_flow_ui") as FirstCaseFlowUI).call("_on_accept_pressed")
	cm.call("view_evidence","mail_photo_01")
	var rm := root.get_node("ReconstructionManager")
	for id: String in ["zone_desk_original","zone_chair_at_desk","zone_computer_on_desk"]:
		main.call("_debug_place_furniture_in_zone",rm.get("zones")[id])
	var desk := main.call("_debug_find_placed_furniture_by_id","desk") as Node3D
	main.call("_select_item", main.call("_find_entry_by_node",desk))
	main.call("_focus_selected_furniture")
	await create_timer(0.8).timeout
	var point := desk.get_node("DeskSideWearClue") as SceneCluePoint
	point.set_inspection_context(desk)
	# The side scratch must be visible before testing its popup animation.
	main.set("focus_target_yaw", 45.0)
	main.set("focus_target_pitch", -22.0)
	main.call("_update_focus_camera", 10.0)
	check(point.investigate(),"Point opens animated inspection")
	var popup := main.get("scene_clue_popup") as SceneCluePopup
	popup.set_process(false)
	check(not cm.call("has_clue",point.clue_id),"Opening does not collect clue")
	check(not popup.collect_button.visible,"Collect hidden before text")
	check(not point.investigate(),"Repeated opening is ignored")
	popup.elapsed = 0.7
	popup.call("_apply_intro")
	check(popup.picture.modulate.a > 0 and popup.line_progress == 0,"Image enters before line")
	popup.elapsed = 1.3
	popup.call("_apply_intro")
	check(popup.line_progress > 0 and popup.line_progress < 1 and popup.description_label.visible_ratio == 0,"Line draws before text")
	popup.elapsed = 1.8
	popup.call("_apply_intro")
	check(popup.line_progress == 1 and popup.description_label.visible_ratio > 0 and not popup.collect_button.visible,"Typing follows completed line")
	var blank_click := InputEventMouseButton.new()
	await process_frame
	blank_click.button_index = MOUSE_BUTTON_LEFT
	blank_click.pressed = true
	blank_click.position = Vector2(20,20)
	root.push_input(blank_click, true)
	check(popup.speed > 1,"Blank click accelerates")
	popup.call("_process",10.0)
	check(popup.collect_button.visible,"Button appears only after all text")
	check(not cm.call("has_clue",point.clue_id),"Acceleration never auto-collects")
	if DisplayServer.get_name() != "headless":
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/clue_animation_preview.png")
		check(popup.photo.texture != null,"Live detail image available")
	var collect_click := InputEventMouseButton.new()
	collect_click.button_index = MOUSE_BUTTON_LEFT
	collect_click.pressed = true
	collect_click.position = popup.collect_button.get_global_rect().get_center()
	root.push_input(collect_click,true)
	check(cm.call("has_clue",point.clue_id),"Collect awards clue")
	check(cm.call("is_furniture_unlocked","small_cabinet"),"Collect unlocks next item")
	popup.call("_process",0.2)
	check(popup.picture.position.x < popup.picture_home.x and popup.copy.position.y > popup.copy_home.y,"Image exits left; line and text exit down")
	popup.call("_process",0.3)
	check(not popup.visible,"Exit restores scene interaction")
	print("CLUE_ANIMATION_OK" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
