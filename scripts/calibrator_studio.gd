extends Node3D

const INVESTIGATION_UI := preload("res://scripts/investigation_ui_theme.gd")


const STUDIO_UI := preload("res://scripts/studio_dossier_ui_theme.gd")

const FLOOR_HEIGHT := 3.65
const ROOM_SIZE := Vector2(10.2, 8.6)
const ROOM_ORIGIN := Vector2(0.0, -0.7)
const ROOM_WALL_HEIGHT := 3.3
const ROOM_PLOT_SEQUENCE: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
const FLOOR_FADE_DURATION := 0.28
const CAMERA_DURATION := 0.65
const OVERVIEW_FOV := 35.0
const FOCUS_FOV := 24.0
const FOCUS_FOV_MIN := 17.0
const FOCUS_FOV_MAX := 34.0
const FOCUS_FOV_STEP := 1.0
const FOCUS_YAW_LIMIT := 45.0
const FOCUS_PITCH_LIMIT := 22.0
const FOCUS_ORBIT_SENSITIVITY := 0.20
const FOCUS_PAN_SENSITIVITY := 0.006
const FOCUS_PAN_HORIZONTAL_LIMIT := 1.6
const FOCUS_PAN_VERTICAL_LIMIT := 1.0
const FOCUS_VIEW_OFFSET := Vector3(3.8, 3.15, 4.45)
const ROTATION_GIZMO_LAYER := 8
const ROTATION_GIZMO_SENSITIVITY := 0.42
const FURNITURE_LAYER := 4
const CATALOG_RESERVED_WIDTH := 306.0
const CATALOG_PAGE_SIZE := 4

var profile: Node
var camera: Camera3D
var furniture_root: Node3D
var shell_root: Node3D
var ui_root: Control
var hud_root: Control
var catalog_list: Control
var catalog_slots: Array[Control] = []
var catalog_cards: Array[CatalogItem] = []
var catalog_empty_label: Label
var catalog_scroll: ScrollContainer
var catalog_panel: PanelContainer
var catalog_tabs_layer: Control
var catalog_page_buttons: Array[Button] = []
var catalog_entries: Array[Dictionary] = []
var catalog_page := 0
var mode_label: Label
var money_label: Label
var status_label: Label
var work_button: Button
var floor1_button: Button
var floor2_button: Button
var room_pan_panel: PanelContainer
var floor_fade_overlay: ColorRect
var computer_ui: StudioComputerUI
var furniture_menu: PanelContainer
var furniture_menu_title: Label
var furniture_rotate_button: Button
var overview_button: Button
var open_computer_button: Button
var return_build_button: Button
var rotation_overlay: ColorRect

var active_floor := 0
var overview_room_pan := Vector2.ZERO
var floor_switching := false
var build_mode := true
var active_kind := ""
var active_preview: Node3D
var preview_rotation := Vector3.ZERO
var preview_valid := false
var preview_support: Node3D
var preview_wall_attachment: Dictionary = {}
var placing_from_inventory := false
var selected_furniture: Node3D
var moving_furniture: Node3D
var moving_original_transform := Transform3D.IDENTITY
var moving_supported_items: Array[Dictionary] = []
var pending_world_drag := false
var world_press_position := Vector2.ZERO

var selection_marker: Node3D
var rotation_mode := false
var rotation_gizmo: Node3D
var gizmo_dragging := false
var gizmo_axis_index := -1
var gizmo_last_mouse_position := Vector2.ZERO

var camera_tween: Tween
var camera_transitioning := false
var camera_focused := false
var focus_target_position := Vector3.ZERO
var focus_yaw := 0.0
var focus_target_yaw := 0.0
var focus_pitch := 0.0
var focus_target_pitch := 0.0
var focus_fov := FOCUS_FOV
var focus_target_fov := FOCUS_FOV
var focus_pan := Vector2.ZERO
var focus_target_pan := Vector2.ZERO
var orbit_dragging := false
var focus_pan_dragging := false

var _wall_style := 0
var _floor_style := 0
var _desktop_hud_was_visible := true
var _debug_case_jump_in_progress := false


func _ready() -> void:
	profile = get_node_or_null("/root/PlayerProfile")
	camera = $StudioCamera
	furniture_root = $StudioFurniture
	shell_root = $StudioShell
	ui_root = $StudioUI/UIRoot
	if not is_instance_valid(profile):
		push_error("PlayerProfile Autoload is missing")
		return
	_wall_style = int((profile.get("studio_shell") as Dictionary).get("wall_style", 0))
	_floor_style = int((profile.get("studio_shell") as Dictionary).get("floor_style", 0))
	_build_shell()
	_restore_layout()
	_build_ui()
	GameAudio.set_ambience("amb_studio")
	_refresh_catalog()
	_switch_floor(0, false)
	_set_status("搭建模式 · 从右侧拖出家具，或按住场内家具直接移动 · Q/E 旋转 90°", Color("cbbce5"))


func _process(delta: float) -> void:
	if not active_kind.is_empty() and is_instance_valid(active_preview):
		_update_preview()
	if camera_focused and not camera_transitioning:
		_update_focus_camera(delta)


func _input(event: InputEvent) -> void:
	if is_instance_valid(computer_ui) and computer_ui.visible:
		return
	if floor_switching:
		return
	if gizmo_dragging:
		if event is InputEventMouseMotion:
			_update_rotation_gizmo_drag(event)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_end_rotation_gizmo_drag()
		return
	if rotation_mode:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			_confirm_rotation_mode()
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_try_begin_rotation_gizmo_drag(event.position)
		return
	if not active_kind.is_empty():
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
				_finish_placement()
			elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				_cancel_placement()
		elif event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				_cancel_placement()
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_Q:
				_rotate_active_preview(-90.0)
			elif event.keycode == KEY_E:
				_rotate_active_preview(90.0)
		return
	if camera_focused:
		_handle_focus_camera_input(event)
		return
	if camera_transitioning:
		return
	if not build_mode:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if _pointer_over_ui(event.position):
				return
			var clicked := _pick_furniture(event.position)
			if is_instance_valid(clicked) and String(clicked.get_meta("studio_kind", "")) == "studio_computer":
				computer_ui.open_desktop()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_pointer_over_furniture_menu(event.position) or _pointer_over_ui(event.position):
			return
		if event.pressed:
			_handle_world_press(event.position)
		elif pending_world_drag:
			pending_world_drag = false
			_show_furniture_menu(event.position)
	elif event is InputEventMouseMotion and pending_world_drag:
		if event.position.distance_to(world_press_position) > 5.0:
			_begin_move_selected()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_DELETE, KEY_BACKSPACE]:
			_store_selected()
		elif event.keycode == KEY_ESCAPE and is_instance_valid(selected_furniture):
			_clear_selection(true)
			get_viewport().set_input_as_handled()


func _build_shell() -> void:
	var exact_shell := shell_root.get_node_or_null("AuthoredEmptyStudio") as Node3D
	for child: Node in shell_root.get_children():
		if child != exact_shell:
			child.queue_free()
	var floor_color: Color = [Color("5a6873"), Color("766252"), Color("57685b")][_floor_style]
	var wall_color: Color = [Color("b8b5aa"), Color("8f9bab"), Color("b4a28d")][_wall_style]
	var authored_architecture := _wall_style == 0 and int(profile.call("get_studio_room_count", 0)) > 0
	var authored_floor := _floor_style == 0 and int(profile.call("get_studio_room_count", 0)) > 0
	if is_instance_valid(exact_shell):
		exact_shell.set_meta("studio_floor", 0)
		var architecture := exact_shell.get_node_or_null("Architecture") as Node3D
		var wood_floor := exact_shell.get_node_or_null("WoodFloor") as Node3D
		if is_instance_valid(architecture):
			architecture.visible = authored_architecture
		if is_instance_valid(wood_floor):
			wood_floor.visible = authored_floor
	for floor_index: int in range(2):
		var room_count := int(profile.call("get_studio_room_count", floor_index))
		for room_index: int in range(room_count):
			var plot := ROOM_PLOT_SEQUENCE[room_index]
			var center2 := _room_plot_center(room_index)
			var base_y := float(floor_index) * FLOOR_HEIGHT
			var prefix := "Floor%02dRoom%02d" % [floor_index + 1, room_index + 1]
			var room_floor_color := floor_color.lightened(0.06 * floor_index)
			var is_authored_base := floor_index == 0 and room_index == 0
			if not (is_authored_base and authored_floor):
				_add_shell_box(prefix + "Floor", Vector3(ROOM_SIZE.x - 0.08, 0.18, ROOM_SIZE.y - 0.08), Vector3(center2.x, base_y - 0.09, center2.y), room_floor_color, floor_index)
			# The isometric room keeps the front and right open. Back/left walls are
			# only created along the outer boundary, so adjacent plots join cleanly.
			if plot.y == 0 and not (is_authored_base and authored_architecture):
				_add_shell_box(prefix + "BackWall", Vector3(ROOM_SIZE.x, ROOM_WALL_HEIGHT, 0.16), Vector3(center2.x, base_y + ROOM_WALL_HEIGHT * 0.5, center2.y - ROOM_SIZE.y * 0.5), wall_color, floor_index)
			if plot.x == 0 and not (is_authored_base and authored_architecture):
				_add_shell_box(prefix + "LeftWall", Vector3(0.16, ROOM_WALL_HEIGHT, ROOM_SIZE.y), Vector3(center2.x - ROOM_SIZE.x * 0.5, base_y + ROOM_WALL_HEIGHT * 0.5, center2.y), wall_color.darkened(0.08), floor_index)
			# A very low seam makes each purchased plot readable without blocking
			# furniture or turning the four rooms into separate interaction systems.
			if plot.x > 0:
				_add_shell_box(prefix + "XSeam", Vector3(0.055, 0.025, ROOM_SIZE.y - 0.20), Vector3(center2.x - ROOM_SIZE.x * 0.5, base_y + 0.013, center2.y), wall_color.darkened(0.18), floor_index)
			if plot.y > 0:
				_add_shell_box(prefix + "ZSeam", Vector3(ROOM_SIZE.x - 0.20, 0.025, 0.055), Vector3(center2.x, base_y + 0.013, center2.y - ROOM_SIZE.y * 0.5), wall_color.darkened(0.18), floor_index)
	_apply_floor_visibility()


