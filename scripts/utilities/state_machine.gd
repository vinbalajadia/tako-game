class_name StateMachine
extends Node

@export_category("State Machine Vars")
@export var customer: Node

var current_state: State

func _ready() -> void:
	for child in get_children():
		if child is State:
			child.state_owner = customer
			child.set_process(false)

func get_current_state_name() -> String:
	return current_state.name

func change_state(new_state: String) -> void:
	if current_state:
		current_state.exit_state()
	current_state = get_node(new_state)
	if current_state:
		current_state.enter_state()

	for child in get_children():
		if child is State:
			child.set_process(child == current_state)
