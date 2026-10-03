extends SceneTree

func _initialize() -> void:
	var image := Image.load_from_file("C:/Users/REX/.codex/generated_images/01a083a6-ccf6-73c0-bb73-1491c7442b00/exec-1cb5b955-fcfe-4377-a2a6-71586663a2f9.png")
	var protected: Array[PackedVector2Array] = []
	for points in [
		[Vector2(47,104),Vector2(306,82),Vector2(325,379),Vector2(55,405)],
		[Vector2(285,66),Vector2(520,87),Vector2(503,303),Vector2(300,286)],
		[Vector2(543,53),Vector2(710,52),Vector2(714,292),Vector2(545,292)],
		[Vector2(1006,52),Vector2(1259,34),Vector2(1279,342),Vector2(1026,363)],
		[Vector2(428,371),Vector2(649,336),Vector2(687,610),Vector2(449,640)],
		[Vector2(1330,247),Vector2(1493,231),Vector2(1512,496),Vector2(1344,511)],
		[Vector2(1166,496),Vector2(1396,518),Vector2(1380,680),Vector2(1153,658)],
		[Vector2(83,634),Vector2(355,605),Vector2(379,834),Vector2(98,866)],
		[Vector2(506,693),Vector2(813,662),Vector2(840,910),Vector2(526,940)],
		[Vector2(938,656),Vector2(1115,626),Vector2(1146,895),Vector2(966,924)],
		[Vector2(562,109),Vector2(1150,97),Vector2(1179,603),Vector2(588,617)]
	]: protected.append(PackedVector2Array(points))
	image.convert(Image.FORMAT_RGBA8)
	var cleared := 0
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x,y)
			# The generated matte is slightly blue-gray; the monochrome artwork is neutral.
			if c.b-c.r > 0.007 and c.b-c.r < 0.065 and absf(c.g-c.r) < 0.025 and c.r > 0.38:
				var inside := false
				for polygon in protected:
					if Geometry2D.is_point_in_polygon(Vector2(x,y),polygon):
						inside=true
						break
				if inside: continue
				c.a=0.0
				image.set_pixel(x,y,c)
				cleared+=1
	assert(cleared>100000 or image.detect_alpha()!=Image.ALPHA_NONE)
	assert(image.save_png("res://assets/player_studio/clue_board/collage.png")==OK)
	print("TRANSPARENT_PIXELS: ",cleared)
	quit()
