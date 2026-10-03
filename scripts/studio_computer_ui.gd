class_name StudioComputerUI
extends Control

const PAPER_CONFIRMATION_DIALOG := preload("res://scenes/ui/paper_confirmation_dialog.tscn")
const TERMINAL_ATLAS: Texture2D = preload("res://assets/ui/computer_terminal/terminal_atlas.png")
const FURNITURE_ICONS := preload("res://scripts/furniture_icon_library.gd")

const ATLAS_TOP_BUTTON_LEFT := Rect2(34, 29, 193, 82)
const ATLAS_TOP_BUTTON_RIGHT := Rect2(239, 29, 195, 82)
const ATLAS_TITLE_BAR := Rect2(650, 112, 652, 52)
const ATLAS_WINDOW_MINIMIZE := Rect2(1205, 29, 68, 66)
const ATLAS_WINDOW_MAXIMIZE := Rect2(1278, 29, 69, 66)
const ATLAS_WINDOW_CLOSE := Rect2(1353, 29, 67, 66)
const APP_ICON_TEXTURES := {
	"mail": preload("res://assets/ui/computer_terminal/icons/mail.png"),
	"album": preload("res://assets/ui/computer_terminal/icons/album.png"),
	"shop": preload("res://assets/ui/computer_terminal/icons/shop.png"),
	"cases": preload("res://assets/ui/computer_terminal/icons/cases.png"),
	"minigame": preload("res://assets/ui/computer_terminal/icons/minigame.png"),
	"system": preload("res://assets/ui/computer_terminal/icons/system.png"),
}
const FOLDER_ICON_TEXTURES: Array[Texture2D] = [
	preload("res://assets/ui/computer_terminal/icons/folder_mail.png"),
	preload("res://assets/ui/computer_terminal/icons/folder_document.png"),
	preload("res://assets/ui/computer_terminal/icons/folder_archive.png"),
]


signal opened
signal closed

var _profile: Node
var _content: VBoxContainer
var _title: Label
var _money_label: Label
var _mail_button: Button
var _mail_badge: Label
var _window_icon: TextureRect
var _window_title: Label
var _category_column: VBoxContainer
var _app_buttons: Dictionary = {}
var _current_app := "mail"
var _reset_overlay: Control
var _reset_confirm_button: Button
var _resetting_game := false


func setup(profile: Node) -> void:
	_profile = profile


func _ready() -> void:
	name = "StudioComputerUI"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_desktop()
	_build_reset_confirmation()
	_connect_profile()


func open_desktop() -> void:
	visible = true
	move_to_front()
	opened.emit()
	_show_app(_current_app)


func close_desktop() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if is_instance_valid(_reset_overlay) and _reset_overlay.visible:
			_close_reset_confirmation()
		else:
			close_desktop()
		get_viewport().set_input_as_handled()


