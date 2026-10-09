extends RefCounted
## Check rendered native text and its surrounding UI frames after layout completes.

static func audit(node: Node, issues: Array[Dictionary], context: String) -> void:
	if node is Control and not node.is_visible_in_tree(): return
	if node is Label or node is Button or node is RichTextLabel:
		var control := node as Control
		if control.size.x > 0 and control.size.y > 0:
			var parent := control.get_parent() as Control
			# Check outer cards as well as the nearest layout container. A VBox
			# can grow past its card while all its labels still fit the VBox.
			# Stop at the scroll viewport, whose contents may extend intentionally.
			while parent != null and not parent is ScrollContainer:
				if parent.size.x > 0 and parent.size.y > 0:
					var transform := parent.get_global_transform_with_canvas().affine_inverse() * control.get_global_transform_with_canvas()
					var rect := transform * Rect2(Vector2.ZERO, control.size)
					if not Rect2(Vector2(-1, -1), parent.size + Vector2(2, 2)).encloses(rect):
						add_issue(issues, control, context, "outside ancestor frame %s: %s / %s" % [parent.name, rect, parent.size])
						break
				parent = parent.get_parent() as Control
			if node is Label:
				if node.autowrap_mode == TextServer.AUTOWRAP_OFF:
					var text: String = node.text if node.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED else node.tr(node.text)
					if node.uppercase: text = text.to_upper()
					var font: Font = node.get_theme_font("font")
					var style: StyleBox = node.get_theme_stylebox("normal")
					var available: float = node.size.x - style.get_content_margin(SIDE_LEFT) - style.get_content_margin(SIDE_RIGHT)
					for line: String in text.split("\n"):
						var width: float = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, node.get_theme_font_size("font_size")).x
						if width > available + 1:
							add_issue(issues, control, context, "text wider than label: %.1f / %.1f" % [width, available])
							break
				if node.get_line_count() > node.get_visible_line_count():
					add_issue(issues, control, context, "hidden text lines: %d / %d" % [node.get_visible_line_count(), node.get_line_count()])
			elif node is Button:
				audit_button(node, issues, context)
			elif node is RichTextLabel and not node.scroll_active:
				if node.get_content_height() > node.size.y + 2:
					add_issue(issues, control, context, "clipped paragraph: %d / %.1f" % [node.get_content_height(), node.size.y])
	for child: Node in node.get_children():
		audit(child, issues, context)

static func audit_button(button: Button, issues: Array[Dictionary], context: String) -> void:
	var text := button.text if button.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED else button.tr(button.text)
	if text.is_empty(): return
	# Text must fit inside the artwork in every interaction state, not just
	# inside the outer Control rectangle. Clipping/ellipsis still counts as a
	# finding so labels can be shortened or their frames enlarged deliberately.
	var margins := Vector2.ZERO
	for state: String in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		var style := button.get_theme_stylebox(state)
		margins.x = maxf(margins.x, style.get_content_margin(SIDE_LEFT) + style.get_content_margin(SIDE_RIGHT))
		margins.y = maxf(margins.y, style.get_content_margin(SIDE_TOP) + style.get_content_margin(SIDE_BOTTOM))
	var available := button.size - margins
	if button.icon != null:
		var icon_size := button.icon.get_size()
		var icon_max_width := button.get_theme_constant("icon_max_width")
		if icon_max_width > 0 and icon_size.x > icon_max_width:
			icon_size *= float(icon_max_width) / icon_size.x
		if button.expand_icon and icon_size.y > available.y:
			icon_size *= available.y / icon_size.y
		if button.icon_alignment == HORIZONTAL_ALIGNMENT_CENTER and button.vertical_icon_alignment != VERTICAL_ALIGNMENT_CENTER:
			available.y -= icon_size.y + button.get_theme_constant("h_separation")
		else:
			available.x -= icon_size.x + button.get_theme_constant("h_separation")
	if button is OptionButton:
		available.x -= button.get_theme_icon("arrow").get_width() + button.get_theme_constant("arrow_margin")
	elif button is CheckButton or button is CheckBox:
		available.x -= maxf(button.get_theme_icon("checked").get_width(), button.get_theme_icon("unchecked").get_width()) + button.get_theme_constant("h_separation")
	var font := button.get_theme_font("font")
	var font_size := button.get_theme_font_size("font_size")
	var flags := TextServer.BREAK_MANDATORY
	match button.autowrap_mode:
		TextServer.AUTOWRAP_ARBITRARY: flags |= TextServer.BREAK_GRAPHEME_BOUND
		TextServer.AUTOWRAP_WORD: flags |= TextServer.BREAK_WORD_BOUND
		TextServer.AUTOWRAP_WORD_SMART: flags |= TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	var measured := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, maxf(1, available.x), font_size, -1, flags)
	if button.autowrap_mode == TextServer.AUTOWRAP_OFF:
		for line: String in text.split("\n"):
			measured.x = maxf(measured.x, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	if measured.x > available.x + 1:
		add_issue(issues, button, context, "button text wider than inner frame: %.1f / %.1f" % [measured.x, available.x])
	if measured.y > available.y + 2:
		add_issue(issues, button, context, "button text taller than inner frame: %.1f / %.1f" % [measured.y, available.y])

static func add_issue(issues: Array[Dictionary], control: Control, context: String, reason: String) -> void:
	var entry := {"context": context, "path": String(control.get_path()), "source": String(control.text), "reason": reason}
	if entry not in issues: issues.append(entry)
