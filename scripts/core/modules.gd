extends Node
# Autoload: Modules

func is_action_just_pressed() -> bool:
	return (
		Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down") or
		Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right") or
		Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_down") or
		Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right")
	)

func is_action_pressed() -> bool:
	return (
		Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down") or
		Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right") or
		Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down") or
		Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")
	)

func is_action_just_released() -> bool:
	return (
		Input.is_action_just_released("ui_up") or Input.is_action_just_released("ui_down") or
		Input.is_action_just_released("ui_left") or Input.is_action_just_released("ui_right") or
		Input.is_action_just_released("move_up") or Input.is_action_just_released("move_down") or
		Input.is_action_just_released("move_left") or Input.is_action_just_released("move_right")
	)
