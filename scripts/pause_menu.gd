extends CanvasLayer


const START_MENU_SCENE := "res://scenes/start_menu/start_menu_office.tscn"
const INVESTIGATION_ATLAS: Texture2D = preload("res://assets/ui/studio_dossier/investigation_atlas.png")
const PAUSE_PAPER_REGION := Rect2(16, 12, 596, 291)
const PAUSE_BUTTON_REGION := Rect2(626, 234, 229, 70)

var overlay: Control
var panel: PanelContainer
var continue_button: Button
var return_button: Button
var exit_button: Button
var _returning_to_menu := false


func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	var transition := get_node_or_null("/root/SceneTransition")
	if is_instance_valid(transition) and transition.has_signal("transition_started"):
		transition.transition_started.connect(_on_transition_started)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or event.keycode != KEY_ESCAPE:
		return
	if is_open():
		close_pause_menu()
		get_viewport().set_input_as_handled()
	elif open_pause_menu():
		get_viewport().set_input_as_handled()


func is_open() -> bool:
	return is_instance_valid(overlay) and overlay.visible


func open_pause_menu() -> bool:
	if is_open() or _returning_to_menu or _is_start_menu_active() or _is_scene_transitioning():
		return false
	overlay.visible = true
	overlay.move_to_front()
	get_tree().paused = true
	GameAudio.play("dossier_open")
	continue_button.grab_focus()
	return true


func close_pause_menu() -> void:
	if not is_open() or _returning_to_menu:
		return
	get_tree().paused = false
	overlay.visible = false
	GameAudio.play("dossier_close")


func _on_continue_pressed() -> void:
	close_pause_menu()


func _on_return_to_start_pressed() -> void:
	if _returning_to_menu:
		return
	_returning_to_menu = true
	_set_buttons_disabled(true)
	get_tree().paused = false
	overlay.visible = false
	var flow := get_node_or_null("/root/GameFlow")
	var succeeded := is_instance_valid(flow) and bool(await flow.call("return_to_start_menu"))
	_returning_to_menu = false
	_set_buttons_disabled(false)
	if not succeeded and not _is_start_menu_active():
		overlay.visible = true
		get_tree().paused = true
		continue_button.grab_focus()


func _on_exit_pressed() -> void:
	get_tree().paused = false
	GameAudio.stop_all()
	get_tree().quit()


func _on_transition_started(_scene_path: String) -> void:
	# A scene transition must never inherit a paused SceneTree. This also keeps
	# the title screen interactive if another system initiates the transition.
	get_tree().paused = false
	if is_instance_valid(overlay):
		overlay.visible = false


func _is_start_menu_active() -> bool:
	var current := get_tree().current_scene
	return is_instance_valid(current) and current.scene_file_path == START_MENU_SCENE


func _is_scene_transitioning() -> bool:
	var transition := get_node_or_null("/root/SceneTransition")
	return is_instance_valid(transition) and bool(transition.get("is_transitioning"))


func _set_buttons_disabled(value: bool) -> void:
	if is_instance_valid(continue_button):
		continue_button.disabled = value
	if is_instance_valid(return_button):
		return_button.disabled = value
	if is_instance_valid(exit_button):
		exit_button.disabled = value


func _build_ui() -> void:
	overlay = Control.new()
	overlay.name = "PauseOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	add_child(overlay)

	var backdrop := ColorRect.new()
	backdrop.name = "PauseBackdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.019608, 0.015686, 0.011765, 0.82)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(backdrop)

	panel = PanelContainer.new()
	panel.name = "PauseWindow"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -350.0
	panel.offset_right = 350.0
	panel.offset_top = -215.0
	panel.offset_bottom = 215.0
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	overlay.add_child(panel)

	var note := Control.new()
	note.name = "PausePaperRoot"
	panel.add_child(note)
	var paper := TextureRect.new()
	paper.name = "PausePaper"
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.texture = _atlas_texture(PAUSE_PAPER_REGION)
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.add_child(paper)

	var title := Label.new()
	title.name = "GameTitle"
	title.text = "错位现场"
	title.position = Vector2(110, 74)
	title.size = Vector2(500, 48)
	title.add_theme_font_size_override("font_size", 31)
	title.add_theme_color_override("font_color", Color(0.19, 0.125, 0.085, 1))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.add_child(title)

	var english_title := Label.new()
	english_title.name = "EnglishTitle"
	english_title.text = "GAME PAUSED  /  SCENE CALIBRATION"
	english_title.position = Vector2(112, 122)
	english_title.size = Vector2(500, 24)
	english_title.add_theme_font_size_override("font_size", 12)
	english_title.add_theme_color_override("font_color", Color(0.42, 0.31, 0.22, 1))
	english_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.add_child(english_title)

	var message := Label.new()
	message.name = "PauseMessage"
	message.text = "调查暂时中止，当前进度已经保存。"
	message.position = Vector2(112, 153)
	message.size = Vector2(500, 34)
	message.add_theme_font_size_override("font_size", 16)
	message.add_theme_color_override("font_color", Color(0.27, 0.195, 0.14, 1))
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.add_child(message)

	continue_button = _menu_button("继续游戏", "✓")
	continue_button.name = "ContinueButton"
	continue_button.position = Vector2(73, 205)
	continue_button.size = Vector2(267, 80)
	continue_button.pressed.connect(_on_continue_pressed)
	note.add_child(continue_button)

	return_button = _menu_button("回到开始界面", "↩")
	return_button.name = "ReturnToStartButton"
	return_button.position = Vector2(358, 205)
	return_button.size = Vector2(267, 80)
	return_button.pressed.connect(_on_return_to_start_pressed)
	note.add_child(return_button)

	exit_button = _menu_button("退出游戏", "×")
	exit_button.name = "ExitGameButton"
	exit_button.position = Vector2(215, 300)
	exit_button.size = Vector2(267, 80)
	exit_button.pressed.connect(_on_exit_pressed)
	note.add_child(exit_button)


func _menu_button(text_value: String, symbol: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 19)
	for color_name: String in ["font_color", "font_focus_color", "font_pressed_color", "font_hover_color"]:
		button.add_theme_color_override(color_name, Color(0.19, 0.125, 0.085, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.45, 0.39, 0.32, 1))
	button.add_theme_stylebox_override("normal", _button_style(Color.WHITE))
	button.add_theme_stylebox_override("hover", _button_style(Color(1.1, 1.06, 0.93, 1)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.88, 0.82, 0.72, 1)))
	button.add_theme_stylebox_override("disabled", _button_style(Color(0.82, 0.79, 0.73, 1)))
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color(0.35, 0.16, 0.13, 0.85)
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	var icon := Label.new()
	icon.text = symbol
	icon.name = "PaperSymbol"
	icon.position = Vector2(24, 24)
	icon.size = Vector2(34, 32)
	icon.add_theme_font_size_override("font_size", 20)
	icon.add_theme_color_override("font_color", Color(0.19, 0.125, 0.085, 1))
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)
	return button


func _atlas_texture(region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = INVESTIGATION_ATLAS
	texture.region = region
	return texture


func _button_style(tint: Color) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = _atlas_texture(PAUSE_BUTTON_REGION)
	style.modulate_color = tint
	return style
