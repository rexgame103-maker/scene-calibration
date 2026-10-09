extends Node

## Shared sound bank, bounded playback pools and scene ambience.
## Gameplay calls this after its existing eligibility/visibility checks.
signal sound_played(event_id: String, spatial: bool, position: Vector3)
signal ambience_changed(event_id: String)

const BANK_PATH := "res://assets/audio/scene_calibration/sound_bank.json"
const OPTIONS_PATH := "user://the_scene_options.cfg"
const MAX_UI_VOICES := 16
const MAX_WORLD_VOICES := 12
const PLACE_SOUNDS := {
	"desk": "place_wood", "studio_desk": "place_wood", "restoration_table": "place_wood",
	"chair": "place_chair", "studio_chair": "place_chair", "stool": "place_chair",
	"shelf": "place_cabinet", "small_cabinet": "place_cabinet", "studio_bookshelf": "place_cabinet",
	"small_shelf": "place_cabinet", "restoration_stool": "place_chair",
	"studio_window_bookcase": "place_cabinet", "archive_cabinet": "place_cabinet",
	"folder": "place_paper", "folder_red": "place_paper", "folder_gray": "place_paper", "folder_beige": "place_paper",
	"red_file": "place_paper", "gray_file": "place_paper",
	"analysis_board": "place_paper", "studio_rug": "place_paper",
	"computer": "place_metal", "studio_computer": "place_metal", "printer": "place_metal",
	"water_dispenser": "place_metal", "studio_lamp": "place_metal", "archive_terminal": "place_metal",
	"reference_lightbox": "place_metal", "coffee_machine": "place_metal", "case_projector": "place_metal",
	"cold_light": "place_metal", "warm_light": "place_metal", "reflector": "place_metal",
	"cold_light_panel": "place_metal", "halogen_inspection_lamp": "place_metal",
	"metal_reflector": "place_metal", "camera_tripod": "place_metal",
}

var hover_sounds_enabled := false
var _events: Dictionary = {}
var _streams: Dictionary = {}
var _last_played: Dictionary = {}
var _last_variant: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _ui_voices: Array[AudioStreamPlayer] = []
var _world_voices: Array[AudioStreamPlayer3D] = []
var _ambience_players: Array[AudioStreamPlayer] = []
var _ambience_tweens: Array[Tween] = []
var _ambience_event := ""
var _ambience_slot := 0
var _levels: Dictionary = {"effects": 0.9, "ambience": 0.8}
var _paused := false
var _ambience_duck_db := 0.0
var _duck_tween: Tween
var _drag_positions: Dictionary = {}
var _notified_mail: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BANK_PATH))
	if parsed is Dictionary:
		_events = parsed.get("events", {})
	_create_bus("Effects", "Master")
	_create_bus("UI", "Effects")
	_create_bus("SFX", "Effects")
	_create_bus("Ambience", "Master")
	_load_options()
	for index: int in range(2):
		var player := AudioStreamPlayer.new()
		player.name = "Ambience%d" % index
		player.bus = "Ambience"
		add_child(player)
		_ambience_players.append(player)
		_ambience_tweens.append(null)
	get_tree().node_added.connect(_on_node_added)
	get_tree().root.close_requested.connect(stop_all)
	_bind_tree(get_tree().root)
	var transition := get_node_or_null("/root/SceneTransition")
	if transition != null:
		transition.transition_started.connect(_on_transition_started)
	var profile := get_node_or_null("/root/PlayerProfile")
	if profile != null:
		profile.mail_changed.connect(_on_mail_changed)
		# Loaded unread mail is acknowledged once when opening the terminal.
		# Profile loading/resetting itself must never generate arrival sounds.
		_remember_mail(profile)

func _process(_delta: float) -> void:
	if get_tree().paused == _paused:
		return
	_paused = get_tree().paused
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_duck_tween.tween_method(_set_ambience_duck, _ambience_duck_db, -12.0 if _paused else 0.0, 0.18)

