extends SceneTree
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
	ui.open_files()
	await _capture("journal_empty")
	assert(not ui._photo_frame.visible)
	assert(not manager.call("get_evidence_data","mail_photo_01").get("is_viewed"))
	ui._select_evidence("mail_photo_01")
	assert(ui._photo_frame.visible)
	assert(ui._photo_texture.texture != null)
	assert(ui._photo_texture.material == null)
	assert(manager.call("is_catalog_kind_unlocked","desk"))
	assert(ui._result_label.text.contains("3"))
	await _capture("journal_photo")
	ui._select_evidence("mail_photo_01")
	assert(ui._result_label.text.contains("没有发现新的线索"))
	ui.close_files()
	assert((main.get("case_files_button") as Button).modulate.a == 1.0)
	ui.open_files()
	assert(not ui._photo_frame.visible)
	ui._select_journal_tab(1)
	await process_frame
	await process_frame
	assert(ui._evidence_list.get_child_count() > 0)
	(ui._evidence_list.get_child(0) as Button).pressed.emit()
	assert(not ui._photo_frame.visible)
	assert(ui._detail_description.size.x > 900)
	assert(not ui._detail_description.text.contains("警方交付资料"))
	await _capture("journal_document")
	ui._select_journal_tab(3)
	assert(ui._selected_evidence_id.is_empty())
	assert(not ui._photo_frame.visible)
	ui._select_journal_tab(0)
	ui._select_evidence("commission_note")
	root.size = Vector2i(1600,1000)
	await _capture("journal_document_tall")
	assert(ui._layout_root.get_global_rect().end.x <= ui.size.x + 1)
	ui.close_files()
	assert(not ui.visible)
	ui.open_files()
	assert(not ui._photo_frame.visible)
	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	ui._unhandled_key_input(escape)
	assert(not ui.visible)
	root.remove_child(main)
	main.free()
	manager.call("load_case","res://data/cases/gallery_case_002.json")
	root.size = Vector2i(1280,720)
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	main.get("first_case_flow_ui").call("_on_accept_pressed")
	ui = main.get("case_file_ui") as CaseFileUI
	ui.debug_open_evidence("standard_layout_photo")
	assert(ui._photo_frame.visible and ui._photo_texture.texture != null)
	await _capture("journal_gallery_photo")
	ui._select_evidence("restoration_case_brief")
	assert(not ui._photo_frame.visible)
	await _capture("journal_gallery_document")
	ui._display_evidence({"view_type":"photo","description":"无贴图资料的示意图"},[])
	assert(ui._photo_canvas.visible and not ui._photo_texture.visible)
	ui._archive_view.return_button.pressed.emit()
	assert(not ui.visible)
	print("CASE_JOURNAL_OK")
	quit()
func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/"+label+".png")
