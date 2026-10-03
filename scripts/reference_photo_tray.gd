class_name ReferencePhotoTray
extends Control


class PhotoSketch:
	extends Control
	var data: Dictionary = {}

	func setup(value: Dictionary) -> void:
		data = value.duplicate(true)
		queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color("d8cfba"), true)
		draw_rect(Rect2(8, 8, size.x - 16, size.y - 16), Color("575c61"), true)
		var subjects: Array = data.get("photo_subjects", [])
		var floor_y := size.y * 0.68
		draw_line(Vector2(12, floor_y), Vector2(size.x - 12, floor_y), Color("9a8c78"), 2.0)
		if subjects.has("artwork_closeup"):
			var artwork := Rect2(size.x * 0.17, size.y * 0.24, size.x * 0.66, size.y * 0.52)
			draw_rect(artwork, Color("596f68"), true)
			draw_rect(artwork.grow(5), Color("332e2b"), false, 5.0)
			if subjects.has("scale_ruler"):
				draw_rect(Rect2(artwork.position + Vector2(12, artwork.size.y - 25), Vector2(artwork.size.x * 0.58, 11)), Color("ddd4b9"), true)
			if subjects.has("hard_shadow"):
				draw_line(artwork.position + Vector2(artwork.size.x * 0.68, artwork.size.y * 0.30), artwork.position + Vector2(artwork.size.x * 0.24, artwork.size.y * 0.74), Color("1b1919b8"), 9.0)
			if subjects.has("warm_highlight"):
				draw_circle(artwork.position + Vector2(artwork.size.x * 0.73, artwork.size.y * 0.34), 15, Color("ffc477cc"))
			if subjects.has("secondary_reflection"):
				draw_circle(artwork.position + Vector2(artwork.size.x * 0.27, artwork.size.y * 0.49), 9, Color("dce9df88"))
			if subjects.has("rotated_frame_shadow"):
				draw_line(artwork.position + Vector2(8, 5), artwork.position + Vector2(artwork.size.x * 0.50, artwork.size.y - 4), Color("171719aa"), 8.0)
			if subjects.has("camera_axis"):
				draw_dashed_line(Vector2(size.x * 0.50, size.y - 18), Vector2(size.x * 0.50, artwork.end.y), Color("a9d8e5"), 2.0, 6.0)
		elif subjects.has("restoration_table"):
			var table_rect := Rect2(size.x * 0.28, size.y * 0.49, size.x * 0.38, size.y * 0.10)
			draw_rect(table_rect, Color("b9a47e"), true)
			draw_rect(Rect2(table_rect.position + Vector2(13, 4), table_rect.size - Vector2(26, 8)), Color("62766e"), true)
			for leg_x: float in [table_rect.position.x + 8, table_rect.end.x - 8]:
				draw_line(Vector2(leg_x, table_rect.end.y), Vector2(leg_x, floor_y), Color("46545b"), 4.0)
			# Broad calibrated light behind the table.
			draw_rect(Rect2(size.x * 0.31, size.y * 0.30, size.x * 0.32, 13), Color("c7f2f4"), true)
			draw_line(Vector2(size.x * 0.33, size.y * 0.43), Vector2(size.x * 0.33, floor_y), Color("596b74"), 3.0)
			# Camera and stool face the work surface from the foreground.
			draw_rect(Rect2(size.x * 0.20, size.y * 0.47, 26, 17), Color("303842"), true)
			draw_line(Vector2(size.x * 0.25, size.y * 0.56), Vector2(size.x * 0.19, floor_y), Color("3f4a53"), 3.0)
			draw_line(Vector2(size.x * 0.25, size.y * 0.56), Vector2(size.x * 0.31, floor_y), Color("3f4a53"), 3.0)
			draw_circle(Vector2(size.x * 0.48, size.y * 0.69), 9, Color("668297"))
			# Inspection lamp and reflector remain parked on the right wall marks.
			draw_line(Vector2(size.x * 0.82, floor_y), Vector2(size.x * 0.82, size.y * 0.43), Color("4e5358"), 3.0)
			draw_rect(Rect2(size.x * 0.77, size.y * 0.37, 31, 17), Color("d28d55"), true)
			draw_rect(Rect2(size.x * 0.69, size.y * 0.38, 15, 55), Color("c6ccca"), true)
		else:
			var slot := 0
			var spacing := minf(60.0, (size.x - 48.0) / maxf(1.0, float(subjects.size())))
			for subject_value: Variant in subjects:
				var subject := String(subject_value)
				var x := 18.0 + slot * spacing
				match subject:
					"desk":
						draw_rect(Rect2(x, floor_y - 32, 58, 9), Color("a87955"), true)
						draw_line(Vector2(x + 8, floor_y - 23), Vector2(x + 8, floor_y), Color("4e4037"), 5)
						draw_line(Vector2(x + 50, floor_y - 23), Vector2(x + 50, floor_y), Color("4e4037"), 5)
					"office_chair":
						draw_rect(Rect2(x + 8, floor_y - 35, 28, 25), Color("68758b"), true)
						draw_circle(Vector2(x + 22, floor_y - 4), 6, Color("343b45"))
					"computer":
						draw_rect(Rect2(x + 8, floor_y - 38, 38, 25), Color("28333d"), true)
						draw_rect(Rect2(x + 12, floor_y - 34, 30, 17), Color("75a5b4"), true)
					"shelf":
						draw_rect(Rect2(x + 5, floor_y - 70, 44, 70), Color("75685a"), true)
						for y: float in [floor_y - 52, floor_y - 34, floor_y - 16]: draw_line(Vector2(x + 8, y), Vector2(x + 46, y), Color("b6a98e"), 3)
					"water_dispenser":
						draw_rect(Rect2(x + 12, floor_y - 58, 28, 58), Color("c6d4d8"), true)
						draw_circle(Vector2(x + 26, floor_y - 42), 8, Color("7eb6ca"))
					"files":
						for file_index: int in range(3): draw_rect(Rect2(x + 5 + file_index * 14, floor_y - 40, 10, 40), [Color("a75155"),Color("707781"),Color("c7ad7c")][file_index], true)
					"sofa":
						draw_rect(Rect2(x, floor_y - 34, 58, 34), Color("7d668c"), true)
					"plant":
						draw_rect(Rect2(x + 18, floor_y - 20, 22, 20), Color("765947"), true)
						draw_circle(Vector2(x + 28, floor_y - 38), 18, Color("6d9267"))
					"lamp":
						draw_line(Vector2(x + 28, floor_y), Vector2(x + 28, floor_y - 55), Color("4c4c49"), 4)
						draw_colored_polygon(PackedVector2Array([Vector2(x+12,floor_y-54),Vector2(x+44,floor_y-54),Vector2(x+36,floor_y-72),Vector2(x+20,floor_y-72)]),Color("d0af5d"))
					"restoration_table":
						draw_rect(Rect2(x, floor_y - 28, spacing * 0.95, 8), Color("b9a47e"), true)
						draw_rect(Rect2(x + 7, floor_y - 26, spacing * 0.68, 5), Color("62766e"), true)
					"restoration_stool":
						draw_circle(Vector2(x + spacing * 0.42, floor_y - 19), 10, Color("668297"))
						draw_line(Vector2(x + spacing * 0.42, floor_y - 9), Vector2(x + spacing * 0.42, floor_y), Color("46545e"), 4)
					"cold_light_panel":
						draw_rect(Rect2(x, floor_y - 58, spacing * 0.90, 12), Color("c7f2f4"), true)
						draw_line(Vector2(x + 5, floor_y - 46), Vector2(x + 5, floor_y), Color("596b74"), 3)
					"camera_tripod":
						draw_rect(Rect2(x + 8, floor_y - 55, spacing * 0.54, 17), Color("303842"), true)
						draw_line(Vector2(x + spacing * 0.38, floor_y - 38), Vector2(x + 4, floor_y), Color("3f4a53"), 3)
						draw_line(Vector2(x + spacing * 0.38, floor_y - 38), Vector2(x + spacing * 0.76, floor_y), Color("3f4a53"), 3)
					"halogen_parked":
						draw_line(Vector2(x + spacing * 0.42, floor_y), Vector2(x + spacing * 0.42, floor_y - 44), Color("4e5358"), 3)
						draw_rect(Rect2(x + 5, floor_y - 55, spacing * 0.72, 15), Color("d28d55"), true)
					"reflector_parked":
						draw_rect(Rect2(x + 5, floor_y - 58, spacing * 0.72, 50), Color("c6ccca"), true)
				slot += 1
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(14, 25), String(data.get("caption", "参考照片")), HORIZONTAL_ALIGNMENT_LEFT, size.x - 28, 11, Color("f2eadc"))


