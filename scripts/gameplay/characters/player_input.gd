class_name PlayerInput
extends CharacterInput

@export_category("Player Input")
@export var hold_threshold: float = 0.1
@export var hold_time: float = 0.0

func _ready() -> void:
	GameLogger.info("Loading player input component ...")

func is_continuous_input() -> bool:
	return Modules.is_action_pressed()
