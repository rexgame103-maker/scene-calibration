extends SceneTree
func _initialize() -> void: call_deferred("run")
func move_pointer(at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position=at
	event.global_position=at
	root.push_input(event,true)
	await process_frame
	await process_frame
func run() -> void:
	root.size=Vector2i(1280,720)
	var menu := (load("res://scenes/start_menu/start_menu_office.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	current_scene=menu
	menu.camera_motion_enabled=false
	await create_timer(1.1).timeout
	var ui := menu.get_node("StartMenuUI/UIRoot")
	assert(not ui.has_node("Portrait") and not ui.has_node("MenuSlash"))
	var start: Button = ui.get_node("MenuLayout/MenuColumn/StartButton")
	var settings: Button = ui.get_node("MenuLayout/MenuColumn/SettingsButton")
	assert(start.rotation==0 and start.get_global_rect().end.x<640)
	assert(start.get_theme_stylebox("focus").border_width_left==3)
	await move_pointer(Vector2(1200,680))
	assert(not start.is_hovered() and not start.has_focus())
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/start_menu_window_preview.png")
	await move_pointer(start.get_global_transform_with_canvas()*(start.size*0.5))
	assert(start.is_hovered())
	await move_pointer(settings.get_global_transform_with_canvas()*(settings.size*0.5))
	assert(settings.is_hovered() and not start.is_hovered())
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/start_menu_window_hover.png")
	var press := InputEventMouseButton.new()
	press.button_index=MOUSE_BUTTON_LEFT
	press.position=settings.get_global_transform_with_canvas()*(settings.size*0.5)
	press.pressed=true
	root.push_input(press,true)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed=false
	root.push_input(release,true)
	await process_frame
	assert(ui.get_node("Settings").visible)
	print("MENU_HOVER_OK: left menu, native pointer hover transfer, real settings click")
	root.get_node("GameAudio").call("stop_all")
	menu.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.15).timeout
	quit()