func _add_shell_box(node_name: String, size: Vector3, position: Vector3, color: Color, floor_index := 0) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	mesh_instance.material_override = material
	mesh_instance.set_meta("studio_floor", floor_index)
	shell_root.add_child(mesh_instance)


func _build_ui() -> void:
	hud_root = ui_root.get_node("StudioHUD") as Control
	mode_label = hud_root.get_node("StudioTitlePanel/EditableContent/ModeLabel") as Label
	money_label = hud_root.get_node("StudioTitlePanel/EditableContent/MoneyLabel") as Label
	status_label = hud_root.get_node("ArchiveStatusPanel/EditableContent/StatusLabel") as Label
	floor1_button = hud_root.get_node("StudioToolsPanel/Floor1Button") as Button
	floor2_button = hud_root.get_node("StudioToolsPanel/Floor2Button") as Button
	catalog_panel = hud_root.get_node("ArchiveInventoryPanel") as PanelContainer
	catalog_scroll = hud_root.get_node("ArchiveInventoryPanel/EditableContent/FurniturePageViewport") as ScrollContainer
	catalog_list = hud_root.get_node("ArchiveInventoryPanel/EditableContent/FurniturePageViewport/CatalogList") as Control
	catalog_slots.clear()
	catalog_cards.clear()
	for slot_index: int in range(CATALOG_PAGE_SIZE):
		var slot := catalog_list.get_node("CatalogSlot%d" % (slot_index + 1)) as Control
		catalog_slots.append(slot)
		var card := slot.get_node("CatalogCard") as CatalogItem
		card.drag_started.connect(_begin_inventory_drag)
		catalog_cards.append(card)
	catalog_empty_label = catalog_list.get_node("CatalogEmptyLabel") as Label
	catalog_tabs_layer = hud_root.get_node("FurniturePageTabs") as Control
	work_button = hud_root.get_node("ArchiveInventoryPanel/EditableContent/WorkButton") as Button
	furniture_menu = hud_root.get_node("FurnitureActionMenu") as PanelContainer
	furniture_menu_title = hud_root.get_node("FurnitureActionMenu/EditableContent/FurnitureMenuTitle") as Label
	furniture_rotate_button = hud_root.get_node("FurnitureActionMenu/EditableContent/FurnitureRotateButton") as Button
	room_pan_panel = hud_root.get_node("RoomPanControls") as PanelContainer
	rotation_overlay = hud_root.get_node("RotationOverlay") as ColorRect
	overview_button = hud_root.get_node("OverviewButton") as Button
	open_computer_button = hud_root.get_node("OpenComputerButton") as Button
	return_build_button = hud_root.get_node("ReturnBuildButton") as Button

	floor1_button.pressed.connect(func() -> void: await _switch_floor(0))
	floor2_button.pressed.connect(func() -> void: await _switch_floor(1))
	(hud_root.get_node("StudioToolsPanel/WallStyleButton") as Button).pressed.connect(_cycle_wall_style)
	(hud_root.get_node("StudioToolsPanel/FloorStyleButton") as Button).pressed.connect(_cycle_floor_style)
	(hud_root.get_node("StudioToolsPanel/DebugAddMoneyButton") as Button).pressed.connect(_add_debug_money)
	(hud_root.get_node("DebugCaseJumpPanel/DebugJumpFirstCaseButton") as Button).pressed.connect(_debug_jump_to_case.bind("office_case_001"))
	(hud_root.get_node("DebugCaseJumpPanel/DebugJumpSecondCaseButton") as Button).pressed.connect(_debug_jump_to_case.bind("gallery_case_002"))
	overview_button.pressed.connect(_focus_overview)
	open_computer_button.pressed.connect(func() -> void: computer_ui.open_desktop())
	return_build_button.pressed.connect(_enter_build_mode)
	(hud_root.get_node("FurnitureActionMenu/EditableContent/InspectFurnitureButton") as Button).pressed.connect(_focus_selected_furniture)
	furniture_rotate_button.pressed.connect(_enter_rotation_mode)
	(hud_root.get_node("FurnitureActionMenu/EditableContent/StoreFurnitureButton") as Button).pressed.connect(_store_selected)
	work_button.pressed.connect(_toggle_work_mode)
	catalog_page_buttons.clear()
	for page_index: int in range(4):
		var tab := catalog_tabs_layer.get_node("FurniturePageTab%d" % (page_index + 1)) as Button
		tab.pressed.connect(_set_catalog_page.bind(page_index))
		catalog_page_buttons.append(tab)
	(hud_root.get_node("RoomPanControls/EditableContent/PanLeftButton") as Button).pressed.connect(_pan_overview.bind(Vector2(-1, 0)))
	(hud_root.get_node("RoomPanControls/EditableContent/PanUpButton") as Button).pressed.connect(_pan_overview.bind(Vector2(0, -1)))
	(hud_root.get_node("RoomPanControls/EditableContent/PanCenterButton") as Button).pressed.connect(_center_overview_pan)
	(hud_root.get_node("RoomPanControls/EditableContent/PanDownButton") as Button).pressed.connect(_pan_overview.bind(Vector2(0, 1)))
	(hud_root.get_node("RoomPanControls/EditableContent/PanRightButton") as Button).pressed.connect(_pan_overview.bind(Vector2(1, 0)))
	(hud_root.get_node("RotationOverlay/RotationDialog/EditableContent/ConfirmRotationButton") as Button).pressed.connect(_confirm_rotation_mode)
	_refresh_room_pan_controls()
	_build_floor_fade_overlay()

	computer_ui = StudioComputerUI.new()
	computer_ui.setup(profile)
	computer_ui.z_index = 100
	ui_root.add_child(computer_ui)
	computer_ui.opened.connect(_on_desktop_opened)
	computer_ui.closed.connect(_on_desktop_closed)
	profile.money_changed.connect(func(_amount: int) -> void: _refresh_catalog())
	profile.shop_changed.connect(_refresh_catalog)
	profile.studio_tier_changed.connect(_on_tier_changed)
	profile.studio_rooms_changed.connect(_on_studio_rooms_changed)


func _debug_jump_to_case(case_id: String) -> void:
	if _debug_case_jump_in_progress:
		return
	var flow := get_node_or_null("/root/GameFlow")
	if not is_instance_valid(flow):
		_set_status("关卡跳转失败：GameFlow 不可用", Color("e18b91"))
		return
	_debug_case_jump_in_progress = true
	_cancel_placement(false)
	_clear_selection(false)
	_save_layout()
	_set_status("测试跳转 · 正在载入%s……" % ("第一关" if case_id == "office_case_001" else "第二关"), Color("75c8ff"))
	var succeeded := bool(await flow.call("start_case", case_id))
	if is_instance_valid(self) and not succeeded:
		_debug_case_jump_in_progress = false
		_set_status("关卡跳转失败，请检查案件配置", Color("e18b91"))


func _catalog_page_count() -> int:
	return maxi(1, ceili(float(catalog_entries.size()) / float(CATALOG_PAGE_SIZE)))


func _set_catalog_page(page_index: int) -> void:
	var page_count := _catalog_page_count()
	if page_index < 0 or page_index >= page_count:
		return
	if page_index != catalog_page:
		GameAudio.play("page_turn")
	catalog_page = page_index
	_render_catalog_page()


func _update_catalog_page_tabs() -> void:
	var page_count := _catalog_page_count()
	for index: int in range(catalog_page_buttons.size()):
		var tab := catalog_page_buttons[index]
		if not is_instance_valid(tab):
			continue
		tab.disabled = index >= page_count
		INVESTIGATION_UI.page_tab(tab, index == catalog_page)
		tab.modulate = Color.WHITE
		tab.tooltip_text = "家具栏第 %d 页" % (index + 1) if index < page_count else "暂无家具"


func _build_floor_fade_overlay() -> void:
	floor_fade_overlay = ui_root.get_node("FloorTransitionFade") as ColorRect


