extends PanelContainer
## A desktop application window. Its parent is the usable desktop workspace.

signal activation_requested
signal minimize_requested
signal close_requested
signal maximized_changed(maximized: bool)

var app_id := ""
var is_maximized := false
var is_minimized := false
var normal_rect := Rect2()
var _title_bar: Control
var _dragging := false
var _drag_offset := Vector2.ZERO


func _ready() -> void:
	# Wrapped text can change its minimum height after the first layout pass.
	minimum_size_changed.connect(func() -> void: fit_to_workspace.call_deferred())


func bind_title_bar(title_bar: Control) -> void:
	_title_bar = title_bar
	title_bar.gui_input.connect(_on_title_input)
	title_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		activation_requested.emit()


func _on_title_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		activation_requested.emit()
		if event.double_click:
			toggle_maximized()
		elif not is_maximized:
			var pointer := _workspace_pointer(_title_bar.get_global_transform_with_canvas() * event.position)
			_drag_offset = pointer - position
			_dragging = true
	else:
		_dragging = false
	_title_bar.accept_event()


func _input(event: InputEvent) -> void:
	# Activate before child buttons handle input, so callbacks use this app's context.
	if event is InputEventMouseButton and event.pressed and is_visible_in_tree():
		var siblings := get_parent().get_children()
		siblings.reverse()
		for sibling: Node in siblings:
			if sibling.get_script() == get_script() and sibling.visible and sibling.get_global_rect().has_point(event.position):
				if sibling == self: activation_requested.emit()
				break
	if not _dragging: return
	if not is_visible_in_tree():
		_dragging = false
		return
	if event is InputEventMouseMotion:
		position = _clamp_position(_workspace_pointer(event.position) - _drag_offset)
		normal_rect = Rect2(position, size)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging = false
		get_viewport().set_input_as_handled()


func toggle_maximized() -> void:
	_dragging = false
	if not is_maximized:
		normal_rect = Rect2(position, size)
	is_maximized = not is_maximized
	fit_to_workspace()
	maximized_changed.emit(is_maximized)


func fit_to_workspace() -> void:
	var workspace_size: Vector2 = get_parent().size
	if is_maximized:
		position = Vector2.ZERO
		size = workspace_size
	else:
		size = normal_rect.size.min(workspace_size)
		position = _clamp_position(normal_rect.position)


func stop_dragging() -> void:
	_dragging = false


func _clamp_position(value: Vector2) -> Vector2:
	var available: Vector2 = (get_parent().size - size).max(Vector2.ZERO)
	return value.clamp(Vector2.ZERO, available)


func _workspace_pointer(viewport_position: Vector2) -> Vector2:
	return get_parent().get_global_transform_with_canvas().affine_inverse() * viewport_position
