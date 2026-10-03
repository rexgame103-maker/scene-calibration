extends SceneTree

func _initialize() -> void:
	var path := "res://scenes/studio/player_studio_concept.tscn"
	var scene := (load(path) as PackedScene).instantiate() as Node3D
	load("res://tools/player_studio_layout_fix.gd").apply(scene)
	for child in scene.find_children("*", "", true, false):
		child.owner = scene
	var packed := PackedScene.new()
	assert(packed.pack(scene) == OK)
	assert(ResourceSaver.save(packed, path) == OK)
	scene.free()
	quit()
