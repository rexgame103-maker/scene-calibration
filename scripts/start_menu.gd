extends Node3D

const PAPER_CONFIRMATION_DIALOG := preload("res://scenes/ui/paper_confirmation_dialog.tscn")


@export_file("*.tscn") var first_level_scene := "res://scenes/studio/calibrator_studio.tscn"
@export_range(0.5, 12.0, 0.5) var camera_push_in_distance := 4.0
@export_range(0.1, 4.0, 0.05) var fade_out_duration := 1.2
@export_range(0.1, 4.0, 0.05) var fade_in_duration := 0.9

@onready var start_camera: Camera3D = $StartCamera
@onready var start_button: Button = $StartMenuUI/UIRoot/MenuLayout/MenuColumn/StartButton
@onready var exit_button: Button = $StartMenuUI/UIRoot/MenuLayout/MenuColumn/ExitButton
@onready var reset_game_button: Button = $StartMenuUI/UIRoot/ResetGameButton
@onready var ui_root: Control = $StartMenuUI/UIRoot

var _starting_game := false
var _resetting_game := false
var _reset_overlay: Control
var _reset_confirm_button: Button


func _ready() -> void:
	start_button.pressed.connect(_on_start_game_pressed)
	exit_button.pressed.connect(_on_exit_game_pressed)
	reset_game_button.pressed.connect(_open_reset_confirmation)
	_build_reset_confirmation()
	start_button.grab_focus()


func _on_start_game_pressed() -> void:
	if _starting_game or _resetting_game:
		return
	var transition := get_node_or_null("/root/SceneTransition")
	if not is_instance_valid(transition):
		push_error("SceneTransition Autoload is missing")
		return

	_starting_game = true
	start_button.disabled = true
	exit_button.disabled = true
	transition.call(
		"transition_to_scene",
		first_level_scene,
		start_camera,
		-camera_push_in_distance,
		fade_out_duration,
		fade_in_duration
	)


func _on_exit_game_pressed() -> void:
	if _starting_game or _resetting_game:
		return
	GameAudio.stop_all()
	get_tree().quit()


func _build_reset_confirmation() -> void:
	_reset_overlay = PAPER_CONFIRMATION_DIALOG.instantiate() as Control
	_reset_overlay.name = "ResetGameConfirmation"
	_reset_overlay.z_index = 20
	ui_root.add_child(_reset_overlay)
	(_reset_overlay.get_node("Note/TitleLabel") as Label).text = "重置全部游戏进度？"
	var cancel_button := _reset_overlay.get_node("Note/CancelButton") as Button
	cancel_button.pressed.connect(_close_reset_confirmation)
	_reset_confirm_button = _reset_overlay.get_node("Note/ConfirmButton") as Button
	_reset_confirm_button.pressed.connect(_confirm_global_reset)


func _open_reset_confirmation() -> void:
	if _starting_game or _resetting_game:
		return
	_reset_overlay.visible = true
	_reset_overlay.move_to_front()
	(_reset_overlay.get_node("Note/CancelButton") as Button).grab_focus()


func _close_reset_confirmation() -> void:
	if _resetting_game:
		return
	_reset_overlay.visible = false
	start_button.grab_focus()


func _confirm_global_reset() -> void:
	if _resetting_game:
		return
	_resetting_game = true
	_reset_confirm_button.disabled = true
	start_button.disabled = true
	exit_button.disabled = true
	reset_game_button.disabled = true
	var flow := get_node_or_null("/root/GameFlow")
	var succeeded := is_instance_valid(flow) and bool(await flow.call("reset_game_progress", false, true))
	_resetting_game = false
	_reset_confirm_button.disabled = false
	start_button.disabled = false
	exit_button.disabled = false
	reset_game_button.disabled = false
	_reset_overlay.visible = false
	if succeeded:
		reset_game_button.text = "✓  游戏进度已重置"
	else:
		reset_game_button.text = "重置失败，请重试"


func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(_reset_overlay) and _reset_overlay.visible and event.pressed and event.keycode == KEY_ESCAPE:
		_close_reset_confirmation()
		get_viewport().set_input_as_handled()


func _dialog_button(text_value: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 46)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_stylebox_override("normal", _button_style(color))
	button.add_theme_stylebox_override("hover", _button_style(color.lightened(0.08)))
	button.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.10)))
	return button


func _panel_style(color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(20)
	style.shadow_color = Color("00000099")
	style.shadow_size = 18
	return style


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(10)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
