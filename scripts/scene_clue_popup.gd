class_name SceneCluePopup
extends Control

signal closed
const BLUR_END := 0.45
const IMAGE_END := 1.05
const LINE_END := 1.65
var title_label: Label
var description_label: RichTextLabel
var collect_button: Button
var backdrop: ColorRect
var picture: Panel
var photo: TextureRect
var copy: Control
var hint: Label
var point: SceneCluePoint
var elapsed := 0.0
var speed := 1.0
var text_duration := 1.0
var exiting := false
var exit_elapsed := 0.0
var anchor := Vector2.ZERO
var picture_home := Vector2.ZERO
var copy_home := Vector2.ZERO
var line_points := PackedVector2Array()
var line_progress := 0.0
var line_alpha := 1.0
var line_offset := Vector2.ZERO
var capture_view: SubViewport
var connector: Line2D

func _ready() -> void:
	name = "SceneCluePopup"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	add_to_group("scene_clue_ui")
	_build_ui()
	resized.connect(_layout)

func show_point(value: SceneCluePoint) -> bool:
	if visible: return false
	point = value
	var camera := get_viewport().get_camera_3d()
	anchor = camera.unproject_position(point.global_position) if camera != null else size * 0.5
	title_label.text = point.title
	description_label.text = point.description
	text_duration = maxf(0.8, point.description.length() / 24.0)
	elapsed = 0.0
	speed = 1.0
	exiting = false
	exit_elapsed = 0.0
	photo.texture = null
	collect_button.hide()
	collect_button.disabled = false
	hint.modulate.a = 1.0
	hint.text = "点击空白处加速"
	visible = true
	move_to_front()
	_layout()
	_apply_intro()
	_capture_detail(camera)
	return true

func _capture_detail(camera: Camera3D) -> void:
	if camera == null or DisplayServer.get_name() == "headless": return
	# Separate camera provides a sharp close-up without moving the main view.
	capture_view = SubViewport.new()
	capture_view.size = Vector2i(640, 640)
	capture_view.world_3d = camera.get_world_3d()
	capture_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	capture_view.msaa_3d = Viewport.MSAA_4X
	add_child(capture_view)
	var detail_camera := Camera3D.new()
	capture_view.add_child(detail_camera)
	detail_camera.environment = camera.environment
	detail_camera.fov = 36.0
	detail_camera.near = 0.025
	var target := point.global_position
	var direction := (camera.global_position - target).normalized()
	if not point.detail_view_offset.is_zero_approx():
		direction = (point.global_basis.orthonormalized() * point.detail_view_offset).normalized()
	detail_camera.global_position = target + direction * point.detail_view_distance
	detail_camera.look_at(target, Vector3.UP)
	detail_camera.current = true
	detail_camera.cull_mask &= ~(1 << 19)
	photo.texture = capture_view.get_texture()

func _layout() -> void:
	if not is_instance_valid(picture): return
	var side := minf(size.y * 0.34, size.x * 0.28)
	picture.size = Vector2.ONE * side
	picture_home = Vector2(size.x * 0.17, size.y * 0.48)
	copy_home = picture_home + Vector2(side + 30, side * 0.39)
	copy.size = Vector2(minf(size.x * 0.37, size.x-copy_home.x-28), side)
	title_label.size = Vector2(copy.size.x, 35)
	description_label.position = Vector2(0, 42)
	description_label.size = Vector2(copy.size.x, maxf(100, side * 0.50))
	collect_button.size = Vector2(170, 42)
	collect_button.position = Vector2(
		maxf(0, copy.size.x - collect_button.size.x),
		description_label.position.y + description_label.get_content_height() + 18
	)
	hint.position = Vector2(0, size.y - 42)
	hint.size = Vector2(size.x, 30)
	var start := picture_home + Vector2(side, side * 0.30)
	var end := Vector2(clampf(anchor.x,20,size.x-20),clampf(anchor.y,20,size.y-20))
	line_points = PackedVector2Array([start, Vector2(start.x+maxf(35,(end.x-start.x)*0.55),start.y),end])

func _process(delta: float) -> void:
	if not visible: return
	if exiting:
		exit_elapsed += delta
		var t := clampf(exit_elapsed / 0.42,0,1)
		picture.position = picture_home + Vector2(-95*t,0)
		picture.modulate.a = 1.0-t
		copy.position = copy_home + Vector2(0,65*t)
		copy.modulate.a = 1.0-t
		line_alpha = 1.0-t
		line_offset = Vector2(0,65*t)
		(backdrop.material as ShaderMaterial).set_shader_parameter("amount",1.0-t)
		hint.modulate.a = 1.0-t
		_update_line()
		if t >= 1.0: _dismiss()
	else:
		elapsed += delta * speed
		_apply_intro()

