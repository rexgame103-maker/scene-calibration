extends SceneTree
var errors: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		errors.append(message)
		push_error(message)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1280,720)
	var cm := root.get_node("CaseManager")
	cm.call("load_case","res://data/cases/office_case_001.json")
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	(main.get("first_case_flow_ui") as FirstCaseFlowUI).call("_on_accept_pressed")
	await create_timer(1.0).timeout
	for key: String in ["case_panel","inventory_panel","button","status_bar","empty_archive"]:
		var img := (load("res://assets/ui/archive_theme/"+key+".png") as Texture2D).get_image()
		check(img.detect_alpha() != Image.ALPHA_NONE,"Real alpha channel: "+key)
		check(img.get_pixel(0,0).a == 0,"Transparent corner: "+key)
	var panel := main.get("catalog_panel") as PanelContainer
	check(panel.get_theme_stylebox("panel") is StyleBoxTexture,"Inventory uses archive paper artwork")
	var button := main.get("case_files_button") as Button
	check(button.text.contains("案件资料"),"Button caption remains real text")
	check(not button.has_theme_font_override("font"),"Default font retained")
	check(button.get_theme_color("font_color").get_luminance()<0.2,"Dark ink on paper button")
	await _capture("case_scene_ui_empty")
	button.pressed.emit()
	check(main.get("case_file_ui").visible,"Case files button still works")
	main.get("case_file_ui").close_files()
	cm.call("view_evidence","mail_photo_01")
	await process_frame
	await process_frame
	var cards := main.get("catalog_item_list") as VBoxContainer
	check(cards.get_child_count() >= 3,"Furniture unlocks populate inventory")
	var card := cards.get_child(0) as CatalogItem
	check(card != null and card.title_label != null,"Furniture captions are Label controls")
	check(card != null and card.visual_style == "case_dossier","Furniture cards use archive paper style")
	card.drag_started.emit(card.kind)
	check(not String(main.get("active_kind")).is_empty(),"Furniture dragging still begins")
	main.call("_cancel_placement",false)
	await _capture("case_scene_ui_inventory")
	# Translation smoke check without installing or changing project locale files.
	var translation := Translation.new()
	translation.locale = "en"
	translation.add_message(button.text,"Case files")
	translation.add_message("家具栏","Furniture")
	translation.add_message("查看资料获得线索 · 解锁后拖出摆放","Read evidence, then drag unlocked furniture into the room")
	TranslationServer.add_translation(translation)
	TranslationServer.set_locale("en")
	await process_frame
	check(button.tr(button.text)=="Case files","UI caption can be translated separately from art")
	await _capture("case_scene_ui_translation")
	TranslationServer.remove_translation(translation)
	TranslationServer.set_locale("zh_CN")
	print("CASE_SCENE_UI_OK" if errors.is_empty() else str(errors))
	quit(0 if errors.is_empty() else 1)
func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/"+label+".png")
