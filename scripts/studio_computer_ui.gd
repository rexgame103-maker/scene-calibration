class_name StudioComputerUI
extends Control

const PAPER_CONFIRMATION_DIALOG := preload("res://scenes/ui/paper_confirmation_dialog.tscn")
const TERMINAL_ATLAS: Texture2D = preload("res://assets/ui/computer_terminal/terminal_atlas.png")
const FURNITURE_ICONS := preload("res://scripts/furniture_icon_library.gd")
const MAIL_CLIENT := preload("res://scenes/ui/terminal_mail_client.tscn")
const MAIL_THEME: Theme = preload("res://assets/ui/computer_terminal/classic_mail_theme.tres")
const APP_WINDOW := preload("res://scripts/terminal_app_window.gd")
const RESTORE_ICON := preload("res://assets/ui/computer_terminal/window_restore.svg")
const CLASSIC_TEXT := Color("222925")
const CLASSIC_MUTED := Color("55615b")
const APP_CAPTIONS := {"mail": "邮箱", "album": "相册", "shop": "商店", "cases": "案件", "minigame": "游戏", "system": "工具"}
const APP_CONTEXT: Array[String] = ["_content", "_title", "_window_icon", "_window_title",
	"_category_column", "_content_panel", "_content_margin", "_content_scroll",
	"_content_divider", "_category_panel", "_mail_host"]

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
var _mail_badge: Panel
var _window_icon: TextureRect
var _window_title: Label
var _category_column: VBoxContainer
var _app_buttons: Dictionary = {}
var _current_app := ""
var _workspace: Control
var _task_buttons: HBoxContainer
var _start_menu: PanelContainer
var _clock_label: Label
var _windows: Dictionary = {}
var _reset_overlay: Control
var _reset_confirm_button: Button
var _resetting_game := false
var _content_panel: PanelContainer
var _content_margin: MarginContainer
var _content_scroll: ScrollContainer
var _content_divider: HSeparator
var _category_panel: PanelContainer
var _mail_host: VBoxContainer
var _scanlines: TextureRect
var _mail_folder := "inbox"
var _selected_mail_id := ""


func setup(profile: Node) -> void:
	_profile = profile


func _ready() -> void:
	name = "StudioComputerUI"
	add_to_group("audio_terminal_ui")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_desktop()
	_build_reset_confirmation()
	_connect_profile()


func open_desktop() -> void:
	if visible:
		return
	visible = true
	GameAudio.play("crt_boot")
	move_to_front()
	opened.emit()
	# Each computer session starts on the desktop. Running apps remain on the taskbar.
	for entry: Dictionary in _windows.values():
		entry.window.hide()
		entry.window.is_minimized = true
		entry.window.stop_dragging()
	_current_app = ""
	_start_menu.hide()
	_refresh_header()
	_refresh_taskbar()