class FloatingPhoto:
	extends PanelContainer
	var dragging := false
	var drag_offset := Vector2.ZERO

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			if dragging:
				drag_offset = event.position
			accept_event()
		elif event is InputEventMouseMotion and dragging:
			position += event.relative
			var viewport_size := get_viewport_rect().size
			position.x = clampf(position.x, 0.0, viewport_size.x - size.x)
			position.y = clampf(position.y, 0.0, viewport_size.y - size.y)
			accept_event()


var _case_manager: Node
var _button_row: HBoxContainer
var _references: Dictionary = {}
var _floating_cards: Dictionary = {}


func setup(case_manager: Node) -> void:
	_case_manager = case_manager


func _ready() -> void:
	name = "ReferencePhotoTray"
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	offset_left = 24
	offset_right = 504
	offset_top = -126
	offset_bottom = -78
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_button_row = HBoxContainer.new()
	_button_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_button_row.add_theme_constant_override("separation", 8)
	_button_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(_button_row)


func add_reference(evidence_id: String) -> void:
	if not is_instance_valid(_case_manager) or _references.has(evidence_id):
		return
	var evidence := _case_manager.call("get_evidence_data", evidence_id) as Dictionary
	if not bool(evidence.get("pin_as_reference", false)):
		return
	_references[evidence_id] = evidence
	var button := Button.new()
	button.text = "拖出参考 · %s" % String(evidence.get("title", "照片"))
	button.custom_minimum_size = Vector2(150, 42)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 12)
	preload("res://scripts/investigation_ui_theme.gd").button(button, "wide")
	button.pressed.connect(func() -> void: _toggle_photo(evidence_id))
	_button_row.add_child(button)


