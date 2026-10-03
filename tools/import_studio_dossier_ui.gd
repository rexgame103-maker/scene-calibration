extends SceneTree
## Slice the text-free, transparent artwork into reusable studio UI textures.


func _initialize() -> void:
	var atlas := Image.load_from_file("res://assets/ui/studio_dossier/blank_atlas.png")
	assert(atlas != null and atlas.detect_alpha() != Image.ALPHA_NONE)
	var regions := {
		"title": Rect2i(0, 20, 550, 290),
		"tab_floor_1": Rect2i(30, 305, 250, 88),
		"tab_floor_2": Rect2i(30, 390, 250, 82),
		"tab_wall": Rect2i(30, 470, 250, 82),
		"tab_floor_style": Rect2i(30, 550, 250, 82),
		"tab_money": Rect2i(30, 630, 250, 85),
		"jump_label": Rect2i(25, 730, 240, 100),
		"jump_label_alt": Rect2i(270, 730, 250, 100),
		"catalog_card": Rect2i(680, 95, 345, 135),
		"catalog_book": Rect2i(1040, 0, 495, 880),
		"status": Rect2i(28, 838, 570, 70),
		"button_wide": Rect2i(605, 838, 370, 70),
		"button_small": Rect2i(30, 920, 135, 80),
		"button_bottom": Rect2i(1030, 902, 470, 88),
	}
	for asset: String in regions:
		var piece := atlas.get_region(regions[asset])
		var used := piece.get_used_rect()
		assert(used.size.x > 0 and used.size.y > 0, "Missing artwork: " + asset)
		piece = piece.get_region(used.grow(2).intersection(Rect2i(Vector2i.ZERO, piece.get_size())))
		var path := "res://assets/ui/studio_dossier/%s.png" % asset
		assert(piece.save_png(path) == OK)
		print("STUDIO_UI_ASSET: %s %s" % [asset, piece.get_size()])
	quit()