func _build_desktop() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("061a1d")
	add_child(background)

	var topbar := PanelContainer.new()
	topbar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	topbar.offset_left = 18
	topbar.offset_top = 14
	topbar.offset_right = -18
	topbar.offset_bottom = 80
	topbar.add_theme_stylebox_override("panel", _style(Color("071e21f4"), 2, Color("65716f"), 2))
	add_child(topbar)
	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 26)
	top_margin.add_theme_constant_override("margin_right", 14)
	top_margin.add_theme_constant_override("margin_top", 4)
	top_margin.add_theme_constant_override("margin_bottom", 4)
	topbar.add_child(top_margin)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	top_margin.add_child(top_row)
	var brand_column := VBoxContainer.new()
	brand_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand_column.alignment = BoxContainer.ALIGNMENT_CENTER
	brand_column.add_theme_constant_override("separation", -3)
	top_row.add_child(brand_column)
	brand_column.add_child(_label("CALIBRATOR / 本地终端", 20, Color("d8f3f1")))
	var version := _label("INVESTIGATION TERMINAL  v1.3.0", 9, Color("70a6a9"))
	version.add_theme_constant_override("character_spacing", 2)
	brand_column.add_child(version)
	_money_label = _label("", 16, Color("f0cc78"))
	_money_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(_money_label)
	var debug_money := _button("+ ¥5000", Color("704f52"))
	debug_money.name = "ComputerDebugAddMoneyButton"
	debug_money.custom_minimum_size = Vector2(112, 44)
	_apply_atlas_button(debug_money, ATLAS_TOP_BUTTON_LEFT)
	debug_money.tooltip_text = "测试用：立即增加 ¥5000"
	debug_money.pressed.connect(func() -> void: _profile.call("add_debug_money", 5000))
	top_row.add_child(debug_money)
	var close_button := _button("离开电脑", Color("714f62"))
	close_button.custom_minimum_size = Vector2(126, 44)
	_apply_atlas_button(close_button, ATLAS_TOP_BUTTON_RIGHT)
	close_button.pressed.connect(close_desktop)
	top_row.add_child(close_button)

	var body := HBoxContainer.new()
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 18
	body.offset_top = 90
	body.offset_right = -18
	body.offset_bottom = -20
	body.add_theme_constant_override("separation", 16)
	add_child(body)
	var dock := PanelContainer.new()
	dock.custom_minimum_size = Vector2(136, 0)
	dock.add_theme_stylebox_override("panel", _style(Color("071d20e6"), 4, Color("64706e"), 2))
	body.add_child(dock)
	var dock_margin := MarginContainer.new()
	dock_margin.add_theme_constant_override("margin_left", 8)
	dock_margin.add_theme_constant_override("margin_right", 8)
	dock_margin.add_theme_constant_override("margin_top", 8)
	dock_margin.add_theme_constant_override("margin_bottom", 8)
	dock.add_child(dock_margin)
	var dock_column := VBoxContainer.new()
	dock_column.add_theme_constant_override("separation", 4)
	dock_margin.add_child(dock_column)
	_mail_button = _app_button("邮箱", "mail")
	dock_column.add_child(_mail_button)
	dock_column.add_child(_app_button("现场相册", "album"))
	dock_column.add_child(_app_button("设备商店", "shop"))
	dock_column.add_child(_app_button("案件索引", "cases"))
	dock_column.add_child(_app_button("小游戏", "minigame"))
	dock_column.add_child(_app_button("系统工具", "system"))

	var window := PanelContainer.new()
	window.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	window.add_theme_stylebox_override("panel", _style(Color("0a2d31f2"), 3, Color("b0b2a8"), 3))
	body.add_child(window)
	var window_column := VBoxContainer.new()
	window_column.add_theme_constant_override("separation", 0)
	window.add_child(window_column)

	var title_bar := PanelContainer.new()
	title_bar.custom_minimum_size = Vector2(0, 43)
	title_bar.add_theme_stylebox_override("panel", _atlas_style(ATLAS_TITLE_BAR, 7))
	window_column.add_child(title_bar)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	title_bar.add_child(title_row)
	_window_icon = TextureRect.new()
	_window_icon.name = "WindowAppIcon"
	_window_icon.custom_minimum_size = Vector2(32, 30)
	_window_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_window_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_row.add_child(_window_icon)
	_window_title = _label("邮箱  MAIL", 15, Color("eef4e9"))
	_window_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_window_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(_window_title)
	for rect: Rect2 in [ATLAS_WINDOW_MINIMIZE, ATLAS_WINDOW_MAXIMIZE, ATLAS_WINDOW_CLOSE]:
		var control_icon := TextureRect.new()
		control_icon.custom_minimum_size = Vector2(30, 30)
		control_icon.texture = _atlas_texture(rect)
		control_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		control_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		control_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_row.add_child(control_icon)

	var work_area := HBoxContainer.new()
	work_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	work_area.add_theme_constant_override("separation", 0)
	window_column.add_child(work_area)
	var category_panel := PanelContainer.new()
	category_panel.custom_minimum_size = Vector2(188, 0)
	category_panel.add_theme_stylebox_override("panel", _style(Color("d4cfbd"), 0, Color("85867e"), 2))
	work_area.add_child(category_panel)
	var category_margin := MarginContainer.new()
	category_margin.add_theme_constant_override("margin_left", 12)
	category_margin.add_theme_constant_override("margin_right", 12)
	category_margin.add_theme_constant_override("margin_top", 28)
	category_margin.add_theme_constant_override("margin_bottom", 20)
	category_panel.add_child(category_margin)
	_category_column = VBoxContainer.new()
	_category_column.add_theme_constant_override("separation", 10)
	category_margin.add_child(_category_column)

	var content_panel := PanelContainer.new()
	content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_panel.add_theme_stylebox_override("panel", _style(Color("0b3034"), 0, Color("5a8587"), 1))
	work_area.add_child(content_panel)
	var content_margin := MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 24)
	content_margin.add_theme_constant_override("margin_right", 24)
	content_margin.add_theme_constant_override("margin_top", 20)
	content_margin.add_theme_constant_override("margin_bottom", 20)
	content_panel.add_child(content_margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	content_margin.add_child(outer)
	_title = _label("", 27, Color("e8f2ee"))
	outer.add_child(_title)
	var divider := HSeparator.new()
	divider.add_theme_stylebox_override("separator", _style(Color("6b939377"), 0))
	outer.add_child(divider)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	scroll.add_child(_content)
	var scanlines := TextureRect.new()
	scanlines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scanlines.texture = _make_scanline_texture()
	scanlines.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scanlines.stretch_mode = TextureRect.STRETCH_TILE
	scanlines.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scanlines.modulate = Color(1, 1, 1, 0.26)
	scanlines.z_index = 2
	add_child(scanlines)
	_refresh_header()


func _build_reset_confirmation() -> void:
	_reset_overlay = PAPER_CONFIRMATION_DIALOG.instantiate() as Control
	_reset_overlay.name = "ResetGameConfirmation"
	_reset_overlay.z_index = 50
	add_child(_reset_overlay)
	(_reset_overlay.get_node("Note/TitleLabel") as Label).text = "重置全部游戏进度？"
	(_reset_overlay.get_node("Note/WarningLabel") as Label).text = "将清除工作室布置、金钱、商店物品，\n以及邮件、相册和全部案件记录。\n重置后返回开始界面，此操作无法撤销。"
	var cancel := _reset_overlay.get_node("Note/CancelButton") as Button
	cancel.pressed.connect(_close_reset_confirmation)
	_reset_confirm_button = _reset_overlay.get_node("Note/ConfirmButton") as Button
	_reset_confirm_button.pressed.connect(_confirm_global_reset)


func _open_reset_confirmation() -> void:
	if _resetting_game:
		return
	_reset_overlay.visible = true
	_reset_overlay.move_to_front()
	(_reset_overlay.get_node("Note/CancelButton") as Button).grab_focus()


func _close_reset_confirmation() -> void:
	if _resetting_game:
		return
	_reset_overlay.visible = false


func _confirm_global_reset() -> void:
	if _resetting_game:
		return
	_resetting_game = true
	_reset_confirm_button.disabled = true
	var flow := get_node_or_null("/root/GameFlow")
	if is_instance_valid(flow) and bool(await flow.call("reset_game_progress", true, true)):
		return
	_resetting_game = false
	_reset_confirm_button.disabled = false
	_reset_overlay.visible = false
	_show_app("system")


func _show_app(app_id: String) -> void:
	_current_app = app_id
	_clear_content()
	match app_id:
		"mail": _build_mail()
		"album": _build_album()
		"shop": _build_shop()
		"cases": _build_cases()
		"minigame": _build_minigame()
		_: _build_system()
	_refresh_app_chrome()
	_refresh_header()


func _build_mail() -> void:
	_title.text = "邮箱"
	var mails: Array = _profile.call("get_available_mail") if is_instance_valid(_profile) else []
	if mails.is_empty():
		_content.add_child(_empty("暂无邮件。风扇声听起来像一封很长的回信。"))
		return
	for mail_value: Variant in mails:
		var mail := mail_value as Dictionary
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _style(Color("23394a"), 14, Color("5a789077"), 1))
		_content.add_child(card)
		var margin := MarginContainer.new()
		for side: String in ["left", "right", "top", "bottom"]:
			margin.add_theme_constant_override("margin_%s" % side, 16)
		card.add_child(margin)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 8)
		margin.add_child(column)
		var row := HBoxContainer.new()
		column.add_child(row)
		var unread := "●  " if not bool(mail.get("is_read", false)) else ""
		var subject := _label(unread + String(mail.get("subject", "无主题")), 17, Color("eaf4fa"))
		subject.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(subject)
		row.add_child(_label(String(mail.get("sender", "未知发件人")), 12, Color("8fb0c3")))
		var body := _label(String(mail.get("body", "")), 13, Color("bacbd5"))
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size = Vector2(0, 52)
		column.add_child(body)
		var buttons := HBoxContainer.new()
		buttons.alignment = BoxContainer.ALIGNMENT_END
		column.add_child(buttons)
		var read_button := _button("标为已读", Color("405c70"))
		read_button.visible = not bool(mail.get("is_read", false))
		read_button.pressed.connect(func() -> void:
			_profile.call("mark_mail_read", String(mail.get("mail_id", "")))
			_show_app("mail")
		)
		buttons.add_child(read_button)
		var case_id := String(mail.get("case_id", ""))
		var completed := false
		if not case_id.is_empty() and is_instance_valid(_profile):
			completed = bool((_profile.get("completed_cases") as Dictionary).get(case_id, false))
		if not case_id.is_empty() and not completed:
			var accepted := bool(mail.get("is_accepted", false))
			var enter_case := _button("继续委托" if accepted else "接取委托", Color("557862"))
			enter_case.pressed.connect(_on_mail_case_pressed.bind(String(mail.get("mail_id", "")), case_id, accepted))
			buttons.add_child(enter_case)
		elif completed:
			var archived := _label("已完成", 12, Color("8fc6a4"))
			archived.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			buttons.add_child(archived)
			var replay := _button("重新调查", Color("5a4e75"))
			replay.tooltip_text = "重新进入已完成案件，不会重复获得酬劳"
			replay.pressed.connect(_start_case.bind(case_id))
			buttons.add_child(replay)


