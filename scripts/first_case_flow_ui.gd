class_name FirstCaseFlowUI
extends Control


const CASE_SCENE_UI := preload("res://scripts/case_scene_ui_theme.gd")
const PAPER_UI := preload("res://scripts/investigation_ui_theme.gd")
const PAPER_INK := Color("30251f")
const NEWSPAPER_ATLAS: Texture2D = preload("res://assets/ui/case_briefing_newspaper/newspaper_modules.png")
const NEWSPAPER_REGIONS := {
	"masthead": Rect2(43, 70, 1060, 160),
	"page": Rect2(28, 364, 710, 445),
	"photo": Rect2(744, 380, 425, 350),
	"paperclip": Rect2(1288, 164, 145, 145),
	"instruction": Rect2(30, 827, 420, 142),
	"button_dark": Rect2(1168, 457, 350, 88),
	"paper_grain": Rect2(70, 646, 630, 113),
}

signal briefing_accepted
signal submit_requested
signal photo_requested
signal settlement_closed

var _case_manager: Node
var modal_backdrop: ColorRect
var briefing_panel: PanelContainer
var settlement_panel: PanelContainer
var submit_button: Button
var submit_feedback: Label
var photo_button: Button
var return_button: Button


func setup(case_manager: Node) -> void:
	_case_manager = case_manager


func _ready() -> void:
	name = "FirstCaseFlowUI"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_modal_backdrop()
	_build_briefing()
	_build_submit_button()
	_build_settlement()
	resized.connect(_fit_settlement)
	_fit_settlement()
	show_briefing()


func show_briefing() -> void:
	if not briefing_panel.visible:
		GameAudio.play("dossier_open")
	var data := _case_manager.call("get_briefing_data") as Dictionary if is_instance_valid(_case_manager) else {}
	briefing_panel.get_node("Margin/Column/Eyebrow").text = String(data.get("eyebrow", "收到警局委托"))
	briefing_panel.get_node("Margin/Column/Title").text = String(data.get("title", "蓝色档案失窃案"))
	briefing_panel.get_node("Margin/Column/Description").text = String(data.get("description", ""))
	briefing_panel.get_node("Margin/Column/InstructionPanel/Instruction").text = String(data.get("instruction", ""))
	briefing_panel.get_node("Margin/Column/AcceptButton").text = String(data.get("accept_button", "接受委托"))
	_fit_modal_text.call_deferred(briefing_panel)
	briefing_panel.visible = true
	modal_backdrop.visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	submit_button.visible = false


func show_submit_failure(message: String) -> void:
	GameAudio.play("terminal_unavailable")
	submit_feedback.text = message
	submit_feedback.visible = true
	var tween := create_tween()
	tween.tween_interval(4.0)
	tween.tween_callback(func() -> void: submit_feedback.visible = false)


func show_settlement() -> void:
	if not settlement_panel.visible:
		GameAudio.play("case_complete")
	var data := _case_manager.call("get_completion_data") as Dictionary if is_instance_valid(_case_manager) else {}
	settlement_panel.get_node("Margin/Column/Title").text = String(data.get("title", "案件完成"))
	settlement_panel.get_node("Margin/Column/Description").text = String(data.get("description", ""))
	settlement_panel.get_node("Margin/Column/DeductionPanel/Deduction").text = String(data.get("deduction", ""))
	settlement_panel.get_node("Margin/Column/ReturnButton").text = String(data.get("return_button", "返回工作台"))
	_fit_modal_text.call_deferred(settlement_panel)
	briefing_panel.visible = false
	_fit_settlement()
	settlement_panel.visible = true
	modal_backdrop.visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	submit_button.visible = false
	photo_button.visible = true
	photo_button.disabled = false
	photo_button.text = "拍摄复原照片"
	return_button.visible = false


func begin_photo_capture() -> void:
	settlement_panel.visible = false
	modal_backdrop.visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func finish_photo_capture(success: bool) -> void:
	settlement_panel.visible = true
	modal_backdrop.visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	photo_button.visible = true
	photo_button.disabled = true
	photo_button.text = "照片已存入工作室相册" if success else "拍照失败，但案件进度已保存"
	return_button.visible = true


func set_submit_available(available: bool) -> void:
	submit_button.visible = available and not briefing_panel.visible and not settlement_panel.visible


func is_modal_active() -> bool:
	return briefing_panel.visible or settlement_panel.visible


func is_pointer_over_ui(screen_position: Vector2) -> bool:
	if is_modal_active():
		return true
	return submit_button.visible and submit_button.get_global_rect().has_point(screen_position)


