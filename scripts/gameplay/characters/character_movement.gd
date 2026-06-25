class_name CharacterMovement
extends Node

signal animation(animation_type: String)

@export_category("Nodes")
@export var character: CharacterBody2D
@export var character_input: CharacterInput

@export_category("Movement")
@export var target_position: Vector2 = Vector2.DOWN
@export var is_walking: bool = false
@export var collision_detected: bool = false

func _ready() -> void:
	if character == null:
		push_error("CharacterMovement: character export is not set.")
	if character_input == null:
		push_error("CharacterMovement: character_input export is not set.")
		return
	character_input.walk.connect(_start_walking)
	character_input.turn.connect(_turn)
	character_input.idle.connect(_on_idle)
	GameLogger.info("Loading player movement component ...")

func _physics_process(delta: float) -> void:
	if SceneManager.is_changing or DialogueManager.is_dialogue:
		is_walking = false
		if character != null:
			character.velocity = Vector2.ZERO
		return
	_walk(delta)

func is_moving() -> bool:
	return is_walking

func is_colliding() -> bool:
	return collision_detected

func _start_walking() -> void:
	if character == null or character_input == null:
		return
	if is_moving():
		return
	if DialogueManager.is_dialogue:
		return

	# Grid step: only start walking if the next cell is not blocked.
	var motion: Vector2 = character_input.direction * Globals.grid_size
	if motion == Vector2.ZERO:
		return

	# test_move checks collisions via CharacterBody2D collision shapes/layers/masks.
	collision_detected = character.test_move(character.global_transform, motion)
	if collision_detected:
		_on_idle()
		return

	animation.emit("walk")
	target_position = character.position + motion
	GameLogger.info("Moving from " + str(character.position) + " to " + str(target_position))
	is_walking = true

func _walk(delta: float) -> void:
	if character == null:
		return
	if is_walking:
		var is_running: bool = character_input is PlayerInput and Input.is_action_pressed("run")
		var speed: float = Globals.run_speed if is_running else Globals.walk_speed

		var to_target: Vector2 = target_position - character.position
		if to_target.length() < speed * 4.0 * delta + 0.5:
			character.position = target_position
			_stop_walking()
			return

		character.velocity = to_target.normalized() * (speed * 4.0)
		character.move_and_slide()

		# If we slid into anything (e.g. boundary TileMap collision), cancel the step.
		if character.get_slide_collision_count() > 0:
			collision_detected = true
			_stop_walking()
	else:
		character.velocity = Vector2.ZERO

func _stop_walking() -> void:
	if character != null:
		character.velocity = Vector2.ZERO
	_snap_position_to_grid()
	is_walking = false
	var blocked: bool = (character_input is PlayerInput) and \
		(SceneManager.is_enemy_approaching or SceneManager.is_battling)
	if not character_input.is_continuous_input() or blocked:
		animation.emit("idle")

func _turn() -> void:
	animation.emit("turn")

func _on_idle() -> void:
	animation.emit("idle")

func _snap_position_to_grid() -> void:
	if character == null:
		return
	character.position = Vector2(
		roundf(character.position.x / Globals.grid_size) * Globals.grid_size,
		roundf(character.position.y / Globals.grid_size) * Globals.grid_size
	)