func _refresh_catalog() -> void:
	if not is_instance_valid(catalog_list):
		return
	catalog_entries.clear()
	var available := profile.call("get_available_studio_inventory") as Dictionary
	var kinds: Array = available.keys()
	kinds.sort_custom(func(a: String, b: String) -> bool:
		var order := ["studio_desk", "studio_chair", "studio_computer", "studio_bookshelf"]
		var a_rank := order.find(a)
		var b_rank := order.find(b)
		if a_rank < 0: a_rank = 100
		if b_rank < 0: b_rank = 100
		return a < b if a_rank == b_rank else a_rank < b_rank)
	for kind_value: Variant in kinds:
		var kind := String(kind_value)
		var count := int(available[kind])
		if count <= 0:
			continue
		var info := StudioFurnitureFactory.get_info(kind)
		var item_data := profile.call("get_studio_item", kind) as Dictionary
		var size: Vector3 = info.size
		catalog_entries.append({
			"kind": kind,
			"icon_kind": _catalog_icon_kind(kind),
			"label": "%s  × %d" % [String(info.label), count],
			"description": "仅可吸附墙面 · 点击可检视" if bool(info.get("wall_item", false)) else _short_description(item_data),
			"footprint": Vector2i(maxi(1, ceili(size.x)), maxi(1, ceili(size.z))),
			"color": info.color
		})
	catalog_page = clampi(catalog_page, 0, _catalog_page_count() - 1)
	_render_catalog_page()
	if is_instance_valid(money_label):
		money_label.text = "余额 ¥%d　 一楼 %d/4　 二楼 %d/4" % [
			int(profile.get("money")),
			int(profile.call("get_studio_room_count", 0)),
			int(profile.call("get_studio_room_count", 1))
		]


func _render_catalog_page() -> void:
	if not is_instance_valid(catalog_list):
		return
	for card: CatalogItem in catalog_cards:
		card.hide()
	var first_index := catalog_page * CATALOG_PAGE_SIZE
	var last_index := mini(first_index + CATALOG_PAGE_SIZE, catalog_entries.size())
	for entry_index: int in range(first_index, last_index):
		var entry := catalog_entries[entry_index]
		var card := catalog_cards[entry_index - first_index]
		card.setup({
			"kind": entry.kind,
			"visual_style": "studio_dossier",
			"icon_kind": entry.icon_kind,
			"label": entry.label,
			"description": entry.description,
			"footprint": entry.footprint,
			"color": entry.color
		})
		card.show()
	catalog_empty_label.visible = first_index == last_index
	_update_catalog_page_tabs()


func _add_debug_money() -> void:
	profile.call("add_debug_money", 5000)
	_refresh_catalog()
	_set_status("测试资金已增加 ¥5000", Color("f0cc78"))


func _catalog_icon_kind(kind: String) -> String:
	match kind:
		"studio_desk": return "desk"
		"studio_chair": return "chair"
		"studio_computer": return "computer"
		"studio_bookshelf": return "shelf"
		"studio_lamp": return "lamp"
		"studio_plant": return "plant"
		"case_frame_office", "case_frame_gallery", "case_frame_apartment": return "case_frame"
		_: return kind


func _short_description(item: Dictionary) -> String:
	return "摆入工作室后启用能力" if not String(item.get("skill_id", "")).is_empty() else "自由摆放 · Q/E 旋转"


func _begin_inventory_drag(kind: String) -> void:
	_begin_placement(kind, null, true)


func _begin_placement(kind: String, moving: Node3D = null, from_inventory := false) -> void:
	if not build_mode or camera_focused or rotation_mode:
		return
	_cancel_placement(false)
	_hide_furniture_menu()
	active_kind = kind
	placing_from_inventory = from_inventory
	preview_wall_attachment.clear()
	preview_rotation = moving.rotation_degrees if is_instance_valid(moving) else Vector3.ZERO
	active_preview = StudioFurnitureFactory.build(kind, true)
	GameAudio.begin_drag(self, moving.global_position if is_instance_valid(moving) else Vector3.ZERO)
	active_preview.rotation_degrees = preview_rotation
	add_child(active_preview)
	if is_instance_valid(moving):
		moving_furniture = moving
		moving_original_transform = moving.global_transform
		active_floor = int(moving.get_meta("studio_floor", active_floor))
		_prepare_supported_items(moving)
		moving.visible = false
	var info := StudioFurnitureFactory.get_info(kind)
	_set_status(
		"墙面相框 · 移向墙面自动吸附 · 松开确认 · 右键或 Esc 取消"
		if bool(info.get("wall_item", false))
		else "自由移动中 · Q/E 每次旋转 90° · 松开确认 · 右键或 Esc 取消",
		Color("d9c4f1")
	)


func _update_preview() -> void:
	var mouse := get_viewport().get_mouse_position()
	var viewport_size := get_viewport().get_visible_rect().size
	if mouse.x >= viewport_size.x - CATALOG_RESERVED_WIDTH:
		active_preview.visible = false
		preview_valid = false
		return
	var origin := camera.project_ray_origin(mouse)
	var direction := camera.project_ray_normal(mouse)
	var info := StudioFurnitureFactory.get_info(active_kind)
	var object_size: Vector3 = info.size
	if bool(info.get("wall_item", false)):
		var attachment := _find_wall_snap(origin, direction, object_size, active_floor)
		if attachment.is_empty():
			active_preview.visible = false
			preview_valid = false
			preview_wall_attachment.clear()
			_set_status("相框只能放在已购买房间的墙面上", Color("ff9da6"))
			return
		preview_wall_attachment = attachment
		preview_rotation = Vector3(0, float(attachment.get("yaw", 0.0)), 0)
		var wall_position := attachment.get("position", Vector3.ZERO) as Vector3
		active_preview.global_position = wall_position
		active_preview.rotation_degrees = preview_rotation
		active_preview.visible = true
		preview_support = null
		preview_valid = _wall_placement_clear(wall_position, object_size, moving_furniture, attachment)
		_set_status(
			"已吸附墙面 · 松开确认" if preview_valid else "该墙面位置已有其他相框",
			Color("98e3b4") if preview_valid else Color("ff9da6")
		)
		return
	var floor_y := float(active_floor) * FLOOR_HEIGHT
	if absf(direction.y) < 0.0001:
		return
	var distance := (floor_y - origin.y) / direction.y
	if distance <= 0.0:
		active_preview.visible = false
		preview_valid = false
		return
	var world := origin + direction * distance
	var projected := _projected_box(object_size, preview_rotation)
	var min_offset: Vector3 = projected.min
	var max_offset: Vector3 = projected.max
	var dimensions := _floor_dimensions(active_floor)
	var center := _floor_center(active_floor)
	world.x = clampf(world.x, center.x - dimensions.x * 0.5 - min_offset.x, center.x + dimensions.x * 0.5 - max_offset.x)
	world.z = clampf(world.z, center.y - dimensions.y * 0.5 - min_offset.z, center.y + dimensions.y * 0.5 - max_offset.z)
	preview_support = null
	var surface_y := floor_y
	if bool(info.get("desk_item", false)):
		preview_support = _desk_under_position(world, moving_furniture)
		if is_instance_valid(preview_support):
			surface_y = _desk_surface_height(preview_support)
	world.y = surface_y - min_offset.y
	active_preview.global_position = world
	active_preview.rotation_degrees = preview_rotation
	active_preview.visible = true
	preview_valid = (not bool(info.get("desk_item", false)) or is_instance_valid(preview_support)) and _placement_clear(world, object_size, preview_rotation, moving_furniture, preview_support)
	GameAudio.update_drag(self, active_preview.global_position, active_kind)
	_sync_supported_items(active_preview.global_transform)
	if preview_valid:
		_set_status("%s · Q/E 每次旋转 90° · 松开确认" % ("已吸附桌面" if is_instance_valid(preview_support) else "可放置"), Color("98e3b4"))
	else:
		_set_status("这里不能放置：家具必须完整位于房间内，桌面物品必须吸附到工作桌", Color("ff9da6"))


func _rotate_active_preview(amount: float) -> void:
	if bool(StudioFurnitureFactory.get_info(active_kind).get("wall_item", false)):
		_set_status("墙面相框会自动朝向所吸附的墙面", Color("d9c4f1"))
		return
	preview_rotation.y = fposmod(preview_rotation.y + amount, 360.0)
	if is_instance_valid(active_preview):
		active_preview.rotation_degrees = preview_rotation
	_update_preview()
	if is_instance_valid(active_preview):
		GameAudio.play("furniture_rotate", active_preview.global_position)


func _finish_placement() -> void:
	if not preview_valid or not is_instance_valid(active_preview) or not active_preview.visible:
		GameAudio.play("placement_invalid")
		_set_status("本次没有放置：请把家具完整放在室内；电脑必须放在桌面上。", Color("ff9da6"))
		_cancel_placement(false)
		return
	var transform_value := active_preview.global_transform
	var node: Node3D
	if is_instance_valid(moving_furniture):
		node = moving_furniture
		node.visible = true
	else:
		node = StudioFurnitureFactory.build(active_kind)
		furniture_root.add_child(node)
		_ensure_furniture_uid(node)
	node.global_transform = transform_value
	node.set_meta("studio_floor", active_floor)
	if not preview_wall_attachment.is_empty():
		node.set_meta("wall_side", String(preview_wall_attachment.get("side", "")))
		node.set_meta("wall_room", int(preview_wall_attachment.get("room_index", 0)))
	else:
		node.remove_meta("wall_side")
		node.remove_meta("wall_room")
	if is_instance_valid(preview_support):
		node.set_meta("support_uid", _ensure_furniture_uid(preview_support))
	else:
		node.remove_meta("support_uid")
	_commit_supported_items(node)
	GameAudio.play_placement(active_kind, node.global_position)
	GameAudio.end_drag(self)
	active_preview.queue_free()
	active_preview = null
	active_kind = ""
	moving_furniture = null
	placing_from_inventory = false
	preview_rotation = Vector3.ZERO
	preview_valid = false
	preview_support = null
	preview_wall_attachment.clear()
	_save_layout()
	_refresh_catalog()
	_select_furniture(node)
	_set_status("位置已更新 · 按住家具可继续移动，单击可打开检视 / 旋转 / 收纳菜单", Color("a7e5bb"))