func close_desktop() -> void:
	if not visible:
		return
	visible = false
	_start_menu.hide()
	_update_reading_activity()
	GameAudio.play("terminal_window_close")
	closed.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if is_instance_valid(_reset_overlay) and _reset_overlay.visible:
			_close_reset_confirmation()
		elif _start_menu.visible:
			_start_menu.hide()
		elif not _current_app.is_empty():
			_close_app(_current_app)
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
	var debug_money := _button("+ ¥5000")
	debug_money.name = "ComputerDebugAddMoneyButton"
	debug_money.custom_minimum_size = Vector2(112, 44)
	_apply_atlas_button(debug_money, ATLAS_TOP_BUTTON_LEFT)
	debug_money.tooltip_text = "测试用：立即增加 ¥5000"
	debug_money.pressed.connect(func() -> void: _profile.call("add_debug_money", 5000))
	top_row.add_child(debug_money)
	var close_button := _button("离开电脑")
	close_button.custom_minimum_size = Vector2(126, 44)
	_apply_atlas_button(close_button, ATLAS_TOP_BUTTON_RIGHT)
	close_button.pressed.connect(close_desktop)
	GameAudio.bind_button(close_button, "")
	top_row.add_child(close_button)

	_workspace = Control.new()
	_workspace.name = "DesktopWorkspace"
	_workspace.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_workspace.offset_left = 18
	_workspace.offset_top = 90
	_workspace.offset_right = -18
	_workspace.offset_bottom = -48
	_workspace.clip_contents = true
	_workspace.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_start_menu.hide())
	_workspace.resized.connect(_fit_desktop_windows)
	add_child(_workspace)

	var desktop_mark := _label("CALIBRATOR", 42, Color("264348"))
	desktop_mark.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	desktop_mark.offset_left = -390
	desktop_mark.offset_right = -28
	desktop_mark.offset_top = -96
	desktop_mark.offset_bottom = -36
	desktop_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	desktop_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_workspace.add_child(desktop_mark)
	var desktop_note := _label("本地工作站", 12, Color("527173"))
	desktop_note.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	desktop_note.offset_left = -390
	desktop_note.offset_right = -32
	desktop_note.offset_top = -32
	desktop_note.offset_bottom = -12
	desktop_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	desktop_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_workspace.add_child(desktop_note)

	var shortcuts := GridContainer.new()
	shortcuts.name = "DesktopShortcuts"
	shortcuts.position = Vector2(12, 12)
	shortcuts.columns = 2
	shortcuts.add_theme_constant_override("h_separation", 10)
	shortcuts.add_theme_constant_override("v_separation", 14)
	_workspace.add_child(shortcuts)
	for app_id: String in APP_CAPTIONS:
		var shortcut := _app_button(APP_CAPTIONS[app_id], app_id)
		shortcut.custom_minimum_size = Vector2(90, 82)
		shortcuts.add_child(shortcut)
		if app_id == "mail": _mail_button = shortcut
	_build_taskbar()
	var scanlines := TextureRect.new()
	_scanlines = scanlines
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


