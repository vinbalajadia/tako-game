class_name EnemyAlertState
extends State

# Pokémon-style "!" pause before the enemy starts chasing.

@export_category("Nodes")
@export var enemy_input: EnemyInput

var _timer: float = 0.0

func enter_state() -> void:
	super.enter_state()
	_timer = 0.0
	SceneManager.set_enemy_approaching(true)
	if enemy_input != null:
		enemy_input.idle.emit()

func _process(delta: float) -> void:
	var enemy: Enemy = state_owner as Enemy
	if enemy == null:
		return
	_timer += delta
	if _timer >= enemy.alert_duration:
		enemy.state_machine.change_state("Chase")
