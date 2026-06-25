class_name EnemyChaseState
extends State

@export_category("Nodes")
@export var enemy_input: EnemyInput
@export var character_movement: CharacterMovement

var _last_direction: Vector2 = Vector2.ZERO
var _turn_timer: float = 0.0
const TURN_PAUSE: float = 0.15

func enter_state() -> void:
	super.enter_state()
	_last_direction = Vector2.ZERO
	_turn_timer = 0.0
	if enemy_input != null:
		enemy_input.is_chasing = true

func exit_state() -> void:
	super.exit_state()
	if enemy_input != null:
		enemy_input.is_chasing = false

func _process(delta: float) -> void:
	if SceneManager.is_changing or SceneManager.is_battling or DialogueManager.is_dialogue:
		return
	if character_movement == null or character_movement.is_moving():
		return

	var enemy: Enemy = state_owner as Enemy
	if enemy == null:
		return

	var player: Node = GameManager.get_player()
	if player == null:
		return

	var diff: Vector2 = player.global_position - enemy.global_position
	var dist: float = absf(diff.x) + absf(diff.y)

	if dist <= Globals.grid_size + 1.0:
		_trigger_battle(enemy)
		return

	var dir: Vector2
	if absf(diff.x) >= absf(diff.y):
		dir = Vector2.RIGHT if diff.x > 0 else Vector2.LEFT
	else:
		dir = Vector2.DOWN if diff.y > 0 else Vector2.UP

	enemy_input.direction = dir

	if dir != _last_direction:
		_last_direction = dir
		_turn_timer = 0.0
		enemy_input.turn.emit()
		return

	_turn_timer += delta
	if _turn_timer >= TURN_PAUSE:
		enemy_input.walk.emit()

func _trigger_battle(enemy: Enemy) -> void:
	enemy_input.is_chasing = false
	enemy_input.idle.emit()
	if enemy.battle_dialogue.size() > 0:
		await DialogueManager.show(enemy.battle_dialogue)
	SceneManager.start_battle(enemy)
