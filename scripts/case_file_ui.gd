class_name CaseFileUI
extends Control

const ARCHIVE_VIEW := preload("res://scripts/case_archive_view.gd")


signal closed
signal evidence_opened(evidence_id: String)


class EvidencePhotoCanvas:
	extends Control

	var evidence_data: Dictionary = {}

	func set_evidence(data: Dictionary) -> void:
		evidence_data = data.duplicate(true)
		queue_redraw()

	func _draw() -> void:
		var view_size := size
		draw_rect(Rect2(Vector2.ZERO, view_size), Color("171923"), true)
		var inset := Rect2(Vector2(12, 12), view_size - Vector2(24, 24))
		draw_rect(inset, Color("776b58"), true)
		var horizon_y := inset.position.y + inset.size.y * 0.46
		draw_colored_polygon(PackedVector2Array([
			inset.position,
			Vector2(inset.end.x, inset.position.y),
			Vector2(inset.end.x, horizon_y),
			Vector2(inset.position.x, horizon_y)
		]), Color("514b47"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(inset.position.x, horizon_y),
			Vector2(inset.end.x, horizon_y),
			inset.end,
			Vector2(inset.position.x, inset.end.y)
		]), Color("665b4b"))

		for line_index: int in range(1, 6):
			var y := lerpf(horizon_y, inset.end.y, float(line_index) / 6.0)
			draw_line(Vector2(inset.position.x, y), Vector2(inset.end.x, y), Color("88796470"), 1.0)
		for line_index: int in range(1, 7):
			var x := lerpf(inset.position.x, inset.end.x, float(line_index) / 7.0)
			draw_line(Vector2(view_size.x * 0.5, horizon_y), Vector2(x, inset.end.y), Color("88796455"), 1.0)

		var subjects: Array = evidence_data.get("photo_subjects", [])
		if subjects.has("artwork_closeup"):
			var artwork := Rect2(view_size.x * 0.18, view_size.y * 0.23, view_size.x * 0.64, view_size.y * 0.54)
			draw_rect(artwork, Color("566e68"), true)
			draw_rect(artwork.grow(7), Color("342d29"), false, 7.0)
			if subjects.has("scale_ruler"):
				var ruler := Rect2(artwork.position + Vector2(18, artwork.size.y - 34), Vector2(artwork.size.x * 0.56, 16))
				draw_rect(ruler, Color("d8d1b7"), true)
				for tick: int in range(12):
					var tick_x := ruler.position.x + 6.0 + tick * ruler.size.x / 12.0
					draw_line(Vector2(tick_x, ruler.position.y), Vector2(tick_x, ruler.position.y + 7), Color("5d554c"), 1.0)
			if subjects.has("hard_shadow"):
				draw_line(artwork.position + Vector2(artwork.size.x * 0.62, artwork.size.y * 0.35), artwork.position + Vector2(artwork.size.x * 0.26, artwork.size.y * 0.72), Color("1b1919b8"), 14.0)
			if subjects.has("warm_highlight"):
				draw_circle(artwork.position + Vector2(artwork.size.x * 0.72, artwork.size.y * 0.34), 24, Color("ffc477cc"))
			if subjects.has("secondary_reflection"):
				draw_circle(artwork.position + Vector2(artwork.size.x * 0.28, artwork.size.y * 0.50), 14, Color("dce9df88"))
			if subjects.has("rotated_frame_shadow"):
				draw_line(artwork.position + Vector2(12, 8), artwork.position + Vector2(artwork.size.x * 0.48, artwork.size.y - 6), Color("171719aa"), 12.0)
			if subjects.has("camera_axis"):
				draw_dashed_line(Vector2(view_size.x * 0.50, inset.end.y - 5), Vector2(view_size.x * 0.50, artwork.end.y), Color("a9d8e5"), 2.0, 7.0)
		elif subjects.has("restoration_table"):
			var table_rect := Rect2(view_size.x * 0.28, view_size.y * 0.49, view_size.x * 0.38, view_size.y * 0.11)
			draw_rect(table_rect, Color("b9a47e"), true)
			draw_rect(Rect2(table_rect.position + Vector2(22, 8), table_rect.size - Vector2(44, 16)), Color("657872"), true)
			for x: float in [table_rect.position.x + 12, table_rect.end.x - 12]:
				draw_line(Vector2(x, table_rect.end.y), Vector2(x, view_size.y * 0.78), Color("46545b"), 7.0)
			# Calibrated light, camera and the two parked pieces of inspection equipment.
			draw_rect(Rect2(view_size.x * 0.31, view_size.y * 0.26, view_size.x * 0.32, 22), Color("bfe7ea"), true)
			draw_line(Vector2(view_size.x * 0.25, view_size.y * 0.72), Vector2(view_size.x * 0.25, view_size.y * 0.40), Color("46545b"), 5.0)
			draw_rect(Rect2(view_size.x * 0.215, view_size.y * 0.36, 34, 24), Color("303941"), true)
			draw_line(Vector2(view_size.x * 0.82, view_size.y * 0.72), Vector2(view_size.x * 0.82, view_size.y * 0.42), Color("6b5650"), 5.0)
			draw_rect(Rect2(view_size.x * 0.77, view_size.y * 0.37, 42, 28), Color("d28d55"), true)
			draw_rect(Rect2(view_size.x * 0.69, view_size.y * 0.37, 18, 78), Color("c6ccca"), true)
		if subjects.has("desk"):
			var desk_rect := Rect2(view_size.x * 0.26, view_size.y * 0.49, view_size.x * 0.45, view_size.y * 0.12)
			draw_rect(desk_rect, Color("9c7655"), true)
			draw_rect(Rect2(desk_rect.position + Vector2(8, desk_rect.size.y), Vector2(10, view_size.y * 0.23)), Color("49382f"), true)
			draw_rect(Rect2(Vector2(desk_rect.end.x - 18, desk_rect.end.y), Vector2(10, view_size.y * 0.23)), Color("49382f"), true)
			draw_rect(Rect2(view_size.x * 0.49, view_size.y * 0.36, view_size.x * 0.14, view_size.y * 0.13), Color("292d36"), true)
			draw_rect(Rect2(view_size.x * 0.505, view_size.y * 0.375, view_size.x * 0.11, view_size.y * 0.09), Color("718088"), true)
		if subjects.has("office_chair"):
			var chair_center := Vector2(view_size.x * 0.48, view_size.y * 0.72)
			draw_rect(Rect2(chair_center - Vector2(34, 14), Vector2(68, 28)), Color("554552"), true)
			draw_rect(Rect2(chair_center - Vector2(29, 66), Vector2(58, 47)), Color("684d5b"), true)
			draw_line(chair_center + Vector2(-22, 14), chair_center + Vector2(-29, 55), Color("29242a"), 6.0)
			draw_line(chair_center + Vector2(22, 14), chair_center + Vector2(29, 55), Color("29242a"), 6.0)

		draw_rect(inset, Color("d7c8aa"), false, 2.0)
		var font := ThemeDB.fallback_font
		var caption := String(evidence_data.get("caption", "警方现场照片"))
		draw_string(font, Vector2(24, view_size.y - 20), caption, HORIZONTAL_ALIGNMENT_LEFT, view_size.x - 48, 13, Color("eee6d6"))
		draw_string(font, Vector2(view_size.x - 116, 34), "POLICE / 01", HORIZONTAL_ALIGNMENT_LEFT, 96, 11, Color("ead8b0"))


