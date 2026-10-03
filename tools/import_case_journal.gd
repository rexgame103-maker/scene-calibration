extends SceneTree
func _initialize() -> void:
	var img := Image.load_from_file("res://assets/ui/case_journal/source.png")
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var seen := PackedByteArray()
	seen.resize(w*h)
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
		if seen[p]: continue
		seen[p] = 1
		var x := p%w
		var y := p/w
		var c := img.get_pixel(x,y)
		if maxf(c.r,maxf(c.g,c.b))-minf(c.r,minf(c.g,c.b)) > 0.085 or minf(c.r,minf(c.g,c.b)) < 0.40: continue
		img.set_pixel(x,y,Color(c.r,c.g,c.b,0))
		if x>0: queue.append(p-1)
		if x<w-1: queue.append(p+1)
		if y>0: queue.append(p-w)
		if y<h-1: queue.append(p+w)
	assert(img.get_pixel(0,0).a == 0)
	img.save_png("res://assets/ui/case_journal/book.png")
	print("JOURNAL_ALPHA_OK")
	quit()
