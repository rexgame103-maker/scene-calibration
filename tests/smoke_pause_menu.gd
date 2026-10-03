extends SceneTree


const PREVIEW_PATH := "res://tests/pause_menu_preview.png"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var pause_menu := root.get_node_or_null("PauseMenu")
	_expect(is_instance_valid(pause_menu), "PauseMenu autoload should exist")
	if not is_instance_valid(pause_menu):
		_finish()
		return

	var studio_scene := load("res://scenes/studio/calibrator_studio.tscn") as PackedScene
	var studio := studio_scene.instantiate() as Node3D
	root.add_child(studio)
	current_scene = studio
	await create_timer(1.0).timeout

	var escape_event := InputEventKey.new()
	escape_event.keycode = KEY_ESCAPE
	escape_event.pressed = true
	Input.parse_input_event(escape_event)
	await process_frame
	var opened := bool(pause_menu.call("is_open"))
	_expect(opened, "Pause menu should open during gameplay")
	_expect(paused, "Opening the pause menu should pause the SceneTree")
	var overlay := pause_menu.get("overlay") as Control
	var panel := pause_menu.get("panel") as PanelContainer
	_expect(is_instance_valid(overlay) and overlay.visible, "Pause overlay should be visible")
	_expect(is_instance_valid(panel) and panel.size.x <= 720.0 and panel.size.y <= 460.0, "Pause UI should use the current centered paper-dialog size")
	_expect(_has_label_text(overlay, "错位现场"), "Pause window should show the game name")
	_expect(_has_button_text(overlay, "继续游戏"), "Pause window should contain Continue")
	_expect(_has_button_text(overlay, "回到开始界面"), "Pause window should contain Return to Start")
	_expect(_has_button_text(overlay, "退出游戏"), "Pause window should contain Exit Game")
	var pause_paper := overlay.find_child("PausePaper", true, false) as TextureRect
	_expect(is_instance_valid(pause_paper) and pause_paper.texture is AtlasTexture, "Pause window should use the current investigation paper atlas")
	if is_instance_valid(pause_paper) and pause_paper.texture is AtlasTexture:
		_expect((pause_paper.texture as AtlasTexture).atlas.resource_path == "res://assets/ui/studio_dossier/investigation_atlas.png", "Pause paper should not use the retired archive-theme assets")
	var pause_continue := overlay.find_child("ContinueButton", true, false) as Button
	_expect(is_instance_valid(pause_continue) and pause_continue.get_theme_stylebox("normal") is StyleBoxTexture, "Pause buttons should use the current paper-button texture")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image != null and not image.is_empty():
			_expect(image.save_png(PREVIEW_PATH) == OK, "Pause menu preview should be saved")

	var continue_button := pause_menu.get("continue_button") as Button
	continue_button.emit_signal("pressed")
	await process_frame
	_expect(not paused and not overlay.visible, "Continue should close the window and resume gameplay")

	_expect(bool(pause_menu.call("open_pause_menu")), "Pause menu should reopen after continuing")
	var return_button := pause_menu.get("return_button") as Button
	return_button.emit_signal("pressed")
	await create_timer(2.8).timeout
	_expect(not paused, "Returning to the title should leave the SceneTree unpaused")
	_expect(is_instance_valid(current_scene) and current_scene.scene_file_path == "res://scenes/start_menu/start_menu_office.tscn", "Return button should open the start scene")
	_expect(not bool(pause_menu.call("open_pause_menu")), "Pause menu should stay disabled on the start scene")

	_finish()


func _has_button_text(node: Node, expected: String) -> bool:
	if node is Button and (node as Button).text == expected:
		return true
	for child: Node in node.get_children():
		if _has_button_text(child, expected):
			return true
	return false


func _has_label_text(node: Node, expected: String) -> bool:
	if node is Label and (node as Label).text == expected:
		return true
	for child: Node in node.get_children():
		if _has_label_text(child, expected):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures.append(message)
	push_error("PAUSE MENU SMOKE: %s" % message)


func _finish() -> void:
	paused = false
	if failures.is_empty():
		print("PAUSE_MENU_SMOKE_OK")
		quit(0)
	else:
		print("PAUSE_MENU_SMOKE_FAILED: %s" % [failures])
		quit(1)
