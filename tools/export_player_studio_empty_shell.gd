extends SceneTree


const SOURCE_SCENE := "res://scenes/studio/player_studio_concept.tscn"
const OUTPUT_SCENE := "res://scenes/studio/player_studio_empty_shell.scn"
const KEEP_NODES: Array[String] = [
	"Architecture",
	"WoodFloor",
	"WorldEnvironment",
	"WarmKey",
	"CoolFill",
	"CeilingLightBlocker",
	"WorkspaceLighting",
	"WindowLightMist",
]


func _init() -> void:
	call_deferred("_export_shell")


func _export_shell() -> void:
	var source_packed := load(SOURCE_SCENE) as PackedScene
	if not is_instance_valid(source_packed):
		push_error("Unable to load complete player studio scene")
		quit(1)
		return
	var source := source_packed.instantiate() as Node3D
	var shell := Node3D.new()
	shell.name = "PlayerStudioEmptyShell"
	shell.set_meta("source_scene", SOURCE_SCENE)
	shell.set_meta("room_size", Vector2(10.2, 8.6))
	shell.set_meta("room_origin", Vector2(0.0, -0.7))
	for node_name: String in KEEP_NODES:
		var source_node := source.get_node_or_null(node_name)
		if not is_instance_valid(source_node):
			push_error("Missing empty-shell source node: %s" % node_name)
			source.free()
			shell.free()
			quit(1)
			return
		var clone := source_node.duplicate()
		shell.add_child(clone)
		clone.owner = shell
		_set_scene_owner(clone, shell)
	var packed_shell := PackedScene.new()
	var result := packed_shell.pack(shell)
	if result == OK:
		result = ResourceSaver.save(packed_shell, OUTPUT_SCENE, ResourceSaver.FLAG_COMPRESS)
	source.free()
	shell.free()
	if result != OK:
		push_error("Unable to save exact player studio shell: %s" % error_string(result))
		quit(1)
		return
	print("PLAYER_STUDIO_EMPTY_SHELL_OK: %s" % OUTPUT_SCENE)
	quit(0)


func _set_scene_owner(node: Node, scene_owner: Node) -> void:
	for child: Node in node.get_children():
		child.owner = scene_owner
		_set_scene_owner(child, scene_owner)
