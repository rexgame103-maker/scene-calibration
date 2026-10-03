extends Node


var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var profile_script := load("res://scripts/player_profile.gd") as GDScript
	var profile := profile_script.new() as Node
	profile.call("reset_profile", false)

	_expect(int(profile.call("get_studio_room_count", 0)) == 1, "New profile should start with one first-floor room")
	_expect(int(profile.call("get_studio_room_count", 1)) == 0, "New profile should not start with a second floor")
	_expect(not bool(profile.call("is_studio_floor_available", 1)), "Second floor should be hidden before its first room is bought")
	_expect(not bool(profile.call("can_unlock_studio_room_purchase", 1)), "Second-floor expansion should wait for four first-floor rooms")

	profile.call("add_debug_money", 20000, false)
	for expected_count: int in range(2, 5):
		_expect(bool(profile.call("unlock_studio_room_purchase", 0, false)), "First-floor expansion action should unlock one room purchase")
		_expect(bool(profile.call("purchase_studio_room", 0, false)), "Unlocked first-floor room should be purchasable")
		_expect(int(profile.call("get_studio_room_count", 0)) == expected_count, "First-floor room count should increase one plot at a time")
		_expect(not bool(profile.call("is_studio_room_purchase_unlocked", 0)), "Room offer should close after one purchase")
	_expect(not bool(profile.call("can_unlock_studio_room_purchase", 0)), "First-floor expansion should stop at four rooms")

	_expect(bool(profile.call("unlock_studio_room_purchase", 1, false)), "Second-floor expansion should unlock after the first floor is complete")
	_expect(bool(profile.call("purchase_studio_room", 1, false)), "The first second-floor room should be purchasable")
	_expect(int(profile.call("get_studio_room_count", 1)) == 1, "Second floor should begin with one purchased room")
	_expect(bool(profile.call("is_studio_floor_available", 1)), "Buying a second-floor room should enable floor switching")

	var studio := (load("res://scenes/studio/calibrator_studio.tscn") as PackedScene).instantiate() as Node3D
	studio.set("profile", profile)
	studio.set("camera", studio.get_node("StudioCamera"))
	studio.set("furniture_root", studio.get_node("StudioFurniture"))
	studio.set("shell_root", studio.get_node("StudioShell"))
	studio.set("ui_root", studio.get_node("StudioUI/UIRoot"))
	studio.set("active_floor", 0)
	studio.call("_build_shell")
	_expect(_floor_shell_visibility_is(studio.get_node("StudioShell"), 0), "First floor should be visible while second-floor geometry is hidden")
	studio.set("active_floor", 1)
	studio.call("_apply_floor_visibility")
	_expect(_floor_shell_visibility_is(studio.get_node("StudioShell"), 1), "Switching floors should hide first-floor geometry and show the second floor")
	studio.set("active_floor", 0)
	studio.call("_apply_floor_visibility")
	studio.call("_build_ui")
	studio.call("_refresh_floor_buttons")
	studio.call("_refresh_room_pan_controls")
	_expect(is_instance_valid(studio.find_child("DebugAddMoneyButton", true, false)), "Studio HUD should expose the add-money test button")
	_expect(is_instance_valid(studio.find_child("DebugJumpFirstCaseButton", true, false)), "Studio HUD should expose the first-case jump button")
	_expect(is_instance_valid(studio.find_child("DebugJumpSecondCaseButton", true, false)), "Studio HUD should expose the second-case jump button")
	var pan_controls := studio.find_child("RoomPanControls", true, false) as Control
	_expect(is_instance_valid(pan_controls) and pan_controls.visible, "Overview pan controls should appear after the floor has multiple rooms")
	var floor2_button := studio.get("floor2_button") as Button
	_expect(is_instance_valid(floor2_button) and not floor2_button.disabled, "Second-floor button should enable after its first room is purchased")
	studio.free()

	var computer := StudioComputerUI.new()
	computer.setup(profile)
	get_tree().root.add_child(computer)
	await get_tree().process_frame
	computer.open_desktop()
	computer.call("_show_app", "shop")
	await get_tree().process_frame
	_expect(is_instance_valid(computer.find_child("ComputerDebugAddMoneyButton", true, false)), "Computer shop should keep the add-money test button accessible")
	_expect(_has_button_text(computer, "一楼已扩建完成"), "Shop should disable the completed first-floor expansion")
	_expect(_has_button_text(computer, "扩建二楼"), "Second-floor expansion must remain a separate action")
	get_tree().root.remove_child(computer)
	computer.free()
	profile.free()
	_finish()


func _has_button_text(node: Node, expected_text: String) -> bool:
	if node is Button and (node as Button).text == expected_text:
		return true
	for child: Node in node.get_children():
		if _has_button_text(child, expected_text):
			return true
	return false


func _floor_shell_visibility_is(shell_root: Node, visible_floor: int) -> bool:
	var found_visible_floor := false
	var found_hidden_floor := false
	for child: Node in shell_root.get_children():
		if not child is Node3D:
			continue
		var floor_index := int(child.get_meta("studio_floor", 0))
		if floor_index == visible_floor:
			found_visible_floor = found_visible_floor or (child as Node3D).visible
		elif (child as Node3D).visible:
			return false
		else:
			found_hidden_floor = true
	return found_visible_floor and found_hidden_floor


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures.append(message)
	push_error("STUDIO ROOM EXPANSION SMOKE: %s" % message)


func _finish() -> void:
	if failures.is_empty():
		print("STUDIO_ROOM_EXPANSION_SMOKE_OK")
		get_tree().quit(0)
	else:
		print("STUDIO_ROOM_EXPANSION_SMOKE_FAILED: %s" % [failures])
		get_tree().quit(1)
