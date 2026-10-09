extends SceneTree

var failures: Array[String] = []
var chinese := RegEx.new()
const TEXT_FIT := preload("res://tests/ui_text_fit_audit.gd")
var text_fit_issues: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	root.size = Vector2i(1280, 720)
	chinese.compile("[\\x{3400}-\\x{9fff}]")
	var language := root.get_node("GameLanguage")
	check(language.current_language == "en", "Fresh preferences default to English")
	check(TranslationServer.get_locale() == "en", "English overrides the operating system's language")
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/localization/en.json"))
	for source: String in catalog:
		check(String(TranslationServer.translate(source)) == catalog[source], "Catalog entry: " + source)
	for pair: Array in [
		["已选择「工作桌」", "Selected “Work Desk”"],
		["余额 ¥700　 一楼 1/4　 二楼 0/4", "Balance ¥700   Floor 1 1/4   Floor 2 0/4"],
		["✓  警局委托说明\n案情描述", "✓  Police Assignment Notes\nCase Description"],
		["校准工作桌 × 1", "Calibration Desk × 1"],
		["现场照片 · 来源：现场图像", "Scene Photo · Source: Scene Image"],
		["获得线索：办公桌存在、办公椅存在", "Clues Found: Office Desk Confirmed, Office Chair Confirmed"],
		["3 × 2 格", "3 × 2 tiles"],
		["邮箱   MAIL", "Mail   MAIL"]]:
		check(String(TranslationServer.translate(pair[0])) == pair[1], "Formatted/composite text: " + pair[0])
	var menu := (load("res://scenes/start_menu/start_menu_office.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	current_scene = menu
	menu.camera_motion_enabled = false
	await create_timer(0.6).timeout
	var ui := menu.get_node("StartMenuUI/UIRoot")
	ui.get_node("MenuLayout/MenuColumn/SettingsButton").pressed.emit()
	await process_frame
	var panel: Control = ui.get_node("Settings/Panel")
	var column := panel.get_node("Margin/Column")
	var selector: OptionButton = column.get_node("LanguageRow/LanguageSelector")
	check(selector.selected == 0, "Settings show English selected")
	check(selector.get_item_text(1) == "简体中文", "Language choices retain native names")
	check(panel.get_global_rect().end.y <= 720, "Settings fit the viewport")
	check(column.get_node("Close").get_global_rect().end.y <= panel.get_global_rect().end.y - 20,
		"Back button remains inside the settings panel")
	await capture("language_settings_en")
	var before := ConfigFile.new()
	before.set_value("audio", "volume", 0.65)
	before.set_value("test", "unrelated_option", "keep")
	before.save(language.OPTIONS_PATH)
	selector.select(1)
	selector.item_selected.emit(1)
	await process_frame
	check(language.current_language == "zh_CN", "Language option changes locale immediately")
	check(ui.get_node("MenuLayout/MenuColumn/StartButton").tr("开始游戏") == "开始游戏", "Chinese restored without rebuilding the menu")
	await capture("language_settings_zh")
	column.get_node("EffectsVolume").value = 0.61
	var saved := ConfigFile.new()
	saved.load(language.OPTIONS_PATH)
	check(saved.get_value("interface", "language", "") == "zh_CN", "Audio settings preserve saved language")
	check(saved.get_value("test", "unrelated_option", "") == "keep", "Options changes preserve unrelated settings")
	selector.select(0)
	selector.item_selected.emit(0)
	column.get_node("Close").pressed.emit()
	await process_frame
	check(language.current_language == "en", "Switching back restores English immediately")
	await capture("language_start_menu_en")
	menu.call("_open_reset_confirmation")
	await process_frame
	var note: Control = menu.get("_reset_overlay").get_node("Note")
	check(note.get_node("WarningLabel").get_global_rect().end.y <= note.get_node("CancelButton").get_global_rect().position.y - 4,
		"English reset warning stays above the action buttons")
	note.get_node("CancelButton").pressed.emit()
	menu.queue_free()
	await process_frame
	var manager := root.get_node("CaseManager")
	for case_path: String in ["res://data/cases/office_case_001.json", "res://data/cases/gallery_case_002.json"]:
		manager.load_case(case_path)
		var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
		root.add_child(main)
		current_scene = main
		await create_timer(0.4).timeout
		var flow_ui := main.get("first_case_flow_ui") as Control
		await process_frame
		audit_ui(flow_ui)
		check_paragraphs(flow_ui.briefing_panel)
		await capture("language_briefing_" + case_path.get_file().get_basename())
		flow_ui.call("_on_accept_pressed")
		audit_ui(main)
		await capture("language_scene_" + case_path.get_file().get_basename())
		var files := main.get("case_file_ui") as Control
		files.open_files()
		var available: Array = manager.get_available_evidence()
		check(not available.is_empty(), "Case contains initial documents")
		for item: Dictionary in available:
			files.debug_open_evidence(String(item.id))
			await process_frame
			audit_ui(files)
			var description := String(item.get("description", ""))
			check(chinese.search(String(TranslationServer.translate(description))) == null, "Case body translated: " + String(item.id))
		await capture("language_archive_" + case_path.get_file().get_basename())
		files.get("_category_selector").select(1)
		files.call("_on_category_selected", 1)
		check(files.get("_selected_category") == "案情描述", "Localized filtering retains source category identifiers")
		check(files.get("_evidence_list").get_child_count() > 0, "Text category retains its documents")
		files.close_files()
		flow_ui.show_settlement()
		await process_frame
		await process_frame
		audit_ui(flow_ui)
		check_paragraphs(flow_ui.settlement_panel)
		await capture("language_settlement_" + case_path.get_file().get_basename())
		main.queue_free()
		await process_frame
		await process_frame
	var studio := (load("res://scenes/studio/calibrator_studio.tscn") as PackedScene).instantiate()
	root.add_child(studio)
	current_scene = studio
	await create_timer(0.4).timeout
	audit_ui(studio)
	for card: CatalogItem in studio.get("catalog_cards"):
		for label: Label in [card.title_label, card.detail_label]:
			var font := label.get_theme_font("font")
			check(font.get_string_size(label.tr(label.text), HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x <= label.size.x + 1,
				"Furniture caption fits its authored column: " + label.text)
	await capture("language_studio_en")
	var desktop: Control = studio.get("computer_ui")
	desktop.open_desktop()
	for app: String in ["mail", "album", "shop", "cases", "minigame", "system"]:
		desktop.call("_show_app", app)
		await process_frame
		await process_frame
		audit_ui(desktop)
		if app in ["mail", "shop"]:
			await capture("language_terminal_" + app + "_en")
	desktop.close_desktop()
	studio.queue_free()
	await process_frame
	await process_frame
	language.set_language("zh_CN")
	check(String(TranslationServer.translate("已选择「工作桌」")) == "已选择「工作桌」", "Dynamic text restored to Chinese")
	root.get_node("GameAudio").stop_all()
	await create_timer(0.2).timeout
	var fit_report := FileAccess.open("res://tests/ui_text_fit_report.json", FileAccess.WRITE)
	fit_report.store_string(JSON.stringify(text_fit_issues, "\t"))
	check(text_fit_issues.is_empty(), "Visible text fits UI frames: " + str(text_fit_issues.size()) + " issues (tests/ui_text_fit_report.json)")
	print("LANGUAGE_SETTINGS_OK: default English, live UI, dynamic case/furniture text, saved preference" if failures.is_empty() else "LANGUAGE_SETTINGS_FAILED: " + str(failures))
	quit(0 if failures.is_empty() else 1)


func audit_ui(node: Node) -> void:
	if node is Label or node is Button or node is RichTextLabel:
		var source := String(node.text)
		check(chinese.search(node.tr(source)) == null, "Untranslated control: " + String(node.get_path()) + " = " + source)
	for child: Node in node.get_children():
		audit_ui(child)


func check_paragraphs(node: Node) -> void:
	if node is RichTextLabel and not node.scroll_active:
		check(node.get_content_height() <= node.size.y + 2, "Clipped paragraph: " + String(node.get_path()))
	for child: Node in node.get_children():
		check_paragraphs(child)


func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	TEXT_FIT.audit(root, text_fit_issues, name)
	root.get_texture().get_image().save_png("res://tests/" + name + ".png")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
