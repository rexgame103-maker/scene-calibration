extends SceneTree

const SCENE_PATH := "res://scenes/studio/noir/noir_studio_3d.tscn"
const MODEL_PATHS := [
	"OfficeChair/NormalizedModel/chair",
	"ArchiveCabinet/NormalizedModel/shelf",
	"LowFileCabinet/NormalizedModel/smallShelf",
]

func _initialize() -> void:
	call_deferred("_run")

func _check(studio: Node) -> void:
	for path: String in MODEL_PATHS:
		var model := studio.get_node(path)
		assert(model.scene_file_path.is_empty(), "Model must be local, not an instance with duplicated children")
		assert(model.get_child_count() == 1, "Imported model mesh was duplicated: " + path)
		var mesh := model.get_child(0) as MeshInstance3D
		assert(mesh != null and mesh.mesh != null)
		assert(mesh.material_override is ShaderMaterial, "Noir material must survive editor round-trip")
		assert(mesh.owner == studio)

func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	var editable := packed.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	_check(editable)
	var saved := PackedScene.new()
	assert(saved.pack(editable) == OK)
	var path := "user://noir_serialization_check.tscn"
	assert(ResourceSaver.save(saved, path) == OK)
	var reloaded := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var round_trip := reloaded.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	_check(round_trip)
	round_trip.free()
	editable.free()
	print("NOIR_SERIALIZATION_OK: editor instantiate, save, fresh reload; three models each contain one local mesh")
	quit(0)
