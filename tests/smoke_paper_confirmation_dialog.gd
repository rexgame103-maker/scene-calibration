extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var menu := (load("res://scenes/start_menu/start_menu_office.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	menu.call("_open_reset_confirmation")
	var start_dialog := menu.get("_reset_overlay") as Control
	var start_note := start_dialog.get_node("Note") as TextureRect
	var start_cancel := start_note.get_node("CancelButton") as Button
	var start_confirm := start_note.get_node("ConfirmButton") as Button
	assert(start_dialog.visible)
	assert(start_note.texture is AtlasTexture)
	assert((start_note.texture as AtlasTexture).atlas.resource_path == "res://assets/ui/studio_dossier/investigation_atlas.png")
	assert((start_note.get_node("TitleLabel") as Label).text == "开始新游戏？")
	assert(start_confirm.text.contains("重置进度并开始"))
	assert((start_cancel.get_theme_stylebox("normal") as StyleBoxTexture).texture is AtlasTexture)
	assert((start_confirm.get_theme_stylebox("normal") as StyleBoxTexture).texture is AtlasTexture)
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/paper_confirmation_dialog_preview.png")
	start_cancel.pressed.emit()
	assert(not start_dialog.visible)
	root.remove_child(menu)
	menu.free()
	await process_frame

	var computer := StudioComputerUI.new()
	computer.setup(root.get_node("PlayerProfile"))
	root.add_child(computer)
	await process_frame
	computer.open_desktop()
	computer.call("_open_reset_confirmation")
	var computer_dialog := computer.get("_reset_overlay") as Control
	assert(computer_dialog.visible)
	assert((computer_dialog.get_node("Note/TitleLabel") as Label).text == "重置全部游戏进度？")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/paper_confirmation_computer_preview.png")
	(computer_dialog.get_node("Note/CancelButton") as Button).pressed.emit()
	assert(not computer_dialog.visible)
	print("PAPER_CONFIRMATION_DIALOG_OK")
	quit(0)