func _cancel_placement(show_message := true) -> void:
	if show_message and is_instance_valid(active_preview):
		GameAudio.play("paper_cancel")
	GameAudio.end_drag(self)
	if is_instance_valid(active_preview):
		active_preview.queue_free()
	if is_instance_valid(moving_furniture):
		moving_furniture.global_transform = moving_original_transform
		moving_furniture.visible = true
	_restore_supported_items()
	active_preview = null
	active_kind = ""
	moving_furniture = null
	placing_from_inventory = false
	preview_rotation = Vector3.ZERO
	preview_valid = false
	preview_support = null
	preview_wall_attachment.clear()
	if show_message:
		_set_status("已取消放置", Color("bdb2ca"))


func _handle_world_press(screen_position: Vector2) -> void:
	_hide_furniture_menu()
	var clicked := _pick_furniture(screen_position)
	if not is_instance_valid(clicked):
		_clear_selection(false)
		return
	_select_furniture(clicked)
	pending_world_drag = true
	world_press_position = screen_position


func _begin_move_selected() -> void:
	pending_world_drag = false
	if not is_instance_valid(selected_furniture):
		return
	var moving := selected_furniture
	var kind := String(moving.get_meta("studio_kind", ""))
	_clear_selection(false)
	_begin_placement(kind, moving, false)


func _pick_furniture(screen_position: Vector2) -> Node3D:
	var origin := camera.project_ray_origin(screen_position)
	var end := origin + camera.project_ray_normal(screen_position) * 100.0
	var query := PhysicsRayQueryParameters3D.create(origin, end, FURNITURE_LAYER)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	var collider := hit.get("collider", null) as Node
	if is_instance_valid(collider) and collider.has_meta("studio_furniture_root"):
		return collider.get_meta("studio_furniture_root") as Node3D
	return null


func _select_furniture(node: Node3D) -> void:
	_clear_selection(false)
	if not is_instance_valid(node):
		return
	selected_furniture = node
	_create_selection_marker()
	var kind := String(node.get_meta("studio_kind", ""))
	_set_status("已选中「%s」· 按住拖动，单击打开检视 / 旋转 / 收纳菜单" % String(StudioFurnitureFactory.get_info(kind).label), Color("ffd47e"))


func _show_furniture_menu(screen_position: Vector2) -> void:
	if not is_instance_valid(selected_furniture) or camera_focused or rotation_mode:
		return
	var kind := String(selected_furniture.get_meta("studio_kind", ""))
	var wall_item := bool(StudioFurnitureFactory.get_info(kind).get("wall_item", false))
	if is_instance_valid(furniture_rotate_button):
		furniture_rotate_button.disabled = wall_item
		furniture_rotate_button.tooltip_text = "相框朝向由墙面自动决定" if wall_item else "进入 XYZ 旋转模式"
	furniture_menu_title.text = "已选择「%s」" % String(StudioFurnitureFactory.get_info(kind).label)
	var viewport_size := get_viewport().get_visible_rect().size
	var menu_size := Vector2(286, 94)
	var catalog_left := viewport_size.x - CATALOG_RESERVED_WIDTH
	var menu_x := screen_position.x + 16.0
	if menu_x + menu_size.x > catalog_left - 8.0:
		menu_x = screen_position.x - menu_size.x - 16.0
	menu_x = clampf(menu_x, 12.0, catalog_left - menu_size.x - 8.0)
	var menu_y := clampf(screen_position.y - menu_size.y * 0.5, 88.0, viewport_size.y - menu_size.y - 78.0)
	furniture_menu.position = Vector2(menu_x, menu_y)
	furniture_menu.visible = true


func _hide_furniture_menu() -> void:
	if is_instance_valid(furniture_menu):
		furniture_menu.visible = false


func _is_pointer_over_furniture_menu(screen_position: Vector2) -> bool:
	return is_instance_valid(furniture_menu) and furniture_menu.visible and furniture_menu.get_global_rect().has_point(screen_position)


func _store_selected() -> void:
	_hide_furniture_menu()
	if not is_instance_valid(selected_furniture):
		return
	var node := selected_furniture
	GameAudio.play("furniture_pickup", node.global_position)
	var uid := String(node.get_meta("studio_uid", ""))
	var stored_supported_count := 0
	for child: Node in furniture_root.get_children():
		if child is Node3D and String(child.get_meta("support_uid", "")) == uid:
			# Desktop objects are stored together with their supporting desk, so they can
			# never be left suspended or stranded in an invalid floor position.
			child.queue_free()
			stored_supported_count += 1
	node.queue_free()
	_clear_selection(false)
	await get_tree().process_frame
	_save_layout()
	_refresh_catalog()
	_set_status("家具已收纳回右侧栏位%s。" % ("，桌面物品也已一并收纳" if stored_supported_count > 0 else ""), Color("e0b98b"))


func _clear_selection(restore_camera := false) -> void:
	pending_world_drag = false
	_hide_furniture_menu()
	selected_furniture = null
	if is_instance_valid(selection_marker):
		selection_marker.queue_free()
	selection_marker = null
	_destroy_rotation_gizmo()
	if restore_camera:
		_focus_overview()


func _create_selection_marker() -> void:
	if not is_instance_valid(selected_furniture):
		return
	var info := StudioFurnitureFactory.get_info(String(selected_furniture.get_meta("studio_kind", "")))
	var projected := _projected_box(info.size, selected_furniture.rotation_degrees)
	selection_marker = Node3D.new()
	selection_marker.name = "StudioSelectionMarker"
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(maxf(0.05, projected.max.x - projected.min.x), 0.035, maxf(0.05, projected.max.z - projected.min.z))
	mesh_instance.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.74, 0.26, 0.28)
	material.emission_enabled = true
	material.emission = Color("f3bd58")
	material.emission_energy_multiplier = 0.55
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material
	selection_marker.add_child(mesh_instance)
	add_child(selection_marker)
	selection_marker.global_position = Vector3(selected_furniture.global_position.x, float(selected_furniture.get_meta("studio_floor", 0)) * FLOOR_HEIGHT + 0.02, selected_furniture.global_position.z)


func _focus_selected_furniture() -> void:
	_hide_furniture_menu()
	if not is_instance_valid(selected_furniture):
		return
	GameAudio.play("inspect_focus")
	var info := StudioFurnitureFactory.get_info(String(selected_furniture.get_meta("studio_kind", "")))
	focus_target_position = selected_furniture.global_position + Vector3(0, float(info.size.y) * 0.52, 0)
	focus_yaw = 0.0
	focus_target_yaw = 0.0
	focus_pitch = 0.0
	focus_target_pitch = 0.0
	focus_fov = FOCUS_FOV
	focus_target_fov = FOCUS_FOV
	focus_pan = Vector2.ZERO
	focus_target_pan = Vector2.ZERO
	orbit_dragging = false
	focus_pan_dragging = false
	camera_focused = true
	if is_instance_valid(selection_marker):
		selection_marker.visible = false
	overview_button.visible = true
	if is_instance_valid(room_pan_panel):
		room_pan_panel.visible = false
	catalog_panel.modulate = Color(0.58, 0.58, 0.66, 0.82)
	_set_status("正在进入近景查看……", Color("cbbce5"))
	if bool(info.get("wall_item", false)):
		var front_direction := -selected_furniture.global_basis.z.normalized()
		_animate_camera(focus_target_position + front_direction * 2.35 + Vector3.UP * 0.08, focus_target_position, 22.0)
	else:
		_animate_camera(focus_target_position + FOCUS_VIEW_OFFSET, focus_target_position, FOCUS_FOV)


func _focus_overview() -> void:
	_hide_furniture_menu()
	if not camera_focused and not camera_transitioning:
		return
	camera_focused = false
	orbit_dragging = false
	focus_pan_dragging = false
	focus_pan = Vector2.ZERO
	focus_target_pan = Vector2.ZERO
	overview_button.visible = false
	catalog_panel.modulate = Color.WHITE
	_refresh_room_pan_controls()
	var target := _overview_target(active_floor)
	_set_status("正在返回房间全景……", Color("cbbce5"))
	_animate_camera(target + _overview_camera_offset(), target, OVERVIEW_FOV)


func _handle_focus_camera_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_focus_overview()
		get_viewport().set_input_as_handled()
		return
	if camera_transitioning:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			orbit_dragging = event.pressed and not _pointer_over_ui(event.position)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			focus_pan_dragging = event.pressed and not _pointer_over_ui(event.position)
		elif event.pressed and not _pointer_over_ui(event.position):
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				focus_target_fov = clampf(focus_target_fov - FOCUS_FOV_STEP, FOCUS_FOV_MIN, FOCUS_FOV_MAX)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				focus_target_fov = clampf(focus_target_fov + FOCUS_FOV_STEP, FOCUS_FOV_MIN, FOCUS_FOV_MAX)
	elif event is InputEventMouseMotion:
		if focus_pan_dragging:
			focus_target_pan.x = clampf(focus_target_pan.x - event.relative.x * FOCUS_PAN_SENSITIVITY, -FOCUS_PAN_HORIZONTAL_LIMIT, FOCUS_PAN_HORIZONTAL_LIMIT)
			focus_target_pan.y = clampf(focus_target_pan.y + event.relative.y * FOCUS_PAN_SENSITIVITY, -FOCUS_PAN_VERTICAL_LIMIT, FOCUS_PAN_VERTICAL_LIMIT)
		elif orbit_dragging:
			focus_target_yaw = clampf(focus_target_yaw - event.relative.x * FOCUS_ORBIT_SENSITIVITY, -FOCUS_YAW_LIMIT, FOCUS_YAW_LIMIT)
			focus_target_pitch = clampf(focus_target_pitch + event.relative.y * FOCUS_ORBIT_SENSITIVITY, -FOCUS_PITCH_LIMIT, FOCUS_PITCH_LIMIT)


