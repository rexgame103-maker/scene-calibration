extends SceneTree
## Read-only capture of the three full authored game environments.
## No building tools, save-game reset or scene resource writes are called.

const OUTPUT := "res://design/presentation/process/final"
const SCENES := {
	"studio": "res://scenes/studio/player_studio_concept.tscn",
	"office": "res://scenes/cases/office_restored_concept.tscn",
	"restoration": "res://scenes/cases/gallery_restored_concept.tscn",
}

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1200, 750)
	root.msaa_3d = Viewport.MSAA_4X
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var manifest := {}
	for id: String in SCENES:
		var scene := (load(SCENES[id]) as PackedScene).instantiate() as Node3D
		assert(scene != null)
		root.add_child(scene)
		current_scene = scene
		await process_frame
		var camera := scene.find_child("Camera3D", true, false) as Camera3D
		assert(camera != null)
		camera.current = true
		camera.keep_aspect = Camera3D.KEEP_WIDTH
		var points: Array[Vector3] = []
		for node: Node in scene.find_children("*", "MeshInstance3D", true, false):
			var mesh := node as MeshInstance3D
			if mesh.mesh == null or not mesh.is_visible_in_tree(): continue
			if mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY: continue
			if "Mist" in str(mesh.name) or "Fog" in str(mesh.name): continue
			var bounds := mesh.get_aabb()
			for corner: int in range(8):
				points.append(mesh.global_transform * bounds.get_endpoint(corner))
		var xmin := INF
		var xmax := -INF
		var ymin := INF
		var ymax := -INF
		for p: Vector3 in points:
			var uv := camera.unproject_position(p)
			xmin = minf(xmin, uv.x); xmax = maxf(xmax, uv.x)
			ymin = minf(ymin, uv.y); ymax = maxf(ymax, uv.y)
		var center := Vector2((xmin+xmax)*0.5, (ymin+ymax)*0.5)
		var unit := camera.size / float(root.size.x)
		camera.position += camera.basis.x * (center.x-root.size.x*0.5) * unit
		camera.position -= camera.basis.y * (center.y-root.size.y*0.5) * unit
		camera.size *= maxf((xmax-xmin)/root.size.x, (ymax-ymin)/root.size.y) * 1.08
		await process_frame
		var groups := []
		for child: Node in scene.get_children():
			if not child is Node3D: continue
			var members := child.find_children("*", "MeshInstance3D", true, false)
			if child is MeshInstance3D: members.append(child)
			if members.is_empty(): continue
			var merged := AABB()
			var started := false
			for member: Node in members:
				var mesh := member as MeshInstance3D
				if mesh.mesh == null: continue
				if mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY: continue
				var bound := mesh.global_transform * mesh.get_aabb()
				merged = merged.merge(bound) if started else bound
				started = true
			if started:
				groups.append({"name":str(child.name), "position":array3(child.position), "rotation":array3(child.rotation_degrees), "bounds_center":array3(merged.get_center()), "bounds_size":array3(merged.size)})
		manifest[id] = {"source":SCENES[id], "resolution":[1200,750], "camera_position":array3(camera.position), "camera_forward":array3(-camera.basis.z), "camera_up":array3(camera.basis.y), "ortho_width":camera.size, "groups":groups}
		await create_timer(1.5).timeout
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		assert(image.save_png(OUTPUT + "/" + id + "-final.png") == OK)
		print("FINAL_SCENE_CAPTURED ", id)
		root.remove_child(scene)
		scene.free()
		await process_frame
	var file := FileAccess.open(OUTPUT + "/scene-manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	print("FINAL_SCENES_CAPTURE_COMPLETE")
	quit(0)

func array3(value: Vector3) -> Array:
	return [value.x,value.y,value.z]
