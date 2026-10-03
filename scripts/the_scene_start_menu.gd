extends "res://scripts/start_menu.gd"

@export_group("循环镜头")
@export var camera_target := Vector3(-2.3, 1.6, -3.1)
@export var camera_direction := Vector3(0.34, 0.16, 0.927)
@export_range(3.0,12.0,0.1) var nearest_distance := 6.2
@export_range(3.0,12.0,0.1) var farthest_distance := 7.4
@export_range(8.0,90.0,1.0) var travel_cycle_seconds := 32.0
@export_range(0.0,0.5,0.01) var sway_distance := 0.16
@export_range(0.0,3.0,0.1) var sway_roll_degrees := 0.8
@export var camera_motion_enabled := true

var motion_time := 0.0
var _settings: Control
var _continue: Button
var _menu_buttons: Array[Button] = []
const OPTIONS_PATH := "user://the_scene_options.cfg"

func _ready() -> void:
	super._ready()
	start_button.release_focus()
	_continue=$StartMenuUI/UIRoot/MenuLayout/MenuColumn/ContinueButton
	_continue.pressed.connect(_continue_game)
	$StartMenuUI/UIRoot/MenuLayout/MenuColumn/SettingsButton.pressed.connect(_open_settings)
	for button in $StartMenuUI/UIRoot/MenuLayout/MenuColumn.get_children():
		if button is Button: _menu_buttons.append(button)
	_continue.disabled=not _has_save()
	_continue.tooltip_text="继续已保存的工作室与案件进度" if not _continue.disabled else "暂无存档"
	_load_options()
	_build_settings()
	get_viewport().size_changed.connect(_layout)
	_layout()
	update_camera(0.0)
	_reset_confirm_button.text="✓  重置进度并开始"
	(_reset_overlay.get_node("Note/TitleLabel") as Label).text="开始新游戏？"

func _has_save() -> bool:
	if not FileAccess.file_exists("user://calibrator_profile.json"): return false
	return JSON.parse_string(FileAccess.get_file_as_string("user://calibrator_profile.json")) is Dictionary

func _process(delta: float) -> void:
	if _starting_game: return
	if camera_motion_enabled: motion_time+=delta
	update_camera(motion_time)

func update_camera(time: float) -> void:
	var far_limit := maxf(nearest_distance,farthest_distance)
	var near_limit := minf(nearest_distance,farthest_distance)
	var phase := (1.0-cos(time*TAU/maxf(travel_cycle_seconds,1.0)))*0.5
	var distance := lerpf(far_limit,near_limit,phase)
	var drift := Vector3(sin(time*0.44)*sway_distance,sin(time*0.31)*sway_distance*0.48,0)
	var target := camera_target+drift*0.22
	var at := camera_target+camera_direction.normalized()*distance+drift
	start_camera.transform=Transform3D(Basis.IDENTITY,at).looking_at(target)
	start_camera.rotate_object_local(Vector3.FORWARD,deg_to_rad(sway_roll_degrees)*sin(time*0.23))

func _layout() -> void:
	var viewport := get_viewport().get_visible_rect().size
	var scale_factor := minf(viewport.x/1280.0,viewport.y/720.0)
	ui_root.scale=Vector2.ONE*scale_factor
	ui_root.position=(viewport-Vector2(1280,720)*scale_factor)*0.5

func _on_start_game_pressed() -> void:
	if _starting_game or _resetting_game: return
	if _has_save():
		_open_reset_confirmation()
	else:
		_enter_studio()

func _continue_game() -> void:
	if _starting_game or _resetting_game or not _has_save(): return
	_enter_studio()

func _enter_studio() -> void:
	for button in _menu_buttons: button.disabled=true
	super._on_start_game_pressed()

func _confirm_global_reset() -> void:
	if _resetting_game: return
	_resetting_game=true
	_reset_confirm_button.disabled=true
	var ok := bool(await get_node("/root/GameFlow").call("reset_game_progress",false,true))
	_resetting_game=false
	_reset_confirm_button.disabled=false
	if ok:
		_reset_overlay.hide()
		_enter_studio()
	else:
		_reset_confirm_button.text="保存失败，请重试"

func _open_settings() -> void:
	if _starting_game: return
	_settings.show()
	_settings.get_node("Panel/Margin/Column/Close").grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE and is_instance_valid(_settings) and _settings.visible:
		_settings.hide()
		start_button.grab_focus()
		get_viewport().set_input_as_handled()
	else: super._unhandled_key_input(event)

func _load_options() -> void:
	var config := ConfigFile.new()
	if config.load(OPTIONS_PATH)!=OK: return
	camera_motion_enabled=bool(config.get_value("display","camera_motion",true))
	AudioServer.set_bus_volume_db(0,linear_to_db(float(config.get_value("audio","volume",0.8))))
	if bool(config.get_value("display","fullscreen",false)):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _save_options() -> void:
	var config := ConfigFile.new()
	config.set_value("display","camera_motion",camera_motion_enabled)
	config.set_value("display","fullscreen",DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN)
	config.set_value("audio","volume",db_to_linear(AudioServer.get_bus_volume_db(0)))
	config.save(OPTIONS_PATH)

func _build_settings() -> void:
	_settings=Control.new()
	_settings.name="Settings"
	_settings.size=Vector2(1280,720)
	_settings.z_index=30
	ui_root.add_child(_settings)
	var dim := ColorRect.new()
	dim.size=Vector2(1280,720)
	dim.color=Color(0.02,0.015,0.01,0.9)
	_settings.add_child(dim)
	var panel := PanelContainer.new()
	panel.name="Panel"
	panel.position=Vector2(390,175)
	panel.size=Vector2(500,370)
	panel.add_theme_stylebox_override("panel",_panel_style(Color("211d17"),Color("9e8760")))
	_settings.add_child(panel)
	var margin := MarginContainer.new()
	margin.name="Margin"
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,26)
	panel.add_child(margin)
	var col := VBoxContainer.new()
	col.name="Column"
	col.add_theme_constant_override("separation",20)
	margin.add_child(col)
	var title := Label.new()
	title.text="设置"
	title.add_theme_font_size_override("font_size",30)
	col.add_child(title)
	var volume_title := Label.new()
	volume_title.text="主音量"
	col.add_child(volume_title)
	var volume := HSlider.new()
	volume.max_value=1.0
	volume.step=0.01
	volume.value=db_to_linear(AudioServer.get_bus_volume_db(0))
	volume.value_changed.connect(func(value: float):
		AudioServer.set_bus_volume_db(0,linear_to_db(value))
		_save_options())
	col.add_child(volume)
	var fullscreen := CheckButton.new()
	fullscreen.text="全屏显示"
	fullscreen.button_pressed=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen.toggled.connect(func(value: bool):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED)
		_save_options())
	col.add_child(fullscreen)
	var movement := CheckButton.new()
	movement.text="背景镜头运动"
	movement.button_pressed=camera_motion_enabled
	movement.toggled.connect(func(value: bool):
		camera_motion_enabled=value
		_save_options())
	col.add_child(movement)
	var close := _dialog_button("返回",Color("514332"))
	close.name="Close"
	close.focus_mode=Control.FOCUS_ALL
	close.pressed.connect(func():
		_settings.hide()
		start_button.grab_focus())
	col.add_child(close)
	_settings.hide()
