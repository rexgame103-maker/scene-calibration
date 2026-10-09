extends SceneTree
## Replace foliage in the buyable binary part without regenerating other furniture.

func _initialize() -> void:
	var path := "res://scenes/studio/player_parts/studio_plant.scn"
	var model := load(path).instantiate() as Node3D
	for child: Node in model.get_children():
		if child.name not in ["Terracotta", "Soil"]:
			model.remove_child(child)
			child.free()
	var foliage := preload("res://scenes/props/indoor_plant_foliage.tscn").instantiate() as Node3D
	foliage.name = "Foliage"
	foliage.position.y = 0.405
	model.add_child(foliage)
	foliage.owner = model
	var packed := PackedScene.new()
	assert(packed.pack(model) == OK)
	assert(ResourceSaver.save(packed, path, ResourceSaver.FLAG_COMPRESS) == OK)
	model.free()
	print("UPDATED_STUDIO_PLANT_PART: " + path)
	quit()