func _update_focus_camera(delta: float) -> void:
	var smoothing := 1.0 - exp(-12.0 * delta)
	focus_yaw = lerpf(focus_yaw, focus_target_yaw, smoothing)
	focus_pitch = lerpf(focus_pitch, focus_target_pitch, smoothing)
	focus_fov = lerpf(focus_fov, focus_target_fov, smoothing)
	focus_pan = focus_pan.lerp(focus_target_pan, smoothing)
	var yawed_offset := FOCUS_VIEW_OFFSET.rotated(Vector3.UP, deg_to_rad(focus_yaw))
	var yawed_forward := (-yawed_offset).normalized()
	var pitch_axis := yawed_forward.cross(Vector3.UP).normalized()
	var orbit_offset := yawed_offset.rotated(pitch_axis, deg_to_rad(-focus_pitch))
	var view_forward := (-orbit_offset).normalized()
	var view_right := view_forward.cross(Vector3.UP).normalized()
	var view_up := view_right.cross(view_forward).normalized()
	var panned_target := focus_target_position + view_right * focus_pan.x + view_up * focus_pan.y
	camera.global_position = camera.global_position.lerp(panned_target + orbit_offset, smoothing)
	camera.fov = lerpf(camera.fov, focus_fov, smoothing)
	camera.look_at(panned_target, Vector3.UP)


func _animate_camera(position: Vector3, target: Vector3, fov: float) -> void:
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()
	var next_transform := camera.global_transform
	next_transform.origin = position
	next_transform = next_transform.looking_at(target, Vector3.UP)
	camera_transitioning = true
	camera_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	camera_tween.set_parallel(true)
	camera_tween.tween_property(camera, "global_transform", next_transform, CAMERA_DURATION)
	camera_tween.tween_property(camera, "fov", fov, CAMERA_DURATION)
	camera_tween.finished.connect(func() -> void:
		camera_transitioning = false
		if camera_focused:
			_set_status("近景检视 · 左键环绕（水平 ±45° / 垂直 ±22°）· 中键平移 · 滚轮缩放", Color("9fd9f1"))
		else:
			if is_instance_valid(selection_marker):
				selection_marker.visible = true
			_set_status("全景搭建 · 按住家具移动，单击家具打开菜单", Color("cbbce5"))
	)


func _enter_rotation_mode() -> void:
	_hide_furniture_menu()
	if not is_instance_valid(selected_furniture) or camera_focused:
		return
	if bool(StudioFurnitureFactory.get_info(String(selected_furniture.get_meta("studio_kind", ""))).get("wall_item", false)):
		_set_status("相框只能贴墙，朝向由墙面自动决定", Color("d9c4f1"))
		return
	rotation_mode = true
	pending_world_drag = false
	_prepare_supported_items(selected_furniture)
	if is_instance_valid(selection_marker):
		selection_marker.visible = false
	_create_rotation_gizmo()
	rotation_overlay.visible = true
	_set_status("独占旋转模式 · 只能拖动 XYZ 环 · 点击上方“确定”结束", Color("ffd47e"))


func _confirm_rotation_mode() -> void:
	if not rotation_mode:
		return
	gizmo_dragging = false
	gizmo_axis_index = -1
	rotation_mode = false
	rotation_overlay.visible = false
	_commit_supported_items(selected_furniture)
	_save_layout()
	_destroy_rotation_gizmo()
	_clear_selection(false)
	_focus_overview()
	_set_status("旋转已确认 · 已返回场景全景", Color("a7e5bb"))


func _create_rotation_gizmo() -> void:
	_destroy_rotation_gizmo()
	if not is_instance_valid(selected_furniture):
		return
	var info := StudioFurnitureFactory.get_info(String(selected_furniture.get_meta("studio_kind", "")))
	var object_size: Vector3 = info.size
	var radius := clampf(maxf(object_size.x, object_size.z) * 0.56 + 0.28, 0.58, 1.9)
	rotation_gizmo = Node3D.new()
	rotation_gizmo.name = "StudioRotationGizmo"
	add_child(rotation_gizmo)
	_add_rotation_ring(0, radius, Color("f05d68"))
	_add_rotation_ring(1, radius, Color("62d487"))
	_add_rotation_ring(2, radius, Color("5f9ff3"))
	_sync_rotation_gizmo()


func _add_rotation_ring(axis_index: int, radius: float, color: Color) -> void:
	var ring_root := Node3D.new()
	match axis_index:
		0: ring_root.rotation_degrees.z = 90.0
		2: ring_root.rotation_degrees.x = 90.0
	rotation_gizmo.add_child(ring_root)
	var mesh_instance := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = maxf(0.05, radius - 0.020)
	torus.outer_radius = radius + 0.020
	torus.rings = 40
	torus.ring_segments = 8
	mesh_instance.mesh = torus
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color, 0.92)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.05
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	mesh_instance.material_override = material
	ring_root.add_child(mesh_instance)
	var hit_area := Area3D.new()
	hit_area.collision_layer = ROTATION_GIZMO_LAYER
	hit_area.collision_mask = 0
	hit_area.set_meta("rotation_axis", axis_index)
	ring_root.add_child(hit_area)
	for segment: int in range(28):
		var angle := TAU * float(segment) / 28.0
		var collision := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 0.15
		collision.shape = sphere
		collision.position = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		hit_area.add_child(collision)


func _try_begin_rotation_gizmo_drag(screen_position: Vector2) -> bool:
	if not rotation_mode or not is_instance_valid(rotation_gizmo) or not is_instance_valid(selected_furniture):
		return false
	var origin := camera.project_ray_origin(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(screen_position) * 100.0, ROTATION_GIZMO_LAYER)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	var area := hit.collider as Area3D
	if not is_instance_valid(area) or not area.has_meta("rotation_axis"):
		return false
	gizmo_dragging = true
	gizmo_axis_index = int(area.get_meta("rotation_axis"))
	gizmo_last_mouse_position = screen_position
	_set_status("正在绕 %s 轴旋转 · 松开后可继续选择其他轴" % ["X", "Y", "Z"][gizmo_axis_index], Color("ffd47e"))
	return true


func _update_rotation_gizmo_drag(event: InputEventMouseMotion) -> void:
	if not gizmo_dragging or not is_instance_valid(selected_furniture):
		return
	var delta := event.position - gizmo_last_mouse_position
	gizmo_last_mouse_position = event.position
	var angle := (delta.x - delta.y) * ROTATION_GIZMO_SENSITIVITY
	var next_rotation := selected_furniture.rotation_degrees
	match gizmo_axis_index:
		0: next_rotation.x = fposmod(next_rotation.x + angle, 360.0)
		1: next_rotation.y = fposmod(next_rotation.y + angle, 360.0)
		2: next_rotation.z = fposmod(next_rotation.z + angle, 360.0)
	var info := StudioFurnitureFactory.get_info(String(selected_furniture.get_meta("studio_kind", "")))
	var projected := _projected_box(info.size, next_rotation)
	var floor_index := int(selected_furniture.get_meta("studio_floor", 0))
	var surface_y := float(floor_index) * FLOOR_HEIGHT
	var support := _support_for_node(selected_furniture)
	if is_instance_valid(support):
		surface_y = _desk_surface_height(support)
	var next_position := selected_furniture.global_position
	next_position.y = surface_y - projected.min.y
	var previous_kind := active_kind
	active_kind = String(selected_furniture.get_meta("studio_kind", ""))
	var rotation_valid := _placement_clear(next_position, info.size, next_rotation, selected_furniture, support)
	active_kind = previous_kind
	if not rotation_valid:
		_set_status("该旋转角度会使家具越出房间", Color("ff9da6"))
		return
	selected_furniture.rotation_degrees = next_rotation
	selected_furniture.global_position = next_position
	_sync_supported_items(selected_furniture.global_transform)
	_sync_rotation_gizmo()


func _end_rotation_gizmo_drag() -> void:
	if gizmo_dragging and is_instance_valid(selected_furniture):
		GameAudio.play("furniture_rotate", selected_furniture.global_position)
	gizmo_dragging = false
	gizmo_axis_index = -1
	_set_status("旋转角度已暂存 · 可继续拖动其他轴 · 完成后点击“确定”", Color("ffd47e"))


func _sync_rotation_gizmo() -> void:
	if not is_instance_valid(rotation_gizmo) or not is_instance_valid(selected_furniture):
		return
	var info := StudioFurnitureFactory.get_info(String(selected_furniture.get_meta("studio_kind", "")))
	rotation_gizmo.global_transform = Transform3D(selected_furniture.global_basis.orthonormalized(), selected_furniture.to_global(Vector3(0, float(info.size.y) * 0.5, 0)))


