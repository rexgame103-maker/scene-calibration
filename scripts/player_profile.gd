extends Node


signal money_changed(amount: int)
signal mail_changed
signal shop_changed
signal studio_layout_changed
signal studio_tier_changed(tier: int)
signal studio_rooms_changed(floor_index: int, room_count: int)
signal studio_expansion_changed
signal skills_changed(active_skills: Array[String])
signal case_completed(case_id: String)

const SAVE_PATH := "user://calibrator_profile.json"
const ALBUM_DIRECTORY := "user://case_album"
const CAMPAIGN_PATH := "res://data/progression/campaign.json"
const CATALOG_PATH := "res://data/progression/studio_catalog.json"
const SAVE_VERSION := 2
const MAX_STUDIO_ROOMS_PER_FLOOR := 4
const FIRST_FLOOR_ROOM_COSTS: Array[int] = [0, 900, 1400, 2100]
const SECOND_FLOOR_ROOM_COSTS: Array[int] = [1600, 2200, 3000, 3800]

var money := 700
var studio_tier := 1
var studio_rooms: Dictionary = {"0": 1, "1": 0}
var studio_room_purchase_unlocked: Dictionary = {"0": false, "1": false}
var owned_furniture: Dictionary = {}
var placed_studio_layout: Array[Dictionary] = []
var studio_shell: Dictionary = {"wall_style": 0, "floor_style": 0}
var unlocked_shop_items: Dictionary = {}
var completed_cases: Dictionary = {}
var album_entries: Array[Dictionary] = []
var mail_state: Dictionary = {}
var active_case_id := ""
var active_skills: Array[String] = []
var campaign_data: Dictionary = {}
var catalog_data: Dictionary = {}


func _ready() -> void:
	_load_static_data()
	if not load_profile():
		reset_profile(false)


func reset_profile(save_after := true) -> void:
	money = 700
	studio_tier = 1
	studio_rooms = {"0": 1, "1": 0}
	studio_room_purchase_unlocked = {"0": false, "1": false}
	owned_furniture = {
		"studio_desk": 1,
		"studio_chair": 1,
		"studio_computer": 1,
		"studio_bookshelf": 1,
		"studio_lamp": 1
	}
	placed_studio_layout.clear()
	studio_shell = {"wall_style": 0, "floor_style": 0}
	unlocked_shop_items = {
		"studio_rug": true,
		"studio_plant": true,
		"studio_lamp": true
	}
	completed_cases.clear()
	album_entries.clear()
	mail_state.clear()
	active_case_id = ""
	active_skills.clear()
	_initialize_mail_state()
	_emit_all()
	if save_after:
		save_profile()


func reset_game_progress(save_after := true) -> bool:
	# This is the destructive, player-facing full reset. It is intentionally
	# separate from reset_profile(), which is also used to create defaults when
	# no valid save exists.
	reset_profile(false)
	if not save_after:
		return true
	_clear_saved_album_images()
	return save_profile()