func _exit_tree() -> void:
	stop_all()

func stop_all() -> void:
	# Release active playback references before AudioServer shuts down.
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	for index: int in range(_ambience_players.size()):
		_kill_ambience_tween(index)
		_ambience_players[index].stop()
		_ambience_players[index].stream = null
	for voice: AudioStreamPlayer in _ui_voices:
		voice.stop()
		voice.stream = null
	for voice: AudioStreamPlayer3D in _world_voices:
		voice.stop()
		voice.stream = null
	_ambience_event = ""
	_drag_positions.clear()

func play(event_id: String, world_position: Variant = null, extra_gain_db := 0.0) -> bool:
	if not _events.has(event_id):
		return false
	var event: Dictionary = _events[event_id]
	if bool(event.get("loop", false)):
		return false
	var ui_event := String(event.get("category", "")) in ["paper_ui", "terminal"]
	if get_tree().paused and not ui_event:
		return false
	var now := Time.get_ticks_msec()
	if _last_played.has(event_id) and now - int(_last_played[event_id]) < int(event.get("cooldown_ms", 0)):
		return false
	var stream := _choose_stream(event_id)
	if stream == null:
		return false
	var spatial := world_position is Vector3 and bool(event.get("spatial", false))
	var gain := float(event.get("gain_db", -8.0)) + extra_gain_db
	if spatial:
		var voice := _world_voice()
		voice.global_position = world_position
		voice.stream = stream
		voice.volume_db = gain
		voice.play()
	else:
		var voice := _ui_voice()
		voice.bus = "UI" if ui_event else "SFX"
		voice.process_mode = Node.PROCESS_MODE_ALWAYS if ui_event else Node.PROCESS_MODE_PAUSABLE
		voice.stream = stream
		voice.volume_db = gain
		voice.play()
	_last_played[event_id] = now
	sound_played.emit(event_id, spatial, world_position if spatial else Vector3.ZERO)
	return true

func play_placement(kind: String, position: Vector3) -> bool:
	var event_id := String(PLACE_SOUNDS.get(kind, "place_small"))
	if kind.begins_with("case_frame_") or kind.begins_with("studio_frame_") or kind.begins_with("folder_") or kind.begins_with("ordinary_file_"):
		event_id = "place_paper"
	elif "table" in kind or "desk" in kind or "sofa" in kind:
		event_id = "place_wood"
	elif "cabinet" in kind or "bookcase" in kind or "bookshelf" in kind:
		event_id = "place_cabinet"
	return play(event_id, position)

func begin_drag(owner_node: Node, position: Vector3) -> void:
	_drag_positions[owner_node.get_instance_id()] = position
	play("furniture_pickup", position)

func update_drag(owner_node: Node, position: Vector3, kind := "desk") -> void:
	# Small tabletop objects move through the air; they must not scrape the floor.
	if not ("desk" in kind or "table" in kind or "shelf" in kind or "cabinet" in kind or "bookcase" in kind or "sofa" in kind):
		return
	var key := owner_node.get_instance_id()
	if not _drag_positions.has(key):
		_drag_positions[key] = position
		return
	if position.distance_to(_drag_positions[key]) >= 0.8:
		if play("drag_wood", position, -3.0):
			_drag_positions[key] = position

func end_drag(owner_node: Node) -> void:
	_drag_positions.erase(owner_node.get_instance_id())

func set_ambience(event_id: String, fade_seconds := 1.0) -> void:
	if event_id == _ambience_event:
		return
	if not event_id.is_empty() and (not _events.has(event_id) or not bool(_events[event_id].get("loop", false))):
		return
	for index: int in range(2):
		_kill_ambience_tween(index)
		if _ambience_players[index].playing:
			_fade_ambience(index, -70.0, fade_seconds, true)
	_ambience_event = event_id
	if not event_id.is_empty():
		_ambience_slot = 1 - _ambience_slot
		var index := _ambience_slot
		_kill_ambience_tween(index)
		var player := _ambience_players[index]
		player.stop()
		player.stream = _choose_stream(event_id)
		player.volume_db = -70.0
		player.play()
		_fade_ambience(index, float(_events[event_id].get("gain_db", -10.0)), fade_seconds, false)
	call_deferred("_track_current_scene")
	ambience_changed.emit(event_id)

