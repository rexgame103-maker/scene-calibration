extends RefCounted

## Lightweight scene HUD. All captions stay as Godot controls for localization.
const TEXT := Color("f2f0e9")
const MUTED := Color("aeb3b9")
const BORDER := Color("aeb7bf70")
const PANEL := Color("090c11d9")
const PANEL_SOFT := Color("090c11bd")
const HOVER := Color("242a31e8")
const PRESSED := Color("11161ceb")


static func panel(kind: String = "panel") -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	match kind:
		"status": style.bg_color = PANEL_SOFT
		"card": style.bg_color = Color("07090dc4")
		"card_hover": style.bg_color = HOVER
		_: style.bg_color = PANEL
	style.border_color = BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	if kind != "status":
		style.shadow_color = Color("00000066")
		style.shadow_size = 5
	return style


static func divider() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("b9c0c83d")
	return style


static func button(control: Button) -> void:
	control.add_theme_stylebox_override("normal", _button_box(Color("07090dcf"), BORDER))
	control.add_theme_stylebox_override("hover", _button_box(HOVER, Color("d7dde3a6")))
	control.add_theme_stylebox_override("pressed", _button_box(PRESSED, Color("d7dde3cc")))
	control.add_theme_stylebox_override("disabled", _button_box(Color("090b0f8c"), Color("737a8152")))
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		control.add_theme_color_override(state, TEXT)
	control.add_theme_color_override("font_disabled_color", Color("777c82"))
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("d7dde3aa")
	focus.set_border_width_all(1)
	control.add_theme_stylebox_override("focus", focus)


static func theme() -> Theme:
	var result := Theme.new()
	for type: String in ["Label", "Button", "OptionButton", "CheckButton", "CheckBox", "SpinBox", "LineEdit"]:
		result.set_color("font_color", type, TEXT)
	result.set_color("default_color", "RichTextLabel", TEXT)
	return result


static func _button_box(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style