func _create_app_window(app_id: String) -> void:
	var window := APP_WINDOW.new()
	window.name = app_id.capitalize() + "AppWindow"
	window.app_id = app_id
	window.add_theme_stylebox_override("panel", _style(Color("0a2d31f2"), 3, Color("b0b2a8"), 3))
	_workspace.add_child(window)
	window.activation_requested.connect(func() -> void: _activate_app(app_id))
	window.minimize_requested.connect(func() -> void: _minimize_app(app_id))
	window.close_requested.connect(func() -> void: _close_app(app_id))
	var window_column := VBoxContainer.new()
	window_column.add_theme_constant_override("separation", 0)
	window.add_child(window_column)

	var title_bar := PanelContainer.new()
	title_bar.custom_minimum_size = Vector2(0, 43)
	title_bar.add_theme_stylebox_override("panel", _atlas_style(ATLAS_TITLE_BAR, 7))
	window_column.add_child(title_bar)
	window.bind_title_bar(title_bar)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	title_row.mouse_filter = Control.MOUSE_FILTER_PASS
	title_bar.add_child(title_row)
	_window_icon = TextureRect.new()
	_window_icon.name = "WindowAppIcon"
	_window_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_window_icon.custom_minimum_size = Vector2(32, 30)
	_window_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_window_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_row.add_child(_window_icon)
	_window_title = _label("邮箱  MAIL", 15, Color("eef4e9"))
	_window_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_window_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(_window_title)
	var minimize := _window_control(ATLAS_WINDOW_MINIMIZE, "WindowMinimizeButton", "最小化")
	minimize.pressed.connect(func() -> void: window.minimize_requested.emit())
	title_row.add_child(minimize)
	var maximize := _window_control(ATLAS_WINDOW_MAXIMIZE, "WindowMaximizeButton", "最大化")
	maximize.pressed.connect(window.toggle_maximized)
	window.maximized_changed.connect(func(maximized: bool) -> void:
		maximize.tooltip_text = "还原" if maximized else "最大化"
		maximize.icon = RESTORE_ICON if maximized else null
		maximize.expand_icon = true
		maximize.add_theme_constant_override("icon_max_width", 16)
		for state: String in ["normal", "hover", "pressed", "focus"]:
			var surface: StyleBoxTexture
			if maximized:
				var theme_state := "pressed" if state == "pressed" else "normal"
				surface = MAIL_THEME.get_stylebox(theme_state, "Button").duplicate() as StyleBoxTexture
			else:
				surface = _atlas_style(ATLAS_WINDOW_MAXIMIZE, 6)
			surface.set_content_margin_all(0)
			maximize.add_theme_stylebox_override(state, surface))
	title_row.add_child(maximize)
	var close := _window_control(ATLAS_WINDOW_CLOSE, "WindowCloseButton", "关闭窗口")
	close.pressed.connect(func() -> void: window.close_requested.emit())
	title_row.add_child(close)

	var work_area := HBoxContainer.new()
	work_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	work_area.add_theme_constant_override("separation", 0)
	window_column.add_child(work_area)
	var category_panel := PanelContainer.new()
	_category_panel = category_panel
	category_panel.theme = MAIL_THEME
	category_panel.custom_minimum_size = Vector2(176, 0)
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
	_content_panel = content_panel
	content_panel.theme = MAIL_THEME
	content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_panel.add_theme_stylebox_override("panel", _style(Color("0b3034"), 0, Color("5a8587"), 1))
	work_area.add_child(content_panel)
	var content_margin := MarginContainer.new()
	_content_margin = content_margin
	content_margin.add_theme_constant_override("margin_left", 24)
	content_margin.add_theme_constant_override("margin_right", 24)
	content_margin.add_theme_constant_override("margin_top", 20)
	content_margin.add_theme_constant_override("margin_bottom", 20)
	content_panel.add_child(content_margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	content_margin.add_child(outer)
	_title = _label("", 14, CLASSIC_TEXT)
	outer.add_child(_title)
	var divider := HSeparator.new()
	_content_divider = divider
	divider.add_theme_stylebox_override("separator", MAIL_THEME.get_stylebox("separator", "HSeparator"))
	outer.add_child(divider)
	var scroll := ScrollContainer.new()
	_content_scroll = scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	scroll.add_child(_content)
	_mail_host = VBoxContainer.new()
	_mail_host.name = "MailHost"
	_mail_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mail_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_mail_host.visible = false
	outer.add_child(_mail_host)
	var context := {}
	for property: String in APP_CONTEXT:
		context[property] = get(property)
	var task := _button(APP_CAPTIONS[app_id])
	task.name = app_id.capitalize() + "TaskButton"
	task.icon = APP_ICON_TEXTURES[app_id]
	task.expand_icon = true
	task.add_theme_constant_override("icon_max_width", 18)
	task.toggle_mode = true
	task.custom_minimum_size = Vector2(124, 28)
	task.pressed.connect(func() -> void:
		if _current_app == app_id and window.visible:
			_minimize_app(app_id)
		else:
			_open_app(app_id))
	_task_buttons.add_child(task)
	_windows[app_id] = {"window": window, "task": task, "context": context}
	var area := _workspace.size
	var left := 208.0 if area.x >= 1100.0 else 8.0
	window.normal_rect = Rect2(Vector2(left, 12), Vector2(area.x - left - 12, area.y - 24))
	window.fit_to_workspace.call_deferred()


func _window_control(rect: Rect2, node_name: String, tooltip: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size = Vector2(28, 28)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var surface := _atlas_style(rect, 6)
		surface.set_content_margin_all(0)
		if state == "hover": surface.modulate_color = Color("e9ffff")
		if state == "pressed": surface.modulate_color = Color("a7bcb7")
		button.add_theme_stylebox_override(state, surface)
	button.add_theme_color_override("font_color", CLASSIC_TEXT)
	button.add_theme_font_size_override("font_size", 22)
	GameAudio.bind_button(button, "terminal_click")
	return button


func _build_taskbar() -> void:
	var bar := PanelContainer.new()
	bar.name = "DesktopTaskbar"
	bar.theme = MAIL_THEME
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_left = 18
	bar.offset_right = -18
	bar.offset_top = -40
	bar.offset_bottom = -8
	var surface := MAIL_THEME.get_stylebox("normal", "Button").duplicate() as StyleBoxTexture
	surface.set_content_margin_all(3)
	bar.add_theme_stylebox_override("panel", surface)
	add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	bar.add_child(row)
	var start := _button("开始")
	start.name = "DesktopStartButton"
	start.icon = APP_ICON_TEXTURES["system"]
	start.expand_icon = true
	start.add_theme_constant_override("icon_max_width", 20)
	start.custom_minimum_size = Vector2(82, 28)
	start.pressed.connect(func() -> void:
		_start_menu.visible = not _start_menu.visible
		if _start_menu.visible: _start_menu.move_to_front())
	row.add_child(start)
	_task_buttons = HBoxContainer.new()
	_task_buttons.name = "RunningApplications"
	_task_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_task_buttons.add_theme_constant_override("separation", 4)
	row.add_child(_task_buttons)
	_clock_label = _label(Time.get_time_string_from_system().left(5), 12, CLASSIC_TEXT)
	_clock_label.custom_minimum_size = Vector2(56, 0)
	_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_clock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_clock_label)
	var clock := Timer.new()
	clock.wait_time = 30
	clock.autostart = true
	clock.timeout.connect(func() -> void: _clock_label.text = Time.get_time_string_from_system().left(5))
	add_child(clock)

	_start_menu = PanelContainer.new()
	_start_menu.name = "DesktopStartMenu"
	_start_menu.theme = MAIL_THEME
	_start_menu.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_start_menu.offset_left = 18
	_start_menu.offset_top = -296
	_start_menu.offset_right = 224
	_start_menu.offset_bottom = -46
	_start_menu.z_index = 5
	_start_menu.add_theme_stylebox_override("panel", MAIL_THEME.get_stylebox("normal", "Button"))
	add_child(_start_menu)
	var menu_column := VBoxContainer.new()
	menu_column.add_theme_constant_override("separation", 4)
	_start_menu.add_child(menu_column)
	menu_column.add_child(_label("CALIBRATOR", 12, CLASSIC_MUTED))
	for app_id: String in APP_CAPTIONS:
		var launch := _button(APP_CAPTIONS[app_id])
		launch.name = app_id.capitalize() + "StartMenuButton"
		launch.icon = APP_ICON_TEXTURES[app_id]
		launch.expand_icon = true
		launch.add_theme_constant_override("icon_max_width", 24)
		launch.alignment = HORIZONTAL_ALIGNMENT_LEFT
		launch.pressed.connect(func() -> void: _open_app(app_id))
		menu_column.add_child(launch)
	_start_menu.hide()


func _open_app(app_id: String) -> void:
	_start_menu.hide()
	if _windows.has(app_id):
		_activate_app(app_id)
	else:
		_show_app(app_id)
	GameAudio.play("terminal_window_open")


func _use_app_context(app_id: String) -> void:
	_current_app = app_id
	for property: String in APP_CONTEXT:
		set(property, _windows[app_id].context[property])


func _activate_app(app_id: String) -> void:
	if not _windows.has(app_id): return
	_use_app_context(app_id)
	var window: Control = _windows[app_id].window
	window.is_minimized = false
	window.show()
	window.move_to_front()
	_refresh_taskbar()


func _minimize_app(app_id: String) -> void:
	if not _windows.has(app_id): return
	var window: Control = _windows[app_id].window
	window.stop_dragging()
	window.is_minimized = true
	window.hide()
	if _current_app == app_id: _focus_last_window()
	_refresh_taskbar()


func _close_app(app_id: String) -> void:
	if not _windows.has(app_id): return
	var entry: Dictionary = _windows[app_id]
	entry.window.hide()
	entry.window.stop_dragging()
	_workspace.remove_child(entry.window)
	entry.window.queue_free()
	_task_buttons.remove_child(entry.task)
	entry.task.queue_free()
	_windows.erase(app_id)
	if _current_app == app_id: _focus_last_window()
	_refresh_taskbar()
	GameAudio.play("terminal_window_close")


func _focus_last_window() -> void:
	_current_app = ""
	var children := _workspace.get_children()
	children.reverse()
	for child: Node in children:
		if child.get_script() == APP_WINDOW and child.visible:
			_activate_app(child.app_id)
			break


func _refresh_taskbar() -> void:
	for app_id: String in _windows:
		var entry: Dictionary = _windows[app_id]
		entry.task.set_pressed_no_signal(_current_app == app_id and entry.window.visible)
	for app_id: String in _app_buttons:
		var shortcut: Button = _app_buttons[app_id]
		var selected := app_id == _current_app
		shortcut.add_theme_stylebox_override("normal", _style(Color("164c50e6") if selected else Color.TRANSPARENT, 0, Color("75b4b5") if selected else Color.TRANSPARENT, 1 if selected else 0))
		var caption := shortcut.get_meta("caption_label") as Label
		caption.add_theme_color_override("font_color", Color("f3eee0") if selected else Color("b8cfcc"))
	_update_reading_activity()


func _update_reading_activity() -> void:
	if not _windows.has("mail"): return
	var host: Control = _windows["mail"].context["_mail_host"]
	if host.get_child_count() == 0: return
	var client := host.get_child(0) as TerminalMailClient
	client.set_reading_active(visible and _current_app == "mail" and _windows["mail"].window.visible)


func _fit_desktop_windows() -> void:
	for entry: Dictionary in _windows.values():
		entry.window.fit_to_workspace()


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
	if not APP_CAPTIONS.has(app_id): return
	if not _windows.has(app_id): _create_app_window(app_id)
	_activate_app(app_id)
	_render_app(app_id)


func _render_app(app_id: String) -> void:
	_clear_content()
	var is_mail := app_id == "mail"
	_scanlines.modulate.a = 0.12
	_title.visible = not is_mail
	_content_divider.visible = not is_mail
	_content_scroll.visible = not is_mail
	_mail_host.visible = is_mail
	_content_panel.add_theme_stylebox_override("panel", _style(Color("d5d2c6"), 0, Color("85867e"), 1))
	_category_panel.add_theme_stylebox_override("panel", _style(Color("d5d2c6"), 0, Color("85867e"), 2))
	for side: String in ["left", "right", "top", "bottom"]:
		_content_margin.add_theme_constant_override("margin_" + side, 6 if is_mail else 12)
	match app_id:
		"mail": _build_mail()
		"album": _build_album()
		"shop": _build_shop()
		"cases": _build_cases()
		"minigame": _build_minigame()
		_: _build_system()
	_refresh_app_chrome()
	_refresh_header()
	_windows[app_id].window.fit_to_workspace.call_deferred()


func _build_mail() -> void:
	_title.text = "邮箱"
	var mails: Array = _profile.call("get_available_mail") if is_instance_valid(_profile) else []
	var client := MAIL_CLIENT.instantiate() as TerminalMailClient
	_mail_host.add_child(client)
	client.refresh_requested.connect(func() -> void: _show_app("mail"))
	client.mark_read_requested.connect(func(mail_id: String) -> void: _profile.call("mark_mail_read", mail_id))
	client.case_requested.connect(_on_mail_case_pressed)
	client.replay_requested.connect(_start_case)
	client.mail_selected.connect(func(mail_id: String) -> void: _selected_mail_id = mail_id)
	var completed: Dictionary = _profile.get("completed_cases") if is_instance_valid(_profile) else {}
	client.configure(mails, completed, _mail_folder, _selected_mail_id)
	_selected_mail_id = client.selected_mail_id
	_update_reading_activity()


func _accept_case(mail_id: String) -> void:
	var case_id := String(_profile.call("accept_mail", mail_id))
	if case_id.is_empty():
		return
	GameAudio.play("paper_confirm")
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
		var card := _classic_panel()
		card.custom_minimum_size = Vector2(0, 128)
		_content.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 18)
		card.add_child(row)
		var image_panel := ColorRect.new()
		image_panel.custom_minimum_size = Vector2(190, 112)
		image_panel.color = Color("aeb4ad")
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
		var album_title := _label(String(entry.get("title", "现场记录")), 14, CLASSIC_TEXT)
		album_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(album_title)
		var description := _label(String(entry.get("description", "")), 12, CLASSIC_MUTED)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(description)