func _accept_case(mail_id: String) -> void:
	var case_id := String(_profile.call("accept_mail", mail_id))
	if case_id.is_empty():
		return
	await _start_case(case_id)


func _on_mail_case_pressed(mail_id: String, case_id: String, accepted: bool) -> void:
	if accepted:
		await _start_case(case_id)
	else:
		await _accept_case(mail_id)


func _start_case(case_id: String) -> void:
	var flow := get_node_or_null("/root/GameFlow")
	if is_instance_valid(flow):
		await flow.call("start_case", case_id)


func _build_album() -> void:
	_title.text = "现场相册"
	var entries: Array = _profile.get("album_entries") if is_instance_valid(_profile) else []
	if entries.is_empty():
		_content.add_child(_empty("尚无完成现场。结案后拍摄的复原照片会保存在这里。"))
		return
	for value: Variant in entries:
		var entry := value as Dictionary
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 128)
		card.add_theme_stylebox_override("panel", _style(Color("27394a"), 14))
		_content.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 18)
		card.add_child(row)
		var image_panel := ColorRect.new()
		image_panel.custom_minimum_size = Vector2(190, 112)
		image_panel.color = Color("596f7c")
		row.add_child(image_panel)
		var path := String(entry.get("image_path", ""))
		if not path.is_empty() and FileAccess.file_exists(path):
			var image := Image.load_from_file(path)
			if not image.is_empty():
				var texture := TextureRect.new()
				texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				texture.texture = ImageTexture.create_from_image(image)
				texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				image_panel.add_child(texture)
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(column)
		column.add_child(_label(String(entry.get("title", "现场记录")), 19, Color("edf7fc")))
		var description := _label(String(entry.get("description", "")), 13, Color("aabfca"))
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(description)