func get_ambience_event() -> String:
	return _ambience_event

func set_level(channel: String, value: float) -> void:
	if not _levels.has(channel):
		return
	_levels[channel] = clampf(value, 0.0, 1.0)
	_apply_level(channel)

func get_level(channel: String) -> float:
	return float(_levels.get(channel, 1.0))

func bind_button(button: BaseButton, event_id: String) -> void:
	button.set_meta("sound_event", event_id)
	_bind_control(button)

func _bind_tree(node: Node) -> void:
	_bind_control(node)
	for child: Node in node.get_children():
		_bind_tree(child)

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		# Dynamic panels can free a button before the deferred queue is flushed.
		# Resolve its ID later so a freed Node never reaches a typed parameter.
		call_deferred("_bind_control_id", node.get_instance_id())

func _bind_control_id(instance_id: int) -> void:
	if not is_instance_id_valid(instance_id):
		return
	var node := instance_from_id(instance_id) as Node
	if is_instance_valid(node) and node.is_inside_tree():
		_bind_control(node)

func _bind_control(node: Node) -> void:
	if not is_instance_valid(node) or not node is BaseButton or node.has_meta("sound_bound"):
		return
	var button := node as BaseButton
	button.set_meta("sound_bound", true)
	button.button_down.connect(_on_button_down.bind(button))
	button.mouse_entered.connect(_on_button_hover.bind(button))
	if button is OptionButton:
		(button as OptionButton).item_selected.connect(_on_option_selected.bind(button))

func _on_button_down(button: BaseButton) -> void:
	if not is_instance_valid(button) or button.disabled or not button.is_visible_in_tree():
		return
	var event_id := String(button.get_meta("sound_event", "terminal_click" if _inside_terminal(button) else "paper_click"))
	if not event_id.is_empty():
		play(event_id)

func _on_button_hover(button: BaseButton) -> void:
	if hover_sounds_enabled and not button.disabled and button.is_visible_in_tree() and not String(button.get_meta("sound_event", "default")).is_empty():
		play("terminal_click" if _inside_terminal(button) else "paper_hover", null, -6.0)

func _on_option_selected(_index: int, button: BaseButton) -> void:
	if button.is_visible_in_tree() and not button.disabled:
		play("terminal_click" if _inside_terminal(button) else "page_turn")

func _inside_terminal(node: Node) -> bool:
	var ancestor := node
	while ancestor != null:
		if ancestor.is_in_group("audio_terminal_ui"):
			return true
		ancestor = ancestor.get_parent()
	return false

func _choose_stream(event_id: String) -> AudioStream:
	var paths: Array = _events[event_id].get("streams", [])
	if paths.is_empty():
		return null
	var index := _rng.randi_range(0, paths.size() - 1)
	if paths.size() > 1 and int(_last_variant.get(event_id, -1)) == index:
		index = (index + 1) % paths.size()
	_last_variant[event_id] = index
	var path := String(paths[index])
	if not _streams.has(path):
		_streams[path] = load(path) as AudioStream
	return _streams[path] as AudioStream

func _ui_voice() -> AudioStreamPlayer:
	for voice: AudioStreamPlayer in _ui_voices:
		if not voice.playing:
			return voice
	if _ui_voices.size() >= MAX_UI_VOICES:
		var voice := _ui_voices.pop_front() as AudioStreamPlayer
		voice.stop()
		_ui_voices.append(voice)
		return voice
	var voice := AudioStreamPlayer.new()
	add_child(voice)
	_ui_voices.append(voice)
	return voice

