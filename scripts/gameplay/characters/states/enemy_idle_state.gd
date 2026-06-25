class_name EnemyIdleState
extends State

@export_category("Nodes")
@export var enemy_input: EnemyInput
@export var character_movement: CharacterMovement

var _vision_ray: RayCast2D

func enter_state() -> void:
	super.enter_state()
	var enemy: Enemy = state_owner as Enemy

	if enemy_input != null and enemy != null:
		enemy_input.direction = enemy.vision_direction
		enemy_input.idle.emit()

	if enemy == null or enemy.is_final_boss:
		return

	_vision_ray = state_owner.get_node_or_null("VisionRay")
	if _vision_ray != null:
		_vision_ray.add_exception(state_owner as CollisionObject2D)
		_vision_ray.enabled = true
		_vision_ray.target_position = enemy.vision_direction * enemy.vision_range * Globals.grid_size

func exit_state() -> void:
	super.exit_state()
	if _vision_ray != null:
		_vision_ray.enabled = false

func _process(_delta: float) -> void:
	if SceneManager.is_changing or SceneManager.is_battling or DialogueManager.is_dialogue:
		return

	var enemy: Enemy = state_owner as Enemy
	if enemy == null:
		return

	if enemy.is_final_boss:
		var player: Node = GameManager.get_player()
		if player == null:
			return

		var diff: Vector2 = enemy.global_position - player.global_position
		var dist: float = absf(diff.x) + absf(diff.y)
		if dist > Globals.grid_size + 1.0:
			return

		var dir_to_boss: Vector2
		if absf(diff.x) >= absf(diff.y):
			dir_to_boss = Vector2.RIGHT if diff.x > 0 else Vector2.LEFT
		else:
			dir_to_boss = Vector2.DOWN if diff.y > 0 else Vector2.UP

		var player_movement: CharacterMovement = player.get_node_or_null("Movement")
		if player_movement != null and player_movement.is_moving():
			return

		var player_char_input: CharacterInput = player.get_node_or_null("Input")
		var player_dir: Vector2 = player_char_input.direction if player_char_input != null else Vector2.ZERO

		if player_dir == dir_to_boss and Input.is_action_just_pressed("interact"):
			_trigger_final_boss_battle(enemy)
		return

	if _vision_ray == null or not _vision_ray.enabled:
		return

	_vision_ray.force_raycast_update()
	if _vision_ray.is_colliding() and _vision_ray.get_collider() is Player:
		AudioManager.play_music("battle")
		enemy.state_machine.change_state("Alert")

func _trigger_final_boss_battle(enemy: Enemy) -> void:
	if Globals.final_boss_defeated:
		if enemy.post_defeat_dialogue.size() > 0:
			await DialogueManager.show(enemy.post_defeat_dialogue)
		return
	if enemy.battle_dialogue.size() > 0:
		await DialogueManager.show(enemy.battle_dialogue)
	SceneManager.start_battle(enemy)
