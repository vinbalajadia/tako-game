class_name Level
extends Node2D

@export_category("Level Basics")
@export var level_name: int = Enums.LevelId.Level0
@export var spawn_dialogue: Array[DialogueEntry] = []

@export_category("Camera Limits")
@export var top: int = 0
@export var bottom: int = 0
@export var left: int = 0
@export var right: int = 0

func _ready() -> void:
	GameLogger.info("Loading level: " + str(level_name) + " ...")