func _build_modal_backdrop() -> void:
	modal_backdrop = ColorRect.new()
	modal_backdrop.name = "ModalBackdrop"
	modal_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_backdrop.color = Color("05070ac7")
	modal_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_backdrop.visible = false
	add_child(modal_backdrop)


func _build_briefing() -> void:
	briefing_panel = PanelContainer.new()
	briefing_panel.name = "BriefingPanel"
	briefing_panel.set_anchors_preset(Control.PRESET_CENTER)
	briefing_panel.offset_left = -590
	briefing_panel.offset_right = 590
	briefing_panel.offset_top = -340
	briefing_panel.offset_bottom = 340
	briefing_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	briefing_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(briefing_panel)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	briefing_panel.add_child(margin)
	var column := Control.new()
	column.name = "Column"
	column.custom_minimum_size = Vector2(1180, 680)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)

	column.add_child(_newspaper_texture_rect("NewspaperPage", "page", Rect2(0, 0, 1180, 680)))
	column.add_child(_newspaper_texture_rect("MastheadArt", "masthead", Rect2(40, 24, 1100, 154)))

	var newspaper_name := _label("CITY DAILY", 46, PAPER_INK)
	newspaper_name.name = "NewspaperName"
	newspaper_name.position = Vector2(338, 48)
	newspaper_name.size = Vector2(500, 58)
	newspaper_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	newspaper_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	column.add_child(newspaper_name)
	var newspaper_motto := _label("TRUTH LIES IN DETAILS", 11, Color("59483d"))
	newspaper_motto.name = "NewspaperMotto"
	newspaper_motto.position = Vector2(338, 106)
	newspaper_motto.size = Vector2(500, 22)
	newspaper_motto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	newspaper_motto.add_theme_color_override("font_color", Color("59483d"))
	column.add_child(newspaper_motto)
	var issue := _label("NO. 0327\nCITY INVESTIGATION BUREAU", 10, Color("59483d"))
	issue.name = "Issue"
	issue.position = Vector2(910, 67)
	issue.size = Vector2(188, 50)
	issue.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	issue.add_theme_color_override("font_color", Color("59483d"))
	column.add_child(issue)

	var title := _label("", 43, PAPER_INK)
	title.name = "Title"
	title.position = Vector2(66, 170)
	title.size = Vector2(1048, 76)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.clip_text = true
	column.add_child(title)
	var title_rule := ColorRect.new()
	title_rule.name = "TitleRule"
	title_rule.color = Color("8d4a3c")
	title_rule.position = Vector2(67, 247)
	title_rule.size = Vector2(1046, 5)
	title_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(title_rule)

	var briefing_label := _label("INVESTIGATION BRIEFING", 13, Color("57463b"))
	briefing_label.name = "BriefingLabel"
	briefing_label.position = Vector2(70, 260)
	briefing_label.size = Vector2(470, 26)
	column.add_child(briefing_label)
	var eyebrow := _label("", 14, Color("7f4438"))
	eyebrow.name = "Eyebrow"
	eyebrow.position = Vector2(70, 286)
	eyebrow.size = Vector2(500, 28)
	eyebrow.add_theme_color_override("font_color", Color("7f4438"))
	column.add_child(eyebrow)

	var description := _rich_text(19, PAPER_INK, 0)
	description.name = "Description"
	description.position = Vector2(70, 321)
	description.size = Vector2(520, 188)
	description.scroll_active = false
	description.add_theme_constant_override("line_separation", 10)
	column.add_child(description)

	var photo := _newspaper_texture_rect("CasePhoto", "photo", Rect2(650, 285, 466, 300))
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(photo)
	column.add_child(_newspaper_texture_rect("PhotoPaperclip", "paperclip", Rect2(1012, 270, 102, 102)))

	var instruction_panel := PanelContainer.new()
	instruction_panel.name = "InstructionPanel"
	instruction_panel.position = Vector2(68, 525)
	instruction_panel.size = Vector2(566, 112)
	instruction_panel.add_theme_stylebox_override("panel", _newspaper_style("instruction"))
	column.add_child(instruction_panel)
	var instruction := _label("", 14, PAPER_INK)
	instruction.name = "Instruction"
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.custom_minimum_size = Vector2(0, 90)
	instruction.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction_panel.add_child(instruction)

	var accept_button := Button.new()
	_newspaper_button(accept_button)
	accept_button.text = "接受委托"
	accept_button.name = "AcceptButton"
	accept_button.position = Vector2(702, 566)
	accept_button.size = Vector2(390, 72)
	accept_button.add_theme_font_size_override("font_size", 21)
	accept_button.pressed.connect(_on_accept_pressed)
	column.add_child(accept_button)
	var arrow := _label("→", 30, Color("efe2cd"))
	arrow.name = "AcceptArrow"
	arrow.position = Vector2(1027, 575)
	arrow.size = Vector2(48, 50)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.add_theme_color_override("font_color", Color("efe2cd"))
	column.add_child(arrow)


