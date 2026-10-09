class_name TerminalMailClient
extends VBoxContainer
## A local inbox. Visible messages become read after a short dwell at the end.

signal refresh_requested
signal mark_read_requested(mail_id: String)
signal case_requested(mail_id: String, case_id: String, accepted: bool)
signal replay_requested(case_id: String)
signal mail_selected(mail_id: String)

const FOLDER_NAMES := {"inbox": "收件箱", "read": "已读邮件", "archived": "已归档"}

@onready var messages: Tree = %Messages
@onready var sender_label: Label = %Sender
@onready var subject_label: Label = %Subject
@onready var body_label: RichTextLabel = %Body
@onready var mark_read: Button = %MarkRead
@onready var case_action: Button = %CaseAction
@onready var body_scroll: ScrollContainer = %Scroll

var selected_mail_id := ""
var _mails: Array[Dictionary] = []
var _completed_cases: Dictionary = {}
var _folder := "inbox"
var _rebuilding := false
var _read_timer: Timer
var _displayed_mail_id := ""
var _displayed_body := ""
var _reading_active := true

func _ready() -> void:
	_read_timer = Timer.new()
	_read_timer.one_shot = true
	_read_timer.wait_time = 1.2
	_read_timer.timeout.connect(_finish_reading)
	add_child(_read_timer)
	body_scroll.get_v_scroll_bar().value_changed.connect(_queue_read_check)
	body_scroll.resized.connect(func() -> void: _queue_read_check.call_deferred())
	visibility_changed.connect(func() -> void: _queue_read_check.call_deferred())
	%CheckMail.pressed.connect(func() -> void: refresh_requested.emit())
	mark_read.pressed.connect(_mark_selected_read)
	case_action.pressed.connect(_open_selected_case)
	messages.item_selected.connect(_on_item_selected)
	messages.item_activated.connect(_on_item_selected)
	messages.set_column_expand(0, false)
	messages.set_column_custom_minimum_width(0, 175)
	messages.set_column_expand(1, true)
	messages.set_column_expand(2, false)
	messages.set_column_custom_minimum_width(2, 84)
	_refresh_view()

func configure(mails: Array, completed_cases: Dictionary, folder: String, selected_id: String) -> void:
	_mails.clear()
	for value: Variant in mails:
		if value is Dictionary:
			_mails.append((value as Dictionary).duplicate(true))
	_completed_cases = completed_cases.duplicate()
	_folder = folder if FOLDER_NAMES.has(folder) else "inbox"
	selected_mail_id = selected_id
	_refresh_view()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh_view.call_deferred()

func _refresh_view() -> void:
	if not is_node_ready(): return
	_rebuilding = true
	messages.clear()
	# TreeItem text is explicitly translated; it is not a Label control.
	for column: int in 3:
		messages.set_column_title(column, tr(["发件人", "主题", "状态"][column]))
	var tree_root := messages.create_item()
	var selection: TreeItem
	var unread := 0
	var count := 0
	for mail: Dictionary in _mails:
		if not _matches_folder(mail): continue
		count += 1
		var item := messages.create_item(tree_root)
		item.set_metadata(0, String(mail.get("mail_id", "")))
		item.set_text(0, tr(String(mail.get("sender", "未知发件人"))))
		item.set_text(1, tr(String(mail.get("subject", "无主题"))))
		item.set_text(2, tr(_mail_state(mail)))
		for column: int in 3:
			item.set_tooltip_text(column, item.get_text(column))
		if not bool(mail.get("is_read", false)):
			unread += 1
			item.set_text(1, "●  " + item.get_text(1))
		if String(mail.get("mail_id", "")) == selected_mail_id:
			selection = item
	if selection == null:
		selection = tree_root.get_first_child()
	selected_mail_id = String(selection.get_metadata(0)) if selection != null else ""
	if selection != null:
		selection.select(0)
		messages.scroll_to_item(selection)
	%FolderName.text = FOLDER_NAMES[_folder]
	%MessageCount.text = "共 %d 封邮件，%d 封未读" % [count, unread]
	_rebuilding = false
	_update_reader()

func _matches_folder(mail: Dictionary) -> bool:
	match _folder:
		"read": return bool(mail.get("is_read", false))
		"archived": return _is_completed(mail)
		_: return true

func _is_completed(mail: Dictionary) -> bool:
	return bool(_completed_cases.get(String(mail.get("case_id", "")), false))

func _mail_state(mail: Dictionary) -> String:
	if _is_completed(mail): return "已归档"
	if bool(mail.get("is_accepted", false)): return "已接取"
	return "已读" if bool(mail.get("is_read", false)) else "未读"

func _selected_mail() -> Dictionary:
	for mail: Dictionary in _mails:
		if String(mail.get("mail_id", "")) == selected_mail_id:
			return mail
	return {}

func _on_item_selected() -> void:
	if _rebuilding: return
	var item := messages.get_selected()
	if item == null: return
	selected_mail_id = String(item.get_metadata(0))
	_update_reader()
	mail_selected.emit(selected_mail_id)

func _update_reader() -> void:
	var mail := _selected_mail()
	var has_mail := not mail.is_empty()
	var body_text := String(mail.get("body", "")) if has_mail else "此文件夹中没有邮件。"
	var changed := _displayed_mail_id != selected_mail_id or _displayed_body != body_text
	_displayed_mail_id = selected_mail_id
	_displayed_body = body_text
	sender_label.text = String(mail.get("sender", ""))
	subject_label.text = String(mail.get("subject", ""))
	subject_label.tooltip_text = subject_label.text
	body_label.text = body_text
	mark_read.disabled = not has_mail or bool(mail.get("is_read", false))
	case_action.disabled = not has_mail or String(mail.get("case_id", "")).is_empty()
	case_action.text = "重新调查" if _is_completed(mail) else ("继续委托" if bool(mail.get("is_accepted", false)) else "接取委托")
	case_action.tooltip_text = "重新进入已完成案件，不会重复获得酬劳" if _is_completed(mail) else ""
	%SelectionState.text = _mail_state(mail) if has_mail else ""
	if changed:
		body_scroll.scroll_vertical = 0
	_queue_read_check.call_deferred()

func _can_finish_reading() -> bool:
	var mail := _selected_mail()
	if not _reading_active or not is_visible_in_tree() or mail.is_empty() or bool(mail.get("is_read", false)):
		return false
	var bar := body_scroll.get_v_scroll_bar()
	return bar.value >= bar.max_value - bar.page - 1.0

func set_reading_active(active: bool) -> void:
	if _reading_active == active: return
	_reading_active = active
	_queue_read_check.call_deferred()

func _queue_read_check(_scroll_value: float = 0.0) -> void:
	if not is_instance_valid(_read_timer): return
	_read_timer.stop()
	if _can_finish_reading():
		_read_timer.start()

func _finish_reading() -> void:
	if _can_finish_reading():
		mark_read_requested.emit(selected_mail_id)

func _mark_selected_read() -> void:
	if not mark_read.disabled:
		mark_read_requested.emit(selected_mail_id)

func _open_selected_case() -> void:
	if case_action.disabled: return
	var mail := _selected_mail()
	var case_id := String(mail.get("case_id", ""))
	if _is_completed(mail):
		replay_requested.emit(case_id)
	else:
		case_requested.emit(selected_mail_id, case_id, bool(mail.get("is_accepted", false)))
