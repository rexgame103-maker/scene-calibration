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
	var face: TextureRect = ui.get_node("Portrait")
	assert(face.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	assert(face.size==Vector2(580,770))
	assert(ui.has_node("MenuSlash"))
	var start: Button = ui.get_node("MenuLayout/MenuColumn/StartButton")
	var settings: Button = ui.get_node("MenuLayout/MenuColumn/SettingsButton")
	assert(start.get_theme_stylebox("focus") is StyleBoxEmpty)
	await move_pointer(Vector2(1200,680))
	assert(not start.is_hovered() and not start.has_focus())
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/menu_visual_fixed.png")
	await move_pointer(start.get_global_transform_with_canvas()*(start.size*0.5))
	assert(start.is_hovered())
	await move_pointer(settings.get_global_transform_with_canvas()*(settings.size*0.5))
	assert(settings.is_hovered() and not start.is_hovered())
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/menu_hover_settings.png")
	print("MENU_HOVER_OK: native pointer hover transfer, default black, aspect-correct portrait, slash")
	quit()
