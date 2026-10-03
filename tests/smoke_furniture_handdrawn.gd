extends SceneTree

const ICONS := preload("res://scripts/furniture_icon_library.gd")
var failures: Array[String] = []
var dragged := ""

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _run() -> void:
	root.size = Vector2i(1280, 900)
	for entry: Dictionary in FurnitureFactory.CATALOG:
		check(ICONS.has_icon(entry.kind), "Case furniture icon exists: " + entry.kind)
	for kind: String in StudioFurnitureFactory.ITEMS:
		check(ICONS.has_icon(kind), "Studio furniture icon exists: " + kind)
	var view := Control.new()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(view)
	var background := ColorRect.new()
	background.color = Color("e4d4b8")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(background)
	var sheets: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/furniture_handdrawn/sheets.json"))
	var index := 0
	for sheet: Dictionary in sheets:
		for kind: String in sheet.items:
			var texture := ICONS.get_icon(kind) as AtlasTexture
			check(texture != null, "Art loads: " + kind)
			if texture == null: continue
			var image := texture.atlas.get_image()
			check(image.get_pixel(0, 0).a == 0, "Atlas has actual transparent alpha")
			check(Rect2(Vector2.ZERO, image.get_size()).encloses(texture.region), "No region extends beyond atlas")
			var slot := Vector2(22 + (index % 6) * 210, 12 + (index / 6) * 146)
			var icon := TextureRect.new()
			icon.texture = texture
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.position = slot + Vector2(42, 0)
			icon.size = Vector2(115, 115)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			view.add_child(icon)
			var caption := Label.new()
			caption.text = kind
			caption.position = slot + Vector2(0, 116)
			caption.size = Vector2(198, 24)
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			caption.add_theme_font_size_override("font_size", 12)
			caption.add_theme_color_override("font_color", Color("302820"))
			view.add_child(caption)
			index += 1
	await create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/furniture_handdrawn_overview.png")
	for child in view.get_children(): child.queue_free()
	await process_frame
	root.size = Vector2i(1280, 720)
	# Validate real catalog input with new artwork, including authored studio slots.
	var card := CatalogItem.new()
	card.setup(FurnitureFactory.get_info("desk").merged({"visual_style": "case_dossier"}, true))
	card.position = Vector2(30, 30)
	card.size = Vector2(245, 124)
	card.drag_started.connect(func(kind: String): dragged = kind)
	view.add_child(card)
	await process_frame
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = card.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	check(dragged == "desk", "Hand-drawn catalog still begins dragging on a real click")
	card.queue_free()
	await process_frame
	var manager := root.get_node("CaseManager")
	manager.call("load_case", "res://data/cases/office_case_001.json")
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	main.get("first_case_flow_ui").call("_on_accept_pressed")
	main.set("inventory_counts", {"desk": 1, "chair": 1, "computer": 1, "water_dispenser": 1})
	main.call("_refresh_inventory_ui")
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/furniture_handdrawn_case_preview.png")
	main.queue_free()
	await process_frame
	var studio_card := (load("res://scenes/studio/studio_catalog_item.tscn") as PackedScene).instantiate() as CatalogItem
	view.add_child(studio_card)
	studio_card.setup({"kind": "studio_desk", "icon_kind": "desk", "label": "校准工作桌", "description": "自由摆放", "footprint": Vector2i(4,2), "color": Color.WHITE, "visual_style": "studio_dossier"})
	check(studio_card.get_node("IconAnchor").position == Vector2(12, 13), "Authored icon anchors remain editable")
	studio_card.position = Vector2(36, 36)
	studio_card.size = Vector2(260, 96)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/furniture_handdrawn_studio_card_preview.png")
	studio_card.queue_free()
	var computer := StudioComputerUI.new()
	computer.setup(root.get_node("PlayerProfile"))
	root.add_child(computer)
	computer.call("_show_app", "shop")
	await process_frame
	var shop_icons := computer.find_children("FurnitureIcon", "TextureRect", true, false)
	check(shop_icons.size() == 15, "Shop renders an icon for every furniture item")
	for icon: TextureRect in shop_icons:
		check(icon.texture != null, "Shop furniture has no missing art")
	computer.open_desktop()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/furniture_handdrawn_shop_preview.png")
	print("FURNITURE_HANDDRAWN_OK" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