func _build_shop() -> void:
	_title.text = "设备商店"
	_content.add_child(_empty("空间扩建按房间地块计算。先点击对应楼层的“扩建”，再购买刚解锁的房间；购买后地块会立即出现在工作室。", Color("263e4b")))
	_build_expansion_card(0)
	_build_expansion_card(1)
	var furniture_title := _label("家具与功能设备", 19, Color("e5eff5"))
	furniture_title.add_theme_constant_override("outline_size", 3)
	furniture_title.add_theme_color_override("font_outline_color", Color("111b29"))
	_content.add_child(furniture_title)
	for value: Variant in _profile.call("get_shop_items"):
		var item := value as Dictionary
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _style(Color("223545"), 12))
		_content.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		card.add_child(row)
		var furniture_icon := TextureRect.new()
		furniture_icon.name = "FurnitureIcon"
		furniture_icon.custom_minimum_size = Vector2(72, 80)
		furniture_icon.texture = FURNITURE_ICONS.get_icon(String(item.get("furniture_kind", "")))
		furniture_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		furniture_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		furniture_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(furniture_icon)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(copy)
		copy.add_child(_label(String(item.get("display_name", "设备")), 17, Color("ecf5fa")))
		var description := _label(String(item.get("description", "")), 12, Color("a9bdc9"))
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(description)
		var buy := _button("购买  ¥%d" % int(item.get("price", 0)), Color("466a5c"))
		buy.custom_minimum_size = Vector2(132, 44)
		buy.disabled = not bool(item.get("is_unlocked", false)) or int(_profile.get("money")) < int(item.get("price", 0))
		if not bool(item.get("is_unlocked", false)):
			buy.text = "完成案件后解锁"
		buy.pressed.connect(func() -> void:
			_profile.call("purchase_item", String(item.get("item_id", "")))
			_show_app("shop")
		)
		row.add_child(buy)


