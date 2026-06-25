class_name EnemyInput
extends CharacterInput

var is_chasing: bool = false

func is_continuous_input() -> bool:
	return is_chasing

func _ready() -> void:
	GameLogger.info("Loading enemy input component ...")
