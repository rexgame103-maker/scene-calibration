extends SceneTree
func _initialize() -> void:
	var path := "res://scenes/start_menu/start_menu_office.tscn"
	var scene := (load(path) as PackedScene).instantiate()
	load("res://tools/the_scene_menu_visual_fix.gd").apply(scene)
	scene.get_node("StartMenuUI/UIRoot/MenuSlash").owner=scene
	var packed := PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,path)==OK)
	scene.free()
	print("MENU_VISUAL_FIX_OK")
	quit()
