extends CanvasLayer

signal dismissed

var _name_label: Label
var _text_label: Label
var _hint_label: Label

var _full_text: String = ""
var _animating: bool = false
var _char_timer: float = 0.0
var _char_index: int = 0

const CHAR_DELAY = 0.04

func _ready() -> void:
	_name_label = get_node("%NameLabel")
	_text_label = get_node("%TextLabel")
	_hint_label = get_node("%HintLabel")
	
	if Globals.instance and Globals.instance.ui_theme:
		get_node("Panel").theme = Globals.instance.ui_theme

func play_dialogue(entries: Array) -> void:
	for entry in entries:
		_name_label.text = entry.speaker_name
		_text_label.text = ""
		_full_text = entry.text
		_char_index = 0
		_char_timer = 0.0
		_animating = true
		_hint_label.text = "[Enter] Skip"
		
		await dismissed

func _process(delta: float) -> void:
	if not _name_label:
		return
	
	if _animating:
		_char_timer += delta
		while _animating and _char_timer >= CHAR_DELAY:
			_char_index += 1
			_text_label.text = _full_text.substr(0, _char_index)
			_char_timer -= CHAR_DELAY
			if _char_index >= _full_text.length():
				_animating = false
				_hint_label.text = "[Enter] Next"
	
	if Input.is_action_just_pressed("ui_accept"):
		if _animating:
			_animating = false
			_char_index = _full_text.length()
			_text_label.text = _full_text
			_hint_label.text = "[Enter] Next"
		else:
			dismissed.emit()
