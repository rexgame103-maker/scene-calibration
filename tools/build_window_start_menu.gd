extends SceneTree

const PATH := "res://scenes/start_menu/start_menu_office.tscn"
const NEWSPAPER_ATLAS := preload("res://assets/ui/case_briefing_newspaper/newspaper_modules.png")
var scene: Node3D

func _initialize() -> void:
	call_deferred("_build")

func own_children(node: Node) -> void:
	for child: Node in node.get_children():
		child.owner = scene
		if not child.scene_file_path.is_empty():
			continue
		own_children(child)

func label(parent: Control, id: String, text: String, at: Vector2, size: Vector2, font_size: int, color: Color, font: Font = null) -> Label:
	var node := Label.new()
	node.name = id
	node.text = text
	node.position = at
	node.size = size
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	if font != null: node.add_theme_font_override("font", font)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func button_style(color: Color, accent := Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 3
	style.border_color = accent
	style.content_margin_left = 24
	style.content_margin_right = 20
	return style

func paper_texture(region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = NEWSPAPER_ATLAS
	texture.region = region
	texture.filter_clip = true
	return texture

func paper_art(parent: Control, id: String, texture: Texture2D, rect: Rect2) -> TextureRect:
	var art := TextureRect.new()
	art.name = id
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.position = rect.position
	art.size = rect.size
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)
	return art

func build_newspaper_stack(parent: Control) -> void:
	var stack := Control.new()
	stack.name = "NewspaperStack"
	stack.size = Vector2(580, 720)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(stack)
	var page := paper_texture(Rect2(28, 364, 710, 445))
	var grain := paper_texture(Rect2(70, 646, 630, 113))
	for entry: Array in [
		["Bottom", Rect2(-196, 427, 550, 345), -0.28, Color(0.93, 0.89, 0.82), Rect2(30, 60, 490, 245)],
		["Middle", Rect2(-168, 238, 460, 289), -0.08, Color.WHITE, Rect2(25, 55, 410, 205)],
		["Top", Rect2(-85, -110, 625, 390), 0.19, Color.WHITE, Rect2(30, 85, 565, 245)]]:
		var rect: Rect2 = entry[1]
		var shadow := paper_art(stack, entry[0] + "Shadow", page, Rect2(rect.position + Vector2(8, 11), rect.size))
		shadow.rotation = entry[2]
		shadow.pivot_offset = rect.size * 0.5
		shadow.self_modulate = Color(0, 0, 0, 0.4)
		var paper := paper_art(stack, entry[0] + "Paper", page, rect)
		paper.rotation = entry[2]
		paper.pivot_offset = rect.size * 0.5
		paper.modulate = entry[3]
		paper_art(paper, "BlankPrintArea", grain, entry[4])
		if entry[0] == "Middle":
			paper_art(paper, "Masthead", paper_texture(Rect2(43, 70, 1060, 160)), Rect2(25, 15, 410, 62))

func _build() -> void:
	scene = Node3D.new()
	scene.name = "TheSceneStartMenu"
	scene.set_script(load("res://scripts/the_scene_start_menu.gd"))
	scene.set("camera_push_in_distance", 0.65)
	var studio := (load("res://scenes/studio/player_studio_concept.tscn") as PackedScene).instantiate()
	studio.name = "StudioBackground"
	scene.add_child(studio)
	studio.owner = scene
	var camera := Camera3D.new()
	camera.name = "StartCamera"
	camera.current = true
	camera.fov = 38
	camera.near = 0.06
	# Preserve the saved camera framing when rebuilding only the menu layout.
	if ResourceLoader.exists(PATH):
		var existing := (load(PATH) as PackedScene).instantiate()
		var saved_camera := existing.get_node("StartCamera") as Camera3D
		camera.transform = saved_camera.transform
		camera.fov = saved_camera.fov
		existing.free()
	else:
		camera.transform = Transform3D(Basis.IDENTITY, Vector3(-0.65691, 2.00608, 0.27094)).looking_at(Vector3(-4.9, 1.9, 0.08))
	scene.add_child(camera)
	var layer := CanvasLayer.new()
	layer.name = "StartMenuUI"
	scene.add_child(layer)
	var ui := Control.new()
	ui.name = "UIRoot"
	ui.size = Vector2(1280, 720)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	var atmosphere := ColorRect.new()
	atmosphere.name = "Atmosphere"
	atmosphere.size = ui.size
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vignette := ShaderMaterial.new()
	vignette.shader = load("res://shaders/menu_vignette.gdshader")
	atmosphere.material = vignette
	ui.add_child(atmosphere)
	build_newspaper_stack(ui)
	var title_font := SystemFont.new()
	title_font.font_names = PackedStringArray(["STZhongsong", "SimSun", "Microsoft YaHei"])
	title_font.font_weight = 700
	label(ui, "Title", "错位现场", Vector2(65, 85), Vector2(430, 85), 60, Color("2f261f"), title_font)
	(ui.get_node("Title") as Label).clip_text = true
	label(ui, "Subtitle", "SCENE CALIBRATION", Vector2(71, 175), Vector2(360, 26), 17, Color("766853"))
	label(ui, "StudioCaption", "校准员工作室", Vector2(74, 610), Vector2(260, 28), 14, Color("514536"))
	label(ui, "Motto", "观察 · 连接 · 还原", Vector2(74, 638), Vector2(360, 25), 13, Color("796a55"))
	var layout := Control.new()
	layout.name = "MenuLayout"
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(layout)
	var column := Control.new()
	column.name = "MenuColumn"
	column.position = Vector2(62, 310)
	column.size = Vector2(330, 289)
	layout.add_child(column)
	var menu_font := SystemFont.new()
	menu_font.font_names = PackedStringArray(["Georgia", "STZhongsong", "SimSun", "Microsoft YaHei"])
	menu_font.font_weight = 400
	var index := 0
	for entry: Array in [["StartButton", "开始游戏"], ["ContinueButton", "继续游戏"], ["SettingsButton", "设置"], ["ExitButton", "退出游戏"]]:
		var button := Button.new()
		button.name = entry[0]
		button.text = entry[1]
		button.position = Vector2(0, index * 66 + (24 if index == 3 else 0))
		button.size = Vector2(210, 54)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_override("font", menu_font)
		button.add_theme_font_size_override("font_size", 19)
		button.add_theme_color_override("font_color", Color(0.2, 0.16, 0.12))
		button.add_theme_color_override("font_hover_color", Color(0.49, 0.24, 0.16))
		button.add_theme_color_override("font_focus_color", Color(0.49, 0.24, 0.16))
		button.add_theme_color_override("font_pressed_color", Color(0.38, 0.19, 0.11))
		button.add_theme_color_override("font_disabled_color", Color(0.52, 0.48, 0.41))
		button.add_theme_stylebox_override("normal", button_style(Color.TRANSPARENT))
		button.add_theme_stylebox_override("disabled", button_style(Color.TRANSPARENT))
		button.add_theme_stylebox_override("hover", button_style(Color(0.32, 0.18, 0.1, 0.07), Color("7d452e")))
		button.add_theme_stylebox_override("pressed", button_style(Color(0.32, 0.18, 0.1, 0.12), Color("7d452e")))
		button.add_theme_stylebox_override("focus", button_style(Color.TRANSPARENT, Color("7d452e")))
		column.add_child(button)
		index += 1
	var reset := Button.new()
	reset.name = "ResetGameButton"
	reset.visible = false
	ui.add_child(reset)
	own_children(scene)
	var packed := PackedScene.new()
	assert(packed.pack(scene) == OK)
	assert(ResourceSaver.save(packed, PATH) == OK)
	scene.free()
	print("WINDOW_MENU_BUILT")
	await process_frame
	quit()