func _build_shop() -> void:
	_title.text = "设备商店"
	_content.add_child(_empty("空间扩建按房间地块计算。先点击对应楼层的“扩建”，再购买刚解锁的房间；购买后地块会立即出现在工作室。"))
	_build_expansion_card(0)
	_build_expansion_card(1)
	var furniture_title := _label("家具与功能设备", 14, CLASSIC_TEXT)
	_content.add_child(furniture_title)
	for value: Variant in _profile.call("get_shop_items"):
		var item := value as Dictionary
		var card := _classic_panel()
		_content.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		card.add_child(row)
		var furniture_icon := TextureRect.new()
		furniture_icon.name = "FurnitureIcon"
		furniture_icon.custom_minimum_size = Vector2(64, 64)
		furniture_icon.texture = FURNITURE_ICONS.get_icon(String(item.get("furniture_kind", "")))
		furniture_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		furniture_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		furniture_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(furniture_icon)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(copy)
		var item_title := _label(String(item.get("display_name", "设备")), 14, CLASSIC_TEXT)
		item_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(item_title)
		var description := _label(String(item.get("description", "")), 12, CLASSIC_MUTED)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(description)
		var buy := _button("购买  ¥%d" % int(item.get("price", 0)))
		buy.custom_minimum_size = Vector2(132, 32)
		buy.disabled = not bool(item.get("is_unlocked", false)) or int(_profile.get("money")) < int(item.get("price", 0))
		if not bool(item.get("is_unlocked", false)):
			buy.text = "完成案件后解锁"
		buy.pressed.connect(func() -> void:
			var purchased := bool(_profile.call("purchase_item", String(item.get("item_id", ""))))
			GameAudio.play("shop_purchase" if purchased else "terminal_unavailable")
			_show_app("shop")
		)
		GameAudio.bind_button(buy, "")
		row.add_child(buy)


