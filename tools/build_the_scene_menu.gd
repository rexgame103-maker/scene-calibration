extends SceneTree
const ASSETS := "res://assets/ui/the_scene_menu/"
var scene: Node3D
func own_all(node: Node) -> void:
	for child in node.get_children():
		if child==scene.get_node("StudioBackground"): continue
		child.owner=scene
		own_all(child)

func art(parent: Node, label: String, filename: String, at: Vector2, size: Vector2) -> TextureRect:
	var texture := TextureRect.new()
	texture.name=label
	texture.texture=load(ASSETS+filename+".png")
	texture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	texture.position=at
	texture.size=size
	texture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(texture)
	return texture

func _initialize() -> void:
	scene=Node3D.new()
	scene.name="TheSceneStartMenu"
	scene.set_script(load("res://scripts/the_scene_start_menu.gd"))
	var studio := (load("res://scenes/studio/player_studio_concept.tscn") as PackedScene).instantiate()
	studio.name="StudioBackground"
	scene.add_child(studio)
	studio.owner=scene
	# The menu camera is added after the studio camera and becomes current.
	var camera := Camera3D.new()
	camera.name="StartCamera"
	camera.current=true
	camera.fov=48
	camera.near=0.08
	camera.transform=Transform3D(Basis.IDENTITY,Vector3(0.2,2.78,3.76)).looking_at(Vector3(-2.3,1.6,-3.1))
	scene.add_child(camera)
	var layer := CanvasLayer.new()
	layer.name="StartMenuUI"
	scene.add_child(layer)
	var ui := Control.new()
	ui.name="UIRoot"
	ui.size=Vector2(1280,720)
	ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	var vignette := ColorRect.new()
	vignette.name="Atmosphere"
	vignette.size=ui.size
	vignette.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var shader := ShaderMaterial.new()
	shader.shader=load("res://shaders/menu_vignette.gdshader")
	vignette.material=shader
	ui.add_child(vignette)
	art(ui,"Portrait","face",Vector2(-140,-30),Vector2(580,770))
	var ink := art(ui,"InkOverlay","ink",Vector2(-10,-8),Vector2(1300,736))
	ink.modulate.a=0.85
	art(ui,"Title","title",Vector2(327,122),Vector2(850,240)).rotation=deg_to_rad(-7)
	var layout := Control.new()
	layout.name="MenuLayout"
	layout.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(layout)
	var column := VBoxContainer.new()
	column.name="MenuColumn"
	column.position=Vector2(335,311)
	column.size=Vector2(325,256)
	column.rotation=deg_to_rad(-7)
	column.add_theme_constant_override("separation",4)
	layout.add_child(column)
	var normal := StyleBoxTexture.new()
	normal.texture=load(ASSETS+"button.png")
	normal.content_margin_left=40
	normal.content_margin_right=24
	normal.content_margin_top=5
	normal.content_margin_bottom=5
	var selected := normal.duplicate() as StyleBoxTexture
	selected.texture=load(ASSETS+"button_selected.png")
	for entry in [["StartButton","开始游戏"],["ContinueButton","继续游戏"],["SettingsButton","设置"],["ExitButton","退出"]]:
		var button := Button.new()
		button.name=entry[0]
		button.text=entry[1]
		button.alignment=HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size=Vector2(325,56)
		button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size",27)
		for state in ["normal","disabled"]: button.add_theme_stylebox_override(state,normal)
		for state in ["hover","pressed","focus"]: button.add_theme_stylebox_override(state,selected)
		button.add_theme_color_override("font_color",Color("eee1c4"))
		button.add_theme_color_override("font_disabled_color",Color("817766"))
		for state in ["hover","pressed","focus"]: button.add_theme_color_override("font_"+state+"_color",Color("272017"))
		column.add_child(button)
	var reset := Button.new()
	reset.name="ResetGameButton"
	reset.visible=false
	ui.add_child(reset)
	load("res://tools/the_scene_menu_visual_fix.gd").apply(scene)
	own_all(scene)
	var packed := PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,"res://scenes/start_menu/start_menu_office.tscn")==OK)
	scene.free()
	print("THE_SCENE_MENU_BUILT")
	quit()
