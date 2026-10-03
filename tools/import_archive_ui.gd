extends SceneTree
## Slice the generated blank art and remove its neutral exterior in the import step.
func _initialize() -> void:
	var source := Image.load_from_file("res://assets/ui/archive_theme/source/blank_atlas.png")
	var regions := {
		"empty_archive": Rect2i(),
		"case_panel": Rect2i(48,44,880,510),
		"inventory_panel": Rect2i(994,45,494,714),
		"status_bar": Rect2i(47,795,883,149),
		"button": Rect2i(992,796,500,146)
	}
	for key: String in regions:
		var img := Image.load_from_file("res://assets/ui/archive_theme/source/empty_archive.png") if key == "empty_archive" else source.get_region(regions[key])
		img.convert(Image.FORMAT_RGBA8)
		var w := img.get_width()
		var h := img.get_height()
		var visited := PackedByteArray()
		visited.resize(w*h)
		var queue := PackedInt32Array()
		for x in w:
			queue.append(x)
			queue.append((h-1)*w+x)
		for y in h:
			queue.append(y*w)
			queue.append(y*w+w-1)
		var index := 0
		while index < queue.size():
			var p := queue[index]
			index += 1
			if visited[p]: continue
			visited[p] = 1
			var x := p%w
			var y := p/w
			var c := img.get_pixel(x,y)
			var high := maxf(c.r,maxf(c.g,c.b))
			var low := minf(c.r,minf(c.g,c.b))
			if high-low > 0.12 or low < 0.32: continue
			img.set_pixel(x,y,Color(c.r,c.g,c.b,0))
			if x>0: queue.append(p-1)
			if x<w-1: queue.append(p+1)
			if y>0: queue.append(p-w)
			if y<h-1: queue.append(p+w)
		# Small enclosed opening above the clip is also background.
		if key == "case_panel":
			for y in range(8,46):
				for x in range(716,748):
					var c := img.get_pixel(x,y)
					if maxf(c.r,maxf(c.g,c.b))-minf(c.r,minf(c.g,c.b)) < 0.07 and c.r>0.55:
						img.set_pixel(x,y,Color(c.r,c.g,c.b,0))
		assert(img.detect_alpha() != Image.ALPHA_NONE)
		if key == "empty_archive": img = img.get_region(img.get_used_rect().grow(3).intersection(Rect2i(0,0,w,h)))
		else: img.resize(roundi(w*0.4),roundi(h*0.4),Image.INTERPOLATE_LANCZOS)
		assert(img.save_png("res://assets/ui/archive_theme/"+key+".png") == OK)
		print("UI_ALPHA_OK: ",key," ",w,"x",h)
	quit()
