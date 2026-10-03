extends RefCounted
## Text-free dossier artwork for the playable studio. All copy stays in Godot controls.

const INK := Color("34251d")
const MUTED := Color("765a47")
const DIR := "res://assets/ui/studio_dossier/"


static func paper(asset: String, tint := Color.WHITE) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = load(DIR + asset + ".png")
	box.modulate_color = tint
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_content_margin(side, 0.0)
	return box


static func button(control: Button, asset := "button_small", left_inset := 8.0) -> void:
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var tint := Color.WHITE
		match state:
			"hover": tint = Color("fff0cf")
			"pressed": tint = Color("d7b991")
			"disabled": tint = Color("c1b4a4")
		var style := paper(asset, tint)
		style.content_margin_left = left_inset
		style.content_margin_right = 8
		style.content_margin_top = 3
		style.content_margin_bottom = 3
		control.add_theme_stylebox_override(state, style)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		control.add_theme_color_override(state, INK)
	control.add_theme_color_override("font_disabled_color", MUTED)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("855240")
	focus.set_border_width_all(2)
	control.add_theme_stylebox_override("focus", focus)


static func theme() -> Theme:
	var result := Theme.new()
	for type: String in ["Label", "Button", "OptionButton", "CheckButton", "CheckBox"]:
		result.set_color("font_color", type, INK)
	return result