func _toggle_photo(evidence_id: String) -> void:
	if _floating_cards.has(evidence_id) and is_instance_valid(_floating_cards[evidence_id] as Control):
		(_floating_cards[evidence_id] as Control).queue_free()
		_floating_cards.erase(evidence_id)
		return
	var limit := 1
	var profile := get_node_or_null("/root/PlayerProfile")
	if is_instance_valid(profile) and bool(profile.call("has_skill", "extra_photo_slots")):
		limit = 3
	while _floating_cards.size() >= limit:
		var oldest_id := String(_floating_cards.keys()[0])
		var oldest := _floating_cards[oldest_id] as Control
		if is_instance_valid(oldest): oldest.queue_free()
		_floating_cards.erase(oldest_id)
	var card := FloatingPhoto.new()
	card.name = "PinnedPhoto_%s" % evidence_id
	card.size = Vector2(268, 204)
	# Pinned references stay above the ordinary HUD, but below every modal
	# interface (rotation, case files, scene clues and reset confirmation).
	card.z_index = 12
	var viewport_size := get_viewport_rect().size
	card.position = Vector2(
		24 + _floating_cards.size() * 34,
		maxf(16.0, viewport_size.y - 344.0 - _floating_cards.size() * 28.0)
	)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := preload("res://scripts/investigation_ui_theme.gd").paper("wide")
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, 12)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)
	get_parent().add_child(card)
	var evidence := _references[evidence_id] as Dictionary
	var image_path := String(evidence.get("image_path", ""))
	var texture: Texture2D
	if not image_path.is_empty() and ResourceLoader.exists(image_path):
		texture = load(image_path) as Texture2D
	if is_instance_valid(texture):
		var image_view := TextureRect.new()
		image_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		image_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		image_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image_view.texture = texture
		card.add_child(image_view)
	else:
		var sketch := PhotoSketch.new()
		sketch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sketch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		sketch.setup(evidence)
		card.add_child(sketch)
	_floating_cards[evidence_id] = card