func save_profile() -> bool:
	var payload := {
		"save_version": SAVE_VERSION,
		"money": money,
		"studio_tier": studio_tier,
		"studio_rooms": studio_rooms,
		"studio_room_purchase_unlocked": studio_room_purchase_unlocked,
		"owned_furniture": owned_furniture,
		"placed_studio_layout": placed_studio_layout,
		"studio_shell": studio_shell,
		"unlocked_shop_items": unlocked_shop_items,
		"completed_cases": completed_cases,
		"album_entries": album_entries,
		"mail_state": mail_state,
		"active_case_id": active_case_id
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Unable to write player profile")
		return false
	file.store_string(JSON.stringify(payload, "\t", false))
	return true


func load_profile() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var save_text := FileAccess.get_file_as_string(SAVE_PATH)
	if save_text.strip_edges().is_empty():
		return false
	var parsed: Variant = JSON.parse_string(save_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var payload := parsed as Dictionary
	money = maxi(0, int(payload.get("money", 700)))
	studio_tier = clampi(int(payload.get("studio_tier", 1)), 1, 3)
	_load_studio_room_progress(payload)
	owned_furniture = (payload.get("owned_furniture", {}) as Dictionary).duplicate(true)
	placed_studio_layout = _dictionary_array(payload.get("placed_studio_layout", []))
	studio_shell = (payload.get("studio_shell", {"wall_style": 0, "floor_style": 0}) as Dictionary).duplicate(true)
	unlocked_shop_items = (payload.get("unlocked_shop_items", {}) as Dictionary).duplicate(true)
	completed_cases = (payload.get("completed_cases", {}) as Dictionary).duplicate(true)
	album_entries = _dictionary_array(payload.get("album_entries", []))
	mail_state = (payload.get("mail_state", {}) as Dictionary).duplicate(true)
	active_case_id = String(payload.get("active_case_id", ""))
	_initialize_mail_state()
	var frames_migrated := _grant_completed_case_frames()
	if frames_migrated:
		save_profile()
	return true


func get_campaign_cases() -> Array[Dictionary]:
	return _dictionary_array(campaign_data.get("cases", []))


func get_case_definition(case_id: String) -> Dictionary:
	for value: Variant in campaign_data.get("cases", []):
		if value is Dictionary and String((value as Dictionary).get("case_id", "")) == case_id:
			return (value as Dictionary).duplicate(true)
	return {}


func get_available_mail() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value: Variant in campaign_data.get("mail", []):
		if not value is Dictionary:
			continue
		var item := value as Dictionary
		var mail_id := String(item.get("mail_id", ""))
		if mail_id.is_empty() or not _mail_requirements_met(item):
			continue
		var copy := item.duplicate(true)
		var state := mail_state.get(mail_id, {}) as Dictionary
		copy["is_read"] = bool(state.get("is_read", false))
		copy["is_accepted"] = bool(state.get("is_accepted", false))
		result.append(copy)
	return result


func get_unread_mail_count() -> int:
	var count := 0
	for item: Dictionary in get_available_mail():
		if not bool(item.get("is_read", false)):
			count += 1
	return count


func mark_mail_read(mail_id: String) -> void:
	var state := mail_state.get(mail_id, {}) as Dictionary
	state["is_read"] = true
	mail_state[mail_id] = state
	mail_changed.emit()
	save_profile()


func accept_mail(mail_id: String) -> String:
	for item: Dictionary in get_available_mail():
		if String(item.get("mail_id", "")) != mail_id:
			continue
		mark_mail_read(mail_id)
		var state := mail_state.get(mail_id, {}) as Dictionary
		state["is_accepted"] = true
		mail_state[mail_id] = state
		var case_id := String(item.get("case_id", ""))
		if not case_id.is_empty():
			active_case_id = case_id
		mail_changed.emit()
		save_profile()
		return case_id
	return ""


func complete_case(case_id: String, captured_image_path := "", save_after := true) -> void:
	if bool(completed_cases.get(case_id, false)):
		# Replaying an archived case never grants rewards twice, but it still ends
		# the active case session cleanly.
		active_case_id = ""
		_grant_case_frame(get_case_definition(case_id))
		if save_after:
			save_profile()
		return
	var definition := get_case_definition(case_id)
	completed_cases[case_id] = true
	_grant_case_frame(definition)
	money += int(definition.get("reward_money", 0))
	for shop_id_value: Variant in definition.get("shop_unlocks", []):
		unlocked_shop_items[String(shop_id_value)] = true
	var album := definition.get("album", {}) as Dictionary
	if not album.is_empty():
		var entry := album.duplicate(true)
		entry["case_id"] = case_id
		entry["image_path"] = captured_image_path
		album_entries.append(entry)
	active_case_id = ""
	case_completed.emit(case_id)
	money_changed.emit(money)
	shop_changed.emit()
	mail_changed.emit()
	if save_after:
		save_profile()


func _grant_case_frame(definition: Dictionary) -> bool:
	var frame_kind := String(definition.get("studio_frame_kind", ""))
	if frame_kind.is_empty() or int(owned_furniture.get(frame_kind, 0)) > 0:
		return false
	owned_furniture[frame_kind] = 1
	return true


func _grant_completed_case_frames() -> bool:
	var changed := false
	for definition: Dictionary in get_campaign_cases():
		var case_id := String(definition.get("case_id", ""))
		if bool(completed_cases.get(case_id, false)):
			changed = _grant_case_frame(definition) or changed
	return changed


func get_shop_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value: Variant in catalog_data.get("items", []):
		if not value is Dictionary:
			continue
		var item := (value as Dictionary).duplicate(true)
		var item_id := String(item.get("item_id", ""))
		item["is_unlocked"] = bool(unlocked_shop_items.get(item_id, false)) or bool(item.get("initially_unlocked", false))
		item["owned_count"] = int(owned_furniture.get(String(item.get("furniture_kind", "")), 0))
		result.append(item)
	return result


func get_studio_item(kind: String) -> Dictionary:
	for item: Dictionary in get_shop_items():
		if String(item.get("furniture_kind", "")) == kind:
			return item
	return {}


func purchase_item(item_id: String) -> bool:
	for item: Dictionary in get_shop_items():
		if String(item.get("item_id", "")) != item_id or not bool(item.get("is_unlocked", false)):
			continue
		var price := int(item.get("price", 0))
		if money < price:
			return false
		money -= price
		var kind := String(item.get("furniture_kind", ""))
		owned_furniture[kind] = int(owned_furniture.get(kind, 0)) + 1
		money_changed.emit(money)
		shop_changed.emit()
		save_profile()
		return true
	return false


func get_available_studio_inventory() -> Dictionary:
	var result := owned_furniture.duplicate(true)
	for entry: Dictionary in placed_studio_layout:
		var kind := String(entry.get("kind", ""))
		result[kind] = maxi(0, int(result.get(kind, 0)) - 1)
	return result


func set_studio_layout(layout: Array) -> void:
	placed_studio_layout = _dictionary_array(layout)
	_recalculate_active_skills()
	studio_layout_changed.emit()
	save_profile()


func set_studio_shell(wall_style: int, floor_style: int) -> void:
	studio_shell = {"wall_style": clampi(wall_style, 0, 2), "floor_style": clampi(floor_style, 0, 2)}
	studio_layout_changed.emit()
	save_profile()


func has_studio_workstation() -> bool:
	return get_studio_workstation_floor() >= 0


func get_studio_workstation_floor() -> int:
	for floor_index: int in range(2):
		var found := {"studio_desk": false, "studio_chair": false, "studio_computer": false}
		for entry: Dictionary in placed_studio_layout:
			if int(entry.get("floor", 0)) != floor_index:
				continue
			var kind := String(entry.get("kind", ""))
			if found.has(kind):
				found[kind] = true
		if bool(found["studio_desk"] and found["studio_chair"] and found["studio_computer"]):
			return floor_index
	return -1


func has_skill(skill_id: String) -> bool:
	return active_skills.has(skill_id)


# Legacy callers can still read studio_tier, but expansion is now driven by
# independently purchased room plots on each floor.
func get_upgrade_cost() -> int:
	return get_studio_room_cost(0)


func can_upgrade_studio() -> bool:
	return can_purchase_studio_room(0)


func upgrade_studio() -> bool:
	return purchase_studio_room(0)


func get_studio_room_count(floor_index: int) -> int:
	return clampi(int(studio_rooms.get(str(clampi(floor_index, 0, 1)), 0)), 0, MAX_STUDIO_ROOMS_PER_FLOOR)


func is_studio_floor_available(floor_index: int) -> bool:
	return floor_index == 0 or get_studio_room_count(1) > 0


func is_studio_room_purchase_unlocked(floor_index: int) -> bool:
	return bool(studio_room_purchase_unlocked.get(str(clampi(floor_index, 0, 1)), false))


func can_unlock_studio_room_purchase(floor_index: int) -> bool:
	floor_index = clampi(floor_index, 0, 1)
	if get_studio_room_count(floor_index) >= MAX_STUDIO_ROOMS_PER_FLOOR:
		return false
	if floor_index == 1 and get_studio_room_count(0) < MAX_STUDIO_ROOMS_PER_FLOOR:
		return false
	return not is_studio_room_purchase_unlocked(floor_index)


func unlock_studio_room_purchase(floor_index: int, save_after := true) -> bool:
	if not can_unlock_studio_room_purchase(floor_index):
		return false
	studio_room_purchase_unlocked[str(clampi(floor_index, 0, 1))] = true
	studio_expansion_changed.emit()
	shop_changed.emit()
	if save_after:
		save_profile()
	return true


func get_studio_room_cost(floor_index: int) -> int:
	floor_index = clampi(floor_index, 0, 1)
	var room_count := get_studio_room_count(floor_index)
	if room_count >= MAX_STUDIO_ROOMS_PER_FLOOR:
		return 0
	if floor_index == 0:
		return FIRST_FLOOR_ROOM_COSTS[room_count]
	return SECOND_FLOOR_ROOM_COSTS[room_count]


func can_purchase_studio_room(floor_index: int) -> bool:
	floor_index = clampi(floor_index, 0, 1)
	if not is_studio_room_purchase_unlocked(floor_index):
		return false
	if floor_index == 1 and get_studio_room_count(0) < MAX_STUDIO_ROOMS_PER_FLOOR:
		return false
	var cost := get_studio_room_cost(floor_index)
	return cost > 0 and money >= cost


func purchase_studio_room(floor_index: int, save_after := true) -> bool:
	floor_index = clampi(floor_index, 0, 1)
	if not can_purchase_studio_room(floor_index):
		return false
	var cost := get_studio_room_cost(floor_index)
	money -= cost
	var next_count := get_studio_room_count(floor_index) + 1
	studio_rooms[str(floor_index)] = next_count
	# Every new plot needs a deliberate expansion action before it appears as a
	# purchasable room. This prevents one click from buying several rooms.
	studio_room_purchase_unlocked[str(floor_index)] = false
	_sync_legacy_studio_tier()
	money_changed.emit(money)
	studio_rooms_changed.emit(floor_index, next_count)
	studio_expansion_changed.emit()
	studio_tier_changed.emit(studio_tier)
	shop_changed.emit()
	if save_after:
		save_profile()
	return true


func add_debug_money(amount := 5000, save_after := true) -> int:
	money += maxi(0, amount)
	money_changed.emit(money)
	shop_changed.emit()
	if save_after:
		save_profile()
	return money


func _recalculate_active_skills() -> void:
	var next: Array[String] = []
	for entry: Dictionary in placed_studio_layout:
		var item := get_studio_item(String(entry.get("kind", "")))
		var skill_id := String(item.get("skill_id", ""))
		if not skill_id.is_empty() and not next.has(skill_id):
			next.append(skill_id)
	if next != active_skills:
		active_skills = next
		skills_changed.emit(active_skills.duplicate())


func _load_static_data() -> void:
	campaign_data = _read_json(CAMPAIGN_PATH)
	catalog_data = _read_json(CATALOG_PATH)


func _load_studio_room_progress(payload: Dictionary) -> void:
	var saved_rooms: Variant = payload.get("studio_rooms", null)
	if saved_rooms is Dictionary:
		studio_rooms = {
			"0": clampi(int((saved_rooms as Dictionary).get("0", 1)), 1, MAX_STUDIO_ROOMS_PER_FLOOR),
			"1": clampi(int((saved_rooms as Dictionary).get("1", 0)), 0, MAX_STUDIO_ROOMS_PER_FLOOR)
		}
	else:
		# One-time migration from the former 1/2/3 whole-room scale system.
		match studio_tier:
			1: studio_rooms = {"0": 1, "1": 0}
			2: studio_rooms = {"0": 2, "1": 0}
			_: studio_rooms = {"0": 4, "1": 1}
	var saved_unlocks: Variant = payload.get("studio_room_purchase_unlocked", {})
	studio_room_purchase_unlocked = {
		"0": bool((saved_unlocks as Dictionary).get("0", false)) if saved_unlocks is Dictionary else false,
		"1": bool((saved_unlocks as Dictionary).get("1", false)) if saved_unlocks is Dictionary else false
	}
	_sync_legacy_studio_tier()


func _sync_legacy_studio_tier() -> void:
	if get_studio_room_count(1) > 0:
		studio_tier = 3
	elif get_studio_room_count(0) > 1:
		studio_tier = 2
	else:
		studio_tier = 1


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing data file: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return (parsed as Dictionary).duplicate(true)
	push_error("Invalid JSON data file: %s" % path)
	return {}


func _initialize_mail_state() -> void:
	for value: Variant in campaign_data.get("mail", []):
		if not value is Dictionary:
			continue
		var mail_id := String((value as Dictionary).get("mail_id", ""))
		if not mail_id.is_empty() and not mail_state.has(mail_id):
			mail_state[mail_id] = {"is_read": false, "is_accepted": false}


func _mail_requirements_met(item: Dictionary) -> bool:
	for case_id_value: Variant in item.get("required_completed_cases", []):
		if not bool(completed_cases.get(String(case_id_value), false)):
			return false
	return true


func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for item: Variant in value:
			if item is Dictionary:
				result.append((item as Dictionary).duplicate(true))
	return result


func _clear_saved_album_images() -> void:
	var directory := DirAccess.open(ALBUM_DIRECTORY)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry_name := directory.get_next()
	while not entry_name.is_empty():
		if not directory.current_is_dir():
			directory.remove(entry_name)
		entry_name = directory.get_next()
	directory.list_dir_end()


func _emit_all() -> void:
	money_changed.emit(money)
	mail_changed.emit()
	shop_changed.emit()
	studio_layout_changed.emit()
	studio_tier_changed.emit(studio_tier)
	studio_rooms_changed.emit(0, get_studio_room_count(0))
	studio_rooms_changed.emit(1, get_studio_room_count(1))
	studio_expansion_changed.emit()
	skills_changed.emit(active_skills.duplicate())
