extends SceneTree
func _initialize() -> void:
	var source := Image.load_from_file("res://assets/ui/the_scene_menu/source_sheet.png")
	var regions := {"face":Rect2i(0,0,590,690),"title":Rect2i(590,190,664,320),"ink":Rect2i(0,700,635,465),"button":Rect2i(640,840,614,205)}
	for key in regions:
		var image := source.get_region(regions[key])
		image.convert(Image.FORMAT_RGBA8)
		for y in image.get_height():
			for x in image.get_width():
				var c := image.get_pixel(x,y)
				var alpha := clampf(1.0-minf(c.r-c.g,c.b-c.g),0.0,1.0)
				if alpha<0.07:
					c=Color(0,0,0,0)
				else:
					c=Color(clampf((c.r-(1-alpha))/alpha,0,1),clampf(c.g/alpha,0,1),clampf((c.b-(1-alpha))/alpha,0,1),alpha)
					if key in ["ink","button"]:
						c=Color(0.012,0.009,0.006,alpha)
					elif c.b>maxf(c.r,c.g):
						c.b=c.g
				image.set_pixel(x,y,c)
		var trimmed := image.get_region(image.get_used_rect())
		assert(trimmed.detect_alpha()!=Image.ALPHA_NONE)
		assert(trimmed.save_png("res://assets/ui/the_scene_menu/%s.png"%key)==OK)
		if key=="button":
			for y in trimmed.get_height():
				for x in trimmed.get_width():
					var alpha := trimmed.get_pixel(x,y).a
					trimmed.set_pixel(x,y,Color(0.88,0.82,0.67,alpha))
			assert(trimmed.save_png("res://assets/ui/the_scene_menu/button_selected.png")==OK)
		print(key," ",trimmed.get_size())
	quit()
