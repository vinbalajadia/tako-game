class_name CharacterInput
extends Node

@warning_ignore("unused_signal")
signal walk
@warning_ignore("unused_signal")
signal turn
@warning_ignore("unused_signal")
signal idle

@export_category("Common Input")
@export var direction: Vector2 = Vector2.ZERO
@export var target_position: Vector2 = Vector2.ZERO

# True when a continuous input is held — suppresses idle animation flicker
# at the end of each grid step. Override in PlayerInput; enemies return false.
func is_continuous_input() -> bool:
	return false
