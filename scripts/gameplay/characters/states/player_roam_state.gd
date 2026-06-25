class_name PlayerRoamState
extends State

@export_category("State Vars")
@export var player_input: PlayerInput
@export var character_movement: CharacterMovement

var _previous_direction: Vector2 = Vector2.ZERO
var _queued_direction: Vector2 = Vector2.ZERO
var _was_changing_scene: bool = false
var _was_battling: bool = false

func _process(delta: float) -> void:
	_get_input_direction()
	_get_input(delta)

func _get_input_direction() -> void:
	var is_changing_now: bool = SceneManager.is_changing
	var is_battling_now: bool = SceneManager.is_battling
	var just_finished_transition: bool = \
		(_was_changing_scene and not is_changing_now) or (_was_battling and not is_battling_now)
	_was_changing_scene = is_changing_now
	_was_battling = is_battling_now

	if is_changing_now or is_battling_now or SceneManager.is_enemy_approaching:
		return

	var new_direction: Vector2 = Vector2.ZERO

	if just_finished_transition:
		# Reset stale state so held keys and _previous_direction don't carry over.
		_previous_direction = player_input.direction
		_queued_direction = Vector2.ZERO
		player_input.hold_time = 0.0
		# Pick up any key already held so direction syncs on the first frame.
		if Input.is_action_pressed("ui_up") or Input.is_action_pressed("move_up"):
			new_direction = Vector2.UP
			player_input.target_position = Vector2(0, -Globals.grid_size)
		elif Input.is_action_pressed("ui_down") or Input.is_action_pressed("move_down"):
			new_direction = Vector2.DOWN
			player_input.target_position = Vector2(0, Globals.grid_size)
		elif Input.is_action_pressed("ui_left") or Input.is_action_pressed("move_left"):
			new_direction = Vector2.LEFT
			player_input.target_position = Vector2(-Globals.grid_size, 0)
		elif Input.is_action_pressed("ui_right") or Input.is_action_pressed("move_right"):
			new_direction = Vector2.RIGHT
			player_input.target_position = Vector2(Globals.grid_size, 0)

	if new_direction == Vector2.ZERO:
		if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("move_up"):
			new_direction = Vector2.UP
			player_input.target_position = Vector2(0, -Globals.grid_size)
		elif Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("move_down"):
			new_direction = Vector2.DOWN
			player_input.target_position = Vector2(0, Globals.grid_size)
		elif Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("move_left"):
			new_direction = Vector2.LEFT
			player_input.target_position = Vector2(-Globals.grid_size, 0)
		elif Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("move_right"):
			new_direction = Vector2.RIGHT
			player_input.target_position = Vector2(Globals.grid_size, 0)

	# If mid-step, buffer the desired direction change and apply it after snapping to grid.
	if character_movement != null and character_movement.is_moving():
		if new_direction != Vector2.ZERO:
			_queued_direction = new_direction
		return

	# Apply any buffered direction once we become idle.
	if _queued_direction != Vector2.ZERO:
		new_direction = _queued_direction
		_queued_direction = Vector2.ZERO
		player_input.target_position = Vector2(
			new_direction.x * Globals.grid_size,
			new_direction.y * Globals.grid_size
		)

	if new_direction != Vector2.ZERO and new_direction != _previous_direction:
		player_input.direction = new_direction
		_previous_direction = new_direction
		player_input.turn.emit()

func _get_input(delta: float) -> void:
	if SceneManager.is_changing or SceneManager.is_battling or SceneManager.is_enemy_approaching:
		return

	if Modules.is_action_pressed():
		player_input.hold_time += delta
		if player_input.hold_time > player_input.hold_threshold:
			player_input.walk.emit()

	if Modules.is_action_just_released():
		player_input.hold_time = 0.0
		# Don't interrupt a step already in progress; transition to idle when movement completes.
		if character_movement == null or not character_movement.is_moving():
			player_input.idle.emit()