var _manager: Node
var _evidence_list: VBoxContainer
var _category_selector: OptionButton
var _detail_category: Label
var _detail_title: Label
var _detail_description: RichTextLabel
var _photo_frame: PanelContainer
var _photo_canvas: EvidencePhotoCanvas
var _photo_texture: TextureRect
var _result_label: Label
var _selected_category := "全部"


func setup(case_manager: Node) -> void:
	_manager = case_manager
	if is_node_ready():
		_refresh_evidence_list()


func _ready() -> void:
	name = "CaseFileUI"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_interface()
	_refresh_evidence_list()


func open_files() -> void:
	# z_index controls drawing, not GUI hit testing. Pinned references are added
	# later as siblings; put this opaque modal last so it receives clicks first.
	# Making the scene HUD transparent leaves those controls intercepting input.
	move_to_front()
	visible = true
	_selected_category = "全部"
	if is_instance_valid(_category_selector):
		_category_selector.select(0)
	_clear_detail()
	_refresh_evidence_list()


func debug_open_evidence(evidence_id: String) -> bool:
	if evidence_id.is_empty() or not is_instance_valid(_manager):
		return false
	open_files()
	_select_evidence(evidence_id)
	return true


func close_files() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close_files()
		get_viewport().set_input_as_handled()


const PAPER_INK := Color("302b23")
var _layout_root: Control
var _archive_view: Control
var _selected_evidence_id := ""

func _build_interface() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "ArchiveBackdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color("15130f")
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	_archive_view = ARCHIVE_VIEW.new()
	_layout_root = _archive_view
	add_child(_archive_view)
	var summary := _manager.call("get_case_summary") as Dictionary if is_instance_valid(_manager) else {}
	_archive_view.build(summary)
	_category_selector = _archive_view.category
	_evidence_list = _archive_view.evidence_list
	_detail_category = _archive_view.detail_category
	_detail_title = _archive_view.detail_title
	_detail_description = _archive_view.description
	_result_label = _archive_view.result
	_photo_frame = _archive_view.photo_frame
	_photo_texture = _archive_view.photo_texture
	_photo_canvas = EvidencePhotoCanvas.new()
	_photo_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_photo_frame.add_child(_photo_canvas)
	_category_selector.item_selected.connect(_on_category_selected)
	_archive_view.return_button.pressed.connect(close_files)
	resized.connect(_layout_journal)
	_layout_journal()

func _select_journal_tab(index: int) -> void:
	_category_selector.select(index)
	_on_category_selected(index)

