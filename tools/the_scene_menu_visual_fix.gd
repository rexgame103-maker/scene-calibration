extends RefCounted
static func apply(scene: Node) -> void:
	var ui := scene.get_node("StartMenuUI/UIRoot")
	var face := ui.get_node("Portrait") as TextureRect
	# Crop inside the existing rectangle; never stretch or enlarge its screen footprint.
	face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.clip_contents=true
	var line := ui.get_node_or_null("MenuSlash") as Polygon2D
	if line==null:
		line=Polygon2D.new()
		line.name="MenuSlash"
		ui.add_child(line)
	line.polygon=PackedVector2Array([Vector2(379,-20),Vector2(393,-20),Vector2(274,725),Vector2(259,740),Vector2(280,582),Vector2(307,421),Vector2(331,264)])
	line.color=Color("080806")
	line.antialiased=true
	ui.move_child(line,ui.get_node("Title").get_index())
	for button in ui.get_node("MenuLayout/MenuColumn").get_children():
		if button is Button:
			button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
			button.add_theme_color_override("font_focus_color",Color("eee1c4"))
