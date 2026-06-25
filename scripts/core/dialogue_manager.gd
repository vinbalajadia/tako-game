extends Node
# Autoload: DialogueManager

var is_dialogue: bool = false
var _box: Node = null

func show(dialogue: Array) -> void:
	if dialogue == null or dialogue.is_empty():
		return
	if is_dialogue:
		return

	is_dialogue = true

	var scene: PackedScene = load("res://scenes/ui/dialogue_box.tscn")
	_box = scene.instantiate()
	var parent = SceneManager if GameManager.instance == null else GameManager.instance
	parent.add_child(_box)
	await _box.play_dialogue(dialogue)
	if is_instance_valid(_box):
		_box.queue_free()
	_box = null
	is_dialogue = false

func cancel() -> void:
	is_dialogue = false
	if _box != null and is_instance_valid(_box):
		_box.queue_free()
	_box = null
