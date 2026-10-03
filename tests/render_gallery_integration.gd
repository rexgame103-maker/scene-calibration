extends "res://tests/smoke_followup_cases.gd"
var standard_captured := false
var final_captured := false
func _wait_for_debug_action(scene: Node) -> void:
	await super._wait_for_debug_action(scene)
	if not scene.call("_is_concept_gallery"): return
	assert(scene.get_node("PrimitiveRoom/GalleryShell/Architecture/CeilingLightBlocker") != null)
	if not standard_captured and reconstruction_manager.call("is_step_satisfied","standard_restoration_layout"):
		standard_captured = true
		await capture(scene,"res://tests/gallery_gameplay_standard.png")
		await capture(scene,"res://assets/case_photos/gallery/standard_layout_photo.png",true)
	if not final_captured and reconstruction_manager.call("is_step_satisfied","actual_restoration_layout"):
		final_captured = true
		await capture(scene,"res://tests/gallery_gameplay_actual.png")
		var table := scene.call("_debug_find_placed_furniture_by_id","restoration_table") as Node3D
		assert(table.has_node("ConceptModel"))
		assert(table.find_child("ArtworkSurface",true,false) != null and table.has_node("ScalpelTool"))
		var camera := scene.get("camera") as Camera3D
		var original := camera.transform
		var fov := camera.fov
		var target := table.find_child("ArtworkSurface",true,false).global_position as Vector3
		for i in 3:
			camera.transform = Transform3D(Basis.IDENTITY,target+Vector3(0.3+i*0.30,2.1,1.8-i*0.25)).looking_at(target)
			camera.fov = 40
			await capture(scene,"res://assets/case_photos/gallery/"+["process_photo_01_shadow.png","process_photo_02_reflection.png","process_photo_03_orientation.png"][i],true)
		camera.transform = original
		camera.fov = fov
func capture(scene: Node, path: String, hide_ui := false) -> void:
	if DisplayServer.get_name() == "headless": return
	scene.set_process(false)
	var ui := scene.get("ui_root") as Control
	if hide_ui: ui.hide()
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path) == OK)
	if hide_ui: ui.show()
	scene.set_process(true)