func _build_expansion_card(floor_index: int) -> void:
	var room_count := int(_profile.call("get_studio_room_count", floor_index))
	var maximum := 4
	var floor_name := "一楼" if floor_index == 0 else "二楼"
	var card := _classic_panel()
	_content.add_child(card)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 4)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(_label("%s房间地块　%d / %d" % [floor_name, room_count, maximum], 14, CLASSIC_TEXT))
	var description := "每次购买增加一块房间，最多组成 2×2 的四房空间。"
	if floor_index == 1 and int(_profile.call("get_studio_room_count", 0)) < maximum:
		description = "一楼扩建至 4 个房间后，才能启动二楼扩建。"
	elif floor_index == 1 and room_count == 0:
		description = "先启动二楼扩建，再购买二楼第一个房间；购买后开放楼层切换。"
	var detail := _label(description, 12, CLASSIC_MUTED)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(detail)
	var action := _button("")
	action.custom_minimum_size = Vector2(220, 32)
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
		action.pressed.connect(func() -> void:
			var purchased := bool(_profile.call("purchase_studio_room", floor_index))
			GameAudio.play("shop_purchase" if purchased else "terminal_unavailable"))
		GameAudio.bind_button(action, "")
	else:
		action.text = "扩建%s" % floor_name
		action.disabled = not bool(_profile.call("can_unlock_studio_room_purchase", floor_index))
		action.pressed.connect(func() -> void:
			var unlocked := bool(_profile.call("unlock_studio_room_purchase", floor_index))
			GameAudio.play("paper_confirm" if unlocked else "terminal_unavailable"))
		GameAudio.bind_button(action, "")