func _build_expansion_card(floor_index: int) -> void:
	var room_count := int(_profile.call("get_studio_room_count", floor_index))
	var maximum := 4
	var floor_name := "一楼" if floor_index == 0 else "二楼"
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style(Color("2b3f49") if floor_index == 0 else Color("34364d"), 14, Color("8aa27166"), 1))
	_content.add_child(card)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 16)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(_label("%s房间地块　%d / %d" % [floor_name, room_count, maximum], 17, Color("edf5e8")))
	var description := "每次购买增加一块房间，最多组成 2×2 的四房空间。"
	if floor_index == 1 and int(_profile.call("get_studio_room_count", 0)) < maximum:
		description = "一楼扩建至 4 个房间后，才能启动二楼扩建。"
	elif floor_index == 1 and room_count == 0:
		description = "先启动二楼扩建，再购买二楼第一个房间；购买后开放楼层切换。"
	copy.add_child(_label(description, 12, Color("b9c9ca")))
	var action := _button("", Color("62764e") if floor_index == 0 else Color("5d5c83"))
	action.custom_minimum_size = Vector2(220, 48)
	row.add_child(action)
	if room_count >= maximum:
		action.text = "%s已扩建完成" % floor_name
		action.disabled = true
	elif floor_index == 1 and int(_profile.call("get_studio_room_count", 0)) < maximum:
		action.text = "需先完成一楼 4 / 4"
		action.disabled = true
	elif bool(_profile.call("is_studio_room_purchase_unlocked", floor_index)):
		var cost := int(_profile.call("get_studio_room_cost", floor_index))
		action.text = "购买%s第 %d 个房间　¥%d" % [floor_name, room_count + 1, cost]
		action.disabled = not bool(_profile.call("can_purchase_studio_room", floor_index))
		action.pressed.connect(func() -> void: _profile.call("purchase_studio_room", floor_index))
	else:
		action.text = "扩建%s" % floor_name
		action.disabled = not bool(_profile.call("can_unlock_studio_room_purchase", floor_index))
		action.pressed.connect(func() -> void: _profile.call("unlock_studio_room_purchase", floor_index))


func _build_cases() -> void:
	_title.text = "案件索引"
	for value: Variant in _profile.call("get_campaign_cases"):
		var item := value as Dictionary
		var completed := bool((_profile.get("completed_cases") as Dictionary).get(String(item.get("case_id", "")), false))
		var case_text := "%s\n%s · 酬劳 ¥%d" % [String(item.get("title", "案件")), "已归档" if completed else "等待邮件委托", int(item.get("reward_money", 0))]
		if completed and bool(_profile.call("has_skill", "archive_summary")):
			var album := item.get("album", {}) as Dictionary
			case_text += "\n投影归档：%s" % String(album.get("description", "暂无额外摘要。"))
		var panel := _empty(case_text, Color("355064") if not completed else Color("385947"))
		_content.add_child(panel)
		if completed:
			var replay := _button("重新进入现场（无重复奖励）", Color("5a4e75"))
			replay.pressed.connect(func() -> void:
				var flow := get_node_or_null("/root/GameFlow")
				if is_instance_valid(flow): await flow.call("start_case", String(item.get("case_id", "")))
			)
			_content.add_child(replay)


