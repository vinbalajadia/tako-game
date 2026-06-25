class_name SceneTrigger
extends Area2D

@export_category("Target Scene Vars")
@export var target_level_name: int = Enums.LevelName.Level0
@export var target_level_trigger: int = 0

@export_category("Current Scene Vars")
@export var current_level_trigger: int = 0
@export var entry_direction: Vector2 = Vector2.ZERO
@export var locked: bool = false

var _can_trigger: bool = true
var _last_triggered_player: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player" or not _can_trigger:
		return
	if SceneManager.is_changing or SceneManager.is_battling or DialogueManager.is_dialogue:
		return
	if body == _last_triggered_player:
		return

	if locked:
		GameLogger.info("Uh oh, the door is locked! Find a way to unlock it.")
		return

	_can_trigger = false
	_last_triggered_player = body

	var input: CharacterInput = body.get_node_or_null("Input")
	var dir: Vector2 = input.direction if input != null else Vector2.ZERO
	var tile_offset: int = 0
	if dir.y != 0:
		tile_offset = roundi((body.global_position.x - global_position.x) / Globals.grid_size)
	elif dir.x != 0:
		tile_offset = roundi((body.global_position.y - global_position.y) / Globals.grid_size)

	SceneManager.change_level(target_level_name, target_level_trigger, tile_offset)

func _on_body_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
	_can_trigger = true
	_last_triggered_player = null

func _enter_tree() -> void:
	add_to_group(Enums.LevelGroup.keys()[Enums.LevelGroup.SCENETRIGGERS])

func _exit_tree() -> void:
	remove_from_group(Enums.LevelGroup.keys()[Enums.LevelGroup.SCENETRIGGERS])
