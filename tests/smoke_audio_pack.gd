extends SceneTree

const BANK_PATH := "res://assets/audio/scene_calibration/sound_bank.json"

func _initialize() -> void:
	call_deferred("_check_audio_pack")

func _check_audio_pack() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BANK_PATH))
	if not parsed is Dictionary:
		_fail("Cannot read sound bank")
		return
	var bank: Dictionary = parsed
	var sounds: Array = bank.get("sounds", [])
	var events: Dictionary = bank.get("events", {})
	if sounds.size() != 47 or events.size() != 41:
		_fail("Incomplete audio pack: %d files, %d events" % [sounds.size(), events.size()])
		return
	var known_paths: Dictionary = {}
	var loop_count := 0
	for entry_value: Variant in sounds:
		var entry: Dictionary = entry_value
		var path := String(entry["resource"])
		var stream: AudioStreamWAV = load(path) as AudioStreamWAV
		if stream == null:
			_fail("Unimported WAV: " + path)
			return
		if stream.mix_rate != 44100 or stream.stereo != (int(entry["channels"]) == 2):
			_fail("Wrong sample rate or channel format: " + path)
			return
		if absf(stream.get_length() - float(entry["duration_seconds"])) > 0.01:
			_fail("Duration changed during import: " + path)
			return
		if bool(entry["loop"]):
			loop_count += 1
			if stream.loop_mode != AudioStreamWAV.LOOP_FORWARD:
				_fail("Ambience is not imported as a forward loop: " + path)
				return
			if stream.loop_begin != 0 or stream.loop_end <= 0:
				_fail("Invalid loop points: " + path)
				return
		elif stream.loop_mode != AudioStreamWAV.LOOP_DISABLED:
			_fail("One-shot unexpectedly loops: " + path)
			return
		known_paths[path] = true
	for event_value: Variant in events.values():
		var event: Dictionary = event_value
		var paths: Array = event.get("streams", [])
		if paths.is_empty():
			_fail("Event has no streams")
			return
		for path_value: Variant in paths:
			if not known_paths.has(String(path_value)):
				_fail("Unmapped event stream: " + String(path_value))
				return
	if loop_count != 3:
		_fail("Expected three ambience loops")
		return
	print("AUDIO_PACK_OK: 41 events, 47 imported WAVs, 3 forward loops")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