func _world_voice() -> AudioStreamPlayer3D:
	for voice: AudioStreamPlayer3D in _world_voices:
		if not voice.playing:
			return voice
	if _world_voices.size() >= MAX_WORLD_VOICES:
		var voice := _world_voices.pop_front() as AudioStreamPlayer3D
		voice.stop()
		_world_voices.append(voice)
		return voice
	var voice := AudioStreamPlayer3D.new()
	voice.bus = "SFX"
	voice.process_mode = Node.PROCESS_MODE_PAUSABLE
	# The isometric camera sits well above the room. Use a gentle range so its
	# height does not make tabletop sounds inaudible or excessively panned.
	voice.unit_size = 12.0
	voice.max_distance = 60.0
	voice.panning_strength = 0.45
	add_child(voice)
	_world_voices.append(voice)
	return voice

func _create_bus(bus_name: String, send: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, send)

func _apply_level(channel: String) -> void:
	var index := AudioServer.get_bus_index("Effects" if channel == "effects" else "Ambience")
	var value := get_level(channel)
	AudioServer.set_bus_mute(index, value <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)) + (_ambience_duck_db if channel == "ambience" else 0.0))

func _load_options() -> void:
	var config := ConfigFile.new()
	config.load(OPTIONS_PATH)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(config.get_value("audio", "volume", 0.8)), 0.0001)))
	AudioServer.set_bus_mute(0, float(config.get_value("audio", "volume", 0.8)) <= 0.0)
	hover_sounds_enabled = bool(config.get_value("audio", "hover_sounds", false))
	for channel: String in _levels:
		set_level(channel, float(config.get_value("audio", channel, _levels[channel])))

func _set_ambience_duck(value: float) -> void:
	_ambience_duck_db = value
	_apply_level("ambience")

func _kill_ambience_tween(index: int) -> void:
	var tween := _ambience_tweens[index]
	if tween != null and tween.is_valid():
		tween.kill()
	_ambience_tweens[index] = null

func _fade_ambience(index: int, target: float, duration: float, stop_after: bool) -> void:
	var player := _ambience_players[index]
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(player, "volume_db", target, maxf(0.01, duration))
	if stop_after:
		tween.tween_callback(player.stop)
	_ambience_tweens[index] = tween

func _track_current_scene() -> void:
	var scene := get_tree().current_scene
	if scene != null and not scene.tree_exiting.is_connected(_on_scene_leaving):
		scene.tree_exiting.connect(_on_scene_leaving)

func _on_transition_started(_scene_path: String) -> void:
	_stop_scene_sounds()
	set_ambience("", 0.7)

func _on_scene_leaving() -> void:
	_stop_scene_sounds()
	set_ambience("", 0.3)

func _stop_scene_sounds() -> void:
	for voice: AudioStreamPlayer3D in _world_voices:
		voice.stop()
	for voice: AudioStreamPlayer in _ui_voices:
		if voice.bus == "SFX":
			voice.stop()
	_drag_positions.clear()

func _remember_mail(profile: Node) -> void:
	for value: Variant in profile.call("get_available_mail"):
		_notified_mail[String(value.get("mail_id", ""))] = true

func _on_mail_changed() -> void:
	var profile := get_node_or_null("/root/PlayerProfile")
	if profile == null:
		return
	# A full profile reset removes later mail. Forget those IDs so a subsequent
	# campaign in this session can notify them again, without beeping on reset.
	var available: Array = profile.call("get_available_mail")
	var available_ids: Dictionary = {}
	for value: Variant in available:
		available_ids[String(value.get("mail_id", ""))] = true
	for id: String in _notified_mail.keys():
		if not available_ids.has(id):
			_notified_mail.erase(id)
	var new_mail := false
	for value: Variant in available:
		var id := String(value.get("mail_id", ""))
		if not _notified_mail.has(id) and not bool(value.get("is_read", false)):
			new_mail = true
		_notified_mail[id] = true
	if new_mail:
		play("mail_arrive")
