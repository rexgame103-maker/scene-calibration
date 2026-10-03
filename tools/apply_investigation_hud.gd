extends SceneTree
## One-time authoring utility; all generated layout is saved in the editable scene.
const UI := preload("res://scripts/investigation_ui_theme.gd")
var hud: Control

func _init() -> void:
	call_deferred("build")

func place(path: String, rect: Rect2, anchor := Vector2.ZERO) -> Control:
	var control := hud.get_node(path) as Control
	control.custom_minimum_size = Vector2.ZERO
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.anchor_left = anchor.x
	control.anchor_right = anchor.x
	control.anchor_top = anchor.y
	control.anchor_bottom = anchor.y
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.end.x
	control.offset_bottom = rect.end.y
	return control

func label(path: String, rect: Rect2, font_size: int) -> Label:
	var control := place(path, rect) as Label
	control.add_theme_font_size_override("font_size", font_size)
	control.add_theme_color_override("font_color", UI.INK)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return control

func new_label(parent: Node, title: String, copy: String, rect: Rect2, font_size: int) -> void:
	var control := parent.get_node_or_null(title) as Label
	if control == null:
		control = Label.new()
		control.name = title
		parent.add_child(control)
		control.owner = hud
	control.text = copy
	label(str(hud.get_path_to(control)), rect, font_size)

func artwork(parent: Node, title: String, key: String, rect: Rect2) -> TextureRect:
	var control := parent.get_node_or_null(title) as TextureRect
	if control == null:
		control = TextureRect.new()
		control.name = title
		parent.add_child(control)
		control.owner = hud
	control.texture = UI.texture(key)
	control.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(str(hud.get_path_to(control)), rect)
	return control

func style_buttons(node: Node) -> void:
	if node is Button:
		UI.button(node)
	for child in node.get_children():
		style_buttons(child)

func build() -> void:
	hud = load("res://scenes/studio/studio_hud.tscn").instantiate()
	style_buttons(hud)
	place("StudioTitlePanel", Rect2(8, 18, 344, 166)).add_theme_stylebox_override("panel", UI.paper("title"))
	var title := "StudioTitlePanel/EditableContent/"
	label(title + "StudioTitleLabel", Rect2(27, 35, 285, 33), 22)
	label(title + "ModeLabel", Rect2(30, 91, 285, 18), 11)
	label(title + "MoneyLabel", Rect2(30, 112, 300, 20), 11)
	new_label(hud.get_node("StudioTitlePanel/EditableContent"), "StudioSubtitleLabel", "CALIBRATOR'S STUDIO", Rect2(30, 70, 275, 15), 9)
	place("StudioToolsPanel", Rect2(10, 191, 346, 37))
	var names := ["Floor1Button", "Floor2Button", "WallStyleButton", "FloorStyleButton", "DebugAddMoneyButton"]
	for i in range(names.size()):
		var control := place("StudioToolsPanel/" + names[i], Rect2(i * 69, 0, 67, 35)) as Button
		control.add_theme_font_size_override("font_size", 10)
		control.alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.button(control, "dark" if i == 0 else "gold" if i == 4 else "button")
	(hud.get_node("StudioToolsPanel/DebugAddMoneyButton") as Button).text = "+ ¥5000"
	place("DebugCaseJumpPanel", Rect2(10, 234, 288, 40))
	for i in range(2):
		var control := place("DebugCaseJumpPanel/" + ("DebugJumpFirstCaseButton" if i == 0 else "DebugJumpSecondCaseButton"), Rect2(i * 145, 0, 140, 40)) as Button
		UI.button(control, "wide")
		control.add_theme_font_size_override("font_size", 11)
	place("ArchiveInventoryPanel", Rect2(-323, 25, 313, 632), Vector2(1, 0)).add_theme_stylebox_override("panel", UI.paper("inventory"))
	var inventory := "ArchiveInventoryPanel/EditableContent/"
	label(inventory + "CatalogTitleLabel", Rect2(31, 38, 218, 39), 29)
	label(inventory + "CatalogSubtitleLabel", Rect2(31, 108, 262, 18), 12)
	(hud.get_node(inventory + "CatalogHeaderDivider") as Control).hide()
	(hud.get_node(inventory + "CatalogFooterDivider") as Control).hide()
	place(inventory + "FurniturePageViewport", Rect2(28, 131, 261, 424))
	var list := place(inventory + "FurniturePageViewport/CatalogList", Rect2(0, 0, 261, 424))
	list.custom_minimum_size = Vector2(261, 424)
	for i in range(4):
		var slot := inventory + "FurniturePageViewport/CatalogList/CatalogSlot%d" % (i + 1)
		place(slot, Rect2(0, i * 106, 261, 101))
		var card := place(slot + "/CatalogCard", Rect2(0, 0, 261, 101))
		card.set("icon_kind", ["desk", "chair", "computer", "shelf"][i])
	place(inventory + "WorkButton", Rect2(27, 563, 263, 61))
	var work := hud.get_node(inventory + "WorkButton") as Button
	UI.button(work, "work")
	work.add_theme_font_size_override("font_size", 24)
	place("FurniturePageTabs", Rect2(-36, 164, 34, 280), Vector2(1, 0))
	for i in range(4):
		var tab := place("FurniturePageTabs/FurniturePageTab%d" % (i + 1), Rect2(0, i * 68, 33, 66)) as Button
		tab.text = str(i + 1)
		tab.add_theme_font_size_override("font_size", 22)
		UI.page_tab(tab, i == 0)
	place("ArchiveStatusPanel", Rect2(-310, -61, 600, 52), Vector2(0.5, 1)).add_theme_stylebox_override("panel", UI.paper("strip"))
	var status := label("ArchiveStatusPanel/EditableContent/StatusLabel", Rect2(48, 9, 534, 35), 12)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	artwork(hud.get_node("ArchiveStatusPanel/EditableContent"), "HintBulb", "bulb", Rect2(17, 11, 24, 31))
	for path: String in ["FurnitureActionMenu", "RotationOverlay/RotationDialog", "RoomPanControls"]:
		(hud.get_node(path) as Control).add_theme_stylebox_override("panel", UI.paper("strip"))
	var decor := hud.get_node_or_null("ArchiveDecorations") as Control
	if decor == null:
		decor = Control.new()
		decor.name = "ArchiveDecorations"
		hud.add_child(decor)
		decor.owner = hud
		hud.move_child(decor, 0)
	decor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	artwork(decor, "BureauStrip", "strip", Rect2(-9, -12, 445, 55))
	new_label(decor, "BureauLabel", "CITY INVESTIGATION BUREAU   /   OBSERVE · CONNECT · REVEAL", Rect2(24, 14, 404, 16), 9)
	var photo := artwork(decor, "ArchivePhoto", "photo", Rect2(-32, 408, 193, 189))
	photo.modulate = Color(0.8, 0.76, 0.7, 0.76)
	var news := artwork(decor, "ArchiveNewspaper", "newspaper", Rect2(-29, 616, 291, 92))
	news.rotation = 0.09
	news.modulate = Color(0.72, 0.67, 0.6, 0.85)
	var map := artwork(decor, "ArchiveMap", "map", Rect2(1030, 664, 260, 61))
	map.modulate = Color(0.8, 0.73, 0.63, 0.7)
	var packed := PackedScene.new()
	packed.pack(hud)
	var result := ResourceSaver.save(packed, "res://scenes/studio/studio_hud.tscn")
	print("INVESTIGATION_HUD_SAVED ", result)
	hud.free()
	quit(result)
