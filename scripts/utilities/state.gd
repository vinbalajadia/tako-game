class_name State
extends Node

@export var state_owner: Node

func enter_state() -> void:
	GameLogger.info("Entering state: " + name)

func exit_state() -> void:
	GameLogger.info("Exiting state: " + name)