func _apply_intro() -> void:
	(backdrop.material as ShaderMaterial).set_shader_parameter("amount",clampf(elapsed/BLUR_END,0,1))
	var image_t := clampf((elapsed-BLUR_END)/(IMAGE_END-BLUR_END),0,1)
	var eased := 1.0-pow(1.0-image_t,3)
	picture.position = picture_home + Vector2(-110*(1.0-eased),0)
	picture.modulate.a = image_t
	line_progress = clampf((elapsed-IMAGE_END)/(LINE_END-IMAGE_END),0,1)
	line_alpha = 1.0
	line_offset = Vector2.ZERO
	copy.position = copy_home
	copy.modulate.a = 1.0 if elapsed >= LINE_END else 0.0
	var text_t := clampf((elapsed-LINE_END)/text_duration,0,1)
	description_label.visible_ratio = text_t
	collect_button.visible = text_t >= 1.0
	if collect_button.visible: hint.text = "阅读完毕后，收集这条线索"
	_update_line()

func _update_line() -> void:
	if not visible or line_points.size() != 3: return
	var remaining := (line_points[0].distance_to(line_points[1])+line_points[1].distance_to(line_points[2]))*line_progress
	var color := Color("a9c9ac")
	color.a = line_alpha
	connector.default_color = color
	connector.clear_points()
	connector.add_point(line_points[0]+line_offset)
	for i in range(2):
		var length := line_points[i].distance_to(line_points[i+1])
		if remaining <= 0: break
		var end := line_points[i].lerp(line_points[i+1],minf(1,remaining/maxf(length,0.001)))
		connector.add_point(end+line_offset)
		remaining -= length

func _input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if collect_button.visible and collect_button.get_global_rect().has_point(event.position):
				_collect()
			elif not picture.get_global_rect().has_point(event.position) and not copy.get_global_rect().has_point(event.position):
				accelerate()
		get_viewport().set_input_as_handled()

func accelerate() -> void:
	if visible and not exiting: speed = minf(32.0,speed*4.0)

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode in [KEY_ESCAPE,KEY_SPACE]:
		accelerate()
		get_viewport().set_input_as_handled()

func _collect() -> void:
	if exiting or not collect_button.visible: return
	if is_instance_valid(point): point.collect_clue()
	exiting = true
	exit_elapsed = 0.0
	collect_button.disabled = true

func close() -> void:
	# Programmatic completion for Debug/test callers; player uses the button.
	if not visible: return
	if not exiting and is_instance_valid(point): point.collect_clue()
	_dismiss()

func _dismiss() -> void:
	visible = false
	point = null
	photo.texture = null
	if is_instance_valid(capture_view): capture_view.queue_free()
	capture_view = null
	closed.emit()

func _build_ui() -> void:
	backdrop = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/clue_inspection_blur.gdshader")
	backdrop.material = material
	add_child(backdrop)
	connector = Line2D.new()
	connector.width = 2.5
	connector.antialiased = true
	connector.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(connector)
	picture = Panel.new()
	picture.mouse_filter = Control.MOUSE_FILTER_STOP
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("1f2e26")
	frame.border_color = Color("91ae96")
	frame.set_border_width_all(7)
	picture.add_theme_stylebox_override("panel",frame)
	add_child(picture)
	photo = TextureRect.new()
	photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	photo.offset_left = 9
	photo.offset_top = 9
	photo.offset_right = -9
	photo.offset_bottom = -9
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.add_child(photo)
	copy = Control.new()
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(copy)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size",24)
	title_label.add_theme_color_override("font_color",Color("e5ecdb"))
	title_label.add_theme_color_override("font_shadow_color",Color.BLACK)
	title_label.add_theme_constant_override("shadow_offset_y",2)
	copy.add_child(title_label)
	description_label = RichTextLabel.new()
	description_label.bbcode_enabled = false
	description_label.scroll_active = false
	description_label.add_theme_font_size_override("normal_font_size",18)
	description_label.add_theme_color_override("default_color",Color("fff3da"))
	description_label.add_theme_color_override("font_shadow_color",Color.BLACK)
	description_label.add_theme_constant_override("shadow_offset_y",2)
	copy.add_child(description_label)
	collect_button = Button.new()
	collect_button.text = "收集线索"
	collect_button.add_theme_font_size_override("font_size",18)
	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color("405e4d")
	button_style.border_color = Color("a9c9ac")
	button_style.set_border_width_all(1)
	collect_button.add_theme_stylebox_override("normal",button_style)
	collect_button.pressed.connect(_collect)
	copy.add_child(collect_button)
	hint = Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size",14)
	hint.modulate = Color("c7c6b5")
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