func _destroy_rotation_gizmo() -> void:
	gizmo_dragging = false
	gizmo_axis_index = -1
	if is_instance_valid(rotation_gizmo):
		rotation_gizmo.queue_free()
	rotation_gizmo = null


func _toggle_work_mode() -> void:
	if build_mode:
		_save_layout()
		var workstation_floor := int(profile.call("get_studio_workstation_floor"))
		if workstation_floor < 0:
			_set_status("无法开始工作：同一楼层必须摆放工作桌、工作椅，并把电脑吸附到桌面。", Color("ef9b91"))
			return
		if workstation_floor != active_floor:
			await _switch_floor(workstation_floor)
		_enter_work_mode()
	else:
		_enter_build_mode()


func _enter_work_mode() -> void:
	build_mode = false
	_cancel_placement(false)
	_clear_selection(false)
	catalog_panel.visible = false
	if is_instance_valid(catalog_tabs_layer):
		catalog_tabs_layer.visible = false
	if is_instance_valid(room_pan_panel):
		room_pan_panel.visible = false
	mode_label.text = "工作状态"
	var computer := _find_kind("studio_computer")
	var target := computer.global_position + Vector3(0, 0.38, 0) if is_instance_valid(computer) else Vector3.ZERO
	_animate_camera(target + Vector3(0, 1.0, 2.7), target, 38.0)
	open_computer_button.visible = true
	return_build_button.visible = true
	_set_status("工作状态 · 点击电脑或下方按钮进入桌面", Color("9ccde0"))


func _enter_build_mode() -> void:
	if is_instance_valid(computer_ui) and computer_ui.visible:
		computer_ui.close_desktop()
	build_mode = true
	open_computer_button.visible = false
	return_build_button.visible = false
	catalog_panel.visible = true
	if is_instance_valid(catalog_tabs_layer):
		catalog_tabs_layer.visible = true
	mode_label.text = "搭建状态"
	_switch_floor(active_floor, false)
	_refresh_room_pan_controls()
	_set_status("搭建模式 · 从右侧拖出家具，或按住场内家具直接移动 · Q/E 旋转 90°", Color("cbbce5"))


func _on_desktop_opened() -> void:
	_desktop_hud_was_visible = hud_root.visible
	hud_root.visible = false
	computer_ui.move_to_front()


func _on_desktop_closed() -> void:
	hud_root.visible = _desktop_hud_was_visible
	if build_mode:
		_set_status("已离开电脑 · 可以继续搭建工作室。", Color("c5d6e2"))
	else:
		_set_status("已离开电脑 · 可再次进入电脑，或回到搭建状态。", Color("c5d6e2"))


func _switch_floor(floor_index: int, animate := true) -> void:
	floor_index = clampi(floor_index, 0, 1)
	if floor_switching or not bool(profile.call("is_studio_floor_available", floor_index)):
		return
	if floor_index == active_floor and animate:
		return
	_cancel_placement(false)
	_clear_selection(false)
	if animate and is_instance_valid(floor_fade_overlay):
		floor_switching = true
		floor_fade_overlay.visible = true
		floor_fade_overlay.color = Color(0, 0, 0, 0)
		var fade_out := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		fade_out.tween_property(floor_fade_overlay, "color", Color.BLACK, FLOOR_FADE_DURATION)
		await fade_out.finished
	active_floor = floor_index
	overview_room_pan = Vector2.ZERO
	_apply_floor_visibility()
	var target := _overview_target(active_floor)
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()
	camera_transitioning = false
	camera.global_position = target + _overview_camera_offset()
	camera.look_at(target, Vector3.UP)
	camera.fov = OVERVIEW_FOV
	_refresh_floor_buttons()
	_refresh_room_pan_controls()
	if animate and is_instance_valid(floor_fade_overlay):
		var fade_in := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		fade_in.tween_property(floor_fade_overlay, "color", Color(0, 0, 0, 0), FLOOR_FADE_DURATION)
		await fade_in.finished
		floor_fade_overlay.visible = false
		floor_switching = false
		_refresh_floor_buttons()
		_set_status("已进入%s · 当前拥有 %d / 4 个房间" % ["一楼" if active_floor == 0 else "二楼", int(profile.call("get_studio_room_count", active_floor))], Color("cbbce5"))


func _overview_target(floor_index: int) -> Vector3:
	var center := _floor_center(floor_index) + overview_room_pan
	return Vector3(center.x, float(floor_index) * FLOOR_HEIGHT + 1.48, center.y)


func _overview_camera_offset() -> Vector3:
	var dimensions := _floor_dimensions(active_floor)
	var scale_factor := clampf(maxf(dimensions.x / ROOM_SIZE.x, dimensions.y / ROOM_SIZE.y), 1.0, 2.0)
	return Vector3(11.0, 8.52, 15.7) * lerpf(1.0, 1.28, scale_factor - 1.0)


func _pan_overview(direction: Vector2) -> void:
	if camera_focused or floor_switching or not build_mode:
		return
	var dimensions := _floor_dimensions(active_floor)
	var limit := Vector2(maxf(0.0, (dimensions.x - ROOM_SIZE.x) * 0.5), maxf(0.0, (dimensions.y - ROOM_SIZE.y) * 0.5))
	overview_room_pan.x = clampf(overview_room_pan.x + direction.x * ROOM_SIZE.x * 0.5, -limit.x, limit.x)
	overview_room_pan.y = clampf(overview_room_pan.y + direction.y * ROOM_SIZE.y * 0.5, -limit.y, limit.y)
	var target := _overview_target(active_floor)
	_animate_camera(target + _overview_camera_offset(), target, OVERVIEW_FOV)


func _center_overview_pan() -> void:
	if camera_focused or floor_switching or not build_mode:
		return
	overview_room_pan = Vector2.ZERO
	var target := _overview_target(active_floor)
	_animate_camera(target + _overview_camera_offset(), target, OVERVIEW_FOV)


func _refresh_room_pan_controls() -> void:
	if not is_instance_valid(room_pan_panel) or not is_instance_valid(profile):
		return
	room_pan_panel.visible = build_mode and not camera_focused and int(profile.call("get_studio_room_count", active_floor)) > 1


func _refresh_floor_buttons() -> void:
	for index: int in range(2):
		var control: Button = floor1_button if index == 0 else floor2_button
		if not is_instance_valid(control):
			continue
		control.disabled = floor_switching or active_floor == index or not bool(profile.call("is_studio_floor_available", index))
		control.text = ("一楼 %d/4" if index == 0 else "二楼 %d/4") % int(profile.call("get_studio_room_count", index))
		INVESTIGATION_UI.button(control, "dark" if active_floor == index else "button")

func _apply_floor_visibility() -> void:
	if is_instance_valid(shell_root):
		for child: Node in shell_root.get_children():
			if child is Node3D:
				(child as Node3D).visible = int(child.get_meta("studio_floor", 0)) == active_floor
	if is_instance_valid(furniture_root):
		for child: Node in furniture_root.get_children():
			if child is Node3D:
				(child as Node3D).visible = int(child.get_meta("studio_floor", 0)) == active_floor


func _cycle_wall_style() -> void:
	_wall_style = (_wall_style + 1) % 3
	profile.call("set_studio_shell", _wall_style, _floor_style)
	_build_shell()


func _cycle_floor_style() -> void:
	_floor_style = (_floor_style + 1) % 3
	profile.call("set_studio_shell", _wall_style, _floor_style)
	_build_shell()


func _on_tier_changed(_tier: int) -> void:
	_refresh_floor_buttons()
	_refresh_catalog()


func _on_studio_rooms_changed(_floor_index: int, _room_count: int) -> void:
	_build_shell()
	_apply_floor_visibility()
	_refresh_floor_buttons()
	_refresh_room_pan_controls()
	_refresh_catalog()


func _wall_surfaces(floor_index: int) -> Array[Dictionary]:
	var surfaces: Array[Dictionary] = []
	var room_count := int(profile.call("get_studio_room_count", floor_index))
	var base_y := float(floor_index) * FLOOR_HEIGHT
	for room_index: int in range(room_count):
		var plot := ROOM_PLOT_SEQUENCE[room_index]
		var center := _room_plot_center(room_index)
		if plot.y == 0:
			var back_plane := center.y - ROOM_SIZE.y * 0.5 + 0.095
			if floor_index == 0 and room_index == 0 and _wall_style == 0:
				back_plane = -4.80
			surfaces.append({
				"side":"back", "room_index":room_index, "plane":back_plane,
				"horizontal_min":center.x - ROOM_SIZE.x * 0.5, "horizontal_max":center.x + ROOM_SIZE.x * 0.5,
				"base_y":base_y, "yaw":180.0
			})
		if plot.x == 0:
			var left_plane := center.x - ROOM_SIZE.x * 0.5 + 0.095
			if floor_index == 0 and room_index == 0 and _wall_style == 0:
				left_plane = -4.90
			surfaces.append({
				"side":"left", "room_index":room_index, "plane":left_plane,
				"horizontal_min":center.y - ROOM_SIZE.y * 0.5, "horizontal_max":center.y + ROOM_SIZE.y * 0.5,
				"base_y":base_y, "yaw":-90.0
			})
	return surfaces


