@tool
extends Panel

signal close_requested
signal request_hint_requested

@export var popup_size: Vector2 = Vector2.ZERO:
	set(value):
		popup_size = value
		_apply_popup_size()

@onready var _panel_container: PanelContainer = $PanelContainer
@onready var _scroll_container: ScrollContainer = $PanelContainer/VBoxContainer/ScrollContainer
@onready var _hints_list: VBoxContainer = $PanelContainer/VBoxContainer/ScrollContainer/HintsList
@onready var _request_button: Button = $PanelContainer/VBoxContainer/ButtonRow/RequestButton

func _ready() -> void:
	_apply_popup_size()
	if not Engine.is_editor_hint():
		_request_button.pressed.connect(_on_request_pressed)

func _on_request_pressed() -> void:
	request_hint_requested.emit()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if visible and not get_global_rect().has_point(event.global_position):
			call_deferred("hide")
			close_requested.emit()

func add_hint(text: String) -> void:
	if _hints_list.get_child_count() > 0:
		var separator := HSeparator.new()
		_hints_list.add_child(separator)
		
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.x = _hint_text_width()
	_hints_list.add_child(label)
	
func clear_hints() -> void:
	for child in _hints_list.get_children():
		child.queue_free()

func show_no_hints_message() -> void:
	clear_hints()
	var label := Label.new()
	label.text = "No hints available."
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.x = _hint_text_width()
	_hints_list.add_child(label)

func _apply_popup_size() -> void:
	if not is_inside_tree() or _panel_container == null:
		return

	var resolved_size := _get_resolved_popup_size()
	custom_minimum_size = resolved_size
	size = resolved_size
	_panel_container.custom_minimum_size = resolved_size
	_panel_container.size = resolved_size
	_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hints_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hints_list.custom_minimum_size.x = _hint_text_width()
	for child in _hints_list.get_children():
		if child is Control:
			child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			child.custom_minimum_size.x = _hint_text_width()

	set_anchors_preset(Control.PRESET_CENTER, false)
	offset_left = -resolved_size.x * 0.5
	offset_top = -resolved_size.y * 0.5
	offset_right = resolved_size.x * 0.5
	offset_bottom = resolved_size.y * 0.5

func _get_resolved_popup_size() -> Vector2:
	if popup_size.x > 0.0 and popup_size.y > 0.0:
		return Vector2(maxf(popup_size.x, 200.0), maxf(popup_size.y, 140.0))

	if _panel_container.size.x > 0.0 and _panel_container.size.y > 0.0:
		return _panel_container.size

	if _panel_container.custom_minimum_size.x > 0.0 and _panel_container.custom_minimum_size.y > 0.0:
		return _panel_container.custom_minimum_size

	if size.x > 0.0 and size.y > 0.0:
		return size

	return Vector2(300, 200)

func _hint_text_width() -> float:
	var resolved_size := _get_resolved_popup_size()
	return maxf(160.0, resolved_size.x - 48.0)
