extends "res://tools/build_noir_studio_3d.gd"
## Modify the saved office in place, without rebuilding furniture or lighting.

func _build() -> void:
	var path := "res://scenes/cases/office_restored_concept.tscn"
	scene = (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	for node_path: String in ["Architecture/LeftCutaway", "Architecture/LeftSkirting", "Architecture/OpenEntryDoor", "Architecture/FrontCutaway", "Architecture/FrontLeftCutaway", "Architecture/RightSillWall", "Architecture/CompletedWindowWall"]:
		var old := scene.get_node_or_null(node_path)
		if old != null:
			old.free()
	var wall := group("CompletedWindowWall", scene.get_node("Architecture"))
	var paint := Color("8b734d")
	# Window frame spans z = -3.015 ... 1.015 and y = 1.015 ... 3.155.
	box(wall, "RearPier", Vector3(4.3,1.575,-3.3075), Vector3(0.16,3.15,0.585), paint)
	box(wall, "FrontPier", Vector3(4.3,1.575,2.3075), Vector3(0.16,3.15,2.585), paint)
	box(wall, "BelowWindow", Vector3(4.3,0.5075,-1), Vector3(0.16,1.015,4.03), paint)
	box(wall, "WindowHeader", Vector3(4.3,3.2275,0), Vector3(0.16,0.145,7.2), paint)
	box(wall, "TopCornice", Vector3(4.26,3.30,0), Vector3(0.22,0.09,7.2), INK)
	_own(scene)
	var packed := PackedScene.new()
	assert(packed.pack(scene) == OK)
	assert(ResourceSaver.save(packed,path) == OK)
	scene.free()
	print("OFFICE_WALL_OK: window surrounded by solid piers, sill wall and header; user cutaways preserved")
	quit()
