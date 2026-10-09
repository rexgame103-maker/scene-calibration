extends "res://scripts/start_menu.gd"

@export_group("循环镜头")
## StartCamera 的场景位置和角度作为起点，沿镜头前方缓慢推进后返回。
@export_range(0.0,2.0,0.05) var loop_push_in_distance := 0.45
@export_range(8.0,120.0,1.0) var travel_cycle_seconds := 48.0
@export_range(0.0,0.5,0.01) var sway_distance := 0.025
@export_range(0.0,3.0,0.05) var sway_rotation_degrees := 0.22
@export_range(0.0,3.0,0.1) var sway_roll_degrees := 0.12
@export var camera_motion_enabled := true

var motion_time := 0.0
var _camera_base_transform := Transform3D.IDENTITY
var _settings: Control
var _continue: Button
var _menu_buttons: Array[Button] = []
var _language_selector: OptionButton
const OPTIONS_PATH := "user://the_scene_options.cfg"

func _ready() -> void:
	# Keep the editor-authored framing; animate offsets without accumulating drift.
	_camera_base_transform = start_camera.transform
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
	GameAudio.set_ambience("amb_studio")
	_build_settings()
	GameLanguage.language_changed.connect(_on_language_changed)
	_on_language_changed(GameLanguage.current_language)
	get_viewport().size_changed.connect(_layout)
	_layout()
	update_camera(0.0)
	_reset_confirm_button.text="✓  重置进度并开始"
	GameAudio.bind_button(_reset_confirm_button, "paper_confirm")
	(_reset_overlay.get_node("Note/TitleLabel") as Label).text="开始新游戏？"

func _has_save() -> bool:
	if not FileAccess.file_exists("user://calibrator_profile.json"): return false
	return JSON.parse_string(FileAccess.get_file_as_string("user://calibrator_profile.json")) is Dictionary

func _process(delta: float) -> void:
	if _starting_game: return
	if camera_motion_enabled:
		motion_time+=delta
	else:
		motion_time=0.0
	update_camera(motion_time)

