@tool
extends CanvasLayer
class_name HandDrawnPostProcess


signal effect_toggled(enabled: bool)

const HAND_DRAWN_SHADER := preload("res://shaders/hand_drawn_post_process.gdshader")

@export_category("Hand-drawn Style")
@export var effect_enabled := true
@export_range(2.0, 12.0, 1.0) var color_steps := 7.0
@export_range(0.0, 1.0, 0.01) var posterize_strength := 0.12
@export_range(0.0, 1.5, 0.01) var outline_strength := 0.18
@export_range(0.01, 0.5, 0.005) var outline_threshold := 0.105
@export_range(0.5, 3.0, 0.05) var outline_width := 1.15
@export_range(0.0, 0.25, 0.005) var paper_strength := 0.055
@export_range(0.0, 0.3, 0.005) var hatch_strength := 0.015
@export_range(0.0, 1.5, 0.01) var saturation := 0.92
@export_range(-0.3, 0.3, 0.005) var warmth := 0.065
@export_color_no_alpha var ink_color := Color("0e0a08")

@export_category("Runtime")
@export var allow_runtime_toggle := true
@export var show_toggle_hint := true

var _overlay: ColorRect
var _material: ShaderMaterial
var _hint: Label


func _ready() -> void:
	layer = 5
	if Engine.is_editor_hint():
		return
	# Screen-texture post effects are unavailable in Godot's headless test renderer.
	if DisplayServer.get_name() == "headless":
		effect_enabled = false
		return
	_build_overlay()
	_build_hint()
	_apply_parameters()
	_set_effect_enabled(effect_enabled)


func _input(event: InputEvent) -> void:
	if not allow_runtime_toggle:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F4:
		_set_effect_enabled(not effect_enabled)
		get_viewport().set_input_as_handled()


func set_effect_enabled(value: bool) -> void:
	_set_effect_enabled(value)


func is_effect_enabled() -> bool:
	return effect_enabled


func refresh_parameters() -> void:
	_apply_parameters()


func _build_overlay() -> void:
	_overlay = ColorRect.new()
	_overlay.name = "HandDrawnScreenFilter"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = HAND_DRAWN_SHADER
	_overlay.material = _material
	add_child(_overlay)


func _build_hint() -> void:
	if not show_toggle_hint:
		return
	_hint = Label.new()
	_hint.name = "StyleToggleHint"
	_hint.text = "F4  手绘风格"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hint.offset_left = 14.0
	_hint.offset_top = -32.0
	_hint.offset_right = 150.0
	_hint.offset_bottom = -10.0
	_hint.add_theme_font_size_override("font_size", 12)
	_hint.add_theme_color_override("font_color", Color(0.88, 0.82, 0.73, 0.62))
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)


func _apply_parameters() -> void:
	if not is_instance_valid(_material):
		return
	_material.set_shader_parameter("color_steps", color_steps)
	_material.set_shader_parameter("posterize_strength", posterize_strength)
	_material.set_shader_parameter("outline_strength", outline_strength)
	_material.set_shader_parameter("outline_threshold", outline_threshold)
	_material.set_shader_parameter("outline_width", outline_width)
	_material.set_shader_parameter("paper_strength", paper_strength)
	_material.set_shader_parameter("hatch_strength", hatch_strength)
	_material.set_shader_parameter("saturation", saturation)
	_material.set_shader_parameter("warmth", warmth)
	_material.set_shader_parameter("ink_color", Vector3(ink_color.r, ink_color.g, ink_color.b))


func _set_effect_enabled(value: bool) -> void:
	effect_enabled = value
	if is_instance_valid(_overlay):
		_overlay.visible = value
	if is_instance_valid(_hint):
		_hint.text = "F4  手绘风格：%s" % ("开" if value else "关")
	effect_toggled.emit(value)
