extends RefCounted
## Art only; all captions remain translatable Godot text controls.
const INK := Color("292218")
const MUTED := Color("6b5a40")
const DIR := "res://assets/ui/archive_theme/"

static func paper(asset: String = "inventory_panel", tint := Color.WHITE) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = load(DIR + asset + ".png")
	box.modulate_color = tint
	var margin := 12.0
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		box.set_texture_margin(side,margin)
		box.set_content_margin(side,0)
	if asset == "case_panel":
		box.set_texture_margin(SIDE_TOP,42)
		box.set_texture_margin(SIDE_BOTTOM,12)
	return box

static func button(control: Button) -> void:
	for state: String in ["normal","hover","pressed","disabled"]:
		var tint := Color.WHITE
		if state == "hover": tint = Color("fff4d5")
		if state == "pressed": tint = Color("d9c6a4")
		if state == "disabled": tint = Color("c4bba9")
		var style := paper("button",tint)
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 5
		style.content_margin_bottom = 5
		control.add_theme_stylebox_override(state,style)
	for state: String in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		control.add_theme_color_override(state,INK)
	control.add_theme_color_override("font_disabled_color",Color("7c7363"))
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("8d633b")
	focus.set_border_width_all(2)
	control.add_theme_stylebox_override("focus",focus)

static func theme() -> Theme:
	var result := Theme.new()
	# Intentionally do not set a Font: use Godot/project defaults and fallback.
	for type: String in ["Label","Button","OptionButton","CheckButton","CheckBox","SpinBox","LineEdit"]:
		result.set_color("font_color",type,INK)
	result.set_color("default_color","RichTextLabel",INK)
	return result
