extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var profile := root.get_node("PlayerProfile")
	profile.call("reset_profile", false)
	var studio := (load("res://scenes/studio/calibrator_studio.tscn") as PackedScene).instantiate()
	var hud := studio.get_node_or_null("StudioUI/UIRoot/StudioHUD") as Control
	if hud == null:
		_fail("The studio HUD must be an authored scene child before _ready")
		return
	var tab := hud.get_node("StudioToolsPanel/WallStyleButton") as Button
	var saved_position := tab.position + Vector2(11, 7)
	tab.position = saved_position
	var slot := hud.get_node("ArchiveInventoryPanel/EditableContent/FurniturePageViewport/CatalogList/CatalogSlot1") as Control
	var saved_slot_position := slot.position + Vector2(5, 9)
	slot.position = saved_slot_position
	root.add_child(studio)
	current_scene = studio
	await process_frame
	await process_frame
	if tab.position != saved_position:
		_fail("Runtime code must preserve editor-authored button positions")
		return
	if slot.position != saved_slot_position or slot.get_child_count() != 1:
		_fail("Furniture cards must use movable editor-authored slots")
		return
	var tabs := hud.get_node("FurniturePageTabs") as Control
	var second_page := tabs.get_node("FurniturePageTab2") as Button
	second_page.pressed.emit()
	await process_frame
	if int(studio.get("catalog_page")) != 1:
		_fail("Notebook page tabs must remain connected")
		return
	var scroll := studio.get("catalog_scroll") as ScrollContainer
	if scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		_fail("Notebook furniture must use page tabs instead of a scrollbar")
		return
	studio.call("_enter_work_mode")
	await process_frame
	var open_computer := hud.get_node("OpenComputerButton") as Button
	var return_build := hud.get_node("ReturnBuildButton") as Button
	if not open_computer.visible or not return_build.visible:
		_fail("Work-mode buttons should be authored scene nodes")
		return
	return_build.pressed.emit()
	await process_frame
	if open_computer.visible or return_build.visible:
		_fail("Work-mode buttons should hide when returning to building")
		return
	print("STUDIO_HUD_EDITABLE_OK")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