func _build_cases() -> void:
	_title.text = "案件索引"
	for value: Variant in _profile.call("get_campaign_cases"):
		var item := value as Dictionary
		var completed := bool((_profile.get("completed_cases") as Dictionary).get(String(item.get("case_id", "")), false))
		var case_text := "%s\n%s · 酬劳 ¥%d" % [String(item.get("title", "案件")), "已归档" if completed else "等待邮件委托", int(item.get("reward_money", 0))]
		if completed and bool(_profile.call("has_skill", "archive_summary")):
			var album := item.get("album", {}) as Dictionary
			case_text += "\n投影归档：%s" % String(album.get("description", "暂无额外摘要。"))
		var panel := _empty(case_text)
		_content.add_child(panel)
		if completed:
			var replay := _button("重新进入现场（无重复奖励）")
			replay.pressed.connect(func() -> void:
				var flow := get_node_or_null("/root/GameFlow")
				if is_instance_valid(flow): await flow.call("start_case", String(item.get("case_id", "")))
			)
			_content.add_child(replay)


func _build_minigame() -> void:
	_title.text = "小游戏 / 信号校准"
	_content.add_child(_empty("开发中的终端小游戏。\n目前按钮唯一的功能，是确认你的鼠标还在工作。"))
	var button := _button("进行一次毫无意义的校准")
	button.pressed.connect(func() -> void: button.text = "校准结果：非常准确（大概）")
	_content.add_child(button)


