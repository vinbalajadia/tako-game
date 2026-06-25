class_name CharacterAnimation
extends AnimatedSprite2D

@export_category("Nodes")
@export var character_input: CharacterInput
@export var character_movement: CharacterMovement

@export_category("Animation Vars")
@export var e_character_animation: int = Enums.ECharacterAnimation.idle_down

func _ready() -> void:
	character_movement.animation.connect(_play_animation)
	GameLogger.info("Loading player animation component ...")

func _play_animation(animation_type: String) -> void:
	if sprite_frames == null:
		return
	var previous_animation: int = e_character_animation

	match animation_type:
		"walk":
			if character_input.direction == Vector2.DOWN:
				e_character_animation = Enums.ECharacterAnimation.walk_down
			elif character_input.direction == Vector2.UP:
				e_character_animation = Enums.ECharacterAnimation.walk_up
			elif character_input.direction == Vector2.LEFT:
				e_character_animation = Enums.ECharacterAnimation.walk_left
			elif character_input.direction == Vector2.RIGHT:
				e_character_animation = Enums.ECharacterAnimation.walk_right
		"idle":
			if character_input.direction == Vector2.DOWN:
				e_character_animation = Enums.ECharacterAnimation.idle_down
			elif character_input.direction == Vector2.UP:
				e_character_animation = Enums.ECharacterAnimation.idle_up
			elif character_input.direction == Vector2.LEFT:
				e_character_animation = Enums.ECharacterAnimation.idle_left
			elif character_input.direction == Vector2.RIGHT:
				e_character_animation = Enums.ECharacterAnimation.idle_right
		"turn":
			if character_input.direction == Vector2.DOWN:
				e_character_animation = Enums.ECharacterAnimation.turn_down
			elif character_input.direction == Vector2.UP:
				e_character_animation = Enums.ECharacterAnimation.turn_up
			elif character_input.direction == Vector2.LEFT:
				e_character_animation = Enums.ECharacterAnimation.turn_left
			elif character_input.direction == Vector2.RIGHT:
				e_character_animation = Enums.ECharacterAnimation.turn_right

	if previous_animation != e_character_animation:
		var anim_name: String = Enums.ECharacterAnimation.keys()[e_character_animation]
		GameLogger.info("Playing animation: " + anim_name)
		play(anim_name)