func _find_wall_snap(ray_origin: Vector3, ray_direction: Vector3, object_size: Vector3, floor_index: int) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := INF
	for surface: Dictionary in _wall_surfaces(floor_index):
		var side := String(surface.get("side", ""))
		var denominator := ray_direction.z if side == "back" else ray_direction.x
		if absf(denominator) < 0.0001:
			continue
		var distance := (float(surface.get("plane", 0.0)) - (ray_origin.z if side == "back" else ray_origin.x)) / denominator
		if distance <= 0.0 or distance >= best_distance:
			continue
		var hit := ray_origin + ray_direction * distance
		var horizontal := hit.x if side == "back" else hit.z
		var horizontal_min := float(surface.get("horizontal_min", 0.0))
		var horizontal_max := float(surface.get("horizontal_max", 0.0))
		var base_y := float(surface.get("base_y", 0.0))
		if horizontal < horizontal_min - 0.20 or horizontal > horizontal_max + 0.20 or hit.y < base_y or hit.y > base_y + ROOM_WALL_HEIGHT:
			continue
		var half_width := object_size.x * 0.5
		horizontal = clampf(horizontal, horizontal_min + half_width + 0.08, horizontal_max - half_width - 0.08)
		var center_y := clampf(hit.y, base_y + object_size.y * 0.5 + 0.10, base_y + ROOM_WALL_HEIGHT - object_size.y * 0.5 - 0.10)
		var position := Vector3(horizontal, center_y - object_size.y * 0.5, float(surface.get("plane", 0.0)))
		if side == "left":
			position = Vector3(float(surface.get("plane", 0.0)), center_y - object_size.y * 0.5, horizontal)
		best = surface.duplicate(true)
		best["position"] = position
		best_distance = distance
	return best


func _wall_placement_clear(world: Vector3, object_size: Vector3, ignored: Node3D, attachment: Dictionary) -> bool:
	var side := String(attachment.get("side", ""))
	var room_index := int(attachment.get("room_index", -1))
	var horizontal := world.x if side == "back" else world.z
	var center_y := world.y + object_size.y * 0.5
	for child: Node in furniture_root.get_children():
		if not child is Node3D or child == ignored or not (child as Node3D).visible:
			continue
		var other := child as Node3D
		var other_info := StudioFurnitureFactory.get_info(String(other.get_meta("studio_kind", "")))
		if not bool(other_info.get("wall_item", false)) or int(other.get_meta("studio_floor", 0)) != active_floor:
			continue
		if String(other.get_meta("wall_side", "")) != side or int(other.get_meta("wall_room", -1)) != room_index:
			continue
		var other_size := other_info.get("size", Vector3.ONE) as Vector3
		var other_horizontal := other.global_position.x if side == "back" else other.global_position.z
		var other_center_y := other.global_position.y + other_size.y * 0.5
		if (
			absf(horizontal - other_horizontal) < (object_size.x + other_size.x) * 0.5 + 0.04
			and absf(center_y - other_center_y) < (object_size.y + other_size.y) * 0.5 + 0.04
		):
			return false
	return true


func _clamp_wall_item_to_wall(node: Node3D, floor_index: int, info: Dictionary) -> void:
	var surfaces := _wall_surfaces(floor_index)
	if surfaces.is_empty():
		return
	var preferred_side := String(node.get_meta("wall_side", ""))
	var preferred_room := int(node.get_meta("wall_room", -1))
	var chosen: Dictionary = {}
	var best_distance := INF
	for surface: Dictionary in surfaces:
		var matches_saved := String(surface.get("side", "")) == preferred_side and int(surface.get("room_index", -1)) == preferred_room
		var distance := absf(node.position.z - float(surface.get("plane", 0.0))) if String(surface.get("side", "")) == "back" else absf(node.position.x - float(surface.get("plane", 0.0)))
		if matches_saved:
			chosen = surface
			break
		if distance < best_distance:
			best_distance = distance
			chosen = surface
	var size := info.get("size", Vector3(1.36, 0.92, 0.10)) as Vector3
	var side := String(chosen.get("side", "back"))
	var horizontal := node.position.x if side == "back" else node.position.z
	horizontal = clampf(horizontal, float(chosen.get("horizontal_min", 0.0)) + size.x * 0.5 + 0.08, float(chosen.get("horizontal_max", 0.0)) - size.x * 0.5 - 0.08)
	var base_y := float(chosen.get("base_y", 0.0))
	var center_y := clampf(node.position.y + size.y * 0.5, base_y + size.y * 0.5 + 0.10, base_y + ROOM_WALL_HEIGHT - size.y * 0.5 - 0.10)
	node.position = Vector3(horizontal, center_y - size.y * 0.5, float(chosen.get("plane", 0.0))) if side == "back" else Vector3(float(chosen.get("plane", 0.0)), center_y - size.y * 0.5, horizontal)
	node.rotation_degrees = Vector3(0, float(chosen.get("yaw", 0.0)), 0)
	node.set_meta("wall_side", side)
	node.set_meta("wall_room", int(chosen.get("room_index", 0)))


func _placement_clear(world: Vector3, object_size: Vector3, rotation: Vector3, ignored: Node3D, support: Node3D) -> bool:
	var projected := _projected_box(object_size, rotation)
	if not _inside_floor(world, projected, active_floor):
		return false
	var new_rect := Rect2(Vector2(world.x + projected.min.x, world.z + projected.min.z), Vector2(projected.max.x - projected.min.x, projected.max.z - projected.min.z)).grow(-0.05)
	for child: Node in furniture_root.get_children():
		if not child is Node3D:
			continue
		var node := child as Node3D
		if node == ignored or node == support or not node.visible:
			continue
		if int(node.get_meta("studio_floor", 0)) != active_floor:
			continue
		if _is_moving_supported(node):
			continue
		var other_kind := String(node.get_meta("studio_kind", ""))
		if active_kind == "studio_rug" or other_kind == "studio_rug":
			continue
		var other_info := StudioFurnitureFactory.get_info(other_kind)
		var other_projected := _projected_box(other_info.size, node.rotation_degrees)
		var other_rect := Rect2(Vector2(node.global_position.x + other_projected.min.x, node.global_position.z + other_projected.min.z), Vector2(other_projected.max.x - other_projected.min.x, other_projected.max.z - other_projected.min.z)).grow(-0.05)
		if new_rect.intersects(other_rect):
			return false
	return true


func _inside_floor(world: Vector3, projected: Dictionary, floor_index: int) -> bool:
	var corners: Array[Vector2] = [
		Vector2(world.x + float(projected.min.x), world.z + float(projected.min.z)),
		Vector2(world.x + float(projected.max.x), world.z + float(projected.min.z)),
		Vector2(world.x + float(projected.min.x), world.z + float(projected.max.z)),
		Vector2(world.x + float(projected.max.x), world.z + float(projected.max.z))
	]
	for corner: Vector2 in corners:
		if not _point_inside_purchased_room(corner, floor_index):
			return false
	return true


func _point_inside_purchased_room(point: Vector2, floor_index: int) -> bool:
	var room_count := int(profile.call("get_studio_room_count", floor_index))
	for room_index: int in range(room_count):
		var center := _room_plot_center(room_index)
		if (
			point.x >= center.x - ROOM_SIZE.x * 0.5 - 0.001
			and point.x <= center.x + ROOM_SIZE.x * 0.5 + 0.001
			and point.y >= center.y - ROOM_SIZE.y * 0.5 - 0.001
			and point.y <= center.y + ROOM_SIZE.y * 0.5 + 0.001
		):
			return true
	return false


func _projected_box(size: Vector3, rotation_degrees_value: Vector3) -> Dictionary:
	var basis := Basis.from_euler(rotation_degrees_value * PI / 180.0)
	var min_value := Vector3(INF, INF, INF)
	var max_value := Vector3(-INF, -INF, -INF)
	for x_value: float in [-size.x * 0.5, size.x * 0.5]:
		for y_value: float in [0.0, size.y]:
			for z_value: float in [-size.z * 0.5, size.z * 0.5]:
				var point := basis * Vector3(x_value, y_value, z_value)
				min_value = min_value.min(point)
				max_value = max_value.max(point)
	return {"min": min_value, "max": max_value}


func _desk_under_position(world: Vector3, ignored: Node3D = null) -> Node3D:
	var target_floor := active_floor
	if is_instance_valid(ignored) and ignored.has_meta("studio_floor"):
		target_floor = int(ignored.get_meta("studio_floor", active_floor))
	for child: Node in furniture_root.get_children():
		if not child is Node3D or child == ignored or not child.visible:
			continue
		var desk := child as Node3D
		if String(desk.get_meta("studio_kind", "")) != "studio_desk":
			continue
		if int(desk.get_meta("studio_floor", 0)) != target_floor:
			continue
		var local := desk.to_local(Vector3(world.x, desk.global_position.y, world.z))
		if absf(local.x) <= 1.60 and absf(local.z) <= 0.72:
			return desk
	return null


func _desk_surface_height(desk: Node3D) -> float:
	return desk.to_global(Vector3(0, 1.21, 0)).y


func _support_for_node(node: Node3D) -> Node3D:
	var support_uid := String(node.get_meta("support_uid", ""))
	if support_uid.is_empty():
		return null
	for child: Node in furniture_root.get_children():
		if child is Node3D and String(child.get_meta("studio_uid", "")) == support_uid:
			return child as Node3D
	return null