func _build_submit_button() -> void:
	submit_button = _button("提交现场重构", Color("59417b"), 16)
	submit_button.name = "SubmitReconstructionButton"
	submit_button.set_anchors_preset(Control.PRESET_CENTER_TOP)
	submit_button.offset_left = -105
	submit_button.offset_right = 105
	submit_button.offset_top = 72
	submit_button.offset_bottom = 120
	submit_button.visible = false
	submit_button.pressed.connect(func() -> void: submit_requested.emit())
	add_child(submit_button)
	submit_feedback = _label("", 14, Color("f5c780"))
	submit_feedback.name = "SubmitFeedback"
	submit_feedback.set_anchors_preset(Control.PRESET_CENTER_TOP)
	submit_feedback.offset_left = -310
	submit_feedback.offset_right = 310
	submit_feedback.offset_top = 130
	submit_feedback.offset_bottom = 180
	submit_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	submit_feedback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	submit_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	submit_feedback.visible = false
	add_child(submit_feedback)


func _build_settlement() -> void:
	settlement_panel = PanelContainer.new()
	settlement_panel.name = "SettlementPanel"
	settlement_panel.set_anchors_preset(Control.PRESET_CENTER)
	settlement_panel.offset_left = -590
	settlement_panel.offset_right = 590
	settlement_panel.offset_top = -340
	settlement_panel.offset_bottom = 340
	settlement_panel.pivot_offset = Vector2(590, 340)
	settlement_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	settlement_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	settlement_panel.visible = false
	add_child(settlement_panel)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	settlement_panel.add_child(margin)
	var column := Control.new()
	column.name = "Column"
	column.custom_minimum_size = Vector2(1180, 680)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	column.add_child(_newspaper_texture_rect("NewspaperPage", "page", Rect2(0, 0, 1180, 680)))
	# Cover the atlas's preprinted interior rules so they never cross live text.
	for index in 3:
		column.add_child(_newspaper_texture_rect("PaperGrain%d" % index, "paper_grain", Rect2(54, 180 + index * 150, 1070, 150)))
	column.add_child(_newspaper_texture_rect("MastheadArt", "masthead", Rect2(40, 24, 1100, 154)))
	var masthead := _settlement_label(column, "NewspaperName", "CITY DAILY", Rect2(434, 51, 362, 58), 44)
	masthead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var motto := _settlement_label(column, "Motto", "TRUTH LIES IN DETAILS", Rect2(434, 111, 362, 20), 11)
	motto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var issue := _settlement_label(column, "Issue", "结案特刊  /  CASE CLOSED", Rect2(825, 56, 265, 24), 12)
	issue.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var title := _settlement_label(column, "Title", "", Rect2(68, 192, 1010, 61), 44)
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(["SimSun", "Noto Serif CJK SC", "serif"])
	title.add_theme_font_override("font", serif)
	title.clip_text = true
	_settlement_label(column, "Eyebrow", "现场重构完成   /   RECONSTRUCTION REPORT", Rect2(70, 254, 1010, 24), 12, Color("854c3d"))
	_settlement_rule(column, Rect2(68, 286, 1044, 4), Color("8d4a3c"))
	_settlement_label(column, "RecordHeading", "复原记录", Rect2(70, 310, 620, 30), 23)
	var description := _rich_text(20, PAPER_INK, 0)
	description.name = "Description"
	description.position = Vector2(70, 352)
	description.size = Vector2(615, 108)
	description.scroll_active = false
	description.add_theme_constant_override("line_separation", 8)
	column.add_child(description)
	_settlement_rule(column, Rect2(70, 460, 615, 1), Color("897761"))
	_settlement_label(column, "DeductionHeading", "后续调查", Rect2(70, 475, 615, 30), 23)
	var deduction_panel := Control.new()
	deduction_panel.name = "DeductionPanel"
	deduction_panel.position = Vector2(70, 516)
	deduction_panel.size = Vector2(615, 94)
	deduction_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(deduction_panel)
	var deduction := _rich_text(17, PAPER_INK, 0)
	deduction.name = "Deduction"
	deduction.size = deduction_panel.size
	deduction.scroll_active = false
	deduction_panel.add_child(deduction)
	_settlement_rule(column, Rect2(727, 312, 1, 278), Color("a5947c"))
	column.add_child(_newspaper_texture_rect("CasePhoto", "photo", Rect2(767, 310, 324, 267)))
	column.add_child(_newspaper_texture_rect("PhotoPaperclip", "paperclip", Rect2(1023, 300, 80, 80)))
	var caption := _settlement_label(column, "PhotoCaption", "空间已复原 · 线索待追踪", Rect2(775, 578, 316, 24), 14, Color("74624e"))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	photo_button = Button.new()
	_newspaper_button(photo_button)
	photo_button.text = "拍摄复原照片"
	photo_button.name = "CaptureCasePhotoButton"
	photo_button.position = Vector2(68, 615)
	photo_button.size = Vector2(490, 48)
	photo_button.add_theme_font_size_override("font_size", 18)
	photo_button.pressed.connect(func() -> void: photo_requested.emit())
	column.add_child(photo_button)
	return_button = Button.new()
	_newspaper_button(return_button)
	return_button.text = "完成案件，返回工作台"
	return_button.name = "ReturnButton"
	return_button.position = Vector2(718, 615)
	return_button.size = Vector2(394, 48)
	return_button.add_theme_font_size_override("font_size", 18)
	return_button.pressed.connect(func() -> void: settlement_closed.emit())
	return_button.visible = false
	column.add_child(return_button)


