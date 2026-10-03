extends CanvasLayer


signal transition_started(scene_path: String)
signal transition_finished(scene_path: String)

const DEFAULT_FADE_IN_DURATION := 0.85

var is_transitioning := false
var fade_overlay: ColorRect
var _active_tween: Tween


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	fade_overlay = ColorRect.new()
	fade_overlay.name = "FadeOverlay"
	fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_overlay.color = Color.BLACK
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fade_overlay)
	call_deferred("_fade_in_initial_scene")


func transition_to_scene(
	scene_path: String,
	camera: Camera3D = null,
	pullback_distance := 6.5,
	fade_out_duration := 1.2,
	fade_in_duration := 0.9
) -> bool:
	if is_transitioning:
		return false
	if not ResourceLoader.exists(scene_path):
		push_error("Transition target scene does not exist: %s" % scene_path)
		return false

	is_transitioning = true
	transition_started.emit(scene_path)
	_stop_active_tween()
	fade_overlay.visible = true
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var fade_out := create_tween()
	_active_tween = fade_out
	fade_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_out.set_parallel(true)
	fade_out.set_trans(Tween.TRANS_CUBIC)
	fade_out.set_ease(Tween.EASE_IN_OUT)
	fade_out.tween_property(fade_overlay, "color:a", 1.0, maxf(0.01, fade_out_duration))

	if is_instance_valid(camera):
		var pulled_back_transform := camera.global_transform
		pulled_back_transform.origin += camera.global_basis.z.normalized() * pullback_distance
		fade_out.tween_property(
			camera,
			"global_transform",
			pulled_back_transform,
			maxf(0.01, fade_out_duration)
		)

	await fade_out.finished
	_active_tween = null

	var change_error := get_tree().change_scene_to_file(scene_path)
	if change_error != OK:
		push_error("Failed to change scene to %s (error %s)" % [scene_path, change_error])
		await _fade_overlay_to(0.0, 0.25)
		is_transitioning = false
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return false

	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_overlay_to(0.0, maxf(0.01, fade_in_duration))
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false
	transition_finished.emit(scene_path)
	return true


func _fade_in_initial_scene() -> void:
	await get_tree().process_frame
	if is_transitioning:
		return
	await _fade_overlay_to(0.0, DEFAULT_FADE_IN_DURATION)
	if not is_transitioning:
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _fade_overlay_to(alpha: float, duration: float) -> void:
	_stop_active_tween()
	var tween := create_tween()
	_active_tween = tween
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade_overlay, "color:a", alpha, duration)
	await tween.finished
	if _active_tween == tween:
		_active_tween = null


func _stop_active_tween() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null