func _prepare_supported_items(support_node: Node3D) -> void:
	moving_supported_items.clear()
	if not is_instance_valid(support_node) or String(support_node.get_meta("studio_kind", "")) != "studio_desk":
		return
	var support_uid := _ensure_furniture_uid(support_node)
	for child: Node in furniture_root.get_children():
		if not child is Node3D or child == support_node:
			continue
		var node := child as Node3D
		var attached := String(node.get_meta("support_uid", "")) == support_uid
		if not attached and String(node.get_meta("studio_kind", "")) == "studio_computer":
			attached = _desk_under_position(node.global_position, node) == support_node
		if attached:
			node.set_meta("support_uid", support_uid)
			moving_supported_items.append({"node": node, "original": node.global_transform, "relative": support_node.global_transform.affine_inverse() * node.global_transform})


func _sync_supported_items(support_transform: Transform3D) -> void:
	for entry: Dictionary in moving_supported_items:
		var node := entry.get("node", null) as Node3D
		if is_instance_valid(node):
			node.global_transform = support_transform * (entry.relative as Transform3D)


func _commit_supported_items(support_node: Node3D) -> void:
	if is_instance_valid(support_node):
		var support_uid := _ensure_furniture_uid(support_node)
		for entry: Dictionary in moving_supported_items:
			var node := entry.get("node", null) as Node3D
			if is_instance_valid(node):
				node.set_meta("support_uid", support_uid)
	moving_supported_items.clear()


func _restore_supported_items() -> void:
	for entry: Dictionary in moving_supported_items:
		var node := entry.get("node", null) as Node3D
		if is_instance_valid(node):
			node.global_transform = entry.original as Transform3D
	moving_supported_items.clear()


func _is_moving_supported(node: Node3D) -> bool:
	for entry: Dictionary in moving_supported_items:
		if entry.get("node", null) == node:
			return true
	return false


func _ensure_furniture_uid(node: Node3D) -> String:
	var uid := String(node.get_meta("studio_uid", ""))
	if uid.is_empty():
		uid = "%s_%s_%d" % [String(node.get_meta("studio_kind", "item")), Time.get_ticks_usec(), node.get_instance_id()]
		node.set_meta("studio_uid", uid)
	return uid


func _save_layout() -> void:
	var layout: Array = []
	for child: Node in furniture_root.get_children():
		if not child is Node3D or not child.has_meta("studio_kind"):
			continue
		var node := child as Node3D
		layout.append({
			"kind": String(node.get_meta("studio_kind", "")),
			"uid": _ensure_furniture_uid(node),
			"support_uid": String(node.get_meta("support_uid", "")),
			"position": [node.position.x, node.position.y, node.position.z],
			"rotation": [node.rotation_degrees.x, node.rotation_degrees.y, node.rotation_degrees.z],
			"rotation_y": node.rotation_degrees.y,
			"floor": int(node.get_meta("studio_floor", 0)),
			"wall_side": String(node.get_meta("wall_side", "")),
			"wall_room": int(node.get_meta("wall_room", -1))
		})
	profile.call("set_studio_layout", layout)


func _restore_layout() -> void:
	for entry: Dictionary in profile.get("placed_studio_layout"):
		var kind := String(entry.get("kind", ""))
		if kind.is_empty():
			continue
		var node := StudioFurnitureFactory.build(kind)
		furniture_root.add_child(node)
		node.set_meta("studio_uid", String(entry.get("uid", "")))
		_ensure_furniture_uid(node)
		var support_uid := String(entry.get("support_uid", ""))
		if not support_uid.is_empty():
			node.set_meta("support_uid", support_uid)
		var wall_side := String(entry.get("wall_side", ""))
		if not wall_side.is_empty():
			node.set_meta("wall_side", wall_side)
			node.set_meta("wall_room", int(entry.get("wall_room", 0)))
		var values: Array = entry.get("position", [0.0, 0.0, 0.0])
		if values.size() >= 3:
			node.position = Vector3(float(values[0]), float(values[1]), float(values[2]))
		var rotations: Array = entry.get("rotation", [])
		if rotations.size() >= 3:
			node.rotation_degrees = Vector3(float(rotations[0]), float(rotations[1]), float(rotations[2]))
		else:
			node.rotation_degrees.y = float(entry.get("rotation_y", 0.0))
		node.set_meta("studio_floor", int(entry.get("floor", 0)))
		_clamp_restored_node(node)
	_repair_computer_support()
	# Migrate legacy saves once: persist valid bounds, full XYZ rotation and support links.
	_save_layout()


func _clamp_restored_node(node: Node3D) -> void:
	var floor_index := int(node.get_meta("studio_floor", 0))
	if not bool(profile.call("is_studio_floor_available", floor_index)):
		floor_index = 0
		node.set_meta("studio_floor", 0)
	var info := StudioFurnitureFactory.get_info(String(node.get_meta("studio_kind", "")))
	if bool(info.get("wall_item", false)):
		_clamp_wall_item_to_wall(node, floor_index, info)
		return
	var projected := _projected_box(info.size, node.rotation_degrees)
	var dimensions := _floor_dimensions(floor_index)
	var center := _floor_center(floor_index)
	node.position.x = clampf(node.position.x, center.x - dimensions.x * 0.5 - projected.min.x, center.x + dimensions.x * 0.5 - projected.max.x)
	node.position.z = clampf(node.position.z, center.y - dimensions.y * 0.5 - projected.min.z, center.y + dimensions.y * 0.5 - projected.max.z)
	if not _inside_floor(node.position, projected, floor_index):
		var nearest := _nearest_room_center(Vector2(node.position.x, node.position.z), floor_index)
		node.position.x = clampf(node.position.x, nearest.x - ROOM_SIZE.x * 0.5 - projected.min.x, nearest.x + ROOM_SIZE.x * 0.5 - projected.max.x)
		node.position.z = clampf(node.position.z, nearest.y - ROOM_SIZE.y * 0.5 - projected.min.z, nearest.y + ROOM_SIZE.y * 0.5 - projected.max.z)
	if not bool(info.get("desk_item", false)):
		node.position.y = float(floor_index) * FLOOR_HEIGHT - projected.min.y


func _repair_computer_support() -> void:
	for child: Node in furniture_root.get_children():
		if not child is Node3D or String(child.get_meta("studio_kind", "")) != "studio_computer":
			continue
		var computer := child as Node3D
		var desk := _support_for_node(computer)
		if not is_instance_valid(desk):
			desk = _desk_under_position(computer.global_position, computer)
		if not is_instance_valid(desk):
			desk = _nearest_desk(computer.global_position)
		if is_instance_valid(desk):
			var local := desk.to_local(computer.global_position)
			local.x = clampf(local.x, -0.88, 0.88)
			local.z = clampf(local.z, -0.38, 0.38)
			local.y = 1.21
			computer.global_position = desk.to_global(local)
			computer.set_meta("support_uid", _ensure_furniture_uid(desk))


func _nearest_desk(world: Vector3) -> Node3D:
	var result: Node3D
	var best := INF
	for child: Node in furniture_root.get_children():
		if child is Node3D and String(child.get_meta("studio_kind", "")) == "studio_desk":
			var distance := (child as Node3D).global_position.distance_squared_to(world)
			if distance < best:
				best = distance
				result = child as Node3D
	return result


func _find_kind(kind: String) -> Node3D:
	for child: Node in furniture_root.get_children():
		if child is Node3D and String(child.get_meta("studio_kind", "")) == kind and int(child.get_meta("studio_floor", 0)) == active_floor:
			return child as Node3D
	return null


func _floor_dimensions(floor_index: int) -> Vector2:
	var room_count := maxi(1, int(profile.call("get_studio_room_count", floor_index)))
	var has_right := room_count >= 2
	var has_front := room_count >= 3
	return Vector2(ROOM_SIZE.x * (2.0 if has_right else 1.0), ROOM_SIZE.y * (2.0 if has_front else 1.0))


func _floor_center(floor_index: int) -> Vector2:
	var dimensions := _floor_dimensions(floor_index)
	return ROOM_ORIGIN + Vector2((dimensions.x - ROOM_SIZE.x) * 0.5, (dimensions.y - ROOM_SIZE.y) * 0.5)


func _room_plot_center(room_index: int) -> Vector2:
	var plot := ROOM_PLOT_SEQUENCE[clampi(room_index, 0, ROOM_PLOT_SEQUENCE.size() - 1)]
	return ROOM_ORIGIN + Vector2(float(plot.x) * ROOM_SIZE.x, float(plot.y) * ROOM_SIZE.y)


func _nearest_room_center(point: Vector2, floor_index: int) -> Vector2:
	var result := Vector2.ZERO
	var best_distance := INF
	var room_count := maxi(1, int(profile.call("get_studio_room_count", floor_index)))
	for room_index: int in range(room_count):
		var candidate := _room_plot_center(room_index)
		var distance := candidate.distance_squared_to(point)
		if distance < best_distance:
			best_distance = distance
			result = candidate
	return result


func _pointer_over_ui(position: Vector2) -> bool:
	return _control_tree_has_point(hud_root, position)


func _control_tree_has_point(root: Node, position: Vector2) -> bool:
	for child: Node in root.get_children():
		if child is Control:
			var control := child as Control
			if control.is_visible_in_tree() and control.mouse_filter != Control.MOUSE_FILTER_IGNORE and control.get_global_rect().has_point(position):
				return true
			if control.is_visible_in_tree() and _control_tree_has_point(control, position):
				return true
	return false


func _set_status(text_value: String, color: Color) -> void:
	if is_instance_valid(status_label):
		status_label.text = text_value
		status_label.add_theme_color_override("font_color", Color("863b2c") if color.r > color.g * 1.4 else STUDIO_UI.INK)


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
