class_name SpawnPoint
extends Node2D

func _enter_tree() -> void:
	add_to_group(Enums.LevelGroup.keys()[Enums.LevelGroup.SPAWNPOINTS])

func _exit_tree() -> void:
	remove_from_group(Enums.LevelGroup.keys()[Enums.LevelGroup.SPAWNPOINTS])
