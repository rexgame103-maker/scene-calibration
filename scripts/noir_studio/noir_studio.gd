extends Control
## Standalone painted studio study. All coordinates use the original 1536 × 1024 art.

const ART_SIZE := Vector2(1536, 1024)
const IDLE_TEXT := "移动鼠标发现物件 · 单击调查 · 滚轮缩放 · 中键拖动画面 · R 返回全景"
@onready var artwork: Node2D = $Artwork
@onready var hotspots: Node2D = $Artwork/Hotspots
@onready var outline: Line2D = $Artwork/Outline
@onready var heading: Label = $HUD/Panel/Margin/Column/Heading
@onready var detail: Label = $HUD/Panel/Margin/Column/Detail
var hovered: Polygon2D
var selected: Polygon2D
var fit_scale := 1.0
var zoom := 1.0

func _ready() -> void:
	resized.connect(_fit_room)
	$HUD/Panel/Margin/Column/Reset.pressed.connect(_reset_view)
	_fit_room()
	_show_selection(null)

func _fit_room() -> void:
	fit_scale = minf(size.x / ART_SIZE.x, maxf(100.0, size.y - 120.0) / ART_SIZE.y)
	zoom = 1.0
	artwork.scale = Vector2.ONE * fit_scale
	artwork.position = Vector2((size.x - ART_SIZE.x * fit_scale) * 0.5, (size.y - 120.0 - ART_SIZE.y * fit_scale) * 0.5)

func _reset_view() -> void:
	_fit_room()
	_show_selection(null)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_reset_view()
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) and event.position.y < size.y - 120.0:
			artwork.position += event.relative
		_update_hover(event.position)
	if event is InputEventMouseButton and event.pressed and event.position.y < size.y - 120.0:
		_update_hover(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT:
			_show_selection(hovered)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var anchor := artwork.to_local(event.position)
			zoom = clampf(zoom * (1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15), 1.0, 2.5)
			artwork.scale = Vector2.ONE * fit_scale * zoom
			artwork.position = event.position - anchor * artwork.scale
			_update_hover(event.position)

func _update_hover(pointer: Vector2) -> void:
	hovered = null
	if pointer.y < size.y - 120.0:
		var point := artwork.to_local(pointer)
		# Small foreground objects are later in the scene tree and take precedence.
		for child in hotspots.get_children():
			var region := child as Polygon2D
			if Geometry2D.is_point_in_polygon(point, region.polygon):
				hovered = region
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hovered != null else Input.CURSOR_ARROW)
	_draw_outline(hovered if hovered != null else selected)

func _show_selection(region: Polygon2D) -> void:
	selected = region
	heading.text = str(region.get_meta("title")) if region != null else "深夜 · 私人工作室"
	detail.text = str(region.get_meta("description")) if region != null else IDLE_TEXT
	_draw_outline(region)

func _draw_outline(region: Polygon2D) -> void:
	outline.visible = region != null
	if region != null:
		outline.points = region.polygon

func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
