extends SceneTree


const SOURCE_SCENE := "res://scenes/studio/player_studio_concept.tscn"
const OUTPUT_DIRECTORY := "res://scenes/studio/player_parts"
const PARTS := {
	"studio_desk": "InvestigationDesk",
	"studio_chair": "DeskChair",
	"studio_computer": "InvestigationDesk/ComputerAndKeyboard",
	"studio_bookshelf": "ArchiveBookcase",
	"studio_lamp": "FloorLamp",
	"studio_rug": "SofaRug",
	"studio_plant": "PottedPlant",
	"analysis_board": "EvidenceBoard",
	"archive_terminal": "PrinterCabinet",
	"case_projector": "MiniatureWorkbench",
	"studio_sofa": "LeatherSofa",
	"studio_coffee_table": "CoffeeTable",
	"studio_window_bookcase": "WindowBookcase",
}


func _init() -> void:
	call_deferred("_export_parts")


func _export_parts() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	var packed_source := load(SOURCE_SCENE) as PackedScene
	if not is_instance_valid(packed_source):
		push_error("Unable to load player studio concept")
		quit(1)
		return
	var source := packed_source.instantiate() as Node3D
	for part_id: String in PARTS:
		var source_node := source.get_node_or_null(NodePath(String(PARTS[part_id]))) as Node3D
		if not is_instance_valid(source_node):
			push_error("Missing studio concept part: %s" % part_id)
			quit(1)
			return
		var clone := source_node.duplicate() as Node3D
		clone.name = "Model"
		clone.position = Vector3.ZERO
		if part_id == "studio_desk":
			var computer := clone.get_node_or_null("ComputerAndKeyboard")
			if is_instance_valid(computer):
				clone.remove_child(computer)
				computer.free()
		print("STUDIO_PART_BOUNDS: %s %s" % [part_id, _visual_bounds(clone)])
		_set_scene_owner(clone, clone)
		var packed_part := PackedScene.new()
		var result := packed_part.pack(clone)
		if result != OK:
			push_error("Unable to pack studio part %s: %s" % [part_id, error_string(result)])
			quit(1)
			return
		var destination := "%s/%s.scn" % [OUTPUT_DIRECTORY, part_id]
		result = ResourceSaver.save(packed_part, destination, ResourceSaver.FLAG_COMPRESS)
		if result != OK:
			push_error("Unable to save studio part %s: %s" % [part_id, error_string(result)])
			quit(1)
			return
		print("EXPORTED_STUDIO_PART: %s" % destination)
	source.free()
	print("PLAYER_STUDIO_BUILD_PARTS_OK")
	quit(0)


func _set_scene_owner(node: Node, scene_owner: Node) -> void:
	for child: Node in node.get_children():
		child.owner = scene_owner
		_set_scene_owner(child, scene_owner)


func _visual_bounds(root_node: Node3D) -> AABB:
	var result := AABB()
	var has_bounds := false
	for descendant: Node in root_node.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := descendant as MeshInstance3D
		if not is_instance_valid(mesh_instance.mesh):
			continue
		var relative_transform := mesh_instance.transform
		var ancestor := mesh_instance.get_parent() as Node3D
		while is_instance_valid(ancestor) and ancestor != root_node:
			relative_transform = ancestor.transform * relative_transform
			ancestor = ancestor.get_parent() as Node3D
		var transformed := relative_transform * mesh_instance.get_aabb()
		result = result.merge(transformed) if has_bounds else transformed
		has_bounds = true
	return result
