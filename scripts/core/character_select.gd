extends Control

signal character_selected(character: String)
signal cancelled

var _selected_index: int = 0

var _highlight_left: ColorRect
var _highlight_right: ColorRect
var _sprite_m: Sprite2D
var _sprite_f: Sprite2D

const ACTIVE_COLOR = Color(1.0, 1.0, 1.0, 0.12)
const INACTIVE_COLOR = Color(0.0, 0.0, 0.0, 0.0)
const SPRITE_DIM = Color(0.35, 0.35, 0.35, 1.0)
const SPRITE_FULL = Color(1.0, 1.0, 1.0, 1.0)

func _ready() -> void:
	if Globals.instance and Globals.instance.ui_theme:
		theme = Globals.instance.ui_theme
	
	_highlight_left = get_node("HighlightLeft")
	_highlight_right = get_node("HighlightRight")
	_sprite_m = get_node("SpriteM")
	_sprite_f = get_node("SpriteF")
	
	_update_highlight()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key = event as InputEventKey
		if not key.pressed or key.echo:
			return
		
		match key.physical_keycode:
			KEY_LEFT, KEY_A:
				_selected_index = 0
				_update_highlight()
			KEY_RIGHT, KEY_D:
				_selected_index = 1
				_update_highlight()
			KEY_ENTER, KEY_KP_ENTER:
				_confirm()
			KEY_ESCAPE:
				cancelled.emit()
	
	elif event is InputEventMouseMotion:
		var motion = event as InputEventMouseMotion
		var center_x = get_viewport().get_visible_rect().size.x / 2.0
		var hovered = 0 if motion.position.x < center_x else 1
		if hovered != _selected_index:
			_selected_index = hovered
			_update_highlight()
	
	elif event is InputEventMouseButton:
		var btn = event as InputEventMouseButton
		if btn.pressed and btn.button_index == MOUSE_BUTTON_LEFT:
			_confirm()

func _confirm() -> void:
	AudioManager.play_sfx("buttonclick")
	var character = "playerm" if _selected_index == 0 else "playerf"
	character_selected.emit(character)

func _update_highlight() -> void:
	_highlight_left.color = ACTIVE_COLOR if _selected_index == 0 else INACTIVE_COLOR
	_highlight_right.color = ACTIVE_COLOR if _selected_index == 1 else INACTIVE_COLOR
	_sprite_m.modulate = SPRITE_FULL if _selected_index == 0 else SPRITE_DIM
	_sprite_f.modulate = SPRITE_FULL if _selected_index == 1 else SPRITE_DIM