func _fit_settlement() -> void:
	if is_instance_valid(settlement_panel):
		var factor := minf(1.0, minf((size.x - 32.0) / 1180.0, (size.y - 32.0) / 680.0))
		settlement_panel.scale = Vector2.ONE * maxf(0.1, factor)


func _fit_modal_text(node: Node) -> void:
	# Fit translations inside the existing newspaper columns instead of cutting
	# off longer English paragraphs. Keep the original Chinese sizes as defaults.
	if node is RichTextLabel and not node.scroll_active:
		var font_size: int = 19 if node.name == "Description" and briefing_panel.is_ancestor_of(node) else (20 if node.name == "Description" else 17)
		node.add_theme_font_size_override("normal_font_size", font_size)
		while font_size > 14 and node.get_content_height() > node.size.y:
			font_size -= 1
			node.add_theme_font_size_override("normal_font_size", font_size)
	elif node is Button and node.name == "AcceptButton":
		var font_size := 21
		var font: Font = node.get_theme_font("font")
		while font_size > 14 and font.get_string_size(tr(node.text), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > node.size.x - 92:
			font_size -= 1
		node.add_theme_font_size_override("font_size", font_size)
	for child: Node in node.get_children():
		_fit_modal_text(child)


func _settlement_label(parent: Control, node_name: String, text_value: String, rect: Rect2, font_size: int, color := PAPER_INK) -> Label:
	var label := _label(text_value, font_size, color)
	label.name = node_name
	label.position = rect.position
	label.size = rect.size
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _settlement_rule(parent: Control, rect: Rect2, color: Color) -> void:
	var rule := ColorRect.new()
	rule.position = rect.position
	rule.size = rect.size
	rule.color = color
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rule)


func _on_accept_pressed() -> void:
	GameAudio.play("paper_confirm")
	briefing_panel.visible = false
	modal_backdrop.visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	submit_button.visible = false
	briefing_accepted.emit()


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", PAPER_INK)
	return label


func _rich_text(font_size: int, color: Color, minimum_height: float) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = false
	label.fit_content = false
	label.scroll_active = true
	label.custom_minimum_size = Vector2(0, minimum_height)
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_color_override("default_color", PAPER_INK)
	label.add_theme_constant_override("line_separation", 6)
	label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	return label


func _newspaper_texture(key: String) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = NEWSPAPER_ATLAS
	texture.region = NEWSPAPER_REGIONS[key]
	texture.filter_clip = true
	return texture


func _newspaper_texture_rect(node_name: String, key: String, rect: Rect2) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.name = node_name
	texture_rect.texture = _newspaper_texture(key)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.position = rect.position
	texture_rect.size = rect.size
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return texture_rect


func _newspaper_style(key: String, tint := Color.WHITE) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = _newspaper_texture(key)
	style.modulate_color = tint
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _newspaper_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var state_tints := {
		"normal": Color.WHITE,
		"hover": Color("fff4dc"),
		"pressed": Color("cfbaa0"),
		"disabled": Color("8f8578"),
	}
	for state: String in state_tints:
		var style := _newspaper_style("button_dark", state_tints[state])
		style.content_margin_left = 24
		style.content_margin_right = 50
		button.add_theme_stylebox_override(state, style)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color("efe2cd"))
	button.add_theme_color_override("font_disabled_color", Color("b8ad9e"))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _button(text_value: String, color: Color, font_size: int) -> Button:
	var button := Button.new()
	button.text = text_value
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", font_size)
	PAPER_UI.button(button, "button")
	return button


func _style(color: Color, radius: int, border_color := Color.TRANSPARENT, border_width := 0) -> StyleBoxFlat:
	var style := CASE_SCENE_UI.panel()
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style
