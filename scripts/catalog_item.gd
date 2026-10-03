@tool
class_name CatalogItem
extends Control

const ARCHIVE_UI := preload("res://scripts/archive_ui_theme.gd")
const CASE_SCENE_UI := preload("res://scripts/case_scene_ui_theme.gd")
const STUDIO_UI := preload("res://scripts/studio_dossier_ui_theme.gd")
const INVESTIGATION_UI := preload("res://scripts/investigation_ui_theme.gd")
const FURNITURE_ICONS := preload("res://scripts/furniture_icon_library.gd")
var title_label: Label
var detail_label: Label
var size_label: Label


signal drag_started(kind: String)

var kind: String
var item_label: String
var description: String
var footprint := Vector2i.ONE
@export var accent := Color("a77d5b")
@export var icon_kind := "desk"
@export var visual_style := "paper"
var _hovered := false
var _pressed := false


func setup(item: Dictionary) -> void:
	kind = item.kind
	icon_kind = String(item.get("icon_kind", kind))
	item_label = item.label
	description = item.description
	footprint = item.footprint
	accent = item.color
	visual_style = String(item.get("visual_style", "paper"))
	var authored_studio_card := visual_style == "studio_dossier" and has_node("TitleLabel")
	if not authored_studio_card:
		custom_minimum_size = Vector2(228, 96) if visual_style == "studio_dossier" else Vector2(228, 124)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	tooltip_text = description
	if title_label == null:
		if authored_studio_card:
			title_label = get_node("TitleLabel") as Label
			detail_label = get_node("DetailLabel") as Label
			size_label = get_node("SizeLabel") as Label
		else:
			var column := VBoxContainer.new()
			column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			column.offset_left = 82 if visual_style == "studio_dossier" else 88
			column.offset_top = 9 if visual_style == "studio_dossier" else 12
			column.offset_right = -21 if visual_style == "studio_dossier" else -18
			column.offset_bottom = -7 if visual_style == "studio_dossier" else -10
			column.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(column)
			title_label = Label.new()
			detail_label = Label.new()
			size_label = Label.new()
			for label in [title_label,detail_label,size_label]:
				label.mouse_filter = Control.MOUSE_FILTER_IGNORE
				label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				label.add_theme_font_size_override("font_size",12)
				column.add_child(label)
			title_label.add_theme_font_size_override("font_size",14)
			detail_label.max_lines_visible = 2
			detail_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.text = item_label
	detail_label.text = description
	size_label.text = tr("%d × %d 格") % [footprint.x,footprint.y]
	if visual_style == "studio_dossier" and not authored_studio_card:
		title_label.add_theme_font_size_override("font_size", 13)
		detail_label.add_theme_font_size_override("font_size", 11)
		size_label.add_theme_font_size_override("font_size", 11)
	var primary := CASE_SCENE_UI.TEXT if visual_style == "dark" else STUDIO_UI.INK if visual_style == "studio_dossier" else ARCHIVE_UI.INK
	var secondary := CASE_SCENE_UI.MUTED if visual_style == "dark" else STUDIO_UI.MUTED if visual_style == "studio_dossier" else ARCHIVE_UI.INK
	if not authored_studio_card:
		title_label.add_theme_color_override("font_color", primary)
		detail_label.add_theme_color_override("font_color", secondary)
		size_label.add_theme_color_override("font_color", primary)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		_hovered = true
		queue_redraw()
	elif what == NOTIFICATION_MOUSE_EXIT:
		_hovered = false
		_pressed = false
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_pressed = event.pressed
		queue_redraw()
		if event.pressed:
			drag_started.emit(kind)
			accept_event()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if visual_style == "case_dossier":
		var style := INVESTIGATION_UI.paper("wide", Color("fff2d5") if _hovered else Color.WHITE)
		for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			style.set_texture_margin(side, 12)
		draw_style_box(style, rect)
		if _pressed:
			draw_rect(rect.grow(-6), Color("79523724"))
		var case_icon_rect := Rect2(12, 22, 70, 70)
		_draw_icon(case_icon_rect)
		return
	if visual_style == "studio_dossier":
		# Use a blank frame; the older four cards had furniture baked into the art.
		var style := INVESTIGATION_UI.paper("wide", Color("fff2d5") if _hovered else Color.WHITE)
		for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			style.set_texture_margin(side, 12)
		draw_style_box(style, rect)
		if _pressed:
			draw_rect(Rect2(5, 5, size.x - 10, size.y - 10), Color("79523724"), true)
		var icon_anchor := get_node_or_null("IconAnchor") as Control
		var icon_rect := Rect2(icon_anchor.position, icon_anchor.size) if icon_anchor != null else Rect2(12, 13, 64, 64)
		_draw_icon(icon_rect)
		return
	if visual_style == "dark":
		var panel_kind := "card"
		if _hovered:
			panel_kind = "card_hover"
		draw_style_box(CASE_SCENE_UI.panel(panel_kind), rect)
		if _pressed:
			draw_rect(Rect2(1, 1, size.x - 2, size.y - 2), Color("d8dee51c"), true)
		draw_rect(Rect2(0, 13, 4, size.y - 26), accent, true)
		var dark_icon_rect := Rect2(13, 13, 66, 66)
		_draw_icon(dark_icon_rect)
		for i: int in range(3):
			draw_circle(Vector2(size.x - 14, 38 + i * 8), 1.6, CASE_SCENE_UI.MUTED)
		return
	var bg := Color.WHITE
	if _hovered:
		bg = Color("fff2d2")
	if _pressed:
		bg = Color("ddc8a5")
	draw_style_box(ARCHIVE_UI.paper("inventory_panel",bg),rect)
	draw_rect(Rect2(0, 13, 4, size.y - 26), accent, true)

	var icon_rect := Rect2(13, 13, 66, 66)
	_draw_icon(icon_rect)

	for i: int in range(3):
		draw_circle(Vector2(size.x - 14, 38 + i * 8), 1.6, Color("80788f"))


func _draw_icon(rect: Rect2) -> void:
	var key := kind if FURNITURE_ICONS.has_icon(kind) else icon_kind
	var texture := FURNITURE_ICONS.get_icon(key)
	if texture == null:
		return
	draw_texture_rect(texture, FURNITURE_ICONS.fit_rect(texture, rect), false)
