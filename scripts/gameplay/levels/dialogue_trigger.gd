class_name DialogueTrigger
extends Area2D

@export_category("Dialogue")
@export var dialogues: Array[DialogueEntry] = []
@export var one_shot: bool = true
@export var trigger_id: String = ""

var _triggered: bool = false

func _ready() -> void:
	if one_shot and trigger_id != "" and Globals.triggered_dialogues.has(trigger_id):
		queue_free()
		return
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player" or _triggered:
		return
	if SceneManager.is_changing or SceneManager.is_battling or DialogueManager.is_dialogue:
		return
	if dialogues.is_empty():
		return

	_triggered = true
	_run_dialogue(body)

func _run_dialogue(body: Node2D) -> void:
	# Wait for the current movement step to finish so player snaps to grid before dialogue blocks input.
	var movement: CharacterMovement = null
	for child in body.get_children():
		if child is CharacterMovement:
			movement = child
			break
	if movement != null:
		while movement.is_walking:
			await get_tree().process_frame

	await DialogueManager.show(dialogues)

	if one_shot:
		if trigger_id != "":
			Globals.triggered_dialogues[trigger_id] = true
			PlayerDataManager.mark_dialogue_triggered(trigger_id)
		queue_free()
	else:
		_triggered = false
