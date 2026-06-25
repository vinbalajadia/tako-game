class_name Interactable
extends Node2D

@export_category("Dialogue")
@export var dialogues: Array[DialogueEntry] = []
@export var one_shot: bool = false

var _triggered: bool = false

func _exit_tree() -> void:
	if not one_shot:
		_triggered = false

func _process(_delta: float) -> void:
	if one_shot and _triggered:
		return
	if SceneManager.is_changing or SceneManager.is_battling or DialogueManager.is_dialogue:
		return
	if not Input.is_action_just_pressed("interact"):
		return

	var player: Node = GameManager.get_player()
	if player == null:
		return

	var movement: CharacterMovement = player.get_node_or_null("Movement")
	if movement != null and movement.is_moving():
		return

	var input: CharacterInput = player.get_node_or_null("Input")
	if input == null or input.direction == Vector2.ZERO:
		return

	var grid: float = Globals.grid_size
	var facing_tile := Vector2(
		roundf((player.global_position.x + input.direction.x * grid) / grid) * grid,
		roundf((player.global_position.y + input.direction.y * grid) / grid) * grid
	)
	var my_tile := Vector2(
		roundf(global_position.x / grid) * grid,
		roundf(global_position.y / grid) * grid
	)

	if facing_tile != my_tile:
		return

	_triggered = true
	_trigger_dialogue()

func _trigger_dialogue() -> void:
	if dialogues.is_empty():
		return
	await DialogueManager.show(dialogues)
	if not one_shot:
		_triggered = false