func _build_minigame() -> void:
	_title.text = "小游戏 / 信号校准"
	_content.add_child(_empty("开发中的终端小游戏。\n目前按钮唯一的功能，是确认你的鼠标还在工作。"))
	var button := _button("进行一次毫无意义的校准", Color("506b82"))
	button.pressed.connect(func() -> void: button.text = "校准结果：非常准确（大概）")
	_content.add_child(button)


func _build_system() -> void:
	_title.text = "系统工具"
	var skills: Array = _profile.get("active_skills") if is_instance_valid(_profile) else []
	_content.add_child(_empty("当前有效技能：\n%s\n\n技能来自已摆放的功能家具。将家具收起后，能力会立即停止。" % ["、".join(skills) if not skills.is_empty() else "无"]))
	_content.add_child(_empty("存档管理\n重置会清空工作室、金钱、商店、邮件、相册与所有案件进度。", Color("4a3440")))
	var reset_button := _button("重置全部游戏进度", Color("70404d"))
	reset_button.name = "ResetGameProgressButton"
	reset_button.custom_minimum_size = Vector2(240, 46)
	reset_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	reset_button.pressed.connect(_open_reset_confirmation)
	_content.add_child(reset_button)


func _connect_profile() -> void:
	if not is_instance_valid(_profile):
		return
	for signal_name: String in ["money_changed", "mail_changed", "shop_changed"]:
		var callback := Callable(self, "_on_profile_changed")
		if not _profile.is_connected(signal_name, callback):
			_profile.connect(signal_name, callback)


func _on_profile_changed(_value: Variant = null) -> void:
	_refresh_header()
	if visible:
		_show_app(_current_app)


func _refresh_header() -> void:
	if is_instance_valid(_money_label) and is_instance_valid(_profile):
		_money_label.text = "账户余额  ¥%d" % int(_profile.get("money"))
	if is_instance_valid(_mail_button) and is_instance_valid(_profile):
		var unread := int(_profile.call("get_unread_mail_count"))
		if is_instance_valid(_mail_badge):
			_mail_badge.text = str(unread)
			_mail_badge.visible = unread > 0


func _app_button(text_value: String, app_id: String) -> Button:
	var button := Button.new()
	button.name = "%sDockButton" % app_id.capitalize()
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size = Vector2(0, 78)
	button.tooltip_text = text_value
	button.add_theme_stylebox_override("normal", _style(Color("071d2000"), 2))
	button.add_theme_stylebox_override("hover", _style(Color("174a4e99"), 2, Color("72a9ab"), 1))
	button.add_theme_stylebox_override("pressed", _style(Color("0f3b3fff"), 2, Color("9ed1d0"), 2))
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.set_anchors_preset(Control.PRESET_CENTER_TOP)
	icon.position = Vector2(-31, 1)
	icon.size = Vector2(62, 55)
	icon.texture = APP_ICON_TEXTURES[app_id] as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)
	var label := _label(text_value, 12, Color("d8e8e4"))
	label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_top = -24
	label.offset_bottom = -3
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	button.set_meta("caption_label", label)
	if app_id == "mail":
		_mail_badge = _label("", 10, Color("f8f3dd"))
		_mail_badge.position = Vector2(88, 5)
		_mail_badge.size = Vector2(24, 20)
		_mail_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_mail_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_mail_badge.add_theme_stylebox_override("normal", _style(Color("963f42"), 10, Color("f0c8b0"), 1))
		_mail_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(_mail_badge)
	_app_buttons[app_id] = button
	button.pressed.connect(func() -> void: _show_app(app_id))
	return button


func _refresh_app_chrome() -> void:
	var names := {
		"mail": ["邮箱", "MAIL"],
		"album": ["现场相册", "FIELD ALBUM"],
		"shop": ["设备商店", "EQUIPMENT SHOP"],
		"cases": ["案件索引", "CASE INDEX"],
		"minigame": ["小游戏", "SIGNAL LAB"],
		"system": ["系统工具", "SYSTEM TOOLS"],
	}
	var title_parts: Array = names.get(_current_app, ["系统工具", "SYSTEM TOOLS"])
	if is_instance_valid(_window_title):
		_window_title.text = "%s   %s" % [title_parts[0], title_parts[1]]
	if is_instance_valid(_window_icon):
		_window_icon.texture = APP_ICON_TEXTURES.get(_current_app, APP_ICON_TEXTURES["system"]) as Texture2D
	for id_value: Variant in _app_buttons.keys():
		var id := String(id_value)
		var button := _app_buttons[id] as Button
		var selected := id == _current_app
		button.add_theme_stylebox_override("normal", _style(Color("164c50e6") if selected else Color("071d2000"), 2, Color("75b4b5") if selected else Color.TRANSPARENT, 2 if selected else 0))
		var caption := button.get_meta("caption_label") as Label
		caption.add_theme_color_override("font_color", Color("f3eee0") if selected else Color("b8cfcc"))
	_rebuild_category_panel()


