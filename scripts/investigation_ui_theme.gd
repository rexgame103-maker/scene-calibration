extends RefCounted
## Regions of the supplied transparent artwork. Text remains in Godot controls.
const ATLAS = preload("res://assets/ui/studio_dossier/investigation_atlas.png")
const INK := Color("2a211b")
const REGIONS := {
	"title": Rect2(16, 12, 596, 291),
	"inventory": Rect2(1095, 30, 307, 737),
	"strip": Rect2(625, 53, 462, 86),
	"button": Rect2(764, 156, 91, 61),
	"dark": Rect2(626, 156, 131, 61),
	"gold": Rect2(955, 156, 130, 61),
	"wide": Rect2(626, 234, 229, 70),
	"work": Rect2(342, 617, 303, 82),
	"photo": Rect2(17, 402, 260, 294),
	"newspaper": Rect2(18, 823, 561, 177),
	"map": Rect2(590, 882, 472, 112),
	"bulb": Rect2(668, 622, 80, 104),
}

static func region(rect: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = ATLAS
	texture.region = rect
	texture.filter_clip = true
	return texture

static func texture(key: String) -> AtlasTexture:
	return region(REGIONS[key])

static func paper(key: String, tint := Color.WHITE) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture(key)
	style.modulate_color = tint
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, 0)
	return style

static func button(control: Button, key := "button") -> void:
	control.flat = false
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var tint := Color.WHITE
		if state == "hover": tint = Color(1.08, 1.06, 1.0)
		if state == "pressed": tint = Color("d6c2a2")
		if state == "disabled" and key != "dark": tint = Color("c4baaa")
		var style := paper(key, tint)
		style.content_margin_left = 8
		style.content_margin_right = 8
		control.add_theme_stylebox_override(state, style)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		control.add_theme_color_override(state, Color("f1e8d8") if key in ["dark", "work"] else INK)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("aa804b")
	focus.set_border_width_all(1)
	control.add_theme_stylebox_override("focus", focus)

static func page_tab(control: Button, selected: bool) -> void:
	# Blank matching outlines keep page numbers as editable Godot text.
	control.flat = false
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxTexture.new()
		style.texture = load("res://assets/ui/studio_dossier/investigation_tab_%s.svg" % ("dark" if selected else "light"))
		for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]: style.set_content_margin(side, 0)
		if state == "hover": style.modulate_color = Color(1.12, 1.09, 1.02)
		if state == "disabled": style.modulate_color = Color("a99b85")
		control.add_theme_stylebox_override(state, style)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		control.add_theme_color_override(state, Color("eee1c9") if selected else INK)

static func furniture_card(icon: String) -> AtlasTexture:
	var rows := {"desk": 320, "chair": 428, "computer": 539, "shelf": 650}
	return region(Rect2(775, rows.get(icon, 320), 309, 109))

static func has_furniture_art(icon: String) -> bool:
	return icon in ["desk", "chair", "computer", "shelf"]