func update_camera(time: float) -> void:
	if not camera_motion_enabled:
		start_camera.transform = _camera_base_transform
		return
	var phase := (1.0-cos(time*TAU/maxf(travel_cycle_seconds,1.0)))*0.5
	var offset := Vector3(
		sin(time*0.44)*sway_distance,
		sin(time*0.31)*sway_distance*0.48,
		-loop_push_in_distance*phase)
	var rotation_offset := Vector3(
		deg_to_rad(sway_rotation_degrees)*sin(time*0.31)*0.6,
		deg_to_rad(sway_rotation_degrees)*sin(time*0.23),
		deg_to_rad(sway_roll_degrees)*sin(time*0.19))
	start_camera.transform = _camera_base_transform * Transform3D(Basis.from_euler(rotation_offset), offset)

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
	camera_motion_enabled=bool(config.get_value("display","camera_motion",camera_motion_enabled))
	AudioServer.set_bus_volume_db(0,linear_to_db(float(config.get_value("audio","volume",0.8))))
	if bool(config.get_value("display","fullscreen",false)):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _save_options() -> void:
	var config := ConfigFile.new()
	config.load(OPTIONS_PATH)
	config.set_value("display","camera_motion",camera_motion_enabled)
	config.set_value("display","fullscreen",DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN)
	config.set_value("audio","volume",db_to_linear(AudioServer.get_bus_volume_db(0)))
	if AudioServer.is_bus_mute(0):
		config.set_value("audio", "volume", 0.0)
	config.set_value("audio", "effects", GameAudio.get_level("effects"))
	config.set_value("audio", "ambience", GameAudio.get_level("ambience"))
	config.set_value("audio", "hover_sounds", GameAudio.hover_sounds_enabled)
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
	panel.position=Vector2(365,45)
	panel.size=Vector2(550,630)
	panel.add_theme_stylebox_override("panel",_panel_style(Color("211d17"),Color("9e8760")))
	_settings.add_child(panel)
	var margin := MarginContainer.new()
	margin.name="Margin"
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,26)
	panel.add_child(margin)
	var col := VBoxContainer.new()
	col.name="Column"
	col.add_theme_constant_override("separation",12)
	margin.add_child(col)
	var title := Label.new()
	title.name="Title"
	title.text="设置"
	title.add_theme_font_size_override("font_size",30)
	col.add_child(title)
	var language_row := HBoxContainer.new()
	language_row.name="LanguageRow"
	language_row.add_theme_constant_override("separation",20)
	col.add_child(language_row)
	var language_title := Label.new()
	language_title.text="语言"
	language_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	language_row.add_child(language_title)
	_language_selector=OptionButton.new()
	_language_selector.name="LanguageSelector"
	_language_selector.auto_translate_mode=Node.AUTO_TRANSLATE_MODE_DISABLED
	_language_selector.custom_minimum_size=Vector2(225,42)
	_language_selector.add_item("English")
	_language_selector.add_item("简体中文")
	_language_selector.select(GameLanguage.LANGUAGES.find(GameLanguage.current_language))
	_language_selector.item_selected.connect(func(index: int) -> void:
		GameLanguage.set_language(GameLanguage.LANGUAGES[index]))
	language_row.add_child(_language_selector)
	var volume_title := Label.new()
	volume_title.text="主音量"
	col.add_child(volume_title)
	var volume := HSlider.new()
	volume.max_value=1.0
	volume.step=0.01
	volume.value=0.0 if AudioServer.is_bus_mute(0) else db_to_linear(AudioServer.get_bus_volume_db(0))
	volume.value_changed.connect(func(value: float):
		AudioServer.set_bus_mute(0, value <= 0.0)
		AudioServer.set_bus_volume_db(0,linear_to_db(maxf(value, 0.0001)))
		_save_options())
	col.add_child(volume)
	for channel: String in ["effects", "ambience"]:
		var audio_title := Label.new()
		audio_title.text = "音效音量" if channel == "effects" else "环境音量"
		col.add_child(audio_title)
		var audio_slider := HSlider.new()
		audio_slider.name = "EffectsVolume" if channel == "effects" else "AmbienceVolume"
		audio_slider.max_value = 1.0
		audio_slider.step = 0.01
		audio_slider.value = GameAudio.get_level(channel)
		audio_slider.value_changed.connect(func(value: float) -> void:
			GameAudio.set_level(channel, value)
			_save_options())
		col.add_child(audio_slider)
	var hover_sound := CheckButton.new()
	hover_sound.text = "鼠标悬停音效"
	hover_sound.button_pressed = GameAudio.hover_sounds_enabled
	hover_sound.toggled.connect(func(value: bool) -> void:
		GameAudio.hover_sounds_enabled = value
		_save_options())
	col.add_child(hover_sound)
	var fullscreen := CheckButton.new()
	fullscreen.text="全屏显示"
	fullscreen.button_pressed=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen.toggled.connect(func(value: bool):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED)
		_save_options())
	col.add_child(fullscreen)
	var movement := CheckButton.new()
	movement.name="CameraMotion"
	movement.text="背景镜头运动"
	movement.button_pressed=camera_motion_enabled
	movement.toggled.connect(func(value: bool):
		camera_motion_enabled=value
		motion_time=0.0
		update_camera(motion_time)
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


func _on_language_changed(language: String) -> void:
	if is_instance_valid(_language_selector):
		_language_selector.select(GameLanguage.LANGUAGES.find(language))
	# English titles need a smaller font to fit the existing left-hand menu.
	var title := $StartMenuUI/UIRoot/Title as Label
	title.clip_text=true
	title.size=Vector2(430,85)
	var font := title.get_theme_font("font")
	var font_size := 60
	while font_size > 28 and font.get_string_size(tr(title.text), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > title.size.x:
		font_size -= 1
	title.add_theme_font_size_override("font_size",font_size)