func _layout_journal() -> void:
	if not is_instance_valid(_layout_root): return
	var factor := minf(size.x/1600.0,size.y/900.0)
	_layout_root.scale = Vector2.ONE*factor
	_layout_root.position = (size-Vector2(1600,900)*factor)*0.5

func _skin_menu(button: Button) -> void:
	ARCHIVE_VIEW.skin_button(button)
	button.add_theme_font_size_override("font_size",18)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _refresh_evidence_list() -> void:
	if not is_instance_valid(_evidence_list) or not is_instance_valid(_manager):
		return
	for child: Node in _evidence_list.get_children():
		_evidence_list.remove_child(child)
		child.queue_free()
	var shown := 0
	var available: Array = _manager.call("get_available_evidence")
	for evidence_value: Variant in available:
		if typeof(evidence_value) != TYPE_DICTIONARY:
			continue
		var item := evidence_value as Dictionary
		var category := String(item.get("category", "其他"))
		if _selected_category != "全部" and category != _selected_category:
			continue
		var viewed_prefix := "✓  " if bool(item.get("is_viewed", false)) else ""
		var source_hint := ""
		var profile := get_node_or_null("/root/PlayerProfile")
		if is_instance_valid(profile) and bool(profile.call("has_skill", "evidence_source_hint")):
			source_hint = " · 来源：%s" % ("现场图像" if String(item.get("view_type", "text")) == "photo" else "文字记录")
		var item_button := _button(
			"%s%s\n%s%s" % [viewed_prefix, String(item.get("title", "未命名资料")), category, source_hint],
			Color("3a3150")
		)
		item_button.custom_minimum_size = Vector2(0, 86)
		item_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_button.tooltip_text = String(item.get("title", "")) + source_hint
		ARCHIVE_VIEW.skin_button(item_button, String(item.get("id", "")) == _selected_evidence_id)
		item_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		item_button.pressed.connect(_select_evidence.bind(String(item.get("id", ""))))
		_evidence_list.add_child(item_button)
		shown += 1
	_archive_view.count.text = "%d 份资料" % shown
	if shown == 0:
		var empty_label := _label("当前分类暂无资料", 13, Color("b7a78b"))
		empty_label.custom_minimum_size = Vector2(0, 80)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_evidence_list.add_child(empty_label)


func _on_category_selected(index: int) -> void:
	_selected_category = "全部" if index == 0 else _category_selector.get_item_text(index)
	_clear_detail()
	_refresh_evidence_list()


func _select_evidence(evidence_id: String) -> void:
	if evidence_id.is_empty() or not is_instance_valid(_manager):
		return
	_selected_evidence_id = evidence_id
	var discovered_ids: Array = _manager.call("view_evidence", evidence_id)
	var item: Dictionary = _manager.call("get_evidence_data", evidence_id)
	_display_evidence(item, discovered_ids)
	_refresh_evidence_list()
	evidence_opened.emit(evidence_id)


func _display_evidence(item: Dictionary, discovered_ids: Array) -> void:
	_result_label.tooltip_text = ""
	_detail_category.text = String(item.get("category", "案件资料"))
	_detail_title.text = String(item.get("title", "未命名资料"))
	_detail_title.tooltip_text = _detail_title.text
	_detail_description.text = String(item.get("description", ""))
	var is_photo := String(item.get("view_type", "text")) == "photo"
	_archive_view.set_photo_mode(is_photo)
	_archive_view.caption.text = String(item.get("caption", ""))
	if not is_photo:
		_detail_description.text = _detail_description.text.replace("。", "。\n\n").strip_edges()
	if is_photo:
		var image_path := String(item.get("image_path", ""))
		var texture: Texture2D
		if not image_path.is_empty() and ResourceLoader.exists(image_path):
			texture = load(image_path) as Texture2D
		_photo_texture.texture = texture
		_photo_texture.visible = texture != null
		_photo_canvas.visible = texture == null
		_photo_canvas.set_evidence(item)

	if discovered_ids.is_empty():
		_result_label.text = "该资料已查看，没有发现新的线索。"
		_result_label.add_theme_color_override("font_color", Color("776a56"))
		return
	var clue_titles: Array[String] = []
	for clue_id_value: Variant in discovered_ids:
		var clue_data: Dictionary = _manager.call("get_clue_data", String(clue_id_value))
		clue_titles.append(String(clue_data.get("title", clue_id_value)))
	_result_label.text = tr("已获得 %d 条线索，家具栏已更新。") % discovered_ids.size()
	_result_label.tooltip_text = tr("获得线索：%s") % "、".join(clue_titles)
	_result_label.add_theme_color_override("font_color", Color("344c31"))


func _clear_detail() -> void:
	_selected_evidence_id = ""
	_archive_view.set_photo_mode(false)
	_result_label.tooltip_text = ""
	_detail_category.text = "案件资料"
	_detail_title.text = "请选择资料"
	_detail_title.tooltip_text = ""
	_detail_description.text = "从左侧目录选择一份资料进行查看。"
	_result_label.text = ""


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text_value: String, background: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color("30251f"))
	_skin_menu(button)
	
	
	return button


func _style(background: Color, radius: int, border: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style