func _rebuild_category_panel() -> void:
	if not is_instance_valid(_category_column):
		return
	for child: Node in _category_column.get_children():
		child.queue_free()
	var rows: Array[Array] = []
	match _current_app:
		"mail": rows = [["收件箱", "待处理委托"], ["已读邮件", "调查记录"], ["已归档", "完成案件"]]
		"album": rows = [["现场照片", "结案快照"], ["复原记录", "空间档案"], ["归档", "已完成"]]
		"shop": rows = [["功能设备", "工作室能力"], ["家具", "空间陈设"], ["扩建", "楼层地块"]]
		"cases": rows = [["待调查", "邮件委托"], ["已完成", "案件归档"], ["复盘", "重新进入"]]
		"minigame": rows = [["信号输入", "终端通道"], ["校准记录", "实验数据"], ["帮助", "操作说明"]]
		_: rows = [["存档管理", "本地数据"], ["技能状态", "设备能力"], ["关于终端", "版本信息"]]
	for index: int in rows.size():
		var row_data := rows[index]
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(0, 58)
		panel.add_theme_stylebox_override("panel", _style(Color("8ec3c8") if index == 0 else Color("dad5c4"), 0, Color("96998e"), 1))
		_category_column.add_child(panel)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		panel.add_child(row)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(28, 30)
		icon.texture = FOLDER_ICON_TEXTURES[index]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(copy)
		copy.add_child(_label(String(row_data[0]), 13, Color("193a3d")))
		copy.add_child(_label(String(row_data[1]), 9, Color("526b6c")))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_category_column.add_child(spacer)
	var terminal_note := _label("CALIBRATOR\nLOCAL ARCHIVE", 9, Color("526a68"))
	terminal_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_category_column.add_child(terminal_note)


func _clear_content() -> void:
	for child: Node in _content.get_children():
		child.queue_free()


func _empty(text_value: String, color := Color("2a4052")) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 92)
	var terminal_color := Color(color.r * 0.48, maxf(color.g * 0.72, 0.16), maxf(color.b * 0.72, 0.18), color.a)
	panel.add_theme_stylebox_override("panel", _style(terminal_color, 5, Color("5d8585"), 1))
	var label := _label(text_value, 14, Color("c9dcda"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text_value: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_stylebox_override("normal", _style(color, 10))
	button.add_theme_stylebox_override("hover", _style(color.lightened(0.08), 10))
	button.add_theme_stylebox_override("pressed", _style(color.darkened(0.08), 10))
	return button


func _atlas_texture(rect: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = TERMINAL_ATLAS
	texture.region = rect
	return texture


func _atlas_style(rect: Rect2, texture_margin: int = 9) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = _atlas_texture(rect)
	style.texture_margin_left = texture_margin
	style.texture_margin_right = texture_margin
	style.texture_margin_top = texture_margin
	style.texture_margin_bottom = texture_margin
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _apply_atlas_button(button: Button, rect: Rect2) -> void:
	button.add_theme_stylebox_override("normal", _atlas_style(rect, 16))
	button.add_theme_stylebox_override("hover", _atlas_style(rect, 16))
	button.add_theme_stylebox_override("pressed", _atlas_style(rect, 16))
	button.add_theme_stylebox_override("disabled", _atlas_style(rect, 16))
	button.add_theme_color_override("font_color", Color("f0e8e0"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color("e0d2cc"))


func _make_scanline_texture() -> ImageTexture:
	var image := Image.create(2, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	image.set_pixel(0, 3, Color("00131544"))
	image.set_pixel(1, 3, Color("00131544"))
	return ImageTexture.create_from_image(image)


func _style(color: Color, radius: int, border_color := Color.TRANSPARENT, border_width := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
