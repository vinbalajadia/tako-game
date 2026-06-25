class_name Player
extends CharacterBody2D

var state_machine: StateMachine

func _ready() -> void:
	state_machine = get_node("StateMachine")
	state_machine.change_state("Roam")