func _build_system() -> void:
	_title.text = "系统工具"
	var skills: Array = _profile.get("active_skills") if is_instance_valid(_profile) else []
	_content.add_child(_empty("当前有效技能：\n%s\n\n技能来自已摆放的功能家具。将家具收起后，能力会立即停止。" % ["、".join(skills) if not skills.is_empty() else "无"]))
	_content.add_child(_empty("存档管理\n重置会清空工作室、金钱、商店、邮件、相册与所有案件进度。"))
	var reset_button := _button("重置全部游戏进度")
	reset_button.name = "ResetGameProgressButton"
	reset_button.custom_minimum_size = Vector2(240, 32)
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
	var active_app := _current_app
	# Refresh running apps without opening or restoring a hidden window.
	for app_id: String in _windows:
		if app_id == "minigame": continue
		_use_app_context(app_id)
		if app_id == "mail" and _mail_host.get_child_count() > 0:
			var client := _mail_host.get_child(0) as TerminalMailClient
			client.configure(_profile.call("get_available_mail"), _profile.get("completed_cases"), _mail_folder, _selected_mail_id)
			_selected_mail_id = client.selected_mail_id
		else:
			_render_app(app_id)
	if not active_app.is_empty():
		_use_app_context(active_app)
	else:
		_current_app = ""
	_refresh_taskbar()


func _refresh_header() -> void:
	if is_instance_valid(_money_label) and is_instance_valid(_profile):
		_money_label.text = "账户余额  ¥%d" % int(_profile.get("money"))
	if is_instance_valid(_mail_button) and is_instance_valid(_profile):
		var unread := int(_profile.call("get_unread_mail_count"))
		if is_instance_valid(_mail_badge):
			_mail_badge.visible = unread > 0
		_mail_button.tooltip_text = "邮箱 · 有新邮件" if unread > 0 else "邮箱"


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
	# Desktop shortcuts use short captions; the tooltip and window keep full names.
	var label := _label(String(APP_CAPTIONS.get(app_id, text_value)), 12, Color("d8e8e4"))
	label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_left = 4
	label.offset_right = -4
	label.offset_top = -24
	label.offset_bottom = -3
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	button.set_meta("caption_label", label)
	if app_id == "mail":
		_mail_badge = Panel.new()
		_mail_badge.name = "MailUnreadDot"
		_mail_badge.set_anchors_preset(Control.PRESET_CENTER_TOP)
		_mail_badge.offset_left = 22
		_mail_badge.offset_right = 32
		_mail_badge.offset_top = 8
		_mail_badge.offset_bottom = 18
		var dot := StyleBoxFlat.new()
		dot.bg_color = Color("ba4543")
		dot.set_corner_radius_all(5)
		_mail_badge.add_theme_stylebox_override("panel", dot)
		_mail_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(_mail_badge)
	_app_buttons[app_id] = button
	GameAudio.bind_button(button, "")
	button.pressed.connect(func() -> void: _open_app(app_id))
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
		_window_title.text = String(title_parts[0])
	if is_instance_valid(_window_icon):
		_window_icon.texture = APP_ICON_TEXTURES.get(_current_app, APP_ICON_TEXTURES["system"]) as Texture2D
	_rebuild_category_panel()


func _rebuild_category_panel() -> void:
	if not is_instance_valid(_category_column):
		return
	for child: Node in _category_column.get_children():
		_category_column.remove_child(child)
		child.queue_free()
	if _current_app == "mail":
		_build_mail_folders()
		return
	var rows: Array[Array] = []
	match _current_app:
		"album": rows = [["现场照片", "结案快照"], ["复原记录", "空间档案"], ["归档", "已完成"]]
		"shop": rows = [["功能设备", "工作室能力"], ["家具", "空间陈设"], ["扩建", "楼层地块"]]
		"cases": rows = [["待调查", "邮件委托"], ["已完成", "案件归档"], ["复盘", "重新进入"]]
		"minigame": rows = [["信号输入", "终端通道"], ["校准记录", "实验数据"], ["帮助", "操作说明"]]
		_: rows = [["存档管理", "本地数据"], ["技能状态", "设备能力"], ["关于终端", "版本信息"]]
	for index: int in rows.size():
		var row_data := rows[index]
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(0, 58)
		var sidebar_style := MAIL_THEME.get_stylebox("panel", "Tree").duplicate() as StyleBoxTexture
		sidebar_style.modulate_color = Color("e0e4df") if index == 0 else Color.WHITE
		panel.add_theme_stylebox_override("panel", sidebar_style)
		_category_column.add_child(panel)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		panel.add_child(row)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(20, 24)
		icon.texture = FOLDER_ICON_TEXTURES[index]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(copy)
		var category_title := _label(String(row_data[0]), 12, CLASSIC_TEXT)
		category_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(category_title)
		var category_detail := _label(String(row_data[1]), 9, CLASSIC_MUTED)
		category_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(category_detail)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_category_column.add_child(spacer)
	var terminal_note := _label("CALIBRATOR\nLOCAL ARCHIVE", 9, Color("526a68"))
	terminal_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_category_column.add_child(terminal_note)

func _build_mail_folders() -> void:
	for index: int in 3:
		var folder: String = ["inbox", "read", "archived"][index]
		var button := Button.new()
		button.name = "MailFolder" + folder.capitalize() + "Button"
		button.theme = MAIL_THEME
		button.text = TerminalMailClient.FOLDER_NAMES[folder]
		button.icon = FOLDER_ICON_TEXTURES[index]
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 20)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = _mail_folder == folder
		button.custom_minimum_size = Vector2(0, 34)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(func() -> void:
			_mail_folder = folder
			_show_app("mail"))
		_category_column.add_child(button)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_category_column.add_child(spacer)
	var terminal_note := _label("CALIBRATOR\nLOCAL ARCHIVE", 9, Color("526a68"))
	terminal_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_category_column.add_child(terminal_note)


func _clear_content() -> void:
	for host: Control in [_content, _mail_host]:
		for child: Node in host.get_children():
			host.remove_child(child)
			child.queue_free()


func _classic_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var inset := MAIL_THEME.get_stylebox("panel", "Tree").duplicate() as StyleBoxTexture
	inset.content_margin_left = 10
	inset.content_margin_right = 10
	inset.content_margin_top = 10
	inset.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", inset)
	return panel


func _empty(text_value: String) -> PanelContainer:
	var panel := _classic_panel()
	panel.custom_minimum_size = Vector2(0, 92)
	var label := _label(text_value, 13, CLASSIC_TEXT)
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


func _button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.theme = MAIL_THEME
	button.add_theme_font_size_override("font_size", 12)
	button.custom_minimum_size = Vector2(0, 32)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
